--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:17:42 07/27/2015
-- Design Name:   
-- Module Name:   /home/meise/ise_projects/matrixmul_parallelized/tb_osif_multiplex.vhd
-- Project Name:  matrixmul_parallelized
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: osif_multiplex
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_osif_multiplex IS
END tb_osif_multiplex;
 
ARCHITECTURE behavior OF tb_osif_multiplex IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT osif_multiplex
    PORT(
         OSFSL_S_Read : OUT  std_logic;
         OSFSL_S_Data : IN  std_logic_vector(0 to 31);
         OSFSL_S_Control : IN  std_logic;
         OSFSL_S_Exists : IN  std_logic;
         OSFSL_M_Write : OUT  std_logic;
         OSFSL_M_Data : OUT  std_logic_vector(0 to 31);
         OSFSL_M_Control : OUT  std_logic;
         OSFSL_M_Full : IN  std_logic;
         HWT_S_Read : IN  std_logic_vector(0 to 7);
         HWT_S_Data : OUT  std_logic_vector(0 to 255);
         HWT_S_Control : OUT  std_logic_vector(0 to 7);
         HWT_S_Exists : OUT  std_logic_vector(0 to 7);
         HWT_M_Write : IN  std_logic_vector(0 to 7);
         HWT_M_Data : IN  std_logic_vector(0 to 255);
         HWT_M_Control : IN  std_logic_vector(0 to 7);
         HWT_M_Full : OUT  std_logic_vector(0 to 7);
         HWT_reqs : IN  std_logic_vector(0 to 7);
         HWT_acks : OUT  std_logic_vector(0 to 7);
         clk : IN  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal OSFSL_S_Data : std_logic_vector(0 to 31) := (others => '0');
   signal OSFSL_S_Control : std_logic := '0';
   signal OSFSL_S_Exists : std_logic := '0';
   signal OSFSL_M_Full : std_logic := '0';
   signal HWT_S_Read : std_logic_vector(0 to 7) := (others => '0');
   signal HWT_M_Write : std_logic_vector(0 to 7) := (others => '0');
   signal HWT_M_Data : std_logic_vector(0 to 255) := (others => '0');
   signal HWT_M_Control : std_logic_vector(0 to 7) := (others => '0');
   signal HWT_reqs : std_logic_vector(0 to 7) := (others => '0');
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal OSFSL_S_Read : std_logic;
   signal OSFSL_M_Write : std_logic;
   signal OSFSL_M_Data : std_logic_vector(0 to 31);
   signal OSFSL_M_Control : std_logic;
   signal HWT_S_Data : std_logic_vector(0 to 255);
   signal HWT_S_Control : std_logic_vector(0 to 7);
   signal HWT_S_Exists : std_logic_vector(0 to 7);
   signal HWT_M_Full : std_logic_vector(0 to 7);
   signal HWT_acks : std_logic_vector(0 to 7);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: osif_multiplex PORT MAP (
          OSFSL_S_Read => OSFSL_S_Read,
          OSFSL_S_Data => OSFSL_S_Data,
          OSFSL_S_Control => OSFSL_S_Control,
          OSFSL_S_Exists => OSFSL_S_Exists,
          OSFSL_M_Write => OSFSL_M_Write,
          OSFSL_M_Data => OSFSL_M_Data,
          OSFSL_M_Control => OSFSL_M_Control,
          OSFSL_M_Full => OSFSL_M_Full,
          HWT_S_Read => HWT_S_Read,
          HWT_S_Data => HWT_S_Data,
          HWT_S_Control => HWT_S_Control,
          HWT_S_Exists => HWT_S_Exists,
          HWT_M_Write => HWT_M_Write,
          HWT_M_Data => HWT_M_Data,
          HWT_M_Control => HWT_M_Control,
          HWT_M_Full => HWT_M_Full,
          HWT_reqs => HWT_reqs,
          HWT_acks => HWT_acks,
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
      rst <= '1';
      HWT_M_Data<= X"0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF";
      -- hold reset state for 100 ns.
      
      wait for 100 ns;	
      rst <= '0';
      HWT_reqs <= (others => '0');
      HWT_reqs(7) <= '1';
      
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(6) <= '1';
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(5) <= '1';
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(4) <= '1';
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(3) <= '1';
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(2) <= '1';

      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(1) <= '1';
      HWT_reqs(5) <= '1';
      
      wait for clk_period*10;
      HWT_reqs <= (others => '0');
      HWT_reqs(0) <= '1';
      HWT_reqs(5) <= '1';
      wait;
   end process;

END;
