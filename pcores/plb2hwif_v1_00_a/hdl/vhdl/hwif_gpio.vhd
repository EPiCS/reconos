
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;
--! A GPIO module, when you occasionally need to set or read a few bits
--! from your hardware threads.
--!
--! Number of input and output bits is configurable and will be mapped to
--! consecutive number of 32 bit registers. No run-time configuration
--! possible at the moment, except for resetting the module which just sets
--! all output bits to '0'.
--!
--! Address Map:
--! 0x0 : ID Register, returning unique ID for this module
--! 0x1 : length register, returning length of memory mapped area
--! 0x2 : configuration register, read and writable
--! 0x3 to (((C_Bits_Out_Num-1)/32)) :GP output registers
--! (((C_Bits_Out_Num-1)/32)+1) to  (((C_Bits_In_Num-1)/32)): GP input registers
--!
--! Register Layout:
--! Configuration Register:
--! Bit 0 (LSB), RESET: Write 1 to reset all counter registers and the configuraton register.
--!                     You have to re-enable the performance monitor, if you want it to run.
--! Bit 23 downto 16: RO 8 bits wide, giving number of configured GP in  bits
--! Bit 31 downto 24: RO 8 bits wide, giving number of configured GP out bits
--! Bit 1 to  15, RESERVED: Maintain the contents of these bits during 
--!
--! GPIO Register: 32 bit wide bit field. Index 0 of gpio_out is mapped to
--! register 0 index 0 of gpio_out_reg.
--!
entity hwif_gpio is
  generic(
    C_Bits_Out_Num : natural := 32;  -- How many outgoing bits (write only) do you want?
    C_Bits_In_Num : natural := 32;  -- How many ingoing bits (read only) do you want?
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
    gpio_out : out std_logic_vector (C_Bits_Out_Num-1 downto 0);
    gpio_in  : in  std_logic_vector (C_Bits_In_Num-1 downto 0);
    debug: out std_logic_vector(109 downto 0);
    
    clk        : in std_logic;
    rst        : in std_logic);
end entity;

architecture Behavioral of hwif_gpio is
  
  constant C_id_reg_addr     : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_config_reg_addr : natural := 2;
  constant C_Fixed_Reg_Count : natural := 3;

  -- One Register holds 32 individual bits. For more than 32 Bits we need
  -- additional registers. 
  constant C_Registers_Out_Num : positive := (((C_Bits_Out_Num-1)/32)+1);
  constant C_Registers_In_Num : positive := (((C_Bits_In_Num-1)/32)+1);
  
  subtype register_t is std_logic_vector(31 downto 0);
  type register_array_t is array (natural range<>) of register_t;
  signal gpio_out_reg : register_array_t(0 to C_Registers_Out_Num - 1);
  signal gpio_in_reg : register_array_t(0 to C_Registers_in_Num - 1);
  signal reset_bit: std_logic;
  
  signal debugged_HWT2IP_Data : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal debugged_HWT2IP_RdAck: std_logic;
  signal debugged_HWT2IP_WrAck: std_logic;

begin
  debug(109 downto 102) <= (others => '0');
  debug(101)          <= clk;
  debug(100)          <= rst;
  debug(99 downto 68) <=  IP2HWT_Addr;
  debug(67 downto 36 ) <= IP2HWT_Data;
  debug(35) <= IP2HWT_RdCE;
  debug(34) <= IP2HWT_WrCE;
  debug(33 downto 2 ) <= debugged_HWT2IP_Data;
  debug(1) <= debugged_HWT2IP_RdAck;
  debug(0) <= debugged_HWT2IP_WrAck;

  HWT2IP_Data  <= debugged_HWT2IP_Data  ;
  HWT2IP_RdAck <= debugged_HWT2IP_RdAck ;
  HWT2IP_WrAck <= debugged_HWT2IP_WrAck ;


