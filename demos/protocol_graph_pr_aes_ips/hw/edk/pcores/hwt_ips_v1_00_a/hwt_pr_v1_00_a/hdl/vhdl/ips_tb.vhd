--use std.textio.all;
library ieee;
--use ieee.std_logic_textio.all;  -- read and write overloaded for std_logic
use ieee.std_logic_1164.all;


entity ips_tb is
	-- a testbench does not connect to any higher-level hierarchy.
end entity ips_tb;


architecture RTL of ips_tb is
	

	--      	data & control signals:	
	signal  	rx_ll_sof              	: std_logic;
	signal  	rx_ll_eof              	: std_logic;
	signal  	rx_ll_data             	: std_logic_vector(7 downto 0);
	signal  	rx_ll_src_rdy          	: std_logic;
	signal  	rx_ll_dst_rdy          	: std_logic;
	signal  	tx_ll_sof              	: std_logic;
	signal  	tx_ll_eof              	: std_logic;
	signal  	tx_ll_data             	: std_logic_vector(7 downto 0);
	signal  	tx_ll_src_rdy          	: std_logic;
	signal  	tx_ll_dst_rdy          	: std_logic;
	--      	packets (stimuli):     	
	signal  	packet_len             	: integer	range 0 to 1500;
	signal  	cur_len                	: integer	range 0 to 1500;
	signal  	cur_len_next           	: integer	range 0 to 1500;
	type    	packet_state_t         	is( P_STATE_SEND, P_STATE_INIT, P_SLEEP, P_WAIT );
	signal  	packet_state           	: packet_state_t;
	signal  	packet_state_next      	: packet_state_t;
	type    	packet_payload_type    	is array(0 to 1500)	of std_logic_vector(7 downto 0);
	signal  	packet_tx_payload      	: packet_payload_type;
	signal   packet_tx_payload_evil  : packet_payload_type;
	--      	clock and reset:       	
	signal  	clk                    	: std_logic;
	signal  	rst                    	: std_logic;
	constant	RESET                  	: std_logic	:= '1'; -- define if rst is active low or active high
	--      	constants used by IPS  	
	constant	GOOD_FORWARD           	: std_logic	:= '1'; -- used constants instead of a "type" to simplify queuing.
	constant	EVIL_DROP              	: std_logic	:= '0';

	-- a spacer, can be used in packets
	constant	SPACER	: std_logic_vector(7 downto 0)	:= x"58"; -- capital X

	-- statistics signals
	constant	OSIF_MBOX_WIDTH     	: integer		:= 32; 
	signal  	stat_recv_packets   	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal  	stat_forw_packets   	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal  	stat_drop_packets   	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);
	signal  	config_header_length	: std_logic_vector(OSIF_MBOX_WIDTH-1 downto 0);	

	signal packet_count : integer;



	
	-- some debug signals (TODO completely remove these)
	-- signal	debug_fifo_read    	:	std_logic;
	-- signal	debug_fifo_write   	:	std_logic;
	-- signal	debug_severe_error 	:	std_logic;
	-- signal	debug_result_result	:	std_logic;
	-- signal	debug_result_valid 	:	std_logic;

	
	-- the TB has only one component, which ist the entity to be tested (model under test, MUT):
	component ips is
		generic (
			RECONOS_OSIF_MBOX_WIDTH	:	integer	:= OSIF_MBOX_WIDTH
		); 
		port (
			-- -- debug signals
			-- debug_fifo_read    	:	in 	std_logic;
			-- debug_fifo_write   	:	in 	std_logic;
			-- debug_severe_error 	:	out	std_logic; 
			-- debug_result_result	:	in 	std_logic; 
			-- debug_result_valid 	:	in 	std_logic; 
			-- everything else    	
			rst                   	:	in 	std_logic;
			clk                   	:	in 	std_logic;
			rx_ll_sof             	:	in 	std_logic;
			rx_ll_eof             	:	in 	std_logic;
			rx_ll_data            	:	in 	std_logic_vector(7 downto 0);
			rx_ll_src_rdy         	:	in 	std_logic;
			rx_ll_dst_rdy         	:	out	std_logic;
			tx_ll_sof             	:	out	std_logic;
			tx_ll_eof             	:	out	std_logic;
			tx_ll_data            	:	out	std_logic_vector(7 downto 0);
			tx_ll_src_rdy         	:	out	std_logic;
			tx_ll_dst_rdy         	:	in 	std_logic;
			stat_recv_packets     	:	out	std_logic_vector(RECONOS_OSIF_MBOX_WIDTH-1 downto 0);
			stat_forw_packets     	:	out	std_logic_vector(RECONOS_OSIF_MBOX_WIDTH-1 downto 0);
			stat_drop_packets     	:	out	std_logic_vector(RECONOS_OSIF_MBOX_WIDTH-1 downto 0); 
			config_header_length  	:	in 	std_logic_vector(RECONOS_OSIF_MBOX_WIDTH-1 downto 0)
		);
	end component;
	

