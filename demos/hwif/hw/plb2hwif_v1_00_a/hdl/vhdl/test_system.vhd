----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:02:37 02/25/2014 
-- Design Name: 
-- Module Name:    test_system - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library work;
use work.hwif_pck.all;
use work.hwif_address_decoder;
use work.user_logic;
use work.perfmon;
use work.identification;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_system is
  generic
    (
      C_HWIF_IF_COUNT           : integer := 2;
      C_HWIF_ADDRESS_SPACE_BITS : integer := 16;
      C_Counters_Num            : integer := 2;
      C_SLV_AWIDTH              : integer := 32;
      C_SLV_DWIDTH              : integer := 32;
      C_NUM_MEM                 : integer := 1
      );
  port
    (
      Bus2IP_Clk    : in  std_logic;
      Bus2IP_Reset : in  std_logic;
      Bus2IP_Addr   : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
      Bus2IP_Data   : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      Bus2IP_BE     : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
      Bus2IP_CS     : in  std_logic_vector(0 to C_NUM_MEM-1);
      Bus2IP_RNW    : in  std_logic;
      IP2Bus_Data   : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2Bus_RdAck  : out std_logic;
      IP2Bus_WrAck  : out std_logic;
      IP2Bus_Error  : out std_logic;

      increments_a : in std_logic_vector(C_Counters_Num-1 downto 0);
      increments_b : in std_logic_vector(C_Counters_Num-1 downto 0)

      );
end test_system;

architecture Behavioral of test_system is
  constant C_IPIF_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE := ((others => '0'),(others => '1'));
  
  
  constant C_ADDR_RANGE_ARRAY_A : SLV32_ARRAY_TYPE :=
    (X"00000000", X"0000001F",          -- Identification Module, 5 Register
     X"00000020", X"0000003F");         -- Performance monitor, 3 + 2 Register
  constant C_ADDR_RANGE_ARRAY_B : SLV32_ARRAY_TYPE :=
    (X"00000000", X"0000001F",          -- Identification Module, 5 Register
     X"00000020", X"0000003F");         -- Performance monitor, 3 + 2 Register


  ----------------------------------------------------------------------------- 
  -- connections between user_logic and the two address decoders
  -----------------------------------------------------------------------------
  signal IP2HWT_Addr_A  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal IP2HWT_Data_A  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal IP2HWT_RdCE_A  : std_logic;
  signal IP2HWT_WrCE_A  : std_logic;
  signal HWT2IP_Data_A  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal HWT2IP_RdAck_A : std_logic;
  signal HWT2IP_WrAck_A : std_logic;

  signal IP2HWT_Addr_B  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal IP2HWT_Data_B  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal IP2HWT_RdCE_B  : std_logic;
  signal IP2HWT_WrCE_B  : std_logic;
  signal HWT2IP_Data_B  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal HWT2IP_RdAck_B : std_logic;
  signal HWT2IP_WrAck_B : std_logic;

  -----------------------------------------------------------------------------
  -- connections between the address decoder and the sub-modules
  -----------------------------------------------------------------------------
  signal A_DEC2SUB_A_Addr  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal A_DEC2SUB_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_A_RdCE  : std_logic;
  signal A_DEC2SUB_A_WrCE  : std_logic;
  signal A_SUB2DEC_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_A_RdAck : std_logic;
  signal A_SUB2DEC_A_WrAck : std_logic;

  signal A_DEC2SUB_B_Addr  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal A_DEC2SUB_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_DEC2SUB_B_RdCE  : std_logic;
  signal A_DEC2SUB_B_WrCE  : std_logic;
  signal A_SUB2DEC_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal A_SUB2DEC_B_RdAck : std_logic;
  signal A_SUB2DEC_B_WrAck : std_logic;

  signal B_DEC2SUB_A_Addr  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal B_DEC2SUB_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal B_DEC2SUB_A_RdCE  : std_logic;
  signal B_DEC2SUB_A_WrCE  : std_logic;
  signal B_SUB2DEC_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal B_SUB2DEC_A_RdAck : std_logic;
  signal B_SUB2DEC_A_WrAck : std_logic;

  signal B_DEC2SUB_B_Addr  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal B_DEC2SUB_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal B_DEC2SUB_B_RdCE  : std_logic;
  signal B_DEC2SUB_B_WrCE  : std_logic;
  signal B_SUB2DEC_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal B_SUB2DEC_B_RdAck : std_logic;
  signal B_SUB2DEC_B_WrAck : std_logic;

