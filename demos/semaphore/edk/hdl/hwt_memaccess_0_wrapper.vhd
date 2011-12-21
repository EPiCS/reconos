-------------------------------------------------------------------------------
-- hwt_memaccess_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library hwt_memaccess_v1_00_a;
use hwt_memaccess_v1_00_a.all;

entity hwt_memaccess_0_wrapper is
  port (
    OSFSL_Clk : in std_logic;
    OSFSL_Rst : in std_logic;
    OSFSL_S_Clk : out std_logic;
    OSFSL_S_Read : out std_logic;
    OSFSL_S_Data : in std_logic_vector(0 to 31);
    OSFSL_S_Control : in std_logic;
    OSFSL_S_Exists : in std_logic;
    OSFSL_M_Clk : out std_logic;
    OSFSL_M_Write : out std_logic;
    OSFSL_M_Data : out std_logic_vector(0 to 31);
    OSFSL_M_Control : out std_logic;
    OSFSL_M_Full : in std_logic;
    FIFO32_S_Clk : out std_logic;
    FIFO32_S_Data : in std_logic_vector(0 to 31);
    FIFO32_S_Rd : out std_logic;
    FIFO32_S_Fill : in std_logic_vector(0 to 15);
    FIFO32_M_Clk : out std_logic;
    FIFO32_M_Data : out std_logic_vector(0 to 31);
    FIFO32_M_Wr : out std_logic;
    FIFO32_M_Rem : in std_logic_vector(0 to 15);
    Rst : in std_logic
  );
end hwt_memaccess_0_wrapper;

architecture STRUCTURE of hwt_memaccess_0_wrapper is

  component hwt_memaccess is
    port (
      OSFSL_Clk : in std_logic;
      OSFSL_Rst : in std_logic;
      OSFSL_S_Clk : out std_logic;
      OSFSL_S_Read : out std_logic;
      OSFSL_S_Data : in std_logic_vector(0 to 31);
      OSFSL_S_Control : in std_logic;
      OSFSL_S_Exists : in std_logic;
      OSFSL_M_Clk : out std_logic;
      OSFSL_M_Write : out std_logic;
      OSFSL_M_Data : out std_logic_vector(0 to 31);
      OSFSL_M_Control : out std_logic;
      OSFSL_M_Full : in std_logic;
      FIFO32_S_Clk : out std_logic;
      FIFO32_S_Data : in std_logic_vector(0 to 31);
      FIFO32_S_Rd : out std_logic;
      FIFO32_S_Fill : in std_logic_vector(0 to 15);
      FIFO32_M_Clk : out std_logic;
      FIFO32_M_Data : out std_logic_vector(0 to 31);
      FIFO32_M_Wr : out std_logic;
      FIFO32_M_Rem : in std_logic_vector(0 to 15);
      Rst : in std_logic
    );
  end component;

begin

  hwt_memaccess_0 : hwt_memaccess
    port map (
      OSFSL_Clk => OSFSL_Clk,
      OSFSL_Rst => OSFSL_Rst,
      OSFSL_S_Clk => OSFSL_S_Clk,
      OSFSL_S_Read => OSFSL_S_Read,
      OSFSL_S_Data => OSFSL_S_Data,
      OSFSL_S_Control => OSFSL_S_Control,
      OSFSL_S_Exists => OSFSL_S_Exists,
      OSFSL_M_Clk => OSFSL_M_Clk,
      OSFSL_M_Write => OSFSL_M_Write,
      OSFSL_M_Data => OSFSL_M_Data,
      OSFSL_M_Control => OSFSL_M_Control,
      OSFSL_M_Full => OSFSL_M_Full,
      FIFO32_S_Clk => FIFO32_S_Clk,
      FIFO32_S_Data => FIFO32_S_Data,
      FIFO32_S_Rd => FIFO32_S_Rd,
      FIFO32_S_Fill => FIFO32_S_Fill,
      FIFO32_M_Clk => FIFO32_M_Clk,
      FIFO32_M_Data => FIFO32_M_Data,
      FIFO32_M_Wr => FIFO32_M_Wr,
      FIFO32_M_Rem => FIFO32_M_Rem,
      Rst => Rst
    );

end architecture STRUCTURE;

