library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_b;
use noc_switch_v1_00_b.switchPkg.all;

entity intTxPortSelect is
	generic(
		txPortNr			: portNr
	);
	port (
		rxPortNrIn 			: in portNr;
		rxPortNrOut			: out portNr;
		
		txPortIdle			: in std_logic;
		txPortWriteEnable	: out std_logic;
		
		txFifoReadEnable	: out std_logic;
		txFifoEmpty			: in std_logic;
		
		txPortNrOut			: out portNr;
		rxPortWriteEnable	: out std_logic_vector(numPorts-1 downto 0)
	);
end entity intTxPortSelect;

architecture rtl of intTxPortSelect is
	
begin

	txPortNrOut <= txPortNr;
	rxPortNrOut <= rxPortNrIn;
	
	nomem_output:process(txPortIdle, txFifoEmpty, rxPortNrIn) is
	begin
		-- default assignments
		txPortWriteEnable <= '0';
		txFifoReadEnable <= '0';
		rxPortWriteEnable <= (others => '0');
		
		if txPortIdle = '1' and txFifoEmpty = '0' then
			txPortWriteEnable <= '1';
			txFifoReadEnable <= '1';
			rxPortWriteEnable(portNrToInteger(rxPortNrIn)) <= '1';
		end if;
	end process nomem_output;

end architecture rtl;
