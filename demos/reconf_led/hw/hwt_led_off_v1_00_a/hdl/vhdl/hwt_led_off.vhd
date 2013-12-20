library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_01_a;
use reconos_v3_01_a.reconos_pkg.all;

entity hwt_led_off is
	port (
		-- OSIF FIFO ports
		OSIF_FIFO_Sw2Hw_Data    : in  std_logic_vector(31 downto 0);
		OSIF_FIFO_Sw2Hw_Fill    : in  std_logic_vector(15 downto 0);
		OSIF_FIFO_Sw2Hw_Empty   : in  std_logic;
		OSIF_FIFO_Sw2Hw_RE      : out std_logic;

		OSIF_FIFO_Hw2Sw_Data    : out std_logic_vector(31 downto 0);
		OSIF_FIFO_Hw2Sw_Rem     : in  std_logic_vector(15 downto 0);
		OSIF_FIFO_Hw2Sw_Full    : in  std_logic;
		OSIF_FIFO_Hw2Sw_WE      : out std_logic;

		-- MEMIF FIFO ports
		MEMIF_FIFO_Hwt2Mem_Data    : out std_logic_vector(31 downto 0);
		MEMIF_FIFO_Hwt2Mem_Rem     : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_Hwt2Mem_Full    : in  std_logic;
		MEMIF_FIFO_Hwt2Mem_WE      : out std_logic;

		MEMIF_FIFO_Mem2Hwt_Data    : in  std_logic_vector(31 downto 0);
		MEMIF_FIFO_Mem2Hwt_Fill    : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_Mem2Hwt_Empty   : in  std_logic;
		MEMIF_FIFO_Mem2Hwt_RE      : out std_logic;

		HWT_Clk   : in  std_logic;
		HWT_Rst   : in  std_logic;

		USER_Led  : out  std_logic
	);

	attribute SIGIS   : string;

	attribute SIGIS of HWT_Clk   : signal is "Clk";
	attribute SIGIS of HWT_Rst   : signal is "Rst";

end hwt_led_off;

architecture imp of hwt_led_off is
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of IMP: architecture is "true";
	
	constant MBOX_RECV : std_logic_vector(31 downto 0) := x"00000000";
	constant MBOX_SEND : std_logic_vector(31 downto 0) := x"00000001";

	type STATE_TYPE is (STATE_RECV_CMD,STATE_EXEC,STATE_SEND_ACK);

	signal state   : STATE_TYPE;

	signal data    : std_logic_vector(31 downto 0);
	signal ignore  : std_logic_vector(31 downto 0);
	signal counter : std_logic_vector(31 downto 0);

	signal i_osif  : i_osif_t;
	signal o_osif  : o_osif_t;

	signal clk : std_logic;
	signal rst : std_logic;
begin

	clk <= HWT_Clk;
	rst <= HWT_Rst;

	-- ReconOS initilization
	osif_setup (
		i_osif,
		o_osif,
		OSIF_FIFO_Sw2Hw_Data,
		OSIF_FIFO_Sw2Hw_Fill,
		OSIF_FIFO_Sw2Hw_Empty,
		OSIF_FIFO_Hw2Sw_Rem,
		OSIF_FIFO_Hw2Sw_Full,
		OSIF_FIFO_Sw2Hw_RE,
		OSIF_FIFO_Hw2Sw_Data,
		OSIF_FIFO_Hw2Sw_WE
	);

	-- drive memif constant
	MEMIF_FIFO_Hwt2Mem_Data <= (others => '0');
	MEMIF_FIFO_Hwt2Mem_WE <= '0';
	MEMIF_FIFO_Mem2Hwt_RE <= '0';

	USER_Led <= '0';

	-- os and memory synchronisation state machine
	RECONOS_FSM_PROCESS: process (clk,rst) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			done := false;
			state <= STATE_RECV_CMD;
		elsif rising_edge(clk) then
			case state is
				when STATE_RECV_CMD => 
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
					if done then
						counter <= data(31 downto 0);
						state <= STATE_EXEC;
					end if;

				when STATE_EXEC =>
					if or_reduce(counter) = '0' then
						state <= STATE_SEND_ACK;
					else
						counter <= counter - 1;
					end if;

				when STATE_SEND_ACK =>
					osif_set_yield(i_osif, o_osif);
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, (others => '0'), ignore, done);
					if done then
						state <= STATE_RECV_CMD;
					end if;
			end case;
		end if;
	end process RECONOS_FSM_PROCESS;

end architecture imp;

