-------------------------------------------------------------------------------
-- mdm_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library mdm_v2_00_a;
use mdm_v2_00_a.all;

entity mdm_0_wrapper is
  port (
    Interrupt : out std_logic;
    Debug_SYS_Rst : out std_logic;
    Ext_BRK : out std_logic;
    Ext_NM_BRK : out std_logic;
    S_AXI_ACLK : in std_logic;
    S_AXI_ARESETN : in std_logic;
    S_AXI_AWADDR : in std_logic_vector(31 downto 0);
    S_AXI_AWVALID : in std_logic;
    S_AXI_AWREADY : out std_logic;
    S_AXI_WDATA : in std_logic_vector(31 downto 0);
    S_AXI_WSTRB : in std_logic_vector(3 downto 0);
    S_AXI_WVALID : in std_logic;
    S_AXI_WREADY : out std_logic;
    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    S_AXI_BVALID : out std_logic;
    S_AXI_BREADY : in std_logic;
    S_AXI_ARADDR : in std_logic_vector(31 downto 0);
    S_AXI_ARVALID : in std_logic;
    S_AXI_ARREADY : out std_logic;
    S_AXI_RDATA : out std_logic_vector(31 downto 0);
    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    S_AXI_RVALID : out std_logic;
    S_AXI_RREADY : in std_logic;
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
    Sl_MIRQ : out std_logic_vector(0 to 2);
    Dbg_Clk_0 : out std_logic;
    Dbg_TDI_0 : out std_logic;
    Dbg_TDO_0 : in std_logic;
    Dbg_Reg_En_0 : out std_logic_vector(0 to 7);
    Dbg_Capture_0 : out std_logic;
    Dbg_Shift_0 : out std_logic;
    Dbg_Update_0 : out std_logic;
    Dbg_Rst_0 : out std_logic;
    Dbg_Clk_1 : out std_logic;
    Dbg_TDI_1 : out std_logic;
    Dbg_TDO_1 : in std_logic;
    Dbg_Reg_En_1 : out std_logic_vector(0 to 7);
    Dbg_Capture_1 : out std_logic;
    Dbg_Shift_1 : out std_logic;
    Dbg_Update_1 : out std_logic;
    Dbg_Rst_1 : out std_logic;
    Dbg_Clk_2 : out std_logic;
    Dbg_TDI_2 : out std_logic;
    Dbg_TDO_2 : in std_logic;
    Dbg_Reg_En_2 : out std_logic_vector(0 to 7);
    Dbg_Capture_2 : out std_logic;
    Dbg_Shift_2 : out std_logic;
    Dbg_Update_2 : out std_logic;
    Dbg_Rst_2 : out std_logic;
    Dbg_Clk_3 : out std_logic;
    Dbg_TDI_3 : out std_logic;
    Dbg_TDO_3 : in std_logic;
    Dbg_Reg_En_3 : out std_logic_vector(0 to 7);
    Dbg_Capture_3 : out std_logic;
    Dbg_Shift_3 : out std_logic;
    Dbg_Update_3 : out std_logic;
    Dbg_Rst_3 : out std_logic;
    Dbg_Clk_4 : out std_logic;
    Dbg_TDI_4 : out std_logic;
    Dbg_TDO_4 : in std_logic;
    Dbg_Reg_En_4 : out std_logic_vector(0 to 7);
    Dbg_Capture_4 : out std_logic;
    Dbg_Shift_4 : out std_logic;
    Dbg_Update_4 : out std_logic;
    Dbg_Rst_4 : out std_logic;
    Dbg_Clk_5 : out std_logic;
    Dbg_TDI_5 : out std_logic;
    Dbg_TDO_5 : in std_logic;
    Dbg_Reg_En_5 : out std_logic_vector(0 to 7);
    Dbg_Capture_5 : out std_logic;
    Dbg_Shift_5 : out std_logic;
    Dbg_Update_5 : out std_logic;
    Dbg_Rst_5 : out std_logic;
    Dbg_Clk_6 : out std_logic;
    Dbg_TDI_6 : out std_logic;
    Dbg_TDO_6 : in std_logic;
    Dbg_Reg_En_6 : out std_logic_vector(0 to 7);
    Dbg_Capture_6 : out std_logic;
    Dbg_Shift_6 : out std_logic;
    Dbg_Update_6 : out std_logic;
    Dbg_Rst_6 : out std_logic;
    Dbg_Clk_7 : out std_logic;
    Dbg_TDI_7 : out std_logic;
    Dbg_TDO_7 : in std_logic;
    Dbg_Reg_En_7 : out std_logic_vector(0 to 7);
    Dbg_Capture_7 : out std_logic;
    Dbg_Shift_7 : out std_logic;
    Dbg_Update_7 : out std_logic;
    Dbg_Rst_7 : out std_logic;
    bscan_tdi : out std_logic;
    bscan_reset : out std_logic;
    bscan_shift : out std_logic;
    bscan_update : out std_logic;
    bscan_capture : out std_logic;
    bscan_sel1 : out std_logic;
    bscan_drck1 : out std_logic;
    bscan_tdo1 : in std_logic;
    Ext_JTAG_DRCK : out std_logic;
    Ext_JTAG_RESET : out std_logic;
    Ext_JTAG_SEL : out std_logic;
    Ext_JTAG_CAPTURE : out std_logic;
    Ext_JTAG_SHIFT : out std_logic;
    Ext_JTAG_UPDATE : out std_logic;
    Ext_JTAG_TDI : out std_logic;
    Ext_JTAG_TDO : in std_logic
  );

  attribute x_core_info : STRING;
  attribute x_core_info of mdm_0_wrapper : entity is "mdm_v2_00_a";

