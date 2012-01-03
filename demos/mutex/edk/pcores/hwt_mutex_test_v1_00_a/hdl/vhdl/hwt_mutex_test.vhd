library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_mutex_test is
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

end hwt_mutex_test;

architecture implementation of hwt_mutex_test is
	type STATE_TYPE is (STATE_MUTEX_LOCK, STATE_WAIT, STATE_MUTEX_UNLOCK, STATE_WAIT_2);
	
	constant C_MUTEX : std_logic_vector(31 downto 0) := X"00000000";

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
		variable counter : integer range 0 to 25000001;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			state <= STATE_MUTEX_LOCK;
			done := False;
		elsif rising_edge(i_osif.clk) then
			case state is
						
				when STATE_MUTEX_LOCK =>
					osif_mutex_lock(i_osif,o_osif,C_MUTEX,ignore,done);
					if done then
						counter := 25000000;  -- 0.25 seconds @ 100MHz
						state <= STATE_WAIT; 
					end if;

				when STATE_WAIT =>
					if counter = 0 then
						state <= STATE_MUTEX_UNLOCK;
					else
						counter := counter - 1;
					end if;
	
				when STATE_MUTEX_UNLOCK =>
					osif_mutex_unlock(i_osif,o_osif,C_MUTEX,ignore,done);
					if done then 
						counter := 2500000;  -- 0.25 seconds @ 100MHz
						state <= STATE_WAIT_2; 
					end if;

				when STATE_WAIT_2 =>
					if counter = 0 then
						state <= STATE_MUTEX_LOCK;
					else
						counter := counter - 1;
					end if;
									
			end case;
		end if;
	end process;
	
end architecture;
