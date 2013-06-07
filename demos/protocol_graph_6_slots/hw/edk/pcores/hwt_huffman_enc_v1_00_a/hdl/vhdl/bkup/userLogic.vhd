library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

entity userLogic is
	port (
		clk : in std_logic;
		reset : in std_logic;
		
		downstreamReadEnable	: out std_logic;
		downstreamEmpty  		: in std_logic;
		downstreamData			: in std_logic_vector(8 downto 0);
		upstreamWriteEnable		: out std_logic;
		upstreamData			: out std_logic_vector(8 downto 0);
		upstreamFull 			: in std_logic;
		
		packetTransmitted		: out std_logic
	);
end entity userLogic;

architecture rtl of userLogic is

	constant HW_TO_SW_GATEWAY_ADDR_GLOBAL : std_logic_vector(globalAddrWidth-1 downto 0) := "0000";
	constant HW_TO_SW_GATEWAY_ADDR_LOCAL : std_logic_vector(localAddrWidth-1 downto 0) := "00";
	constant MY_SRC_IDP : std_logic_vector(idpWidth-1 downto 0) := x"aabbccdd";
	constant MY_DST_IDP : std_logic_vector(idpWidth-1 downto 0) := x"eeff5566";

	signal decoder_startOfPacket : std_logic;
	signal decoder_endOfPacket : std_logic;
	signal decoder_data : std_logic_vector(dataWidth-1 downto 0);
	signal decoder_dataValid : std_logic;
	signal decoder_direction : std_logic;
	signal decoder_priority : std_logic_vector(priorityWidth-1 downto 0);
	signal decoder_latencyCritical : std_logic;
	signal decoder_srcIdp : std_logic_vector(idpWidth-1 downto 0);
	signal decoder_dstIdp : std_logic_vector(idpWidth-1 downto 0);
	signal decoder_readEnable : std_logic;
	
	signal encoder_startOfPacket : std_logic;
	signal encoder_endOfPacket : std_logic;
	signal encoder_data : std_logic_vector(dataWidth-1 downto 0);
	signal encoder_dataValid : std_logic;
	signal encoder_direction : std_logic;
	signal encoder_priority : std_logic_vector(priorityWidth-1 downto 0);
	signal encoder_latencyCritical : std_logic;
	signal encoder_srcIdp : std_logic_vector(idpWidth-1 downto 0);
	signal encoder_dstIdp : std_logic_vector(idpWidth-1 downto 0);
	signal encoder_readEnable : std_logic;
	signal encoder_globalAddress : std_logic_vector(globalAddrWidth-1 downto 0);
	signal encoder_localAddress : std_logic_vector(localAddrWidth-1 downto 0);
	
	signal checksum_n, checksum_p : unsigned(dataWidth-1 downto 0);
	signal writeChecksum_n, writeChecksum_p : std_logic;
	
begin
	
	packetDecoder : entity ana_v1_00_a.packetDecoder
		port map(
			clk 					=> clk,
			reset 					=> reset,
			
			-- Signals from the switch
			downstreamEmpty			=> downstreamEmpty,
			downstreamData			=> downstreamData,
			downstreamReadEnable 	=> downstreamReadEnable,
			
			-- Decoded values of the packet
			startOfPacket			=> decoder_startOfPacket,	-- Indicates the start of a new packet
			endOfPacket				=> decoder_endOfPacket,		-- Indicates the end of the packet
			data					=> decoder_data,			-- The current data byte
			dataValid				=> decoder_dataValid,		-- '1' if the data are valid, '0' else
			direction				=> decoder_direction,		-- '1' for egress, '0' for ingress
			priority				=> decoder_priority,		-- The priority of the packet
			latencyCritical			=> decoder_latencyCritical,	-- '1' if this packet is latency critical
			srcIdp					=> decoder_srcIdp,			-- The source IDP
			dstIdp					=> decoder_dstIdp,			-- The destination IDP
			readEnable				=> decoder_readEnable
		);
		
	packetEncoder : entity ana_v1_00_a.packetEncoder
	port map(
			clk 					=> clk,
			reset 					=> reset,
			
			-- Signals from the switch
			upstreamFull			=> upstreamFull,
			upstreamData			=> upstreamData,
			upstreamWriteEnable 	=> upstreamWriteEnable,
			
			-- Decoded values of the packet
			startOfPacket			=> encoder_startOfPacket,	-- Indicates the start of a new packet
			endOfPacket				=> encoder_endOfPacket,		-- Indicates the end of the packet
			data					=> encoder_data,			-- The current data byte
			dataValid				=> encoder_dataValid,		-- '1' if the data are valid, '0' else
			globalAddress			=> encoder_globalAddress,	-- The global hardware address of the destination
			localAddress			=> encoder_localAddress,	-- The local hardware address of the destination
			direction				=> encoder_direction,		-- '1' for egress, '0' for ingress
			priority				=> encoder_priority,		-- The priority of the packet
			latencyCritical			=> encoder_latencyCritical,	-- '1' if this packet is latency critical
			srcIdp					=> encoder_srcIdp,			-- The source IDP
			dstIdp					=> encoder_dstIdp,			-- The destination IDP
			readEnable				=> encoder_readEnable
		);
		
	
	decoder_readEnable <= '0' when writeChecksum_p = '1'
						  else encoder_readEnable;
	
	writeChecksum_n <= '1' when decoder_endOfPacket = '1' and decoder_readEnable = '1'
					   else '0' when writeChecksum_p = '1' and encoder_readEnable = '1'
					   else writeChecksum_p; 
					   
	packetTransmitted <= '1' when writeChecksum_p = '1' and encoder_readEnable = '1'
						 else '0';
	
	checksum_n <= checksum_p + unsigned(decoder_data) when decoder_readEnable = '1'
				  else (others => '0') when writeChecksum_p = '1' and encoder_readEnable = '1'
				  else checksum_p;
				  
	encoder_startOfPacket <= '0' when writeChecksum_p = '1'
							 else decoder_startOfPacket;
	
	encoder_endOfPacket <= writeChecksum_p;
	
	encoder_data <= std_logic_vector(checksum_p) when writeChecksum_p = '1'
					else decoder_data;
				
	encoder_dataValid <= '1' when writeChecksum_p = '1'
				 else decoder_dataValid;
				 
	encoder_globalAddress <= HW_TO_SW_GATEWAY_ADDR_GLOBAL;
	encoder_localAddress <= HW_TO_SW_GATEWAY_ADDR_LOCAL;
	encoder_direction <= decoder_direction;
	encoder_priority <= decoder_priority;
	encoder_latencyCritical <= decoder_latencyCritical;
	encoder_srcIdp <= MY_SRC_IDP;
	encoder_dstIdp <= MY_DST_IDP;
	
	mem_stateTransition: process(clk, reset) is
	begin
		if reset = '1' then
			checksum_p <= (dataWidth-1 downto 0 => '0');
			writeChecksum_p <= '0';
		elsif rising_edge(clk) then
			checksum_p <= checksum_n;
			writeChecksum_p <= writeChecksum_n;
		end if;
	end process mem_stateTransition;
	
	
	
end architecture rtl;
