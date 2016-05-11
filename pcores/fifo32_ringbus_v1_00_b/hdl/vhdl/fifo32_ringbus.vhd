--Doxygen
--! @file fifo32_ringbus.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        can connect multipe hardware threads with fifo32 interfaces to  
--!        mutliple other peripherals, like memory controllers.

library ieee;              --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic

use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library fifo32_v1_00_b;
use fifo32_v1_00_b.all;

entity fifo32_ringbus is
    generic (
        G_FIFO32_PORTS     : integer := 16;   --! 1 to 16 allowed
        G_SHADOW_UNITS	 : integer := 7
    );
    port (
    -- Multiple FIFO32 Inputs
        IN_FIFO32_S_Data_A : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_A : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_A   : out std_logic;
        
        IN_FIFO32_M_Data_A : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_A  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_A   : out std_logic;
        
        IN_FIFO32_S_Data_B : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_B : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_B   : out std_logic;
        
        IN_FIFO32_M_Data_B : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_B  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_B   : out std_logic;
        
        IN_FIFO32_S_Data_C : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_C : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_C   : out std_logic;
        
        IN_FIFO32_M_Data_C : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_C  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_C   : out std_logic;
        
        IN_FIFO32_S_Data_D : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_D : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_D   : out std_logic;
        
        IN_FIFO32_M_Data_D : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_D  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_D   : out std_logic;
        
        IN_FIFO32_S_Data_E : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_E : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_E   : out std_logic;
        
        IN_FIFO32_M_Data_E : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_E  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_E   : out std_logic;
        
        IN_FIFO32_S_Data_F : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_F : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_F   : out std_logic;
        
        IN_FIFO32_M_Data_F : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_F  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_F   : out std_logic;
        
        IN_FIFO32_S_Data_G : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_G : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_G   : out std_logic;
        
        IN_FIFO32_M_Data_G : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_G  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_G   : out std_logic;
        
        IN_FIFO32_S_Data_H : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_H : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_H   : out std_logic;
        
        IN_FIFO32_M_Data_H : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_H  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_H   : out std_logic;
        
        IN_FIFO32_S_Data_I : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_I : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_I   : out std_logic;
        
        IN_FIFO32_M_Data_I : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_I  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_I   : out std_logic;
        
        IN_FIFO32_S_Data_J : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_J : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_J   : out std_logic;
        
        IN_FIFO32_M_Data_J : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_J  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_J   : out std_logic;
        
        IN_FIFO32_S_Data_K : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_K : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_K   : out std_logic;
        
        IN_FIFO32_M_Data_K : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_K  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_K   : out std_logic;
        
        IN_FIFO32_S_Data_L : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_L : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_L   : out std_logic;
        
        IN_FIFO32_M_Data_L : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_L  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_L   : out std_logic;
        
        IN_FIFO32_S_Data_M : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_M : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_M   : out std_logic;
        
        IN_FIFO32_M_Data_M : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_M  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_M   : out std_logic;
        
        IN_FIFO32_S_Data_N : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_N : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_N   : out std_logic;
        
        IN_FIFO32_M_Data_N : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_N  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_N   : out std_logic;
        
        IN_FIFO32_S_Data_O : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_O : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_O   : out std_logic;
        
        IN_FIFO32_M_Data_O : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_O  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_O   : out std_logic;
        
        IN_FIFO32_S_Data_P : in  std_logic_vector(31 downto 0);
        IN_FIFO32_S_Fill_P : in  std_logic_vector(15 downto 0);
        IN_FIFO32_S_Rd_P   : out std_logic;
        
        IN_FIFO32_M_Data_P : out std_logic_vector(31 downto 0);
        IN_FIFO32_M_Rem_P  : in  std_logic_vector(15 downto 0);
        IN_FIFO32_M_Wr_P   : out std_logic;
        
        -- Single FIFO32 Output
        OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
        OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
        OUT_FIFO32_S_Rd   : in  std_logic;
        
        OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
        OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
        OUT_FIFO32_M_Wr   : in  std_logic;
        
        -- Run-time options
        RUNTIME_OPTIONS : in std_logic_vector(15 downto 0 );
        
        -- Error reporting
        ERROR_REQ : out std_logic;
        ERROR_ACK : in  std_logic;
        ERROR_TYP : out std_logic_vector(7 downto 0);
        ERROR_ADR : out std_logic_vector(31 downto 0);
        
        -- Misc
        Rst : in std_logic;
        clk : in std_logic;                  -- separate clock for control logic
        
        -- Debug signals to ILA
        ila_signals : out std_logic_vector(255 downto 0)
    );
