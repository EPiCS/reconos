--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - MEMIF Memory controller - Controller impl
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  The memory controller connects the memory subsystem of
--                 ReconOS to the memory bus of the system as an AXI
--                 master.
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;


entity user_logic is
	generic (
		-- Memory controller parameters
		C_MEMIF_FIFO_WIDTH     : integer   := 32;
		C_CTRL_FIFO_WIDTH      : integer   := 32;

		C_MEMIF_LENGTH_WIDTH   : integer   := 24;

		C_USE_MMU_PORT         : boolean   := true;

		-- Bus protocol parameters, do not add to or delete
		C_MST_NATIVE_DATA_WIDTH   : integer   := 32;
		C_LENGTH_WIDTH            : integer   := 12;
		C_MST_AWIDTH              : integer   := 32
	);
	port (
		-- Memory controller ports
		MEMIF_FIFO_Hwt2Mem_Data    : in  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_Hwt2Mem_Fill    : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_Hwt2Mem_Empty   : in  std_logic;
		MEMIF_FIFO_Hwt2Mem_RE      : out std_logic;

		MEMIF_FIFO_Mem2Hwt_Data    : out  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_Mem2Hwt_Rem     : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_Mem2Hwt_Full    : in  std_logic;
		MEMIF_FIFO_Mem2Hwt_WE      : out std_logic;

		CTRL_FIFO_Hwt_Data         : in  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		CTRL_FIFO_Hwt_Fill         : in  std_logic_vector(15 downto 0);
		CTRL_FIFO_Hwt_Empty        : in  std_logic;
		CTRL_FIFO_Hwt_RE           : out std_logic;

		MEMIF_FIFO_Mmu_Data        : out std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		MEMIF_FIFO_Mmu_Rem         : in  std_logic_vector(15 downto 0);
		MEMIF_FIFO_Mmu_Full        : in  std_logic;
		MEMIF_FIFO_Mmu_WE          : out std_logic;

		CTRL_FIFO_Mmu_Data         : in  std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
		CTRL_FIFO_Mmu_Fill         : in  std_logic_vector(15 downto 0);
		CTRL_FIFO_Mmu_Empty        : in  std_logic;
		CTRL_FIFO_Mmu_RE           : out std_logic;

		MEMCTRL_Clk   : in std_logic;
		MEMCTRL_Rst   : in std_logic;

		-- Bus protocol ports, do not add to or delete
		Bus2IP_Clk               : in  std_logic;
		Bus2IP_Resetn            : in  std_logic;
		ip2bus_mstrd_req         : out std_logic;
		ip2bus_mstwr_req         : out std_logic;
		ip2bus_mst_addr          : out std_logic_vector(C_MST_AWIDTH-1 downto 0);
		ip2bus_mst_be            : out std_logic_vector((C_MST_NATIVE_DATA_WIDTH/8)-1 downto 0);
		ip2bus_mst_length        : out std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
		ip2bus_mst_type          : out std_logic;
		ip2bus_mst_lock          : out std_logic;
		ip2bus_mst_reset         : out std_logic;
		bus2ip_mst_cmdack        : in  std_logic;
		bus2ip_mst_cmplt         : in  std_logic;
		bus2ip_mst_error         : in  std_logic;
		bus2ip_mst_rearbitrate   : in  std_logic;
		bus2ip_mst_cmd_timeout   : in  std_logic;
		bus2ip_mstrd_d           : in  std_logic_vector(C_MST_NATIVE_DATA_WIDTH-1 downto 0);
		bus2ip_mstrd_rem         : in  std_logic_vector((C_MST_NATIVE_DATA_WIDTH)/8-1 downto 0);
		bus2ip_mstrd_sof_n       : in  std_logic;
		bus2ip_mstrd_eof_n       : in  std_logic;
		bus2ip_mstrd_src_rdy_n   : in  std_logic;
		bus2ip_mstrd_src_dsc_n   : in  std_logic;
		ip2bus_mstrd_dst_rdy_n   : out std_logic;
		ip2bus_mstrd_dst_dsc_n   : out std_logic;
		ip2bus_mstwr_d           : out std_logic_vector(C_MST_NATIVE_DATA_WIDTH-1 downto 0);
		ip2bus_mstwr_rem         : out std_logic_vector((C_MST_NATIVE_DATA_WIDTH)/8-1 downto 0);
		ip2bus_mstwr_src_rdy_n   : out std_logic;
		ip2bus_mstwr_src_dsc_n   : out std_logic;
		ip2bus_mstwr_sof_n       : out std_logic;
		ip2bus_mstwr_eof_n       : out std_logic;
		bus2ip_mstwr_dst_rdy_n   : in  std_logic;
		bus2ip_mstwr_dst_dsc_n   : in  std_logic
	);

	attribute SIGIS : string;

	attribute SIGIS of Bus2IP_Clk         : signal is "Clk";
	attribute SIGIS of MEMCTRL_Clk        : signal is "Clk";
	attribute SIGIS of ip2bus_mst_reset   : signal is "Rst";
	attribute SIGIS of Bus2IP_Resetn      : signal is "Rst";
	attribute SIGIS of MEMCTRL_Rst        : signal is "Rst";

