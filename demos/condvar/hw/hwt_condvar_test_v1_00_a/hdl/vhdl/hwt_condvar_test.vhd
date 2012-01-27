library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_condvar_test is
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

end hwt_condvar_test;

architecture implementation of hwt_condvar_test is
	type STATE_TYPE is (STATE_MUTEX_A_LOCK,
							STATE_CONDVAR_A_WAIT,
							STATE_MUTEX_A_UNLOCK,
							STATE_MUTEX_B_LOCK,
							STATE_CONDVAR_B_SIGNAL,
							STATE_MUTEX_B_UNLOCK);

	constant C_MUTEX_A   : std_logic_vector(31 downto 0) := X"00000000";
	constant C_CONDVAR_A : std_logic_vector(31 downto 0) := X"00000001";
	constant C_MUTEX_B   : std_logic_vector(31 downto 0) := X"00000002";
	constant C_CONDVAR_B : std_logic_vector(31 downto 0) := X"00000003";

	signal state  : STATE_TYPE;
	signal i_osif     : i_osif_t;
	signal o_osif     : o_osif_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
begin

	-- do not use memory interface (memif)
	FIFO32_S_Clk  <= OSFSL_Clk;
	FIFO32_M_Clk  <= OSFSL_Clk;
	FIFO32_M_Data <= (others => '0');
	FIFO32_S_Rd   <= '0';
	FIFO32_M_Wr   <= '0';

	fsl_setup(
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
	process (i_osif.clk, rst) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			state <= STATE_MUTEX_A_LOCK;
			done := False;
		elsif rising_edge(i_osif.clk) then
			case state is
				when STATE_MUTEX_A_LOCK =>
					osif_mutex_lock(i_osif,o_osif,C_MUTEX_A,ignore,done);
					if done then state <= STATE_CONDVAR_A_WAIT; end if;
				
				when STATE_CONDVAR_A_WAIT =>
					osif_cond_wait(i_osif,o_osif,C_CONDVAR_A,C_MUTEX_A,ignore,done);
					if done then state <= STATE_MUTEX_A_UNLOCK; end if;
				
				when STATE_MUTEX_A_UNLOCK =>
					osif_mutex_unlock(i_osif,o_osif,C_MUTEX_A,ignore,done);
					if done then state <= STATE_MUTEX_B_LOCK; end if;
				
				when STATE_MUTEX_B_LOCK =>
					osif_mutex_lock(i_osif,o_osif,C_MUTEX_B,ignore,done);
					if done then state <= STATE_CONDVAR_B_SIGNAL; end if;			

				when STATE_CONDVAR_B_SIGNAL =>
					osif_cond_signal(i_osif,o_osif,C_CONDVAR_B,ignore,done);
					if done then state <= STATE_MUTEX_B_UNLOCK; end if;
					
				when STATE_MUTEX_B_UNLOCK =>
					osif_mutex_unlock(i_osif,o_osif,C_MUTEX_B,ignore,done);
					if done then state <= STATE_MUTEX_A_LOCK;	end if;					
			end case;
		end if;
	end process;
	
end architecture;
