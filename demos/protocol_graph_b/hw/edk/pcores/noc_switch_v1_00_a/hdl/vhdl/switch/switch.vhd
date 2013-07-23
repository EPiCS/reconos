library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.switchPkg.all;
use noc_switch_v1_00_a.headerPkg.all;

entity switch is
	generic(
		globalAddress	: globalAddr := "0000"	-- The global address of this switch. Packets with this global address are forwarded to the internal output link corresponding to the local address of the packet.
	);
	port (
		clk				: in std_logic;
		reset			: in std_logic;
		inputLinksIn	: in inputLinkInArray(numPorts-1 downto 0);		-- Input signals of the input links (internal AND external links)
		inputLinksOut	: out inputLinkOutArray(numPorts-1 downto 0);	-- Output signals of the input links (internal AND external links)
		outputLinksIn	: in outputLinkInArray(numPorts-1 downto 0);	-- Input signals of the output links (internal AND external links)
		outputLinksOut	: out outputLinkOutArray(numPorts-1 downto 0)	-- Output signals of the output links (internal AND external)
	);
end entity switch;

architecture structural of switch is

	constant defaultInputLinkInValue 	: inputLinkIn := (empty => '1',
														  data => (others => '-'));
	constant defaultOutputLinkInValue 	: outputLinkIn := (full => '1');
	
	signal inputLinksOutMuxOutput		: inputLinkOutArray(numPorts-1 downto 0);
	signal outputLinksOutMuxOutput		: outputLinkOutArray(numPorts-1 downto 0);
	
	signal router_routingRequest		: headerArray(numPorts-1 downto 0);
	signal router_endOfRxPacket			: std_logic_vector(numPorts-1 downto 0);
	signal router_endOfTxPacket			: std_logic_vector(numPorts-1 downto 0);
	signal router_rxPortMap				: portNrWrapperArray(numPorts-1 downto 0);
	signal router_txPortMap				: portNrWrapperArray(numPorts-1 downto 0);
	
	signal invertedOutputLinksInFull	: std_logic_vector(numPorts-1 downto 0);
	signal invertedInputLinksInEmpty	: std_logic_vector(numPorts-1 downto 0);
	
begin

	headerDetectorGenerate: for i in numPorts-1 downto 0 generate
		
		headerDetectorEntity : entity noc_switch_v1_00_a.headerDetector
			port map(
				clk 		=> clk,
				reset 		=> reset,
				readEnable	=> inputLinksOutMuxOutput(i).readEnable,
				empty		=> inputLinksIn(i).empty,
				endOfPacket	=> inputLinksIn(i).data(dataWidth),
				headerValid	=> router_routingRequest(i).valid
			);
		
	end generate headerDetectorGenerate;
	
	headerDecoderGenerate: for i in numPorts-1 downto 0 generate
		
		headerDecoderEntity : entity noc_switch_v1_00_a.headerDecoder
			port map(
				data		=> inputLinksIn(i).data(dataWidth-1 downto 0),
				destAddr	=> router_routingRequest(i).addr,
				prio		=> router_routingRequest(i).prio
			);
		
	end generate headerDecoderGenerate;
	
	endOfPacketDetectorGenerate: for i in numPorts-1 downto 0 generate
		
		invertedInputLinksInEmpty(i) <= not inputLinksIn(i).empty;
		
		rxEndOfPacketDetectorEntity: entity noc_switch_v1_00_a.endOfPacketDetector
			port map(
				dataValid	=> invertedInputLinksInEmpty(i),
				flag		=> inputLinksIn(i).data(dataWidth),
				fifoEnable	=> inputLinksOutMuxOutput(i).readEnable,
				endOfPacket => router_endOfRxPacket(i)
			);
			
		invertedOutputLinksInFull(i) <= not outputLinksIn(i).full;
			
		txEndOfPacketDetectorEntity: entity noc_switch_v1_00_a.endOfPacketDetector
			port map(
				dataValid	=> invertedOutputLinksInFull(i),
				flag		=> outputLinksOutMuxOutput(i).data(dataWidth),
				fifoEnable	=> outputLinksOutMuxOutput(i).writeEnable,
				endOfPacket => router_endOfTxPacket(i)
			);
		
	end generate endOfPacketDetectorGenerate;
	
	routerEntity: entity noc_switch_v1_00_a.router
		generic map (
			globalAddress	=> globalAddress
		)
		port map (
			clk 			=> clk,
			reset			=> reset,
			routingRequest	=> router_routingRequest,
			endOfRxPacket	=> router_endOfRxPacket,
			endOfTxPacket	=> router_endOfTxPacket,
			txPortMap		=> router_txPortMap,
			rxPortMap		=> router_rxPortMap
		);

	nomem_inputMux: process(router_rxPortMap, outputLinksIn) is
		variable muxOutput : outputLinkIn;
	begin
		for i in numPorts-1 downto 0 loop
			muxOutput := defaultOutputLinkInValue;
			if wrappedPortNrEqual(router_rxPortMap(i),portNrUndefined) = false then
				muxOutput := outputLinksIn(wrappedPortNrToInteger(router_rxPortMap(i)));
			end if;
			inputLinksOutMuxOutput(i).readEnable <= not muxOutput.full;
		end loop;
	end process nomem_inputMux;
	
	nomem_outputMux: process(inputLinksIn, router_txPortMap) is
		variable muxOutput : inputLinkIn;
	begin
		for i in numPorts-1 downto 0 loop
			muxOutput := defaultInputLinkInValue;
			if wrappedPortNrEqual(router_txPortMap(i),portNrUndefined) = false then
				muxOutput := inputLinksIn(wrappedPortNrToInteger(router_txPortMap(i)));
			end if;
			outputLinksOutMuxOutput(i).data <= muxOutput.data;
			outputLinksOutMuxOutput(i).writeEnable <= not muxOutput.empty;
		end loop;
	end process nomem_outputMux;
	
	inputLinksOut <= inputLinksOutMuxOutput;
	outputLinksOut <= outputLinksOutMuxOutput;

end architecture structural;
