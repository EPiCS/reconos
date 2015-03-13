--
-- hwt_short_term_synthesis_filtering.vhd
-- Hardwarthread for MiBenchHybrid Benchmark gsm_hybrid using short_term_synthesis_filtering module short_term_synthesis_filtering.vhd
-- 
-- Author:		Alexander Sprenger   <alsp@mail.upb.de>
-- History:		08.02.2013	Alexander Sprenger	created
--				07.03.2013	Alexander Sprenger	bugs fixed

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_short_term_synthesis_filtering is
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
		
		-- HWT reset
		rst           : in std_logic;
		clk           : in std_logic
	);
end entity;

architecture implementation of hwt_short_term_synthesis_filtering is
	type STATE_TYPE is (
					STATE_GET_DATA,
					STATE_WAIT_1,
					STATE_GET_GSMSTATEADDR,
					STATE_INCR_ADDR_1,
					STATE_WAIT_2,
					STATE_GET_RRPADDR,
					STATE_INCR_ADDR_2,
					STATE_WAIT_3,
					STATE_GET_COUNT,
					STATE_SET_START_ADDRESSES,
					STATE_INCR_ADDR_3,
					STATE_WAIT_4,
					STATE_GET_SRADDR,
					STATE_INCR_ADDR_4,
					STATE_WAIT_5,
					STATE_GET_WTADDR,
					STATE_COPY_DATA_TO_RAM_1,
					STATE_COPY_DATA_TO_RAM_2,
					STATE_COPY_DATA_TO_RAM_3,
					STATE_COPY_DATA_TO_RAM_4,
					STATE_CALCULATE,
					STATE_WRITE_1,
					STATE_WRITE_2,
					STATE_ACK_1,
					STATE_ACK_2,
					STATE_ACK_3,
					STATE_THREAD_EXIT
	);

	component short_term_synthesis_filtering is
		generic (
			G_AWIDTH : integer := 11;           -- Addresswidth in bits
			G_DWIDTH : integer := 32            -- Datawidth in bits
		);

		port (
			clk   : in std_logic;
			reset : in std_logic;

			count : in signed(0 to G_DWIDTH-1); 

			-- local ram interface
			o_RAMAddr : out unsigned(0 to G_AWIDTH-1);
			o_RAMData : out unsigned(0 to G_DWIDTH-1);
			i_RAMData : in  unsigned(0 to G_DWIDTH-1);
			o_RAMWE   : out std_logic;

			start     : in  std_logic;
			done      : out std_logic
		);
	end component;
	
	-- IMPORTANT: define number of BYTES in rq_recieve!!!! 
	constant RQ_RECV_LEN_BYTES	  : integer := 20;
	constant RQ_SEND_LEN_BYTES	  : integer := 4;
	
	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 512;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;
	
	--len of arrays to copy in byte
	constant C_LEN_OF_GSM_STATE 	: integer := 648;
	constant C_LEN_OF_RRP			: integer := 16; 
	
	constant C_RRP_START_ADDR	: integer := 162;
	constant C_WT_START_ADDR	: integer := 166;	

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	
	constant RQ_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant RQ_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal data     : std_logic_vector(31 downto 0);
	signal len_recieve	: std_logic_vector(31 downto 0);
	signal len_send      : std_logic_vector(31 downto 0);
	signal message_width : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_short_term_synthesis_filtering : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_short_term_synthesis_filtering : std_logic_vector(0 to 31);
	signal o_RAMWE_short_term_synthesis_filtering   : std_logic;
	signal i_RAMData_short_term_synthesis_filtering : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal ignore_natural : natural range 0 to 32;

	signal short_term_synthesis_filtering_start : std_logic := '0';
	signal short_term_synthesis_filtering_done  : std_logic := '0';
	
	signal cnt : std_logic_vector(31 downto 0);
	
	--function interface
	signal gsm_state_addr 	: std_logic_vector(31 downto 0);
	signal rrp_addr			: std_logic_vector(31 downto 0);
	signal count_hwt			: unsigned(31 downto 0);
	signal wt_addr				: std_logic_vector(31 downto 0);
	signal sr_addr				: std_logic_vector(31 downto 0);
	
	--cache
	signal temp_buffer_1	:std_logic_vector(31 downto 0);
	signal temp_buffer_2	:std_logic_vector(31 downto 0);
	
