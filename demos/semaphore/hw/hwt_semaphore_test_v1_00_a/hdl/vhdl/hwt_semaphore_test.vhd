library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_semaphore_test is
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

end hwt_semaphore_test;

architecture implementation of hwt_semaphore_test is
	type STATE_TYPE is (STATE_WAIT_A, STATE_POST_B);

	type LOCAL_MEMORY_T is array (0 to 1023) of std_logic_vector(31 downto 0);
	
	constant C_SEMAPHORE_A : std_logic_vector(31 downto 0) := X"00000000";
	constant C_SEMAPHORE_B : std_logic_vector(31 downto 0) := X"00000001";

	signal state  : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
begin

   -- do not use memory interface (memif)
	FIFO32_S_Clk  <= OSFSL_Clk;
	FIFO32_M_Clk  <= OSFSL_Clk;
	FIFO32_M_Data <= (others => '0');
	FIFO32_S_Rd   <= '0';
	FIFO32_M_Wr   <= '0';

	osif_setup(
		i_osif,
		o_osif,
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
		
	-- os and memory synchronisation state machine
	process (i_osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			state <= STATE_WAIT_A;
			done := False;
		elsif rising_edge(i_osif.clk) then
			case state is
						
				when STATE_WAIT_A =>
					osif_sem_wait(i_osif,o_osif,C_SEMAPHORE_A,ignore,done);
					if done then state <= STATE_POST_B; end if;
	
				when STATE_POST_B =>
					osif_sem_post(i_osif,o_osif,C_SEMAPHORE_B,ignore,done);
					if done then state <= STATE_WAIT_A; end if;
									
			end case;
		end if;
	end process;
	
end architecture;
