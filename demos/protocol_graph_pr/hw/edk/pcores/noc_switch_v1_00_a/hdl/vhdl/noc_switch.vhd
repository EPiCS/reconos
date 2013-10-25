library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library noc_switch_v1_00_a;
use noc_switch_v1_00_a.switchPkg.all;
use noc_switch_v1_00_a.headerPkg.all;


entity noc_switch is
	generic (
		globalAddr : std_logic_vector(3 downto 0) := B"0000"
	);
  	port (
  		clk125					: in  std_logic;
		reset					: in  std_logic;

		downstream0ReadEnable	: in  std_logic;
		o_downstream0_rdy	  	: out std_logic;
		downstream0Data			: out std_logic_vector(dataWidth downto 0);
		downstream0ReadClock 	: in  std_logic;

		downstream1ReadEnable	: in  std_logic;
		o_downstream1_rdy  		: out std_logic;
		downstream1Data			: out std_logic_vector(dataWidth downto 0);
		downstream1ReadClock 	: in  std_logic;

		upstream0WriteEnable	: in  std_logic;
		upstream0Data			: in  std_logic_vector(dataWidth downto 0);
		o_upstream0_rdy 		: out std_logic;
		upstream0WriteClock 	: in  std_logic;

		upstream1WriteEnable	: in  std_logic;
		upstream1Data			: in  std_logic_vector(dataWidth downto 0);
		o_upstream1_rdy 		: out std_logic;
		upstream1WriteClock 	: in  std_logic;
		
		ringInputEmpty			: in std_logic_vector(numExtPorts-1 downto 0);
		ringInputData			: in std_logic_vector((numExtPorts*(dataWidth+1))-1 downto 0);
		ringInputReadEnable		: out std_logic_vector(numExtPorts-1 downto 0);
		ringOutputReadEnable	: in std_logic_vector(numExtPorts-1 downto 0);
		ringOutputData			: out std_logic_vector((numExtPorts*(dataWidth+1))-1 downto 0);
		ringOutputEmpty			: out std_logic_vector(numExtPorts-1 downto 0)
		
  	);
end noc_switch;
	


architecture rtl of noc_switch is

	signal swInputLinksIn	: inputLinkInArray(numPorts-1 downto 0);
	signal swInputLinksOut	: inputLinkOutArray(numPorts-1 downto 0);
	signal swOutputLinksIn	: outputLinkInArray(numPorts-1 downto 0);
	signal swOutputLinksOut	: outputLinkOutArray(numPorts-1 downto 0);
	signal upstreamInputLinksIn	: inputLinkInArray(numIntPorts-1 downto 0);
	
	                   
	component fbSwitchFifo
  		port(
		    rst : in std_logic;
		    wr_clk : in std_logic;
		    rd_clk : in std_logic;
		    din : in std_logic_vector(8 downto 0);
		    wr_en : in std_logic;
		    rd_en : in std_logic;
		    dout : out std_logic_vector(8 downto 0);
		    full : out std_logic;
		    empty : out std_logic
  		);
  	end component;

	component interSwitchFifo
	  port (
	    clk : in std_logic;
	    rst : in std_logic;
	    din : in std_logic_vector(8 downto 0);
	    wr_en : in std_logic;
	    rd_en : in std_logic;
	    dout : out std_logic_vector(8 downto 0);
	    full : out std_logic;
	    empty : out std_logic
	  );
	end component;

	
	component switch is
		generic(
			globalAddress	: std_logic_vector(3 downto 0)	-- The global address of this switch. Packets with this global address are forwarded to the internal output link corresponding to the local address of the packet.
		);
		port (
			clk				: in std_logic;
			reset			: in std_logic;
			inputLinksIn	: in inputLinkInArray(numPorts-1 downto 0);		-- Input signals of the input links (internal AND external links)
			inputLinksOut	: out inputLinkOutArray(numPorts-1 downto 0);	-- Output signals of the input links (internal AND external links)
			outputLinksIn	: in outputLinkInArray(numPorts-1 downto 0);	-- Input signals of the output links (internal AND external links)
			outputLinksOut	: out outputLinkOutArray(numPorts-1 downto 0)	-- Output signals of the output links (internal AND external)
		);
	end component;
	signal downstream0Empty : std_logic;
	signal downstream1Empty : std_logic;
	signal upstream0Full : std_logic;
	signal upstream1Full : std_logic;
	
	
