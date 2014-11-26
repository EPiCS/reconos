--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - Clock - Top level entity
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  A clock manager which can be configures via the AXI
--                 bus. Therefore it provides the following write only
--                 registers:
--                   Reg0: Clock 1 and 2 register of clock output 0
--                   Reg1: Clock 1 and 2 register of clock output 1
--                   Reg2: Clock 1 and 2 register of clock output 2
--                   Reg3: Clock 1 and 2 register of clock output 3
--                   Reg4: Clock 1 and 2 register of clock output 4
--                   Reg5: Clock 1 and 2 register of clock output 5
--                   Reg6: Reserved
--                   Reg7: Reserved
--
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity user_logic is
	--
	-- Generic definitions
	--
	--   C_NUM_CLOKMGS - number of clock managers
	--
	--   C_PLL#i# - pll generics
	--
	generic (
		C_NUM_CLOCKMGS : integer := 1;

		-- ## BEGIN GENERATE LOOP ##
		C_PLL#i#_CLKIN_PERIOD  : real := 10.00;
		C_PLL#i#_CLKFBOUT_MULT : integer := 16;
		C_PLL#i#_DIVCLK_DIVIDE : integer := 1#c;#
		-- ## END GENERATE LOOP ##
	);

	--
	-- Port defintions
	--
	--   CLK_Ref  - reference clock
	--   CLK_#i#_Out_ - clock outputs
	--
	--   BUS2IP_/IP2BUS_ - axi ipif signals
	--
	port (
		CLK_Ref       : in std_logic;
		-- ## BEGIN GENERATE LOOP ##
		CLK_#i#_Out_0 : out std_logic;
		CLK_#i#_Out_1 : out std_logic;
		CLK_#i#_Out_2 : out std_logic;
		CLK_#i#_Out_3 : out std_logic;
		CLK_#i#_Out_4 : out std_logic;
		CLK_#i#_Out_5 : out std_logic;
		-- ## END GENERATE LOOP ##

		BUS2IP_Clk    : in  std_logic;
		BUS2IP_Resetn : in  std_logic;
		BUS2IP_Data   : in  std_logic_vector(31 downto 0);
		BUS2IP_CS     : in  std_logic_vector(C_NUM_CLOCKMGS - 1 downto 0);
		BUS2IP_RdCE   : in  std_logic_vector(C_NUM_CLOCKMGS * 8 - 1 downto 0);
		BUS2IP_WrCE   : in  std_logic_vector(C_NUM_CLOCKMGS * 8 - 1 downto 0);
		IP2BUS_Data   : out std_logic_vector(31 downto 0);
		IP2BUS_RdAck  : out std_logic;
		IP2BUS_WrAck  : out std_logic;
		IP2BUS_Error  : out std_logic
	);
end entity user_logic;

architecture imp of user_logic is
	--
	-- Internal state machine
	--
	--   state_type - vhdl type of the states
	--   state      - instatntiation of the state
	--
	type state_type is (STATE_WAIT,STATE_RESET,STATE_ACK,
	                    STATE_READ0,STATE_READRDY0,STATE_WRITE0,STATE_WRITERDY0,
	                    STATE_READ1,STATE_READRDY1,STATE_WRITE1,STATE_WRITERDY1);
	signal state : state_type := STATE_WAIT;

	--
	-- Internal signals
	--
	--   req      - indication of write request
	--   pll_     - pll drp multiplexed signals
	--   pll_#i#_ - pll drp signal
	--
	signal req : std_logic;

	signal pll_daddr         : std_logic_vector(7 downto 0);
	signal pll_di, pll_do    : std_logic_vector(15 downto 0);
	signal pll_den, pll_dwe  : std_logic;
	signal pll_drdy, pll_rst : std_logic;

	-- ## BEGIN GENERATE LOOP ##
	signal pll#i#_daddr            : std_logic_vector(7 downto 0);
	signal pll#i#_di, pll#i#_do    : std_logic_vector(15 downto 0);
	signal pll#i#_den, pll#i#_dwe  : std_logic;
	signal pll#i#_drdy, pll#i#_rst : std_logic;
	signal pll#i#_clkfbout         : std_logic;
	signal pll#i#_locked           : std_logic;

	signal pll#i#_clk0, pll#i#_clk1, pll#i#_clk2, pll#i#_clk3, pll#i#_clk4, pll#i#_clk5 : std_logic;
	-- ## END GENERATE LOOP ##
