library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;
--use ana_v1_00_a.packetDecoder.all;

entity hwt_ethernet_test is
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
	--	FIFO32_S_Clk : out std_logic;
	--	FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset
		rst           : in std_logic;

		--Ethernet Signals
  		TXP		: out std_logic;
        	TXN            	: out std_logic;
		RXP		: in  std_logic;
		RXN             : in  std_logic;

		-- SGMII-transceiver reference clock buffer input
		MGTCLK_P        : in  std_logic;
		MGTCLK_N        : in  std_logic;

		-- Asynchronous reset
		PRE_PHY_RESET   : in  std_logic;
		PHY_RESET       : out std_logic;

		-- NoC interface
	switch_data_rdy		: in  std_logic;
	switch_data		: in  std_logic_vector(dataWidth downto 0);
	thread_read_rdy	 	: out std_logic;

	switch_read_rdy			: in  std_logic;
	thread_data			: out std_logic_vector(dataWidth downto 0);
	thread_data_rdy 	: out std_logic

--		rx_ll_sof	: out std_logic;
--		rx_ll_eof	: out std_logic;
--		rx_ll_data	: out std_logic_vector(7 downto 0);
--		rx_ll_src_rdy	: out std_logic;
--		rx_ll_dst_rdy	: in std_logic;
--		tx_ll_sof	: in std_logic;
--		tx_ll_eof	: in std_logic;
--		tx_ll_data	: in std_logic_vector(7 downto 0);
--		tx_ll_src_rdy	: in std_logic;
--		tx_ll_dst_rdy	: out std_logic

	);

end hwt_ethernet_test;

architecture implementation of hwt_ethernet_test is
	type STATE_TYPE is ( STATE_GET, STATE_PUT, STATE_PUT2, STATE_THREAD_EXIT );

	-- PUT YOUR OWN COMPONENTS HERE

    	-- END OF YOUR OWN COMPONENTS
	component eth is
	port(
  	-- Ethernet Signals
  	TXP             : out std_logic;
   	TXN             : out std_logic;
	RXP             : in  std_logic;
	RXN             : in  std_logic;

	-- SGMII-transceiver reference clock buffer input
	MGTCLK_P        : in  std_logic;
	MGTCLK_N        : in  std_logic;

	-- Asynchronous reset
	PRE_PHY_RESET   : in  std_logic;
	PHY_RESET       : out std_logic;

   	-- Standard Signals
	clk             : in  std_logic;
	reset           : in  std_logic;
        
        --Network on Chip signals
        -- To Ethernet block (_n = active low)
        tx_ll_data        : in std_logic_vector(7 downto 0);
        tx_ll_sof_n       : in std_logic;
        tx_ll_eof_n       : in std_logic;
        tx_ll_src_rdy_n   : in std_logic;
        tx_ll_dst_rdy_n   : out std_logic;

	-- From Ethernet block
        rx_ll_data        : out std_logic_vector(7 downto 0);
        rx_ll_sof_n       : out std_logic;
        rx_ll_eof_n       : out std_logic;
        rx_ll_src_rdy_n   : out std_logic;
        rx_ll_dst_rdy_n   : in std_logic
	);
	end component;

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

	signal sort_start : std_logic := '0';
	signal sort_done  : std_logic := '0';

	--Ethernet
	signal tx_ll_data        : std_logic_vector(7 downto 0);
        signal tx_ll_sof_n       : std_logic;
        signal tx_ll_eof_n       : std_logic;
        signal tx_ll_src_rdy_n   : std_logic;
       	signal tx_ll_dst_rdy_n   : std_logic;
	--Decoder has active high
  	signal tx_ll_sof       : std_logic;
        signal tx_ll_eof       : std_logic;
        signal tx_ll_src_rdy   : std_logic;
       	signal tx_ll_dst_rdy   : std_logic;



        signal rx_ll_data        : std_logic_vector(7 downto 0);
        signal rx_ll_sof_n       : std_logic;
        signal rx_ll_eof_n       : std_logic;
        signal rx_ll_src_rdy_n   : std_logic;
        signal rx_ll_dst_rdy_n   : std_logic;
        --encoder has active high
        signal rx_ll_sof       : std_logic;
        signal rx_ll_eof       : std_logic;
        signal rx_ll_src_rdy   : std_logic;
        signal rx_ll_dst_rdy   : std_logic;
        
        
	
	type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state 	    : testing_state_t;
	signal testing_state_next   : testing_state_t;

	signal rx_packet_count 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count_next : std_logic_vector(31 downto 0);
	
	signal tx_testing_state 	    : testing_state_t;
	signal tx_testing_state_next   : testing_state_t;

	signal tx_packet_count 	    : std_logic_vector(31 downto 0);
	signal tx_packet_count_next : std_logic_vector(31 downto 0);
	
	signal src_idp : std_logic_vector(31 downto 0);
	signal dst_idp : std_logic_vector(31 downto 0);
	signal latency_critical : std_logic;
	signal direction : std_logic;
	signal priority : std_logic_vector(1 downto 0);
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);

