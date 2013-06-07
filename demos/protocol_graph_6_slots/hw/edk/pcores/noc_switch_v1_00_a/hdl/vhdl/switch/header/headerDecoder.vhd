library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.headerPkg.all;

entity headerDecoder is
		port (
		data		: in std_logic_vector(dataWidth-1 downto 0);
		
		destAddr	: out address;
		prio		: out priority
	);
end entity headerDecoder;

architecture rtl of headerDecoder is
	
begin

	destAddr <= extractAddress(data);
	prio <= extractPrio(data);
	
end architecture rtl;
