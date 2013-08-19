library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.utilPkg.all;
use noc_switch_v1_00_a.headerPkg.all;

package switchPkg is

	constant numPorts 		: integer := 6;
	constant numIntPorts	: integer := 2;
	constant numExtPorts	: integer := numPorts - numIntPorts;


	type inputLinkIn is record
		empty	: std_logic;
		data	: std_logic_vector(dataWidth downto 0);
	end record;
	type inputLinkInArray is array(natural range<>) of inputLinkIn;

	type inputLinkOut is record
		readEnable	: std_logic;
	end record;
	type inputLinkOutArray is array(natural range<>) of inputLinkOut;

	type outputLinkIn is record
		full	: std_logic;
	end record;
	type outputLinkInArray is array(natural range<>) of outputLinkIn;

	type outputLinkOut is record
		writeEnable	: std_logic;
		data		: std_logic_vector(dataWidth downto 0);
	end record;
	type outputLinkOutArray is array(natural range<>) of outputLinkOut;

	subtype portNr is unsigned(toLog2Ceil(numPorts)-1 downto 0);
	type portNrArray is array(natural range<>) of portNr;
	subtype portNrInteger is integer range numPorts-1 downto 0;

	subtype portNrWrapper is unsigned(toLog2Ceil(numPorts+1)-1 downto 0);
	type portNrWrapperArray is array(natural range<>) of portNrWrapper;
	subtype portNrWrapperInteger is integer range numPorts downto 0;

	constant portNrUndefined	: portNrWrapper := to_unsigned(numPorts, toLog2Ceil(numPorts));

	function toPortNr(wrappedPortNr: portNrWrapper) return portNr;
	function toPortNrWrapper(unwrappedPortNr: portNr) return portNrWrapper;
	function wrappedPortNrToInteger(wrappedPortNr: portNrWrapper) return portNrWrapperInteger;
	function portNrToInteger(portNr: portNr) return portNrInteger;
	function integerToPortNr(intPortNr:portNrInteger) return portNr;
	function wrappedPortNrEqual(wrappedPortNr1, wrappedPortNr2:portNrWrapper) return boolean;

end package switchPkg;

package body switchPkg is

	function toPortNr(wrappedPortNr: portNrWrapper) return portNr is
	begin
		return wrappedPortNr(toLog2Ceil(numPorts)-1 downto 0);
	end toPortNr;

	function toPortNrWrapper(unwrappedPortNr: portNr) return portNrWrapper is
		variable result : portNrWrapper;
	begin
		result := (others => '0');
		result(toLog2Ceil(numPorts)-1 downto 0) := unwrappedPortNr;
		return result;
	end toPortNrWrapper;

	function wrappedPortNrToInteger(wrappedPortNr: portNrWrapper) return portNrWrapperInteger is
		variable result : portNrWrapperInteger;
	begin
		result := to_integer(wrappedPortNr);
		return result;
	end;

	function portNrToInteger(portNr: portNr) return portNrInteger is
		variable result : portNrInteger;
	begin
		result := to_integer(portNr);
		return result;
	end;

	function integerToPortNr(intPortNr:portNrInteger) return portNr is
		variable result: portNr;
	begin
		result := to_unsigned(intPortNr,toLog2Ceil(numPorts));
		return result;
	end function integerToPortNr;

	function wrappedPortNrEqual(wrappedPortNr1, wrappedPortNr2:portNrWrapper) return boolean is
	begin
		for i in toLog2Ceil(numPorts+1)-1 downto 0 loop
			if wrappedPortNr1(i) /= wrappedPortNr2(i) then
				return false;
			end if;
		end loop;
		return true;
	end function wrappedPortNrEqual;

end package body switchPkg;