end entity user_logic;


architecture implementation of user_logic is

	constant C_MEMIF_CMD_WIDTH : integer := C_CTRL_FIFO_WIDTH - C_MEMIF_LENGTH_WIDTH;

	type STATE_TYPE is (WAIT_REQUEST,READ_CMD,READ_ADDR,WAIT_FILL,WAIT_REM,
	                    PERF_WRITE_0,PERF_WRITE_1,PERF_WRITE_2,
	                    PERF_READ_0,PERF_READ_1,PERF_READ_2,
	                    WAIT_CMPLT);
	signal state : STATE_TYPE;
	
	signal port_select : std_logic;
	
	signal count : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	
	signal ctrl_fifo_data  : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
	signal ctrl_fifo_empty : std_logic;
	signal ctrl_fifo_re    : std_logic;
	
	signal memif_fifo_in_data  : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal memif_fifo_in_fill  : std_logic_vector(15 downto 0);
	signal memif_fifo_in_empty : std_logic;
	signal memif_fifo_in_re    : std_logic;
	
	signal memif_fifo_out_data : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal memif_fifo_out_rem  : std_logic_vector(15 downto 0);
	signal memif_fifo_out_full : std_logic;
	signal memif_fifo_out_we   : std_logic;

	signal ctrl_cmd         : std_logic_vector(C_MEMIF_CMD_WIDTH - 1 downto 0);
	signal ctrl_length      : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	signal ctrl_addr        : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
	signal ctrl_length_fifo : std_logic_vector(15 downto 0);

	signal axi_read_req   : std_logic;
	signal axi_write_req  : std_logic;
	signal axi_addr       : std_logic_vector(31 downto 0);
	signal axi_length     : std_logic_vector(C_LENGTH_WIDTH - 1 downto 0);
	signal axi_cmdack     : std_logic;
	signal axi_cmplt      : std_logic;

	signal axi_wr_data    : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal axi_wr_sof     : std_logic;
	signal axi_wr_eof     : std_logic;
	signal axi_wr_src_rdy : std_logic;
	signal axi_wr_dst_rdy : std_logic;
	signal axi_wr_dst_dsc : std_logic;

	signal axi_rd_data    : std_logic_vector(C_MEMIF_FIFO_WIDTH - 1 downto 0);
	signal axi_rd_sof     : std_logic;
	signal axi_rd_eof     : std_logic;
	signal axi_rd_src_rdy : std_logic;
	signal axi_rd_src_dsc : std_logic;
	signal axi_rd_dst_rdy : std_logic;

	signal abort : std_logic;

	signal clk          : std_logic;
	signal rst, rst_bus : std_logic;

