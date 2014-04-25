library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
	generic
	(
		C_DIVIDER                      : integer              := 100;
		C_SLV_DWIDTH                   : integer              := 32;
		C_NUM_REG                      : integer              := 1
	);
	port
	(
		clk                     : in  std_logic;
		rst                     : in  std_logic;
		Bus2IP_Data             : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
		Bus2IP_Rd               : in  std_logic;
		Bus2IP_Wr               : in  std_logic;
		IP2Bus_Data             : out std_logic_vector(0 to C_SLV_DWIDTH-1);
		IP2Bus_RdAck            : out std_logic;
		IP2Bus_WrAck            : out std_logic;
		IP2Bus_Error            : out std_logic
	);
	
	attribute MAX_FANOUT : string;
	attribute SIGIS : string;
	
	attribute SIGIS of clk    : signal is "CLK";
	attribute SIGIS of rst    : signal is "RST";

end entity user_logic;

architecture IMP of user_logic is
	
	signal counter  : std_logic_vector(31 downto 0);
	signal divider  : integer range 0 to C_DIVIDER - 1;

begin
	
	IP2Bus_Data  <= counter;
	IP2Bus_WrAck <= Bus2IP_Wr;
	IP2Bus_RdAck <= Bus2IP_Rd;
	IP2Bus_Error <= '0';
	
	process(clk) is
	begin
	
		if rising_edge(clk) then
			if rst = '1' or Bus2IP_Wr = '1' then
				counter <= (others => '0');
				divider <= 0;
			else
				if divider = C_DIVIDER-1 then
					divider <= 0;
					counter <= counter + 1;
				else
					divider <= divider + 1;
				end if;
			end if;
		end if;
	
	end process;
	
end IMP;
