-------------------------------------------------------------------------------
-- fsl_v20_3_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library fsl_v20_v2_11_c;
use fsl_v20_v2_11_c.all;

entity fsl_v20_3_wrapper is
  port (
    FSL_Clk : in std_logic;
    SYS_Rst : in std_logic;
    FSL_Rst : out std_logic;
    FSL_M_Clk : in std_logic;
    FSL_M_Data : in std_logic_vector(0 to 31);
    FSL_M_Control : in std_logic;
    FSL_M_Write : in std_logic;
    FSL_M_Full : out std_logic;
    FSL_S_Clk : in std_logic;
    FSL_S_Data : out std_logic_vector(0 to 31);
    FSL_S_Control : out std_logic;
    FSL_S_Read : in std_logic;
    FSL_S_Exists : out std_logic;
    FSL_Full : out std_logic;
    FSL_Has_Data : out std_logic;
    FSL_Control_IRQ : out std_logic
  );

  attribute x_core_info : STRING;
  attribute x_core_info of fsl_v20_3_wrapper : entity is "fsl_v20_v2_11_c";

end fsl_v20_3_wrapper;

architecture STRUCTURE of fsl_v20_3_wrapper is

  component fsl_v20 is
    generic (
      C_EXT_RESET_HIGH : integer;
      C_ASYNC_CLKS : integer;
      C_IMPL_STYLE : integer;
      C_USE_CONTROL : integer;
      C_FSL_DWIDTH : integer;
      C_FSL_DEPTH : integer;
      C_READ_CLOCK_PERIOD : integer
    );
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to C_FSL_DWIDTH-1);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to C_FSL_DWIDTH-1);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

begin

  fsl_v20_3 : fsl_v20
    generic map (
      C_EXT_RESET_HIGH => 1,
      C_ASYNC_CLKS => 0,
      C_IMPL_STYLE => 0,
      C_USE_CONTROL => 0,
      C_FSL_DWIDTH => 32,
      C_FSL_DEPTH => 16,
      C_READ_CLOCK_PERIOD => 0
    )
    port map (
      FSL_Clk => FSL_Clk,
      SYS_Rst => SYS_Rst,
      FSL_Rst => FSL_Rst,
      FSL_M_Clk => FSL_M_Clk,
      FSL_M_Data => FSL_M_Data,
      FSL_M_Control => FSL_M_Control,
      FSL_M_Write => FSL_M_Write,
      FSL_M_Full => FSL_M_Full,
      FSL_S_Clk => FSL_S_Clk,
      FSL_S_Data => FSL_S_Data,
      FSL_S_Control => FSL_S_Control,
      FSL_S_Read => FSL_S_Read,
      FSL_S_Exists => FSL_S_Exists,
      FSL_Full => FSL_Full,
      FSL_Has_Data => FSL_Has_Data,
      FSL_Control_IRQ => FSL_Control_IRQ
    );

end architecture STRUCTURE;

