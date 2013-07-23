
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package anaPkg is

	constant addressWidth 	: integer := 6;

	-- The number of bits used to represent an IDP
	constant idpWidth : integer := 32;
	
	-- The number of parallel bits in the up- and downstream
	constant dataWidth : integer := 8;
	
	-- The number of bytes used to represent an IDP
	constant idpBytes : integer := idpWidth/dataWidth;
	
	function toLog2Ceil (x: integer) return integer;
	
--	subtype idpByteCounter is unsigned(1 downto 0); 
--	constant idpByteCounterMax : idpByteCounter := (1 downto 0 => '1');
	subtype idpByteCounter is unsigned(toLog2Ceil(idpBytes)-1 downto 0); 
	constant idpByteCounterMax : idpByteCounter := to_unsigned(idpBytes-1, toLog2Ceil(idpBytes));
	
	-- The number of bits of the local address
	constant localAddrWidth : integer := 2;
	
	-- The number of bits of the global address
	constant globalAddrWidth : integer := addressWidth - localAddrWidth;
	
	-- The number of bits used to represent a priority
	constant priorityWidth : integer := dataWidth - addressWidth;
	
	-- The position of the direction bit
	constant directionBit : integer := 0;
	
	-- The position of the 'latency critical' bit
	constant latencyCriticalBit : integer := 1;
	
	-- The size of the ring buffer used to send data from software to hardware
	constant sw2hwRamSize : integer := 64;
		

	component packetDecoder is
	port (
	clk 			: in std_logic;
	reset 			: in std_logic;
	-- Signals from the switch
	switch_data_rdy		: in  std_logic;
	switch_data		: in  std_logic_vector(dataWidth downto 0);
	thread_read_rdy	 	: out std_logic;

	--- Decoded values of the packet
	noc_rx_sof 		: out std_logic;
	noc_rx_eof 		: out std_logic; -- Indicates the end of the packet
	noc_rx_data		: out std_logic_vector(dataWidth-1 downto 0); -- The current data byte
	noc_rx_src_rdy		: out std_logic; -- '1' if the data are valid, '0' else
	noc_rx_direction	: out std_logic; -- '1' for egress, '0' for ingress
	noc_rx_priority		: out std_logic_vector(priorityWidth-1 downto 0); -- The priority of the packet
	noc_rx_latencyCritical 	: out std_logic; -- '1' if this packet is latency critical
	noc_rx_srcIdp		: out std_logic_vector(idpWidth-1 downto 0); -- The source IDP
	noc_rx_dstIdp		: out std_logic_vector(idpWidth-1 downto 0); -- The destination IDP
	noc_rx_dst_rdy 		: in std_logic -- Read enable for the functional block
	);
	end component;
	
	component packetEncoder is
	port (
	clk 			: in std_logic;
	reset 			: in std_logic;
	-- Signals to the switch
	switch_read_rdy			: in  std_logic;
	thread_data			: out std_logic_vector(dataWidth downto 0);
	thread_data_rdy 	: out std_logic;

	-- Decoded values of the packet
	noc_tx_sof 		: in std_logic; -- Indicates the start of a new packet
	noc_tx_eof 		: in std_logic; -- Indicates the end of the packet
	noc_tx_data		: in std_logic_vector(dataWidth-1 downto 0); -- The current data byte
	noc_tx_src_rdy 		: in std_logic; -- '1' if the data are valid, '0' else
	noc_tx_globalAddress	: in std_logic_vector(globalAddrWidth-1 downto 0); -- The global hardware address of the destination
	noc_tx_localAddress	: in std_logic_vector(localAddrWidth-1 downto 0); -- The local hardware address of the destination
	noc_tx_direction	: in std_logic; -- '1' for egress, '0' for ingress
	noc_tx_priority		: in std_logic_vector(priorityWidth-1 downto 0); -- The priority of the packet
	noc_tx_latencyCritical 	: in std_logic; -- '1' if this packet is latency critical
	noc_tx_srcIdp 		: in std_logic_vector(idpWidth-1 downto 0); -- The source IDP
	noc_tx_dstIdp 		: in std_logic_vector(idpWidth-1 downto 0); -- The destination IDP
	noc_tx_dst_rdy 		: out std_logic -- Read enable for the applied data
	);
	end component packetEncoder;

	
end anaPkg;

package body anaPkg is
	
	function toLog2Ceil (x: integer) return integer is
	  variable y,z: integer;
	begin
	  y := 1;
	  z := 2;
	  while x > z loop
	  	y := y + 1;
	  	z := z * 2;
	  end loop;
	  return y;
	end toLog2Ceil;
	
end anaPkg;
