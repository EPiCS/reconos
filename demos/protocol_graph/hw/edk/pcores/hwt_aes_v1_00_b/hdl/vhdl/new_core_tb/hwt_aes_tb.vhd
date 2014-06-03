library ieee;
use ieee.std_logic_1164.all;

--library yyang_v1_00_a;
use work.hwt_aes_yyang_pkg.all;


entity hwt_aes_tb is
	
end entity hwt_aes_tb;

architecture RTL of hwt_aes_tb is
	
	signal rx_ll_sof  : std_logic;
	signal rx_ll_eof  : std_logic;
	signal rx_ll_data  : std_logic_vector(7 downto 0);
	signal rx_ll_src_rdy  : std_logic;
	signal rx_ll_dst_rdy  : std_logic;
	signal tx_ll_sof  : std_logic;
	signal tx_ll_eof  : std_logic;
	signal tx_ll_data  : std_logic_vector(7 downto 0);
	signal tx_ll_src_rdy  : std_logic;
	signal tx_ll_dst_rdy  : std_logic;
	
	signal startTransmitKey	: std_logic;
    	signal key256In		: CIPHERKEY256_ARRAY;
    	signal modeIn		: std_logic_vector(1 downto 0);
    	signal globalLocalAddrIn: std_logic_vector(5 downto 0);
    	signal keyInjected	: std_logic;            
	signal data 		: std_logic_vector(127 downto 0);
	signal i		: integer range 0 to 15;
	signal i_next		: integer range 0 to 15;
	signal packet_len : integer range 0 to 1500;
	signal count : integer range 0 to 1500;
	signal count_next : integer range 0 to 1500;

	signal cur_len : integer range 0 to 1500;
	signal cur_len_next : integer range 0 to 1500;
	type packet_state_t is ( P_STATE_SEND, P_STATE_INIT, P_STATE_SEND_KEY, P_STATE_WAIT_KEY, P_STATE_END );
	signal packet_state : packet_state_t;
	signal packet_state_next : packet_state_t;
	type rcv_state_t is ( R_STATE_INIT, R_STATE_COUNT );
	signal rcv_state : rcv_state_t;
	signal rcv_state_next : rcv_state_t;

	signal clk : std_logic;
	signal rst : std_logic;
	
	component aesCore is
 	port(
    	--from topfsm:
    	clk:                    in std_logic;
    	rst:                    in std_logic;
    	startTransmitKey:       in std_logic;
    	key256In:               in CIPHERKEY256_ARRAY;
    	modeIn:                 in std_logic_vector(1 downto 0);
    	globalLocalAddrIn:      in std_logic_vector(5 downto 0);
    	keyInjected:            out std_logic;
        
    	--from pktDecoder:    
    	noc_rx_sof:             in std_logic;
    	noc_rx_eof:             in std_logic;
    	noc_rx_data:            in std_logic_vector(7 downto 0);
    	noc_rx_src_rdy:         in std_logic;
    	noc_rx_direction:       in std_logic;
    	noc_rx_priority:        in std_logic_vector(1 downto 0);
    	noc_rx_latencyCritical: in std_logic;
    	noc_rx_srcIdp:          in std_logic_vector(31 downto 0);
    	noc_rx_dstIdp:          in std_logic_vector(31 downto 0);    
    	noc_rx_dst_rdy:         out std_logic;
    
    	--towards pktEncoder:
    	noc_tx_sof:             out std_logic;                        -- Indicates the start of a new packet
	noc_tx_eof:             out std_logic;                        -- Indicates the end of the packet
	noc_tx_data:            out std_logic_vector(7 downto 0);     -- The current data byte
	noc_tx_src_rdy:         out std_logic;                        -- '1' if the data are valid, '0' else
	noc_tx_globalAddress:   out std_logic_vector(3 downto 0);     -- The global hardware address of the destination
	noc_tx_localAddress:    out std_logic_vector(1 downto 0);     -- The local hardware address of the destination
	noc_tx_direction:       out std_logic;                        -- '1' for egress, '0' for ingress
	noc_tx_priority:        out std_logic_vector(1 downto 0);     -- The priority of the packet
	noc_tx_latencyCritical: out std_logic;                        -- '1' if this packet is latency critical
	noc_tx_srcIdp:          out std_logic_vector(31 downto 0);    -- The source IDP
	noc_tx_dstIdp:          out std_logic_vector(31 downto 0);    -- The destination IDP
	noc_tx_dst_rdy:         in std_logic                          -- Read enable for the applied data
  	);
	end component;
	
