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

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;

entity tb_hwif_gpio is
end tb_hwif_gpio;

architecture behavior of tb_hwif_gpio is

  -- Component Declaration for the Unit Under Test (UUT)
  constant C_Bits_Out_Num : integer := 64;
  constant C_Bits_In_Num : integer := 64;
                                      
  constant C_id_reg_addr : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_config_reg_addr : natural := 2;
  constant C_Fixed_Reg_Count : natural := 3;

  constant C_GPOUT_REG : natural := 3;
  constant C_GPIN_REG : natural := 4;
  
   -- One Register holds 32 individual bits. For more than 32 Bits we need
  -- additional registers. 
  constant C_Registers_Out_Num : positive := (((C_Bits_Out_Num-1)/32)+1);
  constant C_Registers_In_Num : positive := (((C_Bits_In_Num-1)/32)+1);
  constant C_Registers_Num : positive := C_Registers_Out_Num + C_Registers_In_Num;
  
  component hwif_gpio
   generic(
    C_Bits_Out_Num : positive := 32;  -- How many outgoing bits (write only) do you want?
    C_Bits_In_Num : positive := 32;  -- How many ingoing bits (read only) do you want?
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
      gpio_out     : out std_logic_vector (C_Bits_Out_Num-1 downto 0);
      gpio_in      : in  std_logic_vector (C_Bits_In_Num-1 downto 0);
      clk          : in  std_logic;
      rst          : in  std_logic
      );
  end component;


  --Inputs
  signal tb_IP2HWT_Addr : std_logic_vector(0 to 31)                   := (others => '0');
  signal tb_IP2HWT_Data : std_logic_vector(31 downto 0)               := (others => '0');
  signal tb_IP2HWT_RdCE : std_logic                                   := '0';
  signal tb_IP2HWT_WrCE : std_logic                                   := '0';
  signal tb_clk         : std_logic                                   := '0';
  signal tb_rst         : std_logic                                   := '0';

  --Outputs
  signal tb_HWT2IP_Data  : std_logic_vector(31 downto 0);
  signal tb_HWT2IP_RdAck : std_logic;
  signal tb_HWT2IP_WrAck : std_logic;

  signal tb_gpio_out     : std_logic_vector (C_Bits_Out_Num-1 downto 0);
  signal tb_gpio_in      : std_logic_vector (C_Bits_In_Num-1 downto 0);
  
  -- Clock period definitions
  constant clk_period : time := 10 ns;

  signal test_desc : string(1 to 16) := "None            ";
  
begin

  -- Instantiate the Unit Under Test (UUT)
  uut : hwif_gpio
    generic map(
      C_Bits_Out_Num => C_Bits_Out_Num,
      C_Bits_In_Num  => C_Bits_In_Num
      )
    port map (
      IP2HWT_Addr  => tb_IP2HWT_Addr,
      IP2HWT_Data  => tb_IP2HWT_Data,
      IP2HWT_RdCE  => tb_IP2HWT_RdCE,
      IP2HWT_WrCE  => tb_IP2HWT_WrCE,
      HWT2IP_Data  => tb_HWT2IP_Data,
      HWT2IP_RdAck => tb_HWT2IP_RdAck,
      HWT2IP_WrAck => tb_HWT2IP_WrAck,
      gpio_out     => tb_gpio_out,
      gpio_in     => tb_gpio_in,      
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

    test_desc      <= "Read ID reg     ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_id_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000000";
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 20*clk_period;

    test_desc      <= "Read size reg   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_size_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 20 *clk_period;

    test_desc      <= "Read conf reg   ";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_config_reg_addr*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000000";
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 20 *clk_period;

    test_desc      <= "Set GP out reg 1";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_GPOUT_REG*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"AAAAAAAA";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 20*clk_period;

    test_desc      <= "Set GP out reg 2";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_GPOUT_REG*4, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"55555555";
    tb_IP2HWT_WrCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_WrCE <= '0';
    wait for 20*clk_period;

    test_desc      <= "Read GPIN reg  1";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_GPIN_REG, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000000";
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 20 *clk_period;

    test_desc      <= "Read GPIN reg  2";
    tb_IP2HWT_Addr <= std_logic_vector(to_unsigned(C_GPIN_REG, tb_IP2HWT_Addr'length));
    tb_IP2HWT_Data <= X"00000000";
    tb_IP2HWT_RdCE <= '1';
    wait for clk_period;
    tb_IP2HWT_Addr <= (others => '0');
    tb_IP2HWT_Data <= (others => '0');
    tb_IP2HWT_RdCE <= '0';
    wait for 20 *clk_period;
    
    test_desc <= "end of testbench";
    wait;
  end process;

  -- Generate some input for the gpio in signals
    performance_input_i : process
    begin
      tb_gpio_in <= (others => '0');
      wait for 13*clk_period;
      tb_gpio_in <= (others => '1');
      wait for 23*clk_period;
    end process;
    


end;
