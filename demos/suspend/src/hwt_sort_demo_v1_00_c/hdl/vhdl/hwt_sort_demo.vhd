--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        Sort Demo Suspendable
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  Sort thread implementing a bubblesorter which can be
--                 interrupted and saves its state.
--
-- ======================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_01_a;
use reconos_v3_01_a.reconos_pkg.all;
use reconos_v3_01_a.reconos_app_pkg.all;

entity hwt_sort_demo is
	--
	-- Port defintions
	--
	--   OSIF_Sw2Hw_/OSIF_Hw2Sw - fifo signals for osif
	--
	--   MEMIF_Hwt2Mem_/MEMIF_Mem2Hwt_ - fifo signals for memif
	--   
	--   HWT_Clk    - hardware thread clock
	--   HWT_Rst    - hardware thread reset
	--   HWT_Signal - hardware thread interrupt
	--
	port (
		OSIF_Sw2Hw_Data    : in  std_logic_vector(31 downto 0);
		OSIF_Sw2Hw_Empty   : in  std_logic;
		OSIF_Sw2Hw_RE      : out std_logic;

		OSIF_Hw2Sw_Data    : out std_logic_vector(31 downto 0);
		OSIF_Hw2Sw_Full    : in  std_logic;
		OSIF_Hw2Sw_WE      : out std_logic;

		MEMIF_Hwt2Mem_Data    : out std_logic_vector(31 downto 0);
		MEMIF_Hwt2Mem_Full    : in  std_logic;
		MEMIF_Hwt2Mem_WE      : out std_logic;

		MEMIF_Mem2Hwt_Data    : in  std_logic_vector(31 downto 0);
		MEMIF_Mem2Hwt_Empty   : in  std_logic;
		MEMIF_Mem2Hwt_RE      : out std_logic;

		HWT_Clk     : in  std_logic;
		HWT_Rst     : in  std_logic;
		HWT_Signal  : in  std_logic
	);
end entity hwt_sort_demo;

architecture implementation of hwt_sort_demo is
	--
	-- Definition of ReconOS signals.
	--
	--   i/o_osif  - signals from osif
	--   i/o_memif - signals from memif
	--   i/o_ram   - signals from local ram
	--
	signal i_osif  : i_osif_t;
	signal o_osif  : o_osif_t;
	signal i_memif : i_memif_t;
	signal o_memif : o_memif_t;
	signal i_ram   : i_ram_t;
	signal o_ram   : o_ram_t;

	--
	-- Definition of resources.
	--
	--   mbox_recv - mbox to receive data
	--   mbox_send - mbox to send acknowledgments
	--
	constant MBOX_RECV : std_logic_vector(31 downto 0) := SORTDEMO_RESOURCES_ADDRESS;
	constant MBOX_SEND : std_logic_vector(31 downto 0) := SORTDEMO_RESOURCES_ACKNOWLEDGE;

	--
	-- Definition of the local RAM. The local RAM will be implemented as
	-- a block-RAM. Therefore, take care to apply proper timing.
	--
	--   c_local_ram_size_words    - size of the local RAM in 32-bit words
	--   c_local_ram_size_bytes    - size of the local RAM in bytes
	--
	--   ram_t - type for the RAM
	--
	--   ram           - the local RAM itself
	--   ram_addr_0/1  - address signal
	--   ram_idata_0/1 - input data (for writing to RAM)
	--   ram_odata_0/1 - output data (for reading from RAM)
	--   ram_we_0/1    - write enable
	--
	constant C_RAM_SIZE_WORDS    : integer := 2048;
	constant C_RAM_SIZE_BYTES    : integer := 4 * C_RAM_SIZE_WORDS;

	type RAM_T is array (0 to C_RAM_SIZE_WORDS - 1) of std_logic_vector(31 downto 0);

	shared variable ram : RAM_T;
	signal ram_addr_0, ram_addr_1   : std_logic_vector(31 downto 0);
	signal ram_idata_0, ram_idata_1 : std_logic_vector(31 downto 0);
	signal ram_odata_0, ram_odata_1 : std_logic_vector(31 downto 0);
	signal ram_we_0, ram_we_1       : std_logic;

	--
	-- Definition of the states for the ReconOS-FSM.
	--
	--   state_type - type for the different states
	--
	--   state      - the state itself
	--
	type STATE_TYPE is (STATE_GET_ADDR, STATE_READ_DATA, STATE_WRITE_DATA, STATE_PUT_ACK,
	                    STATE_SORT, STATE_SORT_START_OVER, STATE_SORT_LOAD_A_WAIT, STATE_SORT_LOAD_A,
	                    STATE_SORT_LOAD_B_WAIT, STATE_SORT_LOAD_B, STATE_SORT_COMPARE, STATE_SORT_LOOP,
	                    STATE_SUSPEND, STATE_SUSPEND_STATE, STATE_SUSPEND_ADDR, STATE_SUSPEND_PTR_MAX, STATE_SUSPEND_SWAPPED, STATE_SUSPEND_DATA,
	                    STATE_RESUME, STATE_RESUME_STATE, STATE_RESUME_ADDR, STATE_RESUME_PTR_MAX, STATE_RESUME_SWAPPED, STATE_RESUME_DATA,
	                    STATE_INIT, STATE_EXIT);

	signal state : STATE_TYPE;

	--
	-- Signals used by the Sort-Demo.
	--
	signal ret          : std_logic_vector(31 downto 0);
	signal state_addr   : std_logic_vector(31 downto 0);
	signal state_tmp    : STATE_TYPE;

	signal addr         : std_logic_vector(31 downto 0);
	signal ptr, ptr_max : std_logic_vector(31 downto 0);
	signal a, b         : std_logic_vector(31 downto 0);
	signal swapped      : std_logic;

	constant SORT_LEN_BYTES : std_logic_vector(31 downto 0) := x"00002000";
	constant SORT_LEN_WORDS : std_logic_vector(31 downto 0) := x"00000800";
