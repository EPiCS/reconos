-------------------------------------------------------------------------------
-- dip_switches_8bit_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library xps_gpio_v2_00_a;
use xps_gpio_v2_00_a.all;

entity dip_switches_8bit_wrapper is
  port (
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
    IP2INTC_Irpt : out std_logic;
    GPIO_IO_I : in std_logic_vector(0 to 7);
    GPIO_IO_O : out std_logic_vector(0 to 7);
    GPIO_IO_T : out std_logic_vector(0 to 7);
    GPIO2_IO_I : in std_logic_vector(0 to 31);
    GPIO2_IO_O : out std_logic_vector(0 to 31);
    GPIO2_IO_T : out std_logic_vector(0 to 31)
  );

  attribute x_core_info : STRING;
  attribute x_core_info of dip_switches_8bit_wrapper : entity is "xps_gpio_v2_00_a";

end dip_switches_8bit_wrapper;

architecture STRUCTURE of dip_switches_8bit_wrapper is

  component xps_gpio is
    generic (
      C_BASEADDR : std_logic_vector(0 to 31);
      C_HIGHADDR : std_logic_vector(0 to 31);
      C_SPLB_AWIDTH : INTEGER;
      C_SPLB_DWIDTH : INTEGER;
      C_SPLB_P2P : INTEGER;
      C_SPLB_MID_WIDTH : INTEGER;
      C_SPLB_NUM_MASTERS : INTEGER;
      C_SPLB_NATIVE_DWIDTH : INTEGER;
      C_SPLB_SUPPORT_BURSTS : INTEGER;
      C_FAMILY : STRING;
      C_ALL_INPUTS : INTEGER;
      C_ALL_INPUTS_2 : INTEGER;
      C_GPIO_WIDTH : INTEGER;
      C_GPIO2_WIDTH : INTEGER;
      C_INTERRUPT_PRESENT : INTEGER;
      C_DOUT_DEFAULT : std_logic_vector;
      C_TRI_DEFAULT : std_logic_vector;
      C_IS_DUAL : INTEGER;
      C_DOUT_DEFAULT_2 : std_logic_vector;
      C_TRI_DEFAULT_2 : std_logic_vector
    );
    port (
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
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to (C_GPIO_WIDTH-1));
      GPIO_IO_O : out std_logic_vector(0 to (C_GPIO_WIDTH-1));
      GPIO_IO_T : out std_logic_vector(0 to (C_GPIO_WIDTH-1));
      GPIO2_IO_I : in std_logic_vector(0 to (C_GPIO2_WIDTH-1));
      GPIO2_IO_O : out std_logic_vector(0 to (C_GPIO2_WIDTH-1));
      GPIO2_IO_T : out std_logic_vector(0 to (C_GPIO2_WIDTH-1))
    );
  end component;

begin

  DIP_Switches_8Bit : xps_gpio
    generic map (
      C_BASEADDR => X"81460000",
      C_HIGHADDR => X"8146ffff",
      C_SPLB_AWIDTH => 32,
      C_SPLB_DWIDTH => 64,
      C_SPLB_P2P => 0,
      C_SPLB_MID_WIDTH => 2,
      C_SPLB_NUM_MASTERS => 3,
      C_SPLB_NATIVE_DWIDTH => 32,
      C_SPLB_SUPPORT_BURSTS => 0,
      C_FAMILY => "virtex6",
      C_ALL_INPUTS => 1,
      C_ALL_INPUTS_2 => 0,
      C_GPIO_WIDTH => 8,
      C_GPIO2_WIDTH => 32,
      C_INTERRUPT_PRESENT => 0,
      C_DOUT_DEFAULT => X"00000000",
      C_TRI_DEFAULT => X"ffffffff",
      C_IS_DUAL => 0,
      C_DOUT_DEFAULT_2 => X"00000000",
      C_TRI_DEFAULT_2 => X"ffffffff"
    )
    port map (
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
      IP2INTC_Irpt => IP2INTC_Irpt,
      GPIO_IO_I => GPIO_IO_I,
      GPIO_IO_O => GPIO_IO_O,
      GPIO_IO_T => GPIO_IO_T,
      GPIO2_IO_I => GPIO2_IO_I,
      GPIO2_IO_O => GPIO2_IO_O,
      GPIO2_IO_T => GPIO2_IO_T
    );

end architecture STRUCTURE;

