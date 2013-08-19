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

entity hwt_smart_cam is
--	generic (
--		destination	: std_logic_vector(5 downto 0);
--		sender		: std_logic
--	);
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
		rst : in std_logic;
		clk : in std_logic;

		switch_data_rdy		: in  std_logic;
		switch_data		: in  std_logic_vector(dataWidth downto 0);
		thread_read_rdy	 	: out std_logic;
		switch_read_rdy		: in  std_logic;
		thread_data		: out std_logic_vector(dataWidth downto 0);
		thread_data_rdy 	: out std_logic;

		-- for smart camera
		video_in_clk                : in  std_logic;
		video_in_vblank             : in  std_logic;
		video_in_hblank             : in  std_logic;
		video_in_de                 : in  std_logic;
		video_in_data               : in  std_logic_vector(23 downto 0);

		switch_camera_1             : in  std_logic;
		switch_camera_2             : in  std_logic;
		switch_camera_3             : in  std_logic;
		switch_camera_4             : in  std_logic;

		button_up                   : in  std_logic;
		button_down                 : in  std_logic;
		button_size                 : in  std_logic;
		button_left                 : in  std_logic;
		button_right                : in  std_logic
	);

end hwt_smart_cam;

architecture implementation of hwt_smart_cam is
	type STATE_TYPE is ( STATE_GET, STATE_PUT, STATE_PUT2, STATE_PUT3, STATE_PUT4, STATE_PUT5, STATE_THREAD_EXIT );

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

	type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state 	    : testing_state_t;
	signal testing_state_next   : testing_state_t;

	type sending_state_t is (S_STATE_INIT, S_STATE_SOF, S_STATE_DATA, S_STATE_EOF, S_STATE_WAIT);
	signal sending_state		: sending_state_t;
	signal sending_state_next	: sending_state_t;


	signal rx_packet_count 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count_next : std_logic_vector(31 downto 0);

	signal rx_packet_count1 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count1_next : std_logic_vector(31 downto 0);
	signal rx_packet_count2 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count2_next : std_logic_vector(31 downto 0);
	signal rx_packet_count3 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count3_next : std_logic_vector(31 downto 0);
	
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

	signal direction_enc : std_logic;
	signal priority_enc : std_logic_vector(1 downto 0);
	signal latency_critical_enc : std_logic;
	signal srcIdp_enc : std_logic_vector(31 downto 0);
	signal dstIdp_enc : std_logic_vector(31 downto 0);
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);
	
	signal direction_dec : std_logic;
	signal priority_dec : std_logic_vector(1 downto 0);
	signal latency_critical_dec : std_logic;
	signal srcIdp_dec : std_logic_vector(31 downto 0);
	signal dstIdp_dec : std_logic_vector(31 downto 0);

	signal tx_ll_sof_n  	   : std_logic;         ----active low 
	signal tx_ll_eof_n      : std_logic;         ----active low 
	signal tx_ll_src_rdy_n  : std_logic;         ----active low  
	signal tx_ll_dst_rdy_n  : std_logic;         ----active low
	signal rx_ll_sof_n       : std_logic;         ----active low
	signal rx_ll_eof_n       : std_logic;         ----active low
	signal rx_ll_src_rdy_n   : std_logic;         ----active low
	signal rx_ll_dst_rdy_n   : std_logic;         ----active low


	component smart_cam is
	generic
	(
		YUV_DATA_DWIDTH                   : integer              := 16;
		RGB_DATA_DWIDTH                   : integer              := 24;
		FRAME_WIDTH                       : integer              := 1920;
		FRAME_HEIGHT                      : integer              := 1080
	);
	port
	(
		clk                         : in  std_logic;
		rst                         : in  std_logic;
		video_in_clk                : in  std_logic;
		video_in_vblank 	    		 : in  std_logic;
		video_in_hblank             : in  std_logic;
		video_in_de 		    		 : in  std_logic;
		video_in_data               : in  std_logic_vector(RGB_DATA_DWIDTH-1 downto 0);
		tx_ll_sof_n  	    		 : out std_logic;          ----active low 
		tx_ll_eof_n              : out std_logic;          ----active low 
		tx_ll_data               : out std_logic_vector(7 downto 0);
		tx_ll_src_rdy_n          : out std_logic;          ----active low  
		tx_ll_dst_rdy_n          : in  std_logic;          ----active low
		rx_ll_sof_n               : in  std_logic;          ----active low
		rx_ll_eof_n               : in  std_logic;          ----active low
		rx_ll_data                : in  std_logic_vector(7 downto 0);
		rx_ll_src_rdy_n           : in  std_logic;          ----active low
		rx_ll_dst_rdy_n           : out std_logic;          ----active low
		switch_camera_1             : in  std_logic;
		switch_camera_2             : in  std_logic;
		switch_camera_3             : in  std_logic;
		switch_camera_4             : in  std_logic;
		button_up                   : in  std_logic;
		button_down                 : in  std_logic;
		button_size                 : in  std_logic;
		button_left                 : in  std_logic;
		button_right                : in  std_logic
	);
	end component;

