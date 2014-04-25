library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library yyang_v1_00_a;
use yyang_v1_00_a.yyangPkg.all;

entity packet_handler is
	port (
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
		noc_tx_dst_rdy:         in std_logic;
		configuring:            in std_logic 
	);
end packet_handler;

architecture implementation of packet_handler is
	component aesCoreDe is
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
			noc_tx_dst_rdy:         in std_logic                          -- Read enable for the applied data
    		);
	end component;
	component fifo32 is
		generic (
			C_FIFO32_WORD_WIDTH         	: integer := 32; 
			C_FIFO32_DEPTH              	: integer := 1600; 
			CLOG2_FIFO32_DEPTH          	: integer := 11; 
			C_FIFO32_CONTROLSIGNAL_WIDTH	: integer := 16; 
			C_FIFO32_SAFE_READ_WRITE    	: boolean := true
		);
		port (
			Rst         	: in  std_logic; 
			FIFO32_S_Clk 	: in  std_logic;
			FIFO32_M_Clk 	: in  std_logic;
			FIFO32_S_Data	: out std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);
			FIFO32_M_Data	: in  std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);
			FIFO32_S_Fill 	: out std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);
			FIFO32_M_Rem  	: out std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);
			FIFO32_S_Full 	: out std_logic;
			FIFO32_M_Empty	: out std_logic;
			FIFO32_S_Rd	: in  std_logic;
			FIFO32_M_Wr	: in  std_logic
		);
	end component;

	component icon
	port (
		control0 : inout std_logic_vector(35 downto 0)
	);
	end component;

	component ila
	port (
		control : inout std_logic_vector(35 downto 0);
		clk   : in std_logic;
		trig0 : in std_logic_vector(15 downto 0);
		trig1 : in std_logic_vector( 7 downto 0);
		trig2 : in std_logic_vector(15 downto 0);
		trig3 : in std_logic_vector(31 downto 0);
		trig4 : in std_logic_vector(31 downto 0);
		trig5 : in std_logic_vector( 3 downto 0);
		trig6 : in std_logic_vector(31 downto 0);
		trig7 : in std_logic_vector( 3 downto 0)
	);
	end component;
	
	signal trig0 : std_logic_vector(15 downto 0);
	signal trig1 : std_logic_vector( 7 downto 0);
	signal trig2 : std_logic_vector(15 downto 0);
	signal trig3 : std_logic_vector(31 downto 0);
	signal trig4 : std_logic_vector(31 downto 0);
	signal trig5 : std_logic_vector( 3 downto 0);
	signal trig6 : std_logic_vector(31 downto 0);
	signal trig7 : std_logic_vector( 3 downto 0);
	signal control : std_logic_vector(35 downto 0);

	signal tx_data_2_noc : std_logic_vector(7 downto 0);
	signal tx_sof_2_noc : std_logic;
	signal tx_eof_2_noc : std_logic;
	signal tx_src_rdy_2_noc : std_logic;
	signal rx_dst_rdy_2_noc : std_logic;

	signal fifo_out_data_in : std_logic_vector(9 downto 0);
	signal fifo_out_data_out : std_logic_vector(9 downto 0);
	signal fifo_out_fill : std_logic_vector(15 downto 0);
	signal fifo_out_rem : std_logic_vector(15 downto 0);
	signal fifo_out_full : std_logic; 
	signal fifo_out_empty : std_logic;
	signal fifo_out_read : std_logic;
	signal fifo_out_write : std_logic;

	signal fifo_in_data_in : std_logic_vector(9 downto 0);
	signal fifo_in_data_out : std_logic_vector(9 downto 0);
	signal fifo_in_fill : std_logic_vector(15 downto 0);
	signal fifo_in_rem : std_logic_vector(15 downto 0);
	signal fifo_in_full : std_logic; 
	signal fifo_in_empty : std_logic;
	signal fifo_in_read : std_logic;
	signal fifo_in_write : std_logic;

	signal rx_data : std_logic_vector(7 downto 0);
	signal rx_sof : std_logic;
	signal rx_eof : std_logic;
	signal rx_src_rdy : std_logic;
	signal rx_dst_rdy : std_logic;
	signal tx_data : std_logic_vector(7 downto 0);
	signal tx_sof : std_logic;
	signal tx_eof : std_logic;
	signal tx_src_rdy : std_logic;
	signal tx_dst_rdy : std_logic;

	signal receive_packet_en : std_logic;
	signal receive_packet_done : std_logic;
	signal process_packet_1_en : std_logic;
	signal process_packet_1_done : std_logic;
	signal process_packet_2_en : std_logic;
	signal process_packet_2_done : std_logic;
	signal send_packet_en : std_logic;
	signal send_packet_done : std_logic;
	signal main_step : std_logic_vector(1 downto 0);
	signal process_1_step : std_logic_vector(1 downto 0);
	signal process_2_step : std_logic_vector(1 downto 0);
	signal receive_step : std_logic_vector(1 downto 0);
	signal send_step : std_logic_vector(2 downto 0);
	signal packet_process_error : std_logic;
	signal store_word : std_logic;
	signal stored_word : std_logic_vector(7 downto 0);