begin

  BUS_ADAPTER : entity user_logic
    generic map
    (
      C_IPIF_ARD_ADDR_RANGE_ARRAY => C_IPIF_ARD_ADDR_RANGE_ARRAY,
      C_HWIF_IF_COUNT             => C_HWIF_IF_COUNT,
      C_HWIF_ADDRESS_SPACE_BITS   => C_HWIF_ADDRESS_SPACE_BITS,
      C_SLV_AWIDTH                => C_SLV_AWIDTH,
      C_SLV_DWIDTH                => C_SLV_DWIDTH,
      C_NUM_MEM                   => C_NUM_MEM
      )
    port map
    (

      IP2HWT_Addr_A  => IP2HWT_Addr_A,
      IP2HWT_Data_A  => IP2HWT_Data_A,
      IP2HWT_RdCE_A  => IP2HWT_RdCE_A,
      IP2HWT_WrCE_A  => IP2HWT_WrCE_A,
      HWT2IP_Data_A  => HWT2IP_Data_A,
      HWT2IP_RdAck_A => HWT2IP_RdAck_A,
      HWT2IP_WrAck_A => HWT2IP_WrAck_A,

      IP2HWT_Addr_B  => IP2HWT_Addr_B,
      IP2HWT_Data_B  => IP2HWT_Data_B,
      IP2HWT_RdCE_B  => IP2HWT_RdCE_B,
      IP2HWT_WrCE_B  => IP2HWT_WrCE_B,
      HWT2IP_Data_B  => HWT2IP_Data_B,
      HWT2IP_RdAck_B => HWT2IP_RdAck_B,
      HWT2IP_WrAck_B => HWT2IP_WrAck_B,

      IP2HWT_Addr_C  => open,
      IP2HWT_Data_C  => open,
      IP2HWT_RdCE_C  => open,
      IP2HWT_WrCE_C  => open,
      HWT2IP_Data_C  => (others => '0'),
      HWT2IP_RdAck_C => '0',
      HWT2IP_WrAck_C => '0',

      IP2HWT_Addr_D  => open,
      IP2HWT_Data_D  => open,
      IP2HWT_RdCE_D  => open,
      IP2HWT_WrCE_D  => open,
      HWT2IP_Data_D  => (others => '0'),
      HWT2IP_RdAck_D => '0',
      HWT2IP_WrAck_D => '0',

      IP2HWT_Addr_E  => open,
      IP2HWT_Data_E  => open,
      IP2HWT_RdCE_E  => open,
      IP2HWT_WrCE_E  => open,
      HWT2IP_Data_E  => (others => '0'),
      HWT2IP_RdAck_E => '0',
      HWT2IP_WrAck_E => '0',

      IP2HWT_Addr_F  => open,
      IP2HWT_Data_F  => open,
      IP2HWT_RdCE_F  => open,
      IP2HWT_WrCE_F  => open,
      HWT2IP_Data_F  => (others => '0'),
      HWT2IP_RdAck_F => '0',
      HWT2IP_WrAck_F => '0',

      IP2HWT_Addr_G  => open,
      IP2HWT_Data_G  => open,
      IP2HWT_RdCE_G  => open,
      IP2HWT_WrCE_G  => open,
      HWT2IP_Data_G  => (others => '0'),
      HWT2IP_RdAck_G => '0',
      HWT2IP_WrAck_G => '0',

      IP2HWT_Addr_H  => open,
      IP2HWT_Data_H  => open,
      IP2HWT_RdCE_H  => open,
      IP2HWT_WrCE_H  => open,
      HWT2IP_Data_H  => (others => '0'),
      HWT2IP_RdAck_H => '0',
      HWT2IP_WrAck_H => '0',

      IP2HWT_Addr_I  => open,
      IP2HWT_Data_I  => open,
      IP2HWT_RdCE_I  => open,
      IP2HWT_WrCE_I  => open,
      HWT2IP_Data_I  => (others => '0'),
      HWT2IP_RdAck_I => '0',
      HWT2IP_WrAck_I => '0',

      IP2HWT_Addr_J  => open,
      IP2HWT_Data_J  => open,
      IP2HWT_RdCE_J  => open,
      IP2HWT_WrCE_J  => open,
      HWT2IP_Data_J  => (others => '0'),
      HWT2IP_RdAck_J => '0',
      HWT2IP_WrAck_J => '0',

      IP2HWT_Addr_K  => open,
      IP2HWT_Data_K  => open,
      IP2HWT_RdCE_K  => open,
      IP2HWT_WrCE_K  => open,
      HWT2IP_Data_K  => (others => '0'),
      HWT2IP_RdAck_K => '0',
      HWT2IP_WrAck_K => '0',

      IP2HWT_Addr_L  => open,
      IP2HWT_Data_L  => open,
      IP2HWT_RdCE_L  => open,
      IP2HWT_WrCE_L  => open,
      HWT2IP_Data_L  => (others => '0'),
      HWT2IP_RdAck_L => '0',
      HWT2IP_WrAck_L => '0',

      IP2HWT_Addr_M  => open,
      IP2HWT_Data_M  => open,
      IP2HWT_RdCE_M  => open,
      IP2HWT_WrCE_M  => open,
      HWT2IP_Data_M  => (others => '0'),
      HWT2IP_RdAck_M => '0',
      HWT2IP_WrAck_M => '0',

      IP2HWT_Addr_N  => open,
      IP2HWT_Data_N  => open,
      IP2HWT_RdCE_N  => open,
      IP2HWT_WrCE_N  => open,
      HWT2IP_Data_N  => (others => '0'),
      HWT2IP_RdAck_N => '0',
      HWT2IP_WrAck_N => '0',

      Bus2IP_Clk    => Bus2IP_Clk,
      Bus2IP_Reset  => Bus2IP_Reset,
      Bus2IP_Addr   => Bus2IP_Addr,
      Bus2IP_Data   => Bus2IP_Data,
      Bus2IP_BE     => Bus2IP_BE,
      Bus2IP_CS     => Bus2IP_CS,
      Bus2IP_RNW    => Bus2IP_RNW,
      IP2Bus_Data   => IP2Bus_Data,
      IP2Bus_RdAck  => IP2Bus_RdAck,
      IP2Bus_WrAck  => IP2Bus_WrAck,
      IP2Bus_Error  => IP2Bus_Error
      );

