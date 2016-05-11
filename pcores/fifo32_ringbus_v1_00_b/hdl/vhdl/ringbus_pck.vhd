--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package ringbus_pck is

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--
    constant RB_DATA_WIDTH  : natural := 32;
    constant RB_ADDR_WIDTH  : natural := 5; -- was 8
    constant RB_CTRL_WIDTH : natural := 2;
    constant RB_CTRL_CMD_DATA: unsigned(RB_CTRL_WIDTH-1 downto 0) := "00";
    constant RB_CTRL_CMD_MGMT: unsigned(RB_CTRL_WIDTH-1 downto 0) := "01";
    constant RB_TRANS_SIZE_WIDTH : natural := 5;
    constant RB_BUS_WIDTH: integer:= RB_DATA_WIDTH + 2*RB_ADDR_WIDTH + RB_CTRL_WIDTH; 
    
    type ring_t is record
    	data: unsigned(RB_DATA_WIDTH-1 downto 0);
    	src:  unsigned(RB_ADDR_WIDTH-1 downto 0);
    	dst:  unsigned(RB_ADDR_WIDTH-1 downto 0);
    	ctrl: unsigned(RB_CTRL_WIDTH-1 downto 0);
    end record;
    
    type ring_vector_t is array (natural range<>) of ring_t;
    
    type ctrl_master_t is record
        free_words: unsigned(RB_TRANS_SIZE_WIDTH-1 downto 0);
        req : std_logic;
        dst : unsigned(RB_ADDR_WIDTH-1 downto 0);
    end record;
    
    type ctrl_slave_t is record
        max_trans: unsigned(RB_TRANS_SIZE_WIDTH-1 downto 0);
        direction: std_logic;
        incoming : std_logic;
    end record;
    
    type ctrl_master_vector_t is array (natural range<>) of ctrl_master_t;
    type ctrl_slave_vector_t  is array (natural range<>) of ctrl_slave_t;
    
    constant RING_IDLE : ring_t := ((others =>'1'),(others =>'1'),(others =>'1'),(others =>'1'));
    constant RING_ADDRESS_IDLE : unsigned(RB_ADDR_WIDTH-1 downto 0) := (others =>'1'); 

	constant CTRL_SLAVE_IDLE : ctrl_slave_t := ((others=>'0'), '0', '0'); 
	constant CTRL_MASTER_IDLE : ctrl_master_t := ((others=>'0'), '0',RING_ADDRESS_IDLE);

end ringbus_pck;

package body ringbus_pck is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end ringbus_pck;
