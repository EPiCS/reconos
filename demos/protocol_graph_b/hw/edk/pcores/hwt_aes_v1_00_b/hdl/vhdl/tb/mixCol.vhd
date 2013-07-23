library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity mixCol is
  port(
    rst:        in std_logic;
    en:         in std_logic;
    bi:         in  DATA_ARRAY;
    bo:         out DATA_ARRAY    
  );
end mixCol;

architecture mixCol of mixCol is
     
begin
  --process(clk,rst)
    process(rst,bi,en)
    begin
      if(rst='1') then
        for i in 0 to 15 loop
          bo(i) <= X"00";
        end loop;
      --elsif rising_edge(clk) then
      else
        if(en='1')then
          for i in 0 to 12 loop
            if(i=0)OR(i=4)OR(i=8)or(i=12)then
              bo(i)   <= mult2(bi(i)) XOR mult3(bi(i+1)) XOR bi(i+2) XOR bi(i+3);
              bo(i+1) <= bi(i) XOR mult2(bi(i+1)) XOR mult3(bi(i+2)) XOR bi(i+3);
              bo(i+2) <= bi(i) XOR bi(i+1) XOR mult2(bi(i+2)) XOR mult3(bi(i+3));
              bo(i+3) <= mult3(bi(i)) XOR bi(i+1) XOR bi(i+2) XOR mult2(bi(i+3)); 
            end if;
          end loop;
        else
          for i in 0 to 15 loop
            bo(i) <= X"00";
          end loop; 
        end if;
      end if;
  end process;     
        
    
end mixCol;   



