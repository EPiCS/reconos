
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

entity remove_header is
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
end remove_header;

architecture Behavioral of remove_header is
	
	component mapping is
  	generic (
  		NR_OF_ENTRIES : integer := 16;
  		INDEX_LEN : integer := 64;
  		VALUE_LEN : integer := 32
  	);
  	port (
  		i_clk		: in std_logic;
  		i_rst		: in std_logic;
  		i_index_set	: in std_logic_vector(INDEX_LEN - 1 downto 0);
  		i_index_get : in std_logic_vector(INDEX_LEN - 1 downto 0);
  		i_value		: in std_logic_vector(VALUE_LEN - 1 downto 0);
  		i_set_value	: in std_logic;
  		i_get_value	: in std_logic;
  		o_value		: out std_logic_vector(VALUE_LEN - 1 downto 0);
  		o_valid 	: out std_logic
    	);
	end component;
	
	type testing_state_t is (STATE_INIT, STATE_IDLE, STATE_IGNORE, STATE_READ_HASH, STATE_LOOKUP, STATE_LOOKUP_2, STATE_FORWARD, STATE_FORWARD_SOF);
	signal state 	    : testing_state_t;
	signal state_next   : testing_state_t;

	signal counter : integer range 0 to 15;
	signal counter_next : integer range 0 to 15;
	signal hash : std_logic_vector(63 downto 0);
	signal hash_next : std_logic_vector(63 downto 0);
	
	signal get_idp : std_logic;
	signal get_address : std_logic;
	
	signal idp_valid : std_logic;
	signal address_valid : std_logic;
	signal int_valid_idp : std_logic;
	signal int_valid_idp_next : std_logic;
	signal address_out : std_logic_vector(5 downto 0);
	
	signal int_hash : std_logic_vector(63 downto 0);
	signal int_idp : std_logic_vector(31 downto 0);
	signal idp_out : std_logic_vector(31 downto 0);
	
begin

	rem_proc : process(state, i_rx_ll_data, i_rx_ll_src_rdy_n, i_rx_ll_sof_n, counter, hash, 
		idp_valid, int_valid_idp, address_valid, address_out, i_tx_dst_rdy, i_rx_ll_eof_n
	)
	begin
		state_next  <= state;
		o_rx_ll_dst_rdy_n  <= '0';
		o_tx_src_rdy  <= '0';
		o_tx_data  <= i_rx_ll_data;
		int_idp  <= idp_out;
		
     	counter_next  <= counter;
		hash_next  <= hash;
		int_valid_idp_next  <= int_valid_idp;
		
		get_idp  <= '0';
		get_address  <= '0';
		int_hash  <= hash;
	    case state is
	    	when STATE_INIT  => 
	    		state_next  <= STATE_IDLE;
	    	when STATE_IDLE  => 
	    		if i_rx_ll_src_rdy_n = '0' and i_rx_ll_sof_n = '0' then
	    			state_next  <= STATE_IGNORE;
	    			counter_next  <= 1;
	    		end if;
	    	when STATE_IGNORE  => 
	    		if i_rx_ll_src_rdy_n = '0' then
	    			counter_next  <= counter + 1;
	    			if counter + 1 = 14 then
	    				state_next  <= STATE_READ_HASH;
	    				counter_next  <= 0;
	    			end if;
	    		end if;
	    	when STATE_READ_HASH  => 
	    		if i_rx_ll_src_rdy_n = '0' then
	    			hash_next(63 - counter * 8 downto 63 - 1 - (counter + 1)*8)  <= i_rx_ll_data;
	    			counter_next  <= counter + 1;
	    			if counter + 1 = 8 then
	    				state_next  <= STATE_LOOKUP;
	    				counter_next  <= 0;
	    				int_hash  <= hash(63 downto 8) & i_rx_ll_data;
	    				o_rx_ll_dst_rdy_n  <= '1';
	    				get_idp  <= '1';
	    			end if;
	    		end if;
	    	when STATE_LOOKUP  => 
	    		o_rx_ll_dst_rdy_n  <= '1';
	    		int_valid_idp_next  <= idp_valid;
	    		state_next  <= STATE_LOOKUP_2;
	    		get_address  <= '1';
	    	when STATE_LOOKUP_2  => 
	    		if int_valid_idp = '1' and address_valid = '1' then
	    			o_global_addr  <= address_out(5 downto 2);
	    			o_local_addr  <= address_out(1 downto 0);
	    		end if;
	    		state_next  <= STATE_FORWARD_SOF;
	    	when STATE_FORWARD_SOF  => 
	    		o_tx_sof  <= '1';
	    		o_tx_src_rdy  <= '1';
	    		if i_tx_dst_rdy = '1' then
	    			state_next  <= STATE_FORWARD;
	    		end if;
			when STATE_FORWARD  => 
					o_rx_ll_dst_rdy_n  <= not i_tx_dst_rdy;
					o_tx_eof  <= not i_rx_ll_eof_n;
					if i_rx_ll_eof_n = '0' then
						state_next  <= STATE_IDLE;
					end if;    		 
	    		
	    	when others => 
	    		state_next  <= STATE_INIT;
	    	end case;

	end process;
	
	hash_mapping_inst : mapping
	generic map (
			INDEX_LEN  => 64,
			VALUE_LEN  => 32
	)
    port map (
    		i_clk  => i_clk,
    		i_rst  => i_rst,
    		i_index_set  => i_hash,
    		i_index_get  => int_hash,
    		i_value  => i_idp,
    		i_set_value  => i_set_idp,
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
    		i_clk  => i_clk,
    		i_rst  => i_rst,
    		i_index_set  => i_idp,
    		i_index_get  => int_idp,
    		i_value  => i_address,
    		i_set_value  => i_set_address,
    		i_get_value  => get_address,
    		o_value  => address_out,
    		o_valid  => address_valid
    );
	
	memzing: process(i_clk, i_rst)
	begin
	    if i_rst = '1' then
			state  <= STATE_INIT;
			counter  <= 0;
			hash  <= (others  => '0');
			int_valid_idp  <= '0';
	    elsif rising_edge(i_clk) then
	     	state  <= state_next;
	     	counter  <= counter_next;
			hash  <= hash_next;
			int_valid_idp  <= int_valid_idp_next;
	    end if;
	end process;
	
end architecture;
