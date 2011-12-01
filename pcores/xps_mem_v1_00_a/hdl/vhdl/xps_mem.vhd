------------------------------------------------------------------------------
-- xps_mem.vhd - entity/architecture pair
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library plbv46_master_burst_v1_01_a;
use plbv46_master_burst_v1_01_a.plbv46_master_burst;

library xps_mem_v1_00_a;
use xps_mem_v1_00_a.user_logic;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_INCLUDE_DPHASE_TIMER       -- PLBv46 slave: Data Phase Timer configuration; 0 = exclude timer, 1 = include timer
--   C_FAMILY                     -- Xilinx FPGA family
--   C_MPLB_AWIDTH                -- PLBv46 master: address bus width
--   C_MPLB_DWIDTH                -- PLBv46 master: data bus width
--   C_MPLB_NATIVE_DWIDTH         -- PLBv46 master: internal native data width
--   C_MPLB_P2P                   -- PLBv46 master: point to point interconnect scheme
--   C_MPLB_SMALLEST_SLAVE        -- PLBv46 master: width of the smallest slave
--   C_MPLB_CLK_PERIOD_PS         -- PLBv46 master: bus clock in picoseconds
--
-- Definition of Ports:
--   SPLB_Clk                     -- PLB main bus clock
--   SPLB_Rst                     -- PLB main bus reset
--   PLB_ABus                     -- PLB address bus
--   PLB_UABus                    -- PLB upper address bus
--   PLB_PAValid                  -- PLB primary address valid indicator
--   PLB_SAValid                  -- PLB secondary address valid indicator
--   PLB_rdPrim                   -- PLB secondary to primary read request indicator
--   PLB_wrPrim                   -- PLB secondary to primary write request indicator
--   PLB_masterID                 -- PLB current master identifier
--   PLB_abort                    -- PLB abort request indicator
--   PLB_busLock                  -- PLB bus lock
--   PLB_RNW                      -- PLB read/not write
--   PLB_BE                       -- PLB byte enables
--   PLB_MSize                    -- PLB master data bus size
--   PLB_size                     -- PLB transfer size
--   PLB_type                     -- PLB transfer type
--   PLB_lockErr                  -- PLB lock error indicator
--   PLB_wrDBus                   -- PLB write data bus
--   PLB_wrBurst                  -- PLB burst write transfer indicator
--   PLB_rdBurst                  -- PLB burst read transfer indicator
--   PLB_wrPendReq                -- PLB write pending bus request indicator
--   PLB_rdPendReq                -- PLB read pending bus request indicator
--   PLB_wrPendPri                -- PLB write pending request priority
--   PLB_rdPendPri                -- PLB read pending request priority
--   PLB_reqPri                   -- PLB current request priority
--   PLB_TAttribute               -- PLB transfer attribute
--   MPLB_Clk                     -- PLB main bus Clock
--   MPLB_Rst                     -- PLB main bus Reset
--   MD_error                     -- Master detected error status output
--   M_request                    -- Master request
--   M_priority                   -- Master request priority
--   M_busLock                    -- Master buslock
--   M_RNW                        -- Master read/nor write
--   M_BE                         -- Master byte enables
--   M_MSize                      -- Master data bus size
--   M_size                       -- Master transfer size
--   M_type                       -- Master transfer type
--   M_TAttribute                 -- Master transfer attribute
--   M_lockErr                    -- Master lock error indicator
--   M_abort                      -- Master abort bus request indicator
--   M_UABus                      -- Master upper address bus
--   M_ABus                       -- Master address bus
--   M_wrDBus                     -- Master write data bus
--   M_wrBurst                    -- Master burst write transfer indicator
--   M_rdBurst                    -- Master burst read transfer indicator
--   PLB_MAddrAck                 -- PLB reply to master for address acknowledge
--   PLB_MSSize                   -- PLB reply to master for slave data bus size
--   PLB_MRearbitrate             -- PLB reply to master for bus re-arbitrate indicator
--   PLB_MTimeout                 -- PLB reply to master for bus time out indicator
--   PLB_MBusy                    -- PLB reply to master for slave busy indicator
--   PLB_MRdErr                   -- PLB reply to master for slave read error indicator
--   PLB_MWrErr                   -- PLB reply to master for slave write error indicator
--   PLB_MIRQ                     -- PLB reply to master for slave interrupt indicator
--   PLB_MRdDBus                  -- PLB reply to master for read data bus
--   PLB_MRdWdAddr                -- PLB reply to master for read word address
--   PLB_MRdDAck                  -- PLB reply to master for read data acknowledge
--   PLB_MRdBTerm                 -- PLB reply to master for terminate read burst indicator
--   PLB_MWrDAck                  -- PLB reply to master for write data acknowledge
--   PLB_MWrBTerm                 -- PLB reply to master for terminate write burst indicator
------------------------------------------------------------------------------

