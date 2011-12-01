library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity fsl_ila is
	port (
		-- OSIF FSL
		FSL_Clk       : in std_logic;                     -- Synchronous clock
		FSL_Rst       : in std_logic;                     -- System reset, should always come from FSL bus
		FSL_S_Clk     : in std_logic;                     -- Slave asynchronous clock
		FSL_S_Read    : in std_logic;                     -- Read signal, requiring next available input to be read
		FSL_S_Data    : in std_logic_vector(31 downto 0); -- Input data
		FSL_S_Control : in std_logic;                     -- Control Bit, indicating the input data are control word
		FSL_S_Exists  : in std_logic;                     -- Data Exist Bit, indicating data exist in the input FSL bus
		FSL_M_Clk     : in std_logic;                     -- Master asynchronous clock
		FSL_M_Write   : in std_logic;                     -- Write signal, enabling writing to output FSL bus
		FSL_M_Data    : in std_logic_vector(31 downto 0); -- Output data
		FSL_M_Control : in std_logic;                     -- Control Bit, indicating the output data are contol word
		FSL_M_Full    : in std_logic;                     -- Full Bit, indicating output FSL bus is full
		
		-- ILA
		control       : in std_logic_vector(0 to 35)
	);
end entity;

architecture implementation of fsl_ila is
	component chipscope_fsl_ila
	PORT (
		CONTROL : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		TRIG0 : IN STD_LOGIC_VECTOR(70 DOWNTO 0)
	);
	end component;
	
	signal data : std_logic_vector(70 downto 0);
begin
	data(0) <= FSL_Rst;
	data(1) <= FSL_S_Read;
	data(33 downto 2) <= FSL_S_Data;
	data(34) <= FSL_S_Control;
	data(35) <= FSL_S_Exists;
	data(36) <= FSL_M_Write;
	data(68 downto 37) <= FSL_M_Data;
	data(69) <= FSL_M_Control;
	data(70) <= FSL_M_Full;                     

	ila_i : chipscope_fsl_ila
	port map (
		CONTROL => control,
		CLK => FSL_Clk,
		TRIG0 => data
	);
	
	
end architecture;

