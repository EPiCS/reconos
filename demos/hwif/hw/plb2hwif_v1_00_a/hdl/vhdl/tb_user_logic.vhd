-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library work;
use work.hwif_pck.all;
use work.user_logic;

entity tb_user_logic is
end;

architecture behavior of tb_user_logic is
  constant C_IPIF_ARD_ADDR_RANGE_ARRAY    : SLV64_ARRAY_TYPE     := ((others => '0'),(others => '1'));
  constant C_HWIF_IF_COUNT                : integer              := 16;
    -- Default: 16 Bit ^= 64Kbyte Address space per interface:
  constant C_HWIF_ADDRESS_SPACE_BITS      : integer              := 16;
  
  constant C_SLV_AWIDTH                   : integer              := 32;
  constant C_SLV_DWIDTH       : integer := 32;
  constant C_NUM_MEM                      : integer              := 1;
  
  signal tb_IP2HWT_Addr_A  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal tb_IP2HWT_Data_A  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_IP2HWT_RdCE_A  : std_logic;
  signal tb_IP2HWT_WrCE_A  : std_logic;
  signal tb_HWT2IP_Data_A  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_HWT2IP_RdAck_A : std_logic;
  signal tb_HWT2IP_WrAck_A : std_logic;

  signal tb_IP2HWT_Addr_B  : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal tb_IP2HWT_Data_B  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_IP2HWT_RdCE_B  : std_logic;
  signal tb_IP2HWT_WrCE_B  : std_logic;
  signal tb_HWT2IP_Data_B  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_HWT2IP_RdAck_B : std_logic;
  signal tb_HWT2IP_WrAck_B : std_logic;

  signal tb_Bus2IP_Clk    : std_logic;
  signal tb_Bus2IP_Reset : std_logic;
  signal tb_Bus2IP_Addr   : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal tb_Bus2IP_Data   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_Bus2IP_BE     : std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
  signal tb_Bus2IP_CS     : std_logic_vector(C_NUM_MEM-1 downto 0);
  signal tb_Bus2IP_RNW    : std_logic;
  signal tb_IP2Bus_Data   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_IP2Bus_RdAck  : std_logic;
  signal tb_IP2Bus_WrAck  : std_logic;
  signal tb_IP2Bus_Error  : std_logic;

  subtype register_t is std_logic_vector(31 downto 0);
  type register_bank_t is array (natural range<>) of std_logic_vector(31 downto 0);

  signal register_bank_A   : register_bank_t(0 to 16);
  signal register_bank_B   : register_bank_t(0 to 16);

  signal tb_desc : string(1 to 16) := "None            ";

 begin                                   -- of architecture

  -- Component Instantiation
  uut : entity user_logic
    generic map(
      C_IPIF_ARD_ADDR_RANGE_ARRAY    => C_IPIF_ARD_ADDR_RANGE_ARRAY,
      C_HWIF_IF_COUNT                => C_HWIF_IF_COUNT,
      C_HWIF_ADDRESS_SPACE_BITS      => C_HWIF_ADDRESS_SPACE_BITS,
      C_SLV_DWIDTH => C_SLV_DWIDTH
      )
    port map(

      IP2HWT_Addr_A => tb_IP2HWT_Addr_A,
      IP2HWT_Data_A => tb_IP2HWT_Data_A,
      IP2HWT_RdCE_A => tb_IP2HWT_RdCE_A,
      IP2HWT_WrCE_A => tb_IP2HWT_WrCE_A,
      HWT2IP_Data_A => tb_HWT2IP_Data_A,
      HWT2IP_RdAck_A=> tb_HWT2IP_RdAck_A,
      HWT2IP_WrAck_A=> tb_HWT2IP_WrAck_A,

      IP2HWT_Addr_B => tb_IP2HWT_Addr_B,
      IP2HWT_Data_B => tb_IP2HWT_Data_B,
      IP2HWT_RdCE_B => tb_IP2HWT_RdCE_B,
      IP2HWT_WrCE_B => tb_IP2HWT_WrCE_B,
      HWT2IP_Data_B => tb_HWT2IP_Data_B,
      HWT2IP_RdAck_B => tb_HWT2IP_RdAck_B,
      HWT2IP_WrAck_B => tb_HWT2IP_WrAck_B,

      IP2HWT_Addr_C => open,
      IP2HWT_Data_C => open,
      IP2HWT_RdCE_C => open,
      IP2HWT_WrCE_C => open,
      HWT2IP_Data_C => (others => '0'),
      HWT2IP_RdAck_C => '0',
      HWT2IP_WrAck_C => '0',

      IP2HWT_Addr_D => open,
      IP2HWT_Data_D => open,
      IP2HWT_RdCE_D => open,
      IP2HWT_WrCE_D => open,
      HWT2IP_Data_D => (others => '0'),
      HWT2IP_RdAck_D => '0',
      HWT2IP_WrAck_D => '0',

      IP2HWT_Addr_E => open,
      IP2HWT_Data_E => open,
      IP2HWT_RdCE_E => open,
      IP2HWT_WrCE_E => open,
      HWT2IP_Data_E => (others => '0'),
      HWT2IP_RdAck_E => '0',
      HWT2IP_WrAck_E => '0',

      IP2HWT_Addr_F => open,
      IP2HWT_Data_F => open,
      IP2HWT_RdCE_F => open,
      IP2HWT_WrCE_F => open,
      HWT2IP_Data_F => (others => '0'),
      HWT2IP_RdAck_F => '0',
      HWT2IP_WrAck_F => '0',

      IP2HWT_Addr_G => open,
      IP2HWT_Data_G => open,
      IP2HWT_RdCE_G => open,
      IP2HWT_WrCE_G => open,
      HWT2IP_Data_G => (others => '0'),
      HWT2IP_RdAck_G => '0',
      HWT2IP_WrAck_G => '0',

      IP2HWT_Addr_H => open,
      IP2HWT_Data_H => open,
      IP2HWT_RdCE_H => open,
      IP2HWT_WrCE_H => open,
      HWT2IP_Data_H => (others => '0'),
      HWT2IP_RdAck_H => '0',
      HWT2IP_WrAck_H => '0',

      IP2HWT_Addr_I => open,
      IP2HWT_Data_I => open,
      IP2HWT_RdCE_I => open,
      IP2HWT_WrCE_I => open,
      HWT2IP_Data_I => (others => '0'),
      HWT2IP_RdAck_I => '0',
      HWT2IP_WrAck_I => '0',

      IP2HWT_Addr_J => open,
      IP2HWT_Data_J => open,
      IP2HWT_RdCE_J => open,
      IP2HWT_WrCE_J => open,
      HWT2IP_Data_J => (others => '0'),
      HWT2IP_RdAck_J => '0',
      HWT2IP_WrAck_J => '0',

      IP2HWT_Addr_K => open,
      IP2HWT_Data_K => open,
      IP2HWT_RdCE_K => open,
      IP2HWT_WrCE_K => open,
      HWT2IP_Data_K => (others => '0'),
      HWT2IP_RdAck_K => '0',
      HWT2IP_WrAck_K => '0',

      IP2HWT_Addr_L => open,
      IP2HWT_Data_L => open,
      IP2HWT_RdCE_L => open,
      IP2HWT_WrCE_L => open,
      HWT2IP_Data_L => (others => '0'),
      HWT2IP_RdAck_L => '0',
      HWT2IP_WrAck_L => '0',

      IP2HWT_Addr_M => open,
      IP2HWT_Data_M => open,
      IP2HWT_RdCE_M => open,
      IP2HWT_WrCE_M => open,
      HWT2IP_Data_M => (others => '0'),
      HWT2IP_RdAck_M => '0',
      HWT2IP_WrAck_M => '0',

      IP2HWT_Addr_N => open,
      IP2HWT_Data_N => open,
      IP2HWT_RdCE_N => open,
      IP2HWT_WrCE_N => open,
      HWT2IP_Data_N => (others => '0'),
      HWT2IP_RdAck_N => '0',
      HWT2IP_WrAck_N => '0',
      
      Bus2IP_Clk    => tb_Bus2IP_Clk,
      Bus2IP_Reset  => tb_Bus2IP_Reset,
      Bus2IP_Addr   => tb_Bus2IP_Addr,
      Bus2IP_Data   => tb_Bus2IP_Data,
      Bus2IP_BE     => tb_Bus2IP_BE,
      Bus2IP_CS     => tb_Bus2IP_CS,
      Bus2IP_RNW    => tb_Bus2IP_RNW,
      IP2Bus_Data   => tb_IP2Bus_Data,
      IP2Bus_RdAck  => tb_IP2Bus_RdAck,
      IP2Bus_WrAck  => tb_IP2Bus_WrAck,
      IP2Bus_Error  => tb_IP2Bus_Error
      );

  port_a : process(tb_Bus2IP_Clk)
  begin
    if tb_BUS2IP_reset = '1' then
      register_bank_A <= (others => (others => '0'));
      tb_HWT2IP_Data_A <= (others => '0');
      tb_HWT2IP_RdAck_A <= '0';
      tb_HWT2IP_WrAck_A <= '0';
    elsif tb_Bus2IP_CLK'event and tb_Bus2IP_CLK = '1' then
      tb_HWT2IP_Data_A <= (others => '0');
      tb_HWT2IP_RdAck_A <= '0';
      tb_HWT2IP_WrAck_A <= '0';
      if (tb_ip2hwt_rdce_a or tb_ip2hwt_wrce_a) = '1' then
        if tb_ip2hwt_wrce_a = '1' then
          register_bank_A(to_integer(unsigned(tb_ip2hwt_addr_a(0 to C_SLV_AWIDTH-3)))) <= tb_ip2hwt_data_a;
          tb_hwt2ip_wrack_a                              <= '1';
        end if;
        if tb_ip2hwt_rdce_a = '1' then
          tb_hwt2ip_rdack_a <= '1';
        end if;
        tb_hwt2ip_data_a <= register_bank_A(to_integer(unsigned(tb_ip2hwt_addr_a(0 to C_SLV_AWIDTH-3))));
      end if;
    end if;
  end process;

 port_b : process(tb_Bus2IP_Clk)
  begin
    if tb_BUS2IP_reset = '1' then
      register_bank_b <= (others => (others => '0'));
      tb_HWT2IP_Data_b <= (others => '0');
      tb_HWT2IP_RdAck_b <= '0';
      tb_HWT2IP_WrAck_b <= '0';
    elsif tb_Bus2IP_CLK'event and tb_Bus2IP_CLK = '1' then
      tb_HWT2IP_Data_b <= (others => '0');
      tb_HWT2IP_RdAck_b <= '0';
      tb_HWT2IP_WrAck_b <= '0';
      if (tb_ip2hwt_rdce_b or tb_ip2hwt_wrce_b) = '1' then
        if tb_ip2hwt_wrce_b = '1' then
          register_bank_b(to_integer(unsigned(tb_ip2hwt_addr_b(0 to C_SLV_AWIDTH-3)))) <= tb_ip2hwt_data_b;
          tb_hwt2ip_wrack_b                              <= '1';
        end if;
        if tb_ip2hwt_rdce_b = '1' then
          tb_hwt2ip_rdack_b <= '1';
        end if;
        tb_hwt2ip_data_b <= register_bank_b(to_integer(unsigned(tb_ip2hwt_addr_b(0 to C_SLV_AWIDTH-3))));
      end if;
    end if;
  end process;
  
  clock : process
  begin
    tb_Bus2IP_Clk <= '1';
    wait for 10 ns;
    tb_Bus2IP_Clk <= '0';
    wait for 10 ns;
  end process;


  tb : process
  begin
    -- set Defaults
    tb_Bus2IP_BE   <= "1111";
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_Data <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '1';

    tb_desc <= "Reset           ";
    tb_Bus2IP_Reset <= '1';
    wait for 100 ns;  -- wait until global set/reset completes
    tb_Bus2IP_Reset <= '0';
    wait for 100 ns;


    tb_desc <= "Write Port A    ";
    tb_Bus2IP_Addr <= X"00000004";
    tb_Bus2IP_Data <= X"DEADBEEF";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_Data <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;

    tb_Bus2IP_Addr <= X"00000008";
    tb_Bus2IP_Data <= X"DEADAFFE";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_Data <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;

    tb_desc <= "Read Port A     ";
    tb_Bus2IP_Addr <= X"00000004";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;

    tb_Bus2IP_Addr <= X"00000008";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;

    tb_desc <= "Write port B    ";
    tb_Bus2IP_Addr <= X"00010004";
    tb_Bus2IP_Data <= X"DEADBEEF";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_Data <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;

    tb_Bus2IP_Addr <= X"00010008";
    tb_Bus2IP_Data <= X"DEADAFFE";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_Data <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '0';
    wait for 100 ns;

    tb_desc <= "Read  Port B    ";
    tb_Bus2IP_Addr <= X"00010004";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;

    tb_Bus2IP_Addr <= X"00010008";
    tb_Bus2IP_CS <= "1";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;
    tb_Bus2IP_Addr <= X"00000000";
    tb_Bus2IP_CS <= "0";
    tb_Bus2IP_RNW <= '1';
    wait for 100 ns;

    tb_desc <= "Testbench End   ";
    wait;
  end process tb;
  

end;
