
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
  	NR_OF_ENTRIES : integer := 16
  );
  port (
  	i_clk		: in std_logic;
  	i_rst		: in std_logic;
  	i_hash 		: in std_logic_vector(63 downto 0);
  	i_idp		: in std_logic_vector(31 downto 0);
  	i_set_hash 	: in std_logic;
  	i_get_idp	: in std_logic;
  	o_idp		: out std_logic_vector(31 downto 0)
    );
end mapping;

architecture Behavioral of mapping is
	
	type mapping_array_type is array (0 to 15) of std_logic_vector(95 downto 0);
	signal mapping_table : mapping_array_type;
	signal mapping_table_next : mapping_array_type;
	
	signal index : integer range 0 to NR_OF_ENTRIES -1;
	signal index_next : integer range 0 to NR_OF_ENTRIES -1;
	
	signal idp : std_logic_vector(31 downto 0);
	signal idp_next : std_logic_vector(31 downto 0);
	
	
	type testing_state_t is (STATE_INIT, STATE_IDLE);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;

	
	
begin
	o_idp  <= idp;
	
	
	mapping_proc : process(i_hash, i_idp, i_set_hash, i_get_idp, index, mapping_table, state)
	begin
		idp_next  <= idp;
		mapping_table_next  <= mapping_table;
		index_next  <= index;
		state_next  <= state;
	    case state is
	    	when STATE_INIT  => 
	    		index_next  <= 0;
	    		idp_next  <= (others  => '0');
	    		mapping_table_next  <= (others  => (others  => '0'));
	    		state_next  <= STATE_IDLE;
        	when STATE_IDLE =>
		   		if i_set_hash = '1' then
		   			mapping_table_next(index) <= i_hash & i_idp;
		   			index_next <= index + 1; --TODO: overflow protection.
		   		end if;
		   		if i_get_idp = '1' then
		   			for i in 0 to NR_OF_ENTRIES - 1 loop
		   				if i_hash = mapping_table(i)(95 downto 32) then
		   					idp_next  <= mapping_table(i)(31 downto 0);
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
			idp  <= (others  => '0');
			mapping_table  <= (others  => (others  => '0'));
			index  <= 0;
			state  <= STATE_INIT;
	    elsif rising_edge(i_clk) then
	     	idp  <= idp_next;
	     	mapping_table  <= mapping_table_next;
	     	index  <= index_next;
	     	state  <= state_next;
	    end if;
	end process;
	
	
	
end architecture;
