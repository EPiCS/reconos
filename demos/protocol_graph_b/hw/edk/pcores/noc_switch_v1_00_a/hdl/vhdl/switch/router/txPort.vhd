library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.switchPkg.all;

entity txPort is
	port (
		clk	 		: in std_logic;
		reset 		: in std_logic;
		
		rxPortNrIn	: in portNr;
		rxPortNrOut	: out portNrWrapper;
		
		idle		: out std_logic;
		writeEnable	: in std_logic;
		endOfPacket	: in std_logic
	);
end entity txPort;

architecture rtl of txPort is
	
	type state is (idleState, packetTransfer);
	signal state_p, state_n : state;
	
	signal rxPortNr_p, rxPortNr_n : portNrWrapper;
	
begin

	rxPortNrOut <= rxPortNr_p;
	
	nomem_output:process(state_p) is
	begin
		idle <= '0';
		if state_p=idleState then
			idle <= '1';
		end if;
	end process nomem_output;

	nomem_nextState : process(state_p, rxPortNr_p, writeEnable, rxPortNrIn, endOfPacket) is
	begin
		-- default assignments
		state_n <= state_p;
		rxPortNr_n <= rxPortNr_p;
		
		if writeEnable = '1' then
			state_n <= packetTransfer;
			rxPortNr_n <= toPortNrWrapper(rxPortNrIn);
		end if;
		if endOfPacket='1' then
			state_n <= idleState;
			rxPortNr_n <= portNrUndefined;
		end if;
	end process nomem_nextState;
	
	mem_stateTransition : process(clk, reset) is
	begin
		if reset = '1' then
			state_p <= idleState;
			rxPortNr_p <= portNrUndefined;
		elsif rising_edge(clk) then
			state_p <= state_n;
			rxPortNr_p <= rxPortNr_n;
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
