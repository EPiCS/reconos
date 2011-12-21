-------------------------------------------------------------------------------
-- xps_timer_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library xps_timer_v1_02_a;
use xps_timer_v1_02_a.all;

entity xps_timer_0_wrapper is
  port (
    CaptureTrig0 : in std_logic;
    CaptureTrig1 : in std_logic;
    GenerateOut0 : out std_logic;
    GenerateOut1 : out std_logic;
    PWM0 : out std_logic;
    Interrupt : out std_logic;
    Freeze : in std_logic;
    SPLB_Clk : in std_logic;
    SPLB_Rst : in std_logic;
    PLB_ABus : in std_logic_vector(0 to 31);
    PLB_PAValid : in std_logic;
    PLB_masterID : in std_logic_vector(0 to 1);
    PLB_RNW : in std_logic;
    PLB_BE : in std_logic_vector(0 to 7);
    PLB_size : in std_logic_vector(0 to 3);
    PLB_type : in std_logic_vector(0 to 2);
    PLB_wrDBus : in std_logic_vector(0 to 63);
    Sl_addrAck : out std_logic;
    Sl_SSize : out std_logic_vector(0 to 1);
    Sl_wait : out std_logic;
    Sl_rearbitrate : out std_logic;
    Sl_wrDAck : out std_logic;
    Sl_wrComp : out std_logic;
    Sl_rdDBus : out std_logic_vector(0 to 63);
    Sl_rdDAck : out std_logic;
    Sl_rdComp : out std_logic;
    Sl_MBusy : out std_logic_vector(0 to 2);
    Sl_MWrErr : out std_logic_vector(0 to 2);
    Sl_MRdErr : out std_logic_vector(0 to 2);
    PLB_UABus : in std_logic_vector(0 to 31);
    PLB_SAValid : in std_logic;
    PLB_rdPrim : in std_logic;
    PLB_wrPrim : in std_logic;
    PLB_abort : in std_logic;
    PLB_busLock : in std_logic;
    PLB_MSize : in std_logic_vector(0 to 1);
    PLB_lockErr : in std_logic;
    PLB_wrBurst : in std_logic;
    PLB_rdBurst : in std_logic;
    PLB_wrPendReq : in std_logic;
    PLB_rdPendReq : in std_logic;
    PLB_wrPendPri : in std_logic_vector(0 to 1);
    PLB_rdPendPri : in std_logic_vector(0 to 1);
    PLB_reqPri : in std_logic_vector(0 to 1);
    PLB_TAttribute : in std_logic_vector(0 to 15);
    Sl_wrBTerm : out std_logic;
    Sl_rdWdAddr : out std_logic_vector(0 to 3);
    Sl_rdBTerm : out std_logic;
    Sl_MIRQ : out std_logic_vector(0 to 2)
  );

  attribute x_core_info : STRING;
  attribute x_core_info of xps_timer_0_wrapper : entity is "xps_timer_v1_02_a";

end xps_timer_0_wrapper;

architecture STRUCTURE of xps_timer_0_wrapper is

  component xps_timer is
    generic (
      C_FAMILY : STRING;
      C_COUNT_WIDTH : INTEGER;
      C_ONE_TIMER_ONLY : INTEGER;
      C_TRIG0_ASSERT : std_logic;
      C_TRIG1_ASSERT : std_logic;
      C_GEN0_ASSERT : std_logic;
      C_GEN1_ASSERT : std_logic;
      C_BASEADDR : std_logic_vector;
      C_HIGHADDR : std_logic_vector;
      C_SPLB_AWIDTH : INTEGER;
      C_SPLB_DWIDTH : INTEGER;
      C_SPLB_P2P : INTEGER;
      C_SPLB_MID_WIDTH : INTEGER;
      C_SPLB_NUM_MASTERS : INTEGER;
      C_SPLB_SUPPORT_BURSTS : INTEGER;
      C_SPLB_NATIVE_DWIDTH : INTEGER
    );
    port (
      CaptureTrig0 : in std_logic;
      CaptureTrig1 : in std_logic;
      GenerateOut0 : out std_logic;
      GenerateOut1 : out std_logic;
      PWM0 : out std_logic;
      Interrupt : out std_logic;
      Freeze : in std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to C_SPLB_AWIDTH-1);
      PLB_PAValid : in std_logic;
      PLB_masterID : in std_logic_vector(0 to (C_SPLB_MID_WIDTH-1));
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to ((C_SPLB_DWIDTH/8)-1));
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrDBus : in std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to (C_SPLB_DWIDTH-1));
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MWrErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      Sl_MRdErr : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1));
      PLB_UABus : in std_logic_vector(0 to C_SPLB_AWIDTH-1);
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_lockErr : in std_logic;
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_wrBTerm : out std_logic;
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdBTerm : out std_logic;
      Sl_MIRQ : out std_logic_vector(0 to (C_SPLB_NUM_MASTERS-1))
    );
  end component;

