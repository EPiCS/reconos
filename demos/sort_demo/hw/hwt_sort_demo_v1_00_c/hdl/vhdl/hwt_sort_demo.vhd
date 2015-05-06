library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_sort_demo is
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
		
		-- fault control
		fault_control : in std_logic_vector(31 downto 0);
		
		debug : out std_logic_vector(127 downto 0);
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);

end entity;

architecture implementation of hwt_sort_demo is
	type STATE_TYPE is (
        STATE_THREAD_YIELD, STATE_GET_LEN,
		STATE_GET_ADDR,STATE_READ,STATE_SORTING,
		STATE_WRITE,STATE_ACK,STATE_THREAD_EXIT);

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
      len       : in  std_logic_vector(0 to G_AWIDTH-1);
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

  signal temp     : std_logic_vector(31 downto 0);
	signal addr     : std_logic_vector(31 downto 0);
	signal len_sorter      : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others => '0'); -- length in words of data
  signal len_reconos     : std_logic_vector(31 downto 0) := (others => '0'); -- length in words of data
	signal state    : STATE_TYPE;
	signal state_with_potential_fault    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_sorter : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_sorter : std_logic_vector(0 to 31);
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
  
    alias control_flow_logic_fault : std_logic is fault_control(0);
    alias control_flow_memory_fault : std_logic is fault_control(1);
    signal control_flow_memory_fault_old : std_logic := '0';
    alias control_flow_wiring_fault : std_logic is fault_control(2);
    alias data_flow_logic_fault : std_logic is fault_control(3);
    alias data_flow_memory_fault : std_logic is fault_control(4);
    alias data_flow_wiring_fault : std_logic is fault_control(5);
    
begin
	
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
  len_sort_proc: process  (len_reconos) is
    variable len : std_logic_vector(31 downto 0);
  begin
    len := len_reconos-1;
    len_sorter <= len(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
  end process;
  
  
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
			o_RAMData => o_RAMData_sorter,
			i_RAMData => i_RAMData_sorter,
			o_RAMWE   => o_RAMWE_sorter,
			start     => sort_start,
      len       => len_sorter,
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
		
	control_logic_memory_fault_p: process(clk, rst, control_flow_memory_fault) is	
	begin
		 if rst = '1' then
			 control_flow_memory_fault_old <= '0';
		 elsif clk'event and clk = '1' then
			 control_flow_memory_fault_old <= control_flow_memory_fault;
		end if;
	end process;
	
	state_with_potential_fault <= STATE_GET_LEN when control_flow_memory_fault_old = '0' and control_flow_memory_fault ='1' else
									state;
	
	debug(3 downto 0) <= X"0" when state = STATE_THREAD_YIELD else
					      X"1" when state = STATE_GET_LEN else
						  X"2" when state = STATE_GET_ADDR else 
						  X"3" when state = STATE_READ else
						  X"4" when state = STATE_SORTING else
					      X"5" when state = STATE_WRITE else
						  X"6" when state = STATE_ACK else
						  X"7" when state = STATE_THREAD_EXIT;
						 
	debug(4) <= sort_start;
	debug(5) <= sort_done;
	debug(21 downto 6) <= FIFO32_S_Fill;
	debug(37 downto 22) <= FIFO32_M_Rem;
			
	debug(127 downto 38) <= (others => '0');
	
	-- os and memory synchronisation state machine
	reconos_fsm: process (clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
		variable done_with_potential_fault  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= STATE_THREAD_YIELD;
			done  := False;
			addr <= (others => '0');
			len_reconos <= (others => '0');
			sort_start <= '0';
		elsif rising_edge(clk) then
			case state_with_potential_fault is
				-- signal to runtime system we don't have any state now and are ready to be replaced
                -- with another thread
                when STATE_THREAD_YIELD =>
                  -- return value is stored to temp, because it is not needed
                  osif_thread_yield(i_osif, o_osif, temp, done);
                  if done then
                    state <= STATE_GET_LEN;
                  end if;

        -- get length via mbox: the amount of data in words to be sorted, will be saved in a local register
				when STATE_GET_LEN =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, temp, done);
					if (control_flow_wiring_fault /= '1') then done_with_potential_fault := done; end if;
					if done_with_potential_fault then
						if (temp = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							len_reconos       <= temp;
							
							-- FAULT INJECTION
							if (control_flow_logic_fault = '1') then
							state             <= STATE_READ; -- skips over STATE_GET_ADDR
							else
							state             <= STATE_GET_ADDR;
							end if;
							-- FAULT INJECTION END	
						end if;
					end if;
          
				-- get address via mbox: the data will be copied from this address to the local ram in the next states
				when STATE_GET_ADDR =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, temp, done);
					if (control_flow_wiring_fault = '0') then done_with_potential_fault := done; end if;
					if done_with_potential_fault then
						addr              <= temp(31 downto 2) & "00";
						state             <= STATE_READ;						
					end if;
				
				-- copy data from main memory to local memory
        -- len_reconos is shifted 2 bits to the left, as len_reconos contains length in words, but
        -- memif_read expects it to be in bytes
				when STATE_READ =>
					memif_read(i_ram,o_ram,i_memif,o_memif,addr,X"00000000", len_reconos(21 downto 0) & "00" ,done);
					if done then
						sort_start <= '1';
						state <= STATE_SORTING;
					end if;

				-- sort the words in local RAM
				when STATE_SORTING =>
					sort_start <= '0';
					if sort_done = '1' then
						state  <= STATE_WRITE;
					end if;
					
				-- copy data from local memory to main memory
        -- len_reconos is shifted 2 bits to the left, as len_reconos contains length in words, but
        -- memif_read expects it to be in bytes
				when STATE_WRITE =>
					memif_write(i_ram,o_ram,i_memif,o_memif,X"00000000",addr,len_reconos(21 downto 0) & "00" ,done);
					if done then
						state <= STATE_ACK;
					end if;
				
				-- send mbox that signals that the sorting is finished
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, addr, ignore, done);
					if done then state <= STATE_THREAD_YIELD; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			
			end case;
		end if;
	end process;
	
end architecture;
