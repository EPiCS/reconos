library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_pr_block is
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
		FIFO32_S_Data : in  std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
		FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
		FIFO32_S_Rd   : out std_logic;
		FIFO32_M_Wr   : out std_logic;
		
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);
end entity;

architecture implementation of hwt_pr_block is
	type STATE_TYPE is (STATE_GET_VALS,STATE_SEND_RESULT,STATE_THREAD_EXIT);
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal val1   : std_logic_vector(15 downto 0);
	signal val2   : std_logic_vector(15 downto 0);
	signal result1    : std_logic_vector(15 downto 0);
	signal vals   : std_logic_vector(31 downto 0);
	signal result : std_logic_vector(31 downto 0);
begin

	-- do not use memory interface (memif)
	FIFO32_M_Data <= (others => '0');
	FIFO32_S_Rd   <= '0';
	FIFO32_M_Wr   <= '0';

	fsl_setup(i_osif,o_osif,OSFSL_S_Data,OSFSL_S_Exists,OSFSL_M_Full,OSFSL_M_Data,OSFSL_S_Read,OSFSL_M_Write,OSFSL_M_Control);
	
	val1 <= vals(31 downto 16);
	val2 <= vals(15 downto 0);
	result1 <= val1 + val2;
	result <= X"0000"&result1;
		
	-- os and memory synchronisation state machine
	reconos_fsm: process (clk,rst,o_osif) is
		variable done  : boolean;
	begin
		if rst = '1' then
			vals <= (others=>'0');
			osif_reset(o_osif);
			state <= STATE_GET_VALS;
			done  := False;
		elsif rising_edge(clk) then
			case state is
				-- get value no 1
				when STATE_GET_VALS =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, vals, done);
					if done then
						if (vals = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							--state <= STATE_GET_VAL2;
							state <= STATE_SEND_RESULT;
						end if;
					end if;
				-- get value no 2
				--when STATE_GET_VAL2 =>
				--	osif_mbox_get(i_osif, o_osif, MBOX_RECV, val2, done);
				--	if done then
				--		if (val2 = X"FFFFFFFF") then
				--			state <= STATE_THREAD_EXIT;
				--		else
				--			state <= STATE_SEND_RESULT;
				--		end if;
				--	end if;					
				-- send result
				when STATE_SEND_RESULT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, result, ignore, done);
					if done then state <= STATE_GET_VALS; end if;
				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);			
			end case;
		end if;
	end process;
	
end architecture;
