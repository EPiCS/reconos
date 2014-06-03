library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package yyangPkg is
  
  TYPE DATA_ARRAY         is array(0 to 15) of std_logic_vector (7 downto 0);
  TYPE KEY256_ARRAY       is array(0 to 59) of std_logic_vector (31 downto 0);
  TYPE CIPHERKEY256_ARRAY is array(0 to 7)  of std_logic_vector (31 downto 0);
  TYPE KEY_ARRAY          is array(0 to 43) of std_logic_vector (31 downto 0);
  TYPE CIPHER_KEY_ARRAY   is array(0 to 3)  of std_logic_vector (31 downto 0);
  TYPE SBOX_ARRAY         is array(0 to 255)of std_logic_vector (7 downto 0);  
  
--  CONSTANT DATA_WAITING:      STD_LOGIC_VECTOR(1 DOWNTO 0):="00";
--  CONSTANT DATA_PROCESSING:   STD_LOGIC_VECTOR(1 DOWNTO 0):="01";
--  CONSTANT DATA_FULL:         STD_LOGIC_VECTOR(1 DOWNTO 0):="11";
  
  CONSTANT mode128:      STD_LOGIC_VECTOR(1 DOWNTO 0):="00";
  CONSTANT mode192:      STD_LOGIC_VECTOR(1 DOWNTO 0):="01";
  CONSTANT mode256:      STD_LOGIC_VECTOR(1 DOWNTO 0):="11";
  
  CONSTANT ZEROMATRIX : DATA_ARRAY := (others => X"00");
  
  
  COMPONENT sBox is
	port(
	  clk       : in std_logic;
	  rst       : in std_logic;
		addr      : in	std_logic_vector  (7 downto 0);	  -- Byte
		sByte     : out std_logic_vector (7 downto 0)	 -- Substituted Byte		
		);		
  end COMPONENT;
  
  function mult2( byte_in:  std_logic_vector) return std_logic_vector;
  function mult3( byte_in:  std_logic_vector) return std_logic_vector;
  function mult( byte1,byte2: std_logic_vector) return std_logic_vector;

end yyangPkg;



package body yyangPkg is
 
   function mult(byte1,byte2: std_logic_vector)return std_logic_vector is
      
      variable tp:        std_logic_vector(7 downto 0);
      variable counter:   integer range 0 to 8;
      variable carry:     std_logic;
      variable a:         std_logic_vector(7 downto 0);
      variable b:         std_logic_vector(7 downto 0);
      variable byte_out:  std_logic_vector(7 downto 0);
      
      begin
        tp:=X"00";
        a:=byte1;
        b:=byte2;
        counter:=0;
        for counter in 0 to 7 loop
          if b(0)='1'then
            tp:=tp XOR a;
          end if;
          carry:=a(7);
          a:=a(6 downto 0)&'0';
          if carry='1' then
            a:=a XOR X"1b";
          end if;
          b:='0'& b(7 downto 1);
        end loop;
        return tp;
  
  end mult;
  
  function mult2(byte_in: std_logic_vector)return std_logic_vector is
      
      variable tp0: std_logic_vector(7 downto 0);
      variable tp1: std_logic_vector(7 downto 0);
      variable tp2: std_logic_vector(7 downto 0);
      variable tp3: std_logic_vector(7 downto 0);
      variable tp4: std_logic_vector(7 downto 0);
      variable tp5: std_logic_vector(7 downto 0);
      variable tp6: std_logic_vector(7 downto 0);
      variable tp7: std_logic_vector(7 downto 0);
      
      variable byte_out: std_logic_vector(7 downto 0);
      
      begin
        if(byte_in(0)='1')then tp0 := X"02";else tp0:= X"00";end if;
        if(byte_in(1)='1')then tp1 := X"04";else tp1:= X"00";end if;
        if(byte_in(2)='1')then tp2 := X"08";else tp2:= X"00";end if;
        if(byte_in(3)='1')then tp3 := X"10";else tp3:= X"00";end if;
        if(byte_in(4)='1')then tp4 := X"20";else tp4:= X"00";end if;
        if(byte_in(5)='1')then tp5 := X"40";else tp5:= X"00";end if;
        if(byte_in(6)='1')then tp6 := X"80";else tp6:= X"00";end if;
        if(byte_in(7)='1')then tp7 := X"1B";else tp7:= X"00";end if; 
        byte_out := tp0 XOR tp1 XOR tp2 XOR tp3 XOR tp4 XOR tp5 XOR tp6 XOR tp7;
        
        return byte_out;
  
  end mult2;
  
  function mult3(byte_in: std_logic_vector)return std_logic_vector is
  
      variable tp0: std_logic_vector(7 downto 0);
      variable tp1: std_logic_vector(7 downto 0);
      variable tp2: std_logic_vector(7 downto 0);
      variable tp3: std_logic_vector(7 downto 0);
      variable tp4: std_logic_vector(7 downto 0);
      variable tp5: std_logic_vector(7 downto 0);
      variable tp6: std_logic_vector(7 downto 0);
      variable tp7: std_logic_vector(7 downto 0);
      
      variable byte_out: std_logic_vector(7 downto 0);
      
      begin
        if(byte_in(0)='1')then tp0 := X"03";else tp0:= X"00";end if;
        if(byte_in(1)='1')then tp1 := X"06";else tp1:= X"00";end if;
        if(byte_in(2)='1')then tp2 := X"0C";else tp2:= X"00";end if;
        if(byte_in(3)='1')then tp3 := X"18";else tp3:= X"00";end if;
        if(byte_in(4)='1')then tp4 := X"30";else tp4:= X"00";end if;
        if(byte_in(5)='1')then tp5 := X"60";else tp5:= X"00";end if;
        if(byte_in(6)='1')then tp6 := X"C0";else tp6:= X"00";end if;
        if(byte_in(7)='1')then tp7 := X"9B";else tp7:= X"00";end if; 
        byte_out := tp0 XOR tp1 XOR tp2 XOR tp3 XOR tp4 XOR tp5 XOR tp6 XOR tp7;
        
        
        return byte_out;
  
  end mult3; 
  
end yyangPkg;     
