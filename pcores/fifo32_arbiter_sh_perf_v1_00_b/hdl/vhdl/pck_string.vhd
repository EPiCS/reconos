

-- @module : pck_string
-- @author : meise
-- @date   : Sep 12, 2016


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pck_string is
    
    function chr(sl: std_logic) return character;
    
    function to_string (number: integer) return string;
    function to_string (number: unsigned) return string;
    function to_string (number: std_logic_vector) return string;
    
    function to_hstring(number: unsigned) return string;
    function to_hstring(slv: std_logic_vector) return string;

end package pck_string;  
 


package body pck_string is

     -- Stupid ISE 14.7 does not have a to_string function...
     function to_string (number: integer) return string
     is begin
         return integer'image(number);
     end function;
     
     
   -- converts std_logic into a character
   function chr(sl: std_logic) return character is
    variable c: character;
    begin
      case sl is
         when 'U' => c:= 'U';
         when 'X' => c:= 'X';
         when '0' => c:= '0';
         when '1' => c:= '1';
         when 'Z' => c:= 'Z';
         when 'W' => c:= 'W';
         when 'L' => c:= 'L';
         when 'H' => c:= 'H';
         when '-' => c:= '-';
      end case;
    return c;
   end chr;
    
    
     function to_string (number: unsigned) return string
     is
         variable s : string( number'range );
     begin
         for i in number'range loop
                s(i) := chr(number(i));
          end loop;
          return s;
     end function;

   -- converts a std_logic_vector into a hex string.
   function to_hstring(number: unsigned) return string is
       variable hexlen: integer;
       variable longslv : unsigned(67 downto 0) := (others => '0');
       variable hex : string(1 to 16);
       variable fourbit : unsigned(3 downto 0);
     begin
       hexlen := (number'left+1)/4;
       if (number'left+1) mod 4 /= 0 then
         hexlen := hexlen + 1;
       end if;
       longslv(number'left downto 0) := number;
       for i in (hexlen -1) downto 0 loop
         fourbit := longslv(((i*4)+3) downto (i*4));
         case fourbit is
           when "0000" => hex(hexlen -I) := '0';
           when "0001" => hex(hexlen -I) := '1';
           when "0010" => hex(hexlen -I) := '2';
           when "0011" => hex(hexlen -I) := '3';
           when "0100" => hex(hexlen -I) := '4';
           when "0101" => hex(hexlen -I) := '5';
           when "0110" => hex(hexlen -I) := '6';
           when "0111" => hex(hexlen -I) := '7';
           when "1000" => hex(hexlen -I) := '8';
           when "1001" => hex(hexlen -I) := '9';
           when "1010" => hex(hexlen -I) := 'A';
           when "1011" => hex(hexlen -I) := 'B';
           when "1100" => hex(hexlen -I) := 'C';
           when "1101" => hex(hexlen -I) := 'D';
           when "1110" => hex(hexlen -I) := 'E';
           when "1111" => hex(hexlen -I) := 'F';
           when "ZZZZ" => hex(hexlen -I) := 'z';
           when "UUUU" => hex(hexlen -I) := 'u';
           when "XXXX" => hex(hexlen -I) := 'x';
           when others => hex(hexlen -I) := '?';
         end case;
       end loop;
       return hex(1 to hexlen);
     end function;

     function to_string (number: std_logic_vector) return string
     is
         variable s : string( number'range );
     begin
         for i in number'range loop
                s(i) := chr(number(i));
          end loop;
          return s;
     end function;
     
   -- converts a std_logic_vector into a hex string.
   function to_hstring(slv: std_logic_vector) return string is
       variable hexlen: integer;
       variable longslv : std_logic_vector(67 downto 0) := (others => '0');
       variable hex : string(1 to 16);
       variable fourbit : std_logic_vector(3 downto 0);
     begin
       hexlen := (slv'left+1)/4;
       if (slv'left+1) mod 4 /= 0 then
         hexlen := hexlen + 1;
       end if;
       longslv(slv'left downto 0) := slv;
       for i in (hexlen -1) downto 0 loop
         fourbit := longslv(((i*4)+3) downto (i*4));
         case fourbit is
           when "0000" => hex(hexlen -I) := '0';
           when "0001" => hex(hexlen -I) := '1';
           when "0010" => hex(hexlen -I) := '2';
           when "0011" => hex(hexlen -I) := '3';
           when "0100" => hex(hexlen -I) := '4';
           when "0101" => hex(hexlen -I) := '5';
           when "0110" => hex(hexlen -I) := '6';
           when "0111" => hex(hexlen -I) := '7';
           when "1000" => hex(hexlen -I) := '8';
           when "1001" => hex(hexlen -I) := '9';
           when "1010" => hex(hexlen -I) := 'A';
           when "1011" => hex(hexlen -I) := 'B';
           when "1100" => hex(hexlen -I) := 'C';
           when "1101" => hex(hexlen -I) := 'D';
           when "1110" => hex(hexlen -I) := 'E';
           when "1111" => hex(hexlen -I) := 'F';
           when "ZZZZ" => hex(hexlen -I) := 'z';
           when "UUUU" => hex(hexlen -I) := 'u';
           when "XXXX" => hex(hexlen -I) := 'x';
           when others => hex(hexlen -I) := '?';
         end case;
       end loop;
       return hex(1 to hexlen);
     end function;
             
        
end package body;




