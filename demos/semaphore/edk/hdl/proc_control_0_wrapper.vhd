-------------------------------------------------------------------------------
-- proc_control_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library proc_control_v1_00_a;
use proc_control_v1_00_a.all;

entity proc_control_0_wrapper is
  port (
    FSL_Clk : in std_logic;
    FSL_Rst : in std_logic;
    FSL_S_Clk : out std_logic;
    FSL_S_Read : out std_logic;
    FSL_S_Data : in std_logic_vector(0 to 31);
    FSL_S_Control : in std_logic;
    FSL_S_Exists : in std_logic;
    FSL_M_Clk : out std_logic;
    FSL_M_Write : out std_logic;
    FSL_M_Data : out std_logic_vector(0 to 31);
    FSL_M_Control : out std_logic;
    FSL_M_Full : in std_logic;
    reset0 : out std_logic;
    reset1 : out std_logic;
    reset2 : out std_logic;
    reset3 : out std_logic;
    reset4 : out std_logic;
    reset5 : out std_logic;
    reset6 : out std_logic;
    reset7 : out std_logic;
    reset8 : out std_logic;
    reset9 : out std_logic;
    resetA : out std_logic;
    resetB : out std_logic;
    resetC : out std_logic;
    resetD : out std_logic;
    resetE : out std_logic;
    resetF : out std_logic;
    page_fault : in std_logic;
    fault_addr : in std_logic_vector(0 to 31);
    retry : out std_logic;
    pgd : out std_logic_vector(0 to 31);
    reconos_reset : out std_logic
  );
end proc_control_0_wrapper;

architecture STRUCTURE of proc_control_0_wrapper is

  component proc_control is
    port (
      FSL_Clk : in std_logic;
      FSL_Rst : in std_logic;
      FSL_S_Clk : out std_logic;
      FSL_S_Read : out std_logic;
      FSL_S_Data : in std_logic_vector(0 to 31);
      FSL_S_Control : in std_logic;
      FSL_S_Exists : in std_logic;
      FSL_M_Clk : out std_logic;
      FSL_M_Write : out std_logic;
      FSL_M_Data : out std_logic_vector(0 to 31);
      FSL_M_Control : out std_logic;
      FSL_M_Full : in std_logic;
      reset0 : out std_logic;
      reset1 : out std_logic;
      reset2 : out std_logic;
      reset3 : out std_logic;
      reset4 : out std_logic;
      reset5 : out std_logic;
      reset6 : out std_logic;
      reset7 : out std_logic;
      reset8 : out std_logic;
      reset9 : out std_logic;
      resetA : out std_logic;
      resetB : out std_logic;
      resetC : out std_logic;
      resetD : out std_logic;
      resetE : out std_logic;
      resetF : out std_logic;
      page_fault : in std_logic;
      fault_addr : in std_logic_vector(0 to 31);
      retry : out std_logic;
      pgd : out std_logic_vector(0 to 31);
      reconos_reset : out std_logic
    );
  end component;

begin

  proc_control_0 : proc_control
    port map (
      FSL_Clk => FSL_Clk,
      FSL_Rst => FSL_Rst,
      FSL_S_Clk => FSL_S_Clk,
      FSL_S_Read => FSL_S_Read,
      FSL_S_Data => FSL_S_Data,
      FSL_S_Control => FSL_S_Control,
      FSL_S_Exists => FSL_S_Exists,
      FSL_M_Clk => FSL_M_Clk,
      FSL_M_Write => FSL_M_Write,
      FSL_M_Data => FSL_M_Data,
      FSL_M_Control => FSL_M_Control,
      FSL_M_Full => FSL_M_Full,
      reset0 => reset0,
      reset1 => reset1,
      reset2 => reset2,
      reset3 => reset3,
      reset4 => reset4,
      reset5 => reset5,
      reset6 => reset6,
      reset7 => reset7,
      reset8 => reset8,
      reset9 => reset9,
      resetA => resetA,
      resetB => resetB,
      resetC => resetC,
      resetD => resetD,
      resetE => resetE,
      resetF => resetF,
      page_fault => page_fault,
      fault_addr => fault_addr,
      retry => retry,
      pgd => pgd,
      reconos_reset => reconos_reset
    );

end architecture STRUCTURE;