end entity;

--! Notes to implementor:
--! This Multiplexer may only switch to another input stream, when a complete
--! packet was transmitted. As we don't have any signals telling us the end or
--! start of a packet, we have to track the protocol to decide when to switch.
architecture behavioural of fifo32_ringbus is
    
	type integer_vector is array (natural range<>) of integer;	
	
	-- How many memory controllers are connected?
	constant C_MEMCTRL_PORTS : integer := 1;
	
	-- Ringbus management module. Should always be 1, constant introduced for code readability
	constant C_RINGBUS_MGMT: integer := 1;

	
	
	-- Physical map of modules to ports of the ringbus.
	-- An optimized arrangement of modules improves performance!  


	-- Shadow configuration - not yet fully implemented
	-- @TODO: Implement shadow module and mgmt module
	-- Total number of internal ports of the ringbus
-- 	constant C_INTERNAL_PORTS: integer := G_FIFO32_PORTS+ C_MEMCTRL_PORTS +  G_SHADOW_UNITS + C_RINGBUS_MGMT;
-- 	constant fifo32_ports : integer_vector := (1,3,4,6,7,9,10,12,13,15,16,18,19,21);
-- 	constant memctrl_ports : integer_vector(0 to 0) := (0 => 0);
-- 	constant shadow_ports : integer_vector := (2,5,8,11,14,17,20);
-- 	constant mgmt_ports : integer_vector(0 to 0) := (0 => 22);

	-- Shadowless configuration
	constant C_INTERNAL_PORTS: integer := G_FIFO32_PORTS+ C_MEMCTRL_PORTS;
	constant fifo32_ports : integer_vector := (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16);
	constant memctrl_ports : integer_vector(0 to 0) := (0 => 0);
	
	
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
  -- Internal signal vectors to unify all 16 FIFO32 ports
  signal IN_FIFO32_S_Data : std_logic_vector((32*C_INTERNAL_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Fill : std_logic_vector((16*C_INTERNAL_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Rd   : std_logic_vector(C_INTERNAL_PORTS-1 downto 0);

  signal IN_FIFO32_M_Data : std_logic_vector((32*C_INTERNAL_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Rem  : std_logic_vector((16*C_INTERNAL_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Wr   : std_logic_vector(C_INTERNAL_PORTS-1 downto 0);
  
  -- Debug
  signal ila_signals_ringbus     : std_logic_vector(255 downto 0);
  signal OUT_FIFO32_S_Data_debug : std_logic_vector(31  downto 0);
  signal OUT_FIFO32_S_Fill_debug : std_logic_vector(15  downto 0);
  signal OUT_FIFO32_M_Rem_debug  : std_logic_vector(15  downto 0);
  
begin  -- of architecture -------------------------------------------------------

  -- connect separate entity ports to internal signal vectors
  A: if G_FIFO32_PORTS > 0 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(0)))-1 downto 32 * fifo32_ports(0)) <= IN_FIFO32_S_Data_A;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(0)))-1 downto 16 * fifo32_ports(0)) <= IN_FIFO32_S_Fill_A;
    IN_FIFO32_S_Rd_A  <= IN_FIFO32_S_Rd(fifo32_ports(0));
    
    IN_FIFO32_M_Data_A <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(0)))-1 downto 32 * fifo32_ports(0));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(0)))-1 downto 16 * fifo32_ports(0))  <= IN_FIFO32_M_Rem_A;
    IN_FIFO32_M_Wr_A   <= IN_FIFO32_M_Wr(fifo32_ports(0));
  end generate;

  B: if G_FIFO32_PORTS > 1 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(1)))-1 downto 32 * fifo32_ports(1)) <= IN_FIFO32_S_Data_B;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(1)))-1 downto 16 * fifo32_ports(1)) <= IN_FIFO32_S_Fill_B;
    IN_FIFO32_S_Rd_B  <= IN_FIFO32_S_Rd(fifo32_ports(1));
    
    IN_FIFO32_M_Data_B <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(1)))-1 downto 32 * fifo32_ports(1));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(1)))-1 downto 16 * fifo32_ports(1))  <= IN_FIFO32_M_Rem_B;
    IN_FIFO32_M_Wr_B   <= IN_FIFO32_M_Wr(fifo32_ports(1));
  end generate;

  C: if G_FIFO32_PORTS > 2 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(2)))-1 downto 32 * fifo32_ports(2)) <= IN_FIFO32_S_Data_C;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(2)))-1 downto 16 * fifo32_ports(2)) <= IN_FIFO32_S_Fill_C;
    IN_FIFO32_S_Rd_C  <= IN_FIFO32_S_Rd(fifo32_ports(2));
    
    IN_FIFO32_M_Data_C <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(2)))-1 downto 32 * fifo32_ports(2));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(2)))-1 downto 16 * fifo32_ports(2))  <= IN_FIFO32_M_Rem_C;
    IN_FIFO32_M_Wr_C   <= IN_FIFO32_M_Wr(fifo32_ports(2));
  end generate;

  D: if G_FIFO32_PORTS > 3 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(3)))-1 downto 32 * fifo32_ports(3)) <= IN_FIFO32_S_Data_D;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(3)))-1 downto 16 * fifo32_ports(3)) <= IN_FIFO32_S_Fill_D;
    IN_FIFO32_S_Rd_D  <= IN_FIFO32_S_Rd(fifo32_ports(3));
    
    IN_FIFO32_M_Data_D <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(3)))-1 downto 32 * fifo32_ports(3));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(3)))-1 downto 16 * fifo32_ports(3))  <= IN_FIFO32_M_Rem_D;
    IN_FIFO32_M_Wr_D   <= IN_FIFO32_M_Wr(fifo32_ports(3));
  end generate;

  E: if G_FIFO32_PORTS > 4 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(4)))-1 downto 32 * fifo32_ports(4)) <= IN_FIFO32_S_Data_E;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(4)))-1 downto 16 * fifo32_ports(4)) <= IN_FIFO32_S_Fill_E;
    IN_FIFO32_S_Rd_E  <= IN_FIFO32_S_Rd(fifo32_ports(4));
    
    IN_FIFO32_M_Data_E <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(4)))-1 downto 32 * fifo32_ports(4));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(4)))-1 downto 16 * fifo32_ports(4))  <= IN_FIFO32_M_Rem_E;
    IN_FIFO32_M_Wr_E   <= IN_FIFO32_M_Wr(fifo32_ports(4));
  end generate;

  F: if G_FIFO32_PORTS > 5 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(5)))-1 downto 32 * fifo32_ports(5)) <= IN_FIFO32_S_Data_F;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(5)))-1 downto 16 * fifo32_ports(5)) <= IN_FIFO32_S_Fill_F;
    IN_FIFO32_S_Rd_F  <= IN_FIFO32_S_Rd(fifo32_ports(5));
    
    IN_FIFO32_M_Data_F <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(5)))-1 downto 32 * fifo32_ports(5));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(5)))-1 downto 16 * fifo32_ports(5))  <= IN_FIFO32_M_Rem_F;
    IN_FIFO32_M_Wr_F   <= IN_FIFO32_M_Wr(fifo32_ports(5));
  end generate;

  G: if G_FIFO32_PORTS > 6 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(6)))-1 downto 32 * fifo32_ports(6)) <= IN_FIFO32_S_Data_G;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(6)))-1 downto 16 * fifo32_ports(6)) <= IN_FIFO32_S_Fill_G;
    IN_FIFO32_S_Rd_G  <= IN_FIFO32_S_Rd(fifo32_ports(6));
    
    IN_FIFO32_M_Data_G <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(6)))-1 downto 32 * fifo32_ports(6));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(6)))-1 downto 16 * fifo32_ports(6))  <= IN_FIFO32_M_Rem_G;
    IN_FIFO32_M_Wr_G   <= IN_FIFO32_M_Wr(fifo32_ports(6));
  end generate;

  H: if G_FIFO32_PORTS > 7 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(7)))-1 downto 32 * fifo32_ports(7)) <= IN_FIFO32_S_Data_H;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(7)))-1 downto 16 * fifo32_ports(7)) <= IN_FIFO32_S_Fill_H;
    IN_FIFO32_S_Rd_H  <= IN_FIFO32_S_Rd(fifo32_ports(7));
    
    IN_FIFO32_M_Data_H <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(7)))-1 downto 32 * fifo32_ports(7));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(7)))-1 downto 16 * fifo32_ports(7))  <= IN_FIFO32_M_Rem_H;
    IN_FIFO32_M_Wr_H   <= IN_FIFO32_M_Wr(fifo32_ports(7));
  end generate;

  I: if G_FIFO32_PORTS > 8 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(8)))-1 downto 32 * fifo32_ports(8)) <= IN_FIFO32_S_Data_I;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(8)))-1 downto 16 * fifo32_ports(8)) <= IN_FIFO32_S_Fill_I;
    IN_FIFO32_S_Rd_I  <= IN_FIFO32_S_Rd(fifo32_ports(8));
    
    IN_FIFO32_M_Data_I <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(8)))-1 downto 32 * fifo32_ports(8));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(8)))-1 downto 16 * fifo32_ports(8))  <= IN_FIFO32_M_Rem_I;
    IN_FIFO32_M_Wr_I   <= IN_FIFO32_M_Wr(fifo32_ports(8));
  end generate;

  J: if G_FIFO32_PORTS > 9 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(9)))-1 downto 32 * fifo32_ports(9)) <= IN_FIFO32_S_Data_J;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(9)))-1 downto 16 * fifo32_ports(9)) <= IN_FIFO32_S_Fill_J;
    IN_FIFO32_S_Rd_J  <= IN_FIFO32_S_Rd(fifo32_ports(9));
    
    IN_FIFO32_M_Data_J <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(9)))-1 downto 32 * fifo32_ports(9));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(9)))-1 downto 16 * fifo32_ports(9))  <= IN_FIFO32_M_Rem_J;
    IN_FIFO32_M_Wr_J   <= IN_FIFO32_M_Wr(fifo32_ports(9));
  end generate;

  K: if G_FIFO32_PORTS > 10 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(10)))-1 downto 32 * fifo32_ports(10)) <= IN_FIFO32_S_Data_K;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(10)))-1 downto 16 * fifo32_ports(10)) <= IN_FIFO32_S_Fill_K;
    IN_FIFO32_S_Rd_K  <= IN_FIFO32_S_Rd(fifo32_ports(10));
    
    IN_FIFO32_M_Data_K <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(10)))-1 downto 32 * fifo32_ports(10));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(10)))-1 downto 16 * fifo32_ports(10))  <= IN_FIFO32_M_Rem_K;
    IN_FIFO32_M_Wr_K   <= IN_FIFO32_M_Wr(fifo32_ports(10));
  end generate;

  L: if G_FIFO32_PORTS > 11 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(11)))-1 downto 32 * fifo32_ports(11)) <= IN_FIFO32_S_Data_L;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(11)))-1 downto 16 * fifo32_ports(11)) <= IN_FIFO32_S_Fill_L;
    IN_FIFO32_S_Rd_L  <= IN_FIFO32_S_Rd(fifo32_ports(11));
    
    IN_FIFO32_M_Data_L <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(11)))-1 downto 32 * fifo32_ports(11));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(11)))-1 downto 16 * fifo32_ports(11))  <= IN_FIFO32_M_Rem_L;
    IN_FIFO32_M_Wr_L   <= IN_FIFO32_M_Wr(fifo32_ports(11));
  end generate;

  M: if G_FIFO32_PORTS > 12 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(12)))-1 downto 32 * fifo32_ports(12)) <= IN_FIFO32_S_Data_M;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(12)))-1 downto 16 * fifo32_ports(12)) <= IN_FIFO32_S_Fill_M;
    IN_FIFO32_S_Rd_M  <= IN_FIFO32_S_Rd(fifo32_ports(12));
    
    IN_FIFO32_M_Data_M <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(12)))-1 downto 32 * fifo32_ports(12));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(12)))-1 downto 16 * fifo32_ports(12))  <= IN_FIFO32_M_Rem_M;
    IN_FIFO32_M_Wr_M   <= IN_FIFO32_M_Wr(fifo32_ports(12));
  end generate;
  
  N: if G_FIFO32_PORTS > 13 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(13)))-1 downto 32 * fifo32_ports(13)) <= IN_FIFO32_S_Data_N;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(13)))-1 downto 16 * fifo32_ports(13)) <= IN_FIFO32_S_Fill_N;
    IN_FIFO32_S_Rd_N  <= IN_FIFO32_S_Rd(fifo32_ports(13));
    
    IN_FIFO32_M_Data_N <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(13)))-1 downto 32 * fifo32_ports(13));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(13)))-1 downto 16 * fifo32_ports(13))  <= IN_FIFO32_M_Rem_N;
    IN_FIFO32_M_Wr_N   <= IN_FIFO32_M_Wr(fifo32_ports(13));
  end generate;

  O: if G_FIFO32_PORTS > 14 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(14)))-1 downto 32 * fifo32_ports(14)) <= IN_FIFO32_S_Data_O;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(14)))-1 downto 16 * fifo32_ports(14)) <= IN_FIFO32_S_Fill_O;
    IN_FIFO32_S_Rd_O  <= IN_FIFO32_S_Rd(fifo32_ports(14));
    
    IN_FIFO32_M_Data_O <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(14)))-1 downto 32 * fifo32_ports(14));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(14)))-1 downto 16 * fifo32_ports(14))  <= IN_FIFO32_M_Rem_O;
    IN_FIFO32_M_Wr_O   <= IN_FIFO32_M_Wr(fifo32_ports(14));
  end generate;

  P: if G_FIFO32_PORTS > 15 generate
    IN_FIFO32_S_Data((32 * (1 + fifo32_ports(15)))-1 downto 32 * fifo32_ports(15)) <= IN_FIFO32_S_Data_P;
    IN_FIFO32_S_Fill((16 * (1 + fifo32_ports(15)))-1 downto 16 * fifo32_ports(15)) <= IN_FIFO32_S_Fill_P;
    IN_FIFO32_S_Rd_P  <= IN_FIFO32_S_Rd(fifo32_ports(15));
    
    IN_FIFO32_M_Data_P <= IN_FIFO32_M_Data((32 * (1 + fifo32_ports(15)))-1 downto 32 * fifo32_ports(15));
    IN_FIFO32_M_Rem((16 * (1 + fifo32_ports(15)))-1 downto 16 * fifo32_ports(15))  <= IN_FIFO32_M_Rem_P;
    IN_FIFO32_M_Wr_P   <= IN_FIFO32_M_Wr(fifo32_ports(15));
  end generate;
  

