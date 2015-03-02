--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:58:59 07/24/2014
-- Design Name:   
-- Module Name:   /home/meise/git/reconos_epics/pcores/fifo32_arbiter_v1_00_b/hdl/vhdl/tb_fifo32_peek.vhd
-- Project Name:  fifo32_peek
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo32_peek
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

entity tb_fifo32_peek is
end tb_fifo32_peek;

architecture behavior of tb_fifo32_peek is
  
  constant C_FIFO32_PEEK_DEPTH : integer := 2;
  -- Component Declaration for the Unit Under Test (UUT)

  component fifo32_peek
    generic (
      C_FIFO32_PEEK_DEPTH : integer := C_FIFO32_PEEK_DEPTH
      );
    port (
      Rst          : in std_logic;
      FIFO32_S_Clk : in std_logic;
      FIFO32_M_Clk : in std_logic;

      -- Active side: fetches data from fifo
      FIFO32_S_IN_Data : in  std_logic_vector(31 downto 0);
      FIFO32_S_IN_Fill : in  std_logic_vector(15 downto 0);
      FIFO32_S_OUT_Rd  : out std_logic;

      -- passive side: will provide data on FIFO32_S_Rd = '1'
      FIFO32_S_OUT_Data : out std_logic_vector(31 downto 0);
      FIFO32_S_OUT_Fill : out std_logic_vector(15 downto 0);
      FIFO32_S_IN_Rd    : in  std_logic;

      FIFO32_PEEK_DATA      : out std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0);
      FIFO32_PEEK_DATA_FILL : out std_logic_vector(15 downto 0)
      );
  end component;


  --Inputs
  signal Rst              : std_logic                     := '0';
  signal FIFO32_S_Clk     : std_logic                     := '0';
  signal FIFO32_M_Clk     : std_logic                     := '0';
  signal FIFO32_S_IN_Data : std_logic_vector(31 downto 0) := (others => '0');
  signal FIFO32_S_IN_Fill : std_logic_vector(15 downto 0) := (others => '0');
  signal FIFO32_S_IN_Rd   : std_logic                     := '0';

  --Outputs
  signal FIFO32_S_OUT_Rd       : std_logic;
  signal FIFO32_S_OUT_Data     : std_logic_vector(31 downto 0);
  signal FIFO32_S_OUT_Fill     : std_logic_vector(15 downto 0);
  signal FIFO32_PEEK_DATA      : std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0);
  signal FIFO32_PEEK_DATA_FILL : std_logic_vector(15 downto 0);

  signal data_left : std_logic_vector(15 downto 0);

  -- Clock period definitions
  constant FIFO32_S_Clk_period : time := 10 ns;
  constant FIFO32_M_Clk_period : time := 10 ns;
  
begin

  -- Instantiate the Unit Under Test (UUT)
  uut : fifo32_peek port map (
    Rst                   => Rst,
    FIFO32_S_Clk          => FIFO32_S_Clk,
    FIFO32_M_Clk          => FIFO32_M_Clk,
    FIFO32_S_IN_Data      => FIFO32_S_IN_Data,
    FIFO32_S_IN_Fill      => FIFO32_S_IN_Fill,
    FIFO32_S_OUT_Rd       => FIFO32_S_OUT_Rd,
    FIFO32_S_OUT_Data     => FIFO32_S_OUT_Data,
    FIFO32_S_OUT_Fill     => FIFO32_S_OUT_Fill,
    FIFO32_S_IN_Rd        => FIFO32_S_IN_Rd,
    FIFO32_PEEK_DATA      => FIFO32_PEEK_DATA,
    FIFO32_PEEK_DATA_FILL => FIFO32_PEEK_DATA_FILL
    );

  -- Clock process definitions
  FIFO32_S_Clk_process : process
  begin
    FIFO32_S_Clk <= '1';
    wait for FIFO32_S_Clk_period/2;
    FIFO32_S_Clk <= '0';
    wait for FIFO32_S_Clk_period/2;
  end process;

  FIFO32_M_Clk_process : process
  begin
    FIFO32_M_Clk <= '1';
    wait for FIFO32_M_Clk_period/2;
    FIFO32_M_Clk <= '0';
    wait for FIFO32_M_Clk_period/2;
  end process;

  FIFO32_S_IN_Fill <= data_left;
  source_proc : process(FIFO32_S_Clk, rst)
    type src_state_t is (START, RISE, HOLD, FALL, STOP);
    variable src_state : src_state_t;
  begin
    if rst = '1' then
      src_state        := START;
      FIFO32_S_IN_Data <= (0      => '1', others => '0');
      -- set incoming fifo level to maximum to see if fifo32_peek fill does not
      -- overflow. If fill is > 0 and peek module is not full, peek module will
      -- read in data.
      data_left        <= (others => '0');
    elsif FIFO32_S_Clk'event and FIFO32_S_Clk = '1' then
      case src_state is
        when START =>
          -- idle phase, uses data signals as counter for time measurement.
          FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+1);
          if FIFO32_S_IN_Data = X"0000000F" then
            src_state        := RISE;
            FIFO32_S_IN_Data <= (0 => '1', others => '0');
            data_left        <= (0 => '1', others => '0');
          end if;
          
        when RISE =>
          data_left <= std_logic_vector(unsigned(data_left)+1);
          if FIFO32_S_OUT_Rd = '1' then
            FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+1);
          end if;
          if data_left = X"000F" then
            src_state := HOLD;
          end if;
          
        when HOLD =>
          if FIFO32_S_OUT_Rd = '1' then
            FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+1);
            -- data_left jumps to maximum value to test overflow handling of
            -- peek module.
            data_left        <= (others => '1');
          end if;
          if FIFO32_S_IN_Data = X"0000001F" then
            src_state := FALL;
          end if;
          
        when FALL =>
          if FIFO32_S_OUT_Rd = '1' then
            FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+1);
            data_left        <= std_logic_vector(unsigned(data_left)-1);
          end if;
          -- Shortcut: dont want to wait for all 16k words to be transferred 
          if data_left = X"FFF0" then
            data_left <= X"000F";
          end if;

          if data_left = X"0001" then
            src_state := STOP;
          end if;

        when STOP =>
          data_left        <= X"0000";
          FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+0);
        when others => null;
      end case;
    end if;
  end process;


  sink_proc : process(FIFO32_S_Clk, rst)
  begin
    if rst = '1' then
      null;
    elsif FIFO32_S_Clk'event and FIFO32_S_Clk = '1' then
      if FIFO32_S_OUT_Fill /= X"0000" then
        FIFO32_S_IN_Rd <= '1';
      else
        FIFO32_S_IN_Rd <= '0';
      end if;
    end if;
  end process;

  reset_proc : process
  begin
    -- hold reset state for 100 ns.
    rst <= '1';
    wait for FIFO32_S_Clk_period*10;
    rst <= '0';
    wait;
  end process;

end;
