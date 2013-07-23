library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity invMixCol is
  port(
    rst:        in std_logic;
    en:         in std_logic;
    bi:         in  DATA_ARRAY;
    bo:         out DATA_ARRAY    
  );
end invMixCol;

architecture invMixCol of invMixCol is
     
begin
    process(rst,bi,en)
    begin
      if(rst='1') then
        for i in 0 to 15 loop
          bo(i) <= X"00";
        end loop;
      else
        if(en='1')then
          for i in 0 to 12 loop
            if(i=0)OR(i=4)OR(i=8)or(i=12)then
              bo(i)   <= mult(bi(i),X"0e") XOR mult(bi(i+1),X"0b") XOR mult(bi(i+2),X"0d") XOR mult(bi(i+3),X"09");
              bo(i+1) <= mult(bi(i),X"09") XOR mult(bi(i+1),X"0e") XOR mult(bi(i+2),X"0b") XOR mult(bi(i+3),X"0d");
              bo(i+2) <= mult(bi(i),X"0d") XOR mult(bi(i+1),X"09") XOR mult(bi(i+2),X"0e") XOR mult(bi(i+3),X"0b");
              bo(i+3) <= mult(bi(i),X"0b") XOR mult(bi(i+1),X"0d") XOR mult(bi(i+2),X"09") XOR mult(bi(i+3),X"0e"); 
            end if;
          end loop;
        else
          for i in 0 to 15 loop
            bo(i) <= X"00";
          end loop; 
        end if;
      end if;
  end process;     
        
    
end invMixCol;   
