library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library noc_switch_v1_00_b;
use noc_switch_v1_00_b.utilPkg.all;

entity interSwitchFifo is
	port (
		clk 		: in std_logic;
		rst 		: in std_logic;
		wr_en		: in std_logic;
		rd_en		: in std_logic;
		empty		: out std_logic;
		full		: out std_logic;
		din			: in std_logic_vector(8 downto 0);
		dout		: out std_logic_vector(8 downto 0)
	);
end entity interSwitchFifo;

architecture rtl of interSwitchFifo is

	constant fifoDepth : integer := 16;

	subtype position is unsigned(toLog2Ceil(fifoDepth)-1 downto 0);
	subtype positionInteger is integer range fifoDepth-1 downto 0;
	function positionToInteger(pos: position) return positionInteger is
		variable result : positionInteger;
	begin
		result := to_integer(pos);
		return result;
	end function positionToInteger;
	
	function isEmpty(readPos, writePos : position) return boolean is
	begin
		if readPos = writePos then
			return true;
		end if;
		return false;
	end function isEmpty;
	
	function isFull(readPos, writePos : position) return boolean is
	begin
		if writePos = fifoDepth-1 then
			if readPos = 0 then
				return true;
			end if;
		else
			if writePos + 1 = readPos then
				return true;
			end if; 
		end if;
		return false;
	end function isFull;
	
	signal readPosition_p, readPosition_n, writePosition_p, writePosition_n : position;
	
	type valueArray is array(natural range<>) of std_logic_vector(8 downto 0);
	signal ringBuffer_p, ringBuffer_n : valueArray(fifoDepth-1 downto 0);
	
begin

	dout <= ringBuffer_p(positionToInteger(readPosition_p));

	nomem_output : process(readPosition_p, writePosition_p) is
	begin
		empty <= '0';
		full <= '0';
		if isEmpty(readPosition_p, writePosition_p) then
			empty <= '1';
		end if;
		if isFull(readPosition_p, writePosition_p) then
			full <= '1';
		end if;
	end process nomem_output;
 
 	nomem_nextState : process(readPosition_p, writePosition_p, ringBuffer_p, wr_en, rd_en, din) is
 	begin
 		-- default assignments
 		readPosition_n <= readPosition_p;
 		writePosition_n <= writePosition_p;
 		ringBuffer_n <= ringBuffer_p;
 		
 		-- writing
 		if wr_en = '1' and not isFull(readPosition_p, writePosition_p) then
 			ringBuffer_n(positionToInteger(writePosition_p)) <= din;
 			if writePosition_p < fifoDepth-1 then
 				writePosition_n <= writePosition_p + 1;
 			else
 				writePosition_n <= (others => '0');
 			end if;
 		end if;
 		
 		-- reading
 		if rd_en = '1' and not isEmpty(readPosition_p, writePosition_p) then
 			if readPosition_p < fifoDepth-1 then
 				readPosition_n <= readPosition_p + 1;
 			else
 				readPosition_n <= (others => '0');
 			end if;
 		end if;
 	end process nomem_nextState;

	mem_stateTransition : process (clk, rst) is
	begin
		if rst = '1' then
			readPosition_p <= (others => '0');
			writePosition_p <= (others => '0');
			for i in 0 to fifoDepth-1 loop
				ringBuffer_p(i) <= (others => '0');
			end loop;
		elsif rising_edge(clk) then
			readPosition_p <= readPosition_n;
			writePosition_p <= writePosition_n;
			ringBuffer_p <= ringBuffer_n;
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