-- Debug
--         OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
--         OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
--         OUT_FIFO32_S_Rd   : in  std_logic;
        
--         OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
--         OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
--         OUT_FIFO32_M_Wr   : in  std_logic;

ila_signals <= ila_signals_ringbus;

--ila_signals(146 downto   0) <= ila_signals_ringbus(146 downto 0);
--ila_signals(255 downto 147) <= (others=>'0');

--ila_signals(113 downto 106)<= OUT_FIFO32_S_Data_debug(31 downto 24);
--ila_signals(117 downto 114)<= OUT_FIFO32_S_Fill_debug(3 downto 0);
--ila_signals(118)           <= OUT_FIFO32_S_Rd;

--ila_signals(126 downto 119)<= OUT_FIFO32_M_Data(31 downto 24);
--ila_signals(129 downto 127)<= OUT_FIFO32_M_Rem_debug(2 downto 0);
--ila_signals(130)           <= OUT_FIFO32_M_Wr;

OUT_FIFO32_S_Data <= OUT_FIFO32_S_Data_debug;
OUT_FIFO32_S_Fill <= OUT_FIFO32_S_Fill_debug;
OUT_FIFO32_M_Rem  <= OUT_FIFO32_M_Rem_debug;

-- Internal FIFOs towards memory controller
mem_ctrl_fifo_out: entity fifo32_v1_00_b.fifo32
    generic map(
        C_FIFO32_DEPTH => 128,
        C_ENABLE_ILA   => 0
    )
    port map(
        Rst => rst,
        FIFO32_S_Clk => clk,
        FIFO32_M_Clk => clk,
        FIFO32_S_Data => OUT_FIFO32_S_Data_debug,
        FIFO32_M_Data => IN_FIFO32_M_Data((32 * (1 + memctrl_ports(0)))-1 downto 32 * memctrl_ports(0)),
        FIFO32_S_Fill => OUT_FIFO32_S_Fill_debug,
        FIFO32_M_Rem => IN_FIFO32_M_Rem((16 * (1 + memctrl_ports(0)))-1 downto 16 * memctrl_ports(0)),
        FIFO32_S_Rd => OUT_FIFO32_S_Rd,
        FIFO32_M_Wr =>IN_FIFO32_M_Wr(memctrl_ports(0))
    );
	