entity xps_mem is
	generic
	(
		C_INCLUDE_DPHASE_TIMER         : integer              := 0;
		C_FAMILY                       : string               := "virtex6";
		C_MPLB_AWIDTH                  : integer              := 32;
		C_MPLB_DWIDTH                  : integer              := 128;
		C_MPLB_NATIVE_DWIDTH           : integer              := 32;
		C_MPLB_P2P                     : integer              := 0;
		C_MPLB_SMALLEST_SLAVE          : integer              := 32;
		C_MPLB_CLK_PERIOD_PS           : integer              := 10000
	);
	port
	(
		--    SPLB_Clk                       : in  std_logic;
		--    SPLB_Rst                       : in  std_logic;
		--    PLB_ABus                       : in  std_logic_vector(0 to 31);
		--    PLB_UABus                      : in  std_logic_vector(0 to 31);
		--    PLB_PAValid                    : in  std_logic;
		--    PLB_SAValid                    : in  std_logic;
		--    PLB_rdPrim                     : in  std_logic;
		--    PLB_wrPrim                     : in  std_logic;
		--    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
		--    PLB_abort                      : in  std_logic;
		--    PLB_busLock                    : in  std_logic;
		--    PLB_RNW                        : in  std_logic;
		--    PLB_BE                         : in  std_logic_vector(0 to C_MPLB_DWIDTH/8-1);
		--    PLB_MSize                      : in  std_logic_vector(0 to 1);
		--    PLB_size                       : in  std_logic_vector(0 to 3);
		--    PLB_type                       : in  std_logic_vector(0 to 2);
		--    PLB_lockErr                    : in  std_logic;
		--    PLB_wrDBus                     : in  std_logic_vector(0 to C_MPLB_DWIDTH-1);
		--    PLB_wrBurst                    : in  std_logic;
		--    PLB_rdBurst                    : in  std_logic;
		--    PLB_wrPendReq                  : in  std_logic;
		--    PLB_rdPendReq                  : in  std_logic;
		--    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
		--    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
		--    PLB_reqPri                     : in  std_logic_vector(0 to 1);
		--    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
		MPLB_Clk                       : in  std_logic;
		MPLB_Rst                       : in  std_logic;
		MD_error                       : out std_logic;
		M_request                      : out std_logic;
		M_priority                     : out std_logic_vector(0 to 1);
		M_busLock                      : out std_logic;
		M_RNW                          : out std_logic;
		M_BE                           : out std_logic_vector(0 to C_MPLB_DWIDTH/8-1);
		M_MSize                        : out std_logic_vector(0 to 1);
		M_size                         : out std_logic_vector(0 to 3);
		M_type                         : out std_logic_vector(0 to 2);
		M_TAttribute                   : out std_logic_vector(0 to 15);
		M_lockErr                      : out std_logic;
		M_abort                        : out std_logic;
		M_UABus                        : out std_logic_vector(0 to 31);
		M_ABus                         : out std_logic_vector(0 to 31);
		M_wrDBus                       : out std_logic_vector(0 to C_MPLB_DWIDTH-1);
		M_wrBurst                      : out std_logic;
		M_rdBurst                      : out std_logic;
		PLB_MAddrAck                   : in  std_logic;
		PLB_MSSize                     : in  std_logic_vector(0 to 1);
		PLB_MRearbitrate               : in  std_logic;
		PLB_MTimeout                   : in  std_logic;
		PLB_MBusy                      : in  std_logic;
		PLB_MRdErr                     : in  std_logic;
		PLB_MWrErr                     : in  std_logic;
		PLB_MIRQ                       : in  std_logic;
		PLB_MRdDBus                    : in  std_logic_vector(0 to (C_MPLB_DWIDTH-1));
		PLB_MRdWdAddr                  : in  std_logic_vector(0 to 3);
		PLB_MRdDAck                    : in  std_logic;
		PLB_MRdBTerm                   : in  std_logic;
		PLB_MWrDAck                    : in  std_logic;
		PLB_MWrBTerm                   : in  std_logic;
		
		-- FIFO Interface
		FIFO32_S_Clk : out std_logic;
		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic
	);
	
	attribute SIGIS : string;
	--  attribute SIGIS of SPLB_Clk      : signal is "CLK";
	attribute SIGIS of MPLB_Clk      : signal is "CLK";
	--  attribute SIGIS of SPLB_Rst      : signal is "RST";
	attribute SIGIS of MPLB_Rst      : signal is "RST";