end mdm_0_wrapper;

architecture STRUCTURE of mdm_0_wrapper is

  component mdm is
    generic (
      C_FAMILY : STRING;
      C_JTAG_CHAIN : INTEGER;
      C_INTERCONNECT : INTEGER;
      C_BASEADDR : STD_LOGIC_VECTOR;
      C_HIGHADDR : STD_LOGIC_VECTOR;
      C_SPLB_AWIDTH : INTEGER;
      C_SPLB_DWIDTH : INTEGER;
      C_SPLB_P2P : INTEGER;
      C_SPLB_MID_WIDTH : INTEGER;
      C_SPLB_NUM_MASTERS : INTEGER;
      C_SPLB_NATIVE_DWIDTH : INTEGER;
      C_SPLB_SUPPORT_BURSTS : INTEGER;
      C_MB_DBG_PORTS : INTEGER;
      C_USE_UART : INTEGER;
      C_S_AXI_ADDR_WIDTH : INTEGER;
      C_S_AXI_DATA_WIDTH : INTEGER
    );
    port (
      Interrupt : out std_logic;
      Debug_SYS_Rst : out std_logic;
      Ext_BRK : out std_logic;
      Ext_NM_BRK : out std_logic;
      S_AXI_ACLK : in std_logic;
      S_AXI_ARESETN : in std_logic;
      S_AXI_AWADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
      S_AXI_AWVALID : in std_logic;
      S_AXI_AWREADY : out std_logic;
      S_AXI_WDATA : in std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
      S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8-1) downto 0);
      S_AXI_WVALID : in std_logic;
      S_AXI_WREADY : out std_logic;
      S_AXI_BRESP : out std_logic_vector(1 downto 0);
      S_AXI_BVALID : out std_logic;
      S_AXI_BREADY : in std_logic;
      S_AXI_ARADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
      S_AXI_ARVALID : in std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
      S_AXI_RRESP : out std_logic_vector(1 downto 0);
      S_AXI_RVALID : out std_logic;
      S_AXI_RREADY : in std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
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
      Sl_MIRQ : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Dbg_Clk_0 : out std_logic;
      Dbg_TDI_0 : out std_logic;
      Dbg_TDO_0 : in std_logic;
      Dbg_Reg_En_0 : out std_logic_vector(0 to 7);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0 : out std_logic;
      Dbg_Update_0 : out std_logic;
      Dbg_Rst_0 : out std_logic;
      Dbg_Clk_1 : out std_logic;
      Dbg_TDI_1 : out std_logic;
      Dbg_TDO_1 : in std_logic;
      Dbg_Reg_En_1 : out std_logic_vector(0 to 7);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1 : out std_logic;
      Dbg_Update_1 : out std_logic;
      Dbg_Rst_1 : out std_logic;
      Dbg_Clk_2 : out std_logic;
      Dbg_TDI_2 : out std_logic;
      Dbg_TDO_2 : in std_logic;
      Dbg_Reg_En_2 : out std_logic_vector(0 to 7);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2 : out std_logic;
      Dbg_Update_2 : out std_logic;
      Dbg_Rst_2 : out std_logic;
      Dbg_Clk_3 : out std_logic;
      Dbg_TDI_3 : out std_logic;
      Dbg_TDO_3 : in std_logic;
      Dbg_Reg_En_3 : out std_logic_vector(0 to 7);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3 : out std_logic;
      Dbg_Update_3 : out std_logic;
      Dbg_Rst_3 : out std_logic;
      Dbg_Clk_4 : out std_logic;
      Dbg_TDI_4 : out std_logic;
      Dbg_TDO_4 : in std_logic;
      Dbg_Reg_En_4 : out std_logic_vector(0 to 7);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4 : out std_logic;
      Dbg_Update_4 : out std_logic;
      Dbg_Rst_4 : out std_logic;
      Dbg_Clk_5 : out std_logic;
      Dbg_TDI_5 : out std_logic;
      Dbg_TDO_5 : in std_logic;
      Dbg_Reg_En_5 : out std_logic_vector(0 to 7);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5 : out std_logic;
      Dbg_Update_5 : out std_logic;
      Dbg_Rst_5 : out std_logic;
      Dbg_Clk_6 : out std_logic;
      Dbg_TDI_6 : out std_logic;
      Dbg_TDO_6 : in std_logic;
      Dbg_Reg_En_6 : out std_logic_vector(0 to 7);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6 : out std_logic;
      Dbg_Update_6 : out std_logic;
      Dbg_Rst_6 : out std_logic;
      Dbg_Clk_7 : out std_logic;
      Dbg_TDI_7 : out std_logic;
      Dbg_TDO_7 : in std_logic;
      Dbg_Reg_En_7 : out std_logic_vector(0 to 7);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7 : out std_logic;
      Dbg_Update_7 : out std_logic;
      Dbg_Rst_7 : out std_logic;
      bscan_tdi : out std_logic;
      bscan_reset : out std_logic;
      bscan_shift : out std_logic;
      bscan_update : out std_logic;
      bscan_capture : out std_logic;
      bscan_sel1 : out std_logic;
      bscan_drck1 : out std_logic;
      bscan_tdo1 : in std_logic;
      Ext_JTAG_DRCK : out std_logic;
      Ext_JTAG_RESET : out std_logic;
      Ext_JTAG_SEL : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT : out std_logic;
      Ext_JTAG_UPDATE : out std_logic;
      Ext_JTAG_TDI : out std_logic;
      Ext_JTAG_TDO : in std_logic
    );
  end component;

