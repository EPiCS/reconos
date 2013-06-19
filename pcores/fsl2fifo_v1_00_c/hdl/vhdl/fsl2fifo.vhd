library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity fsl2fifo is
	port (
		-- OSIF FSL
		
		FSL_S_Read    : in  std_logic;                 -- Read signal, requiring next available input to be read
		FSL_S_Data    : out std_logic_vector(0 to 31); -- Input data
		FSL_S_Control : out std_logic;                 -- Control Bit, indicating the input data are control word
		FSL_S_Exists  : out std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		FSL_M_Write   : in  std_logic;                 -- Write signal, enabling writing to output FSL bus
		FSL_M_Data    : in  std_logic_vector(0 to 31); -- Output data
		FSL_M_Control : in  std_logic;                 -- Control Bit, indicating the output data are contol word
		FSL_M_Full    : out std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_M_Wr : out std_logic
	);

end entity;

architecture implementation of fsl2fifo is

begin
  FIFO32_S_Rd <= FSL_S_Read;
  FSL_S_Data  <= FIFO32_S_Data;
  FSL_S_Control <= '0';
  FSL_S_Exists <= '0' when FIFO32_S_Fill = X"0000" else
                  '1';

  FIFO32_M_Wr <= FSL_M_Write;
  FIFO32_M_Data <= FSL_M_Data;
  FSL_M_Full <= '1' when FIFO32_M_Rem = X"0000" else
                '0';
  -- FSL_M_Control is igrnored


end architecture;
