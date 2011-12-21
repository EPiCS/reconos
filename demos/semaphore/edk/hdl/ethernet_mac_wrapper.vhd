-------------------------------------------------------------------------------
-- ethernet_mac_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library xps_ethernetlite_v4_00_a;
use xps_ethernetlite_v4_00_a.all;

entity ethernet_mac_wrapper is
  port (
    PHY_tx_clk : in std_logic;
    PHY_rx_clk : in std_logic;
    PHY_crs : in std_logic;
    PHY_dv : in std_logic;
    PHY_rx_data : in std_logic_vector(3 downto 0);
    PHY_col : in std_logic;
    PHY_rx_er : in std_logic;
    PHY_rst_n : out std_logic;
    PHY_tx_en : out std_logic;
    PHY_tx_data : out std_logic_vector(3 downto 0);
    PHY_MDC : out std_logic;
    PHY_MDIO_I : in std_logic;
    PHY_MDIO_O : out std_logic;
    PHY_MDIO_T : out std_logic;
    IP2INTC_Irpt : out std_logic;
    SPLB_Clk : in std_logic;
    SPLB_Rst : in std_logic;
    PLB_ABus : in std_logic_vector(0 to 31);
    PLB_UABus : in std_logic_vector(0 to 31);
    PLB_PAValid : in std_logic;
    PLB_SAValid : in std_logic;
    PLB_rdPrim : in std_logic;
    PLB_wrPrim : in std_logic;
    PLB_masterID : in std_logic_vector(0 to 1);
    PLB_abort : in std_logic;
    PLB_busLock : in std_logic;
    PLB_RNW : in std_logic;
    PLB_BE : in std_logic_vector(0 to 7);
    PLB_MSize : in std_logic_vector(0 to 1);
    PLB_size : in std_logic_vector(0 to 3);
    PLB_type : in std_logic_vector(0 to 2);
    PLB_lockErr : in std_logic;
    PLB_wrDBus : in std_logic_vector(0 to 63);
    PLB_wrBurst : in std_logic;
    PLB_rdBurst : in std_logic;
    PLB_wrPendReq : in std_logic;
    PLB_rdPendReq : in std_logic;
    PLB_wrPendPri : in std_logic_vector(0 to 1);
    PLB_rdPendPri : in std_logic_vector(0 to 1);
    PLB_reqPri : in std_logic_vector(0 to 1);
    PLB_TAttribute : in std_logic_vector(0 to 15);
    Sl_addrAck : out std_logic;
    Sl_SSize : out std_logic_vector(0 to 1);
    Sl_wait : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck : out std_logic;
    Sl_wrComp : out std_logic;
    Sl_wrBTerm : out std_logic;
    Sl_rdDBus : out std_logic_vector(0 to 63);
    Sl_rdWdAddr : out std_logic_vector(0 to 3);
    Sl_rdDAck : out std_logic;
    Sl_rdComp : out std_logic;
    Sl_rdBTerm : out std_logic;
    Sl_MBusy : out std_logic_vector(0 to 2);
    Sl_MWrErr : out std_logic_vector(0 to 2);
    Sl_MRdErr : out std_logic_vector(0 to 2);
    Sl_MIRQ : out std_logic_vector(0 to 2)
  );

  attribute x_core_info : STRING;
  attribute x_core_info of ethernet_mac_wrapper : entity is "xps_ethernetlite_v4_00_a";

end ethernet_mac_wrapper;

architecture STRUCTURE of ethernet_mac_wrapper is

  component xps_ethernetlite is
    generic (
      C_FAMILY : STRING;
      C_BASEADDR : std_logic_vector;
      C_HIGHADDR : std_logic_vector;
      C_SPLB_CLK_PERIOD_PS : INTEGER;
      C_SPLB_AWIDTH : INTEGER;
      C_SPLB_DWIDTH : INTEGER;
      C_SPLB_P2P : INTEGER;
      C_SPLB_MID_WIDTH : INTEGER;
      C_SPLB_NUM_MASTERS : INTEGER;
      C_SPLB_NATIVE_DWIDTH : INTEGER;
      C_SPLB_SMALLEST_MASTER : INTEGER;
      C_SPLB_SUPPORT_BURSTS : INTEGER;
      C_INCLUDE_MDIO : INTEGER;
      C_INCLUDE_GLOBAL_BUFFERS : INTEGER;
      C_INCLUDE_INTERNAL_LOOPBACK : INTEGER;
      C_DUPLEX : INTEGER;
      C_TX_PING_PONG : INTEGER;
      C_RX_PING_PONG : INTEGER
    );
    port (
      PHY_tx_clk : in std_logic;
      PHY_rx_clk : in std_logic;
      PHY_crs : in std_logic;
      PHY_dv : in std_logic;
      PHY_rx_data : in std_logic_vector(3 downto 0);
      PHY_col : in std_logic;
      PHY_rx_er : in std_logic;
      PHY_rst_n : out std_logic;
      PHY_tx_en : out std_logic;
      PHY_tx_data : out std_logic_vector(3 downto 0);
      PHY_MDC : out std_logic;
      PHY_MDIO_I : in std_logic;
      PHY_MDIO_O : out std_logic;
      PHY_MDIO_T : out std_logic;
      IP2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to (C_SPLB_AWIDTH-1));
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to (C_SPLB_MID_WIDTH-1));
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to ((C_SPLB_DWIDTH/8)-1));
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MWrErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MRdErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MIRQ : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1))
    );
  end component;

  attribute BUFFER_TYPE : STRING;
  attribute BUFFER_TYPE of PHY_tx_clk : signal is "IBUF";
  attribute BUFFER_TYPE of PHY_rx_clk : signal is "IBUF";

