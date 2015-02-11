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
  -- Types
  -----------------------------------------------------------------------------
  type positive_vector is array(natural range<>) of positive;

  -----------------------------------------------------------------------------
  -- Functions
  -----------------------------------------------------------------------------
  function log2_ceil (
    constant x : natural)
    return natural is
    variable e : integer := 1;
  begin  -- function log2_ceil
    while 2**e < x loop
      e := e+1;
    end loop;
    return e;
  end function log2_ceil;

  -- Function for building an address range array.
  -- Any number of register counts can be given, all counts will
  -- be transformed into consecutive address ranges
  -- of a length, that is the next bigger power of two.
  function return_array (regs : positive_vector)
    return SLV32_ARRAY_TYPE
  is
    variable ret_array  : SLV32_ARRAY_TYPE(0 to regs'length*2-1);
    variable offset     : natural := 0;
    variable size       : natural := 0;
    variable last_index : natural := 0;
  begin
    for i in regs'range loop
      size             := 2**log2_ceil(regs(i));
      ret_array(2*i)   := std_logic_vector(to_unsigned(offset*4, 32));
      ret_array(2*i+1) := std_logic_vector(to_unsigned((offset+size)*4-1, 32));
      offset           := offset + size;
      last_index       := i;
    end loop;

    return ret_array;
  end function;
  
  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant C_ADDR_RANGE_ARRAY : SLV32_ARRAY_TYPE := return_array((
    5,  -- Identification Module, 5 Register
    3+C_Perf_Counters_Num, -- Performance monitor, 3 + 8 Register
    5+C_CHECKSUM_NUM_CHANNELS, -- Read  checksum generator, 5 + 32
    5+C_CHECKSUM_NUM_CHANNELS  -- Write checksum generator, 5 + 32
   ));
                                                    
    --(X"00000000", X"0000001F",          -- Identification Module, 5 Register
    -- X"00000020", X"0000005F",          -- Performance monitor, 3 + 8 Register
    -- X"00000060", X"000000DF",          -- Read  checksum generator, 5 + 32
    -- X"000000E0", X"0000015F");         -- Write checksum generator, 5 + 32

  -----------------------------------------------------------------------------
  -- connections between the address decoder and the sub-modules
  -----------------------------------------------------------------------------

  signal DEC2SUB : master2slave_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
  signal SUB2DEC : slave2master_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
  
begin  -- architecture structural

  assert C_Perf_Counters_Num = 8
    report "Changed Number of Performance Counters. Update Address Mapping!" severity failure;
  assert C_CHECKSUM_NUM_CHANNELS = 16
    report "Changed Number of Checksum Channels. Update Address Mapping!" severity failure;
  
  ad : entity hwif_address_decoder
    generic map (
      C_ADDR_RANGE_ARRAY => C_ADDR_RANGE_ARRAY,
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
      C_HWT_ID       => C_HWT_ID,       -- Unique ID number of this module
      C_VERSION      => C_VERSION,      -- Version Identifier
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

-- Checksum generator for read data
  read_checksum : entity hwif_checksum
    generic map (
      C_CHECKSUM_ALGO => 0,
      C_NUM_CHANNELS  => C_CHECKSUM_NUM_CHANNELS,
      C_SLV_DWIDTH    => C_SLV_DWIDTH)
    port map (
      IP2HWT_Addr  => DEC2SUB(2).address,
      IP2HWT_Data  => DEC2SUB(2).Data_in,
      IP2HWT_RdCE  => DEC2SUB(2).Read_CE,
      IP2HWT_WrCE  => DEC2SUB(2).Write_CE,
      HWT2IP_Data  => SUB2DEC(2).Data_out,
      HWT2IP_RdAck => SUB2DEC(2).Read_Ack,
      HWT2IP_WrAck => SUB2DEC(2).Write_Ack,

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
      IP2HWT_Addr  => DEC2SUB(3).address,
      IP2HWT_Data  => DEC2SUB(3).Data_in,
      IP2HWT_RdCE  => DEC2SUB(3).Read_CE,
      IP2HWT_WrCE  => DEC2SUB(3).Write_CE,
      HWT2IP_Data  => SUB2DEC(3).Data_out,
      HWT2IP_RdAck => SUB2DEC(3).Read_Ack,
      HWT2IP_WrAck => SUB2DEC(3).Write_Ack,

      data       => write_data,
      data_valid => write_data_valid,
      channel    => write_channel,

      clk => clk,
      rst => rst
      );

-- GPIO for write ignore

end architecture structural;
