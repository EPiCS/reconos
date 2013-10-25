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
		thread_data_rdy 	: out std_logic
	);

end hwt_pr;

architecture implementation of hwt_pr is
	type STATE_TYPE is ( STATE_GET, STATE_PUT_FB_ID, --STATE_PUT, STATE_PUT2, STATE_PUT3, STATE_PUT4, STATE_PUT5, 
			STATE_THREAD_EXIT );

	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";
	
	constant PR_MODULE  : std_logic_vector(7 downto 0) := X"0B";

	signal data     : std_logic_vector(31 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	
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

	signal direction : std_logic;
	signal priority : std_logic_vector(1 downto 0);
	signal latency_critical : std_logic;
	signal srcIdp : std_logic_vector(31 downto 0);
	signal dstIdp : std_logic_vector(31 downto 0);
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);

	signal tx_ll_sof_n  	   : std_logic;         ----active low 
	signal tx_ll_eof_n      : std_logic;         ----active low 
	signal tx_ll_src_rdy_n  : std_logic;         ----active low  
	signal tx_ll_dst_rdy_n  : std_logic;         ----active low
	signal rx_ll_sof_n       : std_logic;         ----active low
	signal rx_ll_eof_n       : std_logic;         ----active low
	signal rx_ll_src_rdy_n   : std_logic;         ----active low
	signal rx_ll_dst_rdy_n   : std_logic;         ----active low


begin
	
	decoder_inst : packetDecoder
	port map (
		clk 	=> clk,
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
		noc_rx_direction	=> direction, 		-- '1' for egress, '0' for ingress
		noc_rx_priority		=> priority,		-- The priority of the packet
		noc_rx_latencyCritical	=> latency_critical,		-- '1' if this packet is latency critical
		noc_rx_srcIdp		=> srcIdp,		-- The source IDP
		noc_rx_dstIdp		=> dstIdp,		-- The destination IDP
		noc_rx_dst_rdy		=> rx_ll_dst_rdy	-- Read enable for the functional block
	);
	
	encoder_inst : packetEncoder
	port map(
		clk 				=> clk,					
		reset				=> rst,		
		-- Signals to the switch
		switch_read_rdy  		=> switch_read_rdy, 		
		thread_data  			=> thread_data,		
		thread_data_rdy 		=> thread_data_rdy,
		-- Decoded values of the packet
		noc_tx_sof  			=> tx_ll_sof, 		
		noc_tx_eof  			=> tx_ll_eof,
		noc_tx_data	 		=> tx_ll_data,		
		noc_tx_src_rdy 	 		=> tx_ll_src_rdy,		
		noc_tx_globalAddress  		=> global_addr, --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress  		=> local_addr, --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	=> direction,		
		noc_tx_priority 	 	=> priority,		
		noc_tx_latencyCritical  	=> latency_critical,	
		noc_tx_srcIdp 			=> srcIdp,	
		noc_tx_dstIdp 			=> dstIdp,
		noc_tx_dst_rdy	 		=> tx_ll_dst_rdy
	);
	
	tx_ll_src_rdy <= rx_ll_src_rdy;
	tx_ll_data <= rx_ll_data when rx_ll_sof='1' else PR_MODULE;
	tx_ll_sof <= rx_ll_sof;
	tx_ll_eof <= rx_ll_eof;
	rx_ll_dst_rdy <= tx_ll_dst_rdy;

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
			global_addr <= "0001"; --default: send it to the h2s block
			local_addr  <= "01";
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
							state <= STATE_PUT_FB_ID;
						end if;
					end if;
				-- give back counter values
				when STATE_PUT_FB_ID =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, X"000000"&PR_MODULE, ignore, done);
					if done then state <= STATE_GET; end if;
				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			end case;
		end if;
	end process;

end architecture;
