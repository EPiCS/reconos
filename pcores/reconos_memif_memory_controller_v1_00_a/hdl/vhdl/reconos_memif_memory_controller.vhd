--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - MEMIF Memory controller - Top level entity
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  The memory controller connectr the memory subsystem of
--                 ReconOS to the memory bus of the system as an AXI
--                 master.
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library axi_master_burst_v1_00_a;
use axi_master_burst_v1_00_a.axi_master_burst;

library reconos_memif_memory_controller_v1_00_a;
use reconos_memif_memory_controller_v1_00_a.user_logic;


entity reconos_memif_memory_controller is
	generic (
		-- Memory controller parameters
		C_MEMIF_FIFO_WIDTH      : integer   := 32;
		C_CTRL_FIFO_WIDTH       : integer   := 32;
		C_MEMIF_LENGTH_WIDTH    : integer   := 24;
		C_USE_MMU_PORT          : boolean   := true;

		-- Bus protocol parameters, do not add to or delete
		C_FAMILY                : string    := "virtex6";
		C_M_AXI_ADDR_WIDTH      : integer   := 32;
		C_M_AXI_DATA_WIDTH      : integer   := 32;
		C_MAX_BURST_LEN         : integer   := 256;
		C_ADDR_PIPE_DEPTH       : integer   := 1;
		C_NATIVE_DATA_WIDTH     : integer   := 32;
		C_LENGTH_WIDTH          : integer   := 12
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
		MEMCTRL_Rst   : in  std_logic;

		-- Bus protocol ports, do not add to or delete
		M_AXI_ACLK      : in  std_logic;
		M_AXI_ARESETN   : in  std_logic;
		MD_ERROR        : out std_logic;
		M_AXI_ARREADY   : in  std_logic;
		M_AXI_ARVALID   : out std_logic;
		M_AXI_ARADDR    : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_ARLEN     : out std_logic_vector(7 downto 0);
		M_AXI_ARSIZE    : out std_logic_vector(2 downto 0);
		M_AXI_ARBURST   : out std_logic_vector(1 downto 0);
		M_AXI_ARPROT    : out std_logic_vector(2 downto 0);
		M_AXI_RREADY    : out std_logic;
		M_AXI_RVALID    : in  std_logic;
		M_AXI_RDATA     : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_RRESP     : in  std_logic_vector(1 downto 0);
		M_AXI_RLAST     : in  std_logic;
		M_AXI_AWREADY   : in  std_logic;
		M_AXI_AWVALID   : out std_logic;
		M_AXI_AWADDR    : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		M_AXI_AWLEN     : out std_logic_vector(7 downto 0);
		M_AXI_AWSIZE    : out std_logic_vector(2 downto 0);
		M_AXI_AWBURST   : out std_logic_vector(1 downto 0);
		M_AXI_AWPROT    : out std_logic_vector(2 downto 0);
		M_AXI_WREADY    : in  std_logic;
		M_AXI_WVALID    : out std_logic;
		M_AXI_WDATA     : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		M_AXI_WSTRB     : out std_logic_vector((C_M_AXI_DATA_WIDTH)/8 - 1 downto 0);
		M_AXI_WLAST     : out std_logic;
		M_AXI_BREADY    : out std_logic;
		M_AXI_BVALID    : in  std_logic;
		M_AXI_BRESP     : in  std_logic_vector(1 downto 0);

		M_AXI_AWCACHE   : out std_logic_vector(3 downto 0);
		M_AXI_ARCACHE   : out std_logic_vector(3 downto 0);
		M_AXI_AWUSER    : out std_logic_vector(4 downto 0);                             
		M_AXI_ARUSER    : out std_logic_vector(4 downto 0)
	);

	attribute MAX_FANOUT   : string;
	attribute SIGIS        : string;

	attribute MAX_FANOUT of M_AXI_ACLK      : signal is "10000";
	attribute MAX_FANOUT of M_AXI_ARESETN   : signal is "10000";

	attribute SIGIS of M_AXI_ACLK      : signal is "Clk";
	attribute SIGIS of MEMCTRL_Clk     : signal is "Clk";
	attribute SIGIS of M_AXI_ARESETN   : signal is "Rst";
	attribute SIGIS of MEMCTRL_Rst     : signal is "Rst";
