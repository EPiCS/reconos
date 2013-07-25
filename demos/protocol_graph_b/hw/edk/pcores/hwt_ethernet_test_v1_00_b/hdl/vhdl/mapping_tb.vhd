
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

entity mapping_tb is
 
end mapping_tb;

architecture Behavioral of mapping_tb is
	
	component mapping is
  	generic (
  		NR_OF_ENTRIES : integer := 16;
  		INDEX_LEN : integer := 64;
  		VALUE_LEN : integer := 32
  	);
  	port (
  		i_clk		: in std_logic;
  		i_rst		: in std_logic;
  		i_index 	: in std_logic_vector(INDEX_LEN - 1 downto 0);
  		i_value		: in std_logic_vector(VALUE_LEN - 1 downto 0);
  		i_set_value	: in std_logic;
  		i_get_value	: in std_logic;
  		o_value		: out std_logic_vector(VALUE_LEN - 1 downto 0);
  		o_valid 	: out std_logic
    	);
	end component;
	
	signal clk : std_logic;
	signal rst : std_logic;
	signal hash : std_logic_vector(63 downto 0);
	signal idp_in : std_logic_vector(31 downto 0);
	signal set_hash : std_logic;
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
		
	
begin
	hash_mapping_inst : mapping
	generic map (
			INDEX_LEN  => 64,
			VALUE_LEN  => 32
	)
    port map (
    		i_clk  => clk,
    		i_rst  => rst,
    		i_index  => hash,
    		i_value  => idp_in,
    		i_set_value  => set_hash,
    		i_get_value  => get_idp,
    		o_value  => idp_out,
    		o_valid  => idp_valid
    );
   
   address_mapping_inst : mapping
	generic map (
			INDEX_LEN  => 32,
			VALUE_LEN  => 6
	)
    port map (
    		i_clk  => clk,
    		i_rst  => rst,
    		i_index  => idp_in,
    		i_value  => address_in,
    		i_set_value  => set_address,
    		i_get_value  => get_address,
    		o_value  => address_out,
    		o_valid  => address_valid
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
