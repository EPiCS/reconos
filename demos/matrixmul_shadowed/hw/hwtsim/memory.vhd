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
	constant C_MEM_SIZE : natural := 128*128;
	-- Use the following line for simulation, otherwise your computer runs out of memory
	--constant C_MEM_SIZE : natural := 32*32;
	type MEM_T is array (0 to 4*C_MEM_SIZE-1) of std_logic_vector(31 downto 0);
	signal mem : MEM_T;
begin

	do <= mem(CONV_INTEGER(addr));
	
	process(clk,rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				for i in 0 to C_MEM_SIZE-1 loop
					if (i<3) then
						mem(i) <= CONV_STD_LOGIC_VECTOR((i+1)*C_MEM_SIZE,30) & "00";
					else
						mem(i) <= (others => '0');
					end if;
				end loop;
				for i in C_MEM_SIZE to 2*C_MEM_SIZE-1 loop
					mem(i) <= x"00" & CONV_STD_LOGIC_VECTOR(i,24);
				end loop;
				for i in 2*C_MEM_SIZE to 3*C_MEM_SIZE-1 loop
					mem(i) <= x"00" & CONV_STD_LOGIC_VECTOR(i,24);
				end loop;
				for i in 3*C_MEM_SIZE to 4*C_MEM_SIZE-1 loop
					mem(i) <= x"30" & CONV_STD_LOGIC_VECTOR(i,24);
				end loop;
			elsif we = '1' then
				mem(CONV_INTEGER(addr)) <= di;
			end if;
		end if;
	end process;

end Behavioral;

