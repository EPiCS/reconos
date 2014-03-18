library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_icap is
	port (
		-- OSIF FSL		
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data : in  std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
		FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
		FIFO32_S_Rd   : out std_logic;
		FIFO32_M_Wr   : out std_logic;
		
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);
end entity;

architecture implementation of hwt_icap is
	type STATE_TYPE is (STATE_GET_BITSTREAM_ADDR,STATE_GET_BITSTREAM_SIZE,STATE_SEND_RESULT,STATE_THREAD_EXIT);
	
	constant MBOX_RECV   : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND   : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";
	constant ICAP_DWIDTH : integer                                  := 32;

	constant C_LOCAL_RAM_SIZE          : integer := 2048;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);

	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_icap : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_icap : std_logic_vector(0 to 31);
	signal o_RAMWE_icap   : std_logic;
	signal i_RAMData_icap : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal addr   : std_logic_vector(31 downto 0);
	signal len    : std_logic_vector(31 downto 0);
	signal result : std_logic_vector(31 downto 0);

	-- icap commands
	--signal icap_busy        : std_logic;
	--signal icap_ce          : std_logic;
	--signal icap_we          : std_logic;
	--signal icap_datain      : std_logic_vector(0 to ICAP_DWIDTH-1);
	--signal icap_dataout     : std_logic_vector(0 to ICAP_DWIDTH-1);

begin

	-- setup osif, memif, local ram
	fsl_setup(i_osif,o_osif,OSFSL_S_Data,OSFSL_S_Exists,OSFSL_M_Full,OSFSL_M_Data,OSFSL_S_Read,OSFSL_M_Write,OSFSL_M_Control);
	memif_setup(i_memif,o_memif,FIFO32_S_Data,FIFO32_S_Fill,FIFO32_S_Rd,FIFO32_M_Data,FIFO32_M_Rem,FIFO32_M_Wr);
	ram_setup(i_ram,o_ram,o_RAMAddr_reconos_2,o_RAMData_reconos,i_RAMData_reconos,o_RAMWE_reconos);

	-- local dual-port ram
	local_ram_ctrl_1 : process (clk) is
	begin
		if (rising_edge(clk)) then
			if (o_RAMWE_reconos = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
			else
				i_RAMData_reconos <= local_ram(conv_integer(unsigned(o_RAMAddr_reconos)));
			end if;
		end if;
	end process;
			
	local_ram_ctrl_2 : process (clk) is
	begin
		if (rising_edge(clk)) then		
			if (o_RAMWE_icap = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_icap))) := o_RAMData_icap;
			else
				i_RAMData_icap <= local_ram(conv_integer(unsigned(o_RAMAddr_icap)));
			end if;
		end if;
	end process;

	o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);		
		
	-- os and memory synchronisation state machine
	reconos_fsm: process (clk,rst,o_osif) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			result <= (others=>'0');
			state <= STATE_GET_BITSTREAM_ADDR;
			done  := False;
		elsif rising_edge(clk) then
			case state is
				-- get mem address
				when STATE_GET_BITSTREAM_ADDR =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr, done);
					if done then
						if (addr = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							state <= STATE_GET_BITSTREAM_SIZE;
						end if;
					end if;
				-- get bitstream len
				when STATE_GET_BITSTREAM_SIZE =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, len, done);
					if done then
						if (len = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							state <= STATE_SEND_RESULT;
						end if;
					end if;
				-- TODO configure partial bitstream using ICAP		
				-- send result
				when STATE_SEND_RESULT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, result, ignore, done);
					if done then state <= STATE_GET_BITSTREAM_ADDR; end if;
				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);			
			end case;
		end if;
	end process;

	--ICAP_VERTEX6_I : ICAP_VIRTEX6
        --	generic map (
        --		ICAP_WIDTH => ICAP_DWIDTH)
        --	port map (
        --		clk        => clk,
        --		csb        => icap_ce,
        --		rdwrb      => icap_we,
        --		i          => icap_datain,
        --		busy       => icap_busy,
        --		o          => icap_dataout);
	
end architecture;

