library ieee;
use ieee.std_logic_1164.all;

entity progressCtr is
	generic(
		C_LOCAL_RAM_ADDR_WIDTH 	: integer
	);
	port (
		localRAMValidPointer	: in  std_logic_vector(C_LOCAL_RAM_ADDR_WIDTH-1 downto 0);
		readPointer				: in  std_logic_vector(C_LOCAL_RAM_ADDR_WIDTH-1 downto 0);
		packetAvailable			: out std_logic
	);
end entity progressCtr;

architecture rtl of progressCtr is
	
begin

	packetAvailable <= '0' when localRAMValidPointer = readPointer else '1';

end architecture rtl;
