library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_b;
use noc_switch_v1_00_b.switchPkg.all;

entity rxPort is
	port (
		clk	 		: in std_logic;
		reset 		: in std_logic;
		
		txPortNrIn	: in portNrArray(numIntPorts downto 0);
		txPortNrOut	: out portNrWrapper;
		
		writeEnable	: in std_logic_vector(numIntPorts downto 0);
		endOfPacket	: in std_logic
	);
end entity rxPort;

architecture rtl of rxPort is
	
	signal txPortNr_p, txPortNr_n : portNrWrapper;
	
begin

	txPortNrOut <= txPortNr_p;
	
	nomem_nextState : process(txPortNr_p, writeEnable, txPortNrIn, endOfPacket) is
	begin
		-- default assignments
		txPortNr_n <= txPortNr_p;
		
		for i in numIntPorts downto 0 loop
			if writeEnable(i)='1' then
				txPortNr_n <= toPortNrWrapper(txPortNrIn(i));
				exit;
			end if;
		end loop;

		if endOfPacket='1' then
			txPortNr_n <= portNrUndefined;
		end if;
	end process nomem_nextState;
	
	mem_stateTransition : process(clk, reset) is
	begin
		if reset = '1' then
			txPortNr_p <= portNrUndefined;
		elsif rising_edge(clk) then
			txPortNr_p <= txPortNr_n;
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
