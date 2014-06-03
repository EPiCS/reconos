-------------------------------------------------------------------------------
-- Title      : Block-level Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
-- Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : v6_emac_v1_4_block.vhd
-- Version    : 1.4
-------------------------------------------------------------------------------
--
-- (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Description:  This is the block-level wrapper for the Virtex-6 Embedded
--               Tri-Mode Ethernet MAC. It is intended that this example design
--               can be quickly adapted and downloaded onto an FPGA to provide
--               a hardware test environment.
--
--               The block-level wrapper:
--
--               * instantiates appropriate PHY interface modules (GMII, MII,
--                 RGMII, SGMII or 1000BASE-X) as required per the user
--                 configuration;
--
--               * instantiates some clocking and reset resources to operate
--                 the EMAC and its example design.
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Entity declaration for the block-level wrapper
-------------------------------------------------------------------------------

entity v6_emac_v1_4_block is
   port(

      -- 125MHz clock output from transceiver
      CLK125_OUT               : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                   : in  std_logic;

      -- Client receiver interface
      EMACCLIENTRXD            : out std_logic_vector(7 downto 0);
      EMACCLIENTRXDVLD         : out std_logic;
      EMACCLIENTRXGOODFRAME    : out std_logic;
      EMACCLIENTRXBADFRAME     : out std_logic;
      EMACCLIENTRXFRAMEDROP    : out std_logic;
      EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      EMACCLIENTRXSTATSVLD     : out std_logic;
      EMACCLIENTRXSTATSBYTEVLD : out std_logic;

      -- Client transmitter interface
      CLIENTEMACTXD            : in  std_logic_vector(7 downto 0);
      CLIENTEMACTXDVLD         : in  std_logic;
      EMACCLIENTTXACK          : out std_logic;
      CLIENTEMACTXFIRSTBYTE    : in  std_logic;
      CLIENTEMACTXUNDERRUN     : in  std_logic;
      EMACCLIENTTXCOLLISION    : out std_logic;
      EMACCLIENTTXRETRANSMIT   : out std_logic;
      CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
      EMACCLIENTTXSTATS        : out std_logic;
      EMACCLIENTTXSTATSVLD     : out std_logic;
      EMACCLIENTTXSTATSBYTEVLD : out std_logic;

      -- MAC control interface
      CLIENTEMACPAUSEREQ       : in  std_logic;
      CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

      -- EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  : out std_logic;

      -- Auto-Negotiation interrupt
      EMACANINTERRUPT          : out std_logic;

      -- SGMII interface
      TXP                      : out std_logic;
      TXN                      : out std_logic;
      RXP                      : in  std_logic;
      RXN                      : in  std_logic;
      PHYAD                    : in  std_logic_vector(4 downto 0);
      RESETDONE                : out std_logic;

      -- SGMII transceiver clock buffer input
      CLK_DS                   : in  std_logic;

      -- Asynchronous reset
      RESET                    : in  std_logic

   );
end v6_emac_v1_4_block;


architecture TOP_LEVEL of v6_emac_v1_4_block is

-------------------------------------------------------------------------------
-- Component declarations for lower hierarchial level entities
-------------------------------------------------------------------------------

  -- Component declaration for the primitive-level EMAC wrapper
  component v6_emac_v1_4 is
    port(

      -- Client receiver interface
      EMACCLIENTRXCLIENTCLKOUT    : out std_logic;
      CLIENTEMACRXCLIENTCLKIN     : in  std_logic;
      EMACCLIENTRXD               : out std_logic_vector(7 downto 0);
      EMACCLIENTRXDVLD            : out std_logic;
      EMACCLIENTRXDVLDMSW         : out std_logic;
      EMACCLIENTRXGOODFRAME       : out std_logic;
      EMACCLIENTRXBADFRAME        : out std_logic;
      EMACCLIENTRXFRAMEDROP       : out std_logic;
      EMACCLIENTRXSTATS           : out std_logic_vector(6 downto 0);
      EMACCLIENTRXSTATSVLD        : out std_logic;
      EMACCLIENTRXSTATSBYTEVLD    : out std_logic;

      -- Client transmitter interface
      EMACCLIENTTXCLIENTCLKOUT    : out std_logic;
      CLIENTEMACTXCLIENTCLKIN     : in  std_logic;
      CLIENTEMACTXD               : in  std_logic_vector(7 downto 0);
      CLIENTEMACTXDVLD            : in  std_logic;
      CLIENTEMACTXDVLDMSW         : in  std_logic;
      EMACCLIENTTXACK             : out std_logic;
      CLIENTEMACTXFIRSTBYTE       : in  std_logic;
      CLIENTEMACTXUNDERRUN        : in  std_logic;
      EMACCLIENTTXCOLLISION       : out std_logic;
      EMACCLIENTTXRETRANSMIT      : out std_logic;
      CLIENTEMACTXIFGDELAY        : in  std_logic_vector(7 downto 0);
      EMACCLIENTTXSTATS           : out std_logic;
      EMACCLIENTTXSTATSVLD        : out std_logic;
      EMACCLIENTTXSTATSBYTEVLD    : out std_logic;

      -- MAC control interface
      CLIENTEMACPAUSEREQ          : in  std_logic;
      CLIENTEMACPAUSEVAL          : in  std_logic_vector(15 downto 0);

      -- Clock signals
      GTX_CLK                     : in  std_logic;
      PHYEMACTXGMIIMIICLKIN       : in  std_logic;
      EMACPHYTXGMIIMIICLKOUT      : out std_logic;

      -- SGMII interface
      RXDATA                      : in  std_logic_vector(7 downto 0);
      TXDATA                      : out std_logic_vector(7 downto 0);
      MMCM_LOCKED                 : in  std_logic;
      AN_INTERRUPT                : out std_logic;
      SIGNAL_DETECT               : in  std_logic;
      PHYAD                       : in  std_logic_vector(4 downto 0);
      ENCOMMAALIGN                : out std_logic;
      LOOPBACKMSB                 : out std_logic;
      MGTRXRESET                  : out std_logic;
      MGTTXRESET                  : out std_logic;
      POWERDOWN                   : out std_logic;
      SYNCACQSTATUS               : out std_logic;
      RXCLKCORCNT                 : in  std_logic_vector(2 downto 0);
      RXBUFSTATUS                 : in  std_logic;
      RXCHARISCOMMA               : in  std_logic;
      RXCHARISK                   : in  std_logic;
      RXDISPERR                   : in  std_logic;
      RXNOTINTABLE                : in  std_logic;
      RXREALIGN                   : in  std_logic;
      RXRUNDISP                   : in  std_logic;
      TXBUFERR                    : in  std_logic;
      TXCHARDISPMODE              : out std_logic;
      TXCHARDISPVAL               : out std_logic;
      TXCHARISK                   : out std_logic;

      -- Asynchronous reset
      RESET                       : in  std_logic

    );
  end component;

  -- Component declaration for the GTX wrapper
  component v6_gtxwizard_top
    port (
      RESETDONE      : out   std_logic;
      ENMCOMMAALIGN  : in    std_logic;
      ENPCOMMAALIGN  : in    std_logic;
      LOOPBACK       : in    std_logic;
      POWERDOWN      : in    std_logic;
      RXUSRCLK2      : in    std_logic;
      RXRESET        : in    std_logic;
      TXCHARDISPMODE : in    std_logic;
      TXCHARDISPVAL  : in    std_logic;
      TXCHARISK      : in    std_logic;
      TXDATA         : in    std_logic_vector (7 downto 0);
      TXUSRCLK2      : in    std_logic;
      TXRESET        : in    std_logic;
      RXCHARISCOMMA  : out   std_logic;
      RXCHARISK      : out   std_logic;
      RXCLKCORCNT    : out   std_logic_vector (2 downto 0);
      RXDATA         : out   std_logic_vector (7 downto 0);
      RXDISPERR      : out   std_logic;
      RXNOTINTABLE   : out   std_logic;
      RXRUNDISP      : out   std_logic;
      RXBUFERR       : out   std_logic;
      TXBUFERR       : out   std_logic;
      PLLLKDET       : out   std_logic;
      TXOUTCLK       : out   std_logic;
      RXELECIDLE     : out   std_logic;
      TXN            : out   std_logic;
      TXP            : out   std_logic;
      RXN            : in    std_logic;
      RXP            : in    std_logic;
      CLK_DS         : in    std_logic;
      PMARESET       : in    std_logic
    );
  end component;


-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------

    -- Power and ground signals
    signal gnd_i                      : std_logic;
    signal vcc_i                      : std_logic;

    -- Asynchronous reset signals
    signal reset_ibuf_i               : std_logic;
    signal reset_i                    : std_logic;
    signal reset_r                    : std_logic_vector(3 downto 0);

    -- Client clocking signals
    signal rx_client_clk_out_i        : std_logic;
    signal rx_client_clk_in_i         : std_logic;
    signal tx_client_clk_out_i        : std_logic;
    signal tx_client_clk_in_i         : std_logic;

    -- Physical interface signals
    signal emac_locked_i              : std_logic;
    signal mgt_rx_data_i              : std_logic_vector(7 downto 0);
    signal mgt_tx_data_i              : std_logic_vector(7 downto 0);
    signal signal_detect_i            : std_logic;
    signal elecidle_i                 : std_logic;
    signal resetdone_i                : std_logic;
    signal encommaalign_i             : std_logic;
    signal loopback_i                 : std_logic;
    signal mgt_rx_reset_i             : std_logic;
    signal mgt_tx_reset_i             : std_logic;
    signal powerdown_i                : std_logic;
    signal rxclkcorcnt_i              : std_logic_vector(2 downto 0);
    signal rxchariscomma_i            : std_logic;
    signal rxcharisk_i                : std_logic;
    signal rxdisperr_i                : std_logic;
    signal rxnotintable_i             : std_logic;
    signal rxrundisp_i                : std_logic;
    signal txbuferr_i                 : std_logic;
    signal txchardispmode_i           : std_logic;
    signal txchardispval_i            : std_logic;
    signal txcharisk_i                : std_logic;
    signal gtx_clk_ibufg_i            : std_logic;
    signal rxbufstatus_i              : std_logic;
    signal rxchariscomma_r            : std_logic;
    signal rxcharisk_r                : std_logic;
    signal rxclkcorcnt_r              : std_logic_vector(2 downto 0);
    signal mgt_rx_data_r              : std_logic_vector(7 downto 0);
    signal rxdisperr_r                : std_logic;
    signal rxnotintable_r             : std_logic;
    signal rxrundisp_r                : std_logic;
    signal txchardispmode_r           : std_logic;
    signal txchardispval_r            : std_logic;
    signal txcharisk_r                : std_logic;
    signal mgt_tx_data_r              : std_logic_vector(7 downto 0);

    -- Transceiver clocking signals
    signal usrclk2                    : std_logic;
    signal txoutclk                   : std_logic;
    signal plllock_i                  : std_logic;

-------------------------------------------------------------------------------
-- Attribute declarations
-------------------------------------------------------------------------------

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reset_r : signal is "TRUE";

-------------------------------------------------------------------------------
-- Main body of code
-------------------------------------------------------------------------------

begin

    gnd_i <= '0';
    vcc_i <= '1';

    ---------------------------------------------------------------------------
    -- Main reset circuitry
    ---------------------------------------------------------------------------

    reset_ibuf_i <= RESET;

    -- Synchronize and extend the external reset signal
    process(usrclk2, reset_ibuf_i)
    begin
        if (reset_ibuf_i = '1') then
            reset_r <= "1111";
        elsif usrclk2'event and usrclk2 = '1' then
          if (plllock_i = '1') then
            reset_r <= reset_r(2 downto 0) & reset_ibuf_i;
          end if;
        end if;
    end process;

    -- Apply the extended reset pulse to the EMAC
    reset_i <= reset_r(3);

    ---------------------------------------------------------------------------
    -- Instantiate GTX for SGMII or 1000BASE-X PCS/PMA physical interface
    ---------------------------------------------------------------------------

    v6_gtxwizard_top_inst : v6_gtxwizard_top
      PORT MAP (
         RESETDONE      => resetdone_i,
         ENMCOMMAALIGN  => encommaalign_i,
         ENPCOMMAALIGN  => encommaalign_i,
         LOOPBACK       => loopback_i,
         POWERDOWN      => powerdown_i,
         RXUSRCLK2      => usrclk2,
         RXRESET        => mgt_rx_reset_i,
         TXCHARDISPMODE => txchardispmode_r,
         TXCHARDISPVAL  => txchardispval_r,
         TXCHARISK      => txcharisk_r,
         TXDATA         => mgt_tx_data_r,
         TXUSRCLK2      => usrclk2,
         TXRESET        => mgt_tx_reset_i,
         RXCHARISCOMMA  => rxchariscomma_i,
         RXCHARISK      => rxcharisk_i,
         RXCLKCORCNT    => rxclkcorcnt_i,
         RXDATA         => mgt_rx_data_i,
         RXDISPERR      => rxdisperr_i,
         RXNOTINTABLE   => rxnotintable_i,
         RXRUNDISP      => rxrundisp_i,
         RXBUFERR       => rxbufstatus_i,
         TXBUFERR       => txbuferr_i,
         PLLLKDET       => plllock_i,
         TXOUTCLK       => txoutclk,
         RXELECIDLE     => elecidle_i,
         TXN            => TXN,
         TXP            => TXP,
         RXN            => RXN,
         RXP            => RXP,
         CLK_DS         => CLK_DS,
         PMARESET       => reset_ibuf_i
    );

   RESETDONE <= resetdone_i;

   --------------------------------------------------------------------------
   -- Register the signals between EMAC and transceiver for timing purposes
   --------------------------------------------------------------------------
   regrx : process (usrclk2, reset_i)
   begin
        if reset_i = '1' then
            rxchariscomma_r  <= '0';
            rxcharisk_r      <= '0';
            rxclkcorcnt_r    <= (others => '0');
            mgt_rx_data_r    <= (others => '0');
            rxdisperr_r      <= '0';
            rxnotintable_r   <= '0';
            rxrundisp_r      <= '0';
            txchardispmode_r <= '0';
            txchardispval_r  <= '0';
            txcharisk_r      <= '0';
            mgt_tx_data_r    <= (others => '0');
        elsif usrclk2'event and usrclk2 = '1' then
            rxchariscomma_r  <= rxchariscomma_i;
            rxcharisk_r      <= rxcharisk_i;
            rxclkcorcnt_r    <= rxclkcorcnt_i;
            mgt_rx_data_r    <= mgt_rx_data_i;
            rxdisperr_r      <= rxdisperr_i;
            rxnotintable_r   <= rxnotintable_i;
            rxrundisp_r      <= rxrundisp_i;
            txchardispmode_r <= txchardispmode_i after 1 ns;
            txchardispval_r  <= txchardispval_i after 1 ns;
            txcharisk_r      <= txcharisk_i after 1 ns;
            mgt_tx_data_r    <= mgt_tx_data_i after 1 ns;
        end if;
   end process regrx;

    -- Detect when there has been a disconnect
    signal_detect_i <= not(elecidle_i);

    --------------------------------------------------------------------
    -- GTX clock management
    --------------------------------------------------------------------
    -- 125MHz clock is used for GT user clocks and used
    -- to clock all Ethernet core logic
    usrclk2        <= CLK125;

    -- GTX reference clock
    gtx_clk_ibufg_i <= usrclk2;

    -- PLL locks
    emac_locked_i <= plllock_i;

    -- SGMII client-side transmit clock
    tx_client_clk_in_i <= usrclk2;

    -- SGMII client-side receive clock
    rx_client_clk_in_i <= usrclk2;

    -- 125MHz clock output from transceiver
    CLK125_OUT <= txoutclk;

    --------------------------------------------------------------------------
    -- Instantiate the primitive-level EMAC wrapper (v6_emac_v1_4.vhd)
    --------------------------------------------------------------------------

    v6_emac_v1_4_inst : v6_emac_v1_4
    port map (
        -- Client receiver interface
        EMACCLIENTRXCLIENTCLKOUT    => rx_client_clk_out_i,
        CLIENTEMACRXCLIENTCLKIN     => rx_client_clk_in_i,
        EMACCLIENTRXD               => EMACCLIENTRXD,
        EMACCLIENTRXDVLD            => EMACCLIENTRXDVLD,
        EMACCLIENTRXDVLDMSW         => open,
        EMACCLIENTRXGOODFRAME       => EMACCLIENTRXGOODFRAME,
        EMACCLIENTRXBADFRAME        => EMACCLIENTRXBADFRAME,
        EMACCLIENTRXFRAMEDROP       => EMACCLIENTRXFRAMEDROP,
        EMACCLIENTRXSTATS           => EMACCLIENTRXSTATS,
        EMACCLIENTRXSTATSVLD        => EMACCLIENTRXSTATSVLD,
        EMACCLIENTRXSTATSBYTEVLD    => EMACCLIENTRXSTATSBYTEVLD,

        -- Client transmitter interface
        EMACCLIENTTXCLIENTCLKOUT    => tx_client_clk_out_i,
        CLIENTEMACTXCLIENTCLKIN     => tx_client_clk_in_i,
        CLIENTEMACTXD               => CLIENTEMACTXD,
        CLIENTEMACTXDVLD            => CLIENTEMACTXDVLD,
        CLIENTEMACTXDVLDMSW         => gnd_i,
        EMACCLIENTTXACK             => EMACCLIENTTXACK,
        CLIENTEMACTXFIRSTBYTE       => CLIENTEMACTXFIRSTBYTE,
        CLIENTEMACTXUNDERRUN        => CLIENTEMACTXUNDERRUN,
        EMACCLIENTTXCOLLISION       => EMACCLIENTTXCOLLISION,
        EMACCLIENTTXRETRANSMIT      => EMACCLIENTTXRETRANSMIT,
        CLIENTEMACTXIFGDELAY        => CLIENTEMACTXIFGDELAY,
        EMACCLIENTTXSTATS           => EMACCLIENTTXSTATS,
        EMACCLIENTTXSTATSVLD        => EMACCLIENTTXSTATSVLD,
        EMACCLIENTTXSTATSBYTEVLD    => EMACCLIENTTXSTATSBYTEVLD,

        -- MAC control interface
        CLIENTEMACPAUSEREQ          => CLIENTEMACPAUSEREQ,
        CLIENTEMACPAUSEVAL          => CLIENTEMACPAUSEVAL,

        -- Clock signals
        GTX_CLK                     => usrclk2,
        EMACPHYTXGMIIMIICLKOUT      => open,
        PHYEMACTXGMIIMIICLKIN       => gnd_i,

        -- SGMII interface
        RXDATA                      => mgt_rx_data_r,
        TXDATA                      => mgt_tx_data_i,
        MMCM_LOCKED                 => emac_locked_i,
        AN_INTERRUPT                => EMACANINTERRUPT,
        SIGNAL_DETECT               => signal_detect_i,
        PHYAD                       => PHYAD,
        ENCOMMAALIGN                => encommaalign_i,
        LOOPBACKMSB                 => loopback_i,
        MGTRXRESET                  => mgt_rx_reset_i,
        MGTTXRESET                  => mgt_tx_reset_i,
        POWERDOWN                   => powerdown_i,
        SYNCACQSTATUS               => EMACCLIENTSYNCACQSTATUS,
        RXCLKCORCNT                 => rxclkcorcnt_r,
        RXBUFSTATUS                 => rxbufstatus_i,
        RXCHARISCOMMA               => rxchariscomma_r,
        RXCHARISK                   => rxcharisk_r,
        RXDISPERR                   => rxdisperr_r,
        RXNOTINTABLE                => rxnotintable_r,
        RXREALIGN                   => '0',
        RXRUNDISP                   => rxrundisp_r,
        TXBUFERR                    => txbuferr_i,
        TXCHARDISPMODE              => txchardispmode_i,
        TXCHARDISPVAL               => txchardispval_i,
        TXCHARISK                   => txcharisk_i,

        -- Asynchronous reset
        RESET                       => reset_i
      );


end TOP_LEVEL;
