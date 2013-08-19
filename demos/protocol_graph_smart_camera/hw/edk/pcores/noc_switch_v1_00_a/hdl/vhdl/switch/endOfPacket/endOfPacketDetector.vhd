library ieee;
use ieee.std_logic_1164.all;

entity endOfPacketDetector is
	port (
		dataValid	: in std_logic;
		flag		: in std_logic;
		fifoEnable	: in std_logic;
		
		endOfPacket	: out std_logic
	);
end entity endOfPacketDetector;

architecture rtl of endOfPacketDetector is
begin

	endOfPacket <= dataValid and fifoEnable and flag;
	
end architecture rtl;
