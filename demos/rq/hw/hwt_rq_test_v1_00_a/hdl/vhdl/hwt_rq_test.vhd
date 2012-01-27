library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity hwt_rq_test is
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Clk : out std_logic;
		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset
		rst           : in std_logic
	);

end hwt_rq_test;

architecture implementation of hwt_rq_test is
	type STATE_TYPE is (STATE_RECEIVE_A,STATE_CHANGE_DATA,STATE_CHANGE_DATA_2,STATE_CHANGE_DATA_3,
		STATE_CHANGE_DATA_4,STATE_CHANGE_DATA_5,STATE_SEND_B,STATE_THREAD_EXIT);

	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 512;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
		
	constant C_RECONOS_QUEUE_A : std_logic_vector(31 downto 0) := X"00000000";
	constant C_RECONOS_QUEUE_B : std_logic_vector(31 downto 0) := X"00000001";

	signal len           : std_logic_vector(31 downto 0);
	signal message_width : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal counter       : std_logic_vector(C_FSL_WIDTH-3 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
begin

	-- do not use memory interface (memif)
	FIFO32_S_Clk  <= OSFSL_Clk;
	FIFO32_M_Clk  <= OSFSL_Clk;
	FIFO32_M_Data <= (others => '0');
	FIFO32_S_Rd   <= '0';
	FIFO32_M_Wr   <= '0';

	-- local single-port RAM
	local_ram_ctrl : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then
			if (o_RAMWE_reconos = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
			else
				i_RAMData_reconos <= local_ram(conv_integer(unsigned(o_RAMAddr_reconos)));
			end if;
		end if;
	end process;

	osif_setup(
		i_osif,
		o_osif,
		OSFSL_Clk,
		OSFSL_Rst,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
	
	ram_setup(
		i_ram,
		o_ram,
		o_RAMAddr_reconos_2,		
		o_RAMData_reconos,
		i_RAMData_reconos,
		o_RAMWE_reconos
	);
	
	o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);
		
	-- os and memory synchronisation state machine
	process (i_osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			ram_reset(o_ram);
			--len <= conv_std_logic_vector(48,32);
			len <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES,32);
			state <= STATE_RECEIVE_A;
			done := False;
		elsif rising_edge(i_osif.clk) then
			o_ram.we <= '0';
			case state is
						
				when STATE_RECEIVE_A =>
					osif_rq_receive(i_osif,o_osif,i_ram,o_ram,C_RECONOS_QUEUE_A,len,X"00000000",message_width,done);
					if done then
						if (message_width = 0) then
							state <= STATE_THREAD_EXIT;
						else
							state <= STATE_CHANGE_DATA;
						end if;
					end if;
				
				when STATE_CHANGE_DATA =>
					counter(C_FSL_WIDTH-3 downto 0) <= message_width(C_FSL_WIDTH-1 downto 2); 
					o_ram.addr <= (others=>'0');
					state <= STATE_CHANGE_DATA_2;
					
				when STATE_CHANGE_DATA_2 =>
					if (counter = 0) then
						state <= STATE_SEND_B;
					else 
						state <= STATE_CHANGE_DATA_3;
					end if;

				when STATE_CHANGE_DATA_3 =>					
					o_ram.we   <= '1';
					o_ram.data <= i_ram.data + 1;
					state <= STATE_CHANGE_DATA_4;
						
				when STATE_CHANGE_DATA_4 =>	
					counter <= counter - 1;
					state <= STATE_CHANGE_DATA_5;
					
				when STATE_CHANGE_DATA_5 =>
					o_ram.addr <= i_ram.addr + 1;
					state <= STATE_CHANGE_DATA_2;				
	
				when STATE_SEND_B =>
					osif_rq_send(i_osif,o_osif,i_ram,o_ram,C_RECONOS_QUEUE_B,message_width,X"00000000",ignore,done);
					if done then state <= STATE_RECEIVE_A; end if;
					
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
									
			end case;
		end if;
	end process;
	
end architecture;
