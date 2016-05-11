----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:45:10 02/25/2015 
-- Design Name: 
-- Module Name:    ringbus_control - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ringbus_pck.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ringbus_control is
	generic(
		G_TAP_CNT : integer := 8
	);
	port(
        -- Control Interface
        ctrl_in  : in ctrl_master_vector_t(0 to G_TAP_CNT-1);
        ctrl_out : out  ctrl_slave_vector_t(0 to G_TAP_CNT-1);
        
		clk: in std_logic;
		rst: in std_logic;
		
		-- Debug signals to ILA
    	ila_signals : out std_logic_vector(130 downto 0)
	);
end ringbus_control;

architecture Behavioral of ringbus_control is
  
 --type state_t is (update_conf, select_tap, check_request, try_allocate_path, try_allocate_alternative_path, teardown_path);
 type tapstate_t is (IDLE, SENDING, RECEIVING);
 type tapstate_vector_t is array (natural range <>) of tapstate_t;
 type tapconns_vector_t is array (natural range <>) of integer range 0 to 31; -- @TODO: make integer size adapt to G_TAP_CNT
 type routing_line_t is array (0 to G_TAP_CNT-1) of std_logic;
 type routing_table_t is array (0 to G_TAP_CNT-1) of routing_line_t; 
 
 --signal state: state_t; 
 signal current_idx: integer range 0 to G_TAP_CNT-1;
 signal tapstates: tapstate_vector_t (0 to G_TAP_CNT-1);
 signal tapconns : tapconns_vector_t (0 to G_TAP_CNT-1);
  
 
 -- Calculates the distances between a source and a destination when going
 -- clockwise or counter-clockwise around the ringbus and returns if going 
 -- clockwise is shortest.
 function c_and_not_cc (src, dst, ring_size: integer)  return std_logic is 
	variable cc_dist, c_dist:integer;
	
 begin
	c_dist := dst-src;
	if c_dist >= 0 then 
		cc_dist  := c_dist - ring_size;
	else
		cc_dist  := c_dist + ring_size;
	end if;
	
	if abs(c_dist) < abs(cc_dist) then
		if cc_dist < 0 then
			return '1'; --true;
		else
			return '0'; --false;
		end if;
	else
		if cc_dist < 0 then
			return '0'; --false;
		else
			return '1'; --true;
		end if;
	end if;
 end function;
 
 
 -- Function for automatically filling the routing rom depedant on 
 -- the generic parameters.
 function fill_routing_rom(tap_cnt :integer) return routing_table_t is
     variable routing_table : routing_table_t;
 begin
      for src in 0 to tap_cnt-1 loop
      	for dst in 0 to tap_cnt-1 loop
      	  routing_table(src)(dst) := c_and_not_cc (src, dst, tap_cnt);
      	end loop;
  	  end loop;
  
      return routing_table;
 end function;
 
 
 constant routing_rom: routing_table_t := fill_routing_rom(G_TAP_CNT);
 
begin

	ila_proc: process(tapstates, tapconns) is
    begin
        case(tapstates(0)) is
            when IDLE       => ila_signals(3 downto 0) <= X"0";
            when SENDING    => ila_signals(3 downto 0) <= X"1";
            when RECEIVING  => ila_signals(3 downto 0) <= X"2";
            when others     => ila_signals(3 downto 0) <= X"3";
        end case;
        case(tapstates(1)) is
            when IDLE       => ila_signals(7 downto 4) <= X"0";
            when SENDING    => ila_signals(7 downto 4) <= X"1";
            when RECEIVING  => ila_signals(7 downto 4) <= X"2";
            when others     => ila_signals(7 downto 4) <= X"3";
        end case;
        ila_signals(11 downto  8) <= std_logic_vector(to_unsigned(tapconns(0), 4));
        ila_signals(15 downto 12) <= std_logic_vector(to_unsigned(tapconns(1), 4));
        ila_signals(130 downto 16)<= (others => '0');
    end process;

	ctrl_proc : process (clk,rst,ctrl_in, current_idx) is 
	begin
		if rst='1' then
		    for i in 0 to G_TAP_CNT-1 loop
		    	ctrl_out(i).direction <= '0';
		    	ctrl_out(i).incoming  <= '0';
		    	ctrl_out(i).max_trans <= (others=>'0');
		    end loop;
		    
		    tapstates <= (others => IDLE);
		    tapconns  <= (others => G_TAP_CNT);
		    current_idx <= 0;
		elsif clk'event and clk='1' then
		    case tapstates(current_idx) is
		    when IDLE =>
    		    -- New connection - set it up
    		    if ctrl_in(current_idx).req = '1' and 
    		       tapstates(to_integer(ctrl_in(current_idx).dst) ) = IDLE
    		    then
    		    	    -- Sender 
    		    	    tapstates(current_idx) <= SENDING;
    		    	    tapconns(current_idx) <= to_integer(ctrl_in(current_idx).dst);
    		    	    ctrl_out(current_idx).direction <= routing_rom(current_idx)(to_integer(ctrl_in(current_idx).dst));
    		    	    
    		    	    -- Receiver
    		    		tapstates(to_integer(ctrl_in(current_idx).dst)) <= RECEIVING;
    		    		tapconns(to_integer(ctrl_in(current_idx).dst)) <= current_idx;
    		    		ctrl_out(to_integer(ctrl_in(current_idx).dst)).incoming <= '1';
    		    		ctrl_out(to_integer(ctrl_in(current_idx).dst)).direction <= not routing_rom(current_idx)(to_integer(ctrl_in(current_idx).dst));
    		    end if;
    		when SENDING =>
		    	-- Old connection - tear down sender
		    	if ctrl_in(current_idx).req = '0' and
		    	   ctrl_in(to_integer(ctrl_in(current_idx).dst)).req = '0'
		    	   then
    		    		-- Sender
    		    		tapstates(current_idx) <= IDLE;
    		    		tapconns(current_idx) <= G_TAP_CNT;
    		    		ctrl_out(current_idx).direction <= '0';

						--Receiver
    		    		tapstates(to_integer(ctrl_in(current_idx).dst)) <= IDLE;
						tapconns(to_integer(ctrl_in(current_idx).dst)) <= G_TAP_CNT;
    		    		ctrl_out(to_integer(ctrl_in(current_idx).dst)).direction <= '0';
    		    		ctrl_out(to_integer(ctrl_in(current_idx).dst)).incoming <= '0';    		    		
    		    end if;
			when others =>
			
			end case;
			if current_idx = G_TAP_CNT-1 then
			    current_idx <= 0;
			else
				current_idx <= current_idx +1 ;
			end if;
		
			for i in 0 to G_TAP_CNT-1 loop
				if tapconns(i) = G_TAP_CNT then 
					ctrl_out(i).max_trans <= to_unsigned(0, RB_TRANS_SIZE_WIDTH);
				else
			    	ctrl_out(i).max_trans <= ctrl_in(tapconns(i)).free_words;
			    end if;
				
			end loop;
        end if;
	end process ctrl_proc;
		

-- 	free_words: for i in 0 to G_TAP_CNT-1 generate
-- 		free_words_proc: process(ctrl_in) is
-- 		begin
-- 			ctrl_out(i).max_trans <= --to_unsigned(0, RB_TRANS_SIZE_WIDTH) when tapconns(i) = G_TAP_CNT else
-- 								 ctrl_in(tapconns(i)).free_words;
-- 		end process;
		
-- 	end generate;
end Behavioral;

