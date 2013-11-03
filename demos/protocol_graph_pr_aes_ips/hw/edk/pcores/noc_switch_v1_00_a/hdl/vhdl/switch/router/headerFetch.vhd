library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.headerPkg.all;

entity headerFetch is
	port (
		clk 			: in std_logic;
		reset 			: in std_logic;
		
		headerIn		: in header;
		endOfRxPacket	: in std_logic;
		selected		: in std_logic;
		
		headerOut		: out header
	);
end entity headerFetch;

architecture rtl of headerFetch is
	
	type state is (idle, packetTransfer);
	signal state_p, state_n : state;	
	
begin

	nomem_output : process (state_p, headerIn) is
	begin
		-- default assignment
		headerOut <= headerIn;
		
		if state_p=packetTransfer then
			headerOut.valid <= '0';
		end if;
		
	end process nomem_output;

	nomem_nextState : process (state_p, selected, endOfRxPacket) is
	begin
		-- default assignment
		state_n <= state_p;
		
		case state_p is
			when idle =>
				if selected='1' then
					state_n <= packetTransfer;
				end if;
			when packetTransfer => 
				if endOfRxPacket='1' then
					state_n <= idle;
				end if;
		end case;
	end process nomem_nextState;
	

	mem_stateTransition : process (clk, reset) is
	begin
		if reset = '1' then
			state_p <= idle;
		elsif rising_edge(clk) then
			state_p <= state_n;
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
