library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.switchPkg.all;

entity extTxPortSelect is
	port (
		rxPortNrIn 			: in portNr;
		rxPortNrOut			: out portNr;
		
		txPortIdle			: in std_logic_vector(numExtPorts-1 downto 0);
		txPortWriteEnable	: out std_logic_vector(numExtPorts-1 downto 0);
		
		txFifoReadEnable	: out std_logic;
		txFifoEmpty			: in std_logic;
		
		txPortNrOut			: out portNr;
		rxPortWriteEnable	: out std_logic_vector(numPorts-1 downto 0)
	);
end entity extTxPortSelect;

architecture rtl of extTxPortSelect is
	
	function selectTxPort(txPortIdle: std_logic_vector(numExtPorts-1 downto 0)) return portNrWrapper is
		variable result : portNrWrapper;
	begin
		result := (others => '0');
		while result < numExtPorts loop
			if txPortIdle(wrappedPortNrToInteger(result)) = '1' then
				return result + numIntPorts;
			end if;
			result := result + 1;
		end loop;
		return result + numIntPorts;
	end selectTxPort;
	
begin

	rxPortNrOut <= rxPortNrIn;
	
	nomem_output:process(txPortIdle, txFifoEmpty, rxPortNrIn) is
		variable txPortNr : portNrWrapper;
	begin
		-- default assignments
		txPortWriteEnable <= (others => '0');
		txFifoReadEnable <= '0';
		rxPortWriteEnable <= (others => '0');
		txPortNrOut <= (others => '-');
		
		if txFifoEmpty = '0' then
			txPortNr := selectTxPort(txPortIdle);
			if txPortNr /= portNrUndefined then
				txPortWriteEnable(wrappedPortNrToInteger(txPortNr-numIntPorts)) <= '1';
				txFifoReadEnable <= '1';
				txPortNrOut <= txPortNr;
				rxPortWriteEnable(portNrToInteger(rxPortNrIn)) <= '1';
			end if;
		end if;
			
	end process nomem_output;

end architecture rtl;
