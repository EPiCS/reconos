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

entity hwt_pr is
	port (
		OSFSL_S_Read   	: out	std_logic; -- Read signal, requiring next available input to be read
		OSFSL_S_Data   	: in 	std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control	: in 	std_logic; -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists 	: in 	std_logic; -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Write  	: out	std_logic; -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data   	: out	std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control	: out	std_logic; -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full   	: in 	std_logic; -- Full Bit, indicating output FSL bus is full
		FIFO32_S_Data 	: in 	std_logic_vector(31 downto 0);
		FIFO32_M_Data 	: out	std_logic_vector(31 downto 0);
		FIFO32_S_Fill 	: in 	std_logic_vector(15 downto 0);
		FIFO32_M_Rem  	: in 	std_logic_vector(15 downto 0);
		FIFO32_S_Rd   	: out	std_logic;
		FIFO32_M_Wr   	: out	std_logic;
		rst	: in	std_logic;
		clk	: in	std_logic;
		switch_data_rdy	: in 	std_logic;
		switch_data    	: in 	std_logic_vector(dataWidth downto 0);
		thread_read_rdy	: out	std_logic;
		switch_read_rdy	: in 	std_logic;
		thread_data    	: out	std_logic_vector(dataWidth downto 0);
		thread_data_rdy	: out	std_logic
	);
end hwt_pr;

architecture implementation of hwt_pr is
	type STATE_TYPE is ( STATE_GET, STATE_PUT, STATE_PUT2, STATE_PUT3, STATE_PUT4, STATE_PUT5, STATE_THREAD_EXIT );

	constant OSIF_MBOX_WIDTH : integer := 32;

	component packet_handler is
		port(
			clk:                    in std_logic;
			rst:                    in std_logic; 
			noc_rx_sof:             in std_logic;
			noc_rx_eof:             in std_logic;
			noc_rx_data:            in std_logic_vector(7 downto 0);
			noc_rx_src_rdy:         in std_logic;    
			noc_rx_dst_rdy:         out std_logic;
			noc_tx_sof:             out std_logic;                        -- Indicates the start of a new packet
			noc_tx_eof:             out std_logic;                        -- Indicates the end of the packet
			noc_tx_data:            out std_logic_vector(7 downto 0);     -- The current data byte
			noc_tx_src_rdy:         out std_logic;                        -- '1' if the data are valid, '0' else
			noc_tx_dst_rdy:         in std_logic;                         -- Read enable for the applied data
			configuring:            in std_logic;
			stat_recv_packets:      out std_logic_vector(31 downto 0);
			stat_forw_packets:      out std_logic_vector(31 downto 0);
			stat_drop_packets:      out std_logic_vector(31 downto 0);
			config_header_length:   in std_logic_vector(31 downto 0) 
    		);
	end component;

	constant MBOX_RECV : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal data : std_logic_vector(31 downto 0);
	signal state : STATE_TYPE;
	signal i_osif : i_osif_t;
	signal o_osif : o_osif_t;
	signal i_memif : i_memif_t;
	signal o_memif : o_memif_t;
	signal i_ram : i_ram_t;
	signal o_ram : o_ram_t;

	signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state : testing_state_t;
	signal testing_state_next : testing_state_t;

	type sending_state_t is (S_STATE_INIT, S_STATE_SOF, S_STATE_DATA, S_STATE_EOF, S_STATE_WAIT);
	signal sending_state     	: sending_state_t;
	signal sending_state_next	: sending_state_t;

	signal rx_packet_count : std_logic_vector(31 downto 0);
	signal rx_packet_count_next : std_logic_vector(31 downto 0);

	signal rx_packet_count1 : std_logic_vector(31 downto 0);
	signal rx_packet_count1_next : std_logic_vector(31 downto 0);
	signal rx_packet_count2 : std_logic_vector(31 downto 0);
	signal rx_packet_count2_next : std_logic_vector(31 downto 0);
	signal rx_packet_count3 : std_logic_vector(31 downto 0);
	signal rx_packet_count3_next : std_logic_vector(31 downto 0);

	signal tx_testing_state : testing_state_t;
	signal tx_testing_state_next : testing_state_t;

	signal tx_packet_count : std_logic_vector(31 downto 0);
	signal tx_packet_count_next : std_logic_vector(31 downto 0);

	signal rx_ll_dst_rdy_local	: std_logic;

	signal tx_ll_sof    	: std_logic;
	signal tx_ll_eof    	: std_logic;
	signal tx_ll_data   	: std_logic_vector(7 downto 0);
	signal tx_ll_src_rdy	: std_logic;
	signal tx_ll_dst_rdy	: std_logic;

	signal rx_ll_sof    	: std_logic;
	signal rx_ll_eof    	: std_logic;
	signal rx_ll_data   	: std_logic_vector(7 downto 0);
	signal rx_ll_src_rdy	: std_logic;
	signal rx_ll_dst_rdy	: std_logic;

	signal stat_recv_packets	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal stat_forw_packets	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal stat_drop_packets	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal header_length    	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);

	signal payload_count : integer range 0 to 1500;
	signal payload_count_next : integer range 0 to 1500;

	signal direction : std_logic;
	signal priority : std_logic_vector(1 downto 0);
	signal latency_critical : std_logic;
	signal srcIdp : std_logic_vector(31 downto 0);
	signal dstIdp : std_logic_vector(31 downto 0);
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);

	signal debug_sig : std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal configuring : std_logic;


