
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

entity remove_header_tb is
 
end remove_header_tb;

architecture Behavioral of remove_header_tb is
	
	component remove_header is
	port (
		i_clk		: in std_logic;
  		i_rst		: in std_logic;
  	    -- comm with PHY
  	    i_rx_ll_data        : in std_logic_vector(7 downto 0);
        i_rx_ll_sof_n       : in std_logic;
        i_rx_ll_eof_n       : in std_logic;
        i_rx_ll_src_rdy_n   : in std_logic;
        o_rx_ll_dst_rdy_n   : out std_logic;
  	
  		-- comm with next blocks (with internal switch)
  		o_tx_sof : out std_logic;
  		o_tx_eof : out std_logic;
  		o_tx_data : out std_logic_vector(7 downto 0);
  		o_tx_src_rdy : out std_logic;
  		i_tx_dst_rdy : in std_logic;
  
  		o_global_addr : out std_logic_vector(3 downto 0);
  		o_local_addr : out std_logic_vector(1 downto 0);
  		o_direction : out std_logic;
  		o_priority : out std_logic_vector(1 downto 0);
  		o_latency_critical : out std_logic;	
  		o_src_idp : out  std_logic_vector(31 downto 0);
  		o_dst_idp : out  std_logic_vector(31 downto 0);
  		
  		-- comm to setup hash and address mapping table
		i_config_in_progress : in std_logic;
  		i_set_idp : in std_logic;
  		i_set_address : in std_logic;
  		i_hash	: in std_logic_vector(63 downto 0);
  		i_idp 	: in std_logic_vector(31 downto 0);
  		i_address : in std_logic_vector(5 downto 0)
  		 
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
	
	type testing_state_t is (STATE_INIT, STATE_SET_1, STATE_SET_2, STATE_SET_3, STATE_GET, STATE_GET_2, STATE_SET_ADDR, STATE_DUMMY, STATE_SEND, STATE_WAIT);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;
		
	
	signal global_addr : std_logic_vector(3 downto 0);
	signal local_addr : std_logic_vector(1 downto 0);
	signal direction : std_logic;
	signal priority : std_logic_vector(1 downto 0);
	signal latency_critical : std_logic; 
	signal src_idp : std_logic_vector(31 downto 0);
	signal dst_idp : std_logic_vector(31 downto 0);
	
	signal rx_data : std_logic_vector(7 downto 0);
	signal rx_sof : std_logic;
	signal rx_eof : std_logic;
	signal rx_src_rdy : std_logic;
	signal rx_dst_rdy : std_logic;
	
	signal tx_data : std_logic_vector(7 downto 0);
	signal tx_sof_n : std_logic;
	signal tx_eof_n : std_logic;
	signal tx_src_rdy_n : std_logic;
	signal tx_dst_rdy_n : std_logic;
	
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
	signal config_in_progress : std_logic;
	signal counter : integer range 0 to 100;
	signal counter_next : integer range 0 to 100;
	
	
begin
	
	remove_header_inst : remove_header
	port map (
		i_clk		 => clk,
  		i_rst		 => rst,
  	    -- comm with PHY
  	    i_rx_ll_data    => tx_data,    
        i_rx_ll_sof_n    => tx_sof_n,   
        i_rx_ll_eof_n    => tx_eof_n,   
        i_rx_ll_src_rdy_n => tx_src_rdy_n,  
        o_rx_ll_dst_rdy_n  => tx_dst_rdy_n, 
         	
  		-- comm with next blocks (with internal switch)
  		o_tx_sof => rx_sof,
  		o_tx_eof => rx_eof,
  		o_tx_data => rx_data,
  		o_tx_src_rdy => rx_src_rdy,
  		i_tx_dst_rdy => rx_dst_rdy,
  
  		o_global_addr => global_addr,
  		o_local_addr => local_addr,
  		o_direction => direction,
  		o_priority => priority,
  		o_latency_critical 	=> latency_critical,
  		o_src_idp => src_idp,
  		o_dst_idp => dst_idp,
  		
  		-- comm to setup hash and address mapping table
		i_config_in_progress => config_in_progress,
  		i_set_idp => set_idp,
  		i_set_address => set_address,
  		i_hash	=> hash,
  		i_idp 	=> idp_in,
  		i_address => address_in
	);
   
  	packet_len  <= 64;
	rx_dst_rdy  <= '1';
	
	
	packets : process(packet_state, packet_len, cur_len, config_done, tx_dst_rdy_n) is
	begin
	tx_sof_n  <= '1';
	tx_eof_n  <= '1';
	tx_src_rdy_n  <= '0';
	tx_data  <= "01100001";
	cur_len_next  <= cur_len;
	packet_state_next  <= packet_state;
	case packet_state is
	when P_STATE_INIT  => 
		if config_done = '1' then
			packet_state_next  <= P_STATE_SOF;
		end if;
	when P_STATE_SOF  => 
		tx_sof_n  <= '0';
		tx_data  <= "11111111";
		if tx_dst_rdy_n = '0' then	
			packet_state_next  <= P_STATE_ETH_HDR;
			cur_len_next  <= 1;
		end if;
	when P_STATE_ETH_HDR  => 
		tx_data  <= "11111111";
		if tx_dst_rdy_n = '0' then
			cur_len_next  <= cur_len + 1;
			if cur_len = 13 then
				packet_state_next  <= P_STATE_HASH;
			end if;
		end if;
		
	when P_STATE_HASH  => 
		tx_data  <= x"AB";
		if tx_dst_rdy_n = '0' then
			cur_len_next  <= cur_len + 1;
			if cur_len = 21 then
				packet_state_next  <= P_STATE_SEND;
			end if;
		end if;
		
	when P_STATE_SEND  => 
		if tx_dst_rdy_n = '0' then
			if cur_len = packet_len then
				tx_eof_n  <= '0';
				packet_state_next  <= P_STATE_INIT;
			end if;
			cur_len_next  <= cur_len + 1;
		end if;
	end case;
	end process;

	--count all rx packets
	test_counting : process(rx_sof, rx_src_rdy, rx_dst_rdy, rx_packet_count, testing_state) is
	variable tmp : unsigned(31 downto 0);
	begin
	    rx_packet_count_next <= rx_packet_count;
    	    testing_state_next <= testing_state;
	    case testing_state is
        	when T_STATE_INIT =>
		    rx_packet_count_next <= (others => '0');
		    testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if rx_src_rdy = '0' and (rx_sof = '0' or rx_eof = '0') and rx_dst_rdy = '0' then
			tmp := unsigned(rx_packet_count) + 1;
			rx_packet_count_next <= std_logic_vector(tmp);
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
	    end case;
	end process;



   	test_proc : process(state, idp_out, int_idp_valid, address_out, counter)
	begin
		hash  <= (others  => '0');
		idp_in  <= (others  => '0');
		set_idp  <= '0';
		get_idp  <= '0'; 
		set_address  <= '0';
		get_address  <= '0';
		address_in  <= (others  => '0');
		idp_in  <= (others  => '0');
		state_next  <= state;
		dst_address  <= (others  => '0');
		int_idp_valid_next  <= int_idp_valid;
		config_done  <= '0';
		config_in_progress <= '0';
    case state is
	    	when STATE_INIT  => 
	    		state_next  <= STATE_SET_1;
	    	when STATE_SET_1  => 
			config_in_progress <= '1';
	    		hash  <= x"ABABABABABABABAB";
	    		idp_in  <= x"12344321";
	    		set_idp  <= '1';
	    		state_next  <= STATE_SET_2;
	    	when STATE_SET_2  => 
			config_in_progress <= '1';
	    	 	hash  <= x"EEFFFFEE55667788";
	    		idp_in  <= x"56788765";
	    		set_idp  <= '1';
	    		state_next  <= STATE_WAIT;
		when STATE_WAIT => 
			config_in_progress <= '1';

			if counter > 25 then
				state_next <= STATE_SET_3;
				counter_next <= 0;
			end if;
			counter_next <= counter + 1;
			config_done <= '1'; --config is not done, but we want to see,
			--whether the module handels packet correctly that arrive
			--during reconfig.
			--end if;	
	    	when STATE_SET_3  => 
			config_in_progress <= '1';
	    		set_address  <= '1';
	    		address_in  <= "001100";
	    		idp_in  <= x"12344321";
	    		state_next  <= STATE_SEND;
	    	when STATE_GET  =>
	    		hash  <= x"EEFFFFEE55667789";
	    		get_idp  <= '1';
	    		state_next  <= STATE_GET_2;
	    	when STATE_GET_2  => 
	    		get_address  <= '1';
    			idp_in  <= idp_out;
    			state_next  <= STATE_SET_ADDR;
	    		int_idp_valid_next  <= idp_valid;
    			
	    	when STATE_SET_ADDR  => 
	    		if address_valid = '1' and int_idp_valid = '1' then
	    			dst_address  <= address_out;
	    		else
	    			dst_address  <= (others  => '1');
	    		end if;
	    		state_next  <= STATE_DUMMY;
	    	when STATE_DUMMY  => 
	    		address_in  <= dst_address;
	    	when STATE_SEND  => 
				config_done  <= '1';	    		
	    		
	    	when others => null;
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
			counter <= 0;
	    elsif rising_edge(clk) then
	     	state  <= state_next;
	     	int_idp_valid  <= int_idp_valid_next;
	     	cur_len  <= cur_len_next;
	     	packet_state  <= packet_state_next;
	     	testing_state  <= testing_state_next;
	     	rx_packet_count  <= rx_packet_count_next;
		counter <= counter_next;
	    end if;
	end process;
	
		
end architecture;