begin

  mdm_0 : mdm
    generic map (
      C_FAMILY => "virtex6",
      C_JTAG_CHAIN => 2,
      C_INTERCONNECT => 1,
      C_BASEADDR => X"84400000",
      C_HIGHADDR => X"8440ffff",
      C_SPLB_AWIDTH => 32,
      C_SPLB_DWIDTH => 64,
      C_SPLB_P2P => 0,
      C_SPLB_MID_WIDTH => 2,
      C_SPLB_NUM_MASTERS => 3,
      C_SPLB_NATIVE_DWIDTH => 32,
      C_SPLB_SUPPORT_BURSTS => 1,
      C_MB_DBG_PORTS => 1,
      C_USE_UART => 1,
      C_S_AXI_ADDR_WIDTH => 32,
      C_S_AXI_DATA_WIDTH => 32
    )
    port map (
      Interrupt => Interrupt,
      Debug_SYS_Rst => Debug_SYS_Rst,
      Ext_BRK => Ext_BRK,
      Ext_NM_BRK => Ext_NM_BRK,
      S_AXI_ACLK => S_AXI_ACLK,
      S_AXI_ARESETN => S_AXI_ARESETN,
      S_AXI_AWADDR => S_AXI_AWADDR,
      S_AXI_AWVALID => S_AXI_AWVALID,
      S_AXI_AWREADY => S_AXI_AWREADY,
      S_AXI_WDATA => S_AXI_WDATA,
      S_AXI_WSTRB => S_AXI_WSTRB,
      S_AXI_WVALID => S_AXI_WVALID,
      S_AXI_WREADY => S_AXI_WREADY,
      S_AXI_BRESP => S_AXI_BRESP,
      S_AXI_BVALID => S_AXI_BVALID,
      S_AXI_BREADY => S_AXI_BREADY,
      S_AXI_ARADDR => S_AXI_ARADDR,
      S_AXI_ARVALID => S_AXI_ARVALID,
      S_AXI_ARREADY => S_AXI_ARREADY,
      S_AXI_RDATA => S_AXI_RDATA,
      S_AXI_RRESP => S_AXI_RRESP,
      S_AXI_RVALID => S_AXI_RVALID,
      S_AXI_RREADY => S_AXI_RREADY,
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
      Sl_MIRQ => Sl_MIRQ,
      Dbg_Clk_0 => Dbg_Clk_0,
      Dbg_TDI_0 => Dbg_TDI_0,
      Dbg_TDO_0 => Dbg_TDO_0,
      Dbg_Reg_En_0 => Dbg_Reg_En_0,
      Dbg_Capture_0 => Dbg_Capture_0,
      Dbg_Shift_0 => Dbg_Shift_0,
      Dbg_Update_0 => Dbg_Update_0,
      Dbg_Rst_0 => Dbg_Rst_0,
      Dbg_Clk_1 => Dbg_Clk_1,
      Dbg_TDI_1 => Dbg_TDI_1,
      Dbg_TDO_1 => Dbg_TDO_1,
      Dbg_Reg_En_1 => Dbg_Reg_En_1,
      Dbg_Capture_1 => Dbg_Capture_1,
      Dbg_Shift_1 => Dbg_Shift_1,
      Dbg_Update_1 => Dbg_Update_1,
      Dbg_Rst_1 => Dbg_Rst_1,
      Dbg_Clk_2 => Dbg_Clk_2,
      Dbg_TDI_2 => Dbg_TDI_2,
      Dbg_TDO_2 => Dbg_TDO_2,
      Dbg_Reg_En_2 => Dbg_Reg_En_2,
      Dbg_Capture_2 => Dbg_Capture_2,
      Dbg_Shift_2 => Dbg_Shift_2,
      Dbg_Update_2 => Dbg_Update_2,
      Dbg_Rst_2 => Dbg_Rst_2,
      Dbg_Clk_3 => Dbg_Clk_3,
      Dbg_TDI_3 => Dbg_TDI_3,
      Dbg_TDO_3 => Dbg_TDO_3,
      Dbg_Reg_En_3 => Dbg_Reg_En_3,
      Dbg_Capture_3 => Dbg_Capture_3,
      Dbg_Shift_3 => Dbg_Shift_3,
      Dbg_Update_3 => Dbg_Update_3,
      Dbg_Rst_3 => Dbg_Rst_3,
      Dbg_Clk_4 => Dbg_Clk_4,
      Dbg_TDI_4 => Dbg_TDI_4,
      Dbg_TDO_4 => Dbg_TDO_4,
      Dbg_Reg_En_4 => Dbg_Reg_En_4,
      Dbg_Capture_4 => Dbg_Capture_4,
      Dbg_Shift_4 => Dbg_Shift_4,
      Dbg_Update_4 => Dbg_Update_4,
      Dbg_Rst_4 => Dbg_Rst_4,
      Dbg_Clk_5 => Dbg_Clk_5,
      Dbg_TDI_5 => Dbg_TDI_5,
      Dbg_TDO_5 => Dbg_TDO_5,
      Dbg_Reg_En_5 => Dbg_Reg_En_5,
      Dbg_Capture_5 => Dbg_Capture_5,
      Dbg_Shift_5 => Dbg_Shift_5,
      Dbg_Update_5 => Dbg_Update_5,
      Dbg_Rst_5 => Dbg_Rst_5,
      Dbg_Clk_6 => Dbg_Clk_6,
      Dbg_TDI_6 => Dbg_TDI_6,
      Dbg_TDO_6 => Dbg_TDO_6,
      Dbg_Reg_En_6 => Dbg_Reg_En_6,
      Dbg_Capture_6 => Dbg_Capture_6,
      Dbg_Shift_6 => Dbg_Shift_6,
      Dbg_Update_6 => Dbg_Update_6,
      Dbg_Rst_6 => Dbg_Rst_6,
      Dbg_Clk_7 => Dbg_Clk_7,
      Dbg_TDI_7 => Dbg_TDI_7,
      Dbg_TDO_7 => Dbg_TDO_7,
      Dbg_Reg_En_7 => Dbg_Reg_En_7,
      Dbg_Capture_7 => Dbg_Capture_7,
      Dbg_Shift_7 => Dbg_Shift_7,
      Dbg_Update_7 => Dbg_Update_7,
      Dbg_Rst_7 => Dbg_Rst_7,
      bscan_tdi => bscan_tdi,
      bscan_reset => bscan_reset,
      bscan_shift => bscan_shift,
      bscan_update => bscan_update,
      bscan_capture => bscan_capture,
      bscan_sel1 => bscan_sel1,
      bscan_drck1 => bscan_drck1,
      bscan_tdo1 => bscan_tdo1,
      Ext_JTAG_DRCK => Ext_JTAG_DRCK,
      Ext_JTAG_RESET => Ext_JTAG_RESET,
      Ext_JTAG_SEL => Ext_JTAG_SEL,
      Ext_JTAG_CAPTURE => Ext_JTAG_CAPTURE,
      Ext_JTAG_SHIFT => Ext_JTAG_SHIFT,
      Ext_JTAG_UPDATE => Ext_JTAG_UPDATE,
      Ext_JTAG_TDI => Ext_JTAG_TDI,
      Ext_JTAG_TDO => Ext_JTAG_TDO
    );

end architecture STRUCTURE;

