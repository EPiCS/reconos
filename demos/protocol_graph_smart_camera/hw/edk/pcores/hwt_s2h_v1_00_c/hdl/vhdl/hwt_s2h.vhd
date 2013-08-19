library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;


entity hwt_s2h is
	--generic (
	--	destination	: std_logic_vector(5 downto 0)
	--);
	port (
		-- OSIF FSL
	--	OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
	--	OSFSL_Rst       : in  std_logic;
	--	OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
	--	OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		--FIFO32_S_Clk : out std_logic;
		--FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset
		rst           : in std_logic;
		clk		: in std_logic;
		switch_data_rdy		: in  std_logic;
		switch_data		: in  std_logic_vector(dataWidth downto 0);
		thread_read_rdy	 	: out std_logic;
		switch_read_rdy		: in  std_logic;
		thread_data		: out std_logic_vector(dataWidth downto 0);
		thread_data_rdy 	: out std_logic
	);

end hwt_s2h;

architecture implementation of hwt_s2h is
	type STATE_TYPE is ( STATE_INIT, STATE_GET_LEN, STATE_READ, STATE_WAIT, STATE_WRITE, STATE_PULL, STATE_PUT, STATE_PUT2,STATE_PUT3, STATE_PUT4, STATE_THREAD_EXIT
	);

	-- PUT YOUR OWN COMPONENTS HERE

    -- END OF YOUR OWN COMPONENTS
	

    -- ADD YOUR CONSTANTS, TYPES AND SIGNALS BELOW

	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal data     : std_logic_vector(31 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 2048;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	signal o_RAMAddr_sender : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_sender : std_logic_vector(0 to 31);
	signal o_RAMWE_sender   : std_logic;
	signal i_RAMData_sender : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	signal send_control_addr : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal send_packet_addr  : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal send_packet_addr_offset  : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal send_packet_data  : std_logic_vector(0 to 31);
	signal send_packet_we    : std_logic;

	signal send_packet_clear_offset : std_logic;

	signal send_control_en   : std_logic;
	signal send_control_done : std_logic;

	signal send_packet_en   : std_logic;
	signal send_packet_done : std_logic;

	shared variable local_ram : LOCAL_MEMORY_T;


	type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state 	    : testing_state_t;
	signal testing_state_next   : testing_state_t;

	--type sending_state_t is (S_STATE_INIT, S_STATE_SOF, S_STATE_DATA, S_STATE_EOF, S_STATE_WAIT);
	--signal sending_state		: sending_state_t;
	--signal sending_state_next	: sending_state_t;

	type SENDING_STATE_TYPE_T is (STATE_IDLE, STATE_READ_LEN_WAIT_A, STATE_WAIT_IDP_A, STATE_READ_LEN,STATE_SRCIDP, STATE_DSTIDP, STATE_WAIT_SOF,
						STATE_SEND_SOF, STATE_SEND_SECOND, STATE_SEND_THIRD, STATE_SEND_FOURTH, 
						STATE_SEND_DATA_1, STATE_SEND_DATA_2, STATE_SEND_DATA_3, STATE_SEND_DATA_4,
						 STATE_SEND_EOF_1, STATE_SEND_EOF_2, STATE_SEND_EOF_3, STATE_SEND_EOF_4, STATE_WAIT
	);

	signal sending_state : SENDING_STATE_TYPE_T;
	
	signal rx_packet_count 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count_next : std_logic_vector(31 downto 0);

	signal tx_testing_state 	    : testing_state_t;
	signal tx_testing_state_next   : testing_state_t;

	signal tx_packet_count 	    : std_logic_vector(31 downto 0);
	signal tx_packet_count_next : std_logic_vector(31 downto 0);
	
	signal rx_ll_dst_rdy_local	: std_logic;

	signal tx_ll_sof	: std_logic;
	signal tx_ll_eof	: std_logic;
	signal tx_ll_data	: std_logic_vector(7 downto 0);
	signal tx_ll_src_rdy	: std_logic;
	signal tx_ll_dst_rdy	: std_logic;

	signal rx_ll_sof	: std_logic;
	signal rx_ll_eof	: std_logic;
	signal rx_ll_data	: std_logic_vector(7 downto 0);
	signal rx_ll_src_rdy	: std_logic;
	signal rx_ll_dst_rdy	: std_logic;

	signal payload_count : integer range 0 to 1500;
	signal payload_count_next : integer range 0 to 1500;

	--signal destination	: std_logic_vector(0 to 5);
	signal global_addr : std_logic_vector(0 to 3);
	signal local_addr : std_logic_vector(0 to 1);
	signal data_ready : std_logic;
	signal packets_sent : std_logic;

	signal payload_len : std_logic_vector(15 downto 0);
	
	signal total_packet_len : std_logic_vector(15 downto 0);
	signal debug_packet_len : std_logic_vector(31 downto 0);
	signal debug_packet_len2 : std_logic_vector(31 downto 0);
	signal packet_num : std_logic_vector(31 downto 0); -- number of all packets to be transfered
	signal packet_cur : std_logic_vector(31 downto 0); -- current packet no.
	
	signal tx_data_word : std_logic_vector(0 to 31);
	
	signal base_addr : std_logic_vector(31 downto 0);
	--signal base_addr_answer : std_logic_vector(31 downto 0);
	signal len		: std_logic_vector(31 downto 0);
	signal data_from_ram : std_logic_vector(31 downto 0);
	signal direction : std_logic;
	signal priority : std_logic_vector(0to 1);
	signal latencyCritical : std_logic;
	signal srcIdp : std_logic_vector(0 to 31);
	signal dstIdp : std_logic_vector(0 to 31);
begin
	

    -- PUT YOUR OWN INSTANCES HERE

	decoder_inst : packetDecoder
	port map (
		clk 	=> clk,
		reset 	=> rst,

		-- Signals from the switch
		switch_data_rdy		=> switch_data_rdy,
		switch_data		=> switch_data,
		thread_read_rdy		=> thread_read_rdy,

		-- Decoded values of the packet
		noc_rx_sof		=> rx_ll_sof,		-- Indicates the start of a new packet
		noc_rx_eof		=> rx_ll_eof,		-- Indicates the end of the packet
		noc_rx_data		=> rx_ll_data,		-- The current data byte
		noc_rx_src_rdy		=> rx_ll_src_rdy, 	-- '1' if the data are valid, '0' else
		noc_rx_direction	=> open,		-- '1' for egress, '0' for ingress
		noc_rx_priority		=> open,		-- The priority of the packet
		noc_rx_latencyCritical	=> open,		-- '1' if this packet is latency critical
		noc_rx_srcIdp		=> open,		-- The source IDP
		noc_rx_dstIdp		=> open,		-- The destination IDP
		noc_rx_dst_rdy		=> rx_ll_dst_rdy	-- Read enable for the functional block
	);
	
	encoder_inst : packetEncoder
	port map(
		clk 				=> clk,					
		reset 				=> rst,		
		-- Signals to the switch
		switch_read_rdy  		=> switch_read_rdy, 		
		thread_data  			=> thread_data,		
		thread_data_rdy 		=> thread_data_rdy,
		-- Decoded values of the packet
		noc_tx_sof  			=> tx_ll_sof, 		
		noc_tx_eof  			=> tx_ll_eof,
		noc_tx_data	 			=> tx_ll_data,		
		noc_tx_src_rdy 	 		=> tx_ll_src_rdy,		
		noc_tx_globalAddress  	=> global_addr, --destination(5 downto 2), --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress 	=> local_addr, --destination(1 downto 0), --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	=> direction, 		
		noc_tx_priority 	 	=> priority,		
		noc_tx_latencyCritical 	=> latencyCritical,	
		noc_tx_srcIdp 			=> srcIdp,	
		noc_tx_dstIdp 			=> dstIdp,
		noc_tx_dst_rdy	 		=> tx_ll_dst_rdy
	);
	
    -- END OF YOUR OWN INSTANCES

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
			if (o_RAMWE_sender = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_sender))) := o_RAMData_sender;
			else
				i_RAMData_sender <= local_ram(conv_integer(unsigned(o_RAMAddr_sender)));
			end if;
		end if;
	end process;


	fsl_setup(
		i_osif,
		o_osif,
		--OSFSL_Clk,
		--OSFSL_Rst,
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
	--	OSFSL_Clk,
	--	FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
	--	FIFO32_M_Clk,
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
	
    -- PUT YOUR OWN PROCESSES HERE
	
	--we are always ready and don't send any packets

	rx_ll_dst_rdy <= rx_ll_dst_rdy_local;
	rx_ll_dst_rdy_local <= '1';

	--for now we send everything to destination 0
--	destination(5 downto 2) <= "0001"; --(others => '0');
--	destination(1 downto 0) <= "00"; --back to sw




	send_control_proc : process (send_control_en,clk, rst)
		variable step : natural range 0 to 5;
	begin
		if rst = '1' or send_control_en = '0' then
			send_control_addr <= (others => '0');
			send_control_done <= '0';
			send_packet_en    <= '0';
			send_packet_clear_offset <= '1'; -- set initial offset to local ram address 0x1 (for send_packet_proc) 
			packet_cur <= (others  => '0');
			packet_num <= (others  => '0');
			step := 0;
		elsif rising_edge(clk) then
			send_packet_clear_offset <= '0';
			send_packet_en           <= '0';
			send_control_done        <= '0';
			case step is 
				when 0 => -- read #packets to be send (1/3): set addr
					packet_cur <= (others  => '0');
					send_control_addr <= (others => '0');
					step := step + 1;

				when 1 => -- read #packets to be send (2/3): wait for 1 clock cycle
					step := step + 1;

				when 2 => -- read #packets to be send (3/3): get information from local memory
					packet_num <= send_control_data;
					step := step + 1;

				when 3 => -- check if more packets need to be send, if not 
					if (packet_cur < packet_num) then
						packet_cur <= packet_cur + 1;
						send_packet_en <= '1';
						step := step + 1;
					else
						step := step + 2;
					end if;

				when 4 => -- wait until next packet is sent
					send_packet_en <= '1';
					if (send_packet_done = '1') then
						send_packet_en <= '0';
						step := step - 1;
					end if;

				when 5 => -- sending packets done
					send_control_done <= '1';

				when others =>
					step := 0;
			end case;
		end if;
	end process;


	send_packet_proc : process (send_packet_en,send_packet_clear_offset,clk, rst)
		variable step : natural range 0 to 15;
	begin
		if rst = '1' or send_packet_en = '0' then
			send_packet_addr <= (others => '0');
			tx_ll_src_rdy    <= '0';
			tx_ll_data       <= (others => '0');
			tx_ll_sof        <= '0';
			tx_ll_eof        <= '0';
			payload_len      <= (others => '0');
			payload_count    <= 0;		
			global_addr      <= (others  => '0');
			local_addr       <= (others  => '0');
			priority         <= (others  => '0');
			direction        <= '0';
			latencycritical  <= '0';
			srcIdp           <= (others => '0');
			dstIdp           <= (others => '0');
			if rst = 1 or send_packet_clear_offset = '1' then
				send_packet_addr_offset <= "00000000001";
			end if;
			send_packet_done <= '0';
			step := 0;
		elsif rising_edge(clk) then
			send_packet_done <= '0';
			tx_ll_data <= (others => '0');
			tx_ll_sof <= '0';
			tx_ll_eof <= '0';
			tx_ll_src_rdy <= '1';
			case step is 
				when 0 => -- read header (1/5): set ram adress
					send_packet_addr <= send_packet_addr_offset; -- first header addr
					step := step + 1;

				when 1 => -- read header (2/5): wait 1 clock cycle
					send_packet_addr <= send_packet_addr + 1;
					step := step + 1;

				when 2 => -- read header (3/5): get switch/fb_block adresses, playload length, and more information
					global_addr <= send_packet_data(0 to 3);
					local_addr  <= send_packet_data(4 to 5);
					priority    <= send_packet_data(6 to 7);
					direction   <= send_packet_data(8);
					latencycritical <= send_packet_data(9);
					payload_len <= send_packet_data(16 to 31); 
					payload_count <= 0;
					send_packet_addr <= send_packet_addr + 1;
					step := step + 1;

				when 3 => -- read header (4/5): get source IDP
					send_packet_addr <= send_packet_addr + 1; -- first payload addr
					srcIdp <= send_packet_data;
					step := step + 1;

				when 4 => -- read header (5/5): get destination IDP
					dstIdp <= send_packet_data;
					step := step + 1;

				when 5 => -- sof: data (byte 1 of 4)
					tx_ll_sof <= '1';
					if tx_ll_dst_rdy = '1' then
						tx_ll_data    <= send_packet_data(0 to 7);
						payload_count <= payload_count + 1;
						step := step + 1;
					end if;

				when 6 => -- data (byte 2 of 4)
					if tx_ll_dst_rdy = '1' then
						tx_ll_data    <= send_packet_data(8 to 15);
						payload_count <= payload_count + 1;
						if (payload_count + 2 < payload_len) then
							step := step + 1;
						else
							step := step + 4;
						end if
					end if;

				when 7 => -- data (byte 3 of 4)
					if tx_ll_dst_rdy = '1' then
						tx_ll_data    <= send_packet_data(16 to 23);
						payload_count <= payload_count + 1;
						if (payload_count + 2 < payload_len) then
							-- start TODO: if tx_ll_dst_rdy is not always = '1' (while transmitting a full packet), 
							-- the following line cause a faulty behavior:
							send_packet_addr <= send_packet_addr + 1;
							-- end TODO
							step := step + 1;
						else
							step := step + 4;
						end if
					end if;

				when 8 => -- data (byte 4 of 4)
					if tx_ll_dst_rdy = '1' then
						tx_ll_data    <= send_packet_data(24 to 31);
						payload_count <= payload_count + 1;
						if (payload_count + 2 < payload_len) then
							step := step + 1;
						else
							step := step + 4;
						end if
					end if;

				when 9 => -- data (byte 1 of 4)
					if tx_ll_dst_rdy = '1' then
						tx_ll_data    <= send_packet_data(0 to 7);
						payload_count <= payload_count + 1;
						if (payload_count + 2 < payload_len) then
							step := step - 3;
						else
							step := step + 4;
						end if
					end if;

				when 10 => -- eof (byte 3 of 4)
					tx_ll_eof <= '1';
					if tx_ll_dst_rdy = '1' then
						tx_ll_data       <= send_packet_data(16 to 23);
						payload_count    <= payload_count + 1;
						send_packet_addr <= send_packet_addr + 1;
					end if;

				when 11 => -- eof (byte 4 of 4)
					tx_ll_eof <= '1';
					if tx_ll_dst_rdy = '1' then
						tx_ll_data       <= send_packet_data(24 to 31);
						payload_count    <= payload_count + 1;
						send_packet_addr <= send_packet_addr + 1;
					end if;

				when 12 => -- eof (byte 1 of 4)
					tx_ll_eof <= '1';
					if tx_ll_dst_rdy = '1' then
						tx_ll_data       <= send_packet_data(0 to 7);
						payload_count    <= payload_count + 1;
						send_packet_addr <= send_packet_addr + 1;
					end if;

				when 13 => -- eof (byte 2 of 4) 
					tx_ll_eof <= '1';
					if tx_ll_dst_rdy = '1' then
						tx_ll_data       <= send_packet_data(8 to 15);
						payload_count    <= payload_count + 1;
						send_packet_addr <= send_packet_addr + 1;
						step := step + 1;
					end if;

				when 14 => -- set new offset in local ram for next packet
					send_packet_addr_offset <= send_packet_addr;
					step := step + 1;

				when 15 => -- successfully send entire packet
					send_packet_done <= '1';

				when others =>
					step := 0;
			end case;
		end if;
	end process;


	-- ram mux
	mux_proc: process(send_control_en,send_packet_en,send_packet_addr,send_control_addr,i_RAMData_sender);
		variable addr : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	begin
		if send_packet_en = '1'  then
			addr := send_packet_addr;
		elsif send_control_en = '1' then
			addr := send_control_addr;				
		else
			addr := (others => '0');
		end if;       
		o_RAMAddr_sender  <= addr;
		send_packet_data  <= i_RAMData_sender;
		send_control_data <= i_RAMData_sender;
		--we don't write anything
		o_RAMWE_sender   <= '0';
		o_RAMData_sender <= (others => '0');
	end process;


	--count all tx sof packets
	test_counting : process(tx_ll_sof, tx_ll_src_rdy, tx_ll_dst_rdy, rx_packet_count, testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    rx_packet_count_next <= rx_packet_count;
    	    testing_state_next <= testing_state;
	    case testing_state is
        	when T_STATE_INIT =>
		    rx_packet_count_next <= (others => '0');
		    testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if tx_ll_src_rdy = '1' and tx_ll_sof = '1' and tx_ll_dst_rdy = '1' then
			tmp := unsigned(rx_packet_count) + 1;
			rx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
	    end case;
	end process;

	--count all tx eof packets
	tx_test_counting : process(tx_ll_eof, tx_ll_src_rdy, tx_ll_dst_rdy, tx_packet_count, tx_testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    tx_packet_count_next <= tx_packet_count;
    	    tx_testing_state_next <= tx_testing_state;
	    case tx_testing_state is
        	when T_STATE_INIT =>
		    tx_packet_count_next <= (others => '0');
		    tx_testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if tx_ll_src_rdy = '1' and tx_ll_eof = '1' and tx_ll_dst_rdy = '1' then
			tmp := unsigned(tx_packet_count) + 1;
			tx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    tx_testing_state_next <= T_STATE_INIT;
	    end case;
	end process;


	--creates flipflops
	memzing: process(clk, rst) is
	begin
	    if rst = '1' then
	        rx_packet_count <= (others => '0');
	        testing_state <= T_STATE_INIT;
     		tx_packet_count <= (others => '0');
	        tx_testing_state <= T_STATE_INIT;
	--	sending_state <= S_STATE_INIT;
	--	payload_count <= 0;
	    elsif rising_edge(clk) then
	        rx_packet_count <= rx_packet_count_next;
	        testing_state <= testing_state_next;
  		tx_packet_count <= tx_packet_count_next;
	        tx_testing_state <= tx_testing_state_next;
	--	sending_state <= sending_state_next;
	--	payload_count <= payload_count_next;
	    end if;
	end process;


	-- END OF YOUR OWN PROCESSES
 -- ADJUST THE RECONOS_FSM TO YOUR NEEDS.		
	-- os and memory synchronisation state machine
	reconos_fsm: process (clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			-- RESET YOUR OWN SIGNALS HERE
			state <= STATE_INIT;
			done := False;
			base_addr <= (others => '0');
			len <= (others => '0');
			--data_ready <= '0';
			send_control_en <= '0';
			--base_addr_answer <= (others => '0');

		elsif rising_edge(clk) then
			--data_ready <= '0';
			send_control_en <= '0';
			case state is

                -- EXAMPLE STATE MACHINE - ADD YOUR STATES AS NEEDED

				-- Get some data
				when STATE_INIT =>
					--base_addr_answer <= (others => '0');
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, base_addr, done);
					if done then
						state <= STATE_GET_LEN;
						base_addr <= base_addr(31 downto 2) & "00";
					end if;
				
				when STATE_GET_LEN =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, len, done);
					if done then
						if (len = X"FFFFFFFF") then
							state <= STATE_EXIT;
						else
							state <= STATE_READ;
							--base_addr_answer <= base_addr + 2048; --conv_std_logic_vector(2048, 32); --base_addr + len;
						end if;
					end if;

				when STATE_READ =>
					memif_read(i_ram,o_ram,i_memif,o_memif, base_addr, X"00000000", unsigned(len(23 downto 0)), done); 
					if done then
						state <= STATE_WAIT;
					end if;

				when STATE_WAIT =>
					-- data_ready <= '1';
					-- if packets_sent = '1' then
					--	data_ready <= '0';
					--	len  <= (others  => '0');
					--	state <= STATE_PUT; --STATE_WRITE;
					-- end if;
					send_control_en <= '1';
					if send_control_done = '1' then
						send_control_en <= '0';
						state <= STATE_PUT;
					end if;
					
--				when STATE_WRITE =>
--					memif_write(i_ram, o_ram, i_memif, o_memif, X"00000000", base_addr_answer, unsigned(len(23 downto 0)) + 4, done);
--					if done then 
--						state <= STATE_PUT;
--					end if;
--				when STATE_PULL =>
--					memif_fifo_pull(i_memif,o_memif, data_from_ram, done);
--					if done then
--						state <= STATE_PUT;
--					end if;
					
				-- Echo the data
				when STATE_PUT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, X"0000" & total_packet_len, ignore, done);
				--	osif_mbox_put(i_osif, o_osif, MBOX_SEND, len, ignore, done);

					if done then state <= STATE_GET_LEN; end if;
				
--				when STATE_PUT2 =>
--					osif_mbox_put(i_osif, o_osif, MBOX_SEND, debug_packet_len2, ignore, done);
--					if done then state <= STATE_PUT3; end if;
--					
--				when STATE_PUT3 =>
--					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count, ignore, done);
--					if done then state <= STATE_PUT4; end if;
--				
--				when STATE_PUT4 =>
--					osif_mbox_put(i_osif, o_osif, MBOX_SEND, tx_packet_count, ignore, done);
--					if done then state <= STATE_GET_LEN; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
				when others =>
					state <= STATE_INIT;
			
			end case;
		end if;
	end process;



end architecture;