end entity reconos_memif_memory_controller;


architecture implementation of reconos_memif_memory_controller is

	constant USER_MST_AWIDTH                : integer              := C_M_AXI_ADDR_WIDTH;
	constant USER_MST_DWIDTH                : integer              := C_M_AXI_DATA_WIDTH;
	constant USER_MST_NATIVE_DATA_WIDTH     : integer              := C_NATIVE_DATA_WIDTH;
	constant USER_LENGTH_WIDTH              : integer              := C_LENGTH_WIDTH;

	-- IP Interconnect (IPIC) signal declarations
	signal ipif_Bus2IP_Clk                : std_logic;
	signal ipif_Bus2IP_Resetn             : std_logic;
	signal ipif_ip2bus_mstrd_req          : std_logic;
	signal ipif_ip2bus_mstwr_req          : std_logic;
	signal ipif_ip2bus_mst_addr           : std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	signal ipif_ip2bus_mst_be             : std_logic_vector((C_NATIVE_DATA_WIDTH)/8-1 downto 0);
	signal ipif_ip2bus_mst_length         : std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
	signal ipif_ip2bus_mst_type           : std_logic;
	signal ipif_ip2bus_mst_lock           : std_logic;
	signal ipif_ip2bus_mst_reset          : std_logic;
	signal ipif_bus2ip_mst_cmdack         : std_logic;
	signal ipif_bus2ip_mst_cmplt          : std_logic;
	signal ipif_bus2ip_mst_error          : std_logic;
	signal ipif_bus2ip_mst_rearbitrate    : std_logic;
	signal ipif_bus2ip_mst_cmd_timeout    : std_logic;
	signal ipif_bus2ip_mstrd_d            : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
	signal ipif_bus2ip_mstrd_rem          : std_logic_vector((C_NATIVE_DATA_WIDTH)/8-1 downto 0);
	signal ipif_bus2ip_mstrd_sof_n        : std_logic;
	signal ipif_bus2ip_mstrd_eof_n        : std_logic;
	signal ipif_bus2ip_mstrd_src_rdy_n    : std_logic;
	signal ipif_bus2ip_mstrd_src_dsc_n    : std_logic;
	signal ipif_ip2bus_mstrd_dst_rdy_n    : std_logic;
	signal ipif_ip2bus_mstrd_dst_dsc_n    : std_logic;
	signal ipif_ip2bus_mstwr_d            : std_logic_vector(C_NATIVE_DATA_WIDTH-1 downto 0);
	signal ipif_ip2bus_mstwr_rem          : std_logic_vector((C_NATIVE_DATA_WIDTH)/8-1 downto 0);
	signal ipif_ip2bus_mstwr_src_rdy_n    : std_logic;
	signal ipif_ip2bus_mstwr_src_dsc_n    : std_logic;
	signal ipif_ip2bus_mstwr_sof_n        : std_logic;
	signal ipif_ip2bus_mstwr_eof_n        : std_logic;
	signal ipif_bus2ip_mstwr_dst_rdy_n    : std_logic;
	signal ipif_bus2ip_mstwr_dst_dsc_n    : std_logic;

	signal ignore : std_logic_vector(3 downto 0);

