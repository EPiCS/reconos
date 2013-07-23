library ieee;
use ieee.std_logic_1164.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.headerPkg.all;
use noc_switch_v1_00_a.switchPkg.all;

entity router is
	generic(
		globalAddress	: globalAddr
	);
	port (
		clk 			: in std_logic;
		reset 			: in std_logic;
		
		routingRequest	: in headerArray(numPorts-1 downto 0);
		endOfRxPacket	: in std_logic_vector(numPorts-1 downto 0);
		endOfTxPacket	: in std_logic_vector(numPorts-1 downto 0);
		
		txPortMap		: out portNrWrapperArray(numPorts-1 downto 0);
		rxPortMap		: out portNrWrapperArray(numPorts-1 downto 0)
	);
end entity router;

architecture structural of router is

	signal headerFetch_headerOut			: headerArray(numPorts-1 downto 0);
	signal headerFetch_selected				: std_logic_vector(numPorts-1 downto 0);
	
	signal headerSelect_dataValid			: std_logic;
	signal headerSelect_selectedRxPort		: portNr;
	signal headerSelect_selectedAddr		: address;
	
	signal txFifoSelect_txFifoWriteEnable	: std_logic_vector(numIntPorts downto 0);
	
	signal txFifo_ReadEnable				: std_logic_vector(numIntPorts downto 0);
	signal txFifo_empty						: std_logic_vector(numIntPorts downto 0);
	signal txFifo_rxPortNr					: portNrArray(numIntPorts downto 0);
	
	signal intTxPortSelect_idle				: std_logic_vector(numIntPorts-1 downto 0);
	signal intTxPortSelect_txPortWriteEnable: std_logic_vector(numIntPorts-1 downto 0);

	signal txPortSelect_rxPortNr			: portNrArray(numIntPorts downto 0);
	signal txPortSelect_txPortNr			: portNrArray(numIntPorts downto 0);
	type txPortSelect_rxPortWriteEnable_type is array(numIntPorts downto 0) of std_logic_vector(numPorts-1 downto 0); 
	signal txPortSelect_rxPortWriteEnable	: txPortSelect_rxPortWriteEnable_type;
	
	signal extTxPortSelect_idle				: std_logic_vector(numExtPorts-1 downto 0);
	signal extTxPortSelect_txPortWriteEnable: std_logic_vector(numExtPorts-1 downto 0);
	
	type rxPort_writeEnable_type is array(numPorts-1 downto 0) of std_logic_vector(numIntPorts downto 0);
	signal rxPort_writeEnable				: rxPort_writeEnable_type;
	