begin
	----------------------------------------------------------------
	-- interface conversion
	----------------------------------------------------------------
	o_downstream0_rdy  <= not downstream0Empty;
	o_downstream1_rdy  <= not downstream1Empty;
	o_upstream0_rdy  <= not upstream0Full;
	o_upstream1_rdy  <= not upstream1Full;
	-----------------------------------------------------------------
	-- INPUT BUFFER FROM FUNCTIONAL BLOCK
	-----------------------------------------------------------------
	
	fifo_upstream0 : interSwitchFifo--fbSwitchFifo
		port map (
			rst => reset,
			--rd_clk => clk125,
			--wr_clk => upstream0WriteClock,
			clk => clk125,
			din => upstream0Data,
			wr_en => upstream0WriteEnable,
			rd_en => swInputLinksOut(0).readEnable,
			dout => upstreamInputLinksIn(0).data,
			full => upstream0Full,
			empty => upstreamInputLinksIn(0).empty
		);
	
	fifo_upstream1 : interSwitchFifo --fbSwitchFifo
		port map (
			rst => reset,
		--	rd_clk => clk125,
		--	wr_clk => upstream0WriteClock,
			clk => clk125,
			din => upstream1Data,
			wr_en => upstream1WriteEnable,
			rd_en => swInputLinksOut(1).readEnable,
			dout => upstreamInputLinksIn(1).data,
			full => upstream1Full,
			empty => upstreamInputLinksIn(1).empty
		);
		
	-----------------------------------------------------------------
	-- UNBUFFERED INPUT FROM RING
	-----------------------------------------------------------------
	
	unbufferedInputFromRing : process(ringInputData, ringInputEmpty, swInputLinksOut, upstreamInputLinksIn)
	begin
		swInputLinksIn(numIntPorts-1 downto 0) <= upstreamInputLinksIn;
		for i in 0 to numExtPorts-1 loop
			swInputLinksIn(i+numIntPorts).data <= ringInputData(((dataWidth+1)*(i+1))-1 downto (dataWidth+1)*i);
			swInputLinksIn(i+numIntPorts).empty <= ringInputEmpty(i);
			ringInputReadEnable(i) <= swInputLinksOut(i+numIntPorts).readEnable;
		end loop;
	end process;
		
	-----------------------------------------------------------------
	-- std_logicPUT BUFFER TO FUNCTIONAL BLOCK
	-----------------------------------------------------------------
		
	fifo_downstream0 : interSwitchFifo --fbSwitchFifo
		port map (
			rst => reset,
		--	rd_clk => downstream0ReadClock,
		--	wr_clk => clk125,
			clk => clk125,
			din => swOutputLinksOut(0).data,
			wr_en => swOutputLinksOut(0).writeEnable,
			rd_en => downstream0ReadEnable,
			dout => downstream0Data,
			full => swOutputLinksIn(0).full,
			empty => downstream0Empty
		);
	
	fifo_downstream1 : interSwitchFifo--fbSwitchFifo
		port map (
			rst => reset,
			--rd_clk => downstream1ReadClock,
			--wr_clk => clk125,
			clk => clk125,
			din => swOutputLinksOut(1).data,
			wr_en => swOutputLinksOut(1).writeEnable,
			rd_en => downstream1ReadEnable,
			dout => downstream1Data,
			full => swOutputLinksIn(1).full,
			empty => downstream1Empty
		);
		
	-----------------------------------------------------------------
	-- OUTPUT BUFFER TO RING
	-----------------------------------------------------------------
	
	outputBufferToRing : for i in 0 to numExtPorts-1 generate
		fifo_ring : interSwitchFifo
			port map (
				rst => reset,
				clk => clk125,
				din => swOutputLinksOut(i+numIntPorts).data,
				wr_en => swOutputLinksOut(i+numIntPorts).writeEnable,
				rd_en => ringOutputReadEnable(i),
				dout => ringOutputData(((dataWidth+1)*(i+1))-1 downto (dataWidth+1)*i),
				full => swOutputLinksIn(i+numIntPorts).full,
				empty => ringOutputEmpty(i)
			);
	end generate;
		
	-----------------------------------------------------------------
	-- THE SWITCH
	-----------------------------------------------------------------	
	
-- Direct connecting for testing purposes
--	swOutputLinksOut(0).data <= swInputLinksIn(1).data;
--	swOutputLinksOut(0).writeEnable <= not swInputLinksIn(1).empty;
--	swInputLinksOut(1).readEnable <= not swOutputLinksIn(0).full;
--	
--	swOutputLinksOut(0).data <= swInputLinksIn(1).data;
--	swOutputLinksOut(0).writeEnable <= not swInputLinksIn(1).empty;
--	swInputLinksOut(1).readEnable <= not swOutputLinksIn(0).full;
--	
--	swOutputLinksOut(2).data <= swInputLinksIn(2).data;
--	swOutputLinksOut(2).writeEnable <= not swInputLinksIn(2).empty;
--	swInputLinksOut(2).readEnable <= not swOutputLinksIn(2).full;
--	
--	swOutputLinksOut(3).data <= swInputLinksIn(3).data;
--	swOutputLinksOut(3).writeEnable <= not swInputLinksIn(3).empty;
--	swInputLinksOut(3).readEnable <= not swOutputLinksIn(3).full;
--	
--	swOutputLinksOut(4).data <= swInputLinksIn(4).data;
--	swOutputLinksOut(4).writeEnable <= not swInputLinksIn(4).empty;
--	swInputLinksOut(4).readEnable <= not swOutputLinksIn(4).full;
--	
--	swOutputLinksOut(5).data <= swInputLinksIn(5).data;
--	swOutputLinksOut(5).writeEnable <= not swInputLinksIn(5).empty;
--	swInputLinksOut(5).readEnable <= not swOutputLinksIn(5).full;
	
	
	sw : switch
		generic map(
			globalAddress => globalAddr
		)
		port map(
			clk				=> clk125,
			reset			=> reset,
			inputLinksIn	=> swInputLinksIn,
			inputLinksOut	=> swInputLinksOut,
			outputLinksIn	=> swOutputLinksIn,
			outputLinksOut	=> swOutputLinksOut
		);
	
end architecture rtl;
