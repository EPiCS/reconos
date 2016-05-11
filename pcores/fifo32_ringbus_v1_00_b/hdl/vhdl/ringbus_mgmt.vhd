

-- @module : ringbus_mgmt
-- @author : meise
-- @date   : 09.09.2015


library ieee;
use ieee.std_logic_1164.all;


-- Handles options and errors of the ringbus and connected modules
entity ringbus_mgmt is 
generic (G_ADDRESS : unsigned :=63);
port (
    clk			: in	  std_logic;
    rst : in std_logic;
    
    	-- FIFO32 interface
    	FIFO32_S_Data_A : in  std_logic_vector(31 downto 0);
		FIFO32_S_Fill_A : in  std_logic_vector(15 downto 0);
		FIFO32_S_Rd_A   : out std_logic;

		FIFO32_M_Data_A : out std_logic_vector(31 downto 0);
		FIFO32_M_Rem_A  : in  std_logic_vector(15 downto 0);
		FIFO32_M_Wr_A   : out std_logic;
		
        -- Run-time options
        RUNTIME_OPTIONS : in std_logic_vector(15 downto 0 );
        
        -- Error reporting
        ERROR_REQ : out std_logic;
        ERROR_ACK : in  std_logic;
        ERROR_TYP : out std_logic_vector(7 downto 0);
        ERROR_ADR : out std_logic_vector(31 downto 0)
    
    ); 
     
end ringbus_mgmt;     
        

architecture synth of ringbus_mgmt is
               
begin  

end synth;








