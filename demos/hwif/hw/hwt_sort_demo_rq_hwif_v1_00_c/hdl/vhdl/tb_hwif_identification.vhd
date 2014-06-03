--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:58:53 02/28/2014
-- Design Name:   
-- Module Name:   /home/meise/temp/hwif/pcores/hwif_v1_00_a/hdl/vhdl/tb_identification.vhd
-- Project Name:  hwif
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: identification
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

library work;
use work.hwif_pck.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_hwif_identification IS
END tb_hwif_identification;
 
ARCHITECTURE behavior OF tb_hwif_identification IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT hwif_identification
    generic(
    C_HWT_ID       : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
    C_VERSION      : std_logic_vector(31 downto 0) := X"000004ac";  -- Version Identifier
    C_CAPABILITIES : std_logic_vector(31 downto 0) := X"aaaaaaaa";  --Every Bit specifies a capability like performance monitoring etc.
    
    C_SLV_DWIDTH   : integer := 32
    );
    PORT(
         IP2HWT_Addr : IN  std_logic_vector(0 to 31);
         IP2HWT_Data : IN  std_logic_vector(31 downto 0);
         IP2HWT_RdCE : IN  std_logic;
         IP2HWT_WrCE : IN  std_logic;
         HWT2IP_Data : OUT  std_logic_vector(31 downto 0);
         HWT2IP_RdAck : OUT  std_logic;
         HWT2IP_WrAck : OUT  std_logic;
         clk : IN  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal IP2HWT_Addr : std_logic_vector(0 to 31) := (others => '0');
   signal IP2HWT_Data : std_logic_vector(31 downto 0) := (others => '0');
   signal IP2HWT_RdCE : std_logic := '0';
   signal IP2HWT_WrCE : std_logic := '0';
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal HWT2IP_Data : std_logic_vector(31 downto 0);
   signal HWT2IP_RdAck : std_logic;
   signal HWT2IP_WrAck : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: hwif_identification 
   generic map (
          C_HWT_ID       => X"DEADDEAD",  -- Unique ID number of this module
          C_VERSION      => X"000004ac",  -- Version Identifier
          C_CAPABILITIES => X"aaaaaaaa",  --Every Bit specifies a capability like performance monitoring etc.
    
          C_SLV_DWIDTH   =>32
   )
   PORT MAP (
          IP2HWT_Addr => IP2HWT_Addr,
          IP2HWT_Data => IP2HWT_Data,
          IP2HWT_RdCE => IP2HWT_RdCE,
          IP2HWT_WrCE => IP2HWT_WrCE,
          HWT2IP_Data => HWT2IP_Data,
          HWT2IP_RdAck => HWT2IP_RdAck,
          HWT2IP_WrAck => HWT2IP_WrAck,
          clk => clk,
          rst => rst
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- reset
      rst <= '1';
      wait for 3*clk_period;
      rst <= '0';
      wait for 3*clk_period;
      
      -- write tests, should do nothing
      for i in 0 to 15 loop
        IP2HWT_Addr <= X"000000" & std_logic_vector(to_unsigned(i*4, 8));
        IP2HWT_Data <= X"BEEFBEEF";
        IP2HWT_RdCE <= '1';
        IP2HWT_WrCE <= '0';
        wait for clk_period;
      end loop;
      
      -- read tests, should yield preset data
      for i in 0 to 15 loop
        IP2HWT_Addr <= X"000000" & std_logic_vector(to_unsigned(i*4, 8));
        IP2HWT_Data <= X"00000000";
        IP2HWT_RdCE <= '0';
        IP2HWT_WrCE <= '1';
        wait for clk_period;
      end loop;
      
      wait;
   end process;

END;
