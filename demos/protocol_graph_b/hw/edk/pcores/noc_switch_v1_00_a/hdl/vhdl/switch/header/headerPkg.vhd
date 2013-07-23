library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.utilPkg.all;

package headerPkg is
	
	constant dataWidth		: integer := 8;
	
	constant addressWidth 	: integer := 6;
	constant localAddrWidth	: integer := 2;
	constant globalAddrWidth: integer := addressWidth - localAddrWidth;
	
	constant priorityWidth 	: integer := dataWidth - addressWidth;
	constant numPriorities	: integer := toPow2(priorityWidth);
	
	subtype localAddr is std_logic_vector(localAddrWidth-1 downto 0);
	subtype localAddrInteger is integer range toPow2(localAddrWidth) downto 0;
	function localAddrToInteger(locAddr:localAddr) return localAddrInteger;
	
	subtype globalAddr is std_logic_vector(globalAddrWidth-1 downto 0);
	type address is record
		local	: localAddr;
		global	: globalAddr;
	end record;
	
	constant dontCareAddr : address := (local => (others => '-'), global => (others => '-'));
	
	subtype priority is unsigned(priorityWidth-1 downto 0);
	
	type header is record
		valid	: std_logic;
		addr	: address;
		prio	: priority;
	end record;
	
	type headerArray is array(natural range <>) of header;
	
	function extractAddress(headerBits: std_logic_vector(dataWidth-1 downto 0)) return address;
	function extractPrio(headerBits: std_logic_vector(dataWidth-1 downto 0)) return priority;
		
end package headerPkg;

package body headerPkg is
	
	function extractAddress(headerBits: std_logic_vector(dataWidth-1 downto 0)) return address is
		variable result: address;
	begin
		result.global :=  headerBits(addressWidth-1 downto localAddrWidth); --globalAddrWidth-1 downto 0);
		result.local := headerBits(localAddrWidth-1 downto 0);
		return result;
	end extractAddress;
	
	function extractPrio(headerBits: std_logic_vector(dataWidth-1 downto 0)) return priority is
		variable result: priority;
	begin
		result := unsigned(headerBits(dataWidth-1 downto addressWidth));
		return result;
	end extractPrio;
	
	function localAddrToInteger(locAddr:localAddr) return localAddrInteger is
		variable result: localAddrInteger;
	begin
		result := to_integer(unsigned(locAddr));
		return result;
	end function localAddrToInteger;
	
end package body headerPkg;
