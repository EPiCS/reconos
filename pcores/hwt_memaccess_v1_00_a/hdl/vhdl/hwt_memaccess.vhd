library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_memaccess is
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
		
		-- HWT reset
		rst           : in std_logic
	);

end hwt_memaccess;

architecture implementation of hwt_memaccess is
	type STATE_TYPE is (STATE_GET, STATE_READ, STATE_PUT);

	type LOCAL_MEMORY_T is array (0 to 1023) of std_logic_vector(31 downto 0);
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal addr     : std_logic_Vector(C_FSL_WIDTH-1 downto 0);
	signal data     : std_logic_Vector(C_FSL_WIDTH-1 downto 0);
	signal state  : STATE_TYPE;
	signal osif     : fsl_t;
	signal memif    : memif_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
begin

	fsl_setup(
		osif,
		OSFSL_Clk,
		OSFSL_Rst,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
		
	memif_setup(
		memif,
		OSFSL_Clk,
		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
	-- os and memory synchronisation state machine
	process (osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(osif);
			memif_reset(memif);
			state <= STATE_GET;
			done := False;
			addr <= (others => '0');
			data <= x"AFFE7654";
		elsif rising_edge(osif.clk) then
			case state is
				when STATE_GET =>
					osif_mbox_get(osif, MBOX_RECV, addr, done);
					if done then state <= STATE_READ; end if;
					
				when STATE_READ =>
					memif_read(memif, addr, data, done);
					if done then state <= STATE_PUT; end if;
					
				when STATE_PUT =>
					osif_mbox_put(osif, MBOX_SEND, data, ignore, done);
					if done then state <= STATE_GET; end if;
			end case;
		end if;
	end process;
	
end architecture;
