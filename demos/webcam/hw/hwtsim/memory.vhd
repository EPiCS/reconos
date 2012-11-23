library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity memory is
	port (
		clk  : in  std_logic;
		rst  : in  std_logic;
		addr : in  std_logic_vector(31 downto 0);
		di   : in  std_logic_vector(31 downto 0);
		do   : out std_logic_vector(31 downto 0);
		we   : in std_logic
	);
end memory;

architecture Behavioral of memory is
	constant C_MEM_SIZE : natural := 4*1024;-- 0x00000000 ... 0x00001000
	type MEM_T is array (0 to C_MEM_SIZE-1) of std_logic_vector(31 downto 0);
	signal mem : MEM_T;
begin

	do <= mem(CONV_INTEGER(addr));
	
	process(clk,rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				mem(0) <= x"00000004"; -- size_x
				mem(1) <= x"00000006"; -- size_y
				mem(2) <= x"00000000"; -- size_y
				mem(3) <= x"00000000"; -- size_y
				for i in 4 to C_MEM_SIZE-1 loop
					mem(i) <= x"DA" & CONV_STD_LOGIC_VECTOR(C_MEM_SIZE-1 - i,16) & x"00"; -- 0x00000FFF ... 0x00000000; sort: 0x00000FFF ... 0x00000800
				end loop;
			elsif we = '1' then
				mem(CONV_INTEGER(addr)) <= di;
			end if;
		end if;
	end process;

end Behavioral;

