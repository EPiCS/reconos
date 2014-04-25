library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_b;
use noc_switch_v1_00_b.utilPkg.all;
use noc_switch_v1_00_b.headerPkg.all;
use noc_switch_v1_00_b.switchPkg.all;

entity txFifoSelect is
	generic(
		globalAddress	: globalAddr
	);
	port (
		selectedAddr	: in address;
		dataValid		: in std_logic;
		
		fifoWriteEnable	: out std_logic_vector(numIntPorts downto 0) -- one for each internal fifo and one for the global fifo
	);
end entity txFifoSelect;

architecture rtl of txFifoSelect is
begin

	nomem_output : process (selectedAddr, dataValid) is
	begin
		-- default assignment
		fifoWriteEnable <= (others => '0');
		
		if dataValid = '1' then
			-- second condition required because of possible inconsistent transient state
			if selectedAddr.global = globalAddress and unsigned(selectedAddr.local) < numIntPorts then
					fifoWriteEnable(localAddrToInteger(selectedAddr.local)) <= '1';
			else
				fifoWriteEnable(numIntPorts) <= '1';
			end if;
		end if;
	end process nomem_output;

end architecture rtl;