begin

  Ethernet_MAC : xps_ethernetlite
    generic map (
      C_FAMILY => "virtex6",
      C_BASEADDR => X"81000000",
      C_HIGHADDR => X"8100ffff",
      C_SPLB_CLK_PERIOD_PS => 10000,
      C_SPLB_AWIDTH => 32,
      C_SPLB_DWIDTH => 64,
      C_SPLB_P2P => 0,
      C_SPLB_MID_WIDTH => 2,
      C_SPLB_NUM_MASTERS => 3,
      C_SPLB_NATIVE_DWIDTH => 32,
      C_SPLB_SMALLEST_MASTER => 32,
      C_SPLB_SUPPORT_BURSTS => 1,
      C_INCLUDE_MDIO => 1,
      C_INCLUDE_GLOBAL_BUFFERS => 0,
      C_INCLUDE_INTERNAL_LOOPBACK => 0,
      C_DUPLEX => 1,
      C_TX_PING_PONG => 0,
      C_RX_PING_PONG => 0
    )
    port map (
      PHY_tx_clk => PHY_tx_clk,
      PHY_rx_clk => PHY_rx_clk,
      PHY_crs => PHY_crs,
      PHY_dv => PHY_dv,
      PHY_rx_data => PHY_rx_data,
      PHY_col => PHY_col,
      PHY_rx_er => PHY_rx_er,
      PHY_rst_n => PHY_rst_n,
      PHY_tx_en => PHY_tx_en,
      PHY_tx_data => PHY_tx_data,
      PHY_MDC => PHY_MDC,
      PHY_MDIO_I => PHY_MDIO_I,
      PHY_MDIO_O => PHY_MDIO_O,
      PHY_MDIO_T => PHY_MDIO_T,
      IP2INTC_Irpt => IP2INTC_Irpt,
      SPLB_Clk => SPLB_Clk,
      SPLB_Rst => SPLB_Rst,
      PLB_ABus => PLB_ABus,
      PLB_UABus => PLB_UABus,
      PLB_PAValid => PLB_PAValid,
      PLB_SAValid => PLB_SAValid,
      PLB_rdPrim => PLB_rdPrim,
      PLB_wrPrim => PLB_wrPrim,
      PLB_masterID => PLB_masterID,
      PLB_abort => PLB_abort,
      PLB_busLock => PLB_busLock,
      PLB_RNW => PLB_RNW,
      PLB_BE => PLB_BE,
      PLB_MSize => PLB_MSize,
      PLB_size => PLB_size,
      PLB_type => PLB_type,
      PLB_lockErr => PLB_lockErr,
      PLB_wrDBus => PLB_wrDBus,
      PLB_wrBurst => PLB_wrBurst,
      PLB_rdBurst => PLB_rdBurst,
      PLB_wrPendReq => PLB_wrPendReq,
      PLB_rdPendReq => PLB_rdPendReq,
      PLB_wrPendPri => PLB_wrPendPri,
      PLB_rdPendPri => PLB_rdPendPri,
      PLB_reqPri => PLB_reqPri,
      PLB_TAttribute => PLB_TAttribute,
      Sl_addrAck => Sl_addrAck,
      Sl_SSize => Sl_SSize,
      Sl_wait => Sl_wait,
      Sl_rearbitrate => Sl_rearbitrate,
      Sl_wrDAck => Sl_wrDAck,
      Sl_wrComp => Sl_wrComp,
      Sl_wrBTerm => Sl_wrBTerm,
      Sl_rdDBus => Sl_rdDBus,
      Sl_rdWdAddr => Sl_rdWdAddr,
      Sl_rdDAck => Sl_rdDAck,
      Sl_rdComp => Sl_rdComp,
      Sl_rdBTerm => Sl_rdBTerm,
      Sl_MBusy => Sl_MBusy,
      Sl_MWrErr => Sl_MWrErr,
      Sl_MRdErr => Sl_MRdErr,
      Sl_MIRQ => Sl_MIRQ
    );

end architecture STRUCTURE;