end entity xps_mem;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of xps_mem is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
--  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
--  constant USER_MST_BASEADDR              : std_logic_vector     := C_BASEADDR or X"00000000";
--  constant USER_MST_HIGHADDR              : std_logic_vector     := C_BASEADDR or X"000000FF";

--  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
--    (
--      ZERO_ADDR_PAD & USER_MST_BASEADDR,  -- user logic master space base address
--      ZERO_ADDR_PAD & USER_MST_HIGHADDR   -- user logic master space high address
--    );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_MST_NUM_REG               : integer              := 4;
  constant USER_NUM_REG                   : integer              := USER_MST_NUM_REG;

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
    (
      0  => pad_power2(USER_MST_NUM_REG)  -- number of ce for user logic master space
    );

  ------------------------------------------
  -- Ratio of bus clock to core clock (for use in dual clock systems)
  -- 1 = ratio is 1:1
  -- 2 = ratio is 2:1
  ------------------------------------------
  constant IPIF_BUS2CORE_CLK_RATIO        : integer              := 1;

  ------------------------------------------
  -- Width of the slave data bus (32 only)
  ------------------------------------------
--  constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

--  constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the master data bus (32, 64, or 128)
  ------------------------------------------
  constant USER_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  constant IPIF_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Inhibit the automatic inculsion of the Conversion Cycle and Burst Length Expansion logic
  -- 0 = allow automatic inclusion of the CC and BLE logic
  -- 1 = inhibit automatic inclusion of the CC and BLE logic
  ------------------------------------------
  constant IPIF_INHIBIT_CC_BLE_INCLUSION  : integer              := 0;

  ------------------------------------------
  -- Width of the master address bus (32 only)
  ------------------------------------------
  constant USER_MST_AWIDTH                : integer              := C_MPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant USER_MST_CS_INDEX              : integer              := 0;
--  constant USER_MST_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_MST_CS_INDEX);

--  constant USER_CE_INDEX                  : integer              := USER_MST_CE_INDEX;

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Reset              : std_logic;
--  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
--  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
--  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_Bus2IP_RNW                : std_logic;
--  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
--  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
--  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
--  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_IP2Bus_MstRd_Req          : std_logic;
  signal ipif_IP2Bus_MstWr_Req          : std_logic;
  signal ipif_IP2Bus_Mst_Addr           : std_logic_vector(0 to C_MPLB_AWIDTH-1);
  signal ipif_IP2Bus_Mst_Length         : std_logic_vector(0 to 11);
  signal ipif_IP2Bus_Mst_BE             : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_Mst_Type           : std_logic;
  signal ipif_IP2Bus_Mst_Lock           : std_logic;
  signal ipif_IP2Bus_Mst_Reset          : std_logic;
  signal ipif_Bus2IP_Mst_CmdAck         : std_logic;
  signal ipif_Bus2IP_Mst_Cmplt          : std_logic;
  signal ipif_Bus2IP_Mst_Error          : std_logic;
  signal ipif_Bus2IP_Mst_Rearbitrate    : std_logic;
  signal ipif_Bus2IP_Mst_Cmd_Timeout    : std_logic;
  signal ipif_Bus2IP_MstRd_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_Bus2IP_MstRd_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_Bus2IP_MstRd_sof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_eof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_src_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstRd_src_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstWr_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_IP2Bus_MstWr_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_MstWr_sof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_eof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_src_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstWr_src_dsc_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_dsc_n    : std_logic;
