library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;

entity atb_invMixCol is
end entity;

architecture rtl of atb_invMixCol is
  signal en:          std_logic;
  signal rst:         std_logic;
  signal bi:          DATA_ARRAY;
  signal bo:          DATA_ARRAY;
  signal clk:         std_logic;
  signal xx:          std_logic_vector(7 downto 0);
component invMixCol is
  port(
    rst:        in std_logic;
    en:         in std_logic;
    bi:         in  DATA_ARRAY;
    bo:         out DATA_ARRAY    
  );
end component;

begin
  
    imc:   invMixCol port map(
      rst=>rst,
      en=>en,
      bi=>bi,
      bo=>bo                      
    );
  
  xx<=mult(bi(0),X"0e");
   
  process begin
    en<='1';
    wait;
  end process;
  
  process begin
    clk<='1';
    wait for 5 ns;
    clk<='0';
    wait for 5 ns;
  end process;
  
  process begin
    rst<='1';
    wait for 100 ns;
    rst<='0';
    wait;
  end process;
  
  process(clk,rst)
    begin
      if rst='1'then
        bi<=ZEROMATRIX;
      elsif rising_edge(clk) then
        bi(0)<=X"bd";
        bi(1)<=X"6e";
        bi(2)<=X"7c";
        bi(3)<=X"3d";
        bi(4)<=X"f2";
        bi(5)<=X"b5";
        bi(6)<=X"77";
        bi(7)<=X"9e";
        bi(8)<=X"0b";
        bi(9)<=X"61";
        bi(10)<=X"21";
        bi(11)<=X"6e";
        bi(12)<=X"8b";
        bi(13)<=X"10";
        bi(14)<=X"b6";
        bi(15)<=X"89";
      end if;
    end process;
        
    
end rtl; 
