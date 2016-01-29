-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

library sem_v2_00_a;
use sem_v2_00_a.user_logic;


  ENTITY testbench IS
  END testbench;

  ARCHITECTURE behavior OF testbench IS 

  constant C_SLV_DWIDTH       : integer := 32;
  constant C_NUM_REG          : integer := 4;

  constant NOP          : std_logic_vector(0 to 7 ) := "00000000";
  constant IDLE         : std_logic_vector(0 to 7 ) := "10000000";
  constant INJECTION    : std_logic_vector(0 to 7 ) := "01000000";
  constant STATUS       : std_logic_vector(0 to 7 ) := "00100000";
  constant RESET        : std_logic_vector(0 to 7 ) := "00010000";
  constant OBSERVATION  : std_logic_vector(0 to 7 ) := "00001000";

  signal tb_Bus2IP_Clk    : std_logic;
  signal tb_Bus2IP_Reset  : std_logic;
  signal tb_Bus2IP_Data   : std_logic_vector(0 to C_SLV_DWIDTH-1 );
  signal tb_Bus2IP_BE     : std_logic_vector(0 to C_SLV_DWIDTH/8-1 );
  signal tb_Bus2IP_RdCE	  : std_logic_vector(0 to C_NUM_REG-1);
  signal tb_Bus2IP_WrCE	  : std_logic_vector(0 to C_NUM_REG-1);
  signal tb_IP2Bus_Data   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal tb_IP2Bus_RdAck  : std_logic;
  signal tb_IP2Bus_WrAck  : std_logic;
  signal tb_IP2Bus_Error  : std_logic;
  signal debug   : std_logic_vector(0 to 99); 
  BEGIN

  -- Component Instantiation
    uut: entity user_logic
    generic map(
    C_DEBUG_WIDTH        => 100,
    C_SLV_DWIDTH         => 32,
    C_NUM_REG            => 4
      )
    port map(
	debug       => debug,
      Bus2IP_Clk    => tb_Bus2IP_Clk,
      Bus2IP_Reset  => tb_Bus2IP_Reset,
      Bus2IP_Data   => tb_Bus2IP_Data,
      Bus2IP_BE     => tb_Bus2IP_BE,
      Bus2IP_RdCE   => tb_Bus2IP_RdCE,
      Bus2IP_WrCE   => tb_Bus2IP_WrCE,
      IP2Bus_Data   => tb_IP2Bus_Data,
      IP2Bus_RdAck  => tb_IP2Bus_RdAck,
      IP2Bus_WrAck  => tb_IP2Bus_WrAck,
      IP2Bus_Error  => tb_IP2Bus_Error
      );

  --  Test Bench Statements

  clock : process
  begin
    tb_Bus2IP_Clk <= '1';
    wait for 10 ns;
    tb_Bus2IP_Clk <= '0';
    wait for 10 ns;
  end process;

     tb : PROCESS
     BEGIN

        wait for 100 ns; -- wait until global set/reset completes
	tb_Bus2IP_Reset <= '1';
       tb_Bus2IP_Data <= x"00000000";
       wait for 50 ns;
	tb_Bus2IP_Reset <= '0';
       wait for 50 ns;
        -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";


       wait for 500 ns;
----------------------IDLE STATE-----------------------------    
        -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= IDLE;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 1000 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 1000 ns;
-------------------------------------------------------------------

	tb_Bus2IP_Reset <= '1';
       tb_Bus2IP_Data <= x"00000000";
       wait for 50 ns;
	tb_Bus2IP_Reset <= '0';
       wait for 50 ns;

--------------- INJECTION ADDRESS INTO SLVREG2 AND SLVREG3---------
 -- Address to slvreg2
       tb_Bus2IP_Data(0 to C_SLV_DWIDTH-1) <= x"00000002";
       tb_Bus2IP_BE(0 to 3) <= "1111";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "0010";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 1000 ns;

   -- Addres to slvreg3
       tb_Bus2IP_Data(0 to C_SLV_DWIDTH-1) <= x"00000003";
       tb_Bus2IP_BE(0 to 3) <= "1111";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "0001";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 1000 ns;
------------------------------------------------------------

-----------------INJECTION COMMAND TO SEM-------------------

     -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= INJECTION;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 1000 ns;
---------------------------------------------------------------

	tb_Bus2IP_Reset <= '1';
       tb_Bus2IP_Data <= x"00000000";
       wait for 50 ns;
	tb_Bus2IP_Reset <= '0';
       wait for 50 ns;
-------------------STATUS COMMAND TO SEM-------------------------
 -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= STATUS;
       tb_Bus2IP_BE(0 to 3) <= "1000";
      wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
       wait for 1000 ns;
--------------------------------------------------------------

	tb_Bus2IP_Reset <= '1';
       tb_Bus2IP_Data <= x"00000000";
       wait for 50 ns;
	tb_Bus2IP_Reset <= '0';
       wait for 50 ns;

---------------------RESET------------------------------------
 -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= RESET;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
       wait for 1000 ns;
---------------------------------------------------------------

	tb_Bus2IP_Reset <= '1';
       tb_Bus2IP_Data <= x"00000000";
       wait for 50 ns;
	tb_Bus2IP_Reset <= '0';
       wait for 50 ns;

-----------------OBSERVATION------------------------------------
     -- Add user defined stimulus here
       tb_Bus2IP_Data(0 to 7) <= OBSERVATION;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';	
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
      wait for 500 ns;
      -- Add user defined stimulus here
       tb_Bus2IP_Data (0 to 7) <= NOP;
       tb_Bus2IP_BE(0 to 3) <= "1000";
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';
       tb_Bus2IP_WrCE(0 to 3) <= "1000";
	--wait for 40 ns;
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='1';
       wait until tb_Bus2IP_Clk'event and tb_Bus2IP_Clk='0';		
       tb_Bus2IP_BE(0 to 3) <= "0000";
       tb_Bus2IP_WrCE(0 to 3) <= "0000";
---------------------------------------------------------------
        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
