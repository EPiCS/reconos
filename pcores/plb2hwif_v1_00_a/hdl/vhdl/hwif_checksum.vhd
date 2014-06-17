library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;

library easics_v1_00_a;
use easics_v1_00_a.PCK_CRC32_D32.all;

--! A checksum generator, which generates a checksum from a data stream and
--! provides  access to the checksums via a IPIF like interface. It has one
--! checksum engine, but several checksum registers
--!
--! Every checksum register is 32 bits wide. Available checksum algorithms are
--! CRC with a 32bit polynomial like in the ethernet standard and a simple
--! "sum" of data words.
--!
--! Address Map:
--! 0x0 : ID Register, returning unique ID for this module
--! 0x1 : length register, returning length of memory mapped area
--! 0x2 : config register, encodes number of channels and checksum algorithm
--! 0x3 : reset register: resets individual checksum channels
--! 0x4 : enable register: enables individual checksum channels
--! 0x5 to C_NUM_CHANNELS+4 : checksum registers, read only
--!
--! Register Layout:
--!
--! Config Register:
--! Stores the static configuration of this module, read-only.
--! Bits 31 downto 24 ( 8 bits): Number of channels
--! Bits 23 downto  4 (20 bits): none, keep value for compatibility
--! Bits  3 downto  0 ( 4 bits): encodes checksum algo, 0 is crc32
--!
--! Reset Register:
--! Every bit represents one checksum channel. LSB is channel 0,
--! MSB is channel 31. If a bit is set to 1 its corresponding checksum register
--! is resetted to zero, as well as its enable bit. Bits automatically reset to
--! 0 after a successful reset.
--!
--! Enable Register:
--! Every bit represents one checksum channel. LSB is channel 0,
--! MSB is channel 31. If a bit is set to 1 its corresponding checksum channel
--! is enabled, which means that the checksum will be updated if the channel
--! receives data. If set to 0 the current checksum will not change.
--!
--! Checksum Register:
--! 32 bit wide unsigned integer, reflecting the checksum according
--! to the set checksum algorithm. Default reset value: 0x00000000
--! Read-only
--!
entity hwif_checksum is
  generic(
    C_CHECKSUM_ALGO  : integer := 0;      -- 0: crc32, 1: 32Bit sum of inputs
    C_NUM_CHANNELS   : integer := 14;     -- How many different channels shall
                                          -- be provided ?
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
    data       : in std_logic_vector(31 downto 0);
    data_valid : in std_logic;
    channel    : in std_logic_vector(clog2(C_NUM_CHANNELS)-1 downto 0);
    
    debug: out std_logic_vector(109 downto 0);
    
    clk        : in std_logic;
    rst        : in std_logic);
end hwif_checksum;

architecture Behavioral of hwif_checksum is
  
  constant C_id_reg_addr     : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_config_reg_addr   : natural := 2;
  constant C_reset_reg_addr : natural := 3;
  constant C_enable_reg_addr : natural := 4;
  constant C_Fixed_Reg_Count : natural := 5;

  subtype register_t is std_logic_vector(31 downto 0);
  type register_array_t is array (natural range<>) of register_t;
  signal registers : register_array_t(0 to C_NUM_CHANNELS - 1);

  signal resets: register_t;
  signal enables: register_t;
  
  signal debugged_HWT2IP_Data : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal debugged_HWT2IP_RdAck: std_logic;
  signal debugged_HWT2IP_WrAck: std_logic;

begin
  --debug(109 downto 102) <= increments;
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
  register_read_write : process(clk, rst, registers, enables, resets)
  begin
    if rst = '1'  then
      --registers(C_config_reg_addr)(0)    <= '0';
      --registers(C_config_reg_addr)(1)   <= '0';
      resets <= (others=>'0');
      enables <= (others=>'0');
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      debugged_HWT2IP_Data  <= (others => '0');
    elsif clk'event and clk = '1' then
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      -- RO Registers
      if (IP2HWT_RdCE or IP2HWT_WrCE) = '1' then
        if IP2HWT_WrCE = '1' then
         if unsigned(IP2HWT_Addr(0 to 29)) = C_reset_reg_addr then
           resets <= IP2HWT_Data;            
         elsif  unsigned(IP2HWT_Addr(0 to 29)) = C_enable_reg_addr then
           enables <= IP2HWT_Data;
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

        case to_integer(unsigned(IP2HWT_Addr(0 to 29))) is
        when C_id_reg_addr =>
          debugged_HWT2IP_Data <= C_ID_PERFMON;
        when C_size_reg_addr =>
          debugged_HWT2IP_Data <= std_logic_vector(to_unsigned((2**ceil_power_of_2(C_Fixed_Reg_Count+C_NUM_CHANNELS)*4), 32));
        when C_config_reg_addr =>
          debugged_HWT2IP_Data <= std_logic_vector(to_unsigned(C_NUM_CHANNELS, 8)) &
                                  X"00000" &
                                  std_logic_vector(to_unsigned(C_CHECKSUM_ALGO, 4));
        when C_reset_reg_addr=>
          debugged_HWT2IP_Data <= resets;
        when C_enable_reg_addr=>
          debugged_HWT2IP_Data <= enables;
        when C_Fixed_Reg_Count to C_Fixed_Reg_Count+ C_NUM_CHANNELS-1 =>
          debugged_HWT2IP_Data <= registers(to_integer(unsigned(IP2HWT_Addr(0 to 29)))-C_Fixed_Reg_Count);

          when others =>
          debugged_HWT2IP_Data <= (others=> '0');
        end case;        
      end if;

      -- Automatically reset the reset bits
       for i in 0 to C_Num_Channels - 1 loop
        if resets(i) = '1' then
          resets(i) <= '0';
          enables(i)<= '0';
        end if;
      end loop;
    end if;
  end process;

 --Updates the counting registers
  counting : process(clk, rst, registers, resets, enables)
  begin
    if rst = '1'then
      registers <= (others=>(others => '0'));
    elsif clk'event and clk = '1' then
      if enables(to_integer(unsigned(channel))) = '1' then
        
          if data_valid = '1'  then
            registers(to_integer(unsigned(channel))) <= not nextCRC32_D32(data, not registers(to_integer(unsigned(channel))));
          end if;
        
      end if;
      for i in 0 to C_Num_Channels - 1 loop
        if resets(i) = '1' then
          registers(i) <= (others =>'0');
        end if;
      end loop;
    end if;
  end process;

end Behavioral;

