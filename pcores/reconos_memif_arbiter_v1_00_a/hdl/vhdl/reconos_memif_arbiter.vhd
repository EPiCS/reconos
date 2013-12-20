--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - MEMIF Arbiter
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  The arbiter connects the different HWTs
--                 to the memory system of ReconOS. It acts as an
--                 arbiter and controls the the memory access. For
--                 further details on how the memory system in ReconOS
--                 works take a look into the documentation (memory.txt)
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity reconos_memif_arbiter is
	generic (
		C_NUM_HWTS           : integer := 1;
		C_MEMIF_FIFO_WIDTH   : integer := 32;
		C_CTRL_FIFO_WIDTH    : integer := 32;
		
		C_MEMIF_LENGTH_WIDTH : integer := 24
	);
	port (
		-- Input ports from HWTs
		-- ## BEGIN GENERATE LOOP ##
		MEMIF_FIFO_In_Hwt2Mem_Data_#i#   : in  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_In_Hwt2Mem_Fill_#i#   : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_In_Hwt2Mem_Empty_#i#  : in  std_logic;
		MEMIF_FIFO_In_Hwt2Mem_RE_#i#     : out std_logic;

		MEMIF_FIFO_In_Mem2Hwt_Data_#i#   : out std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_In_Mem2Hwt_Rem_#i#    : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_In_Mem2Hwt_Full_#i#   : in  std_logic;
		MEMIF_FIFO_In_Mem2Hwt_WE_#i#     : out std_logic;
		-- ## END GENERATE LOOP ##


		-- Multiplexed output ports
		MEMIF_FIFO_Out_Hwt2Mem_Data   : out std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_Out_Hwt2Mem_Fill   : out std_logic_vector(15 downto 0);
		MEMIF_FIFO_Out_Hwt2Mem_Empty  : out std_logic;
		MEMIF_FIFO_Out_Hwt2Mem_RE     : in  std_logic;

		MEMIF_FIFO_Out_Mem2Hwt_Data   : in  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_Out_Mem2Hwt_Rem    : out std_logic_vector(15 downto 0);
		MEMIF_FIFO_Out_Mem2Hwt_Full   : out std_logic;
		MEMIF_FIFO_Out_Mem2Hwt_WE     : in  std_logic;
		
		-- Control FIFO for memory subsystem
		-- REMARK: This is not a master interface of a FIFO.
		--         We emulate the FIFO directly to avoid delays.
		CTRL_FIFO_Out_Data    : out std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
		CTRL_FIFO_Out_Fill    : out std_logic_vector(15 downto 0);
		CTRL_FIFO_Out_Empty   : out std_logic;
		CTRL_FIFO_Out_RE      : in  std_logic;

		-- Transaction control ports
		TCTRL_Clk : in std_logic;
		TCTRL_Rst : in std_logic
	);

	attribute SIGIS   : string;

	attribute SIGIS of TCTRL_Clk   : signal is "Clk";
	attribute SIGIS of TCTRL_Rst   : signal is "Rst";

end entity reconos_memif_arbiter;

architecture implementation of reconos_memif_arbiter is

	-- Definition of MEMIF datatypes for easier handling of the FIFOs
	type memif_fifo_t is record
		hw2mem_data   : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		hw2mem_fill   : std_logic_vector(15 downto 0);
		hw2mem_empty  : std_logic;
		hw2mem_re     : std_logic;
		mem2hw_data   : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		mem2hw_rem    : std_logic_vector(15 downto 0);
		mem2hw_full   : std_logic;
		mem2hw_we     : std_logic;
	end record;
	
	-- Signals to control HWT-MEMIF from this control unit
	signal hw2mem_data   : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal hw2mem_fill   : std_logic_vector(15 downto 0);
	signal hw2mem_empty  : std_logic;
	signal hw2mem_re     : std_logic;
	signal mem2hw_data   : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal mem2hw_rem    : std_logic_vector(15 downto 0);
	signal mem2hw_full   : std_logic;
	signal mem2hw_we     : std_logic;
	
	-- Array which contains all connected MEMIFs for easier handling
	type memif_t is array(0 to C_NUM_HWTS - 1) of memif_fifo_t;
	signal memif : memif_t;
	
	signal memif_select  : integer range 0 to C_NUM_HWTS - 1;
	signal memif_empty   : std_logic_vector(0 to C_NUM_HWTS - 1);
	
	-- Transaction control signals
	type STATE_TYPE is (WAIT_REQUEST, READ_CMD, READ_ADDR, SERV_REQUEST);
	signal state : STATE_TYPE;
	
	signal ctrl_cmd     : std_logic_vector(C_MEMIF_FIFO_WIDTH - C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	signal ctrl_length  : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	signal ctrl_addr    : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);

	signal tctrl_bytes_rem  : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);

