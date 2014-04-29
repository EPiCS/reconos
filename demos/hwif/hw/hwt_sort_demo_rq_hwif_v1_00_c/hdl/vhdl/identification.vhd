library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;

--! Identification module
--! Stores some fixed values for module identification and configuration
--! Address     Description
--! 0x0 : ID register, returning unique ID for this module
--! 0x1 : Length register, returning length of memory mapped area
--! 0x2 : Hardware thread ID: Which HWT is this?
--! 0x3 : Version register, returning a version number
--! 0x4 : Capabilities register, one bit per capability
entity identification is
  generic(
    C_HWT_ID       : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
    C_VERSION      : std_logic_vector(31 downto 0) := X"000004ac";  -- Version Identifier
    C_CAPABILITIES : std_logic_vector(31 downto 0) := X"aaaaaaaa";  --Every Bit specifies a capability like performance monitoring etc.
    
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

    debug: out std_logic_vector(101 downto 0);
    
    clk        : in std_logic;
    rst        : in std_logic);
end entity;

architecture Behavioral of identification is

  constant C_id_reg_addr     : natural := 0;
  constant C_size_reg_addr   : natural := 1;
  constant C_hwt_id_reg_addr : natural := 2;
  constant C_version_reg_addr: natural := 3;
  constant C_capabilities_reg_addr: natural := 4;
  constant C_Fixed_Reg_Count : natural := 5;

  signal debugged_HWT2IP_Data : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal debugged_HWT2IP_RdAck: std_logic;
  signal debugged_HWT2IP_WrAck: std_logic;

begin
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
  register_read_write : process(clk, rst)
  begin
    if rst = '1' then
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      debugged_HWT2IP_Data  <= (others => '0');
    elsif clk'event and clk = '1' then
      debugged_HWT2IP_WrAck <= '0';
      debugged_HWT2IP_RdAck <= '0';
      if (IP2HWT_RdCE or IP2HWT_WrCE) = '1' then
        if IP2HWT_WrCE = '1' then
         -- Since we have no writeable registers here,
         -- we acknowledge every write and do nothing.
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
        when C_id_reg_addr   => debugged_HWT2IP_Data <= C_ID_IDENTITY;
        when C_size_reg_addr => debugged_HWT2IP_Data <= std_logic_vector(to_unsigned((2**ceil_power_of_2(C_Fixed_Reg_Count))*4, 32));
        when C_hwt_id_reg_addr => debugged_HWT2IP_Data <= C_HWT_ID;
        when C_version_reg_addr => debugged_HWT2IP_Data <= C_VERSION;
        when C_capabilities_reg_addr => debugged_HWT2IP_Data <= C_CAPABILITIES;
        when others => debugged_HWT2IP_Data <= (others=> '0');
        end case;
        
      end if;
    end if;
  end process;

end Behavioral;

