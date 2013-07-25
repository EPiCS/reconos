
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
  		o_priority : out std_logic;
  		o_latency_critical : out std_logic_vector(1 downto 0);	
  		o_src_idp : out  std_logic_vector(31 downto 0);
  		o_dst_idp : out  std_logic_vector(31 downto 0);
  		
  		-- comm to setup hash and address mapping table
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
	
	type testing_state_t is (STATE_INIT, STATE_SET_1, STATE_SET_2, STATE_SET_3, STATE_GET, STATE_GET_2, STATE_SET_ADDR, STATE_DUMMY);
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
	
begin
	
	remove_header_inst : remove_header
	port map (
		i_clk		 => clk,
  		i_rst		 => rst,
  	    -- comm with PHY
  	    i_rx_ll_data    => rx_ll_data,    
        i_rx_ll_sof_n    => rx_ll_sof_n,   
        i_rx_ll_eof_n    => rx_ll_eof_n,   
        i_rx_ll_src_rdy_n => rx_ll_src_rdy_n,  
        o_rx_ll_dst_rdy_n  => rx_ll_dst_rdy_n, 
         	
  		-- comm with next blocks (with internal switch)
  		o_tx_sof => tx_sof,
  		o_tx_eof => tx_eof,
  		o_tx_data => tx_data,
  		o_tx_src_rdy => tx_src_rdy,
  		i_tx_dst_rdy => tx_dst_rdy,
  
  		o_global_addr => global_addr,
  		o_local_addr => local_addr,
  		o_direction => direction,
  		o_priority => priority,
  		o_latency_critical 	=> latency_critical,
  		o_src_idp => src_idp,
  		o_dst_idp => dst_idp,
  		
  		-- comm to setup hash and address mapping table
  		i_set_idp => set_idp,
  		i_set_address => set_address,
  		i_hash	=> hash,
  		i_idp 	=> idp_in,
  		i_address => address_in,
	);
   
  
   
   	test_proc : process(state, idp_out, int_idp_valid, address_out)
	begin
		hash  <= (others  => '0');
		idp_in  <= (others  => '0');
		set_hash  <= '0';
		get_idp  <= '0'; 
		set_address  <= '0';
		get_address  <= '0';
		address_in  <= (others  => '0');
		idp_in  <= (others  => '0');
		state_next  <= state;
		dst_address  <= (others  => '0');
		int_idp_valid_next  <= int_idp_valid;
    case state is
	    	when STATE_INIT  => 
	    		state_next  <= STATE_SET_1;
	    	when STATE_SET_1  => 
	    		hash  <= x"AABBCCDD11223344";
	    		idp_in  <= x"12344321";
	    		set_hash  <= '1';
	    		state_next  <= STATE_SET_2;
	    	when STATE_SET_2  => 
	    	 	hash  <= x"EEFFFFEE55667788";
	    		idp_in  <= x"56788765";
	    		set_hash  <= '1';
	    		state_next  <= STATE_SET_3;
	    	when STATE_SET_3  => 
	    		set_address  <= '1';
	    		address_in  <= "001100";
	    		idp_in  <= x"56788765";
	    		state_next  <= STATE_GET;
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
	    elsif rising_edge(clk) then
	     	state  <= state_next;
	     	int_idp_valid  <= int_idp_valid_next;
	    end if;
	end process;
	
		
end architecture;
