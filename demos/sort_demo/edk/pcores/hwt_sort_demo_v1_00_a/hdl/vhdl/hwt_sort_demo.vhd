library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_sort_demo is
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

end hwt_sort_demo;

architecture implementation of hwt_sort_demo is
	type STATE_TYPE is (
					STATE_GET_ADDR,STATE_READ_REQ,STATE_READ_CTRL,STATE_READ,STATE_SORTING,
					STATE_WRITE_REQ,STATE_WRITE_CTRL,STATE_WRITE,STATE_ACK,STATE_THREAD_EXIT);

	component bubble_sorter is
		generic (
			G_LEN    : integer := 512;  -- number of words to sort
			G_AWIDTH : integer := 9;  -- in bits
			G_DWIDTH : integer := 32  -- in bits
		);

		port (
			clk   : in std_logic;
			reset : in std_logic;
			-- local ram interface
			o_RAMAddr : out std_logic_vector(0 to G_AWIDTH-1);
			o_RAMData : out std_logic_vector(0 to G_DWIDTH-1);
			i_RAMData : in  std_logic_vector(0 to G_DWIDTH-1);
			o_RAMWE   : out std_logic;
			start     : in  std_logic;
			done      : out std_logic
		);
  	end component;
	
	-- The sorting application reads 'C_LOCAL_RAM_SIZE' 32-bit words into the local RAM,
	-- from a given address (send in a message box), sorts them and writes them back into main memory.

	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 512;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	
	
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal addr     : std_logic_vector(31 downto 0);
	signal data     : std_logic_vector(31 downto 0);
	signal req      : std_logic_vector(31 downto 0);
	signal len      : std_logic_vector(23 downto 0);
	signal cmd      : std_logic_vector(7 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;

	signal o_RAMAddr_sorter : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_sorter : std_logic_vector(0 to 31);
	signal o_RAMWE_sorter   : std_logic;

	signal o_RAMAddr_reconos : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_reconos : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos   : std_logic;

	signal o_RAMAddr : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData : std_logic_vector(0 to 31);
	signal i_RAMData : std_logic_vector(0 to 31);
	signal o_RAMWE   : std_logic;
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	signal local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal sort_start : std_logic := '0';
	signal sort_done  : std_logic := '0';
	signal sort_en    : std_logic := '0';
begin

	-- switch 1: address
	o_RAMAddr <= o_RAMAddr_sorter when sort_en = '1' else o_RAMAddr_reconos;

	-- switch 2: write enable
	o_RAMWE <= o_RAMWE_sorter     when sort_en = '1' else o_RAMWE_reconos;
  
	-- switch 3: output ram data
	o_RAMData <= o_RAMData_sorter when sort_en = '1' else o_RAMData_reconos;
	
	-- local RAM
	local_ram_ctrl : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then
			if (o_RAMWE = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr))) <= o_RAMData;
			else
				i_RAMData <= local_ram(conv_integer(unsigned(o_RAMAddr)));
			end if;
		end if;
	end process;
	

	-- instantiate bubble_sorter module
	sorter_i : bubble_sorter
		generic map (
			G_LEN     => C_LOCAL_RAM_SIZE,
			G_AWIDTH  => C_LOCAL_RAM_ADDRESS_WIDTH,
			G_DWIDTH  => 32
		)
		port map (
			clk       => OSFSL_Clk,
			reset     => rst,
			o_RAMAddr => o_RAMAddr_sorter,
			o_RAMData => o_RAMData_sorter,
			i_RAMData => i_RAMData,
			o_RAMWE   => o_RAMWE_sorter,
			start     => sort_start,
			done      => sort_done
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
		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
	cmd <= req(31 downto 24);

	
	-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			state <= STATE_GET_ADDR;
			done := False;
			addr <= (others => '0');
			o_RAMAddr_reconos <= (others => '0');
			data <= X"AFFEDEAD";
			req <= (others => '0');
			len <= (others => '0');
			req <= (others => '0');
			sort_start <= '0';
			sort_en    <= '0';
			o_RAMWE_reconos <= '0';
		elsif rising_edge(i_osif.clk) then
			case state is

				-- get address via mbox: the data will be copied from this address to the local ram in the next states
				when STATE_GET_ADDR =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr, done);
					if done then
						if (addr = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							len               <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES,24);
							addr              <= addr(31 downto 2) & "00";
							o_RAMAddr_reconos <= (others => '0');
							state             <= STATE_READ_REQ;
						end if;
					end if;
						
				-- start read request
				when STATE_READ_REQ =>
					memif_read_request(i_memif, o_memif,addr,len,done);
					if done then state <= STATE_READ_CTRL; end if;

				-- control the data transfer from main memory to local memory
				when STATE_READ_CTRL =>
					o_RAMWE_reconos <= '0';
					if len = 0 then
						o_RAMWE_reconos <= '0';
						sort_start <= '1';
						state <= STATE_SORTING;
					else
						o_RAMWE_reconos <= '1';
						state <= STATE_READ;
					end if;
				
				-- read: copy data into the local memory
				when STATE_READ =>
					memif_fifo_pull(i_memif, o_memif,o_RAMData_reconos,done);
					if done then
						state <= STATE_READ_CTRL;
						if (o_RAMAddr_reconos < o_RAMAddr_max) then
							o_RAMAddr_reconos <= o_RAMAddr_reconos + 1;
						end if;
						len <= len - 4;
					end if;

				-- sort the words in local RAM
				when STATE_SORTING =>
					sort_en    <= '1';
					sort_start <= '0';
					o_RAMAddr_reconos <= (others => '0');
					if sort_done = '1' then
						len    <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES,24);
						state  <= STATE_WRITE_REQ;
					end if;

				-- start write request
				when STATE_WRITE_REQ =>
					sort_en    <= '0';
					memif_write_request(i_memif, o_memif,addr,len,done);
					if done then 
						state <= STATE_WRITE_CTRL; 
					end if;

				-- control the data transfer from local memory to main memory
				when STATE_WRITE_CTRL =>
					if len = 0 then
						state <= STATE_ACK;
					else
						state <= STATE_WRITE;
					end if;

				-- write: transfer data to the main memory
				when STATE_WRITE =>
					memif_fifo_push(i_memif, o_memif, i_RAMData, done);
					if done then 
						state             <= STATE_WRITE_CTRL;
						if (o_RAMAddr_reconos < o_RAMAddr_max) then
							o_RAMAddr_reconos <= o_RAMAddr_reconos + 1;
						end if;
						len               <= len - 4;
					end if;
				
				-- send mbox that signals that the sorting is finished
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, addr, ignore, done);
					if done then state <= STATE_GET_ADDR; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			
			end case;
		end if;
	end process;
	
end architecture;
