library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

--library reconos_v3_00_b;
--use reconos_v3_00_b.reconos_pkg.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;
use plb2hwif_v1_00_a.hwif_address_decoder;
use plb2hwif_v1_00_a.hwif_identification;
use plb2hwif_v1_00_a.hwif_perfmon;
use plb2hwif_v1_00_a.hwif_checksum;



entity hwif_subsystem is
  generic(
    C_HWT_ID                : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
    C_VERSION               : std_logic_vector(31 downto 0) := X"00000100";  -- Version Identifier
    C_CAPABILITIES          : std_logic_vector(31 downto 0) := X"00000001";  --Every Bit specifies a capability like performance monitoring etc.
    C_Perf_Counters_Num     : integer                       := 8;  -- How many performance counters do you want?
    C_CHECKSUM_NUM_CHANNELS : integer                       := 16;
    C_CHECKSUM_ALGO         : integer                       := 0;
    C_SLV_DWIDTH            : integer                       := 32
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

    -- In-/outputs of internal submodules
    -- Performance Monitors custom signals
    increments : in std_logic_vector (C_Perf_Counters_Num-1 downto 0);

    -- Checksum generators custom signals
    read_data       : in std_logic_vector(31 downto 0);
    read_data_valid : in std_logic;
    read_channel    : in std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

    write_data       : in std_logic_vector(31 downto 0);
    write_data_valid : in std_logic;
    write_channel    : in std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

    -- GPIO 
    write_inhibit : in std_logic_vector(31 downto 0);

    -- other
    debug : out std_logic_vector(109 downto 0);

    clk : in std_logic;
    rst : in std_logic);
end entity hwif_subsystem;

architecture structural of hwif_subsystem is
  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant C_ADDR_RANGE_ARRAY_A : SLV32_ARRAY_TYPE :=
    (X"00000000", X"0000001F",          -- Identification Module, 5 Register
     X"00000020", X"0000005F",          -- Performance monitor, 3 + 8 Register
     X"00000060", X"000000DF",          -- Read  checksum generator, 5 + 16
     X"000000E0", X"0000015F");         -- Write checksum generator, 5 + 16
  
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

  signal A_DEC2SUB_C_Addr  : std_logic_vector(0 to 31);
  signal A_DEC2SUB_C_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_C_RdCE  : std_logic;
  signal A_DEC2SUB_C_WrCE  : std_logic;
  signal A_SUB2DEC_C_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_C_RdAck : std_logic;
  signal A_SUB2DEC_C_WrAck : std_logic;

  signal A_DEC2SUB_D_Addr  : std_logic_vector(0 to 31);
  signal A_DEC2SUB_D_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_D_RdCE  : std_logic;
  signal A_DEC2SUB_D_WrCE  : std_logic;
  signal A_SUB2DEC_D_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_D_RdAck : std_logic;
  signal A_SUB2DEC_D_WrAck : std_logic;
  
begin  -- architecture structural

  assert C_Perf_Counters_Num = 8
    report "Changed Number of Performance Counters. Update Address Mapping!" severity failure;
  assert C_CHECKSUM_NUM_CHANNELS = 16
    report "Changed Number of Checksum Channels. Update Address Mapping!" severity failure;
  
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

      DEC2SUB_C_Addr  => A_DEC2SUB_C_Addr,
      DEC2SUB_C_Data  => A_DEC2SUB_C_Data,
      DEC2SUB_C_RdCE  => A_DEC2SUB_C_RdCE,
      DEC2SUB_C_WrCE  => A_DEC2SUB_C_WrCE,
      SUB2DEC_C_Data  => A_SUB2DEC_C_Data,
      SUB2DEC_C_RdAck => A_SUB2DEC_C_RdAck,
      SUB2DEC_C_WrAck => A_SUB2DEC_C_WrAck,

      DEC2SUB_D_Addr  => A_DEC2SUB_D_Addr,
      DEC2SUB_D_Data  => A_DEC2SUB_D_Data,
      DEC2SUB_D_RdCE  => A_DEC2SUB_D_RdCE,
      DEC2SUB_D_WrCE  => A_DEC2SUB_D_WrCE,
      SUB2DEC_D_Data  => A_SUB2DEC_D_Data,
      SUB2DEC_D_RdAck => A_SUB2DEC_D_RdAck,
      SUB2DEC_D_WrAck => A_SUB2DEC_D_WrAck
      );

-- ID_register_0
  id_0 : entity hwif_identification
    generic map (
      C_HWT_ID       => C_HWT_ID,       -- Unique ID number of this module
      C_VERSION      => C_VERSION,      -- Version Identifier
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
  perfmon_0 : entity hwif_perfmon
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

-- Checksum generator for read data
  read_checksum : entity hwif_checksum
    generic map (
      C_CHECKSUM_ALGO => 0,
      C_NUM_CHANNELS  => C_CHECKSUM_NUM_CHANNELS,
      C_SLV_DWIDTH    => C_SLV_DWIDTH)
    port map (
      IP2HWT_Addr  => A_DEC2SUB_C_Addr,
      IP2HWT_Data  => A_DEC2SUB_C_Data,
      IP2HWT_RdCE  => A_DEC2SUB_C_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_C_WrCE,
      HWT2IP_Data  => A_SUB2DEC_C_Data,
      HWT2IP_RdAck => A_SUB2DEC_C_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_C_WrAck,

      data       => read_data,
      data_valid => read_data_valid,
      channel    => read_channel,

      clk => clk,
      rst => rst
      );

-- Checksum generator for write data 
  write_checksum : entity hwif_checksum
    generic map (
      C_CHECKSUM_ALGO => 0,
      C_NUM_CHANNELS  => C_CHECKSUM_NUM_CHANNELS,
      C_SLV_DWIDTH    => C_SLV_DWIDTH)
    port map (
      IP2HWT_Addr  => A_DEC2SUB_D_Addr,
      IP2HWT_Data  => A_DEC2SUB_D_Data,
      IP2HWT_RdCE  => A_DEC2SUB_D_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_D_WrCE,
      HWT2IP_Data  => A_SUB2DEC_D_Data,
      HWT2IP_RdAck => A_SUB2DEC_D_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_D_WrAck,

      data       => write_data,
      data_valid => write_data_valid,
      channel    => write_channel,

      clk => clk,
      rst => rst
      );
  
-- GPIO for write ignore

end architecture structural;