begin

	-- This process multiplexes the MEMIFs to the right output
	-- dependend on the current state
	mux_proc : process(state,memif,memif_select,
	                   hw2mem_re,hw2mem_data,
	                   mem2hw_we,mem2hw_data,
	                   CTRL_FIFO_Out_RE,
	                   -- sensitivity list for MEMIF-FIFOs
	                   -- ## BEGIN GENERATE LOOP ##
	                   MEMIF_FIFO_In_Hwt2Mem_Data_#i#,MEMIF_FIFO_In_Hwt2Mem_Fill_#i#,MEMIF_FIFO_In_Hwt2Mem_Empty_#i#,
	                   MEMIF_FIFO_In_Mem2Hwt_Rem_#i#,MEMIF_FIFO_In_Mem2Hwt_Full_#i#,
	                   -- ## END GENERATE LOOP ##
	                   MEMIF_FIFO_Out_Hwt2Mem_RE, MEMIF_FIFO_Out_Mem2Hwt_Data, MEMIF_FIFO_Out_Mem2Hwt_WE
	                   ) is
	begin
		-- Assign MEMIF_FIFOs to array
		-- this could be done outside this process but because
		-- of the behaviour of VHDL-record we can not drive different
		-- components of a record in different processes
		-- ## BEGIN GENERATE LOOP ##
		memif(#i#).hw2mem_data        <= MEMIF_FIFO_In_Hwt2Mem_Data_#i#;
		memif(#i#).hw2mem_fill        <= MEMIF_FIFO_In_Hwt2Mem_Fill_#i#;
		memif(#i#).hw2mem_empty       <= MEMIF_FIFO_In_Hwt2Mem_Empty_#i#;
		MEMIF_FIFO_In_Hwt2Mem_RE_#i#  <= memif(#i#).hw2mem_re;

		MEMIF_FIFO_In_Mem2Hwt_Data_#i#  <= memif(#i#).mem2hw_data;
		memif(#i#).mem2hw_rem           <= MEMIF_FIFO_In_Mem2Hwt_Rem_#i#;
		memif(#i#).mem2hw_full          <= MEMIF_FIFO_In_Mem2Hwt_Full_#i#;
		MEMIF_FIFO_In_Mem2Hwt_WE_#i#    <= memif(#i#).mem2hw_we;
			
		memif_empty(#i#) <= not MEMIF_FIFO_In_Hwt2Mem_Empty_#i#;
		-- ## END GENERATE LOOP ##

			
		-- default values for not connected ports
		-- later assignments will override this defaults
		for i in 0 to C_NUM_HWTS - 1 loop
			memif(i).hw2mem_re <= '0';
			memif(i).mem2hw_we <= '0';
			
			memif(i).mem2hw_data <= (others => '0');
		end loop;
		
		MEMIF_FIFO_Out_Hwt2Mem_Empty <= '1';
		MEMIF_FIFO_Out_Hwt2Mem_Fill  <= (others => '0');
		MEMIF_FIFO_Out_Hwt2Mem_Data  <= (others => '0');
		
		MEMIF_FIFO_Out_Mem2Hwt_Full  <= '1';
		MEMIF_FIFO_Out_Mem2Hwt_Rem   <= (others => '0');
		
		CTRL_FIFO_Out_Empty <= '1';
		CTRL_FIFO_Out_Fill  <= (others => '0');
		CTRL_FIFO_Out_Data  <= (others => '0');
		
		hw2mem_data <= (others => '0');


		case state is
			when WAIT_REQUEST  =>
				-- Connect MEMIF-FIFO to this control unit
				hw2mem_data                     <= memif(memif_select).hw2mem_data;
				hw2mem_fill                     <= memif(memif_select).hw2mem_fill;
				hw2mem_empty                    <= memif(memif_select).hw2mem_empty; 
				memif(memif_select).hw2mem_re   <= hw2mem_re;

				memif(memif_select).mem2hw_data <= mem2hw_data;
				mem2hw_rem                      <= memif(memif_select).mem2hw_rem;
				mem2hw_full                     <= memif(memif_select).mem2hw_full;
				memif(memif_select).mem2hw_we   <= mem2hw_we;

			when READ_CMD | READ_ADDR =>
				-- Connecting hw2mem that the memory subsystem can read the command
				CTRL_FIFO_Out_Data              <= memif(memif_select).hw2mem_data;
				CTRL_FIFO_Out_Fill              <= memif(memif_select).hw2mem_fill;
				CTRL_FIFO_Out_Empty             <= memif(memif_select).hw2mem_empty;
				memif(memif_select).hw2mem_re   <= CTRL_FIFO_Out_RE;
				
				hw2mem_data <= memif(memif_select).hw2mem_data;

			when others =>
				-- Connecting selected MEMIF-FIFO to output
				MEMIF_FIFO_Out_Hwt2Mem_Data      <= memif(memif_select).hw2mem_data;
				MEMIF_FIFO_Out_Hwt2Mem_Fill      <= memif(memif_select).hw2mem_fill;
				MEMIF_FIFO_Out_Hwt2Mem_Empty     <= memif(memif_select).hw2mem_empty; 
				memif(memif_select).hw2mem_re    <= MEMIF_FIFO_Out_Hwt2Mem_RE;

				memif(memif_select).mem2hw_data  <= MEMIF_FIFO_Out_Mem2Hwt_Data;
				MEMIF_FIFO_Out_Mem2Hwt_Rem       <= memif(memif_select).mem2hw_rem;
				MEMIF_FIFO_Out_Mem2Hwt_Full      <= memif(memif_select).mem2hw_full;
				memif(memif_select).mem2hw_we    <= MEMIF_FIFO_Out_Mem2Hwt_WE;
			end case;
	end process mux_proc;


	schedule_proc : process(TCTRL_Clk,TCTRL_Rst) is
		variable pos : integer;
	begin
		if TCTRL_Rst = '1' then
			state <= WAIT_REQUEST;

			memif_select <= 0;
			
			hw2mem_re   <= '0';
			mem2hw_we   <= '0';
			mem2hw_data <= (others => '0');
		elsif rising_edge(TCTRL_Clk) then
			case state is
				when WAIT_REQUEST =>
					hw2mem_re <= '0';
					mem2hw_we <= '0';

					-- a request is present, if a FIFO is not empty
					if or_reduce(memif_empty) = '1' then
						-- find out the next request to server with a simple schedule
						-- start to look at FIFOs after the last position and find the first
						-- one which is not empty				
						for i in 1 to C_NUM_HWTS loop
							pos := (memif_select + i) mod C_NUM_HWTS;

							if memif_empty(pos) = '1' then
								memif_select <= pos;
								exit;
							end if;
						end loop;

						state <= READ_CMD;
					end if;

				when READ_CMD =>
					if CTRL_FIFO_Out_RE = '1' then
						ctrl_cmd <= hw2mem_data(31 downto C_MEMIF_LENGTH_WIDTH);
						ctrl_length <= hw2mem_data(C_MEMIF_LENGTH_WIDTH - 1 downto 0);

						state <= READ_ADDR;
					end if;

				when READ_ADDR =>
					if CTRL_FIFO_Out_RE = '1' then
						ctrl_addr <= hw2mem_data;

						tctrl_bytes_rem <= ctrl_length(C_MEMIF_LENGTH_WIDTH - 1 downto 2) & "00";
						state <= SERV_REQUEST;
					end if;

				when SERV_REQUEST =>
					-- count number of written/read words to find end of transaction
					if MEMIF_FIFO_Out_Hwt2Mem_RE = '1' or MEMIF_FIFO_Out_Mem2Hwt_WE = '1' then
						tctrl_bytes_rem <= tctrl_bytes_rem - 4;

						if or_reduce(tctrl_bytes_rem - 4) = '0' then
							state <= WAIT_REQUEST;
						end if;
					end if;
			end case;
		end if;
	end process schedule_proc;

end architecture implementation;