begin

  xps_timer_0 : xps_timer
    generic map (
      C_FAMILY => "virtex6",
      C_COUNT_WIDTH => 32,
      C_ONE_TIMER_ONLY => 0,
      C_TRIG0_ASSERT => '1',
      C_TRIG1_ASSERT => '1',
      C_GEN0_ASSERT => '1',
      C_GEN1_ASSERT => '1',
      C_BASEADDR => X"85000000",
      C_HIGHADDR => X"850000FF",
      C_SPLB_AWIDTH => 32,
      C_SPLB_DWIDTH => 64,
      C_SPLB_P2P => 0,
      C_SPLB_MID_WIDTH => 2,
      C_SPLB_NUM_MASTERS => 3,
      C_SPLB_SUPPORT_BURSTS => 0,
      C_SPLB_NATIVE_DWIDTH => 32
    )
    port map (
      CaptureTrig0 => CaptureTrig0,
      CaptureTrig1 => CaptureTrig1,
      GenerateOut0 => GenerateOut0,
      GenerateOut1 => GenerateOut1,
      PWM0 => PWM0,
      Interrupt => Interrupt,
      Freeze => Freeze,
      SPLB_Clk => SPLB_Clk,
      SPLB_Rst => SPLB_Rst,
      PLB_ABus => PLB_ABus,
      PLB_PAValid => PLB_PAValid,
      PLB_masterID => PLB_masterID,
      PLB_RNW => PLB_RNW,
      PLB_BE => PLB_BE,
      PLB_size => PLB_size,
      PLB_type => PLB_type,
      PLB_wrDBus => PLB_wrDBus,
      Sl_addrAck => Sl_addrAck,
      Sl_SSize => Sl_SSize,
      Sl_wait => Sl_wait,
      Sl_rearbitrate => Sl_rearbitrate,
      Sl_wrDAck => Sl_wrDAck,
      Sl_wrComp => Sl_wrComp,
      Sl_rdDBus => Sl_rdDBus,
      Sl_rdDAck => Sl_rdDAck,
      Sl_rdComp => Sl_rdComp,
      Sl_MBusy => Sl_MBusy,
      Sl_MWrErr => Sl_MWrErr,
      Sl_MRdErr => Sl_MRdErr,
      PLB_UABus => PLB_UABus,
      PLB_SAValid => PLB_SAValid,
      PLB_rdPrim => PLB_rdPrim,
      PLB_wrPrim => PLB_wrPrim,
      PLB_abort => PLB_abort,
      PLB_busLock => PLB_busLock,
      PLB_MSize => PLB_MSize,
      PLB_lockErr => PLB_lockErr,
      PLB_wrBurst => PLB_wrBurst,
      PLB_rdBurst => PLB_rdBurst,
      PLB_wrPendReq => PLB_wrPendReq,
      PLB_rdPendReq => PLB_rdPendReq,
      PLB_wrPendPri => PLB_wrPendPri,
      PLB_rdPendPri => PLB_rdPendPri,
      PLB_reqPri => PLB_reqPri,
      PLB_TAttribute => PLB_TAttribute,
      Sl_wrBTerm => Sl_wrBTerm,
      Sl_rdWdAddr => Sl_rdWdAddr,
      Sl_rdBTerm => Sl_rdBTerm,
      Sl_MIRQ => Sl_MIRQ
    );

end architecture STRUCTURE;

