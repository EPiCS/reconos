-- Originaly created by: Sebastian Meisner
-- Date: 27.07.2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; --! For signed and unsigned arithmetic.

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity osif_multiplex is
  
  generic(
    N : integer := 8
  );
  
  port(
 		-- OSIF FSL - Processor side
		
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
    -- OSIF FSL - HWT side
		HWT_S_Read    : in  std_logic_vector(0 to N-1);                 -- Read signal, requiring next available input to be read
		HWT_S_Data    : out std_logic_vector(0 to N*32-1); -- Input data
		HWT_S_Control : out std_logic_vector(0 to N-1);                 -- Control Bit, indicating the input data are control word
		HWT_S_Exists  : out std_logic_vector(0 to N-1);                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		HWT_M_Write   : in  std_logic_vector(0 to N-1);                 -- Write signal, enabling writing to output FSL bus
		HWT_M_Data    : in  std_logic_vector(0 to N*32-1); -- Output data
		HWT_M_Control : in  std_logic_vector(0 to N-1);                 -- Control Bit, indicating the output data are contol word
		HWT_M_Full    : out std_logic_vector(0 to N-1);                 -- Full Bit, indicating output FSL bus is full
			
    -- Request and Acknowledgment lines
    HWT_reqs  : in  std_logic_vector(0 to N-1);
    HWT_acks  : out std_logic_vector(0 to N-1);
    
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic   
  );
  
end osif_multiplex;

architecture Behavioral of osif_multiplex is

  component rr_arbiter is
    generic(
      request_width : positive := 16  --! How many request inputs do you want?
      );
    port (
      clk      : in  std_logic;           --! Clock signal
      reset    : in  std_logic;           --! Reset signal
      requests : in  std_logic_vector (request_width-1 downto 0);  --! Input lines from the requestors.
      sel      : out std_logic_vector (clog2(request_width)-1 downto 0));  --! Who of the requesters will be served?
  end component rr_arbiter;

  signal active_hwt_slv : std_logic_vector ( clog2(N)-1 downto 0 ) ;
  signal active_hwt : integer range 0 to N-1;
begin

  active_hwt <= to_integer(unsigned(active_hwt_slv));

  rr : rr_arbiter 
    generic map (
      request_width => N)
    port map (
      clk => clk,
      reset => rst,
      requests => HWT_reqs,
      sel => active_hwt_slv);


--  roundrobin: process (clk, rst) is
--  begin
--    if rst = '1' then
--      active_hwt <= 0;
--    elsif clk'event and clk='1' then
--      for i in HWT_reqs'length loop
--        
--      end loop;
--    end if;
--  end process;

  multiplexer: process (active_hwt,  HWT_S_Read, OSFSL_S_Data, OSFSL_S_Control, OSFSL_S_Exists, 
                        HWT_M_Write,  HWT_M_Data, HWT_M_Control, OSFSL_M_Full)
  is
  begin
    -- Defaults for preventing latches
    HWT_S_Data <= (others => '0');
    HWT_S_Control <= (others => '0');
    HWT_S_Exists <= (others => '0');
    HWT_M_Full <= (others => '0');
    
    -- actual values
    HWT_acks <=(others => '0');
    HWT_acks (active_hwt) <= '1';
  
    OSFSL_S_Read <= HWT_S_Read(active_hwt);
		HWT_S_Data(active_hwt*32 to (active_hwt+1)*32-1)    <= OSFSL_S_Data;
		HWT_S_Control(active_hwt) <= OSFSL_S_Control;
		HWT_S_Exists(active_hwt)  <= OSFSL_S_Exists;
		
		OSFSL_M_Write  <= HWT_M_Write(active_hwt);
		OSFSL_M_Data  <= HWT_M_Data(active_hwt*32 to (active_hwt+1)*32-1); 
		OSFSL_M_Control  <= HWT_M_Control(active_hwt);
		HWT_M_Full(active_hwt) <=  OSFSL_M_Full;
  end process;

end Behavioral;