begin

	-- == Instantiation of pll primitives =================================

	-- ## BEGIN GENERATE LOOP ##
	pll#i# : PLLE2_ADV
		generic map (
			CLKIN1_PERIOD => C_PLL#i#_CLKIN_PERIOD,
			CLKFBOUT_MULT => C_PLL#i#_CLKFBOUT_MULT,
			DIVCLK_DIVIDE => C_PLL#i#_DIVCLK_DIVIDE,

			CLKOUT0_DIVIDE => C_PLL#i#_CLKFBOUT_MULT,
			CLKOUT1_DIVIDE => C_PLL#i#_CLKFBOUT_MULT,
			CLKOUT2_DIVIDE => C_PLL#i#_CLKFBOUT_MULT,
			CLKOUT3_DIVIDE => C_PLL#i#_CLKFBOUT_MULT,
			CLKOUT4_DIVIDE => C_PLL#i#_CLKFBOUT_MULT,
			CLKOUT5_DIVIDE => C_PLL#i#_CLKFBOUT_MULT
		)

		port map (
			CLKIN1   => CLK_Ref,
			CLKIN2   => '0',
			CLKINSEL => '1',

			CLKFBOUT => pll#i#_clkfbout,
			CLKFBIN  => pll#i#_clkfbout,

			CLKOUT0 => pll#i#_clk0,
			CLKOUT1 => pll#i#_clk1,
			CLKOUT2 => pll#i#_clk2,
			CLKOUT3 => pll#i#_clk3,
			CLKOUT4 => pll#i#_clk4,
			CLKOUT5 => pll#i#_clk5,

			DCLK   => BUS2IP_Clk,
			DADDR  => pll#i#_daddr(6 downto 0),
			DO     => pll#i#_do,
			DI     => pll#i#_di,
			DEN    => pll#i#_den,
			DWE    => pll#i#_dwe,
			DRDY   => pll#i#_drdy,
			PWRDWN => '0',
			LOCKED => pll#i#_locked,
			RST    => pll#i#_rst
		);

	bufg_pll#i#_0 : BUFG
		port map (
		I => pll#i#_clk0,
		O => CLK_#i#_Out_0
	);

	bufg_pll#i#_1 : BUFG
		port map (
		I => pll#i#_clk1,
		O => CLK_#i#_Out_1
	);

	bufg_pll#i#_2 : BUFG
		port map (
		I => pll#i#_clk2,
		O => CLK_#i#_Out_2
	);

	bufg_pll#i#_3 : BUFG
		port map (
		I => pll#i#_clk3,
		O => CLK_#i#_Out_3
	);

	bufg_pll#i#_4 : BUFG
		port map (
		I => pll#i#_clk4,
		O => CLK_#i#_Out_4
	);

	bufg_pll#i#_5 : BUFG
		port map (
		I => pll#i#_clk5,
		O => CLK_#i#_Out_5
	);
	-- ## END GENERATE LOOP ##


	-- == Process definitions =============================================

	--
	-- Implements the access logic via the drp port
	--
	clk_mg : process(BUS2IP_Clk,BUS2IP_Resetn) is
	begin
		if BUS2IP_Resetn = '0' then
			state <= STATE_WAIT;
		elsif rising_edge(BUS2IP_Clk) then
			case state is
				when STATE_WAIT =>
					if req = '1' then
						state <= STATE_RESET;
					end if;

				when STATE_RESET =>
					state <= STATE_READ0;

				when STATE_READ0 =>
					state <= STATE_READRDY0;

				when STATE_READRDY0 =>
					if pll_drdy = '1' then
						state <= STATE_WRITE0;
					end if;

				when STATE_WRITE0 =>
					state <= STATE_WRITERDY0;

				when STATE_WRITERDY0 =>
					if pll_drdy = '1' then
						state <= STATE_READ1;
					end if;

				when STATE_READ1 =>
					state <= STATE_READRDY1;

				when STATE_READRDY1 =>
					if pll_drdy = '1' then
						state <= STATE_WRITE1;
					end if;

				when STATE_WRITE1 =>
					state <= STATE_WRITERDY1;

				when STATE_WRITERDY1 =>
					if pll_drdy = '1' then
						state <= STATE_ACK;
					end if;

				when STATE_ACK =>
					state <= STATE_WAIT;

				when others =>
			end case;
		end if;
	end process clk_mg;


	req <=
	  -- ## BEGIN GENERATE LOOP ##
	  BUS2IP_CS(#i#) or
	  -- ## END GENERATE LOOP ##
	  '0';

	pll_daddr <= 
	  -- ## BEGIN GENERATE LOOP ##
	  x"08" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 1) = '1' else
	  x"08" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 1) = '1' else
	  x"09" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 1) = '1' else
	  x"09" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 1) = '1' else
	  x"0a" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 2) = '1' else
	  x"0a" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 2) = '1' else
	  x"0b" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 2) = '1' else
	  x"0b" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 2) = '1' else
	  x"0c" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 3) = '1' else
	  x"0c" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 3) = '1' else
	  x"0d" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 3) = '1' else
	  x"0d" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 3) = '1' else
	  x"0e" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 4) = '1' else
	  x"0e" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 4) = '1' else
	  x"0f" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 4) = '1' else
	  x"0f" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 4) = '1' else
	  x"10" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 5) = '1' else
	  x"10" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 5) = '1' else
	  x"11" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 5) = '1' else
	  x"11" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 5) = '1' else
	  x"06" when state = STATE_READ0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 6) = '1' else
	  x"06" when state = STATE_WRITE0 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 6) = '1' else
	  x"07" when state = STATE_READ1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 6) = '1' else
	  x"07" when state = STATE_WRITE1 and BUS2IP_WrCE((C_NUM_CLOCKMGS - #i#) * 8 - 6) = '1' else
	  -- ## END GENERATE LOOP ##
	  x"00";

	pll_den <=
	  '1' when state = STATE_READ0 else
	  '1' when state = STATE_WRITE0 else
	  '1' when state = STATE_READ1 else
	  '1' when state = STATE_WRITE1 else
	  '0';

	pll_dwe <=
	  '1' when state = STATE_WRITE0 else
	  '1' when state = STATE_WRITE1 else
	  '0';

	pll_rst <=
	  '0' when state = STATE_WAIT else
	  '1';

	pll_di <=
	  BUS2IP_Data(15 downto 13) & pll_do(12) & BUS2IP_Data(11 downto 0) when state = STATE_WRITE0 else
	  BUS2IP_Data(15 downto 13) & pll_do(12) & BUS2IP_Data(11 downto 0) when state = STATE_WRITERDY0 else
	  pll_do(15 downto 8) & BUS2IP_Data(23 downto 16) when state = STATE_WRITE1 else
	  pll_do(15 downto 8) & BUS2IP_Data(23 downto 16) when state = STATE_WRITERDY1 else
	  (others => '0');


	-- ## BEGIN GENERATE LOOP ##
	pll#i#_rst <= pll_rst when BUS2IP_CS(C_NUM_CLOCKMGS - #i# - 1) = '1' else '0';
	-- ## END GENERATE LOOP ##

	-- ## BEGIN GENERATE LOOP ##
	pll#i#_daddr <= pll_daddr;
	-- ## END GENERATE LOOP ##

	-- ## BEGIN GENERATE LOOP ##
	pll#i#_den <= pll_den when BUS2IP_CS(C_NUM_CLOCKMGS - #i# - 1) = '1' else '0';
	-- ## END GENERATE LOOP ##

	-- ## BEGIN GENERATE LOOP ##
	pll#i#_dwe <= pll_dwe when BUS2IP_CS(C_NUM_CLOCKMGS - #i# - 1) = '1' else '0';
	-- ## END GENERATE LOOP ##

	-- ## BEGIN GENERATE LOOP ##
	pll#i#_di <= pll_di;
	-- ## END GENERATE LOOP ##

	pll_drdy <=
	  -- ## BEGIN GENERATE LOOP ##
	  (pll#i#_drdy and BUS2IP_CS(C_NUM_CLOCKMGS - #i# - 1)) or
	  -- ## END GENERATE LOOP ##
	  '0';

	pll_do <=
	  -- ## BEGIN GENERATE LOOP ##
	  (pll#i#_do and (pll#i#_do'Range => BUS2IP_CS(C_NUM_CLOCKMGS - #i# - 1))) or
	  -- ## END GENERATE LOOP ##
	  (15 downto 0 => '0');


	-- == Assignment of ouput ports =======================================

	IP2BUS_Data <= (others => '0');

	IP2BUS_RdAck <= '0';
	IP2BUS_WrAck <= '1' when state = STATE_ACK else '0';

	IP2BUS_Error <= '0';

end architecture imp;