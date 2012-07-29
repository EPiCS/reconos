library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

library ana_hwt_sw2hw_v1_00_a;

entity ana_hwt_sw2hw is
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
--		FIFO32_S_Clk : out std_logic;
--		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- NoC interface
--		downstreamReadEnable	: out std_logic;
--		downstreamEmpty  		: in std_logic;
--		downstreamData			: in std_logic_vector(8 downto 0);
--		downstreamReadClock		: out std_logic;
--		upstreamWriteEnable		: out std_logic;
--		upstreamData			: out std_logic_vector(8 downto 0);
--		upstreamFull 			: in std_logic;
--		upstreamWriteClock 		: out std_logic;

		switch_data_rdy	: in std_logic;
		switch_data	: in std_logic_vector(8 downto 0);
		thread_read_rdy : out std_logic;

		thread_data_rdy	: out std_logic;
		thread_data	: out std_logic_vector(8 downto 0);
		switch_read_rdy : in std_logic;
		
		-- HWT reset
		rst           : in std_logic
	);

end ana_hwt_sw2hw;

architecture implementation of ana_hwt_sw2hw is
	
	type STATE_TYPE is (STATE_INIT,
						STATE_GET_ADDR,
						STATE_READ_CONTIGUOUS,
						STATE_READ_DISCONTIGUOUS_1,
						STATE_READ_DISCONTIGUOUS_2,
						STATE_ACK);

	constant C_LOCAL_RAM_SIZE          : integer := 3750; --fits 10 max size ethernet frames
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := toLog2Ceil(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (C_LOCAL_RAM_SIZE-1 downto 0) of std_logic_vector(31 downto 0);
	shared variable local_ram : LOCAL_MEMORY_T;
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal localRAMWriter_addr	: std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	signal localRAMWriter_addr2	: std_logic_vector(31 downto 0);
	signal localRAMWriter_din	: std_logic_vector(31 downto 0);
	signal localRAMWriter_dout	: std_logic_vector(31 downto 0);
	signal localRAMWriter_we	: std_logic;
	signal localRAMReader_addr	: std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	signal localRAMReader_din	: std_logic_vector(31 downto 0);
	signal localRAMReader_dout	: std_logic_vector(31 downto 0);
	signal localRAMReader_we	: std_logic;
	
	signal localRAMValidPointer	: std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	
	signal reconosBaseAddr		: std_logic_vector(31 downto 0);
	signal reconosReadPtrLow	: std_logic_vector(31 downto 0);
	signal reconosReadPtrHigh	: std_logic_vector(31 downto 0);
	signal reconosLength		: std_logic_vector(23 downto 0);
	signal reconosLength2		: std_logic_vector(31 downto 0);
	signal reconosSrcAddr		: std_logic_vector(31 downto 0);
	
	signal ignore				: std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal not_switch_read_rdy	: std_logic;	
begin
	
	------------------------------------------
	-- LOCAL DUAL-PORT RAM
	------------------------------------------
	localRAMReader_we <= '0'; -- Never write to the RAM from the reader port
	
	-- writer port
	local_ram_ctrl_1 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then
			if (localRAMWriter_we = '1') then
				local_ram(to_integer(unsigned(localRAMWriter_addr))) := localRAMWriter_din;
			else
				localRAMWriter_dout <= local_ram(to_integer(unsigned(localRAMWriter_addr)));
			end if;
		end if;
	end process;
	
	-- reader port
	local_ram_ctrl_2 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then		
			if (localRAMReader_we = '1') then
				local_ram(to_integer(unsigned(localRAMReader_addr))) := localRAMReader_din;
			else
				localRAMReader_dout <= local_ram(to_integer(unsigned(localRAMReader_addr)));
			end if;
		end if;
	end process;
	
	not_switch_read_rdy <= not switch_read_rdy;

	-- instantiate user logic
	userLogic: entity ana_hwt_sw2hw_v1_00_a.userLogic
		generic map(
			C_LOCAL_RAM_ADDRESS_WIDTH => C_LOCAL_RAM_ADDRESS_WIDTH
		)
		port map(
			clk						=> OSFSL_Clk,
			reset					=> rst,
			localRAMReader_addr		=> localRAMReader_addr,
			localRAMReader_dout		=> localRAMReader_dout,
			localRAMValidPointer	=> localRAMValidPointer,
			upstreamWriteEnable		=> thread_data_rdy,
			upstreamData			=> thread_data,
			upstreamFull 			=> not_switch_read_rdy
		);

	fsl_setup(
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
		
	memif_setup(
		i_memif,
		o_memif,
		OSFSL_Clk,
--		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
--		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
	ram_setup(
		i_ram,
		o_ram,
		localRAMWriter_addr2,		
		localRAMWriter_din,
		localRAMWriter_dout,
		localRAMWriter_we
	);
	
	localRAMWriter_addr <= localRAMWriter_addr2(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	reconosLength <= reconosLength2(23 downto 0);
	reconosSrcAddr <= std_logic_vector(unsigned(reconosBaseAddr) + unsigned(reconosReadPtrLow));
	--upstreamWriteClock <= OSFSL_Clk;
	thread_read_rdy <= '0';
	--downstreamReadEnable <= '0';
	--downstreamReadClock <= OSFSL_Clk;	
	
		
	-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= STATE_INIT;
			reconosReadPtrHigh <= (others => '0');
			reconosReadPtrLow <= (others => '0');
			reconosLength2 <= (others => '0');
			localRAMValidPointer <= (others => '0');
		elsif rising_edge(i_osif.clk) then
			case state is
				when STATE_INIT =>
					-- initialize the base address (the address of the circular buffer in the system memory)
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, reconosBaseAddr, done);
					if done then
						state <= STATE_GET_ADDR;
					end if;
				
				-- get the pointer up to which the data in the ring buffer is valid
				when STATE_GET_ADDR =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, reconosReadPtrHigh, done);
					if done then
--						reconosReadPtrLow <= reconosReadPtrHigh;
--						state <= STATE_ACK;
						if unsigned(reconosReadPtrLow) < unsigned(reconosReadPtrHigh) then -- if the memory area to be read is contiguous
							reconosLength2 <= std_logic_vector(unsigned(reconosReadPtrHigh)-unsigned(reconosReadPtrLow)); 
							state <= STATE_READ_CONTIGUOUS;
						else
							reconosLength2 <= std_logic_vector(to_unsigned(C_LOCAL_RAM_SIZE_IN_BYTES, 32) - unsigned(reconosReadPtrLow));
							state <= STATE_READ_DISCONTIGUOUS_1;
						end if;
					end if;
				
				-- copy data from main memory to local memory
				when STATE_READ_CONTIGUOUS =>
					memif_read(i_ram,o_ram,i_memif,o_memif,reconosSrcAddr,reconosReadPtrLow,reconosLength,done);
					if done then
						state <= STATE_ACK;
						reconosReadPtrLow <= reconosReadPtrHigh;
						localRAMValidPointer <= reconosReadPtrHigh(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
					end if;
					
				when STATE_READ_DISCONTIGUOUS_1 =>
					memif_read(i_ram,o_ram,i_memif,o_memif,reconosSrcAddr,reconosReadPtrLow,reconosLength,done);
					if done then
						state <= STATE_READ_DISCONTIGUOUS_2;
						reconosReadPtrLow <= (others => '0');
						reconosLength2 <= reconosReadPtrHigh;
					end if;
					
				when STATE_READ_DISCONTIGUOUS_2 =>
					memif_read(i_ram,o_ram,i_memif,o_memif,reconosSrcAddr,reconosReadPtrLow,reconosLength,done);
					if done then
						state <= STATE_ACK;
						reconosReadPtrLow <= reconosReadPtrHigh;
						localRAMValidPointer <= reconosReadPtrHigh(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
					end if;
				
				-- mark the memory area as free by returning the incremented low address
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, reconosReadPtrLow, ignore, done);
					if done then 
						state <= STATE_GET_ADDR; 
					end if;

			end case;
		end if;
	end process;
	
end architecture;