begin

	data <= x"6bc1bee22e409f96e93d7e117393172a";
	packet_len  <= 64;
	rx_ll_dst_rdy  <= '1';
	
	packets : process(packet_state, packet_len, cur_len, tx_ll_dst_rdy, i) is
	begin
	tx_ll_sof  <= '0';
	tx_ll_eof  <= '0';
	tx_ll_src_rdy  <= '1';
	tx_ll_data  <= "01100001";
	cur_len_next  <= cur_len;
	packet_state_next  <= packet_state;
	startTransmitKey <= '0';
	key256In(0) <= x"16157e2b"; --x"2b7e1516";
	key256In(1) <= x"a6d2ae28"; -- x"28aed2a6";
	key256In(2) <= x"8815f7ab";--x"abf71588";
	key256In(3) <= x"3c4fcf09"; --x"09cf4f3c";
	key256In(4 to 7) <= (others => (others => '0'));
	i_next <= i;
	case packet_state is
	when P_STATE_SEND_KEY =>
		tx_ll_src_rdy  <= '0';
		startTransmitKey <= '1';
		packet_state_next <= P_STATE_WAIT_KEY;
	when P_STATE_WAIT_KEY =>
		tx_ll_src_rdy  <= '0';
		if keyInjected = '1' then
			packet_state_next <= P_STATE_INIT;
		end if;
    	
	when P_STATE_INIT  => 
		tx_ll_sof  <= '1';
		tx_ll_data <= data(127 downto 120);
		if tx_ll_dst_rdy = '1' then	
			packet_state_next  <= P_STATE_SEND;
			cur_len_next  <= 1;
			i_next <= i + 1;
		end if;
	when P_STATE_SEND  => 
		tx_ll_data <= data(127 - 8*i downto 120 - 8*i);
		if cur_len = packet_len then
			tx_ll_eof  <= '1';
			packet_state_next  <= P_STATE_END;
		end if;
		if tx_ll_dst_rdy = '1' then
			if i = 15 then
				i_next <= 0;
			else
				i_next <= i + 1;
			end if;
			cur_len_next  <= cur_len + 1;
		end if;
		if i = 15 then
			i_next <= 0;
		end if;
	when P_STATE_END =>
		
	end case;
	end process;

	rcv : process (rx_ll_sof, rx_ll_eof, rcv_state, count) is
	begin
	case rcv_state is
	when R_STATE_INIT =>
		if rx_ll_sof = '1' then
			count_next <= 0;
			rcv_state_next <= R_STATE_COUNT;
		end if;
	when R_STATE_COUNT =>
		if rx_ll_eof = '1' then
			rcv_state_next <= R_STATE_INIT;
		end if;
		count_next <= count + 1;
	end case;
	end process;
	


	rst  <= '1', '0' after 1 us;
	clk_process :process
	begin
		clk <= '0';
		wait for 5 us;
		clk <= '1';
		wait for 5 us;
	end process;

	memzing: process(clk, rst) is
	begin
	    if rst = '1' then
			cur_len  <= 0;
			packet_state  <= P_STATE_SEND_KEY;
			rcv_state <= R_STATE_INIT;
			count <= 0;
			i <= 0;
		
	    elsif rising_edge(clk) then
	    	cur_len  <= cur_len_next;
	    	packet_state  <= packet_state_next;
		rcv_state <= rcv_state_next;
		count <= count_next;
		i <= i_next;
	    end if;
	end process;

	hwt_aes_inst : aesCore 
	port map(
   		clk 			=> clk,
   		rst			=> rst,
   		startTransmitKey	=> startTransmitKey,
    		key256In		=> key256In,
    		modeIn			=> "00",
    		globalLocalAddrIn	=> (others => '0'),
    		keyInjected		=> keyInjected,
        
    		--from pktDecoder:    
   		noc_rx_sof		=> tx_ll_sof,
    		noc_rx_eof		=> tx_ll_eof,
    		noc_rx_data		=> tx_ll_data,
    		noc_rx_src_rdy		=> tx_ll_src_rdy,
    		noc_rx_direction	=> '0',
    		noc_rx_priority		=> (others => '0'),
    		noc_rx_latencyCritical 	=> '0',
    		noc_rx_srcIdp		=> (others => '0'),
    		noc_rx_dstIdp    	=> (others => '0'),
    		noc_rx_dst_rdy		=> tx_ll_dst_rdy,
    
    		--towards pktEncoder:
    		noc_tx_sof		=> rx_ll_sof,
		noc_tx_eof		=> rx_ll_eof,
		noc_tx_data		=> rx_ll_data,
		noc_tx_src_rdy		=> rx_ll_src_rdy,
		noc_tx_globalAddress	=> open,
		noc_tx_localAddress	=> open,
		noc_tx_direction	=> open,
		noc_tx_priority		=> open,
		noc_tx_latencyCritical	=> open,
		noc_tx_srcIdp		=> open,
		noc_tx_dstIdp		=> open,
		noc_tx_dst_rdy		=> rx_ll_src_rdy

	);

end architecture RTL;
