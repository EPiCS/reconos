library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;
-- The HWIF interface and all components should be integrated into reconos lib.
-- For now, we include them seperately
library work;
use work.hwif_address_decoder;
use work.perfmon;
use work.identification;

entity hwif_subsystem is
  generic(
    C_HWT_ID            : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
    C_VERSION           : std_logic_vector(31 downto 0) := X"00000100";  -- Version Identifier
    C_CAPABILITIES      : std_logic_vector(31 downto 0) := X"00000001";  --Every Bit specifies a capability like performance monitoring etc.
    C_Perf_Counters_Num : integer                       := 8;  -- How many performance counters do you want?
    C_SLV_DWIDTH        : integer                       := 32
    );
  port (
    -- HWIF interface
    HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
    HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    HWIF2DEC_RdCE  : in  std_logic;
    HWIF2DEC_WrCE  : in  std_logic;
    DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2HWIF_RdAck : out std_logic;
    DEC2HWIF_WrAck : out std_logic;

    -- in-/outputs of internal submodules
    increments : in std_logic_vector (C_Perf_Counters_Num-1 downto 0);
    -- other
    debug      : out std_logic_vector(109 downto 0);
    
    clk        : in std_logic;
    rst        : in std_logic);
end entity hwif_subsystem;

architecture structural of hwif_subsystem is

  constant C_ADDR_RANGE_ARRAY_A : SLV32_ARRAY_TYPE :=
    (X"00000000", X"0000001F",          -- Identification Module, 5 Register
     X"00000020", X"0000005F");         -- Performance monitor, 3 + 8 Register
  
  -----------------------------------------------------------------------------
  -- connections between the address decoder and the sub-modules
  -----------------------------------------------------------------------------
  signal A_DEC2SUB_A_Addr  : std_logic_vector(0 to 31);
  signal A_DEC2SUB_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_A_RdCE  : std_logic;
  signal A_DEC2SUB_A_WrCE  : std_logic;
  signal A_SUB2DEC_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_A_RdAck : std_logic;
  signal A_SUB2DEC_A_WrAck : std_logic;

  signal A_DEC2SUB_B_Addr  : std_logic_vector(0 to 31);
  signal A_DEC2SUB_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_B_RdCE  : std_logic;
  signal A_DEC2SUB_B_WrCE  : std_logic;
  signal A_SUB2DEC_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_B_RdAck : std_logic;
  signal A_SUB2DEC_B_WrAck : std_logic;
  
begin  -- architecture structural

  ad : entity hwif_address_decoder
    generic map (
      C_ADDR_RANGE_ARRAY => C_ADDR_RANGE_ARRAY_A,
      C_SLV_DWIDTH       => C_SLV_DWIDTH
      )
    port map(
      -- HWIF interface
      HWIF2DEC_Addr  => HWIF2DEC_Addr,
      HWIF2DEC_Data  => HWIF2DEC_Data,
      HWIF2DEC_RdCE  => HWIF2DEC_RdCE,
      HWIF2DEC_WrCE  => HWIF2DEC_WrCE,
      DEC2HWIF_Data  => DEC2HWIF_Data,
      DEC2HWIF_RdAck => DEC2HWIF_RdAck,
      DEC2HWIF_WrAck => DEC2HWIF_WrAck,

      -- sub-module interfaces
      DEC2SUB_A_Addr  => A_DEC2SUB_A_Addr,
      DEC2SUB_A_Data  => A_DEC2SUB_A_Data,
      DEC2SUB_A_RdCE  => A_DEC2SUB_A_RdCE,
      DEC2SUB_A_WrCE  => A_DEC2SUB_A_WrCE,
      SUB2DEC_A_Data  => A_SUB2DEC_A_Data,
      SUB2DEC_A_RdAck => A_SUB2DEC_A_RdAck,
      SUB2DEC_A_WrAck => A_SUB2DEC_A_WrAck,

      DEC2SUB_B_Addr  => A_DEC2SUB_B_Addr,
      DEC2SUB_B_Data  => A_DEC2SUB_B_Data,
      DEC2SUB_B_RdCE  => A_DEC2SUB_B_RdCE,
      DEC2SUB_B_WrCE  => A_DEC2SUB_B_WrCE,
      SUB2DEC_B_Data  => A_SUB2DEC_B_Data,
      SUB2DEC_B_RdAck => A_SUB2DEC_B_RdAck,
      SUB2DEC_B_WrAck => A_SUB2DEC_B_WrAck,

      DEC2SUB_C_Addr  => open,
      DEC2SUB_C_Data  => open,
      DEC2SUB_C_RdCE  => open,
      DEC2SUB_C_WrCE  => open,
      SUB2DEC_C_Data  => (others => '0'),
      SUB2DEC_C_RdAck => '0',
      SUB2DEC_C_WrAck => '0',

      DEC2SUB_D_Addr  => open,
      DEC2SUB_D_Data  => open,
      DEC2SUB_D_RdCE  => open,
      DEC2SUB_D_WrCE  => open,
      SUB2DEC_D_Data  => (others => '0'),
      SUB2DEC_D_RdAck => '0',
      SUB2DEC_D_WrAck => '0'
      );

-- ID_register_0
  id_0 : entity identification
    generic map (
      C_HWT_ID       => C_HWT_ID,    -- Unique ID number of this module
      C_VERSION      => C_VERSION,    -- Version Identifier
      C_CAPABILITIES => C_CAPABILITIES,  --Every Bit specifies a capability like performance monitoring etc.

      C_SLV_DWIDTH => C_SLV_DWIDTH
      )
    port map (
      IP2HWT_Addr  => A_DEC2SUB_A_Addr,
      IP2HWT_Data  => A_DEC2SUB_A_Data,
      IP2HWT_RdCE  => A_DEC2SUB_A_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_A_WrCE,
      HWT2IP_Data  => A_SUB2DEC_A_Data,
      HWT2IP_RdAck => A_SUB2DEC_A_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_A_WrAck,
      debug        => open,
      clk          => clk,
      rst          => rst
      );

-- Performance monitor 0
  perfmon_0 : entity perfmon
    generic map(
      C_Counters_Num => C_Perf_Counters_Num,
      C_SLV_DWIDTH   => C_SLV_DWIDTH
      )
    port map (
      IP2HWT_Addr  => A_DEC2SUB_B_Addr,
      IP2HWT_Data  => A_DEC2SUB_B_Data,
      IP2HWT_RdCE  => A_DEC2SUB_B_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_B_WrCE,
      HWT2IP_Data  => A_SUB2DEC_B_Data,
      HWT2IP_RdAck => A_SUB2DEC_B_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_B_WrAck,
      increments   => increments,
      debug        => debug,
      clk          => clk,
      rst          => rst
      );
end architecture structural;
