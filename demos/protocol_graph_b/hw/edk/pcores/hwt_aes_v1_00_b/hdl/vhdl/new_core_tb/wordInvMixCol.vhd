library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;

entity wordInvMixCol is
  port(
    rst:        in std_logic;
    en:         in std_logic;
    inj:        in std_logic;
    wi:         in  KEY256_ARRAY;
    wo:         out KEY256_ARRAY    
  );
end wordInvMixCol;

architecture wordInvMixCol of wordInvMixCol is     
begin
  
process(rst,en,wi,inj)
  variable tmp0: std_logic_vector(7 downto 0);
  variable tmp1: std_logic_vector(7 downto 0);
  variable tmp2: std_logic_vector(7 downto 0);
  variable tmp3: std_logic_vector(7 downto 0);
begin
  if rst='1'then
    wo<=(others=>X"00000000");
  elsif en='1'then
    for i in 0 to 59 loop
        tmp0:= mult(wi(i)(7 downto 0),X"0e") XOR mult(wi(i)(15 downto 8),X"0b") XOR mult(wi(i)(23 downto 16),X"0d") XOR mult(wi(i)(31 downto 24),X"09");
        tmp1:= mult(wi(i)(7 downto 0),X"09") XOR mult(wi(i)(15 downto 8),X"0e") XOR mult(wi(i)(23 downto 16),X"0b") XOR mult(wi(i)(31 downto 24),X"0d");        
        tmp2:= mult(wi(i)(7 downto 0),X"0d") XOR mult(wi(i)(15 downto 8),X"09") XOR mult(wi(i)(23 downto 16),X"0e") XOR mult(wi(i)(31 downto 24),X"0b");
        tmp3:= mult(wi(i)(7 downto 0),X"0b") XOR mult(wi(i)(15 downto 8),X"0d") XOR mult(wi(i)(23 downto 16),X"09") XOR mult(wi(i)(31 downto 24),X"0e");
        wo(i)<=tmp3 & tmp2 & tmp1 & tmp0;
    end loop;
  end if;
end process;
    
end wordInvMixCol;  
