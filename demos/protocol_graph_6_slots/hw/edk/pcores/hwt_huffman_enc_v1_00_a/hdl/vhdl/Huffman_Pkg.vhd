--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Huffman_Pkg is

	type huffman_enc_type is record
		bufferIn  	: STD_LOGIC_VECTOR(23 downto 0);
		posbufferIn : integer range 0 to 24;
		len			: integer range 0 to 1600;
		eof			: STD_LOGIC;
	end record;
	
	type huffman_dec_type is record
		bufferIn  	: STD_LOGIC_VECTOR(23 downto 0);
		posbufferIn : integer range 0 to 24;
		len			: integer range 0 to 1600;
		eof			: STD_LOGIC;
	end record;
	
	constant REG_NR						  : integer := 256; -- effective 256
	constant REG_LEN						  : integer := 22;  -- effective 22
	
	constant MAX_LEN						  : integer := 17;
	constant MIN_LEN						  : integer := 3;
	
	type STATE_TYPE is (WAIT_FOR_CODE, STATE_GET_CODE, STATE_ACK);
	type FORWARD_TYPE is (NEUTRAL, ANALYZE, WAIT_PRECODE, PRECODE, CODE, POSTCODE, FORWARD);  
	type state_fsm is (Neutral, MoreData, DecodeStart, DecodeProc1, DecodeProc2, DecodeEnd); 
	
	type REG_BANK is array (0 to REG_NR-1) of STD_LOGIC_VECTOR(REG_LEN-1 downto 0);


component huffman_enc
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
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
		
		rst       : in std_logic;
		osif_clk : out std_logic;	
		-- Input Interface
		DataInxD     : in std_logic_vector(7 downto 0);
		ValidInxS    : in std_logic;
		SofInxS      : in std_logic;
		EofInxS      : in std_logic;
		ReadyOutxS   : out std_logic;
		
		-- Output Interface
		FullInxS	 : in std_logic;
		DataOutxD  	 : out std_logic_vector(9 downto 0);
		ValidOutxS 	 : out std_logic
	);
end component;

component huffman_dec
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Clk : out std_logic;
		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;

		rst      : in std_logic;

		-- Input Interface
		DataInxD     : in std_logic_vector(7 downto 0);
		ValidInxS    : in std_logic;
		SofInxS      : in std_logic;
		EofInxS      : in std_logic;
		ReadyOutxS   : out std_logic;
		
		-- Output Interface
		FullInxS	 : in std_logic;
		DataOutxD  	 : out std_logic_vector(9 downto 0);
		ValidOutxS 	 : out std_logic
	);
end component;

COMPONENT Fifo_Huff
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT fifo_bram
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;


end Huffman_Pkg;

package body Huffman_Pkg is


 
end Huffman_Pkg;