-- Reads to all registers and read/writes to config register.
  register_read_write : process(clk, rst, reset_bit)
  begin
    if rst = '1' or reset_bit = '1' then
      reset_bit <= '0';
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      debugged_HWT2IP_Data  <= (others => '0');
      gpio_out_reg          <= (others=>(others => '0'));
    elsif clk'event and clk = '1' then
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      if (IP2HWT_RdCE or IP2HWT_WrCE) = '1' then
        -- Handle writes
        if IP2HWT_WrCE = '1' then
         if unsigned(IP2HWT_Addr(0 to 29)) = C_config_reg_addr then
            reset_bit <= IP2HWT_Data(0);
         elsif unsigned(IP2HWT_Addr(0 to 29)) >= C_Fixed_Reg_Count
               and unsigned(IP2HWT_Addr(0 to 29)) <= C_Fixed_Reg_Count+C_Registers_Out_Num-1
           then
            gpio_out_reg(to_integer(unsigned(IP2HWT_Addr(0 to 29)))- C_Fixed_Reg_Count) <= IP2HWT_Data;
         end if;
         debugged_HWT2IP_WrAck <= '1';
        end if;
        -- Acknowledgements are not allowed to be '1' for longer than 1 clock cycle
        if debugged_HWT2IP_WrAck = '1' then
          debugged_HWT2IP_WrAck <= '0';
        end if;
        
        if IP2HWT_RdCE = '1' then
          debugged_HWT2IP_RdAck <= '1';
        end if;
        -- Acknowledgements are not allowed to be '1' for longer than 1 clock cycle 
        if debugged_HWT2IP_RdAck = '1' then
          debugged_HWT2IP_RdAck <= '0';
        end if;

        -- Handle reads
        case to_integer(unsigned(IP2HWT_Addr(0 to 29))) is
        when C_id_reg_addr =>
          debugged_HWT2IP_Data <= C_ID_GPIO;
        when C_size_reg_addr =>
          debugged_HWT2IP_Data <= std_logic_vector(to_unsigned((2**ceil_power_of_2(C_Fixed_Reg_Count+C_Registers_Out_Num+C_Registers_in_Num)*4), 32));
        when C_config_reg_addr =>
          debugged_HWT2IP_Data <= std_logic_vector( to_unsigned(C_Bits_Out_Num, 8) & to_unsigned(C_Bits_In_Num, 8) & X"000" & "000" & reset_bit );
        when C_Fixed_Reg_Count to C_Fixed_Reg_Count+ C_Registers_Out_Num-1 =>
          debugged_HWT2IP_Data <= gpio_out_reg(to_integer(unsigned(IP2HWT_Addr(0 to 29)))- C_Fixed_Reg_Count);
        when C_Fixed_Reg_Count+ C_Registers_Out_Num to C_Fixed_Reg_Count+ C_Registers_Out_Num+C_Registers_In_Num-1 =>
          debugged_HWT2IP_Data <= gpio_in_reg(to_integer(unsigned(IP2HWT_Addr(0 to 29)))- C_Fixed_Reg_Count- C_Registers_Out_Num);
        when others =>
          debugged_HWT2IP_Data <= (others=> '0');
        end case;
        
      end if;
    end if;
  end process;

  -- Connect registers to output and input signals
  gpio_in_loop: for i in 0 to C_Registers_In_Num-1 generate
    gpio_in_reg(i) <= gpio_in((32*i)+31 downto 32*i) when i /= C_Registers_In_Num-1 else
                      gpio_in(gpio_in'length-1 downto 32*i) when gpio_in'length mod 32 = 0 else
                      (31-(gpio_in'length-32*i) downto 0 => '0')  & gpio_in(gpio_in'length-1 downto 32*i);

  end generate gpio_in_loop;

  gpio_out_loop: for i in 0 to C_Registers_out_Num-2 generate
    gpio_out((32*i)+31 downto 32*i)  <= gpio_out_reg(i);
  end generate gpio_out_loop;
  gpio_out_loop2: for i in C_Registers_out_Num-1 to C_Registers_out_Num-1 generate
    gpio_out(gpio_out'length-1 downto 32*i)  <= gpio_out_reg(i)(gpio_out'length-32*i-1 downto 0);
  end generate gpio_out_loop2;
end architecture;

