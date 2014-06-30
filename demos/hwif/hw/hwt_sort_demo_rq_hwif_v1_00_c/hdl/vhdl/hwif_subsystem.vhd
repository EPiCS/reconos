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
use plb2hwif_v1_00_a.hwif_perfmon;
use plb2hwif_v1_00_a.hwif_identification;

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
  signal DEC2SUB: master2slave_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
  signal SUB2DEC: slave2master_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
  
begin  -- architecture structural
  assert C_Perf_Counters_Num = 8
    report "Changed Number of Performance Counters. Update Address Mapping!" severity failure;
  
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
      DEC2SUB => DEC2SUB,
      SUB2DEC => SUB2DEC 
      );

-- ID_register_0
  id_0 : entity hwif_identification
    generic map (
      C_HWT_ID       => C_HWT_ID,    -- Unique ID number of this module
      C_VERSION      => C_VERSION,    -- Version Identifier
      C_CAPABILITIES => C_CAPABILITIES,  --Every Bit specifies a capability like performance monitoring etc.

      C_SLV_DWIDTH => C_SLV_DWIDTH
      )
    port map (
      IP2HWT_Addr  => DEC2SUB(0).address,
      IP2HWT_Data  => DEC2SUB(0).Data_in,
      IP2HWT_RdCE  => DEC2SUB(0).Read_CE,
      IP2HWT_WrCE  => DEC2SUB(0).Write_CE,
      HWT2IP_Data  => SUB2DEC(0).Data_out,
      HWT2IP_RdAck => SUB2DEC(0).Read_Ack,
      HWT2IP_WrAck => SUB2DEC(0).Write_Ack,
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
      IP2HWT_Addr  => DEC2SUB(1).address,
      IP2HWT_Data  => DEC2SUB(1).Data_in,
      IP2HWT_RdCE  => DEC2SUB(1).Read_CE,
      IP2HWT_WrCE  => DEC2SUB(1).Write_CE,
      HWT2IP_Data  => SUB2DEC(1).Data_out,
      HWT2IP_RdAck => SUB2DEC(1).Read_Ack,
      HWT2IP_WrAck => SUB2DEC(1).Write_Ack,
      increments   => increments,
      debug        => debug,
      clk          => clk,
      rst          => rst
      );
end architecture structural;
