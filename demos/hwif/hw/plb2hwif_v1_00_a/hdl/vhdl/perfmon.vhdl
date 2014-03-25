library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.hwif_pck.all;

--! A Performance Monitor, which counts events and its counter 
--! registers can be read via IPIF like interface.
--!
--! Every counter register is 32 bits wide. For an assumed 100MHz clock rate
--! events can be counted at least 42 seconds long at full rate before 
--! register overrun.
--!
--! Address Map:
--! 0x0 : ID Register, returning unique ID for this module
--! 0x1 : length register, returning length of memory mapped area
--! 0x2 : configuration register, read and writable
--! 0x3 to C_Counters_Num+3 : counter registers, read only
--!
--! Register Layout:
--! Configuration Register:
--! Bit 0 (LSB), RESET: Write 1 to reset all counter registers and the configuraton register.
--!                     You have to re-enable the performance monitor, if you want it to run.
--! Bit 1, ENABLE: Write 1 to enable the performance monitor and 0 to diasable it.
--! Bit 31 downto 24: RO 8 bits wide, giving number of configured counters
--! Bit 2 to  31, RESERVED: Maintain the contents of these bits during 
--!
--! Counter Register: 32 bit wide unsigned integer, reflecting the number of clock 
--!                   cycles the event (increments(i)) was active.
--!
entity perfmon is
  generic(
    C_Counters_Num : integer := 8;  -- How many performance counters do you want?
    C_SLV_DWIDTH   : integer := 32
    );
  port (
    -- HWIF interface
    IP2HWT_Addr  : in  std_logic_vector(0 to 31);
    IP2HWT_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2HWT_RdCE  : in  std_logic;
    IP2HWT_WrCE  : in  std_logic;
    HWT2IP_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    HWT2IP_RdAck : out std_logic;
    HWT2IP_WrAck : out std_logic;

    -- Performance Monitors custom signals
    increments : in std_logic_vector (C_Counters_Num-1 downto 0);
    clk        : in std_logic;
    rst        : in std_logic);
end perfmon;

architecture Behavioral of perfmon is
  
  constant C_id_reg_addr     : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_config_reg_addr : natural := 2;
  constant C_Fixed_Reg_Count : natural := 3;

  subtype register_t is std_logic_vector(31 downto 0);
  type register_array_t is array (natural range<>) of register_t;
  signal registers : register_array_t(0 to C_Counters_Num - 1);
  signal enable_bit: std_logic;
  signal reset_bit: std_logic;
  
  --alias id_reg is registers(C_id_reg_addr);
  --alias size_reg is registers(C_size_reg_addr);

  --alias config_reg is registers(C_config_reg_addr);
  --alias reset_bit is registers(C_config_reg_addr)(0);
  --alias enable_bit is registers(C_config_reg_addr)(1); --config_reg(1);
  --alias counters_num_bits : std_logic_vector(7 downto 0) is registers(C_config_reg_addr)(31 downto 24);

  --alias counters : register_array_t(0 to C_Counters_Num - 1) is registers(C_Fixed_Reg_Count to C_Counters_Num + C_Fixed_Reg_Count - 1);

begin

-- Reads to all registers and read/writes to config register.
  register_read_write : process(clk, rst, reset_bit, registers)
  begin
    if rst = '1' or reset_bit = '1' then
      --registers(C_config_reg_addr)(0)    <= '0';
      --registers(C_config_reg_addr)(1)   <= '0';
      reset_bit <= '0';
      enable_bit <= '0';
      HWT2IP_WrAck <= '0';
      HWT2IP_RdAck <= '0';
      HWT2IP_Data  <= (others => '0');
    elsif clk'event and clk = '1' then
      HWT2IP_WrAck <= '0';
      HWT2IP_RdAck <= '0';
      -- RO Registers
      if (IP2HWT_RdCE or IP2HWT_WrCE) = '1' then
        if IP2HWT_WrCE = '1' then
         if unsigned(IP2HWT_Addr(0 to 29)) = C_config_reg_addr then
            reset_bit <= IP2HWT_Data(0);
            enable_bit <= IP2HWT_Data(1);
         end if;
         HWT2IP_WrAck <= '1';
        end if;
        if IP2HWT_RdCE = '1' then
          HWT2IP_RdAck <= '1';
        end if;

        case to_integer(unsigned(IP2HWT_Addr(0 to 29))) is
        when C_id_reg_addr =>
          HWT2IP_Data <= C_ID_PERFMON;
        when C_size_reg_addr =>
          HWT2IP_Data <= std_logic_vector(to_unsigned((2**ceil_power_of_2(C_Fixed_Reg_Count+C_Counters_Num)*4), 32));
        when C_config_reg_addr =>
          HWT2IP_Data <= std_logic_vector(to_unsigned(C_Counters_Num, 8)) & X"0000" & "000000" & enable_bit & reset_bit;
        when C_Fixed_Reg_Count to C_Fixed_Reg_Count+ C_Counters_Num-1 =>
          HWT2IP_Data <= registers(to_integer(unsigned(IP2HWT_Addr(0 to 29)))-C_Fixed_Reg_Count);
        when others =>
          HWT2IP_Data <= (others=> '0');
        end case;
        
      end if;
    end if;
  end process;

 --Updates the counting registers
  counting : process(clk, rst, reset_bit, registers)
  begin
    if rst = '1' or reset_bit = '1' then
      registers(0 to C_Counters_Num - 1) <= (others=>(others => '0'));
    elsif clk'event and clk = '1' then
      if enable_bit = '1' then
        for i in 0 to C_Counters_Num - 1 loop
          if increments(i) = '1' and registers(i) /= X"FFFFFFFF" then
            registers(i) <= std_logic_vector(unsigned(registers(i)) +1);
          end if;
        end loop;
      end if;
    end if;
  end process;

end Behavioral;