begin

	-- instantiate axi_master_burst
	AXI_MASTER_BURST_I : entity axi_master_burst_v1_00_a.axi_master_burst
		generic map (
			C_M_AXI_ADDR_WIDTH    => C_M_AXI_ADDR_WIDTH,
			C_M_AXI_DATA_WIDTH    => C_M_AXI_DATA_WIDTH,
			C_MAX_BURST_LEN       => C_MAX_BURST_LEN,
			C_NATIVE_DATA_WIDTH   => C_NATIVE_DATA_WIDTH,
			C_LENGTH_WIDTH        => C_LENGTH_WIDTH,
			C_ADDR_PIPE_DEPTH     => C_ADDR_PIPE_DEPTH,
			C_FAMILY              => C_FAMILY
		)
		port map
		(
			m_axi_aclk               => M_AXI_ACLK,
			m_axi_aresetn            => M_AXI_ARESETN,
			md_error                 => MD_ERROR,
			m_axi_arready            => M_AXI_ARREADY,
			m_axi_arvalid            => M_AXI_ARVALID,
			m_axi_araddr             => M_AXI_ARADDR,
			m_axi_arlen              => M_AXI_ARLEN,
			m_axi_arsize             => M_AXI_ARSIZE,
			m_axi_arburst            => M_AXI_ARBURST,
			m_axi_arprot             => M_AXI_ARPROT,
			m_axi_arcache            => ignore,
			m_axi_rready             => M_AXI_RREADY,
			m_axi_rvalid             => M_AXI_RVALID,
			m_axi_rdata              => M_AXI_RDATA,
			m_axi_rresp              => M_AXI_RRESP,
			m_axi_rlast              => M_AXI_RLAST,
			m_axi_awready            => M_AXI_AWREADY,
			m_axi_awvalid            => M_AXI_AWVALID,
			m_axi_awaddr             => M_AXI_AWADDR,
			m_axi_awlen              => M_AXI_AWLEN,
			m_axi_awsize             => M_AXI_AWSIZE,
			m_axi_awburst            => M_AXI_AWBURST,
			m_axi_awprot             => M_AXI_AWPROT,
			m_axi_awcache            => ignore,
			m_axi_wready             => M_AXI_WREADY,
			m_axi_wvalid             => M_AXI_WVALID,
			m_axi_wdata              => M_AXI_WDATA,
			m_axi_wstrb              => M_AXI_WSTRB,
			m_axi_wlast              => M_AXI_WLAST,
			m_axi_bready             => M_AXI_BREADY,
			m_axi_bvalid             => M_AXI_BVALID,
			m_axi_bresp              => M_AXI_BRESP,
			ip2bus_mstrd_req         => ipif_ip2bus_mstrd_req,
			ip2bus_mstwr_req         => ipif_ip2bus_mstwr_req,
			ip2bus_mst_addr          => ipif_ip2bus_mst_addr,
			ip2bus_mst_be            => ipif_ip2bus_mst_be,
			ip2bus_mst_length        => ipif_ip2bus_mst_length,
			ip2bus_mst_type          => ipif_ip2bus_mst_type,
			ip2bus_mst_lock          => ipif_ip2bus_mst_lock,
			ip2bus_mst_reset         => ipif_ip2bus_mst_reset,
			bus2ip_mst_cmdack        => ipif_bus2ip_mst_cmdack,
			bus2ip_mst_cmplt         => ipif_bus2ip_mst_cmplt,
			bus2ip_mst_error         => ipif_bus2ip_mst_error,
			bus2ip_mst_rearbitrate   => ipif_bus2ip_mst_rearbitrate,
			bus2ip_mst_cmd_timeout   => ipif_bus2ip_mst_cmd_timeout,
			bus2ip_mstrd_d           => ipif_bus2ip_mstrd_d,
			bus2ip_mstrd_rem         => ipif_bus2ip_mstrd_rem,
			bus2ip_mstrd_sof_n       => ipif_bus2ip_mstrd_sof_n,
			bus2ip_mstrd_eof_n       => ipif_bus2ip_mstrd_eof_n,
			bus2ip_mstrd_src_rdy_n   => ipif_bus2ip_mstrd_src_rdy_n,
			bus2ip_mstrd_src_dsc_n   => ipif_bus2ip_mstrd_src_dsc_n,
			ip2bus_mstrd_dst_rdy_n   => ipif_ip2bus_mstrd_dst_rdy_n,
			ip2bus_mstrd_dst_dsc_n   => ipif_ip2bus_mstrd_dst_dsc_n,
			ip2bus_mstwr_d           => ipif_ip2bus_mstwr_d,
			ip2bus_mstwr_rem         => ipif_ip2bus_mstwr_rem,
			ip2bus_mstwr_src_rdy_n   => ipif_ip2bus_mstwr_src_rdy_n,
			ip2bus_mstwr_src_dsc_n   => ipif_ip2bus_mstwr_src_dsc_n,
			ip2bus_mstwr_sof_n       => ipif_ip2bus_mstwr_sof_n,
			ip2bus_mstwr_eof_n       => ipif_ip2bus_mstwr_eof_n,
			bus2ip_mstwr_dst_rdy_n   => ipif_bus2ip_mstwr_dst_rdy_n,
			bus2ip_mstwr_dst_dsc_n   => ipif_bus2ip_mstwr_dst_dsc_n
		);

	-- instantiate User Logic
	USER_LOGIC_I : entity reconos_memif_memory_controller_v1_00_a.user_logic
		generic map (
			-- Memory controller parameters
			C_MEMIF_FIFO_WIDTH      => C_MEMIF_FIFO_WIDTH,
			C_CTRL_FIFO_WIDTH       => C_CTRL_FIFO_WIDTH,
			C_MEMIF_LENGTH_WIDTH    => C_MEMIF_LENGTH_WIDTH,
			C_USE_MMU_PORT          => C_USE_MMU_PORT,

			-- Bus protocol parameters
			C_MST_NATIVE_DATA_WIDTH        => USER_MST_NATIVE_DATA_WIDTH,
			C_LENGTH_WIDTH                 => USER_LENGTH_WIDTH,
			C_MST_AWIDTH                   => USER_MST_AWIDTH
		)
		port map (
			-- Memory controller ports
			MEMIF_FIFO_Hwt2Mem_Data    => MEMIF_FIFO_Hwt2Mem_Data,
			MEMIF_FIFO_Hwt2Mem_Fill    => MEMIF_FIFO_Hwt2Mem_Fill,
			MEMIF_FIFO_Hwt2Mem_Empty   => MEMIF_FIFO_Hwt2Mem_Empty,
			MEMIF_FIFO_Hwt2Mem_RE      => MEMIF_FIFO_Hwt2Mem_RE,

			MEMIF_FIFO_Mem2Hwt_Data    => MEMIF_FIFO_Mem2Hwt_Data,
			MEMIF_FIFO_Mem2Hwt_Rem     => MEMIF_FIFO_Mem2Hwt_Rem,
			MEMIF_FIFO_Mem2Hwt_Full    => MEMIF_FIFO_Mem2Hwt_Full,
			MEMIF_FIFO_Mem2Hwt_WE      => MEMIF_FIFO_Mem2Hwt_WE,

			CTRL_FIFO_Hwt_Data         => CTRL_FIFO_Hwt_Data,
			CTRL_FIFO_Hwt_Fill         => CTRL_FIFO_Hwt_Fill,
			CTRL_FIFO_Hwt_Empty        => CTRL_FIFO_Hwt_Empty,
			CTRL_FIFO_Hwt_RE           => CTRL_FIFO_Hwt_RE,

			MEMIF_FIFO_Mmu_Data        => MEMIF_FIFO_Mmu_Data,
			MEMIF_FIFO_Mmu_Rem         => MEMIF_FIFO_Mmu_Rem,
			MEMIF_FIFO_Mmu_Full        => MEMIF_FIFO_Mmu_Full,
			MEMIF_FIFO_Mmu_WE          => MEMIF_FIFO_Mmu_WE,

			CTRL_FIFO_Mmu_Data         => CTRL_FIFO_Mmu_Data,
			CTRL_FIFO_Mmu_Fill         => CTRL_FIFO_Mmu_Fill,
			CTRL_FIFO_Mmu_Empty        => CTRL_FIFO_Mmu_Empty,
			CTRL_FIFO_Mmu_RE           => CTRL_FIFO_Mmu_RE,

			MEMCTRL_Clk   => MEMCTRL_Clk,
			MEMCTRL_Rst   => MEMCTRL_Rst,

			-- Bus protocol ports
			Bus2IP_Clk               => ipif_Bus2IP_Clk,
			Bus2IP_Resetn            => ipif_Bus2IP_Resetn,
			ip2bus_mstrd_req         => ipif_ip2bus_mstrd_req,
			ip2bus_mstwr_req         => ipif_ip2bus_mstwr_req,
			ip2bus_mst_addr          => ipif_ip2bus_mst_addr,
			ip2bus_mst_be            => ipif_ip2bus_mst_be,
			ip2bus_mst_length        => ipif_ip2bus_mst_length,
			ip2bus_mst_type          => ipif_ip2bus_mst_type,
			ip2bus_mst_lock          => ipif_ip2bus_mst_lock,
			ip2bus_mst_reset         => ipif_ip2bus_mst_reset,
			bus2ip_mst_cmdack        => ipif_bus2ip_mst_cmdack,
			bus2ip_mst_cmplt         => ipif_bus2ip_mst_cmplt,
			bus2ip_mst_error         => ipif_bus2ip_mst_error,
			bus2ip_mst_rearbitrate   => ipif_bus2ip_mst_rearbitrate,
			bus2ip_mst_cmd_timeout   => ipif_bus2ip_mst_cmd_timeout,
			bus2ip_mstrd_d           => ipif_bus2ip_mstrd_d,
			bus2ip_mstrd_rem         => ipif_bus2ip_mstrd_rem,
			bus2ip_mstrd_sof_n       => ipif_bus2ip_mstrd_sof_n,
			bus2ip_mstrd_eof_n       => ipif_bus2ip_mstrd_eof_n,
			bus2ip_mstrd_src_rdy_n   => ipif_bus2ip_mstrd_src_rdy_n,
			bus2ip_mstrd_src_dsc_n   => ipif_bus2ip_mstrd_src_dsc_n,
			ip2bus_mstrd_dst_rdy_n   => ipif_ip2bus_mstrd_dst_rdy_n,
			ip2bus_mstrd_dst_dsc_n   => ipif_ip2bus_mstrd_dst_dsc_n,
			ip2bus_mstwr_d           => ipif_ip2bus_mstwr_d,
			ip2bus_mstwr_rem         => ipif_ip2bus_mstwr_rem,
			ip2bus_mstwr_src_rdy_n   => ipif_ip2bus_mstwr_src_rdy_n,
			ip2bus_mstwr_src_dsc_n   => ipif_ip2bus_mstwr_src_dsc_n,
			ip2bus_mstwr_sof_n       => ipif_ip2bus_mstwr_sof_n,
			ip2bus_mstwr_eof_n       => ipif_ip2bus_mstwr_eof_n,
			bus2ip_mstwr_dst_rdy_n   => ipif_bus2ip_mstwr_dst_rdy_n,
			bus2ip_mstwr_dst_dsc_n   => ipif_bus2ip_mstwr_dst_dsc_n
		);
		
		ipif_Bus2IP_Clk      <= M_AXI_ACLK;
		ipif_Bus2IP_Resetn   <= M_AXI_ARESETN;

		M_AXI_AWCACHE <= (others => '1');                                               
		M_AXI_ARCACHE <= (others => '1');                                               
		M_AXI_AWUSER  <= (others => '1');                                                
		M_AXI_ARUSER  <= (others => '1');  

end implementation;