begin

	packet_len  <= 64; -- is constant for the moment

	-- Uncomment next line to perform TEST: receiver not ready in a certaint time period.
	--rx_ll_dst_rdy  <= '1', '0' after 1.78 ms, '1' after 2.5111 ms, '0' after 3.145 ms, '1' after 3.3 ms;

	-- Uncomment next line to perform TEST: sender not ready in a certaint time period.
	--tx_ll_src_rdy	<= '1', '0' after 2.3333 ms, '1' after 3.2222 ms;
	
	
	--rx_ll_dst_rdy  <= '1', '0' after 1.79 ms, '1' after 2.50 ms, '0' after 3.03 ms, '1' after 3.3 ms;
	rx_ll_dst_rdy  <= '0', '1' after 1.79 ms; --, '1' after 2.50 ms, '0' after 3.03 ms, '1' after 3.3 ms;
	--tx_ll_src_rdy	<= '1', '0' after 2.34 ms, '1' after 3.20 ms;
	--tx_ll_src_rdy	<= '1';
	--rx_ll_dst_rdy <= '1';


	-- some general hexspeak packets:
	-- packet_tx_payload <= (	x"de", -- four dead beef :-(
	--                       	x"ad", 
	--                       	x"be", 
	--                       	x"ef", 
	--                       	x"00", 
	--                       	x"de", 
	--                       	x"ad", 
	--                       	x"be", 
	--                       	x"ef", 
	--                       	x"00", 
	--                       	x"de", 
	--                       	x"ad", 
	--                       	x"be", 
	--                       	x"ef", 
	--                       	x"00", 
	--                       	x"de", 
	--                       	x"ad", 
	--                       	x"be", 
	--                       	x"ef", 
	--                       	x"00",	-- and 2 counters
	--                       	x"11",
	--                       	x"22", 
	--                       	x"33", 
	--                       	x"44", 
	--                       	x"55", 
	--                       	x"66", 
	--                       	x"77", 
	--                       	x"88", 
	--                       	x"99", 
	--                       	x"aa", 
	--                       	x"bb", 
	--                       	x"cc", 
	--                       	x"dd", 
	--                       	x"ee", 
	--                       	x"ff", 
	--                       	x"00",
	--                       	x"11",
	--                       	x"22", 
	--                       	x"33", 
	--                       	x"44", 
	--                       	x"55", 
	--                       	x"66", 
	--                       	x"77", 
	--                       	x"88", 
	--                       	x"99", 
	--                       	x"aa", 
	--                       	x"bb", 
	--                       	x"cc", 
	--                       	x"dd", 
	--                       	x"ee", 
	--                       	x"ff", 
	--                       	others => "00000000"
	-- );


	-- UTF-8 packets:
	packet_tx_payload <= (	--x"61",         	-- a
--	                      	x"62",         	-- b
--	                      	x"63",         	-- c
--	                      	--x"c0", x"af",	-- Attack - Should be ignored when still in the header
--	                      	x"64",         	-- d
--	                      	x"65",         	-- e
--	                      	x"66",         	-- f
--	                      	x"67",         	-- g
--	                      	x"68",         	-- h
--	                      	x"69",         	-- i
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	-- some invalid bytes "10xxxxxx", but not a non-shortest form.
--	                      	x"49", x"3a",       	-- I:, an identitier to find them in the simulation later.
--	                      	x"9f", x"92", x"a9",	-- the actual data.
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	-- and some valid (multibyte) characters: 
--	                      	x"56", x"3a", -- V:, identifier
--	                      	--x"", x"", x"", x"", SPACER,      	-- boilerplate
--	                      	x"5f", SPACER,                     	-- underscore _
--	                      	x"c3", x"a4", SPACER,              	-- a Umlaut a.k.a. 'LATIN SMALL LETTER A WITH DIAERESIS' (U+00E4)
--	                      	x"e6", x"b8", x"af", SPACER,       	-- Han Character 'port, harbor; small stream; bay' (U+6E2F)
--	                      	x"f0", x"9f", x"92", x"a9", SPACER,	-- 'PILE OF POO' (U+1F4A9)
--	                      	-- TODO add more characters s.t. all possible bit length are tested.
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	SPACER, 
--	                      	-- The attack:
--	                      	x"41", x"3a",	-- A:
--	                      	x"2e",       	-- ../
--	                      	x"2e",       	
--	                      	x"2f",       	
--	                      	SPACER,      	
--	                      	x"2e",       	-- ../ again, but with the / as... 
--	                      	x"2e",       	
--	                      	-- uncomment one of the next three lines to send an attack.
--	                      	--x"c0", x"af",              	-- ...2-byte...
--	                      	--x"e0", x"80", x"af",       	-- ...3-byte...
--	                      	--x"f0", x"80", x"80", x"af",	-- ...or 4-byte non-shortest form.
--	                      	-- TODO add more invalid characters s.t. all possible bit length are tested.
				x"01", x"02", x"03" , x"04" , x"05" , x"06" , x"07" , x"08" , x"09" , x"0a" , x"0b", x"0c" , x"0d" , x"0e" , x"0f" ,  x"10" ,
				x"11", x"12", x"13" , x"14" , x"15" , x"16" , x"17" , x"18" , x"19" , x"1a" , x"1b", x"1c" , x"1d" , x"1e" , x"1f" ,  x"20" ,
				x"21", x"22", x"23" , x"24" , x"25" , x"26" , x"27" , x"28" , x"29" , x"2a" , x"2b", x"2c" , x"2d" , x"2e" , x"2f" ,  x"30" ,
				x"31", x"32", x"33" , x"34" , x"35" , x"36" , x"37" , x"38" , x"39" , x"3a" , x"3b", x"3c" , x"3d" , x"3e" , x"3f" ,  x"40" ,
				x"41", x"42", x"43" , x"44" , x"45" , x"46" , x"47" , x"48" , x"49" , x"4a" , x"4b", x"4c" , x"4d" , x"4e" , x"4f" ,  x"50" ,
	                      	others => SPACER
	);
	
	
	packet_tx_payload_evil <= (	x"01", x"02", x"03" , x"04" , x"05" , x"06" , x"07" , x"08" , x"09" , x"0a" , x"0b", x"0c" , x"0d" , x"0e" , x"0f" ,  x"10" ,
				x"11", x"12", x"13" , x"14" , x"15" , x"16" , x"17" , x"18" , x"19" , x"1a" , x"1b", x"1c" , x"1d" , x"1e" , x"1f" ,  x"20" ,
				x"21", x"22", x"23" , x"24" , x"25" , x"26" , x"27" , x"28" , x"29" , x"2a" , x"2b", x"2c" , x"2d" , x"2e" , x"2f" ,  x"30" ,
				x"e0", x"80", x"80", x"80", --attach
				x"31", x"32", x"33" , x"34" , x"35" , x"36" , x"37" , x"38" , x"39" , x"3a" , x"3b", x"3c" , x"3d" , x"3e" , x"3f" ,  x"40" ,
				x"41", x"42", x"43" , x"44" , x"45" , x"46" , x"47" , x"48" , x"49" , x"4a" , x"4b", x"4c" , x"4d" , x"4e" , x"4f" ,  x"50" ,
	                      	others => SPACER
	);

	-- the first x bits will not be checked.
	--config_header_length	<= "00000000000000000000000000000100"; 
	config_header_length	<= "00000000000000000000000000000001"; 
	
	
	send_packets: process(clk, rst) is
		variable cnt : natural range 0 to 1600;
	begin
		if (rst='1') then
			tx_ll_sof        	<= '0'; 
			tx_ll_eof        	<= '0';
			tx_ll_data       	<= packet_tx_payload(0);
			tx_ll_src_rdy	   <= '0';
			cur_len     		<= 0;
			packet_state		<= P_SLEEP; --P_STATE_INIT;
			packet_count      <= 0;
			cnt := 0;
		elsif (rising_edge(clk)) then
			tx_ll_src_rdy	   <= '1';
			tx_ll_sof        	<= '0'; 
			tx_ll_eof        	<= '0';
			--tx_ll_data       	<= packet_tx_payload(cur_len);
			if (packet_count=3) then
				tx_ll_data       	<= packet_tx_payload_evil(cnt);
			else
				tx_ll_data       	<= packet_tx_payload(cnt);
			end if;
			case packet_state is
			
			   when P_SLEEP =>
					tx_ll_src_rdy	   <= '0';
					cur_len     	<= 0;
					cnt := 0;
					packet_state    	<= P_WAIT;
				
				when P_WAIT =>
					tx_ll_src_rdy	   <= '1';
					tx_ll_sof			<= '1';
					if tx_ll_dst_rdy = '1' then
						if packet_count<5 then
							tx_ll_src_rdy <= '1';
							tx_ll_sof	  <= '1'; 
							cur_len     	<= 1;
							cnt := 1;
						end if;
						if (packet_count=3) then
							tx_ll_data       	<= packet_tx_payload_evil(1);
						else
							tx_ll_data       	<= packet_tx_payload(1);
						end if;
						packet_state    	<= P_STATE_INIT;
					end if;

				when P_STATE_INIT  => 
					cur_len     	<= 0;
					--if packet_count<5 then
						--tx_ll_sof	<= '1'; -- test without SOF
					--end if;
					---tx_ll_sof        	<= '1';
					--if tx_ll_dst_rdy = '1'  and packet_count<1 then
					--	tx_ll_sof	<= '0';
					--	packet_state	<= P_STATE_SEND;
					--	cur_len     	<= cur_len + 1;
					--	packet_count   <= packet_count + 1;
					--	cnt := 1;
					--	tx_ll_data       	<= packet_tx_payload(1);
					--els
					tx_ll_data       	<= packet_tx_payload(0);
					if tx_ll_dst_rdy = '1'  and packet_count<5 then
						tx_ll_sof	<= '0';
						packet_state	<= P_STATE_SEND;
						cur_len     	<= 2;
						packet_count   <= packet_count + 1;
						cnt := 2;
						--tx_ll_data       	<= packet_tx_payload(1);
						if (packet_count=3) then
							tx_ll_data       	<= packet_tx_payload_evil(2);
						else
							tx_ll_data       	<= packet_tx_payload(2);
						end if;
					end if;

				when P_STATE_SEND  => 
					--tx_ll_data       	<= packet_tx_payload(cnt);
					if (packet_count=3) then
						tx_ll_data       	<= packet_tx_payload_evil(cnt);
					else
						tx_ll_data       	<= packet_tx_payload(cnt);
					end if;
					if tx_ll_dst_rdy = '1' then
						cnt := cnt + 1;
						--tx_ll_data       	<= packet_tx_payload(cnt);
						if (packet_count=3) then
							tx_ll_data       	<= packet_tx_payload_evil(cnt);
						else
							tx_ll_data       	<= packet_tx_payload(cnt);
						end if;
						cur_len       	<= cur_len + 1;
						if packet_len <= cur_len + 2 then
							tx_ll_eof        	<= '1';
							packet_state    	<= P_SLEEP;
							cur_len         	<= 0;
							cnt := 0;
						end if;
					end if;
				
			end case;
			
		end if;
	end process;
	

--
--	packets : process(packet_state, packet_len, cur_len, tx_ll_dst_rdy) is
--	-- update packet contents
--	begin
--		tx_ll_sof        	<= '0'; 
--		tx_ll_eof        	<= '0';
--		tx_ll_data       	<= packet_tx_payload(cur_len);
--		cur_len_next     	<= cur_len;
--		packet_state_next	<= packet_state;
--
--		-- debug_result_result <= '0';
--		-- debug_result_valid <= '0';
--
--
--		case packet_state is
--
--			when P_STATE_INIT  => 
--				tx_ll_sof	<= '1'; -- test without SOF
--				if tx_ll_dst_rdy = '1' and tx_ll_src_rdy = '1' then
--					packet_state_next	<= P_STATE_SEND;
--					cur_len_next     	<= 1;
--				end if;
--
--			when P_STATE_SEND  => 
--				if tx_ll_dst_rdy = '1' and tx_ll_src_rdy = '1' then
--					cur_len_next        	<= cur_len + 1;
--					-- packet_state_next	<= P_STATE_SEND; -- implicitely given.
--				end if;
--				if cur_len = packet_len then
--					tx_ll_eof        	<= '1';
--					packet_state_next	<= P_STATE_INIT;
--					cur_len_next     	<= 0;
--				end if;
--
--
--				-- define here, when to send the "good" resp "bad" signal.
--				-- e.g. if cur_len = packet_len-5 then debug_result_valid	<= '1'; end if; 
--				-- if cur_len = packet_len-5 then
--				--	debug_result_result	<= EVIL_DROP;
--				--	debug_result_valid 	<= '1';
--				-- end if;
--
--		end case;
--	end process;


	rst  <= '1', '0' after 0.996 ms;
	

	clk_process :process
	-- the Clock: 100kHz
	begin
		clk <= '1';	wait for 5 us;
		clk <= '0';	wait for 5 us;
	end process;

--	memzing: process(clk, rst) is
--	-- FSM state transition
--	begin
--	    if rst = RESET then
--			cur_len     	<= 0;
--			packet_state	<= P_STATE_INIT;
--	    elsif rising_edge(clk) then
--			cur_len     	<= cur_len_next;
--			packet_state	<= packet_state_next;
--	    end if;
--	end process;
	
	fifo_contrl: process(clk, rst) is--???????
	begin
	    if rst = RESET then
			--debug_fifo_read  <= '0';
			--debug_fifo_write <= '0';
	    elsif rising_edge(clk) then
			--debug_fifo_write <= '1';
			--debug_fifo_read <= '1'; -- see process below
			-- if (debug_fifo_write = '0') then
			--	debug_fifo_read <= '0';
			-- end if;
	    end if;
	end process;

	-- process
	-- begin
	--	debug_fifo_read	<= '1';	wait for 55 us;
	--	debug_fifo_read	<= '0';	wait for 10 us;
	-- end process;


	-- instatiate 1 ips component
	ips_inst : ips 
	generic map(
		RECONOS_OSIF_MBOX_WIDTH	=> OSIF_MBOX_WIDTH
	)
	port map(
		-- debug_fifo_read     	=>	debug_fifo_read,
		-- debug_fifo_write    	=>	debug_fifo_write,
		-- debug_severe_error  	=>	debug_severe_error,
		-- debug_result_result 	=>	debug_result_result,
		-- debug_result_valid  	=>	debug_result_valid,
		-- as always           	
		rst                    	=>	rst,
		clk                    	=>	clk,
		-- what the TB sends...	is what the MUT reveives
		tx_ll_sof              	=>	rx_ll_sof,
		tx_ll_eof              	=>	rx_ll_eof,
		tx_ll_data             	=>	rx_ll_data,
		tx_ll_src_rdy          	=>	rx_ll_src_rdy,
		tx_ll_dst_rdy          	=>	rx_ll_dst_rdy,
		-- ...and vice-versa.  	
		rx_ll_sof              	=>	tx_ll_sof,
		rx_ll_eof              	=>	tx_ll_eof,
		rx_ll_data             	=>	tx_ll_data,
		rx_ll_src_rdy          	=>	tx_ll_src_rdy,
		rx_ll_dst_rdy          	=>	tx_ll_dst_rdy,
		-- statistics signals  	
		stat_recv_packets      	=>	stat_recv_packets,
		stat_forw_packets      	=>	stat_forw_packets,
		stat_drop_packets      	=>	stat_drop_packets,
		config_header_length   	=>	config_header_length
	);

end architecture RTL;
