
-- mapps hashes to idps
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

entity add_header_tb is
 
end add_header_tb;

architecture Behavioral of add_header_tb is
	
	component add_header is
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
end component;
	
	signal clk : std_logic;
	signal rst : std_logic;
	signal hash : std_logic_vector(63 downto 0);
	signal idp_in : std_logic_vector(31 downto 0);
	signal set_idp : std_logic;
	signal get_idp : std_logic;
	signal idp_out : std_logic_vector(31 downto 0);
	signal address_in : std_logic_vector(5 downto 0);
	signal address_out : std_logic_vector(5 downto 0);
	signal set_address : std_logic;
	signal get_address : std_logic;
	signal idp_valid : std_logic;
	signal int_idp_valid : std_logic;
	signal int_idp_valid_next : std_logic;
	signal address_valid : std_logic;
	signal dst_address : std_logic_vector(5 downto 0);
	
	type testing_state_t is (STATE_INIT, STATE_SET_1, STATE_SET_2, STATE_SET_3, STATE_GET, STATE_GET_2, STATE_SET_ADDR, STATE_DUMMY, STATE_SEND);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;
		
	
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);
	signal direction : std_logic;
	signal priority : std_logic;
	signal latency_critical : std_logic_vector(1 downto 0); 
	signal src_idp : std_logic_vector(31 downto 0);
	signal dst_idp : std_logic_vector(31 downto 0);
	
	signal rx_ll_data : std_logic_vector(7 downto 0);
	signal rx_ll_sof_n : std_logic;
	signal rx_ll_eof_n : std_logic;
	signal rx_ll_src_rdy_n : std_logic;
	signal rx_ll_dst_rdy_n : std_logic;
	
	signal tx_data : std_logic_vector(7 downto 0);
	signal tx_sof : std_logic;
	signal tx_eof : std_logic;
	signal tx_src_rdy : std_logic;
	signal tx_dst_rdy : std_logic;
	
	signal config_done : std_logic;
	
	signal packet_len : integer range 0 to 1500;
	signal cur_len : integer range 0 to 1500;
	signal cur_len_next : integer range 0 to 1500;
	type packet_state_t is ( P_STATE_SEND, P_STATE_SOF, P_STATE_INIT, P_STATE_HASH, P_STATE_ETH_HDR );
	signal packet_state : packet_state_t;
	signal packet_state_next : packet_state_t;
	
	type receiving_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state 	    : receiving_state_t;
	signal testing_state_next   : receiving_state_t;

	signal rx_packet_count 	    : std_logic_vector(31 downto 0);
	signal rx_packet_count_next : std_logic_vector(31 downto 0);
	
	
begin


	add_header_inst : add_header
	port map (
		i_clk		=> clk, 
  		i_rst		=> rst, 
  	    	-- comm with PHY
  	    	o_tx_ll_data    => rx_ll_data,    
        	o_tx_ll_sof_n   => rx_ll_sof_n,    
        	o_tx_ll_eof_n   => rx_ll_eof_n,    
        	o_tx_ll_src_rdy_n  => rx_ll_src_rdy_n, 
        	i_tx_ll_dst_rdy_n  => rx_ll_dst_rdy_n, 
  	
  		-- comm with previous blocks (with internal switch)
  		i_rx_sof => tx_sof,
  		i_rx_eof => tx_eof,
  		i_rx_data => tx_data,
  		i_rx_src_rdy => tx_src_rdy,
  		o_rx_dst_rdy => tx_dst_rdy,
  
  		i_src_idp => src_idp,
  		i_dst_idp => dst_idp
  			 
    );


   
  	packet_len  <= 64;
	rx_ll_dst_rdy_n  <= '0';
	config_done <= '1';
	
	src_idp <= x"CDEFFEDC";
	dst_idp <= x"12344321";
	
	packets : process(packet_state, packet_len, cur_len, config_done, tx_dst_rdy) is
	begin
	tx_sof  <= '0';
	tx_eof  <= '0';
	tx_src_rdy  <= '1';
	tx_data  <= "01100001";
	cur_len_next  <= cur_len;
	packet_state_next  <= packet_state;
	case packet_state is
	when P_STATE_INIT  => 
		if config_done = '1' then
			packet_state_next  <= P_STATE_SOF;
		end if;
	when P_STATE_SOF  => 
		tx_sof  <= '1';
		tx_data  <= "11111111";
		if tx_dst_rdy = '1' then	
			packet_state_next  <= P_STATE_ETH_HDR;
			cur_len_next  <= 1;
		end if;
	when P_STATE_ETH_HDR  => 
		tx_data  <= "11111111";
		if tx_dst_rdy = '1' then
			cur_len_next  <= cur_len + 1;
			if cur_len = 13 then
				packet_state_next  <= P_STATE_HASH;
			end if;
		end if;
		
	when P_STATE_HASH  => 
		tx_data  <= x"AB";
		if tx_dst_rdy = '1' then
			cur_len_next  <= cur_len + 1;
			if cur_len = 21 then
				packet_state_next  <= P_STATE_SEND;
			end if;
		end if;
		
	when P_STATE_SEND  => 
		if tx_dst_rdy = '1' then
			if cur_len = packet_len then
				tx_eof  <= '1';
				packet_state_next  <= P_STATE_INIT;
			end if;
			cur_len_next  <= cur_len + 1;
		end if;
	end case;
	end process;

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
		    if rx_ll_src_rdy_n = '1' and (rx_ll_sof_n = '1' or rx_ll_eof_n = '1') and rx_ll_dst_rdy_n = '1' then
			tmp := unsigned(rx_packet_count) + 1;
			rx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
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
	
	--creates flipflops
	memzing: process(clk, rst)
	begin
	    if rst = '1' then
			state  <= STATE_INIT;
			int_idp_valid  <= '0';
			cur_len  <= 0;
			packet_state  <= P_STATE_INIT;
			rx_packet_count  <= (others  => '0');
			testing_state  <= T_STATE_INIT;
	    elsif rising_edge(clk) then
	     	state  <= state_next;
	     	int_idp_valid  <= int_idp_valid_next;
	     	cur_len  <= cur_len_next;
	     	packet_state  <= packet_state_next;
	     	testing_state  <= testing_state_next;
	     	rx_packet_count  <= rx_packet_count_next;
	    end if;
	end process;
	
		
end architecture;
