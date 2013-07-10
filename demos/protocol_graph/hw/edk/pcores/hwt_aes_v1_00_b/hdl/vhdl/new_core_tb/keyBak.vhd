library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;

entity keyBak is
  port(
    rst                     :in std_logic;
    clk                     :in std_logic;
    keyIn                   :in KEY256_ARRAY;
    keyInject               :in std_logic;
    
    addrA                   :in std_logic_vector(3 downto 0);
    addrB                   :in std_logic_vector(3 downto 0);
    addrC                   :in std_logic_vector(3 downto 0);
    addrD                   :in std_logic_vector(3 downto 0);
    keyA                    :out DATA_ARRAY;
    keyB                    :out DATA_ARRAY;
    keyC                    :out DATA_ARRAY;
    keyD                    :out DATA_ARRAY
  );
end keyBak;

architecture rtl of keyBak is
  signal key:         KEY256_ARRAY;
  
  begin
    
    process(rst,clk)
      begin
        if rst='1' then
            key<=(others=>X"0FFF0FFF");
        elsif rising_edge(clk)then
          if keyInject='1'then
            key<=keyIn;
          end if;
        end if;
    end process;
    
    process(rst,clk)
      variable round_key: CIPHER_KEY_ARRAY;
      begin
       if(rst='1')then
        for i in 0 to 15 loop
              keyA(i) <= X"AA";
        end loop;
       elsif rising_edge(clk)then
              round_key(0)  := key (to_integer(UNSIGNED(addrA))*4);
              round_key(1)  := key (to_integer(UNSIGNED(addrA))*4+1);
              round_key(2)  := key (to_integer(UNSIGNED(addrA))*4+2);
              round_key(3)  := key (to_integer(UNSIGNED(addrA))*4+3);
        for i in 0 to 3 loop
            for j in 0 to 3 loop
              keyA(i*4+j) <= round_key(i)((j+1)*8-1 downto j*8);
            end loop;
        end loop;
       end if;
    end process;
    
    process(rst,clk)
      variable round_key: CIPHER_KEY_ARRAY;
      begin
       if(rst='1')then
        for i in 0 to 15 loop
              keyB(i) <= X"BB";
        end loop;
       elsif rising_edge(clk)then
              round_key(0)  := key (to_integer(UNSIGNED(addrB))*4);
              round_key(1)  := key (to_integer(UNSIGNED(addrB))*4+1);
              round_key(2)  := key (to_integer(UNSIGNED(addrB))*4+2);
              round_key(3)  := key (to_integer(UNSIGNED(addrB))*4+3);
        for i in 0 to 3 loop
            for j in 0 to 3 loop
              keyB(i*4+j) <= round_key(i)((j+1)*8-1 downto j*8);
            end loop;
        end loop;
       end if;
    end process;

    process(rst,clk)
      variable round_key: CIPHER_KEY_ARRAY;
      begin
       if(rst='1')then
        for i in 0 to 15 loop
              keyC(i) <= X"CC";
        end loop;
       elsif rising_edge(clk)then
              round_key(0)  := key (to_integer(UNSIGNED(addrC))*4);
              round_key(1)  := key (to_integer(UNSIGNED(addrC))*4+1);
              round_key(2)  := key (to_integer(UNSIGNED(addrC))*4+2);
              round_key(3)  := key (to_integer(UNSIGNED(addrC))*4+3);
        for i in 0 to 3 loop
            for j in 0 to 3 loop
              keyC(i*4+j) <= round_key(i)((j+1)*8-1 downto j*8);
            end loop;
        end loop;
       end if;
    end process;
    
    process(rst,clk)
      variable round_key: CIPHER_KEY_ARRAY;
      begin
       if(rst='1')then
        for i in 0 to 15 loop
              keyD(i) <= X"DD";
        end loop;
       elsif rising_edge(clk)then
              round_key(0)  := key (to_integer(UNSIGNED(addrD))*4);
              round_key(1)  := key (to_integer(UNSIGNED(addrD))*4+1);
              round_key(2)  := key (to_integer(UNSIGNED(addrD))*4+2);
              round_key(3)  := key (to_integer(UNSIGNED(addrD))*4+3);
        for i in 0 to 3 loop
            for j in 0 to 3 loop
              keyD(i*4+j) <= round_key(i)((j+1)*8-1 downto j*8);
            end loop;
        end loop;
       end if;
    end process;
    
  end rtl;
