-------------------------------------------------------------------------------
-- mmu_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library mmu_v1_00_a;
use mmu_v1_00_a.all;

entity mmu_0_wrapper is
  port (
    HWT_FIFO32_S_Clk : out std_logic;
    HWT_FIFO32_S_Data : in std_logic_vector(0 to 31);
    HWT_FIFO32_S_Rd : out std_logic;
    HWT_FIFO32_S_Fill : in std_logic_vector(0 to 15);
    HWT_FIFO32_M_Clk : out std_logic;
    HWT_FIFO32_M_Data : out std_logic_vector(0 to 31);
    HWT_FIFO32_M_Wr : out std_logic;
    HWT_FIFO32_M_Rem : in std_logic_vector(0 to 15);
    MEM_FIFO32_S_Clk : in std_logic;
    MEM_FIFO32_S_Data : out std_logic_vector(0 to 31);
    MEM_FIFO32_S_Rd : in std_logic;
    MEM_FIFO32_S_Fill : out std_logic_vector(0 to 15);
    MEM_FIFO32_M_Clk : in std_logic;
    MEM_FIFO32_M_Data : in std_logic_vector(0 to 31);
    MEM_FIFO32_M_Wr : in std_logic;
    MEM_FIFO32_M_Rem : out std_logic_vector(0 to 15);
    RETRY : in std_logic;
    PAGE_FAULT : out std_logic;
    FAULT_ADDR : out std_logic_vector(0 to 31);
    PGD : in std_logic_vector(0 to 31);
    Rst : in std_logic;
    Clk : in std_logic
  );
end mmu_0_wrapper;

architecture STRUCTURE of mmu_0_wrapper is

  component mmu is
    generic (
      C_ENABLE_ILA : integer
    );
    port (
      HWT_FIFO32_S_Clk : out std_logic;
      HWT_FIFO32_S_Data : in std_logic_vector(0 to 31);
      HWT_FIFO32_S_Rd : out std_logic;
      HWT_FIFO32_S_Fill : in std_logic_vector(0 to 15);
      HWT_FIFO32_M_Clk : out std_logic;
      HWT_FIFO32_M_Data : out std_logic_vector(0 to 31);
      HWT_FIFO32_M_Wr : out std_logic;
      HWT_FIFO32_M_Rem : in std_logic_vector(0 to 15);
      MEM_FIFO32_S_Clk : in std_logic;
      MEM_FIFO32_S_Data : out std_logic_vector(0 to 31);
      MEM_FIFO32_S_Rd : in std_logic;
      MEM_FIFO32_S_Fill : out std_logic_vector(0 to 15);
      MEM_FIFO32_M_Clk : in std_logic;
      MEM_FIFO32_M_Data : in std_logic_vector(0 to 31);
      MEM_FIFO32_M_Wr : in std_logic;
      MEM_FIFO32_M_Rem : out std_logic_vector(0 to 15);
      RETRY : in std_logic;
      PAGE_FAULT : out std_logic;
      FAULT_ADDR : out std_logic_vector(0 to 31);
      PGD : in std_logic_vector(0 to 31);
      Rst : in std_logic;
      Clk : in std_logic
    );
  end component;

begin

  mmu_0 : mmu
    generic map (
      C_ENABLE_ILA => 0
    )
    port map (
      HWT_FIFO32_S_Clk => HWT_FIFO32_S_Clk,
      HWT_FIFO32_S_Data => HWT_FIFO32_S_Data,
      HWT_FIFO32_S_Rd => HWT_FIFO32_S_Rd,
      HWT_FIFO32_S_Fill => HWT_FIFO32_S_Fill,
      HWT_FIFO32_M_Clk => HWT_FIFO32_M_Clk,
      HWT_FIFO32_M_Data => HWT_FIFO32_M_Data,
      HWT_FIFO32_M_Wr => HWT_FIFO32_M_Wr,
      HWT_FIFO32_M_Rem => HWT_FIFO32_M_Rem,
      MEM_FIFO32_S_Clk => MEM_FIFO32_S_Clk,
      MEM_FIFO32_S_Data => MEM_FIFO32_S_Data,
      MEM_FIFO32_S_Rd => MEM_FIFO32_S_Rd,
      MEM_FIFO32_S_Fill => MEM_FIFO32_S_Fill,
      MEM_FIFO32_M_Clk => MEM_FIFO32_M_Clk,
      MEM_FIFO32_M_Data => MEM_FIFO32_M_Data,
      MEM_FIFO32_M_Wr => MEM_FIFO32_M_Wr,
      MEM_FIFO32_M_Rem => MEM_FIFO32_M_Rem,
      RETRY => RETRY,
      PAGE_FAULT => PAGE_FAULT,
      FAULT_ADDR => FAULT_ADDR,
      PGD => PGD,
      Rst => Rst,
      Clk => Clk
    );

end architecture STRUCTURE;

