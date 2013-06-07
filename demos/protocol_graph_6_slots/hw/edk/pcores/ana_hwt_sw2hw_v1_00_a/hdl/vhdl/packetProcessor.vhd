library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

entity packetProcessor is
	port (
		clk 				: in std_logic;
		reset 				: in std_logic;
		
		packetAvailable		: in  std_logic;
		
		readEnable			: out std_logic;
		ramData				: in  std_logic_vector(31 downto 0);
		
		upstreamWriteEnable	: out std_logic;
		upstreamData		: out std_logic_vector(dataWidth downto 0);
		upstreamFull		: in  std_logic
	);
end entity packetProcessor;

architecture rtl of packetProcessor is
	
	type state_t is (STATE_IDLE,
					 STATE_READING_PACKET_LENGTH,
					 STATE_PACKET_TRANSFER);
	signal state_n, state_p : state_t;
	
	signal remainingPacketLength_n, remainingPacketLength_p : unsigned(31 downto 0);
	signal byteCounter_n, byteCounter_p : unsigned(1 downto 0);
	
	function getByte(word: std_logic_vector(31 downto 0); byte: unsigned(1 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(dataWidth-1 downto 0);
		variable a, b: integer;
	begin
		a := to_integer(byte)*dataWidth;
		b := a + dataWidth - 1;
		result(dataWidth-1 downto 0) := word(b downto a);
		return result;
	end getByte;
	
begin

	upstreamData(dataWidth-1 downto 0) <= getByte(ramData, byteCounter_p);
	upstreamData(dataWidth) <= '1' when remainingPacketLength_p = (31 downto 0 => '0') else '0';
	upstreamWriteEnable <= '1' when state_p = STATE_PACKET_TRANSFER else '0';

	nomem_readEnable : process(state_p, byteCounter_p, remainingPacketLength_p) is
	begin
		readEnable <= '0';
		if state_p = STATE_READING_PACKET_LENGTH then
			readEnable <= '1';
		elsif state_p = STATE_PACKET_TRANSFER then
			if byteCounter_p = (1 downto 0 => '0') or remainingPacketLength_p = (31 downto 0 => '0') then
				readEnable <= '1';
			end if;
		end if; 
	end process nomem_readEnable;

	byteCounter : process(state_p, byteCounter_p, upstreamFull) is
	begin
		byteCounter_n <= byteCounter_p;
		if state_p = STATE_READING_PACKET_LENGTH then
			byteCounter_n <= (others => '1');
		elsif state_p = STATE_PACKET_TRANSFER then
			if upstreamFull = '0' then
				byteCounter_n <= byteCounter_p-1;
			end if;
		end if;
	end process byteCounter;

	remainingPacketLength : process(state_p, remainingPacketLength_p, upstreamFull) is
	begin
		remainingPacketLength_n <= remainingPacketLength_p;
		if state_p = STATE_READING_PACKET_LENGTH then
			remainingPacketLength_n <= unsigned(ramData)-1;
		elsif state_p = STATE_PACKET_TRANSFER then
			if upstreamFull = '0' then
				remainingPacketLength_n <= remainingPacketLength_p-1;
			end if;			
		end if;
	end process remainingPacketLength;

	nomem_nextState : process(state_p, packetAvailable, remainingPacketLength_p) is
	begin
		state_n <= state_p;
		case state_p is
			when STATE_IDLE =>
				if packetAvailable = '1' then
					state_n <= STATE_READING_PACKET_LENGTH;
				end if;
				
			when STATE_READING_PACKET_LENGTH =>
				state_n <= STATE_PACKET_TRANSFER;
				
			when STATE_PACKET_TRANSFER =>
				if remainingPacketLength_p = (31 downto 0 => '0') then
					state_n <= STATE_IDLE;
				end if;
		end case;
	end process nomem_nextState;

	mem_stateTransition : process (clk, reset) is
	begin
		if reset = '1' then
			state_p <= STATE_IDLE;
			remainingPacketLength_p <= (others => '-');
			byteCounter_p <= (others => '-');
		elsif rising_edge(clk) then
			state_p <= state_n;
			remainingPacketLength_p <= remainingPacketLength_n;
			byteCounter_p <= byteCounter_n;  
		end if;
	end process mem_stateTransition;
	

end architecture rtl;
