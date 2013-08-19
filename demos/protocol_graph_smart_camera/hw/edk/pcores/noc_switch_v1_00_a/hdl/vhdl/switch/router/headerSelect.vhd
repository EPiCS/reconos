library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.headerPkg.all;
use noc_switch_v1_00_a.utilPkg.all;
use noc_switch_v1_00_a.switchPkg.all;

entity headerSelect is
	port (
		headerIn		: in headerArray(numPorts-1 downto 0);
		selected		: out std_logic_vector(numPorts-1 downto 0);
		
		dataValid		: out std_logic;
		selectedRxPort	: out portNr;
		selectedAddr	: out address
	);
end entity headerSelect;


architecture rtl of headerSelect is

	function selectHeaderWithPrio(headers:headerArray(numPorts-1 downto 0); searchedPrio:priority) return portNrWrapper is
		variable rxPortNr : portNrWrapper;
	begin
		rxPortNr := (others => '0');
		while rxPortNr<numPorts loop
			if headers(wrappedPortNrToInteger(rxPortNr)).valid='1' then
				if headers(wrappedPortNrToInteger(rxPortNr)).prio = searchedPrio then
					return rxPortNr;
				end if;
			end if;
			rxPortNr := rxPortNr + 1;
		end loop;
		return portNrUndefined;
	end selectHeaderWithPrio;

	function selectHeader(headers:headerArray(numPorts-1 downto 0)) return portNrWrapper is
		variable rxPortNr : portNrWrapper;
		variable pri : priority;
	begin
		pri := to_unsigned(numPriorities-1, priorityWidth);
		loop
			rxPortNr := selectHeaderWithPrio(headers,pri);
			if rxPortNr /= portNrUndefined then
				return rxPortNr;
			end if;
			exit when pri = to_unsigned(0, priorityWidth);
			pri := pri-1; 
		end loop;
		return portNrUndefined;
	end selectHeader;	

begin
	
	nomem_output : process(headerIn)
		variable rxPortNr : portNrWrapper;
	begin
		-- default assignments
		selected <= (others => '0');
		dataValid <= '0';
		selectedRxPort <= (others => '-');
		selectedAddr <= dontCareAddr;
		
		rxPortNr := selectHeader(headerIn);
		if rxPortNr /= portNrUndefined then
			selected(wrappedPortNrToInteger(rxPortNr)) <= '1';
			dataValid <= '1';
			selectedRxPort <= toPortNr(rxPortNr);
			selectedAddr <= headerIn(wrappedPortNrToInteger(rxPortNr)).addr;
		end if;
		
	end process nomem_output;
end architecture rtl;