mem_ctrl_fifo_in: entity fifo32_v1_00_b.fifo32
    generic map(
        C_FIFO32_DEPTH => 128,
        C_ENABLE_ILA   => 0
    )
    port map(
        Rst => rst,
        FIFO32_S_Clk => clk,
        FIFO32_M_Clk => clk,
        FIFO32_S_Data => IN_FIFO32_S_Data((32 * (1 + memctrl_ports(0)))-1 downto 32 * memctrl_ports(0)),
        FIFO32_M_Data => OUT_FIFO32_M_Data,
        FIFO32_S_Fill => IN_FIFO32_S_Fill((16 * (1 + memctrl_ports(0)))-1 downto 16 * memctrl_ports(0)),
        FIFO32_M_Rem => OUT_FIFO32_M_Rem_debug,
        FIFO32_S_Rd => IN_FIFO32_S_Rd(memctrl_ports(0)),
        FIFO32_M_Wr =>OUT_FIFO32_M_Wr
    );

-- Internal Management Unit -> connects to proc_control

-- Internal Ringbus
my_ringbus : entity work.ringbus 
    generic map (
        G_TAP_CNT        => C_INTERNAL_PORTS)
    port    map (
        FIFO32_S_Data          => IN_FIFO32_S_Data,
        FIFO32_S_Fill          => IN_FIFO32_S_Fill,
        FIFO32_S_Rd           => IN_FIFO32_S_Rd,
        FIFO32_M_Data         => IN_FIFO32_M_Data,
        FIFO32_M_Rem           => IN_FIFO32_M_Rem,
        FIFO32_M_Wr           => IN_FIFO32_M_Wr,
        clk              => clk,
        rst              => rst,
        ila_signals      => ila_signals_ringbus);   

end architecture;