begin

	headerFetchGenerate : for i in numPorts-1 downto 0 generate
		
		headerFetchEntity: entity noc_switch_v1_00_a.headerFetch
			port map (
				clk 			=> clk,
				reset 			=> reset,
				headerIn 		=> routingRequest(i),
				endOfRxPacket 	=> endOfRxPacket(i), 
				selected 		=> headerFetch_selected(i),
				headerOut 		=> headerFetch_headerOut(i)
			);
		
	end generate headerFetchGenerate;
	
	headerSelectEntity: entity noc_switch_v1_00_a.headerSelect
		port map (
			headerIn		=> headerFetch_headerOut,
			selected		=> headerFetch_selected,
			dataValid		=> headerSelect_dataValid,
			selectedRxPort	=> headerSelect_selectedRxPort,
			selectedAddr	=> headerSelect_selectedAddr
		);
		
	txFifoSelectEntity: entity noc_switch_v1_00_a.txFifoSelect
		generic map (
			globalAddress	=> globalAddress
		)
		port map (
			selectedAddr	=> headerSelect_selectedAddr,
			dataValid		=> headerSelect_dataValid,
			fifoWriteEnable	=> txFifoSelect_txFifoWriteEnable
		);
	
	intTxFifoGenerate: for i in numIntPorts-1 downto 0 generate
		
		intTxFifoEntity: entity noc_switch_v1_00_a.txFifo
			port map (
				clk 		=> clk,
				reset 		=> reset,
				writeEnable	=> txFifoSelect_txFifoWriteEnable(i),
				readEnable	=> txFifo_readEnable(i),
				empty		=> txFifo_empty(i),
				rxPortNrIn	=> headerSelect_selectedRxPort,
				rxPortNrOut	=> txFifo_rxPortNr(i)
			);
		
	end generate intTxFifoGenerate;
	
	extTxFifoEntity: entity noc_switch_v1_00_a.txFifo
		port map (
			clk 		=> clk,
			reset 		=> reset,
			writeEnable	=> txFifoSelect_txFifoWriteEnable(numIntPorts),
			readEnable	=> txFifo_readEnable(numIntPorts),
			empty		=> txFifo_empty(numIntPorts),
			rxPortNrIn	=> headerSelect_selectedRxPort,
			rxPortNrOut	=> txFifo_rxPortNr(numIntPorts)
		);
		
	intTxPortSelectGenerate: for i in numIntPorts-1 downto 0 generate
	
		intTxPortSelectEntity: entity noc_switch_v1_00_a.intTxPortSelect
			generic map (
				txPortNr			=> integerToPortNr(i)
			)
			port map (
				rxPortNrIn 			=> txFifo_rxPortNr(i),
				rxPortNrOut			=> txPortSelect_rxPortNr(i),
				txPortIdle			=> intTxPortSelect_idle(i),
				txPortWriteEnable	=> intTxPortSelect_txPortWriteEnable(i),
				txFifoReadEnable	=> txFifo_ReadEnable(i),
				txFifoEmpty			=> txFifo_empty(i),
				txPortNrOut			=> txPortSelect_txPortNr(i),
				rxPortWriteEnable	=> txPortSelect_rxPortWriteEnable(i)
			);
	
	end generate intTxPortSelectGenerate;
	
	extTxPortSelectEntity: entity noc_switch_v1_00_a.extTxPortSelect
		port map (
			rxPortNrIn 			=> txFifo_rxPortNr(numIntPorts),
			rxPortNrOut			=> txPortSelect_rxPortNr(numIntPorts),
			txPortIdle			=> extTxPortSelect_idle,
			txPortWriteEnable	=> extTxPortSelect_txPortWriteEnable,
			txFifoReadEnable	=> txFifo_ReadEnable(numIntPorts),
			txFifoEmpty			=> txFifo_empty(numIntPorts),
			txPortNrOut			=> txPortSelect_txPortNr(numIntPorts),
			rxPortWriteEnable	=> txPortSelect_rxPortWriteEnable(numIntPorts)
		);
		
	intTxPortGenerate: for i in numIntPorts-1 downto 0 generate
		
		intTxPortEntity: entity noc_switch_v1_00_a.txPort
			port map(
				clk			=> clk,
				reset		=> reset,
				rxPortNrIn	=> txPortSelect_rxPortNr(i),
				rxPortNrOut	=> txPortMap(i),
				idle		=> intTxPortSelect_idle(i),
				writeEnable	=> intTxPortSelect_txPortWriteEnable(i),
				endOfPacket	=> endOfTxPacket(i)
			);
		
	end generate intTxPortGenerate;
	
	extTxPortGenerate: for i in numExtPorts-1 downto 0 generate
		
		extTxPortEntity: entity noc_switch_v1_00_a.txPort
			port map(
				clk			=> clk,
				reset		=> reset,
				rxPortNrIn	=> txPortSelect_rxPortNr(numIntPorts),
				rxPortNrOut	=> txPortMap(numIntPorts + i),
				idle		=> extTxPortSelect_idle(i),
				writeEnable	=> extTxPortSelect_txPortWriteEnable(i),
				endOfPacket	=> endOfTxPacket(numIntPorts + i)
			);
		
	end generate extTxPortGenerate;
	
	rxPortGenerate: for i in numPorts-1 downto 0 generate
	
		rxPortEntity:entity noc_switch_v1_00_a.rxPort
			port map(
				clk	 		=> clk,
				reset 		=> reset,
				txPortNrIn	=> txPortSelect_txPortNr,
				txPortNrOut	=> rxPortMap(i),
				writeEnable	=> rxPort_writeEnable(i),
				endOfPacket => endOfRxPacket(i)
			);
	
	end generate rxPortGenerate;
	
	rxPortWriteEnableMappingGenerate: for i in numPorts-1 downto 0 generate
		j: for j in numIntPorts downto 0 generate
			rxPort_writeEnable(i)(j) <= txPortSelect_rxPortWriteEnable(j)(i); 
		end generate j;
	end generate rxPortWriteEnableMappingGenerate;

end architecture structural;