begin
	
	-- local dual-port RAM
	local_ram_ctrl_1 : process (clk) is
	begin
		if (rising_edge(clk)) then
			if (o_RAMWE_reconos = '1') then
				local_ram(to_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
			else
				i_RAMData_reconos <= local_ram(to_integer(unsigned(o_RAMAddr_reconos)));
			end if;
		end if;
	end process;
			
	local_ram_ctrl_2 : process (clk) is
	begin
		if (rising_edge(clk)) then		
			if (o_RAMWE_short_term_synthesis_filtering = '1') then
				local_ram(to_integer(unsigned(o_RAMAddr_short_term_synthesis_filtering))) := o_RAMData_short_term_synthesis_filtering;
			else
				i_RAMData_short_term_synthesis_filtering <= local_ram(to_integer(unsigned(o_RAMAddr_short_term_synthesis_filtering)));
			end if;
		end if;
	end process;
	

	-- instantiate short_term_synthesis_filtering module
	short_term_synthesis_filter : short_term_synthesis_filtering
		generic map (
			G_AWIDTH  => C_LOCAL_RAM_ADDRESS_WIDTH,
			G_DWIDTH  => 32
		)
		port map (
			clk       => clk,
			reset     => rst,
			count		 => signed(cnt),
			std_logic_vector(o_RAMAddr) => o_RAMAddr_short_term_synthesis_filtering,
			std_logic_vector(o_RAMData) => o_RAMData_short_term_synthesis_filtering,
			i_RAMData => unsigned(i_RAMData_short_term_synthesis_filtering),
			o_RAMWE   => o_RAMWE_short_term_synthesis_filtering,
			start     => short_term_synthesis_filtering_start,
			done      => short_term_synthesis_filtering_done
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
		
		variable len_of_wt		: integer range 0 to 255 := 120; 
		variable len_of_sr		: integer range 0 to 255 := 120;
		variable sr_start_addr	: integer range 0 to 255 := 226;	
		variable len_of_wt_for_memif : integer range 0 to 255 := 0;
		variable len_of_sr_for_memif : integer range 0 to 255 := 0;
	
		
	begin		
		--RESET
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);			
			state <= STATE_GET_DATA;
			done  := False;
			data <= (others => '0');
			len_recieve <= std_logic_vector(to_unsigned(RQ_RECV_LEN_BYTES,32));
			len_send <= std_logic_vector(to_unsigned(RQ_SEND_LEN_BYTES,32));
			short_term_synthesis_filtering_start <= '0';			
			gsm_state_addr 	<= (others => '0');
			rrp_addr				<= (others => '0');
			count_hwt			<= (others => '0');
			wt_addr				<= (others => '0');
			sr_addr				<= (others => '0');
			cnt <= (others => '0');
			
		elsif rising_edge(clk) then
			cnt <= std_logic_vector(count_hwt);
		
			case state is
				-- get Data via rq
				when STATE_GET_DATA =>				
					osif_rq_receive(i_osif,o_osif,i_ram,o_ram,RQ_RECV,len_recieve,X"00000000",message_width,done);
					if done then
						if (unsigned(message_width) = 0) then
							state <= STATE_THREAD_EXIT;
						else
							o_ram.addr <= (others => '0');
							state <= STATE_WAIT_1;
						end if;
					end if;
				
				when STATE_WAIT_1 =>
					state <= STATE_GET_GSMSTATEADDR;
				
				-- get first value in reconos_queue -> gsm_state_addr
				when STATE_GET_GSMSTATEADDR =>
					gsm_state_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_1;
				
				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_1 =>
					if(gsm_state_addr = X"FFFFFFFF") then
						state <= STATE_THREAD_EXIT;
					else
					   o_ram.addr <= X"00000001";
					   state <= STATE_WAIT_2;
					end if;
					
				when STATE_WAIT_2 =>
					state <= STATE_GET_RRPADDR;

				-- get second value in reconos_queue -> rrp_addr
				when STATE_GET_RRPADDR =>
					rrp_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_2;

				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_2 =>
					o_ram.addr <= X"00000002";
					state <= STATE_WAIT_3;
					
				when STATE_WAIT_3 =>
					state <= STATE_GET_COUNT;

				-- get third value in reconos_queue -> number of values to calculate (count)
				when STATE_GET_COUNT =>
					count_hwt <= unsigned(i_ram.data);
					len_of_wt := to_integer(unsigned(i_ram.data));
					len_of_sr := to_integer(unsigned(i_ram.data));
					state <= STATE_SET_START_ADDRESSES;
					
				-- compute start address of sr and the number of bytes to be copied using count_hwt
				when STATE_SET_START_ADDRESSES =>
					if(len_of_wt mod 2 = 1) then
						sr_start_addr := C_WT_START_ADDR + (len_of_wt/2) + 1;
						len_of_wt_for_memif := (len_of_wt+1)*2;
						len_of_sr_for_memif := (len_of_sr+1)*2;
					else
						sr_start_addr := C_WT_START_ADDR + (len_of_wt/2);
						len_of_wt_for_memif := (len_of_wt)*2;
						len_of_sr_for_memif := (len_of_sr)*2;
					end if;
					state <= STATE_INCR_ADDR_3;

				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_3 =>
					o_ram.addr <= X"00000003";
					state <= STATE_WAIT_4;
					
				when STATE_WAIT_4 =>
					state <= STATE_GET_WTADDR;

				-- get fourth value in reconos_queue -> wt_addr
				when STATE_GET_WTADDR =>
					wt_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_4;
					
				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_4 =>
					o_ram.addr <= X"00000004";
					state <= STATE_WAIT_5;
					
				when STATE_WAIT_5 =>
					state <= STATE_GET_SRADDR;
					
				-- get fifth value in reconos_queue -> sr_addr
				when STATE_GET_SRADDR =>
					sr_addr <= i_ram.data;					
					state <= STATE_COPY_DATA_TO_RAM_1;
				
				-- copy "C_LEN_OF_GSM_STATE" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM_1 =>
					memif_read(i_ram, o_ram, i_memif, o_memif, gsm_state_addr, (others => '0'), std_logic_vector(to_unsigned(C_LEN_OF_GSM_STATE,24)), done);
					if done then
						state <= STATE_COPY_DATA_TO_RAM_2;
					end if;
				
				-- copy "C_LEN_OF_RRP" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM_2 =>
					memif_read(i_ram, o_ram, i_memif, o_memif, rrp_addr, std_logic_vector(to_unsigned(C_RRP_START_ADDR,32)), std_logic_vector(to_unsigned(C_LEN_OF_RRP,24)), done);
					if done then
						state <= STATE_COPY_DATA_TO_RAM_3;
					end if;
				
				-- copy "len_of_wt" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM_3 =>
					memif_read(i_ram, o_ram, i_memif, o_memif, wt_addr, std_logic_vector(to_unsigned(C_WT_START_ADDR,32)), std_logic_vector(to_unsigned(len_of_wt_for_memif,24)), done);
					if done then
						state <= STATE_COPY_DATA_TO_RAM_4;
					end if;
					
				-- copy "len_of_sr" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM_4 =>
					memif_read(i_ram, o_ram, i_memif, o_memif, sr_addr, std_logic_vector(to_unsigned(sr_start_addr,32)), std_logic_vector(to_unsigned(len_of_sr_for_memif,24)), done);
					if done then
						short_term_synthesis_filtering_start <= '1';
						state <= STATE_CALCULATE;
					end if;				
	
				-- calculate the given values in local RAM
				when STATE_CALCULATE =>
					short_term_synthesis_filtering_start <= '0';

					if short_term_synthesis_filtering_done = '1' then
						state  <= STATE_WRITE_1;
					end if;
					
				-- copy data from local RAM to the given output_addr in main memory
				when STATE_WRITE_1 =>
					memif_write(i_ram,o_ram,i_memif,o_memif,(others => '0'),gsm_state_addr, std_logic_vector(to_unsigned(C_LEN_OF_GSM_STATE,24)),done);
					if done then
						state <= STATE_WRITE_2;
					end if;

				-- copy data from local RAM to the given output_addr in main memory
				when STATE_WRITE_2 =>
					memif_write(i_ram,o_ram,i_memif,o_memif,std_logic_vector(to_unsigned(sr_start_addr,32)),sr_addr, std_logic_vector(to_unsigned(len_of_sr_for_memif,24)),done);
					if done then
						state <= STATE_ACK_1;
					end if;
				
				-- set the local RAM pointer to 0
				when STATE_ACK_1 =>
					o_ram.addr <= (others => '0');
					state <= STATE_ACK_2;
				
				-- write the gsm_state_addr to the local RAM
				when STATE_ACK_2 =>
					o_ram.we   <= '1';
					o_ram.data <= gsm_state_addr;
					state <= STATE_ACK_3;
				
				-- send rq with the gsm_state_addr as value, to signal that the calculating is finished
				when STATE_ACK_3 =>
					osif_rq_send(i_osif, o_osif, i_ram, o_ram, RQ_SEND, len_send, X"00000000", ignore, done);
					if done then 
						state <= STATE_GET_DATA; 
					end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);			

			end case;
		end if;
	end process;	
end architecture;