begin


	debug_sig <= "00000000000000000000000000101010"; --42

	packet_handler_inst : packet_handler
	port map(
		clk => clk,
		rst => rst,
		noc_rx_sof => rx_ll_sof,
		noc_rx_eof => rx_ll_eof,
		noc_rx_data => rx_ll_data,
		noc_rx_src_rdy => rx_ll_src_rdy,
		noc_rx_dst_rdy => rx_ll_dst_rdy,	      
		noc_tx_sof => tx_ll_sof, 		
		noc_tx_eof => tx_ll_eof,
		noc_tx_data => tx_ll_data,		
		noc_tx_src_rdy => tx_ll_src_rdy,		
		noc_tx_dst_rdy => tx_ll_dst_rdy,
		configuring => configuring,
		stat_recv_packets => stat_recv_packets,
		stat_forw_packets => stat_forw_packets,
		stat_drop_packets => stat_drop_packets,
		config_header_length =>	header_length
	);




	decoder_inst : packetDecoder
	port map (
		clk => clk, 
		reset => rst,
		switch_data_rdy	=> switch_data_rdy,
		switch_data    	=> switch_data,
		thread_read_rdy	=> thread_read_rdy,
		noc_rx_sof            	=> rx_ll_sof,       	-- Indicates the start of a new packet
		noc_rx_eof            	=> rx_ll_eof,       	-- Indicates the end of the packet
		noc_rx_data           	=> rx_ll_data,      	-- The current data byte
		noc_rx_src_rdy        	=> rx_ll_src_rdy,   	-- '1' if the data are valid, '0' else
		noc_rx_direction      	=> direction,       	-- '1' for egress, '0' for ingress
		noc_rx_priority       	=> priority,        	-- The priority of the packet
		noc_rx_latencyCritical	=> latency_critical,	-- '1' if this packet is latency critical
		noc_rx_srcIdp         	=> srcIdp,          	-- The source IDP
		noc_rx_dstIdp         	=> dstIdp,          	-- The destination IDP
		noc_rx_dst_rdy        	=> rx_ll_dst_rdy    	-- Read enable for the functional block
	);

	encoder_inst : packetEncoder
	port map(
		clk  	=> clk, 
		reset	=> rst,	
		switch_read_rdy	=> switch_read_rdy,
		thread_data    	=> thread_data,	
		thread_data_rdy	=> thread_data_rdy,
		noc_tx_sof            	=> tx_ll_sof,
		noc_tx_eof            	=> tx_ll_eof,
		noc_tx_data           	=> tx_ll_data,
		noc_tx_src_rdy        	=> tx_ll_src_rdy,
		noc_tx_globalAddress  	=> global_addr,     	--"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)
		noc_tx_localAddress   	=> local_addr,      	--"01",-- (others => '0'), --2 bits
		noc_tx_direction      	=> direction,       	
		noc_tx_priority       	=> "11",--priority,        	
		noc_tx_latencyCritical	=> latency_critical,	
		noc_tx_srcIdp         	=> srcIdp,          	
		noc_tx_dstIdp         	=> dstIdp,
		noc_tx_dst_rdy        	=> tx_ll_dst_rdy
	);


	fsl_setup(i_osif,o_osif,OSFSL_S_Data,OSFSL_S_Exists,OSFSL_M_Full,
		OSFSL_M_Data,OSFSL_S_Read,OSFSL_M_Write,OSFSL_M_Control);
		
	memif_setup(i_memif,o_memif,FIFO32_S_Data,FIFO32_S_Fill,FIFO32_S_Rd,
		FIFO32_M_Data,FIFO32_M_Rem,FIFO32_M_Wr);


	-- os and memory synchronisation state machine
	reconos_fsm: process (clk,rst,o_osif,o_memif,o_ram) is
		variable done : boolean;
	begin
		if rst = '1' then
			configuring <= '1';
			osif_reset(o_osif);
			memif_reset(o_memif);
			state      	<= STATE_GET;
			global_addr	<= "0001"; --default: send it to the h2s block
			local_addr 	<= "01";
			header_length  	<= X"0000000F";

		elsif rising_edge(clk) then
		case state is

			when STATE_GET =>
				osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done); --. data = shared_mem_h2s in der Software
				if done then
					if (data = X"FFFFFFFF") 
					then
						state <= STATE_THREAD_EXIT;
					elsif (data(31 downto 24) = "01110011") -- ASCII 's' "Statistics"
					then
						state <= STATE_PUT;
					elsif (data(31 downto 24) = "01101000") -- ASCII 'h' for "Header Length"
					then
						header_length(23 downto 0) <= data(23 downto 0);
						state <= STATE_GET;
					else 
						configuring <= '0';
						global_addr <= data(5 downto 2);
						local_addr <= data(1 downto 0);
						state <= STATE_PUT5;
					end if;
				end if;

			when STATE_PUT =>
				osif_mbox_put(i_osif, o_osif, MBOX_SEND, stat_recv_packets, ignore, done);
				if done then state <= STATE_PUT2; end if;

			when STATE_PUT2 =>
				osif_mbox_put(i_osif, o_osif, MBOX_SEND, stat_forw_packets, ignore, done);
				if done then state <= STATE_PUT3; end if;

			when STATE_PUT3 =>
				osif_mbox_put(i_osif, o_osif, MBOX_SEND, stat_drop_packets, ignore, done);
				if done then state <= STATE_PUT4; end if;

			when STATE_PUT4 =>
				osif_mbox_put(i_osif, o_osif, MBOX_SEND, header_length, ignore, done);
				if done then state <= STATE_PUT5; end if;

			when STATE_PUT5 =>
				osif_mbox_put(i_osif, o_osif, MBOX_SEND, debug_sig, ignore, done);
				if done then state <= STATE_GET; end if;

			-- thread exit
			when STATE_THREAD_EXIT =>
				configuring <= '1';
				osif_thread_exit(i_osif,o_osif);

		end case; -- state
		end if; -- rst / rising clk
	end process; -- reconos_fsm

end architecture;
