library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_sort_demo is
	port (
		-- OSIF FSL
		
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);

end entity;

architecture implementation of hwt_sort_demo is
    component hwt_sort_demo_netlist is
	port (
		-- OSIF FSL
		
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);
    end component;

begin
	
    hwt_sort_demo_instance : hwt_sort_demo_netlist
    port map(
        OSFSL_S_Read => OSFSL_S_Read,
        OSFSL_S_Data => OSFSL_S_Data,
		OSFSL_S_Control => OSFSL_S_Control,
		OSFSL_S_Exists => OSFSL_S_Exists,
		
		OSFSL_M_Write => OSFSL_M_Write,
		OSFSL_M_Data  => OSFSL_M_Data,
		OSFSL_M_Control => OSFSL_M_Control,
		OSFSL_M_Full => OSFSL_M_Full,
		
		-- FIFO Interface
		FIFO32_S_Data => FIFO32_S_Data,
		FIFO32_M_Data => FIFO32_M_Data,
		FIFO32_S_Fill => FIFO32_S_Fill,
		FIFO32_M_Rem  => FIFO32_M_Rem,
		FIFO32_S_Rd  => FIFO32_S_Rd,
		FIFO32_M_Wr  => FIFO32_M_Wr,
		
		-- HWT reset and clock
		clk => clk,
		rst => rst
    );

end architecture;