begin

	clk     <= MEMCTRL_Clk;
	rst     <= MEMCTRL_Rst;
	rst_bus <= not Bus2IP_Resetn;

	-- drive constant bus signals
	ip2bus_mstwr_src_dsc_n <= '1';
	ip2bus_mstrd_dst_dsc_n <= '1';
	ip2bus_mstwr_rem       <= (others => '0');

	ip2bus_mst_be    <= (others => '1');
	ip2bus_mst_type  <= '1'; -- (always burst)
	ip2bus_mst_lock  <= '0';
	ip2bus_mst_reset <= '0';

	-- drive output ports and internal signals
	ip2bus_mstrd_req  <= axi_read_req;
	ip2bus_mstwr_req  <= axi_write_req;
	ip2bus_mst_addr   <= axi_addr;
	ip2bus_mst_length <= axi_length;
	axi_cmdack        <= bus2ip_mst_cmdack;
	axi_cmplt         <= bus2ip_mst_cmplt;

	ip2bus_mstwr_d         <= axi_wr_data;
	ip2bus_mstwr_sof_n     <= not axi_wr_sof;
	ip2bus_mstwr_eof_n     <= not axi_wr_eof;
	ip2bus_mstwr_src_rdy_n <= not axi_wr_src_rdy;
	axi_wr_dst_rdy         <= not bus2ip_mstwr_dst_rdy_n;
	axi_wr_dst_dsc         <= not bus2ip_mstwr_dst_dsc_n;

	axi_rd_data            <= bus2ip_mstrd_d;
	axi_rd_sof             <= not bus2ip_mstrd_sof_n;
	axi_rd_eof             <= not bus2ip_mstrd_eof_n;
	axi_rd_src_rdy         <= not bus2ip_mstrd_src_rdy_n;
	axi_rd_src_dsc         <= not bus2ip_mstrd_src_dsc_n;
	ip2bus_mstrd_dst_rdy_n <= not axi_rd_dst_rdy;


	ctrl_length_fifo <= ctrl_length(17 downto 2) - 1;

	-- driving sof and eof dependent on count
	axi_wr_sof <= '1' when or_reduce(count) = '0' else '0';
	axi_wr_eof <= '1' when count = ctrl_length - 4 else '0';


	-- multiplex port 1 (MMU) and port 2 (HWT)
	port_mux_proc : process(port_select,
	                        CTRL_FIFO_Mmu_Data,CTRL_FIFO_Hwt_Data,
	                        CTRL_FIFO_Mmu_Empty,CTRL_FIFO_Hwt_Empty,
	                        ctrl_fifo_re,memif_fifo_in_re,
	                        memif_fifo_out_data,memif_fifo_out_we,
	                        MEMIF_FIFO_Mmu_Rem,MEMIF_FIFO_Mmu_Full,
	                        MEMIF_FIFO_Hwt2Mem_Data,
	                        MEMIF_FIFO_Hwt2Mem_Fill,MEMIF_FIFO_Hwt2Mem_Empty,
	                        MEMIF_FIFO_Mem2Hwt_Rem,MEMIF_FIFO_Mem2Hwt_Full) is
	begin
		ctrl_fifo_data   <= (others => '0');
		ctrl_fifo_empty  <= '1';
		CTRL_FIFO_Mmu_RE <= '0';
		CTRL_FIFO_Hwt_RE <= '0';

		memif_fifo_in_data    <= (others => '0');
		memif_fifo_in_fill    <= (others => '0');
		memif_fifo_in_empty   <= '0';
		MEMIF_FIFO_Hwt2Mem_RE <= '0';

		memif_fifo_out_rem      <= (others => '0');
		memif_fifo_out_full     <= '0';
		MEMIF_FIFO_Mem2Hwt_Data <= (others => '0');
		MEMIF_FIFO_Mem2Hwt_WE   <= '0';
		MEMIF_FIFO_Mmu_Data     <= (others => '0');
		MEMIF_FIFO_Mmu_WE       <= '0';

		if port_select = '0' then
			ctrl_fifo_data   <= CTRL_FIFO_Mmu_Data;
			ctrl_fifo_empty  <= CTRL_FIFO_Mmu_Empty;
			CTRL_FIFO_Mmu_RE <= ctrl_fifo_re;

			memif_fifo_out_rem  <= MEMIF_FIFO_Mmu_Rem;
			memif_fifo_out_full <= MEMIF_FIFO_Mmu_Full;
			MEMIF_FIFO_Mmu_Data <= memif_fifo_out_data;
			MEMIF_FIFO_Mmu_WE   <= memif_fifo_out_we;
		else
			ctrl_fifo_data   <= CTRL_FIFO_Hwt_Data;
			ctrl_fifo_empty  <= CTRL_FIFO_Hwt_Empty;
			CTRL_FIFO_Hwt_RE <= ctrl_fifo_re;

			memif_fifo_out_rem      <= MEMIF_FIFO_Mem2Hwt_Rem;
			memif_fifo_out_full     <= MEMIF_FIFO_Mem2Hwt_Full;
			MEMIF_FIFO_Mem2Hwt_Data <= memif_fifo_out_data;
			MEMIF_FIFO_Mem2Hwt_WE   <= memif_fifo_out_we;

			memif_fifo_in_data    <= MEMIF_FIFO_Hwt2Mem_Data;
			memif_fifo_in_fill    <= MEMIF_FIFO_Hwt2Mem_Fill;
			memif_fifo_in_empty   <= MEMIF_FIFO_Hwt2Mem_Empty;
			MEMIF_FIFO_Hwt2Mem_RE <= memif_fifo_in_re;
		end if;	
	end process port_mux_proc;


	-- drive in/out FIFO RE/WE signals
	fifo_rd_proc : process(state,
	                       axi_wr_dst_rdy,memif_fifo_in_data,
	                       axi_rd_src_rdy,axi_rd_data) is
	begin
		memif_fifo_in_re <= '0';
		axi_wr_data      <= (others => '0');

		memif_fifo_out_we   <= '0';
		memif_fifo_out_data <= (others => '0');

		if state = PERF_WRITE_2 and abort = '0' then
			memif_fifo_in_re <= axi_wr_dst_rdy;
			axi_wr_data <= memif_fifo_in_data;
		end if;

		if state = PERF_READ_2 and abort = '0' then
			memif_fifo_out_we <= axi_rd_src_rdy;
			memif_fifo_out_data <= axi_rd_data;
		end if;
	end process fifo_rd_proc;


	mem_proc : process(clk,rst_bus) is
	begin
		if rst_bus = '1' then
			state <= WAIT_REQUEST;

			axi_read_req  <= '0';
			axi_write_req <= '0';
			axi_addr      <= (others => '0');
			axi_length    <= (others => '0');

			axi_wr_src_rdy <= '0';
			axi_rd_dst_rdy <= '0';

			ctrl_fifo_re <= '0';

			port_select <= '1';

			count <= (others => '0');
		elsif rising_edge(clk) then
			if rst = '1' then
				abort <= '1';
			end if;
		
			case state is
				when WAIT_REQUEST =>				
					if CTRL_FIFO_Mmu_Empty = '0' AND C_USE_MMU_PORT then
						port_select <= '0';

						ctrl_fifo_re <= '1';

						state <= READ_CMD;
					elsif CTRL_FIFO_Hwt_Empty = '0' then
						port_select <= '1';

						ctrl_fifo_re <= '1';

						state <= READ_CMD;
					end if;

					if abort = '1' or rst = '1' then
						ctrl_fifo_re <= '0';
						state <= WAIT_REQUEST;
					end if;
					abort <= '0';

				when READ_CMD =>
					ctrl_cmd <= ctrl_fifo_data(31 downto C_MEMIF_LENGTH_WIDTH);
					ctrl_length <= ctrl_fifo_data(C_MEMIF_LENGTH_WIDTH - 1 downto 0);

					state <= READ_ADDR;

					if abort = '1' or rst = '1' then
						ctrl_fifo_re <= '0';
						state <= WAIT_REQUEST;
					end if;

				when READ_ADDR =>
					if ctrl_fifo_empty = '0' then
						ctrl_addr <= ctrl_fifo_data;

						ctrl_fifo_re <= '0';
					
						if ctrl_cmd(C_MEMIF_CMD_WIDTH - 1) = '1' then
							state <= WAIT_FILL;
						else
							state <= WAIT_REM;
						end if;
					end if;

					if abort = '1' or rst = '1' then
						ctrl_fifo_re <= '0';
						state <= WAIT_REQUEST;
					end if;

				when WAIT_FILL =>
					if memif_fifo_in_empty = '0' and memif_fifo_in_fill >= ctrl_length_fifo then
						state <= PERF_WRITE_0;
					end if;

					if abort = '1' or rst = '1' then
						state <= WAIT_REQUEST;
					end if;

				when WAIT_REM =>
					if memif_fifo_out_full = '0' and memif_fifo_out_rem >= ctrl_length_fifo then
						state <= PERF_READ_0;
					end if;

					if abort = '1' or rst = '1' then
						ctrl_fifo_re <= '0';
						state <= WAIT_REQUEST;
					end if;

				-- preparing for transfer
				when PERF_WRITE_0 =>
					axi_addr <= ctrl_addr;
					axi_length <= ctrl_length(C_LENGTH_WIDTH - 1 downto 2) & "00";

					axi_write_req <= '1';

					count <= (others => '0');

					state <= PERF_WRITE_1;

				-- waiting for cmdack
				when PERF_WRITE_1 =>
					if axi_cmdack = '1' then
						axi_write_req <= '0';
						axi_wr_src_rdy <= '1';

						state <= PERF_WRITE_2;
					end if;

				-- performing transfer
				when PERF_WRITE_2 =>
					if axi_wr_dst_rdy = '1' then
						count <= count + 4;

						if count = ctrl_length - 4 then
							axi_wr_src_rdy <= '0';
							
							state <= WAIT_CMPLT;
						end if;
					end if;

				-- preparing for transfer
				when PERF_READ_0 =>
					axi_addr <= ctrl_addr;
					axi_length <= ctrl_length(C_LENGTH_WIDTH - 1 downto 2) & "00";

					axi_read_req <= '1';

					count <= (others => '0');

					state <= PERF_READ_1;

				-- waiting for cmdack
				when PERF_READ_1 =>
					if axi_cmdack = '1' then
						axi_read_req <= '0';
						axi_rd_dst_rdy <= '1';

						state <= PERF_READ_2;
					end if;

				when PERF_READ_2 =>
					if axi_rd_src_rdy = '1' then
						count <= count + 4;

						if count = ctrl_length - 4 then
							axi_rd_dst_rdy <= '0';

							state <= WAIT_CMPLT;
						end if;
					end if;

				-- waiting for completion
				when WAIT_CMPLT =>
					if axi_cmplt = '1' then
						state <= WAIT_REQUEST;
					end if;

			end case;
		end if;
	end process mem_proc;

end implementation;
