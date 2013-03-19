library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_sort_demo_messages is
  generic (
    C_FAULT_CHANNEL_WIDTH: Natural := 2 -- 2^2 = 4 channels
  );
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
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
    -- Fault injection related ports
    fault_sa0     : in std_logic_vector(32*(2**C_FAULT_CHANNEL_WIDTH)-1 downto 0 );
    fault_sa1     : in std_logic_vector(32*(2**C_FAULT_CHANNEL_WIDTH)-1 downto 0 );

		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);

end hwt_sort_demo_messages;

architecture implementation of hwt_sort_demo_messages is

  function faultinject(signal sa0: std_logic_vector; signal sa1: std_logic_vector; signal s: std_logic_vector)
  return std_logic_vector
  is
     variable temp: std_logic_vector(s'range);
  begin
     temp := s and not sa0;
     return temp or sa1;
  end function;

  function faultinject_c(signal sa0: std_logic_vector; signal sa1: std_logic_vector; constant s: std_logic_vector)
  return std_logic_vector
  is
     variable temp: std_logic_vector(s'range);
  begin
     temp := s and not sa0;
     return temp or sa1;
  end function;
  
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
	constant C_LOCAL_RAM_SIZE          : integer := 2048;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

--	type STATE_TYPE is (
--					STATE_GET_LENGTH,STATE_READ,STATE_SORTING,
--					STATE_WRITE,STATE_THREAD_YIELD,STATE_THREAD_EXIT);
--  signal state    : STATE_TYPE;
  
  constant STATE_GET_LENGTH   : std_logic_vector(2 downto 0) := "000";
  constant STATE_READ         : std_logic_vector(2 downto 0) := "001";
  constant STATE_SORTING      : std_logic_vector(2 downto 0) := "010";
  constant STATE_WRITE        : std_logic_vector(2 downto 0) := "011";
  constant STATE_THREAD_YIELD : std_logic_vector(2 downto 0) := "100";
  constant STATE_THREAD_EXIT  : std_logic_vector(2 downto 0) := "101";
  signal state  : std_logic_vector(2 downto 0) := "000";
  
	signal data_len : std_logic_vector(31 downto 0);
	signal len      : std_logic_vector(31 downto 0);
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_sorter : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_sorter : std_logic_vector(0 to 31);
  signal o_RAMData_sorter_orig : std_logic_vector(0 to 31);
	signal o_RAMWE_sorter   : std_logic;
	signal i_RAMData_sorter : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal sort_start : std_logic := '0';
	signal sort_done  : std_logic := '0';
begin
	
  -- fault injections:
  o_RAMData_sorter <= faultinject(fault_sa0(63 downto 32), fault_sa1(63 downto 32), o_RAMData_sorter_orig);
  
	-- local dual-port RAM
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
			if (o_RAMWE_sorter = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_sorter))) := o_RAMData_sorter;
			else
				i_RAMData_sorter <= local_ram(conv_integer(unsigned(o_RAMAddr_sorter)));
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
			clk       => clk,
			reset     => rst,
			o_RAMAddr => o_RAMAddr_sorter,
			o_RAMData => o_RAMData_sorter_orig,
			i_RAMData => i_RAMData_sorter,
			o_RAMWE   => o_RAMWE_sorter,
			start     => sort_start,
			done      => sort_done
	);

	fsl_setup(
		i_osif,
		o_osif,
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
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
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
	reconos_fsm: process (clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_GET_LENGTH);
			done  := False;
			data_len <= (others => '0');
			len <= (others => '0');
			sort_start <= '0';
		elsif rising_edge(clk) then
			case state is

				-- get address via mbox: the data will be copied from this address to the local ram in the next states
				when STATE_GET_LENGTH =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, data_len, done);
          o_ram.we <= '0';
					if done then
            len <= data_len;
            o_ram.addr <= (others =>'1' );
						if (data_len = X"FFFFFFFF") then
							state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_THREAD_EXIT);
						else
							state             <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_READ);
						end if;
					end if;
				
				-- copy data from mbox to local memory
				when STATE_READ =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, o_ram.data, done);
          o_ram.we <= '0';
					if done then
            o_ram.we <= '1';
            o_ram.addr <= i_ram.addr + 1;
            if len = 1 then
              sort_start <= '1';
              state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_SORTING);
            else
              len <= len - 1;
            end if;
					end if;

				-- sort the words in local RAM
				when STATE_SORTING =>
					sort_start <= '0';
          o_ram.we <= '0';
					if sort_done = '1' then
						len    <= data_len;
            o_ram.addr <= (others => '0');
						state  <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_WRITE);
					end if;
					
				-- copy data from local memory to main memory
				when STATE_WRITE =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND, i_ram.data, ignore, done);
          o_ram.we <= '0';
					if done then 
            if len = 1 then
              state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_THREAD_YIELD);
            else
              len <= len - 1;
              o_ram.addr <= i_ram.addr + 1;
            end if;
          end if;
        
        -- signal to runtime system we don't have any state now and are ready to be replaced
        -- with another thread
        when STATE_THREAD_YIELD =>
          -- return value is stored to data_len, because it is not needed and data_len will 
          -- be overwritten in next state.
          osif_thread_yield(i_osif, o_osif, data_len, done);
          if done then
            state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_GET_LENGTH);
          end if;
        
				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
          
        when others =>
          state <= faultinject_c(fault_sa0(2 downto 0), fault_sa1(2 downto 0), STATE_GET_LENGTH);
			
			end case;
		end if;
	end process;
	
end architecture;
