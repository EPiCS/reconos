-- TestBench Template 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.test_system;

entity tb_test_system is
end tb_test_system;

architecture behavior of tb_test_system is

  constant C_HWIF_IF_COUNT           : integer := 2;
  constant C_HWIF_ADDRESS_SPACE_BITS : integer := 16;
  constant C_Counters_Num            : integer := 2;
  constant C_SLV_AWIDTH              : integer := 32;
  constant C_SLV_DWIDTH              : integer := 32;
  constant C_NUM_MEM                 : integer := 1;

  constant clk_cycle : time := 10 ns;

  constant C_ID_MEM_SPACE_SIZE_BYTES      : integer := 32;
  constant C_PERFMON_MEM_SPACE_SIZE_BYTES : integer := 32;

  signal tb_Bus2IP_Clk    : std_logic;
  signal tb_Bus2IP_Reset  : std_logic;
  signal tb_Bus2IP_Addr   : std_logic_vector(0 to C_SLV_AWIDTH-1);
  signal tb_Bus2IP_Data   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_Bus2IP_BE     : std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
  signal tb_Bus2IP_CS     : std_logic_vector(0 to C_NUM_MEM-1);
  signal tb_Bus2IP_RNW    : std_logic;
  signal tb_IP2Bus_Data   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_IP2Bus_RdAck  : std_logic;
  signal tb_IP2Bus_WrAck  : std_logic;
  signal tb_IP2Bus_Error  : std_logic;

  signal tb_increments_a : std_logic_vector(C_Counters_Num-1 downto 0);
  signal tb_increments_b : std_logic_vector(C_Counters_Num-1 downto 0);

  signal tb_desc : string(1 to 16) := "None            ";
  
begin

  uut : entity test_system
    generic map (
      C_HWIF_IF_COUNT           => C_HWIF_IF_COUNT,
      C_HWIF_ADDRESS_SPACE_BITS => C_HWIF_ADDRESS_SPACE_BITS,
      C_Counters_Num            => C_Counters_Num,
      C_SLV_AWIDTH              => C_SLV_AWIDTH,
      C_SLV_DWIDTH              => C_SLV_DWIDTH,
      C_NUM_MEM                 => C_NUM_MEM
      )
    port map(
      Bus2IP_Clk    => tb_Bus2IP_Clk,
      Bus2IP_Reset  => tb_Bus2IP_Reset,
      Bus2IP_Addr   => tb_Bus2IP_Addr,
      Bus2IP_Data   => tb_Bus2IP_Data,
      Bus2IP_BE     => tb_Bus2IP_BE,
      Bus2IP_CS   => tb_Bus2IP_CS,
      Bus2IP_RNW   => tb_Bus2IP_RNW,
      IP2Bus_Data   => tb_IP2Bus_Data,
      IP2Bus_RdAck  => tb_IP2Bus_RdAck,
      IP2Bus_WrAck  => tb_IP2Bus_WrAck,
      IP2Bus_Error  => tb_IP2Bus_Error,
      increments_a  => tb_increments_a,
      increments_b  => tb_increments_b
      );


  --  Test Bench Statements
  clock : process
  begin
    tb_Bus2IP_Clk <= '1';
    wait for clk_cycle/2;
    tb_Bus2IP_Clk <= '0';
    wait for clk_cycle/2;
  end process;

  reset : process is
  begin
    tb_Bus2IP_Reset <= '1';
    wait for 10*clk_cycle;
    tb_Bus2IP_Reset <= '0';
    wait;
  end process;

  increments : process is
  begin  -- process increments
    tb_increments_a <= (others => '0');
    tb_increments_b <= (others => '0');
    wait for clk_cycle;
    tb_increments_a <= (others => '1');
    tb_increments_b <= (others => '1');
    wait for clk_cycle;
  end process;

  tb : process
    
    procedure idle
    is
    begin
      tb_Bus2IP_Addr <= (others => '0');
      tb_Bus2IP_Data <= (others => '0');
      tb_Bus2IP_CS <= (others => '0');
      tb_Bus2IP_RNW <= '0';
    end procedure;
    
    procedure write (
      constant hwt  : in integer;
      constant addr : in std_logic_vector(tb_Bus2IP_Addr'range);
      constant data : in std_logic_vector(C_SLV_DWIDTH-1 downto 0)
      )is
    begin
      tb_Bus2IP_Addr <= std_logic_vector(to_unsigned(hwt,C_SLV_AWIDTH-C_HWIF_ADDRESS_SPACE_BITS)) &
                        addr(C_SLV_AWIDTH-C_HWIF_ADDRESS_SPACE_BITS to C_SLV_AWIDTH-1);
      tb_Bus2IP_Data <= data;
      tb_Bus2IP_CS <=  "1";
      tb_Bus2IP_RNW <= '0';
      wait until tb_IP2Bus_WrAck = '1';
      wait for clk_cycle;
      idle;
      wait for clk_cycle;
    end procedure;

    procedure read (
      constant hwt  : in integer;
      constant addr : in std_logic_vector(tb_Bus2IP_Addr'range)
      )is
    begin
      tb_Bus2IP_Addr <= std_logic_vector('1' & to_unsigned(hwt,C_SLV_AWIDTH-C_HWIF_ADDRESS_SPACE_BITS-1)) &
                        addr(C_SLV_AWIDTH-C_HWIF_ADDRESS_SPACE_BITS to C_SLV_AWIDTH-1);
      tb_Bus2IP_Data <= (others => '0');
      tb_Bus2IP_CS <= "1";
      tb_Bus2IP_RNW <= '1';
      wait until tb_IP2Bus_RdAck = '1';
      wait for clk_cycle;
      idle;
      wait for clk_cycle;
    end procedure;
    
  begin
    
    wait for 10*clk_cycle;  -- wait until global set/reset completes

    -- Add user defined stimulus here
    tb_Bus2IP_BE <= (others => '1');    -- not used by test_system

    tb_desc <= "Read HWT0 ID Reg";
    for i in 0 to 5 loop
      read(0, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i

    tb_desc <= "Read HWT1 ID Reg";
    for i in 0 to 5 loop
      read(1, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i

    tb_desc <= "Read Perfmon0   ";
    for i in 8 to 15 loop
      read(0, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i

    tb_desc <= "Read Perfmon1   ";
    for i in 8 to 15 loop
      read(1, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i

    tb_desc <= "ActivatePerfmon0";
    write(0, std_logic_vector(to_unsigned(C_ID_MEM_SPACE_SIZE_BYTES+2*4, tb_Bus2IP_Addr'length)), X"00000002");


    tb_desc <= "Read Perfmon0   ";
    for i in 8 to 15 loop
      read(0, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i

    tb_desc <= "Read Perfmon1   ";
    for i in 8 to 15 loop
      read(1, std_logic_vector(to_unsigned(i*4, tb_Bus2IP_Addr'length)));
    end loop;  -- i


    tb_desc <= "Testbench End   ";
    idle;
    wait;                               -- will wait forever
  end process tb;
  --  End Test Bench 

end;
