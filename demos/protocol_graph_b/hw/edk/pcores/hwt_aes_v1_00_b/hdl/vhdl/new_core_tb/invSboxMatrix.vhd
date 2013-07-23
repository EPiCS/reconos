library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--------------------------FUNCTION: LUT+SHIFT---------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

entity invSboxMatrix is  
  port(   
    clk:                        in std_logic;
    rst:                        in std_logic;
    byte_array_in:              in DATA_ARRAY;        
    byte_array_out:             out DATA_ARRAY   
  );
end invSboxMatrix;

architecture invSboxMatrix of invSboxMatrix is

---------------------------------------------------------------------------------------------  
 component invSbox is

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
  
    invSbox0:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(0),
      sByte  => byte_array_out(0)
    );
    
    invSbox4:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(4),
      sByte  => byte_array_out(4)
    );
    
    invSbox8:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(8),
      sByte  => byte_array_out(8)
    );
    
    invSbox12:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(12),
      sByte  => byte_array_out(12)
    );

------------------------------------------------------------------
    invSbox1:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(1),
      sByte  => byte_array_out(5)
    );
    
    invSbox5:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(5),
      sByte  => byte_array_out(9)
    );
    
    invSbox9:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(9),
      sByte  => byte_array_out(13)
    );
    
    invSbox13:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(13),
      sByte  => byte_array_out(1)
    );
-----------------------------------------------------------------------------------------------
    invSbox2:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(2),
      sByte  => byte_array_out(10)
    );
    
    invSbox6:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(6),
      sByte  => byte_array_out(14)
    );
    
    invSbox10:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(10),
      sByte  => byte_array_out(2)
    );
    
    invSbox14:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(14),
      sByte  => byte_array_out(6)
    );

------------------------------------------------------------------
    invSbox3:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(3),
      sByte  => byte_array_out(15)
    );
    
    invSbox7:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(7),
      sByte  => byte_array_out(3)
    );
    
    invSbox11:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(11),
      sByte  => byte_array_out(7)
    );
    
    invSbox15:  invSbox
    port map(
      clk     => clk,
      rst     => rst,
      addr    => byte_array_in(15),
      sByte  => byte_array_out(11)
    );

end invSboxMatrix;

