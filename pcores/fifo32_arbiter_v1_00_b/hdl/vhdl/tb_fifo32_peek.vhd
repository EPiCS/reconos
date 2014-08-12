--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:58:59 07/24/2014
-- Design Name:   
-- Module Name:   /home/meise/git/reconos_epics/pcores/fifo32_arbiter_v1_00_b/hdl/vhdl/tb_fifo32_peek.vhd
-- Project Name:  fifo32_peek
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo32_peek
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
use ieee.numeric_std.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_fifo32_peek IS
END tb_fifo32_peek;
 
ARCHITECTURE behavior OF tb_fifo32_peek IS 
 
    constant C_FIFO32_PEEK_DEPTH : integer := 2;
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fifo32_peek
    generic (
    C_FIFO32_PEEK_DEPTH : integer := C_FIFO32_PEEK_DEPTH
    );
    port (
    Rst          : in std_logic;
    FIFO32_S_Clk : in std_logic;
    FIFO32_M_Clk : in std_logic;

    -- Active side: fetches data from fifo
    FIFO32_S_IN_Data : in  std_logic_vector(31 downto 0);
    FIFO32_S_IN_Fill : in  std_logic_vector(15 downto 0);
    FIFO32_S_OUT_Rd  : out std_logic;

    -- passive side: will provide data on FIFO32_S_Rd = '1'
    FIFO32_S_OUT_Data : out std_logic_vector(31 downto 0);
    FIFO32_S_OUT_Fill : out std_logic_vector(15 downto 0);
    FIFO32_S_IN_Rd    : in  std_logic;

    FIFO32_PEEK_DATA : out std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0)
    );
    END COMPONENT;
    

   --Inputs
   signal Rst : std_logic := '0';
   signal FIFO32_S_Clk : std_logic := '0';
   signal FIFO32_M_Clk : std_logic := '0';
   signal FIFO32_S_IN_Data : std_logic_vector(31 downto 0) := (others => '0');
   signal FIFO32_S_IN_Fill : std_logic_vector(15 downto 0) := (others => '0');
   signal FIFO32_S_IN_Rd : std_logic := '0';

 	--Outputs
   signal FIFO32_S_OUT_Rd : std_logic;
   signal FIFO32_S_OUT_Data : std_logic_vector(31 downto 0);
   signal FIFO32_S_OUT_Fill : std_logic_vector(15 downto 0);
   signal FIFO32_PEEK_DATA :  std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0);


   signal data_left : std_logic_vector(15 downto 0);
    
   -- Clock period definitions
   constant FIFO32_S_Clk_period : time := 10 ns;
   constant FIFO32_M_Clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fifo32_peek PORT MAP (
          Rst => Rst,
          FIFO32_S_Clk => FIFO32_S_Clk,
          FIFO32_M_Clk => FIFO32_M_Clk,
          FIFO32_S_IN_Data => FIFO32_S_IN_Data,
          FIFO32_S_IN_Fill => FIFO32_S_IN_Fill,
          FIFO32_S_OUT_Rd => FIFO32_S_OUT_Rd,
          FIFO32_S_OUT_Data => FIFO32_S_OUT_Data,
          FIFO32_S_OUT_Fill => FIFO32_S_OUT_Fill,
          FIFO32_S_IN_Rd => FIFO32_S_IN_Rd,
          FIFO32_PEEK_DATA => FIFO32_PEEK_DATA
        );

   -- Clock process definitions
   FIFO32_S_Clk_process :process
   begin
		FIFO32_S_Clk <= '1';
		wait for FIFO32_S_Clk_period/2;
		FIFO32_S_Clk <= '0';
		wait for FIFO32_S_Clk_period/2;
   end process;
 
   FIFO32_M_Clk_process :process
   begin
		FIFO32_M_Clk <= '1';
		wait for FIFO32_M_Clk_period/2;
		FIFO32_M_Clk <= '0';
		wait for FIFO32_M_Clk_period/2;
   end process;
 
   FIFO32_S_IN_Fill <= data_left;
   source_proc:process(FIFO32_S_Clk,rst)
   begin
     if rst = '1' then
       FIFO32_S_IN_Data <= (0 => '1', others => '0');
      -- set incoming fifo level to maximum to see if fifo32_peek fill does not
      -- overflow. If fill is > 0 and peek module is not full, peek module will
      -- read in data.
       data_left <= (others => '1');
     elsif FIFO32_S_Clk'event and FIFO32_S_Clk='1' and FIFO32_S_OUT_Rd = '1'  then
       FIFO32_S_IN_Data <= std_logic_vector(unsigned(FIFO32_S_IN_Data)+1);
       
       data_left <= std_logic_vector(unsigned(data_left)-1);
       -- Shortcut: dont want to wait for all 16k words to be transferred 
       if data_left = X"FFF0" then
         data_left <= X"000F";
       end if;
     end if;
   end process;


   sink_proc :process(FIFO32_S_Clk,rst)
   begin
     if rst = '1' then
       null;
     elsif FIFO32_S_Clk'event and FIFO32_S_Clk='1'  then
       if FIFO32_S_OUT_Fill /= X"0000" then
          FIFO32_S_IN_Rd <= '1';
       else
          FIFO32_S_IN_Rd <= '0';
       end if;
     end if;
   end process;
   
   stim_proc: process
   begin
      -- FIFO32_S_IN_Rd <= '0';
     
      -- hold reset state for 100 ns.
      rst <= '1';
      wait for FIFO32_S_Clk_period*10;	
      rst <= '0';
      wait for FIFO32_S_Clk_period*10;

      
      -- set incoming fifo level to maximum to see if fifo32_peek fill does not
      -- overflow. If fill is > 0 and peek module is not full, peek module will
      -- read in data.
      --FIFO32_S_IN_Fill <= (others => '1');
      --wait for 10*FIFO32_S_Clk_period;
      --FIFO32_S_IN_Fill <= (others => '0');
      --wait for 10*FIFO32_S_Clk_period;
      
      -- now let's read 
      --FIFO32_S_IN_Rd <= '1';
      --wait until FIFO32_S_OUT_fill = X"0000";
      --wait for 2*FIFO32_S_Clk_period; 
      --FIFO32_S_IN_Rd <= '0';

      -- And now read and write simultaneously
      --wait for 10*FIFO32_S_Clk_period;
      --FIFO32_S_IN_Fill <= (others => '1');
      -- peek filled up...
      --wait for 20*FIFO32_S_Clk_period;
      -- ... and activate read
      --FIFO32_S_IN_Rd <= '1';
      
      wait;
   end process;

END;
