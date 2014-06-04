--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:28:22 12/05/2013
-- Design Name:   
-- Module Name:   /home/meise/temp/pcores/hwif_v1_00_a/hdl/vhdl/tb_perfmon.vhd
-- Project Name:  hwif
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: perfmon
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all;

library work;
use work.hwif_pck.all;

entity tb_perfmon is
end tb_perfmon;

architecture behavior of tb_perfmon is

  -- Component Declaration for the Unit Under Test (UUT)
  constant C_Counters_Num : integer := 8; 
                                      
constant C_id_reg_addr : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_config_reg_addr : natural := 2;
  constant C_Fixed_Reg_Count : natural := 3;

  component perfmon
    generic(
      C_Counters_Num : integer := C_Counters_Num;
      C_SLV_DWIDTH   : integer := 32
      );
    port(
      IP2HWT_Addr  : in  std_logic_vector(0 to 31);
      IP2HWT_Data  : in  std_logic_vector(31 downto 0);
      IP2HWT_RdCE  : in  std_logic;
      IP2HWT_WrCE  : in  std_logic;
      HWT2IP_Data  : out std_logic_vector(31 downto 0);
      HWT2IP_RdAck : out std_logic;
      HWT2IP_WrAck : out std_logic;
      increments   : in  std_logic_vector (C_Counters_Num-1 downto 0);
      clk          : in  std_logic;
      rst          : in  std_logic
      );
  end component;


  --Inputs
  signal tb_IP2HWT_Addr : std_logic_vector(0 to 31)                   := (others => '0');
  signal tb_IP2HWT_Data : std_logic_vector(31 downto 0)               := (others => '0');
  signal tb_IP2HWT_RdCE : std_logic                                   := '0';
  signal tb_IP2HWT_WrCE : std_logic                                   := '0';
  signal tb_increments  : std_logic_vector(C_Counters_Num-1 downto 0) := (others => '0');
  signal tb_clk         : std_logic                                   := '0';
  signal tb_rst         : std_logic                                   := '0';

  --Outputs
  signal tb_HWT2IP_Data  : std_logic_vector(31 downto 0);
  signal tb_HWT2IP_RdAck : std_logic;
  signal tb_HWT2IP_WrAck : std_logic;

  -- Clock period definitions
  constant clk_period : time := 10 ns;

  signal test_desc : string(1 to 16) := "None            ";
  
begin

  -- Instantiate the Unit Under Test (UUT)
  uut : perfmon
    generic map(
      C_Counters_Num => C_Counters_Num
      )
    port map (
      IP2HWT_Addr  => tb_IP2HWT_Addr,
      IP2HWT_Data  => tb_IP2HWT_Data,
      IP2HWT_RdCE  => tb_IP2HWT_RdCE,
      IP2HWT_WrCE  => tb_IP2HWT_WrCE,
      HWT2IP_Data  => tb_HWT2IP_Data,
      HWT2IP_RdAck => tb_HWT2IP_RdAck,
      HWT2IP_WrAck => tb_HWT2IP_WrAck,
      increments   => tb_increments,
      clk          => tb_clk,
      rst          => tb_rst
      );

  -- Clock process definitions
  clk_process : process
  begin
    tb_clk <= '1';
    wait for clk_period/2;
    tb_clk <= '0';
    wait for clk_period/2;
  end process;


  -- Stimulus process
  stim_proc : process
  begin
    -- set Defaults
    tb_IP2HWT_Addr <= (others=>'0');
    tb_IP2HWT_Data <= (others=>'0');
    tb_IP2HWT_RdCE <= '0';
    tb_IP2HWT_WrCE <= '0';

    -- hold reset state for 100 ns.
    tb_rst <= '1';
    wait for 100 ns;
    tb_rst <= '0';
    wait for clk_period*10;

    test_desc      <= "enable perfmon  ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000002";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 100*clk_period;

    -- disable perfmon
    test_desc      <= "disable perfmon ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 100 *clk_period;

    -- reset perfmon
    test_desc      <= "reset perfmon   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000001";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 100 *clk_period;

    -- enable perfmon
    test_desc      <= "enable perfmon  ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000002";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 100*clk_period;

    -- illegal write to counter register
    test_desc      <= "illegal write   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_Fixed_Reg_Count*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"DEADBEAF";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 100*clk_period;

    -- illegal read from undefined address 
    test_desc      <= "illegal read    ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned((C_Fixed_Reg_Count+C_Counters_Num)*4, tb_IP2HWT_Addr'length));  -- first illegal address
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 100*clk_period;
    
      -- read ID register
      test_desc <= "read ID reg     ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_ID_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 100*clk_period; 
      
      -- read size register
      test_desc <= "read size reg   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_size_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 100*clk_period; 

      -- read config register
      test_desc <= "read conf reg   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 100*clk_period;

    -- read counter register
    for i in C_Fixed_Reg_Count to C_Counters_Num+C_Fixed_Reg_Count-1 loop
      test_desc      <= "read count reg  ";
      tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(i*4, tb_IP2HWT_Addr'length));
      tb_IP2HWT_Data <= (others => '0');
      tb_IP2HWT_RdCE <= '1';
      wait for clk_period;
      tb_IP2HWT_Addr <= (others => '0');
      tb_IP2HWT_Data <= (others => '0');
      tb_IP2HWT_RdCE <= '0';
      wait for 100*clk_period;
    end loop;

    test_desc <= "end of testbench";
    wait;
  end process;

  -- Generate some input for the performance counters
  perfomance_inputs : for i in C_Counters_Num-1 downto 0 generate
    performance_input_i : process
    begin
      tb_increments(i) <= '0';
      wait for (i+1)*clk_period;
      tb_increments(i) <= '1';
      --wait;
      wait for (i+1)*clk_period;
    end process;
    
  end generate;

end;