--  signal user_Bus2IP_RdCE               : std_logic_vector(0 to USER_NUM_REG-1);
--  signal user_Bus2IP_WrCE               : std_logic_vector(0 to USER_NUM_REG-1);
--  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;

begin

  ------------------------------------------
  -- instantiate plbv46_master_burst
  ------------------------------------------
  PLBV46_MASTER_BURST_I : entity plbv46_master_burst_v1_01_a.plbv46_master_burst
    generic map
    (
      C_MPLB_AWIDTH                  => C_MPLB_AWIDTH,
      C_MPLB_DWIDTH                  => C_MPLB_DWIDTH,
      C_MPLB_NATIVE_DWIDTH           => IPIF_MST_DWIDTH,
      C_MPLB_SMALLEST_SLAVE          => C_MPLB_SMALLEST_SLAVE,
      C_INHIBIT_CC_BLE_INCLUSION     => IPIF_INHIBIT_CC_BLE_INCLUSION,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      MPLB_Clk                       => MPLB_Clk,
      MPLB_Rst                       => MPLB_Rst,
      MD_error                       => MD_error,
      M_request                      => M_request,
      M_priority                     => M_priority,
      M_busLock                      => M_busLock,
      M_RNW                          => M_RNW,
      M_BE                           => M_BE,
      M_MSize                        => M_MSize,
      M_size                         => M_size,
      M_type                         => M_type,
      M_TAttribute                   => M_TAttribute,
      M_lockErr                      => M_lockErr,
      M_abort                        => M_abort,
      M_UABus                        => M_UABus,
      M_ABus                         => M_ABus,
      M_wrDBus                       => M_wrDBus,
      M_wrBurst                      => M_wrBurst,
      M_rdBurst                      => M_rdBurst,
      PLB_MAddrAck                   => PLB_MAddrAck,
      PLB_MSSize                     => PLB_MSSize,
      PLB_MRearbitrate               => PLB_MRearbitrate,
      PLB_MTimeout                   => PLB_MTimeout,
      PLB_MBusy                      => PLB_MBusy,
      PLB_MRdErr                     => PLB_MRdErr,
      PLB_MWrErr                     => PLB_MWrErr,
      PLB_MIRQ                       => PLB_MIRQ,
      PLB_MRdDBus                    => PLB_MRdDBus,
      PLB_MRdWdAddr                  => PLB_MRdWdAddr,
      PLB_MRdDAck                    => PLB_MRdDAck,
      PLB_MRdBTerm                   => PLB_MRdBTerm,
      PLB_MWrDAck                    => PLB_MWrDAck,
      PLB_MWrBTerm                   => PLB_MWrBTerm,
      IP2Bus_MstRd_Req               => ipif_IP2Bus_MstRd_Req,
      IP2Bus_MstWr_Req               => ipif_IP2Bus_MstWr_Req,
      IP2Bus_Mst_Addr                => ipif_IP2Bus_Mst_Addr,
      IP2Bus_Mst_Length              => ipif_IP2Bus_Mst_Length,
      IP2Bus_Mst_BE                  => ipif_IP2Bus_Mst_BE,
      IP2Bus_Mst_Type                => ipif_IP2Bus_Mst_Type,
      IP2Bus_Mst_Lock                => ipif_IP2Bus_Mst_Lock,
      IP2Bus_Mst_Reset               => ipif_IP2Bus_Mst_Reset,
      Bus2IP_Mst_CmdAck              => ipif_Bus2IP_Mst_CmdAck,
      Bus2IP_Mst_Cmplt               => ipif_Bus2IP_Mst_Cmplt,
      Bus2IP_Mst_Error               => ipif_Bus2IP_Mst_Error,
      Bus2IP_Mst_Rearbitrate         => ipif_Bus2IP_Mst_Rearbitrate,
      Bus2IP_Mst_Cmd_Timeout         => ipif_Bus2IP_Mst_Cmd_Timeout,
      Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
      Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
      Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
      Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
      Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
      Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
      IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
      IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
      IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
      IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
      IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
      IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
      IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
      IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
      Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
      Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n
    );

	------------------------------------------
	-- instantiate User Logic
	------------------------------------------
	USER_LOGIC_I : entity xps_mem_v1_00_a.user_logic
	generic map
	(
		--C_SLV_DWIDTH                   => USER_SLV_DWIDTH,
		C_MST_AWIDTH                   => USER_MST_AWIDTH,
		C_MST_DWIDTH                   => USER_MST_DWIDTH,
		C_NUM_REG                      => USER_NUM_REG
	)
	port map
	(
		Bus2IP_Clk                     => MPLB_Clk,
		Bus2IP_Reset                   => MPLB_Rst,
		--      Bus2IP_Data                    => ipif_Bus2IP_Data,
		--      Bus2IP_BE                      => ipif_Bus2IP_BE,
		--      Bus2IP_RdCE                    => user_Bus2IP_RdCE,
		--      Bus2IP_WrCE                    => user_Bus2IP_WrCE,
		--      IP2Bus_Data                    => user_IP2Bus_Data,
		IP2Bus_RdAck                   => user_IP2Bus_RdAck,
		IP2Bus_WrAck                   => user_IP2Bus_WrAck,
		IP2Bus_Error                   => user_IP2Bus_Error,
		IP2Bus_MstRd_Req               => ipif_IP2Bus_MstRd_Req,
		IP2Bus_MstWr_Req               => ipif_IP2Bus_MstWr_Req,
		IP2Bus_Mst_Addr                => ipif_IP2Bus_Mst_Addr,
		IP2Bus_Mst_BE                  => ipif_IP2Bus_Mst_BE,
		IP2Bus_Mst_Length              => ipif_IP2Bus_Mst_Length,
		IP2Bus_Mst_Type                => ipif_IP2Bus_Mst_Type,
		IP2Bus_Mst_Lock                => ipif_IP2Bus_Mst_Lock,
		IP2Bus_Mst_Reset               => ipif_IP2Bus_Mst_Reset,
		Bus2IP_Mst_CmdAck              => ipif_Bus2IP_Mst_CmdAck,
		Bus2IP_Mst_Cmplt               => ipif_Bus2IP_Mst_Cmplt,
		Bus2IP_Mst_Error               => ipif_Bus2IP_Mst_Error,
		Bus2IP_Mst_Rearbitrate         => ipif_Bus2IP_Mst_Rearbitrate,
		Bus2IP_Mst_Cmd_Timeout         => ipif_Bus2IP_Mst_Cmd_Timeout,
		Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
		Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
		Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
		Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
		Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
		Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
		IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
		IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
		IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
		IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
		IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
		IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
		IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
		IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
		Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
		Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n,
		
		-- FIFO Interface
		FIFO32_S_Clk => FIFO32_S_Clk,
		FIFO32_S_Data => FIFO32_S_Data,
		FIFO32_S_Fill => FIFO32_S_Fill,
		FIFO32_S_Rd => FIFO32_S_Rd,
		
		FIFO32_M_Clk => FIFO32_M_Clk,
		FIFO32_M_Data => FIFO32_M_Data,
		FIFO32_M_Rem => FIFO32_M_Rem,
		FIFO32_M_Wr => FIFO32_M_Wr
	);

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
--  ipif_IP2Bus_Data <= user_IP2Bus_Data;
  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error;

--  user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);
--  user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);

end IMP;
