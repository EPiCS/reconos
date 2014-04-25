library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library yyang_v1_00_a;
use yyang_v1_00_a.yyangPkg.all;

entity hwt_packet_handler_tb is
	
end entity hwt_packet_handler_tb;

architecture RTL of hwt_packet_handler_tb is
	
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
	
	signal data 		: std_logic_vector(255 downto 0);
	signal data2 		: std_logic_vector(255 downto 0);
	signal i		: integer range 0 to 20;
	signal i_next		: integer range 0 to 20;
	signal packet_len : integer range 0 to 1500;
	signal count : integer range 0 to 1500;
	signal count_next : integer range 0 to 1500;

	signal cur_len : integer range 0 to 1500;
	signal cur_len_next : integer range 0 to 1500;
	type packet_state_t is ( P_STATE_SEND, P_STATE_INIT, P_STATE_SEND_KEY, P_STATE_WAIT_KEY, P_STATE_END,
			P_STATE_SEND_LAST_BYTES_1,P_STATE_SEND_LAST_BYTES_2 );
	signal packet_state : packet_state_t;
	signal packet_state_next : packet_state_t;
	type rcv_state_t is ( R_STATE_INIT, R_STATE_COUNT );
	signal rcv_state : rcv_state_t;
	signal rcv_state_next : rcv_state_t;
	signal counter :std_logic_vector(7 downto 0);
	
	signal noc_tx_globalAddress:   std_logic_vector(3 downto 0);     -- The global hardware address of the destination
	signal noc_tx_localAddress:    std_logic_vector(1 downto 0);     -- The local hardware address of the destination
	signal noc_tx_direction:       std_logic;                        -- '1' for egress, '0' for ingress
	signal noc_tx_priority:        std_logic_vector(1 downto 0);     -- The priority of the packet
	signal noc_tx_latencyCritical: std_logic;                        -- '1' if this packet is latency critical
	signal noc_tx_srcIdp:          std_logic_vector(31 downto 0);    -- The source IDP
	signal noc_tx_dstIdp:          std_logic_vector(31 downto 0);    -- The destination IDP
	signal noc_tx_dst_rdy:         std_logic;   
	
	component packet_handler is
		port(
			clk:                    in std_logic;
			rst:                    in std_logic;
			startTransmitKey:       in std_logic;
			key256In:               in CIPHERKEY256_ARRAY;
			modeIn:                 in std_logic_vector(1 downto 0);
			globalLocalAddrIn:      in std_logic_vector(5 downto 0);
			keyInjected:            out std_logic;  
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
			noc_tx_dst_rdy:         in std_logic;                         -- Read enable for the applied data
			configuring:            in std_logic
    		);
	end component;

	signal startTransmitKey	: std_logic;
	signal key256In		: CIPHERKEY256_ARRAY;
	signal modeIn		: std_logic_vector(1 downto 0);
	signal globalLocalAddrIn: std_logic_vector(5 downto 0);
	signal keyInjected	: std_logic; 
	signal configuring   : std_logic;
	
	signal clk : std_logic;
	signal rst : std_logic;
	
