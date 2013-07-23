library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;


entity addKey is
  port(
    round_key_bytes:            in  DATA_ARRAY;
    round_txt_bytes:            in  DATA_ARRAY;        
    ciphered_bytes:             out DATA_ARRAY   
  );
end addKey;

architecture addKey of addKey is

begin
process(round_key_bytes,round_txt_bytes)
  begin
    for i in 0 to 15 loop
          ciphered_bytes(i)<=round_key_bytes(i)XOR round_txt_bytes(i);
    end loop;
end process;
  
end addKey;