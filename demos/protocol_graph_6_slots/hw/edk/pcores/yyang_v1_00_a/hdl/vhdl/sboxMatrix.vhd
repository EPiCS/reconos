library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library yyang_v1_00_a;
use yyang_v1_00_a.yyangPkg.all;
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--------------------------FUNCTION: LUT+SHIFT---------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

entity sboxMatrix is  
  port(   
    clk:                        in std_logic;
    rst:                        in std_logic;
    byte_array_in:              in DATA_ARRAY;        
    byte_array_out:             out DATA_ARRAY   
  );
end sboxMatrix;

architecture sboxMatrix of sboxMatrix is

---------------------------------------------------------------------------------------------  
 component sbox is

	port(
	  
		clk		     : in	STD_LOGIC;		
		rst       : in std_logic;
		addr      : in	STD_LOGIC_VECTOR (7 downto 0);	  -- Byte
		sByte    : out STD_LOGIC_VECTOR (7 downto 0)	 -- Substituted Byte
		
		);
		
end component;
---------------------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------    
begin
  
    sbox0:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(0),
      sByte  => byte_array_out(0)
    );
    
    sbox4:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(4),
      sByte  => byte_array_out(4)
    );
    
    sbox8:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(8),
      sByte  => byte_array_out(8)
    );
    
    sbox12:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(12),
      sByte  => byte_array_out(12)
    );

------------------------------------------------------------------
    sbox1:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(5),
      sByte  => byte_array_out(1)
    );
    
    sbox5:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(9),
      sByte  => byte_array_out(5)
    );
    
    sbox9:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(13),
      sByte  => byte_array_out(9)
    );
    
    sbox13:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(1),
      sByte  => byte_array_out(13)
    );
-----------------------------------------------------------------------------------------------
    sbox2:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(10),
      sByte  => byte_array_out(2)
    );
    
    sbox6:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(14),
      sByte  => byte_array_out(6)
    );
    
    sbox10:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(2),
      sByte  => byte_array_out(10)
    );
    
    sbox14:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(6),
      sByte  => byte_array_out(14)
    );

------------------------------------------------------------------
    sbox3:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(15),
      sByte  => byte_array_out(3)
    );
    
    sbox7:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(3),
      sByte  => byte_array_out(7)
    );
    
    sbox11:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(7),
      sByte  => byte_array_out(11)
    );
    
    sbox15:  sbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(11),
      sByte  => byte_array_out(15)
    );

end sboxMatrix;



