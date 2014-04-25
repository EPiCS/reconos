library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library noc_switch_v1_00_b;
use noc_switch_v1_00_b.switchPkg.all;
use noc_switch_v1_00_b.headerPkg.all;


entity noc_switch is
	generic (
		C_ENABLE_ILA : integer := 0;
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
	
	component icon
	port (
		control0 : inout std_logic_vector(35 downto 0)
	);
	end component;

	component ila
	port (
		control : inout std_logic_vector(35 downto 0);
		clk : in std_logic;
		trig0 : in std_logic_vector(63 downto 0);
		trig1 : in std_logic_vector(63 downto 0);
		trig2 : in std_logic_vector(63 downto 0)
	);
	end component;
	
	signal control : std_logic_vector(35 downto 0);
	signal data    : std_logic_vector(524 downto 0);
	signal trig0   : std_logic_vector(63 downto 0);
	signal trig1   : std_logic_vector(63 downto 0);
	signal trig2   : std_logic_vector(63 downto 0);
	
	signal downstream0Data_tmp : std_logic_vector(dataWidth downto 0);
	signal downstream1Data_tmp : std_logic_vector(dataWidth downto 0);
	signal ringInputReadEnable_tmp : std_logic_vector(numExtPorts-1 downto 0);
	signal ringOutputData_tmp      : std_logic_vector((numExtPorts*(dataWidth+1))-1 downto 0);
	signal ringOutputEmpty_tmp     : std_logic_vector(numExtPorts-1 downto 0);
	
	
begin

	--------------------- CHIPSCOPE -------------------------
	
	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

	icon_i : icon
	port map (
		control0 => control
	);
	
	ila_i : ila
	port map (
		control => control,
		clk   => clk125,
		trig0 => trig0,
		trig1 => trig1,
		trig2 => trig2
	);

	end generate;
	
	
	trig0(63) <=  downstream0ReadEnable;
	trig0(62) <=  not downstream0Empty;
	trig0(61 downto 53) <=  downstream0Data_tmp;
	trig0(52) <=  downstream0ReadClock;
	
	trig0(51) <=  downstream1ReadEnable;
	trig0(50) <=  not downstream1Empty;
	trig0(49 downto 41) <=  downstream1Data_tmp;
	trig0(40) <=  downstream1ReadClock;
	
	trig0(39) <=  upstream0WriteEnable;
	trig0(38) <=  not upstream0Full;
	trig0(37 downto 29) <=  upstream0Data;
	trig0(28) <=  upstream0WriteClock;
	
	trig0(27) <=  upstream1WriteEnable;
	trig0(26) <=  not upstream1Full;
	trig0(25 downto 17) <=  upstream1Data;
	trig0(16) <=  upstream1WriteClock;
	
	trig0(15 downto 5) <= (others=>'0');
	trig0(4) <= downstream0Empty;
	trig0(3) <= downstream1Empty;
	trig0(2) <= upstream0Full;
	trig0(1) <= upstream1Full;
	trig0(0) <= reset;
	
	trig1(63 downto 60) <= ringInputReadEnable_tmp;
	trig1(59 downto 24) <= ringInputData;
	trig1(23 downto 20) <= ringInputEmpty;
	trig1(19 downto  0) <= (others=>'0');
   --trig1( 1 downto  0) <= upstreamInputLinksIn;
	--trig1(11 downto 6)  <= swInputLinksIn;
	--trig1( 5 downto 0)  <= swInputLinksOut;
	
	trig2(63 downto 60) <= ringOutputReadEnable;
	trig2(59 downto 24) <= ringOutputData_tmp;
	trig2(23 downto 20) <= ringOutputEmpty_tmp;
	trig2(19 downto  0) <= (others=>'0');
	--trig2(11 downto 6)  <= swOutputLinksIn;
	--trig2( 5 downto 0)  <= swOutputLinksOut;

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
	ringInputReadEnable <= ringInputReadEnable_tmp;
	
	unbufferedInputFromRing : process(ringInputData, ringInputEmpty, swInputLinksOut, upstreamInputLinksIn)
	begin
		swInputLinksIn(numIntPorts-1 downto 0) <= upstreamInputLinksIn;
		for i in 0 to numExtPorts-1 loop
			swInputLinksIn(i+numIntPorts).data <= ringInputData(((dataWidth+1)*(i+1))-1 downto (dataWidth+1)*i);
			swInputLinksIn(i+numIntPorts).empty <= ringInputEmpty(i);
			ringInputReadEnable_tmp(i) <= swInputLinksOut(i+numIntPorts).readEnable;
		end loop;
	end process;
		
	-----------------------------------------------------------------
	-- std_logicPUT BUFFER TO FUNCTIONAL BLOCK
	-----------------------------------------------------------------
	downstream0Data <= downstream0Data_tmp;
	
	fifo_downstream0 : interSwitchFifo --fbSwitchFifo
		port map (
			rst => reset,
		--	rd_clk => downstream0ReadClock,
		--	wr_clk => clk125,
			clk => clk125,
			din => swOutputLinksOut(0).data,
			wr_en => swOutputLinksOut(0).writeEnable,
			rd_en => downstream0ReadEnable,
			dout => downstream0Data_tmp,
			full => swOutputLinksIn(0).full,
			empty => downstream0Empty
		);
	
	downstream1Data <= downstream1Data_tmp;
	
	fifo_downstream1 : interSwitchFifo--fbSwitchFifo
		port map (
			rst => reset,
			--rd_clk => downstream1ReadClock,
			--wr_clk => clk125,
			clk => clk125,
			din => swOutputLinksOut(1).data,
			wr_en => swOutputLinksOut(1).writeEnable,
			rd_en => downstream1ReadEnable,
			dout => downstream1Data_tmp,
			full => swOutputLinksIn(1).full,
			empty => downstream1Empty
		);
		
	-----------------------------------------------------------------
	-- OUTPUT BUFFER TO RING
	-----------------------------------------------------------------
	
	ringOutputData <= ringOutputData_tmp;
	ringOutputEmpty <= ringOutputEmpty_tmp;
	
	outputBufferToRing : for i in 0 to numExtPorts-1 generate
		fifo_ring : interSwitchFifo
			port map (
				rst => reset,
				clk => clk125,
				din => swOutputLinksOut(i+numIntPorts).data,
				wr_en => swOutputLinksOut(i+numIntPorts).writeEnable,
				rd_en => ringOutputReadEnable(i),
				dout => ringOutputData_tmp(((dataWidth+1)*(i+1))-1 downto (dataWidth+1)*i),
				full => swOutputLinksIn(i+numIntPorts).full,
				empty => ringOutputEmpty_tmp(i)
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