begin
	--
	-- Description of local RAM. This pattern will be recognized by XST to
	-- implement a block-RAM.
	--
	--   @see Xilinx XST User Guide (UG687)
	--
	local_ram_0 : process (HWT_Clk) is
	begin
		if (rising_edge(HWT_Clk)) then
			if (ram_we_0 = '1') then
				ram(CONV_INTEGER(ram_addr_0)) := ram_idata_0;
			else
				ram_odata_0 <= ram(CONV_INTEGER(ram_addr_0));
			end if;
		end if;
	end process local_ram_0;

	local_ram_1 : process (HWT_Clk) is
	begin
		if (rising_edge(HWT_Clk)) then
			if (ram_we_1 = '1') then
				ram(CONV_INTEGER(ram_addr_1)) := ram_idata_1;
			else
				ram_odata_1 <= ram(CONV_INTEGER(ram_addr_1));
			end if;
		end if;
	end process local_ram_1;
	
	--
	-- ReconOS setup functions assigning records.
	--
	osif_setup (
		i_osif,
		o_osif,
		OSIF_Sw2Hw_Data,
		OSIF_Sw2Hw_Empty,
		OSIF_Sw2Hw_RE,
		OSIF_Hw2Sw_Data,
		OSIF_Hw2Sw_Full,
		OSIF_Hw2Sw_WE
	);

	memif_setup (
		i_memif,
		o_memif,
		MEMIF_Mem2Hwt_Data,
		MEMIF_Mem2Hwt_Empty,
		MEMIF_Mem2Hwt_RE,
		MEMIF_Hwt2Mem_Data,
		MEMIF_Hwt2Mem_Full,
		MEMIF_Hwt2Mem_WE
	);

	ram_setup (
		i_ram,
		o_ram,
		ram_addr_0,
		ram_idata_0,
		ram_odata_0,
		ram_we_0
	);

	--
	-- ReconOS-FSM doing all synchronization with other threads by using
	-- the ReconOS-package functions.
	--
	reconos_fsm: process (HWT_Clk,HWT_Rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if HWT_Rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);

			state <= STATE_INIT;
		elsif rising_edge(HWT_Clk) then
			ram_we_1 <= '0';

			case state is
				--
				-- Starting end exiting the hardware thread
				--
				when STATE_INIT =>
					osif_read(i_osif, o_osif, ret, done);
					if done then
						if ret = OSIF_SIGNAL_THREAD_START then
							state <= STATE_GET_ADDR;
						elsif ret = OSIF_SIGNAL_THREAD_RESUME then
							state <= STATE_RESUME;
						end if;
					end if;

				when STATE_EXIT =>
					osif_thread_exit(i_osif, o_osif);

				--
				-- Execution of Sort-Demo
				--
				when STATE_GET_ADDR =>
					if HWT_Signal = '1' then
						osif_reset(o_osif);
						memif_reset(o_memif);
						state_tmp <= STATE_GET_ADDR;
						state <= STATE_SUSPEND;
					else
						osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr, done);
						if done then
							state <= STATE_READ_DATA;
						end if;
					end if;

				when STATE_READ_DATA =>
					memif_read(i_ram, o_ram, i_memif, o_memif, addr, x"00000000", SORT_LEN_BYTES, done);
					if done then
						state <= STATE_SORT;
					end if;

				when STATE_SORT =>
					ptr_max <= SORT_LEN_WORDS - 1;
					swapped <= '1';
					state <= STATE_SORT_START_OVER;

				when STATE_SORT_START_OVER =>
					if HWT_Signal = '1' then
						osif_reset(o_osif);
						memif_reset(o_memif);
						state_tmp <= STATE_SORT_START_OVER;
						state <= STATE_SUSPEND;
					else
						if swapped = '0' or ptr_max = x"00000000" then
							state <= STATE_WRITE_DATA;
						else
							ptr <= x"00000000";
							ptr_max <= ptr_max - 1;
							swapped <= '0';

							ram_addr_1 <= x"00000000";
							state <= STATE_SORT_LOAD_A_WAIT;
						end if;
					end if;

				when STATE_SORT_LOAD_A_WAIT =>
					ram_addr_1 <= ptr + 1;
					state <= STATE_SORT_LOAD_A;

				when STATE_SORT_LOAD_A =>
					a <= ram_odata_1;
					state <= STATE_SORT_LOAD_B;

				when STATE_SORT_LOAD_B_WAIT =>
					state <= STATE_SORT_LOAD_B;

				when STATE_SORT_LOAD_B =>
					b <= ram_odata_1;
					state <= STATE_SORT_COMPARE;

				when STATE_SORT_COMPARE =>
					if a > b then
						swapped <= '1';
						a <= b;
						b <= a;

						ram_addr_1 <= ptr;
						ram_we_1 <= '1';
						ram_idata_1 <= b;
					end if;

					state <= STATE_SORT_LOOP;

				when STATE_SORT_LOOP =>
					if ptr = ptr_max then
						ram_addr_1 <= ptr + 1;
						ram_we_1 <= '1';
						ram_idata_1 <= b;

						state <= STATE_SORT_START_OVER;
					else
						ptr <= ptr + 1;
						a <= b;

						ram_addr_1 <= ptr + 2;
						state <= STATE_SORT_LOAD_B_WAIT;
					end if;

				when STATE_WRITE_DATA =>
					memif_write(i_ram, o_ram, i_memif, o_memif, x"00000000", addr, SORT_LEN_BYTES, done);
					if done then
						state <= STATE_PUT_ACK;
					end if;

				when STATE_PUT_ACK =>
					if HWT_Signal = '1' then
						osif_reset(o_osif);
						memif_reset(o_memif);
						state_tmp <= STATE_PUT_ACK;
						state <= STATE_SUSPEND;
					else
						osif_mbox_put(i_osif, o_osif, MBOX_SEND, x"00000000", ret, done);
						if done then
							state <= STATE_GET_ADDR;
						end if;
					end if;

				-- 
				-- Suspending the hardware thread and saving its state
				--
				when STATE_SUSPEND =>
					osif_call_0_1(i_osif, o_osif, OSIF_CMD_THREAD_GET_STATE_ADDR, state_addr, done);
					if done then
						state <= STATE_SUSPEND_STATE;
					end if;

				when STATE_SUSPEND_STATE =>
					case state_tmp is
						when STATE_READ_DATA =>
							memif_write_word(i_memif, o_memif, state_addr, x"00000001", done);
						when STATE_SORT_START_OVER =>
							memif_write_word(i_memif, o_memif, state_addr, x"00000002", done);
						when STATE_PUT_ACK =>
							memif_write_word(i_memif, o_memif, state_addr, x"00000003", done);
						when others =>
					end case;

					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_SUSPEND_ADDR;
					end if;

				when STATE_SUSPEND_ADDR =>
					memif_write_word(i_memif, o_memif, state_addr, addr, done);
					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_SUSPEND_PTR_MAX;
					end if;

				when STATE_SUSPEND_PTR_MAX =>
					memif_write_word(i_memif, o_memif, state_addr, ptr_max, done);
					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_SUSPEND_SWAPPED;
					end if;

				when STATE_SUSPEND_SWAPPED =>
					memif_write_word(i_memif, o_memif, state_addr, x"0000000" & b"000" & swapped, done);
					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_SUSPEND_DATA;
					end if;

				when STATE_SUSPEND_DATA =>
					memif_write(i_ram, o_ram, i_memif, o_memif, x"00000000", state_addr, SORT_LEN_BYTES, done);
					if done then
						state <= STATE_EXIT;
					end if;

				-- 
				-- Resuming the hardware thread and restoring its state
				--
				when STATE_RESUME =>
					osif_call_0_1(i_osif, o_osif, OSIF_CMD_THREAD_GET_STATE_ADDR, state_addr, done);
					if done then
						state <= STATE_RESUME_STATE;
					end if;

				when STATE_RESUME_STATE =>
					memif_read_word(i_memif, o_memif, state_addr, ret, done);
					if done then
						case ret is
							when x"00000001" =>
								state_tmp <= STATE_READ_DATA;
							when x"00000002" =>
								state_tmp <= STATE_SORT_START_OVER;
							when x"00000003" =>
								state_tmp <= STATE_PUT_ACK;
							when others =>
						end case;

						state_addr <= state_addr + x"00000004";
						state <= STATE_RESUME_ADDR;
					end if;


				when STATE_RESUME_ADDR =>
					memif_read_word(i_memif, o_memif, state_addr, addr, done);
					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_RESUME_PTR_MAX;
					end if;

				when STATE_RESUME_PTR_MAX =>
					memif_read_word(i_memif, o_memif, state_addr, ptr_max, done);
					if done then
						state_addr <= state_addr + x"00000004";
						state <= STATE_RESUME_SWAPPED;
					end if;

				when STATE_RESUME_SWAPPED =>
					memif_read_word(i_memif, o_memif, state_addr, ret, done);
					if done then
						swapped <= ret(0);
						state_addr <= state_addr + x"00000004";
						state <= STATE_RESUME_DATA;
					end if;

				when STATE_RESUME_DATA =>
					memif_read(i_ram, o_ram, i_memif, o_memif, state_addr, x"00000000", SORT_LEN_BYTES, done);
					if done then
						state <= state_tmp;
					end if;
			end case;
		end if;
	end process;
	
end architecture;