begin

	--data  <= x"6bc1bee22e409f96e93d7e117393172aa1a2a3a4a5a6a7a8a9aaabacadaeafb0";
	--data2 <= x"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
	data  <= x"2cf6a4dde085628218fc97e00c6d63942cf6a4dde085628218fc97e00c6d6394";

	data2 <= data;
	packet_len  <= 64;
	rx_ll_dst_rdy  <= '0', '1' after 5 ms;--'1';
	
	packets : process(packet_state, packet_len, cur_len, tx_ll_dst_rdy, i, keyInjected, data ) is
		--variable counter : integer := 0;
	begin
		tx_ll_sof  <= '0';
		tx_ll_eof  <= '0';
		tx_ll_src_rdy  <= '1';
		tx_ll_data  <= "01100001";
		cur_len_next  <= cur_len;
		packet_state_next  <= packet_state;
		startTransmitKey <= '0';
		key256In(0) <= x"16157e2b"; 
		key256In(1) <= x"a6d2ae28"; 
		key256In(2) <= x"8815f7ab";
		key256In(3) <= x"3c4fcf09";
		key256In(4) <= x"13121110";
		key256In(5) <= x"17161514";
		key256In(6) <= x"1b1a1918";
		key256In(7) <= x"1f1e1d1c";
		i_next <= i;
		configuring <= '0';
		case packet_state is
			when P_STATE_SEND_KEY =>
				configuring <= '1';
				counter <= (others=>'0');
				tx_ll_src_rdy  <= '0';
				startTransmitKey <= '1';
				packet_state_next <= P_STATE_WAIT_KEY;
			when P_STATE_WAIT_KEY =>
				configuring <= '1';
				tx_ll_src_rdy  <= '0';
				if keyInjected = '1' then
					packet_state_next <= P_STATE_INIT;
				end if;
				
			when P_STATE_INIT  => 
				configuring <= '0';
				if (counter < 5) then
					tx_ll_sof  <= '1';
					if (counter = "00000000" or counter = "00000010" or counter = "00000100") then
						--tx_ll_data <= data(127 downto 120);
						tx_ll_data <= data(255 downto 248);
					else
						--tx_ll_data <= data2(127 downto 120);
						tx_ll_data <= data2(255 downto 248);
					end if;
					if tx_ll_dst_rdy = '1' then	
						packet_state_next  <= P_STATE_SEND;
						cur_len_next  <= 1;
						i_next <= i + 1;
					end if;
				end if;
			when P_STATE_SEND  => 
				--tx_ll_data <= data(127 - 8*i downto 120 - 8*i);
				if (counter = "00000000" or counter = "00000010" or counter = "00000100") then
					--tx_ll_data <= data(127 - 8*i downto 120 - 8*i);
					tx_ll_data <= data(255 - 8*i downto 248 - 8*i);
				else
					--tx_ll_data <= data2(127 - 8*i downto 120 - 8*i);
					tx_ll_data <= data2(255 - 8*i downto 248 - 8*i);
				end if;
				if cur_len  + 1 = packet_len then
					--tx_ll_eof  <= '1';
					packet_state_next  <= P_STATE_SEND_LAST_BYTES_1;--P_STATE_INIT;
				end if;
				if tx_ll_dst_rdy = '1' then
					if i = 31 then
						i_next <= 0;
					else
						i_next <= i + 1;
					end if;
					cur_len_next  <= cur_len + 1;
				end if;
				
			when P_STATE_SEND_LAST_BYTES_1  => 
			tx_ll_data <= X"00";
			if tx_ll_dst_rdy = '1' then
				packet_state_next  <= P_STATE_SEND_LAST_BYTES_2;
			end if;
			
			when P_STATE_SEND_LAST_BYTES_2  =>
			tx_ll_data <= X"40";
			tx_ll_eof  <= '1';
			if tx_ll_dst_rdy = '1' then
				counter <= counter + 1;
				packet_state_next  <= P_STATE_INIT;
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

	packet_handler_inst : packet_handler
	port map(
		clk => clk,
		rst => rst,
		startTransmitKey => startTransmitKey,
		key256In => key256In,
		modeIn => modeIn,
		globalLocalAddrIn =>"000001",
		keyInjected =>keyInjected,
		noc_rx_sof => tx_ll_sof,
		noc_rx_eof => tx_ll_eof,
		noc_rx_data => tx_ll_data,
		noc_rx_src_rdy => tx_ll_src_rdy, 
		noc_rx_direction => '1',
		noc_rx_priority => "01",
		noc_rx_latencyCritical=> '0',
		noc_rx_srcIdp => X"00000000",
		noc_rx_dstIdp => X"00000002",
		noc_rx_dst_rdy => tx_ll_dst_rdy,	      
		noc_tx_sof => rx_ll_sof, 		
		noc_tx_eof => rx_ll_eof,
		noc_tx_data => rx_ll_data,		
		noc_tx_src_rdy => rx_ll_src_rdy,		
		noc_tx_globalAddress => noc_tx_globalAddress,	
		noc_tx_localAddress => noc_tx_localAddress,
		noc_tx_direction => noc_tx_direction,		
		noc_tx_priority => noc_tx_priority,		
		noc_tx_latencyCritical=> noc_tx_latencyCritical,	
		noc_tx_srcIdp => noc_tx_srcIdp,	
		noc_tx_dstIdp => noc_tx_dstIdp,
		noc_tx_dst_rdy => rx_ll_dst_rdy,
		configuring => configuring 
	);

end architecture RTL;
