--
-- hwt_adpcm.vhd
-- Hardwarethread for MibenchHybrid Benchmark adpcm_hybird using adpcm module adpcm.vhd
-- 
-- Author:		Alexander Sprenger	<alsp@mail.upb.de>
-- History:		30.01.2013	Alexander Sprenger created

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_adpcm is
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
end entity;

architecture implementation of hwt_adpcm is
	type STATE_TYPE is (
					STATE_GET_DATA,
					STATE_WAIT_1,
					STATE_GET_INPADDR,
					STATE_INCR_ADDR_1,
					STATE_WAIT_2,
					STATE_GET_OUTPADDR,
					STATE_INCR_ADDR_2,
					STATE_WAIT_3,
					STATE_GET_COUNT,
					STATE_INCR_ADDR_3,
					STATE_WAIT_4,
					STATE_GET_ADPCM_STATE,
					STATE_COPY_DATA_TO_RAM,
					STATE_CALCULATE,
					STATE_WRITE,
					STATE_ACK_1,
					STATE_ACK_2,
					STATE_ACK_3,
					STATE_THREAD_EXIT
	);

	component adpcm is
		generic (
			G_AWIDTH : integer := 11;           -- in bits
			G_DWIDTH : integer := 32            -- in bits
		);

		port (
			clk   : in std_logic;
			reset : in std_logic;

			coder_decoder: in std_logic;  --1=>coder / 0=>decoder 
			count : in unsigned(0 to G_AWIDTH);

			-- local ram interface
			o_RAMAddr : out unsigned(0 to G_AWIDTH-1);
			o_RAMData : out unsigned(0 to G_DWIDTH-1);
			i_RAMData : in  unsigned(0 to G_DWIDTH-1);
			o_RAMWE   : out std_logic;

			-- ADPCM state
			i_state_valprev : in signed(15 downto 0) := (others => '0');
			i_state_index	 : in unsigned(7 downto 0) := (others => '0');
	 
			o_state_valprev : out signed(15 downto 0) := (others => '0');
			o_state_index	 : out unsigned(7 downto 0) := (others => '0');

			start     : in  std_logic;
			done      : out std_logic
		);
	end component;
	
	-- IMPORTANT: define number of BYTES in rq_recieve!!!! 
	constant RQ_RECV_LEN_BYTES	  : integer := 16;
	constant RQ_SEND_LEN_BYTES	  : integer := 4;
	
	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 16384;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

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

	signal o_RAMAddr_adpcm : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_adpcm : std_logic_vector(0 to 31);
	signal o_RAMWE_adpcm   : std_logic;
	signal i_RAMData_adpcm : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal ignore_natural : natural range 0 to 32;

	signal adpcm_start : std_logic := '0';
	signal adpcm_done  : std_logic := '0';
	
	signal cnt : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH downto 0);
	
	signal inp_addr : std_logic_vector(31 downto 0);
	signal outp_addr: std_logic_vector(31 downto 0);
	signal count_hwt: unsigned(31 downto 0);
	signal adpcm_state: std_logic_vector(31 downto 0);
	signal i_state_valprev_adpcm	: std_logic_vector(15 downto 0);
	signal i_state_index_adpcm	: std_logic_vector(7 downto 0);
	signal o_state_valprev_adpcm	: std_logic_vector(15 downto 0);
	signal o_state_index_adpcm	: std_logic_vector(7 downto 0);
	signal coder_decoder_adpcm	: std_logic;
	
