library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity localRAMCtr is
	generic(
		C_LOCAL_RAM_ADD_WIDTH 	: integer;
		C_RING_BUFFER_WORDS		: integer
	);
	port (
		clk 		: in std_logic;
		reset 		: in std_logic;
		
		readEnable	: in  std_logic;
		dout		: out std_logic_vector(31 downto 0);
		
		ramAddr		: out std_logic_vector(C_LOCAL_RAM_ADD_WIDTH-1 downto 0);
		ramData		: in  std_logic_vector(31 downto 0)
	);
end entity localRAMCtr;

architecture rtl of localRAMCtr is
	
	signal ramAddr_n, ramAddr_p : std_logic_vector(C_LOCAL_RAM_ADD_WIDTH-1 downto 0);
	
	constant maxAddr : std_logic_vector := std_logic_vector(to_unsigned(C_RING_BUFFER_WORDS, C_LOCAL_RAM_ADD_WIDTH));
	
	function incAddr (addr : std_logic_vector(C_LOCAL_RAM_ADD_WIDTH-1 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(C_LOCAL_RAM_ADD_WIDTH-1 downto 0);
	begin
		if addr = maxAddr then
			result := (others => '0');
		else
			result := std_logic_vector(unsigned(addr)+1);
		end if;
		return result;
	end function incAddr;
	
	
begin
	
	-- output
	dout <= ramData;
	ramAddr <= ramAddr_n;	
	
	-- internal state
	ramAddr_n <= incAddr(ramAddr_p) when readEnable = '1' else ramAddr_p;

	mem_stateTransition:process (clk, reset) is
	begin
		if reset = '1' then
			ramAddr_p <= (others => '0');
		elsif rising_edge(clk) then
			ramAddr_p <= ramAddr_n;
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