begin

	icon_i : icon
	port map (
		control0 => control
	);
	
	ila_i : ila
	port map (
		control => control, clk => clk, trig0 => trig0, trig1 => trig1, trig2 => trig2, trig3 => trig3,
		trig4 => trig4,	trig5 => trig5,	trig6 => trig6,	trig7 => trig7
	);

	trig0(15 downto 0) <= main_step & receive_step & process_1_step & process_2_step & send_step & "0000" & rst;
	trig1( 7 downto 0) <= receive_packet_en & receive_packet_done & process_packet_1_en & process_packet_1_done &
	                      process_packet_2_en & process_packet_2_done & send_packet_en & send_packet_done;
	trig2(15 downto 0) <= noc_rx_sof & noc_rx_eof & noc_rx_src_rdy & rx_dst_rdy_2_noc &
	                      rx_sof & rx_eof & rx_src_rdy & rx_dst_rdy &
	                      tx_sof & tx_eof & tx_src_rdy & tx_dst_rdy &
	                      tx_sof_2_noc & tx_eof_2_noc & tx_src_rdy_2_noc & noc_tx_dst_rdy;
	trig3(31 downto 0) <= noc_rx_data(7 downto 0) & rx_data(7 downto 0) & tx_data(7 downto 0) & tx_data_2_noc(7 downto 0);
	trig4(31 downto 0) <= fifo_in_data_in(9 downto 0) & fifo_in_data_out(9 downto 0) & fifo_in_fill(11 downto 0);
	trig5( 3 downto 0) <= fifo_in_full & fifo_in_empty & fifo_in_read & fifo_in_write;
	trig6(31 downto 0) <= fifo_out_data_in(9 downto 0) & fifo_out_data_out(9 downto 0) & fifo_out_fill(11 downto 0);
	trig7( 3 downto 0) <= fifo_out_full & fifo_out_empty & fifo_out_read & fifo_out_write;

	main_fsm : process (clk, rst) is
	begin
		if (rst='1') then
			receive_packet_en <= '0';
			process_packet_1_en <= '0';
			process_packet_2_en <= '0';
			send_packet_en <= '0';
			main_step <= "00";
		elsif (rising_edge(clk)) then
			receive_packet_en <= '0';
			process_packet_1_en <= '0';
			process_packet_2_en <= '0';
			send_packet_en <= '0';
			case main_step is
				when "00" => -- wait until fsm+core are configured
					if (configuring = '0') then
						main_step <= "01";
					end if;
				when "01" => -- get packet from noc
					receive_packet_en <= '1';
					if (receive_packet_done = '1') then
						main_step <= "10";
					end if;
				when "10" => -- process packet in functional block
					process_packet_1_en <= '1';
					process_packet_2_en <= '1';
					if (process_packet_1_done = '1' and process_packet_2_done = '1') then
						if (packet_process_error = '1') then
							main_step <= "01"; -- this should not happen (there was no packet in fifo_in)
						else
							main_step <= "11";
						end if;
					end if;
				when "11" => -- send processed packet to noc
					send_packet_en <= '1';
					if (send_packet_done = '1') then
						main_step <= "01";
					end if;
				when others =>
					main_step <= "01";
			end case;
		end if;
	end process;

	receive_packet_fsm : process (clk, rst, receive_packet_en) is -- receive packet from noc (and store it to fifo_in)
	begin
		if (rst='1' or receive_packet_en='0') then
			fifo_in_write <= '0';
			noc_rx_dst_rdy <= '0';
			rx_dst_rdy_2_noc <= '0';
			fifo_in_data_in (9 downto 0) <= (others => '0');
			receive_packet_done <= '0';
			receive_step <= "00";
		elsif (rising_edge(clk)) then
			noc_rx_dst_rdy <= '1';
			rx_dst_rdy_2_noc <= '1';
			fifo_in_write <= '0';
			receive_packet_done <= '0';
			case receive_step is
				when "00" => -- get start of frame
					if (noc_rx_src_rdy='1' and noc_rx_sof='1' and rx_dst_rdy_2_noc='0') then -- src_rdy='1' before dst_rdy='1'
						fifo_in_write <= '0';
						fifo_in_data_in (7 downto 0) <= noc_rx_data (7 downto 0);
						fifo_in_data_in (8) <= '1'; -- sof
						fifo_in_data_in (9) <= '0'; -- eof
						receive_step <= "01";
					elsif (noc_rx_src_rdy='1' and noc_rx_sof='1') then
						fifo_in_write <= '1';
						fifo_in_data_in (7 downto 0) <= noc_rx_data (7 downto 0);
						fifo_in_data_in (8) <= '1'; -- sof
						fifo_in_data_in (9) <= '0'; -- eof
						receive_step <= "01";
					end if;
				when "01" => -- get rest of packet
					fifo_in_data_in (7 downto 0) <= noc_rx_data (7 downto 0);
					if (noc_rx_src_rdy='1' and noc_rx_eof='1') then
						fifo_in_write <= '1';
						fifo_in_data_in (8) <= '0';
						fifo_in_data_in (9) <= '1';
						noc_rx_dst_rdy <= '0';
						rx_dst_rdy_2_noc <= '0';
						receive_step <= "11";
					elsif (noc_rx_src_rdy='1') then
						fifo_in_write <= '1';
						fifo_in_data_in (8) <= noc_rx_sof;
						fifo_in_data_in (9) <= noc_rx_eof;
					end if;
				when "11" => -- successfully stored entire packetin fifo_in
					noc_rx_dst_rdy <= '0';
					rx_dst_rdy_2_noc <= '0';
					receive_packet_done <= '1';
				when others =>
					receive_step <= "00";
			end case;
		end if;
	end process;

	send_packet_fsm : process (clk, rst, send_packet_en) is -- send packet from fifo_out to noc
	begin
		if (rst='1' or send_packet_en='0') then
			noc_tx_src_rdy <= '0';
			noc_tx_sof <= '0';
			noc_tx_eof <= '0';
			tx_src_rdy_2_noc <= '0';
			tx_sof_2_noc <= '0';
			tx_eof_2_noc <= '0';
			noc_tx_data <= (others=>'0');
			tx_data_2_noc <= (others=>'0');
			store_word <= '0';
			stored_word <= (others=>'0');
			fifo_out_read <= '0';
			send_packet_done <= '0';
			send_step <= "000";
		elsif (rising_edge(clk)) then
			send_packet_done <= '0';
			noc_tx_src_rdy <= '1';
			noc_tx_sof <= '0';
			noc_tx_eof <= '0';
			tx_src_rdy_2_noc <= '1';
			tx_sof_2_noc <= '0';
			tx_eof_2_noc <= '0';
			fifo_out_read <= '0';
			case send_step is
				when "000" => -- store first word
					noc_tx_data(7 downto 0) <=   "00000001"; --fifo_out_data_out(7 downto 0); -- test : ( TODO change this line back to fifo_out_data ) 
					tx_data_2_noc(7 downto 0) <= "00000001"; --fifo_out_data_out(7 downto 0); -- test: ( TODO change this line back to fifo_out_data ) 
					noc_tx_sof <= '1';
					noc_tx_eof <= '0';
					tx_sof_2_noc <= '1';
					tx_eof_2_noc <= '0';
					fifo_out_read <= '1';
					if (fifo_out_fill<2) then
						send_step <= "111";  -- this should not happen
					else
						send_step <= "001";
					end if;
				when "001" => -- store second word -- bugfix: do not send second byte twice
					noc_tx_sof <= '1';
					noc_tx_eof <= '0';
					tx_sof_2_noc <= '1';
					tx_eof_2_noc <= '0';
					stored_word <= fifo_out_data_out(7 downto 0);
					store_word <= '1';
					fifo_out_read <= '1';
					if (fifo_out_fill<2) then
						send_step <= "111";  -- this should not happen
					else
						send_step <= "010"; -- bugfix: do not send second byte twice (2nd)
					end if;
				when "010" => 
					noc_tx_src_rdy <= '1';
					noc_tx_sof <= '1';
					noc_tx_eof <= '0';
					tx_sof_2_noc <= '1';
					tx_eof_2_noc <= '0';
					if (fifo_out_empty='0' and noc_tx_dst_rdy='1') then
						fifo_out_read <= '1';
						noc_tx_sof <= '0';
						noc_tx_data <= stored_word; --fifo_out_data_out (7 downto 0); -- bugfix: do not send second byte twice
						tx_data_2_noc(7 downto 0) <= stored_word; --fifo_out_data_out(7 downto 0); -- bugfix: do not send second byte twice
						send_step <= "011";
					elsif (fifo_out_empty='1') then -- this should not happen
						send_step <= "111";
					end if;
				when "011" => 
					noc_tx_data <= fifo_out_data_out (7 downto 0);
					tx_data_2_noc(7 downto 0) <= fifo_out_data_out(7 downto 0);
					noc_tx_sof <= '0';
					tx_sof_2_noc <= '0';
					if (fifo_out_fill<2 and noc_tx_dst_rdy='1') then -- last byte of packet
						noc_tx_eof <= '1';
						tx_eof_2_noc <= '1';
						fifo_out_read <= '1';
						send_step <= "111";						
					--elsif  (store_word = '1' and fifo_out_empty='0' and noc_tx_dst_rdy='1') then -- bugfix-idea: do not send second byte twice 
					--	store_word <= '0';
					--	noc_tx_data <= stored_word;
					--	tx_data_2_noc(7 downto 0) <= stored_word;
					elsif (fifo_out_empty='0' and noc_tx_dst_rdy='1') then -- 'middle' bytes
						noc_tx_eof <= '0';
						tx_eof_2_noc <= '0';
						fifo_out_read <= '1';
					end if;
				when "111" => -- successfully sent entire packet to noc
					if (fifo_out_empty='0') then -- this should not happen
						fifo_out_read <= '1';
					end if;
					noc_tx_src_rdy <= '0';
					tx_src_rdy_2_noc <= '0';
					send_packet_done <= '1';
				when others =>
					send_step <= "000";
			end case;
		end if;
	end process;

	process_packet_1_fsm : process (clk, rst, process_packet_1_en) is -- forward packet to functional block (from fifo_in)
	begin
		if (rst='1' or process_packet_1_en='0') then
			rx_sof <= '0';
			rx_eof <= '0';
			rx_src_rdy <= '0';
			rx_data <= (others=>'0');
			fifo_in_read <= '0';
			packet_process_error <= '0';
			process_packet_1_done <= '0';
			process_1_step <= "00";
		elsif (rising_edge(clk)) then
			rx_sof <= '0';
			rx_eof <= '0';
			rx_src_rdy <= '0';
			rx_data <= (others=>'0');
			process_packet_1_done <= '0';
			fifo_in_read <= '0';
			case process_1_step is
				when "00" => -- get first byte of packet
					if (fifo_in_empty = '1') then
						packet_process_error <= '1';
						process_1_step <= "11"; -- this should not happen
					elsif (rx_dst_rdy = '1') then
						rx_src_rdy <= '0'; --'1';--bugfix: send first byte only once (2nd fix)
						rx_sof <= '0'; --'1'; --bugfix: send first byte only once
						rx_eof <= '0';
						rx_data <= fifo_in_data_out(7 downto 0);
						fifo_in_read <= '1';
						process_1_step <= "01";
					end if;
				when "01" => -- get rest of packet
					rx_data <= fifo_in_data_out(7 downto 0);
					rx_sof <= fifo_in_data_out(8); --'0'; --fifo_in_data_out(8); --bugfix: send first byte only once
					rx_eof <= '0'; --fifo_in_data_out(9);
					rx_src_rdy <= '1';
					if (rx_dst_rdy = '1') then
						--if (fifo_in_empty = '1') then
						if (fifo_in_fill < 2) then --bugfix: send last byte correctly
							rx_eof <= '1';
							fifo_in_read <= '1'; -- '0';
							process_1_step <= "11";
						else
							fifo_in_read <= '1';
							--main_step <= "01";
						end if;
					end if;
				when "11" => -- forwarded entire packet to functional block
					process_packet_1_done <= '1';
				when others =>
					process_1_step <= "00";
			end case;
		end if;
	end process;	

	process_packet_2_fsm : process (clk, rst, process_packet_2_en) is -- receive packet from functional block (and store it in fifo_out)
	begin
		if (rst='1' or process_packet_2_en='0') then
			tx_dst_rdy <= '0';
			fifo_out_write <= '0';
			fifo_out_data_in(9 downto 0) <= (others => '0');
			process_packet_2_done <= '0';
			process_2_step <= "00";
		elsif (rising_edge(clk)) then
			process_packet_2_done <= '0';
			tx_dst_rdy <= '1';
			fifo_out_write <= '0';
			case process_2_step is
				when "00" => -- write first byte of packet
					if (packet_process_error='1') then
						tx_dst_rdy <= '0';
						process_2_step <= "11";
					elsif (fifo_out_empty = '1' and tx_src_rdy = '1' and tx_sof = '1') then
						fifo_out_write <= '1';
						fifo_out_data_in(7 downto 0) <= tx_data(7 downto 0);
						fifo_out_data_in(8) <= tx_sof;
						fifo_out_data_in(9) <= tx_eof;
						process_2_step <= "01";
					end if;
				when "01" => -- write rest of packet
					if (tx_src_rdy = '1') then
						fifo_out_write <= '1';
						fifo_out_data_in(7 downto 0) <= tx_data(7 downto 0);
						fifo_out_data_in(8) <= tx_sof;
						--fifo_out_data_in(9) <= tx_eof;
						if (tx_eof = '1' or fifo_out_full='1') then -- fifo_out_full='1' should not happen
							fifo_out_data_in(9) <= '1';
							process_2_step <= "11";
						else
							fifo_out_data_in(9) <= tx_eof;
						end if;
					end if;
				when "11" => -- successfully stored entire packet to fifo out
					fifo_out_write <= '0';
					tx_dst_rdy <= '0';
					process_packet_2_done <= '1';
				when others =>
					process_2_step <= "00";
			end case;
		end if;
	end process;

	aes_corede_inst : aesCoreDe 
	port map (
		clk => clk,
		rst => rst,
		startTransmitKey => startTransmitKey,
		key256In => key256In,
		modeIn => modeIn,
		globalLocalAddrIn =>globalLocalAddrIn,
		keyInjected =>keyInjected,
		noc_rx_sof => rx_sof,
		noc_rx_eof => rx_eof,
		noc_rx_data => rx_data,
		noc_rx_src_rdy => rx_src_rdy, 
		noc_rx_direction => noc_rx_direction,
		noc_rx_priority => noc_rx_priority,
		noc_rx_latencyCritical=> noc_rx_latencyCritical,
		noc_rx_srcIdp => noc_rx_srcIdp,
		noc_rx_dstIdp => noc_rx_dstIdp,
		noc_rx_dst_rdy => rx_dst_rdy,	      
		noc_tx_sof => tx_sof, 		
		noc_tx_eof => tx_eof,
		noc_tx_data => tx_data,		
		noc_tx_src_rdy => tx_src_rdy,		
		noc_tx_globalAddress => noc_tx_globalAddress,	
		noc_tx_localAddress => noc_tx_localAddress,
		noc_tx_direction => noc_tx_direction,		
		noc_tx_priority => noc_tx_priority,		
		noc_tx_latencyCritical=> noc_tx_latencyCritical,	
		noc_tx_srcIdp => noc_tx_srcIdp,	
		noc_tx_dstIdp => noc_tx_dstIdp,
		noc_tx_dst_rdy => tx_dst_rdy
	);

	fifo_in_inst : fifo32
	generic map (
		C_FIFO32_WORD_WIDTH => 10,
		C_FIFO32_DEPTH  => 1600,
		CLOG2_FIFO32_DEPTH => 11,
		C_FIFO32_CONTROLSIGNAL_WIDTH => 16,
		C_FIFO32_SAFE_READ_WRITE => true
	)
	port map (
		Rst            	=> rst, 
		FIFO32_S_Clk   	=> clk,
		FIFO32_M_Clk   	=> clk,
		FIFO32_S_Data  	=> fifo_in_data_out,
		FIFO32_M_Data  	=> fifo_in_data_in, 
		FIFO32_S_Fill   => fifo_in_fill,
		FIFO32_M_Rem    => fifo_in_rem,
		FIFO32_S_Full  	=> fifo_in_full, 
		FIFO32_M_Empty 	=> fifo_in_empty, 
		FIFO32_S_Rd    	=> fifo_in_read, 
		FIFO32_M_Wr    	=> fifo_in_write
	);

	fifo_out_inst : fifo32
	generic map (
		C_FIFO32_WORD_WIDTH => 10,
		C_FIFO32_DEPTH  => 1600,
		CLOG2_FIFO32_DEPTH => 11,
		C_FIFO32_CONTROLSIGNAL_WIDTH => 16,
		C_FIFO32_SAFE_READ_WRITE => true
	)
	port map (
		Rst            	=> rst, 
		FIFO32_S_Clk   	=> clk,
		FIFO32_M_Clk   	=> clk,
		FIFO32_S_Data  	=> fifo_out_data_out,
		FIFO32_M_Data  	=> fifo_out_data_in, 
		FIFO32_S_Fill   => fifo_out_fill,
		FIFO32_M_Rem    => fifo_out_rem,
		FIFO32_S_Full  	=> fifo_out_full, 
		FIFO32_M_Empty 	=> fifo_out_empty, 
		FIFO32_S_Rd    	=> fifo_out_read, 
		FIFO32_M_Wr    	=> fifo_out_write
	);
	
end architecture;