begin
	
	-- local dual-port RAM
	local_ram_ctrl_1 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then
			if (o_RAMWE_reconos = '1') then
				local_ram(to_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
			else
				i_RAMData_reconos <= local_ram(to_integer(unsigned(o_RAMAddr_reconos)));
			end if;
		end if;
	end process;
			
	local_ram_ctrl_2 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then		
			if (o_RAMWE_adpcm = '1') then
				local_ram(to_integer(unsigned(o_RAMAddr_adpcm))) := o_RAMData_adpcm;
			else
				i_RAMData_adpcm <= local_ram(to_integer(unsigned(o_RAMAddr_adpcm)));
			end if;
		end if;
	end process;
	

	-- instantiate adpcm module
	adpcm_en_decoder : adpcm
		generic map (
			G_AWIDTH  => C_LOCAL_RAM_ADDRESS_WIDTH,
			G_DWIDTH  => 32
		)
		port map (
			clk       => OSFSL_Clk,
			reset     => rst,
			coder_decoder	=> coder_decoder_adpcm,
			count		 => unsigned(cnt),
			std_logic_vector(o_RAMAddr) => o_RAMAddr_adpcm,
			std_logic_vector(o_RAMData) => o_RAMData_adpcm,
			i_RAMData => unsigned(i_RAMData_adpcm),
			o_RAMWE   => o_RAMWE_adpcm,
			i_state_valprev 	=> signed(i_state_valprev_adpcm),
			i_state_index 	=> unsigned(i_state_index_adpcm),
			std_logic_vector(o_state_valprev) 	=> o_state_valprev_adpcm,
			std_logic_vector(o_state_index) 	=> o_state_index_adpcm,
			start     => adpcm_start,
			done      => adpcm_done
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
	reconos_fsm: process (OSFSL_Clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
		variable ptr	: std_logic_vector(0 to 31);
		
		variable in_count	: unsigned(21 downto 0);
		variable out_count: unsigned(21 downto 0);
		variable start_output_addr: unsigned(31 downto 0);
		
	begin		
		if rst = '1' then
			ptr := (others => '0');
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= STATE_GET_DATA;
			done  := False;
			data <= (others => '0');
			len_recieve <= std_logic_vector(to_unsigned(RQ_RECV_LEN_BYTES,32));
			len_send <= std_logic_vector(to_unsigned(RQ_SEND_LEN_BYTES,32));
			adpcm_start <= '0';
			inp_addr <= (others => '0');
			outp_addr <= (others => '0');
			count_hwt <= (others => '0');
			cnt <= (others => '0');
			coder_decoder_adpcm <= '1';
			
		elsif rising_edge(OSFSL_Clk) then
			cnt <= std_logic_vector(count_hwt(C_LOCAL_RAM_ADDRESS_WIDTH downto 0));
		
			case state is
				-- get Data via rq
				when STATE_GET_DATA =>
					in_count := (others  => '0');
					out_count := (others  => '0');
					start_output_addr := (others  => '0');
				
					osif_rq_receive(i_osif,o_osif,i_ram,o_ram,RQ_RECV,len_recieve,X"00000000",message_width,done);
					if done then
						if (unsigned(message_width) = 0) then
							--state <= STATE_THREAD_EXIT;
						else
							o_ram.addr <= (others => '0');
							state <= STATE_WAIT_1;
						end if;
					end if;
				
				when STATE_WAIT_1 =>
					state <= STATE_GET_INPADDR;
				
				-- get first value in reconos_queue -> input_addr
				when STATE_GET_INPADDR =>
					inp_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_1;
				
				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_1 =>
					if(inp_addr = X"FFFFFFFF") then
						state <= STATE_THREAD_EXIT;
					else
					   o_ram.addr <= X"00000001";
					   state <= STATE_WAIT_2;
					end if;
					
				when STATE_WAIT_2 =>
					state <= STATE_GET_OUTPADDR;

				-- get second value in reconos_queue -> output_addr
				when STATE_GET_OUTPADDR =>
					outp_addr <= i_ram.data;
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
					state <= STATE_INCR_ADDR_3;

				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_3 =>
					o_ram.addr <= X"00000003";
					state <= STATE_WAIT_4;
					
				when STATE_WAIT_4 =>
					state <= STATE_GET_ADPCM_STATE;

				-- get fourth value in reconos_queue -> adpcm_state
				when STATE_GET_ADPCM_STATE =>
					adpcm_state <= i_ram.data;
					
					--set counter
					if (count_hwt(31) = '1') then --encoder
						in_count(21 downto 1) := count_hwt(20 downto 0);  --count_hwt*2
						out_count(20 downto 0) := count_hwt(21 downto 1); --count_hwt/2
						start_output_addr(29 downto 0) := count_hwt(30 downto 1); --count_hwt/2 without highest bit 
					else
						in_count(20 downto 0) := count_hwt(21 downto 1); --count_hwt/2
						out_count(21 downto 1) := count_hwt(20 downto 0);  --count_hwt*2
						start_output_addr(27 downto 0) := count_hwt(30 downto 3); --count_hwt/8 without highest bit
					end if;
					
					if count_hwt(0) = '1' then		--((count_hwt mod 2) = 1) then
						start_output_addr := start_output_addr + 1;
						out_count := out_count + 1;
					end if;
					
					state <= STATE_COPY_DATA_TO_RAM;
				
				-- copy "count" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM =>
					memif_read(i_ram, o_ram, i_memif, o_memif, inp_addr, (others => '0'), "00" & std_logic_vector(in_count), done); 
					
					-- decode information
					coder_decoder_adpcm 	<= count_hwt(31);
					i_state_valprev_adpcm 	<= adpcm_state(31 downto 16);
					i_state_index_adpcm		<= adpcm_state(7 downto 0);
					
					if done then
						adpcm_start <= '1';
						state <= STATE_CALCULATE;
					end if;
	
				-- calculate the square root of the given values in local RAM
				when STATE_CALCULATE =>
					adpcm_start <= '0';

					if adpcm_done = '1' then
						state  <= STATE_WRITE;
					end if;
					
					
				-- copy data from local RAM to the given output_addr in main memory
				when STATE_WRITE =>
					memif_write(i_ram,o_ram,i_memif,o_memif,std_logic_vector(start_output_addr),outp_addr, "00" & std_logic_vector(out_count),done);
					if done then
						--adpcm_state <= o_state_valprev_adpcm & X"00" & o_state_index_adpcm; 
						state <= STATE_ACK_1;
						--state <= STATE_GET_DATA;
					end if;
				
				-- set the local RAM pointer to 0
				when STATE_ACK_1 =>
					adpcm_state <= o_state_valprev_adpcm & X"00" & o_state_index_adpcm; 
					o_ram.addr <= (others => '0');
					state <= STATE_ACK_2;
				
				-- write the adpcm_state to the local RAM
				when STATE_ACK_2 =>
					o_ram.we   <= '1';
					o_ram.data <= adpcm_state;
					state <= STATE_ACK_3;
				
				-- send rq with the output_addr as value, to signal that the calculating is finished
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
