
-- remove ethernet header
-- header format: [ dst MAC 6 bytes][ src MAC 6 bytes][ETHER TYPE 2 bytes][ connection id 8 bytes]
--!
--
--!
--! \author     Ariane Trammell
--! \date       24.07.2013
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
	
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity add_header is
	port (
		i_clk		: in std_logic;
  		i_rst		: in std_logic;
  	    	-- comm with PHY
  	    	o_tx_ll_data        : out std_logic_vector(7 downto 0);
        	o_tx_ll_sof_n       : out std_logic;
        	o_tx_ll_eof_n       : out std_logic;
        	o_tx_ll_src_rdy_n   : out std_logic;
        	i_tx_ll_dst_rdy_n   : in std_logic;
  	
  		-- comm with previous blocks (with internal switch)
  		i_rx_sof : in std_logic;
  		i_rx_eof : in std_logic;
  		i_rx_data : in std_logic_vector(7 downto 0);
  		i_rx_src_rdy : in std_logic;
  		o_rx_dst_rdy : out std_logic;
  
  		i_src_idp : in  std_logic_vector(31 downto 0);
  		i_dst_idp : in  std_logic_vector(31 downto 0)
  			 
    );
end add_header;

architecture Behavioral of add_header is
	
	
	type testing_state_t is (STATE_INIT, STATE_IDLE, STATE_ADD_HEADER_DST, STATE_ADD_HEADER_SRC, STATE_ADD_HEADER_TYPE, 
				STATE_ADD_HEADER_HASH_1, STATE_ADD_HEADER_HASH_2, STATE_FORWARD);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;

	signal counter : integer range 0 to 15;
	signal counter_next : integer range 0 to 15;
	
begin

	add_proc : process(state, i_rx_src_rdy, i_rx_sof, i_rx_eof, i_rx_data, counter, i_tx_ll_dst_rdy_n, i_src_idp, i_dst_idp	)
	begin
		state_next  <= state;
		--towards local node
		o_rx_dst_rdy <= '1';

		-- towards ethernet interface	
		o_tx_ll_src_rdy_n <= '1';
		o_tx_ll_data <= i_rx_data;
		o_tx_ll_sof_n <= '1';
		o_tx_ll_eof_n <= '1';
		
	    case state is
	    	when STATE_INIT  => 
	    		state_next  <= STATE_IDLE;
	    	when STATE_IDLE  => 
	    		if i_rx_src_rdy = '1' and i_rx_sof = '1' then
	    			state_next  <= STATE_ADD_HEADER_DST;
					o_rx_dst_rdy <= '0'; --first we need to add the header
	    			counter_next  <= 1;
	    		end if;
		when STATE_ADD_HEADER_DST =>
			o_rx_dst_rdy <= '0'; --first we need to add the header
			o_tx_ll_src_rdy_n <= '0';
			o_tx_ll_data <= x"ff";
			if counter = 1 then
				o_tx_ll_sof_n <= '0';
			end if;
			if i_tx_ll_dst_rdy_n = '0' then
				counter_next <= counter + 1;
				if counter = 6 then
					state_next <= STATE_ADD_HEADER_SRC;
					counter_next <= 1;
				end if;
			end if;
		when STATE_ADD_HEADER_SRC =>
			o_rx_dst_rdy <= '0'; --first we need to add the header
			o_tx_ll_src_rdy_n <= '0';
			o_tx_ll_data <= x"aa";
			if i_tx_ll_dst_rdy_n = '0' then
				counter_next <= counter + 1;
				if counter= 6 then
					state_next <= STATE_ADD_HEADER_TYPE;
					counter_next <= 1;
				end if;
			end if;
		when STATE_ADD_HEADER_TYPE =>
			o_rx_dst_rdy <= '0'; --first we need to add the header
			o_tx_ll_src_rdy_n <= '0';
			o_tx_ll_data <= x"ba";
			if i_tx_ll_dst_rdy_n = '0' then
				counter_next <= counter + 1;
				if counter= 2 then
					state_next <= STATE_ADD_HEADER_HASH_1;
					counter_next <= 0;
				end if;
			end if;
		when STATE_ADD_HEADER_HASH_1 =>
			o_rx_dst_rdy <= '0'; --first we need to add the header
			o_tx_ll_src_rdy_n <= '0';
			o_tx_ll_data <= i_src_idp(32 - 1 - counter*8 downto 32 - (counter + 1)*8);
			if i_tx_ll_dst_rdy_n = '0' then
				counter_next <= counter + 1;
				if counter= 3 then
					state_next <= STATE_ADD_HEADER_HASH_2;
					counter_next <= 0;
				end if;
			end if;

		when STATE_ADD_HEADER_HASH_2 =>
			o_rx_dst_rdy <= '0'; --first we need to add the header
			o_tx_ll_src_rdy_n <= '0';
			o_tx_ll_data <= i_dst_idp(32 - 1 - counter*8 downto 32 - (counter + 1)*8);
			if i_tx_ll_dst_rdy_n = '0' then
				counter_next <= counter + 1;
				if counter= 3 then
					state_next <= STATE_FORWARD;
				end if;
			end if;

		when STATE_FORWARD  => 
			o_rx_dst_rdy <= not i_tx_ll_dst_rdy_n;
			o_tx_ll_src_rdy_n <= not i_rx_src_rdy;			
			o_tx_ll_eof_n <= not i_rx_eof;
			if i_rx_eof = '1' and i_tx_ll_dst_rdy_n = '0' then
				state_next  <= STATE_IDLE;
			end if;    		 
	    		
	    	when others => 
	    		state_next  <= STATE_INIT;
	    	end case;

	end process;
	
	
	memzing: process(i_clk, i_rst)
	begin
	    if i_rst = '1' then
			state  <= STATE_INIT;
			counter  <= 0;
	   elsif rising_edge(i_clk) then
	     	state  <= state_next;
	     	counter  <= counter_next;
	end if;
	end process;
	
end architecture;