begin
	

   

    -- PUT YOUR OWN INSTANCES HERE
	-- interface from switch to block
	decoder_inst : packetDecoder
	port map (
		clk 	=> i_osif.clk,
		reset 	=> rst,

		-- Signals from the switch
		switch_data_rdy		=> switch_data_rdy,
		switch_data		=> switch_data,
		thread_read_rdy		=> thread_read_rdy,

		-- Decoded values of the packet
		noc_rx_sof		=> tx_ll_sof,		-- Indicates the start of a new packet
		noc_rx_eof		=> tx_ll_eof,		-- Indicates the end of the packet
		noc_rx_data		=> tx_ll_data,		-- The current data byte
		noc_rx_src_rdy		=> tx_ll_src_rdy, 	-- '1' if the data are valid, '0' else
		noc_rx_direction	=> open,		-- '1' for egress, '0' for ingress
		noc_rx_priority		=> open,		-- The priority of the packet
		noc_rx_latencyCritical	=> open,		-- '1' if this packet is latency critical
		noc_rx_srcIdp		=> open,		-- The source IDP
		noc_rx_dstIdp		=> open,		-- The destination IDP
		noc_rx_dst_rdy		=> tx_ll_dst_rdy	-- Read enable for the functional block	
);
	
	encoder_inst : packetEncoder
	port map(
		clk 				=> i_osif.clk,					
		reset 				=> rst,		
		-- Signals to the switch
		switch_read_rdy  		=> switch_read_rdy, 		
		thread_data  			=> thread_data,		
		thread_data_rdy 		=> thread_data_rdy,
		-- Decoded values of the packet
		noc_tx_sof  			=> rx_ll_sof, 		
		noc_tx_eof  			=> rx_ll_eof,
		noc_tx_data	 		=> rx_ll_data,		
		noc_tx_src_rdy 	 		=> rx_ll_src_rdy,		
		noc_tx_globalAddress  		=> global_addr, --"0001",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress  		=> local_addr, --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	=> direction,		
		noc_tx_priority 	 	=> priority,		
		noc_tx_latencyCritical  	=> latency_critical,	
		noc_tx_srcIdp 			=> src_idp,	
		noc_tx_dstIdp 			=> dst_idp,
		noc_tx_dst_rdy	 		=> rx_ll_dst_rdy
	);
	
	
	-- eth
	eth_inst : eth
	port map(
    	-- Ethernet Signals
  	TXP             => TXP,
  	TXN             => TXN,
	RXP             => RXP,
	RXN             => RXN,

	-- SGMII-transceiver reference clock buffer input
	MGTCLK_P        => MGTCLK_P,
	MGTCLK_N        => MGTCLK_N,

	-- Asynchronous reset
	PRE_PHY_RESET   => PRE_PHY_RESET,
	PHY_RESET       => PHY_RESET,

        -- Standard Signals
	clk             => i_osif.clk,
	reset           => rst,
        
        --Network on Chip signals
        -- To Ethernet block (_n = active low)
        tx_ll_data        => tx_ll_data,
        tx_ll_sof_n       => tx_ll_sof_n,
        tx_ll_eof_n       => tx_ll_eof_n,
        tx_ll_src_rdy_n   => tx_ll_src_rdy_n,
        tx_ll_dst_rdy_n   => tx_ll_dst_rdy_n,

	-- From Ethernet block
        rx_ll_data        => rx_ll_data,
        rx_ll_sof_n       => rx_ll_sof_n,
        rx_ll_eof_n       => rx_ll_eof_n,
        rx_ll_src_rdy_n   => rx_ll_src_rdy_n,
        rx_ll_dst_rdy_n   => rx_ll_dst_rdy_n
	);

    -- END OF YOUR OWN INSTANCES

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
	--	FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
	--	FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
    -- PUT YOUR OWN PROCESSES HERE
	--conversion packet decoder and ethernet interface.
    	tx_ll_sof_n     <= not tx_ll_sof;
        tx_ll_eof_n     <= not tx_ll_eof;
        tx_ll_src_rdy_n <= not tx_ll_src_rdy;
       	tx_ll_dst_rdy	<= not tx_ll_dst_rdy_n;
	--downstreamReadClock	<= i_osif.clk;
		
	rx_ll_sof       <= not rx_ll_sof_n;
        rx_ll_eof       <= not rx_ll_eof_n;
        rx_ll_src_rdy   <= not rx_ll_src_rdy_n;
       	rx_ll_dst_rdy_n	<= not rx_ll_dst_rdy;
	--upstreamWriteClock	<= i_osif.clk;

	--count all rx packets
	test_counting : process(rx_ll_sof_n, rx_ll_src_rdy_n, rx_ll_dst_rdy_n, rx_packet_count, testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    rx_packet_count_next <= rx_packet_count;
    	    testing_state_next <= testing_state;
	    case testing_state is
        	when T_STATE_INIT =>
		    rx_packet_count_next <= (others => '0');
		    testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if rx_ll_src_rdy_n = '0' and rx_ll_sof_n = '0' and rx_ll_dst_rdy_n = '0' then
			tmp := unsigned(rx_packet_count) + 1;
			rx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
	    end case;
	end process;

	--count all tx packets
	tx_test_counting : process(tx_ll_eof_n, tx_ll_src_rdy_n, tx_ll_dst_rdy_n, tx_packet_count, tx_testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    tx_packet_count_next <= tx_packet_count;
    	    tx_testing_state_next <= tx_testing_state;
	    case tx_testing_state is
        	when T_STATE_INIT =>
		    tx_packet_count_next <= (others => '0');
		    tx_testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if tx_ll_src_rdy_n = '0' and tx_ll_eof_n = '0' and tx_ll_dst_rdy_n = '0' then
			tmp := unsigned(tx_packet_count) + 1;
			tx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    tx_testing_state_next <= T_STATE_INIT;
	    end case;
	end process;



	--creates flipflops
	memzing: process(i_osif.clk, rst) is
	begin
	    if rst = '1' then
	        rx_packet_count <= (others => '0');
	        testing_state <= T_STATE_INIT;
     		tx_packet_count <= (others => '0');
	        tx_testing_state <= T_STATE_INIT;
	    elsif rising_edge(i_osif.clk) then
	        rx_packet_count <= rx_packet_count_next;
	        testing_state <= testing_state_next;
  		tx_packet_count <= tx_packet_count_next;
	        tx_testing_state <= tx_testing_state_next;

	    end if;
	end process;

	-- END OF YOUR OWN PROCESSES


    -- ADJUST THE RECONOS_FSM TO YOUR NEEDS.		
	-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			state <= STATE_GET;
			dst_idp  <= (others  => '0');
			src_idp  <= (others  => '0');
			latency_critical  <= '0';
			direction  <= '0'; --0 = ingress
			priority  <= (others  => '0');
			global_addr  <= "0001"; --default: send all packets to sw
			local_addr  <= "01";

            -- RESET YOUR OWN SIGNALS HERE

		elsif rising_edge(i_osif.clk) then
			case state is

                -- EXAMPLE STATE MACHINE - ADD YOUR STATES AS NEEDED

				-- Get some data
				when STATE_GET =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
					if done then
						if (data = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							dst_idp(7 downto 0)  <= data(31 downto 24);
							src_idp(7 downto 0)  <= data(23 downto 16);
							latency_critical  <= data(9);
							direction  <= data(8);
							priority  <= data(7 downto 6);
							global_addr  <= data(5 downto 2);
							local_addr  <= data(1 downto 0);
							state <= STATE_PUT;
						end if;
					end if;
				
				
				-- Echo the data
				when STATE_PUT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count, ignore, done);
					if done then state <= STATE_PUT2; end if;
				
				when STATE_PUT2 =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, tx_packet_count, ignore, done);
					if done then state <= STATE_GET; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			
			end case;
		end if;
	end process;
	
	


end architecture;