begin
	
	decoder_inst : packetDecoder
	port map (
		clk 		=> clk,
		reset 	=> rst,
		-- Signals from the switch
		switch_data_rdy	=> switch_data_rdy,
		switch_data	=> switch_data,
		thread_read_rdy	=> thread_read_rdy,
		-- Decoded values of the packet
		noc_rx_sof		=> rx_ll_sof,		-- Indicates the start of a new packet
		noc_rx_eof		=> rx_ll_eof,		-- Indicates the end of the packet
		noc_rx_data		=> rx_ll_data,		-- The current data byte
		noc_rx_src_rdy		=> rx_ll_src_rdy, 	-- '1' if the data are valid, '0' else
		noc_rx_direction	=> direction_dec, 		-- '1' for egress, '0' for ingress
		noc_rx_priority	=> priority_dec,		-- The priority of the packet
		noc_rx_latencyCritical	=> latency_critical_dec,		-- '1' if this packet is latency critical
		noc_rx_srcIdp		=> srcIdp_dec,		-- The source IDP
		noc_rx_dstIdp		=> dstIdp_dec,		-- The destination IDP
		noc_rx_dst_rdy		=> rx_ll_dst_rdy	-- Read enable for the functional block
	);
	
	encoder_inst : packetEncoder
	port map(
		clk 				=> clk,					
		reset 			=> rst,		
		-- Signals to the switch
		switch_read_rdy  		=> switch_read_rdy, 		
		thread_data  			=> thread_data,		
		thread_data_rdy 		=> thread_data_rdy,
		-- Decoded values of the packet
		noc_tx_sof  			=> tx_ll_sof, 		
		noc_tx_eof  			=> tx_ll_eof,
		noc_tx_data	 			=> tx_ll_data,		
		noc_tx_src_rdy 	 		=> tx_ll_src_rdy,		
		noc_tx_globalAddress  		=> global_addr, --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress  		=> local_addr, --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	=> direction_enc,		
		noc_tx_priority 	 	=> priority_enc,		
		noc_tx_latencyCritical  	=> latency_critical_enc,	
		noc_tx_srcIdp 			=> srcIdp_enc,	
		noc_tx_dstIdp 			=> dstIdp_enc,
		noc_tx_dst_rdy	 		=> tx_ll_dst_rdy
	);
	

 
	-- instantiate smart camera code
	smart_cam_inst : smart_cam
		generic map ( YUV_DATA_DWIDTH=>16, RGB_DATA_DWIDTH=>24, FRAME_WIDTH=>1920, FRAME_HEIGHT=>1080)
		port map (clk=>clk,rst=>rst,video_in_clk=>video_in_clk,video_in_vblank=>video_in_vblank,video_in_hblank=>video_in_hblank,video_in_de=>video_in_de,video_in_data=>video_in_data,
			tx_ll_sof_n=>tx_ll_sof_n,tx_ll_eof_n=>tx_ll_eof_n,tx_ll_data=>tx_ll_data,tx_ll_src_rdy_n=>tx_ll_src_rdy_n,tx_ll_dst_rdy_n=>tx_ll_dst_rdy_n,
			rx_ll_sof_n=>rx_ll_sof_n,rx_ll_eof_n=>rx_ll_eof_n,rx_ll_data=>rx_ll_data,rx_ll_src_rdy_n=>rx_ll_src_rdy_n,rx_ll_dst_rdy_n=>rx_ll_dst_rdy_n,
			switch_camera_1=>switch_camera_1,switch_camera_2=>switch_camera_2,switch_camera_3=>switch_camera_3,switch_camera_4=>switch_camera_4,
			button_up=>button_up,button_down=>button_down,button_size=>button_size,button_left=>button_left,button_right=>button_right
		);

	tx_ll_sof <= not tx_ll_sof_n;
	tx_ll_eof <= not tx_ll_eof_n;
	tx_ll_src_rdy <= not tx_ll_src_rdy_n;
	tx_ll_dst_rdy_n <= not tx_ll_dst_rdy;

	rx_ll_sof_n      <= not rx_ll_sof;
	rx_ll_eof_n      <= not rx_ll_eof;
	rx_ll_src_rdy_n  <= not rx_ll_src_rdy;
	rx_ll_dst_rdy <= not rx_ll_dst_rdy_n;

	priority_enc         <= "00";
	direction_enc        <= '1';
	latency_critical_enc <= '0';
	srcIdp_enc           <= X"00000000";
	dstIdp_enc           <= X"00000000";

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
	
	--count all rx packets
	test_counting : process(rx_ll_sof, rx_ll_src_rdy, rx_ll_dst_rdy, rx_packet_count, testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    rx_packet_count_next <= rx_packet_count;
    	    testing_state_next <= testing_state;
	    case testing_state is
        	when T_STATE_INIT =>
		    rx_packet_count_next <= (others => '0');
		    testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if rx_ll_src_rdy = '1' and rx_ll_sof = '1' and rx_ll_dst_rdy = '1' then
			tmp := unsigned(rx_packet_count) + 1;
			rx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		    if rx_ll_sof = '1' then
		    	tmp := unsigned(rx_packet_count1) + 1;
				rx_packet_count1_next <= std_logic_vector(tmp);
		    end if;
		    if rx_ll_src_rdy = '1' then
		    	tmp := unsigned(rx_packet_count2) + 1;
				rx_packet_count2_next <= std_logic_vector(tmp);
		    end if;
		    if tx_ll_dst_rdy = '1' then
		    	tmp := unsigned(rx_packet_count3) + 1;
				rx_packet_count3_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
	    end case;
	end process;

	--count all tx packets
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
			rx_packet_count1 <= (others => '0');
			rx_packet_count2 <= (others => '0');
			rx_packet_count3 <= (others => '0');
	        
			testing_state <= T_STATE_INIT;
			tx_packet_count <= (others => '0');
			tx_testing_state <= T_STATE_INIT;
		elsif rising_edge(clk) then
			rx_packet_count <= rx_packet_count_next;
			rx_packet_count1 <= rx_packet_count1_next;
			rx_packet_count2 <= rx_packet_count2_next;
			rx_packet_count3 <= rx_packet_count3_next;
	        
			testing_state <= testing_state_next;
			tx_packet_count <= tx_packet_count_next;
			tx_testing_state <= tx_testing_state_next;
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
			state <= STATE_GET;
			global_addr <= "0001"; --default: send it to the ethernet block
			local_addr  <= "00";
		elsif rising_edge(clk) then
			case state is
				-- Get global and local addresses (NoC)
				when STATE_GET =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
					if done then
						if (data = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							global_addr <= data(5 downto 2);
							local_addr  <= data(1 downto 0);
							state <= STATE_PUT;
						end if;
					end if;
				-- give back counter values
				when STATE_PUT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count, ignore, done);
					if done then state <= STATE_PUT2; end if;
				when STATE_PUT2 =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count1, ignore, done);
					if done then state <= STATE_PUT3; end if;
				when STATE_PUT3 =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count2, ignore, done);
					if done then state <= STATE_PUT4; end if;
				when STATE_PUT4 =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count3, ignore, done);
					if done then state <= STATE_PUT5; end if;
				when STATE_PUT5 =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, tx_packet_count, ignore, done);
					if done then state <= STATE_GET; end if;
				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			end case;
		end if;
	end process;

end architecture;
