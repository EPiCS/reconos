library ieee;
use ieee.std_logic_1164.all;

entity headerDetector is
	port (
		clk 		: in std_logic;
		reset 		: in std_logic;
		
		readEnable	: in std_logic;
		empty		: in std_logic;
		endOfPacket	: in std_logic;
		
		headerValid	: out std_logic
	);
end entity headerDetector;

architecture rtl of headerDetector is
	
	type state is (idle, packetTransfer);
	signal state_p, state_n	: state;
	
begin

	nomem_output : process (state_p, readEnable, empty, endOfPacket) is
	begin
		-- default assignment
		headerValid <= '0';
		
		if state_p = idle then
			headerValid <= not empty;
		end if;
		
	end process nomem_output;
	
	nomem_nextState : process(state_p, empty, readEnable, endOfPacket) is
	begin
		-- default assignment
		state_n <= state_p;
		
		case state_p is
			when idle => 
				if empty='0' and readEnable='1' then
					state_n <= packetTransfer;
				end if;
			when packetTransfer => 
				if endOfPacket='1' and readEnable='1' then
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
