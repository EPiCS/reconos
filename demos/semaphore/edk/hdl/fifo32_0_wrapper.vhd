-------------------------------------------------------------------------------
-- fifo32_0_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library fifo32_v1_00_a;
use fifo32_v1_00_a.all;

entity fifo32_0_wrapper is
  port (
    Rst : in std_logic;
    FIFO32_S_Clk : in std_logic;
    FIFO32_S_Data : out std_logic_vector(0 to 31);
    FIFO32_S_Rd : in std_logic;
    FIFO32_S_Fill : out std_logic_vector(0 to 15);
    FIFO32_M_Clk : in std_logic;
    FIFO32_M_Data : in std_logic_vector(0 to 31);
    FIFO32_M_Wr : in std_logic;
    FIFO32_M_Rem : out std_logic_vector(0 to 15)
  );
end fifo32_0_wrapper;

architecture STRUCTURE of fifo32_0_wrapper is

  component fifo32 is
    generic (
      C_FIFO32_DEPTH : INTEGER
    );
    port (
      Rst : in std_logic;
      FIFO32_S_Clk : in std_logic;
      FIFO32_S_Data : out std_logic_vector(0 to 31);
      FIFO32_S_Rd : in std_logic;
      FIFO32_S_Fill : out std_logic_vector(0 to 15);
      FIFO32_M_Clk : in std_logic;
      FIFO32_M_Data : in std_logic_vector(0 to 31);
      FIFO32_M_Wr : in std_logic;
      FIFO32_M_Rem : out std_logic_vector(0 to 15)
    );
  end component;

begin

  fifo32_0 : fifo32
    generic map (
      C_FIFO32_DEPTH => 1024
    )
    port map (
      Rst => Rst,
      FIFO32_S_Clk => FIFO32_S_Clk,
      FIFO32_S_Data => FIFO32_S_Data,
      FIFO32_S_Rd => FIFO32_S_Rd,
      FIFO32_S_Fill => FIFO32_S_Fill,
      FIFO32_M_Clk => FIFO32_M_Clk,
      FIFO32_M_Data => FIFO32_M_Data,
      FIFO32_M_Wr => FIFO32_M_Wr,
      FIFO32_M_Rem => FIFO32_M_Rem
    );

end architecture STRUCTURE;