-- hwif_address_decoder_0
  ad0 : entity hwif_address_decoder
    generic map (
      C_ADDR_RANGE_ARRAY => C_ADDR_RANGE_ARRAY_A,
      C_SLV_DWIDTH       => 32
      )
    port map(
      -- HWIF interface
      HWIF2DEC_Addr  => IP2HWT_Addr_A,
      HWIF2DEC_Data  => IP2HWT_Data_A,
      HWIF2DEC_RdCE  => IP2HWT_RdCE_A,
      HWIF2DEC_WrCE  => IP2HWT_WrCE_A,
      DEC2HWIF_Data  => HWT2IP_Data_A,
      DEC2HWIF_RdAck => HWT2IP_RdAck_A,
      DEC2HWIF_WrAck => HWT2IP_WrAck_A,

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

-- hwif_address_decoder_1
  ad2 : entity hwif_address_decoder
    generic map (
      C_ADDR_RANGE_ARRAY => C_ADDR_RANGE_ARRAY_B,
      C_SLV_DWIDTH       => 32
      )
    port map(
      -- HWIF interface
      HWIF2DEC_Addr  => IP2HWT_Addr_B,
      HWIF2DEC_Data  => IP2HWT_Data_B,
      HWIF2DEC_RdCE  => IP2HWT_RdCE_B,
      HWIF2DEC_WrCE  => IP2HWT_WrCE_B,
      DEC2HWIF_Data  => HWT2IP_Data_B,
      DEC2HWIF_RdAck => HWT2IP_RdAck_B,
      DEC2HWIF_WrAck => HWT2IP_WrAck_B,

      -- sub-module interfaces
      DEC2SUB_A_Addr  => B_DEC2SUB_A_Addr,
      DEC2SUB_A_Data  => B_DEC2SUB_A_Data,
      DEC2SUB_A_RdCE  => B_DEC2SUB_A_RdCE,
      DEC2SUB_A_WrCE  => B_DEC2SUB_A_WrCE,
      SUB2DEC_A_Data  => B_SUB2DEC_A_Data,
      SUB2DEC_A_RdAck => B_SUB2DEC_A_RdAck,
      SUB2DEC_A_WrAck => B_SUB2DEC_A_WrAck,

      DEC2SUB_B_Addr  => B_DEC2SUB_B_Addr,
      DEC2SUB_B_Data  => B_DEC2SUB_B_Data,
      DEC2SUB_B_RdCE  => B_DEC2SUB_B_RdCE,
      DEC2SUB_B_WrCE  => B_DEC2SUB_B_WrCE,
      SUB2DEC_B_Data  => B_SUB2DEC_B_Data,
      SUB2DEC_B_RdAck => B_SUB2DEC_B_RdAck,
      SUB2DEC_B_WrAck => B_SUB2DEC_B_WrAck,

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
      C_HWT_ID       => X"AAAAAAAA",    -- Unique ID number of this module
      C_VERSION      => X"00000001",    -- Version Identifier
      C_CAPABILITIES => X"aaaaaaaa",  --Every Bit specifies a capability like performance monitoring etc.

      C_SLV_DWIDTH => 32
      )
    port map (
      IP2HWT_Addr  => A_DEC2SUB_A_Addr,
      IP2HWT_Data  => A_DEC2SUB_A_Data,
      IP2HWT_RdCE  => A_DEC2SUB_A_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_A_WrCE,
      HWT2IP_Data  => A_SUB2DEC_A_Data,
      HWT2IP_RdAck => A_SUB2DEC_A_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_A_WrAck,
      clk          => Bus2IP_Clk,
      rst          => Bus2IP_Reset
      );

-- Performance monitor 0
  perfmon_0 : entity perfmon
    generic map(
      C_Counters_Num => C_Counters_Num
      )
    port map (
      IP2HWT_Addr  => A_DEC2SUB_B_Addr,
      IP2HWT_Data  => A_DEC2SUB_B_Data,
      IP2HWT_RdCE  => A_DEC2SUB_B_RdCE,
      IP2HWT_WrCE  => A_DEC2SUB_B_WrCE,
      HWT2IP_Data  => A_SUB2DEC_B_Data,
      HWT2IP_RdAck => A_SUB2DEC_B_RdAck,
      HWT2IP_WrAck => A_SUB2DEC_B_WrAck,
      increments   => increments_A,
      clk          => Bus2IP_Clk,
      rst          => Bus2IP_Reset
      );

-- ID register_1
  id_1 : entity identification
    generic map (
      C_HWT_ID       => X"BBBBBBBB",    -- Unique ID number of this module
      C_VERSION      => X"00000002",    -- Version Identifier
      C_CAPABILITIES => X"55555555",  --Every Bit specifies a capability like performance monitoring etc.

      C_SLV_DWIDTH => 32
      )
    port map (
      IP2HWT_Addr  => B_DEC2SUB_A_Addr,
      IP2HWT_Data  => B_DEC2SUB_A_Data,
      IP2HWT_RdCE  => B_DEC2SUB_A_RdCE,
      IP2HWT_WrCE  => B_DEC2SUB_A_WrCE,
      HWT2IP_Data  => B_SUB2DEC_A_Data,
      HWT2IP_RdAck => B_SUB2DEC_A_RdAck,
      HWT2IP_WrAck => B_SUB2DEC_A_WrAck,
      clk          => Bus2IP_Clk,
      rst          => Bus2IP_Reset
      );
-- Performance monitor 1
  perfmon_1 : entity perfmon
    generic map(
      C_Counters_Num => C_Counters_Num
      )
    port map (
      IP2HWT_Addr  => B_DEC2SUB_B_Addr,
      IP2HWT_Data  => B_DEC2SUB_B_Data,
      IP2HWT_RdCE  => B_DEC2SUB_B_RdCE,
      IP2HWT_WrCE  => B_DEC2SUB_B_WrCE,
      HWT2IP_Data  => B_SUB2DEC_B_Data,
      HWT2IP_RdAck => B_SUB2DEC_B_RdAck,
      HWT2IP_WrAck => B_SUB2DEC_B_WrAck,
      increments   => increments_B,
      clk          => Bus2IP_Clk,
      rst          => Bus2IP_Reset
      );

end Behavioral;

