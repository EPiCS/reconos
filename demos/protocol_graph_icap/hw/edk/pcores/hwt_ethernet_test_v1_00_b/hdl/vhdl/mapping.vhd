
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

entity mapping is
  generic (
  	NR_OF_ENTRIES : integer := 16;
  	INDEX_LEN : integer := 64;
  	VALUE_LEN : integer := 32
  );
  port (
  	i_clk		: in std_logic;
  	i_rst		: in std_logic;
  	i_index_get	: in std_logic_vector(INDEX_LEN - 1 downto 0);
  	i_index_set	: in std_logic_vector(INDEX_LEN - 1 downto 0);
  	i_value		: in std_logic_vector(VALUE_LEN - 1 downto 0);
  	i_set_value	: in std_logic;
  	i_get_value	: in std_logic;
  	o_value		: out std_logic_vector(VALUE_LEN - 1 downto 0);
  	o_valid 	: out std_logic
    );
end mapping;

architecture Behavioral of mapping is
	
	type mapping_array_type is array (0 to NR_OF_ENTRIES - 1) of std_logic_vector(INDEX_LEN + VALUE_LEN - 1 downto 0);
	signal mapping_table : mapping_array_type;
	signal mapping_table_next : mapping_array_type;
	
	signal int_index : integer range 0 to NR_OF_ENTRIES -1;
	signal int_index_next : integer range 0 to NR_OF_ENTRIES -1;
	
	signal int_value : std_logic_vector(VALUE_LEN - 1 downto 0);
	signal int_value_next : std_logic_vector(VALUE_LEN - 1 downto 0);
	signal int_valid : std_logic;
	signal int_valid_next : std_logic;
	
	type testing_state_t is (STATE_INIT, STATE_IDLE);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;

	
	
begin
	o_value  <= int_value;
	o_valid  <=  int_valid;
	
	
	mapping_proc : process(i_index_get, i_index_set, i_value, i_set_value, i_get_value, int_index, mapping_table, state, int_value, int_valid)
	variable found : std_logic;
	begin
		int_value_next  <= int_value;
		mapping_table_next  <= mapping_table;
		int_index_next  <= int_index;
		state_next  <= state;
		int_valid_next  <= '0';
	    case state is
	    	when STATE_INIT  => 
	    		int_index_next  <= 0;
	    		int_value_next  <= (others  => '0');
	    		mapping_table_next  <= (others  => (others  => '0'));
	    		state_next  <= STATE_IDLE;
        	when STATE_IDLE =>
        		found := '0';
		   		if i_set_value = '1' then
		   			for i in 0 to NR_OF_ENTRIES - 1 loop
		   				if i_index_set = mapping_table(i)(INDEX_LEN + VALUE_LEN -1 downto VALUE_LEN) then
		   					mapping_table_next(i) <= i_index_set & i_value;
		   					found := '1';
		   				end if;
		   			end loop;
		   			if found = '0' then
		   					mapping_table_next(int_index) <= i_index_set & i_value;
		   					int_index_next <= int_index + 1; --TODO: overflow protection.
		   				end if;
		   		end if;
		   		if i_get_value = '1' then
		   			for i in 0 to NR_OF_ENTRIES - 1 loop
		   				if i_index_get = mapping_table(i)(INDEX_LEN + VALUE_LEN -1 downto VALUE_LEN) then
		   					int_value_next  <= mapping_table(i)(VALUE_LEN - 1 downto 0);
		   					int_valid_next  <= '1';
		   				end if;
		   			end loop;
		   		end if;
		
	--	when others =>
	    end case;
	end process;

		--creates flipflops
	memzing: process(i_clk, i_rst)
	begin
	    if i_rst = '1' then
			int_value  <= (others  => '0');
			int_valid  <= '0';
			mapping_table  <= (others  => (others  => '0'));
			int_index  <= 0;
			state  <= STATE_INIT;
	    elsif rising_edge(i_clk) then
	     	int_value  <= int_value_next;
	     	int_valid  <= int_valid_next;
	     	mapping_table  <= mapping_table_next;
	     	int_index  <= int_index_next;
	     	state  <= state_next;
	    end if;
	end process;
	
	
	
end architecture;
