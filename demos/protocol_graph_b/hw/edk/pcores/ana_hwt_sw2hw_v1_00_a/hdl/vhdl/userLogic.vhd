library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

library ana_hwt_sw2hw_v1_00_a;

entity userLogic is
	generic(
		C_LOCAL_RAM_ADDRESS_WIDTH : integer
	);
	port(
		clk				: in  std_logic;
		reset				: in  std_logic;
		
		-- The local memory port
		localRAMReader_addr		: out std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
		localRAMReader_dout		: in  std_logic_vector(31 downto 0);
		
		-- The memory address up to which the data in the local RAM are valid
		localRAMValidPointer		: in  std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
		
		-- The upstream port
		upstreamWriteEnable		: out std_logic;
		upstreamData			: out std_logic_vector(dataWidth downto 0);
		upstreamFull 			: in  std_logic
	);
end userLogic;



architecture structural of userLogic is

	signal localRAMCtrReadEnable		: std_logic;
	signal localRAMCtrDataOut		: std_logic_vector(31 downto 0);
	signal localRAMCtrAddr			: std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	
	signal progressCtrPacketAvailable	: std_logic;

begin

	localRAMReader_addr <= localRAMCtrAddr;

	localRAMCtr: entity ana_hwt_sw2hw_v1_00_a.localRAMCtr
		generic map(
			C_LOCAL_RAM_ADD_WIDTH 	=> C_LOCAL_RAM_ADDRESS_WIDTH,
			C_RING_BUFFER_WORDS	=> sw2hwRamSize/4
		)
		port map(
			clk 		=> clk,
			reset 		=> reset,
			readEnable	=> localRAMCtrReadEnable,
			dout		=> localRAMCtrDataOut,
			ramAddr		=> localRAMCtrAddr,
			ramData		=> localRAMReader_dout
		);
		
	progressCtr: entity ana_hwt_sw2hw_v1_00_a.progressCtr
		generic map(
			C_LOCAL_RAM_ADDR_WIDTH => C_LOCAL_RAM_ADDRESS_WIDTH
		)
		port map(
			localRAMValidPointer	=> localRAMValidPointer,
			readPointer		=> localRAMCtrAddr,
			packetAvailable		=> progressCtrPacketAvailable
		);
		
	packetProcessor: entity ana_hwt_sw2hw_v1_00_a.packetProcessor
		port map(
			clk 			=> clk,
			reset 			=> reset,
			packetAvailable		=> progressCtrPacketAvailable,
			readEnable		=> localRAMCtrReadEnable,
			ramData			=> localRAMCtrDataOut,
			upstreamWriteEnable	=> upstreamWriteEnable,
			upstreamData		=> upstreamData,
			upstreamFull		=> upstreamFull
		);
	
	
end architecture structural;
