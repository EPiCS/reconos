-------------------------------------------------------------------------------
-- system.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity system is
  port (
    fpga_0_RS232_Uart_1_RX_pin : in std_logic;
    fpga_0_RS232_Uart_1_TX_pin : out std_logic;
    fpga_0_LEDs_8Bit_GPIO_IO_pin : inout std_logic_vector(0 to 7);
    fpga_0_LEDs_Positions_GPIO_IO_pin : inout std_logic_vector(0 to 4);
    fpga_0_Push_Buttons_5Bit_GPIO_IO_pin : inout std_logic_vector(0 to 4);
    fpga_0_DIP_Switches_8Bit_GPIO_IO_pin : inout std_logic_vector(0 to 7);
    fpga_0_IIC_EEPROM_Sda_pin : inout std_logic;
    fpga_0_IIC_EEPROM_Scl_pin : inout std_logic;
    fpga_0_IIC_FMC_LPC_Sda_pin : inout std_logic;
    fpga_0_IIC_FMC_LPC_Scl_pin : inout std_logic;
    fpga_0_IIC_DVI_Sda_pin : inout std_logic;
    fpga_0_IIC_DVI_Scl_pin : inout std_logic;
    fpga_0_IIC_SFP_Sda_pin : inout std_logic;
    fpga_0_IIC_SFP_Scl_pin : inout std_logic;
    fpga_0_FLASH_Mem_A_pin : out std_logic_vector(7 to 30);
    fpga_0_Ethernet_MAC_PHY_tx_clk_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_rx_clk_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_crs_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_dv_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_rx_data_pin : in std_logic_vector(3 downto 0);
    fpga_0_Ethernet_MAC_PHY_col_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_rx_er_pin : in std_logic;
    fpga_0_Ethernet_MAC_PHY_rst_n_pin : out std_logic;
    fpga_0_Ethernet_MAC_PHY_tx_en_pin : out std_logic;
    fpga_0_Ethernet_MAC_PHY_tx_data_pin : out std_logic_vector(3 downto 0);
    fpga_0_Ethernet_MAC_PHY_MDC_pin : out std_logic;
    fpga_0_Ethernet_MAC_PHY_MDIO_pin : inout std_logic;
    fpga_0_Ethernet_MAC_MDINT_pin : in std_logic;
    fpga_0_DDR3_SDRAM_DDR3_Clk_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_Clk_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_CE_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_CS_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_ODT_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_RAS_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_CAS_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_WE_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_BankAddr_pin : out std_logic_vector(2 downto 0);
    fpga_0_DDR3_SDRAM_DDR3_Addr_pin : out std_logic_vector(12 downto 0);
    fpga_0_DDR3_SDRAM_DDR3_DQ_pin : inout std_logic_vector(31 downto 0);
    fpga_0_DDR3_SDRAM_DDR3_DM_pin : out std_logic_vector(3 downto 0);
    fpga_0_DDR3_SDRAM_DDR3_Reset_n_pin : out std_logic;
    fpga_0_DDR3_SDRAM_DDR3_DQS_pin : inout std_logic_vector(3 downto 0);
    fpga_0_DDR3_SDRAM_DDR3_DQS_n_pin : inout std_logic_vector(3 downto 0);
    fpga_0_clk_1_sys_clk_p_pin : in std_logic;
    fpga_0_clk_1_sys_clk_n_pin : in std_logic;
    fpga_0_rst_1_sys_rst_pin : in std_logic;
    fpga_0_FLASH_CE_inverter_Res_pin : out std_logic;
    fpga_0_PCIe_Diff_Clk_IBUF_DS_P_pin : in std_logic;
    fpga_0_PCIe_Diff_Clk_IBUF_DS_N_pin : in std_logic;
    fsl_ila_0_FSL_S_Read_pin : in std_logic
  );
end system;

architecture STRUCTURE of system is

  component microblaze_0_wrapper is
    port (
      CLK : in std_logic;
      RESET : in std_logic;
      MB_RESET : in std_logic;
      INTERRUPT : in std_logic;
      EXT_BRK : in std_logic;
      EXT_NM_BRK : in std_logic;
      DBG_STOP : in std_logic;
      MB_Halted : out std_logic;
      MB_Error : out std_logic;
      INSTR : in std_logic_vector(0 to 31);
      IREADY : in std_logic;
      IWAIT : in std_logic;
      ICE : in std_logic;
      IUE : in std_logic;
      INSTR_ADDR : out std_logic_vector(0 to 31);
      IFETCH : out std_logic;
      I_AS : out std_logic;
      IPLB_M_ABort : out std_logic;
      IPLB_M_ABus : out std_logic_vector(0 to 31);
      IPLB_M_UABus : out std_logic_vector(0 to 31);
      IPLB_M_BE : out std_logic_vector(0 to 7);
      IPLB_M_busLock : out std_logic;
      IPLB_M_lockErr : out std_logic;
      IPLB_M_MSize : out std_logic_vector(0 to 1);
      IPLB_M_priority : out std_logic_vector(0 to 1);
      IPLB_M_rdBurst : out std_logic;
      IPLB_M_request : out std_logic;
      IPLB_M_RNW : out std_logic;
      IPLB_M_size : out std_logic_vector(0 to 3);
      IPLB_M_TAttribute : out std_logic_vector(0 to 15);
      IPLB_M_type : out std_logic_vector(0 to 2);
      IPLB_M_wrBurst : out std_logic;
      IPLB_M_wrDBus : out std_logic_vector(0 to 63);
      IPLB_MBusy : in std_logic;
      IPLB_MRdErr : in std_logic;
      IPLB_MWrErr : in std_logic;
      IPLB_MIRQ : in std_logic;
      IPLB_MWrBTerm : in std_logic;
      IPLB_MWrDAck : in std_logic;
      IPLB_MAddrAck : in std_logic;
      IPLB_MRdBTerm : in std_logic;
      IPLB_MRdDAck : in std_logic;
      IPLB_MRdDBus : in std_logic_vector(0 to 63);
      IPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      IPLB_MRearbitrate : in std_logic;
      IPLB_MSSize : in std_logic_vector(0 to 1);
      IPLB_MTimeout : in std_logic;
      DATA_READ : in std_logic_vector(0 to 31);
      DREADY : in std_logic;
      DWAIT : in std_logic;
      DCE : in std_logic;
      DUE : in std_logic;
      DATA_WRITE : out std_logic_vector(0 to 31);
      DATA_ADDR : out std_logic_vector(0 to 31);
      D_AS : out std_logic;
      READ_STROBE : out std_logic;
      WRITE_STROBE : out std_logic;
      BYTE_ENABLE : out std_logic_vector(0 to 3);
      DPLB_M_ABort : out std_logic;
      DPLB_M_ABus : out std_logic_vector(0 to 31);
      DPLB_M_UABus : out std_logic_vector(0 to 31);
      DPLB_M_BE : out std_logic_vector(0 to 7);
      DPLB_M_busLock : out std_logic;
      DPLB_M_lockErr : out std_logic;
      DPLB_M_MSize : out std_logic_vector(0 to 1);
      DPLB_M_priority : out std_logic_vector(0 to 1);
      DPLB_M_rdBurst : out std_logic;
      DPLB_M_request : out std_logic;
      DPLB_M_RNW : out std_logic;
      DPLB_M_size : out std_logic_vector(0 to 3);
      DPLB_M_TAttribute : out std_logic_vector(0 to 15);
      DPLB_M_type : out std_logic_vector(0 to 2);
      DPLB_M_wrBurst : out std_logic;
      DPLB_M_wrDBus : out std_logic_vector(0 to 63);
      DPLB_MBusy : in std_logic;
      DPLB_MRdErr : in std_logic;
      DPLB_MWrErr : in std_logic;
      DPLB_MIRQ : in std_logic;
      DPLB_MWrBTerm : in std_logic;
      DPLB_MWrDAck : in std_logic;
      DPLB_MAddrAck : in std_logic;
      DPLB_MRdBTerm : in std_logic;
      DPLB_MRdDAck : in std_logic;
      DPLB_MRdDBus : in std_logic_vector(0 to 63);
      DPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      DPLB_MRearbitrate : in std_logic;
      DPLB_MSSize : in std_logic_vector(0 to 1);
      DPLB_MTimeout : in std_logic;
      M_AXI_IP_AWID : out std_logic_vector(0 downto 0);
      M_AXI_IP_AWADDR : out std_logic_vector(31 downto 0);
      M_AXI_IP_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_IP_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_IP_AWLOCK : out std_logic;
      M_AXI_IP_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWVALID : out std_logic;
      M_AXI_IP_AWREADY : in std_logic;
      M_AXI_IP_WDATA : out std_logic_vector(31 downto 0);
      M_AXI_IP_WSTRB : out std_logic_vector(3 downto 0);
      M_AXI_IP_WLAST : out std_logic;
      M_AXI_IP_WVALID : out std_logic;
      M_AXI_IP_WREADY : in std_logic;
      M_AXI_IP_BID : in std_logic_vector(0 downto 0);
      M_AXI_IP_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_IP_BVALID : in std_logic;
      M_AXI_IP_BREADY : out std_logic;
      M_AXI_IP_ARID : out std_logic_vector(0 downto 0);
      M_AXI_IP_ARADDR : out std_logic_vector(31 downto 0);
      M_AXI_IP_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_IP_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_IP_ARLOCK : out std_logic;
      M_AXI_IP_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARVALID : out std_logic;
      M_AXI_IP_ARREADY : in std_logic;
      M_AXI_IP_RID : in std_logic_vector(0 downto 0);
      M_AXI_IP_RDATA : in std_logic_vector(31 downto 0);
      M_AXI_IP_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_IP_RLAST : in std_logic;
      M_AXI_IP_RVALID : in std_logic;
      M_AXI_IP_RREADY : out std_logic;
      M_AXI_DP_AWID : out std_logic_vector(0 downto 0);
      M_AXI_DP_AWADDR : out std_logic_vector(31 downto 0);
      M_AXI_DP_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_DP_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_DP_AWLOCK : out std_logic;
      M_AXI_DP_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWVALID : out std_logic;
      M_AXI_DP_AWREADY : in std_logic;
      M_AXI_DP_WDATA : out std_logic_vector(31 downto 0);
      M_AXI_DP_WSTRB : out std_logic_vector(3 downto 0);
      M_AXI_DP_WLAST : out std_logic;
      M_AXI_DP_WVALID : out std_logic;
      M_AXI_DP_WREADY : in std_logic;
      M_AXI_DP_BID : in std_logic_vector(0 downto 0);
      M_AXI_DP_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_DP_BVALID : in std_logic;
      M_AXI_DP_BREADY : out std_logic;
      M_AXI_DP_ARID : out std_logic_vector(0 downto 0);
      M_AXI_DP_ARADDR : out std_logic_vector(31 downto 0);
      M_AXI_DP_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_DP_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_DP_ARLOCK : out std_logic;
      M_AXI_DP_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARVALID : out std_logic;
      M_AXI_DP_ARREADY : in std_logic;
      M_AXI_DP_RID : in std_logic_vector(0 downto 0);
      M_AXI_DP_RDATA : in std_logic_vector(31 downto 0);
      M_AXI_DP_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_DP_RLAST : in std_logic;
      M_AXI_DP_RVALID : in std_logic;
      M_AXI_DP_RREADY : out std_logic;
      M_AXI_IC_AWID : out std_logic_vector(0 downto 0);
      M_AXI_IC_AWADDR : out std_logic_vector(31 downto 0);
      M_AXI_IC_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_IC_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_IC_AWLOCK : out std_logic;
      M_AXI_IC_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWVALID : out std_logic;
      M_AXI_IC_AWREADY : in std_logic;
      M_AXI_IC_WDATA : out std_logic_vector(31 downto 0);
      M_AXI_IC_WSTRB : out std_logic_vector(3 downto 0);
      M_AXI_IC_WLAST : out std_logic;
      M_AXI_IC_WVALID : out std_logic;
      M_AXI_IC_WREADY : in std_logic;
      M_AXI_IC_BID : in std_logic_vector(0 downto 0);
      M_AXI_IC_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_IC_BVALID : in std_logic;
      M_AXI_IC_BREADY : out std_logic;
      M_AXI_IC_ARID : out std_logic_vector(0 downto 0);
      M_AXI_IC_ARADDR : out std_logic_vector(31 downto 0);
      M_AXI_IC_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_IC_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_IC_ARLOCK : out std_logic;
      M_AXI_IC_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARVALID : out std_logic;
      M_AXI_IC_ARREADY : in std_logic;
      M_AXI_IC_RID : in std_logic_vector(0 downto 0);
      M_AXI_IC_RDATA : in std_logic_vector(31 downto 0);
      M_AXI_IC_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_IC_RLAST : in std_logic;
      M_AXI_IC_RVALID : in std_logic;
      M_AXI_IC_RREADY : out std_logic;
      M_AXI_DC_AWID : out std_logic_vector(0 downto 0);
      M_AXI_DC_AWADDR : out std_logic_vector(31 downto 0);
      M_AXI_DC_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_DC_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_DC_AWLOCK : out std_logic;
      M_AXI_DC_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWVALID : out std_logic;
      M_AXI_DC_AWREADY : in std_logic;
      M_AXI_DC_WDATA : out std_logic_vector(31 downto 0);
      M_AXI_DC_WSTRB : out std_logic_vector(3 downto 0);
      M_AXI_DC_WLAST : out std_logic;
      M_AXI_DC_WVALID : out std_logic;
      M_AXI_DC_WREADY : in std_logic;
      M_AXI_DC_BID : in std_logic_vector(0 downto 0);
      M_AXI_DC_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_DC_BVALID : in std_logic;
      M_AXI_DC_BREADY : out std_logic;
      M_AXI_DC_ARID : out std_logic_vector(0 downto 0);
      M_AXI_DC_ARADDR : out std_logic_vector(31 downto 0);
      M_AXI_DC_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_DC_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_DC_ARLOCK : out std_logic;
      M_AXI_DC_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARVALID : out std_logic;
      M_AXI_DC_ARREADY : in std_logic;
      M_AXI_DC_RID : in std_logic_vector(0 downto 0);
      M_AXI_DC_RDATA : in std_logic_vector(31 downto 0);
      M_AXI_DC_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_DC_RLAST : in std_logic;
      M_AXI_DC_RVALID : in std_logic;
      M_AXI_DC_RREADY : out std_logic;
      DBG_CLK : in std_logic;
      DBG_TDI : in std_logic;
      DBG_TDO : out std_logic;
      DBG_REG_EN : in std_logic_vector(0 to 7);
      DBG_SHIFT : in std_logic;
      DBG_CAPTURE : in std_logic;
      DBG_UPDATE : in std_logic;
      DEBUG_RST : in std_logic;
      Trace_Instruction : out std_logic_vector(0 to 31);
      Trace_Valid_Instr : out std_logic;
      Trace_PC : out std_logic_vector(0 to 31);
      Trace_Reg_Write : out std_logic;
      Trace_Reg_Addr : out std_logic_vector(0 to 4);
      Trace_MSR_Reg : out std_logic_vector(0 to 14);
      Trace_PID_Reg : out std_logic_vector(0 to 7);
      Trace_New_Reg_Value : out std_logic_vector(0 to 31);
      Trace_Exception_Taken : out std_logic;
      Trace_Exception_Kind : out std_logic_vector(0 to 4);
      Trace_Jump_Taken : out std_logic;
      Trace_Delay_Slot : out std_logic;
      Trace_Data_Address : out std_logic_vector(0 to 31);
      Trace_Data_Access : out std_logic;
      Trace_Data_Read : out std_logic;
      Trace_Data_Write : out std_logic;
      Trace_Data_Write_Value : out std_logic_vector(0 to 31);
      Trace_Data_Byte_Enable : out std_logic_vector(0 to 3);
      Trace_DCache_Req : out std_logic;
      Trace_DCache_Hit : out std_logic;
      Trace_DCache_Rdy : out std_logic;
      Trace_DCache_Read : out std_logic;
      Trace_ICache_Req : out std_logic;
      Trace_ICache_Hit : out std_logic;
      Trace_ICache_Rdy : out std_logic;
      Trace_OF_PipeRun : out std_logic;
      Trace_EX_PipeRun : out std_logic;
      Trace_MEM_PipeRun : out std_logic;
      Trace_MB_Halted : out std_logic;
      Trace_Jump_Hit : out std_logic;
      FSL0_S_CLK : out std_logic;
      FSL0_S_READ : out std_logic;
      FSL0_S_DATA : in std_logic_vector(0 to 31);
      FSL0_S_CONTROL : in std_logic;
      FSL0_S_EXISTS : in std_logic;
      FSL0_M_CLK : out std_logic;
      FSL0_M_WRITE : out std_logic;
      FSL0_M_DATA : out std_logic_vector(0 to 31);
      FSL0_M_CONTROL : out std_logic;
      FSL0_M_FULL : in std_logic;
      FSL1_S_CLK : out std_logic;
      FSL1_S_READ : out std_logic;
      FSL1_S_DATA : in std_logic_vector(0 to 31);
      FSL1_S_CONTROL : in std_logic;
      FSL1_S_EXISTS : in std_logic;
      FSL1_M_CLK : out std_logic;
      FSL1_M_WRITE : out std_logic;
      FSL1_M_DATA : out std_logic_vector(0 to 31);
      FSL1_M_CONTROL : out std_logic;
      FSL1_M_FULL : in std_logic;
      FSL2_S_CLK : out std_logic;
      FSL2_S_READ : out std_logic;
      FSL2_S_DATA : in std_logic_vector(0 to 31);
      FSL2_S_CONTROL : in std_logic;
      FSL2_S_EXISTS : in std_logic;
      FSL2_M_CLK : out std_logic;
      FSL2_M_WRITE : out std_logic;
      FSL2_M_DATA : out std_logic_vector(0 to 31);
      FSL2_M_CONTROL : out std_logic;
      FSL2_M_FULL : in std_logic;
      FSL3_S_CLK : out std_logic;
      FSL3_S_READ : out std_logic;
      FSL3_S_DATA : in std_logic_vector(0 to 31);
      FSL3_S_CONTROL : in std_logic;
      FSL3_S_EXISTS : in std_logic;
      FSL3_M_CLK : out std_logic;
      FSL3_M_WRITE : out std_logic;
      FSL3_M_DATA : out std_logic_vector(0 to 31);
      FSL3_M_CONTROL : out std_logic;
      FSL3_M_FULL : in std_logic;
      FSL4_S_CLK : out std_logic;
      FSL4_S_READ : out std_logic;
      FSL4_S_DATA : in std_logic_vector(0 to 31);
      FSL4_S_CONTROL : in std_logic;
      FSL4_S_EXISTS : in std_logic;
      FSL4_M_CLK : out std_logic;
      FSL4_M_WRITE : out std_logic;
      FSL4_M_DATA : out std_logic_vector(0 to 31);
      FSL4_M_CONTROL : out std_logic;
      FSL4_M_FULL : in std_logic;
      FSL5_S_CLK : out std_logic;
      FSL5_S_READ : out std_logic;
      FSL5_S_DATA : in std_logic_vector(0 to 31);
      FSL5_S_CONTROL : in std_logic;
      FSL5_S_EXISTS : in std_logic;
      FSL5_M_CLK : out std_logic;
      FSL5_M_WRITE : out std_logic;
      FSL5_M_DATA : out std_logic_vector(0 to 31);
      FSL5_M_CONTROL : out std_logic;
      FSL5_M_FULL : in std_logic;
      FSL6_S_CLK : out std_logic;
      FSL6_S_READ : out std_logic;
      FSL6_S_DATA : in std_logic_vector(0 to 31);
      FSL6_S_CONTROL : in std_logic;
      FSL6_S_EXISTS : in std_logic;
      FSL6_M_CLK : out std_logic;
      FSL6_M_WRITE : out std_logic;
      FSL6_M_DATA : out std_logic_vector(0 to 31);
      FSL6_M_CONTROL : out std_logic;
      FSL6_M_FULL : in std_logic;
      FSL7_S_CLK : out std_logic;
      FSL7_S_READ : out std_logic;
      FSL7_S_DATA : in std_logic_vector(0 to 31);
      FSL7_S_CONTROL : in std_logic;
      FSL7_S_EXISTS : in std_logic;
      FSL7_M_CLK : out std_logic;
      FSL7_M_WRITE : out std_logic;
      FSL7_M_DATA : out std_logic_vector(0 to 31);
      FSL7_M_CONTROL : out std_logic;
      FSL7_M_FULL : in std_logic;
      FSL8_S_CLK : out std_logic;
      FSL8_S_READ : out std_logic;
      FSL8_S_DATA : in std_logic_vector(0 to 31);
      FSL8_S_CONTROL : in std_logic;
      FSL8_S_EXISTS : in std_logic;
      FSL8_M_CLK : out std_logic;
      FSL8_M_WRITE : out std_logic;
      FSL8_M_DATA : out std_logic_vector(0 to 31);
      FSL8_M_CONTROL : out std_logic;
      FSL8_M_FULL : in std_logic;
      FSL9_S_CLK : out std_logic;
      FSL9_S_READ : out std_logic;
      FSL9_S_DATA : in std_logic_vector(0 to 31);
      FSL9_S_CONTROL : in std_logic;
      FSL9_S_EXISTS : in std_logic;
      FSL9_M_CLK : out std_logic;
      FSL9_M_WRITE : out std_logic;
      FSL9_M_DATA : out std_logic_vector(0 to 31);
      FSL9_M_CONTROL : out std_logic;
      FSL9_M_FULL : in std_logic;
      FSL10_S_CLK : out std_logic;
      FSL10_S_READ : out std_logic;
      FSL10_S_DATA : in std_logic_vector(0 to 31);
      FSL10_S_CONTROL : in std_logic;
      FSL10_S_EXISTS : in std_logic;
      FSL10_M_CLK : out std_logic;
      FSL10_M_WRITE : out std_logic;
      FSL10_M_DATA : out std_logic_vector(0 to 31);
      FSL10_M_CONTROL : out std_logic;
      FSL10_M_FULL : in std_logic;
      FSL11_S_CLK : out std_logic;
      FSL11_S_READ : out std_logic;
      FSL11_S_DATA : in std_logic_vector(0 to 31);
      FSL11_S_CONTROL : in std_logic;
      FSL11_S_EXISTS : in std_logic;
      FSL11_M_CLK : out std_logic;
      FSL11_M_WRITE : out std_logic;
      FSL11_M_DATA : out std_logic_vector(0 to 31);
      FSL11_M_CONTROL : out std_logic;
      FSL11_M_FULL : in std_logic;
      FSL12_S_CLK : out std_logic;
      FSL12_S_READ : out std_logic;
      FSL12_S_DATA : in std_logic_vector(0 to 31);
      FSL12_S_CONTROL : in std_logic;
      FSL12_S_EXISTS : in std_logic;
      FSL12_M_CLK : out std_logic;
      FSL12_M_WRITE : out std_logic;
      FSL12_M_DATA : out std_logic_vector(0 to 31);
      FSL12_M_CONTROL : out std_logic;
      FSL12_M_FULL : in std_logic;
      FSL13_S_CLK : out std_logic;
      FSL13_S_READ : out std_logic;
      FSL13_S_DATA : in std_logic_vector(0 to 31);
      FSL13_S_CONTROL : in std_logic;
      FSL13_S_EXISTS : in std_logic;
      FSL13_M_CLK : out std_logic;
      FSL13_M_WRITE : out std_logic;
      FSL13_M_DATA : out std_logic_vector(0 to 31);
      FSL13_M_CONTROL : out std_logic;
      FSL13_M_FULL : in std_logic;
      FSL14_S_CLK : out std_logic;
      FSL14_S_READ : out std_logic;
      FSL14_S_DATA : in std_logic_vector(0 to 31);
      FSL14_S_CONTROL : in std_logic;
      FSL14_S_EXISTS : in std_logic;
      FSL14_M_CLK : out std_logic;
      FSL14_M_WRITE : out std_logic;
      FSL14_M_DATA : out std_logic_vector(0 to 31);
      FSL14_M_CONTROL : out std_logic;
      FSL14_M_FULL : in std_logic;
      FSL15_S_CLK : out std_logic;
      FSL15_S_READ : out std_logic;
      FSL15_S_DATA : in std_logic_vector(0 to 31);
      FSL15_S_CONTROL : in std_logic;
      FSL15_S_EXISTS : in std_logic;
      FSL15_M_CLK : out std_logic;
      FSL15_M_WRITE : out std_logic;
      FSL15_M_DATA : out std_logic_vector(0 to 31);
      FSL15_M_CONTROL : out std_logic;
      FSL15_M_FULL : in std_logic;
      M0_AXIS_TLAST : out std_logic;
      M0_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M0_AXIS_TVALID : out std_logic;
      M0_AXIS_TREADY : in std_logic;
      S0_AXIS_TLAST : in std_logic;
      S0_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S0_AXIS_TVALID : in std_logic;
      S0_AXIS_TREADY : out std_logic;
      M1_AXIS_TLAST : out std_logic;
      M1_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M1_AXIS_TVALID : out std_logic;
      M1_AXIS_TREADY : in std_logic;
      S1_AXIS_TLAST : in std_logic;
      S1_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S1_AXIS_TVALID : in std_logic;
      S1_AXIS_TREADY : out std_logic;
      M2_AXIS_TLAST : out std_logic;
      M2_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M2_AXIS_TVALID : out std_logic;
      M2_AXIS_TREADY : in std_logic;
      S2_AXIS_TLAST : in std_logic;
      S2_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S2_AXIS_TVALID : in std_logic;
      S2_AXIS_TREADY : out std_logic;
      M3_AXIS_TLAST : out std_logic;
      M3_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M3_AXIS_TVALID : out std_logic;
      M3_AXIS_TREADY : in std_logic;
      S3_AXIS_TLAST : in std_logic;
      S3_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S3_AXIS_TVALID : in std_logic;
      S3_AXIS_TREADY : out std_logic;
      M4_AXIS_TLAST : out std_logic;
      M4_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M4_AXIS_TVALID : out std_logic;
      M4_AXIS_TREADY : in std_logic;
      S4_AXIS_TLAST : in std_logic;
      S4_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S4_AXIS_TVALID : in std_logic;
      S4_AXIS_TREADY : out std_logic;
      M5_AXIS_TLAST : out std_logic;
      M5_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M5_AXIS_TVALID : out std_logic;
      M5_AXIS_TREADY : in std_logic;
      S5_AXIS_TLAST : in std_logic;
      S5_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S5_AXIS_TVALID : in std_logic;
      S5_AXIS_TREADY : out std_logic;
      M6_AXIS_TLAST : out std_logic;
      M6_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M6_AXIS_TVALID : out std_logic;
      M6_AXIS_TREADY : in std_logic;
      S6_AXIS_TLAST : in std_logic;
      S6_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S6_AXIS_TVALID : in std_logic;
      S6_AXIS_TREADY : out std_logic;
      M7_AXIS_TLAST : out std_logic;
      M7_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M7_AXIS_TVALID : out std_logic;
      M7_AXIS_TREADY : in std_logic;
      S7_AXIS_TLAST : in std_logic;
      S7_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S7_AXIS_TVALID : in std_logic;
      S7_AXIS_TREADY : out std_logic;
      M8_AXIS_TLAST : out std_logic;
      M8_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M8_AXIS_TVALID : out std_logic;
      M8_AXIS_TREADY : in std_logic;
      S8_AXIS_TLAST : in std_logic;
      S8_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S8_AXIS_TVALID : in std_logic;
      S8_AXIS_TREADY : out std_logic;
      M9_AXIS_TLAST : out std_logic;
      M9_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M9_AXIS_TVALID : out std_logic;
      M9_AXIS_TREADY : in std_logic;
      S9_AXIS_TLAST : in std_logic;
      S9_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S9_AXIS_TVALID : in std_logic;
      S9_AXIS_TREADY : out std_logic;
      M10_AXIS_TLAST : out std_logic;
      M10_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M10_AXIS_TVALID : out std_logic;
      M10_AXIS_TREADY : in std_logic;
      S10_AXIS_TLAST : in std_logic;
      S10_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S10_AXIS_TVALID : in std_logic;
      S10_AXIS_TREADY : out std_logic;
      M11_AXIS_TLAST : out std_logic;
      M11_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M11_AXIS_TVALID : out std_logic;
      M11_AXIS_TREADY : in std_logic;
      S11_AXIS_TLAST : in std_logic;
      S11_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S11_AXIS_TVALID : in std_logic;
      S11_AXIS_TREADY : out std_logic;
      M12_AXIS_TLAST : out std_logic;
      M12_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M12_AXIS_TVALID : out std_logic;
      M12_AXIS_TREADY : in std_logic;
      S12_AXIS_TLAST : in std_logic;
      S12_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S12_AXIS_TVALID : in std_logic;
      S12_AXIS_TREADY : out std_logic;
      M13_AXIS_TLAST : out std_logic;
      M13_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M13_AXIS_TVALID : out std_logic;
      M13_AXIS_TREADY : in std_logic;
      S13_AXIS_TLAST : in std_logic;
      S13_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S13_AXIS_TVALID : in std_logic;
      S13_AXIS_TREADY : out std_logic;
      M14_AXIS_TLAST : out std_logic;
      M14_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M14_AXIS_TVALID : out std_logic;
      M14_AXIS_TREADY : in std_logic;
      S14_AXIS_TLAST : in std_logic;
      S14_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S14_AXIS_TVALID : in std_logic;
      S14_AXIS_TREADY : out std_logic;
      M15_AXIS_TLAST : out std_logic;
      M15_AXIS_TDATA : out std_logic_vector(31 downto 0);
      M15_AXIS_TVALID : out std_logic;
      M15_AXIS_TREADY : in std_logic;
      S15_AXIS_TLAST : in std_logic;
      S15_AXIS_TDATA : in std_logic_vector(31 downto 0);
      S15_AXIS_TVALID : in std_logic;
      S15_AXIS_TREADY : out std_logic;
      ICACHE_FSL_IN_CLK : out std_logic;
      ICACHE_FSL_IN_READ : out std_logic;
      ICACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      ICACHE_FSL_IN_CONTROL : in std_logic;
      ICACHE_FSL_IN_EXISTS : in std_logic;
      ICACHE_FSL_OUT_CLK : out std_logic;
      ICACHE_FSL_OUT_WRITE : out std_logic;
      ICACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      ICACHE_FSL_OUT_CONTROL : out std_logic;
      ICACHE_FSL_OUT_FULL : in std_logic;
      DCACHE_FSL_IN_CLK : out std_logic;
      DCACHE_FSL_IN_READ : out std_logic;
      DCACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      DCACHE_FSL_IN_CONTROL : in std_logic;
      DCACHE_FSL_IN_EXISTS : in std_logic;
      DCACHE_FSL_OUT_CLK : out std_logic;
      DCACHE_FSL_OUT_WRITE : out std_logic;
      DCACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      DCACHE_FSL_OUT_CONTROL : out std_logic;
      DCACHE_FSL_OUT_FULL : in std_logic
    );
  end component;

  component mb_plb_wrapper is
    port (
      PLB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      PLB_Rst : out std_logic;
      SPLB_Rst : out std_logic_vector(0 to 13);
      MPLB_Rst : out std_logic_vector(0 to 2);
      PLB_dcrAck : out std_logic;
      PLB_dcrDBus : out std_logic_vector(0 to 31);
      DCR_ABus : in std_logic_vector(0 to 9);
      DCR_DBus : in std_logic_vector(0 to 31);
      DCR_Read : in std_logic;
      DCR_Write : in std_logic;
      M_ABus : in std_logic_vector(0 to 95);
      M_UABus : in std_logic_vector(0 to 95);
      M_BE : in std_logic_vector(0 to 23);
      M_RNW : in std_logic_vector(0 to 2);
      M_abort : in std_logic_vector(0 to 2);
      M_busLock : in std_logic_vector(0 to 2);
      M_TAttribute : in std_logic_vector(0 to 47);
      M_lockErr : in std_logic_vector(0 to 2);
      M_MSize : in std_logic_vector(0 to 5);
      M_priority : in std_logic_vector(0 to 5);
      M_rdBurst : in std_logic_vector(0 to 2);
      M_request : in std_logic_vector(0 to 2);
      M_size : in std_logic_vector(0 to 11);
      M_type : in std_logic_vector(0 to 8);
      M_wrBurst : in std_logic_vector(0 to 2);
      M_wrDBus : in std_logic_vector(0 to 191);
      Sl_addrAck : in std_logic_vector(0 to 13);
      Sl_MRdErr : in std_logic_vector(0 to 41);
      Sl_MWrErr : in std_logic_vector(0 to 41);
      Sl_MBusy : in std_logic_vector(0 to 41);
      Sl_rdBTerm : in std_logic_vector(0 to 13);
      Sl_rdComp : in std_logic_vector(0 to 13);
      Sl_rdDAck : in std_logic_vector(0 to 13);
      Sl_rdDBus : in std_logic_vector(0 to 895);
      Sl_rdWdAddr : in std_logic_vector(0 to 55);
      Sl_rearbitrate : in std_logic_vector(0 to 13);
      Sl_SSize : in std_logic_vector(0 to 27);
      Sl_wait : in std_logic_vector(0 to 13);
      Sl_wrBTerm : in std_logic_vector(0 to 13);
      Sl_wrComp : in std_logic_vector(0 to 13);
      Sl_wrDAck : in std_logic_vector(0 to 13);
      Sl_MIRQ : in std_logic_vector(0 to 41);
      PLB_MIRQ : out std_logic_vector(0 to 2);
      PLB_ABus : out std_logic_vector(0 to 31);
      PLB_UABus : out std_logic_vector(0 to 31);
      PLB_BE : out std_logic_vector(0 to 7);
      PLB_MAddrAck : out std_logic_vector(0 to 2);
      PLB_MTimeout : out std_logic_vector(0 to 2);
      PLB_MBusy : out std_logic_vector(0 to 2);
      PLB_MRdErr : out std_logic_vector(0 to 2);
      PLB_MWrErr : out std_logic_vector(0 to 2);
      PLB_MRdBTerm : out std_logic_vector(0 to 2);
      PLB_MRdDAck : out std_logic_vector(0 to 2);
      PLB_MRdDBus : out std_logic_vector(0 to 191);
      PLB_MRdWdAddr : out std_logic_vector(0 to 11);
      PLB_MRearbitrate : out std_logic_vector(0 to 2);
      PLB_MWrBTerm : out std_logic_vector(0 to 2);
      PLB_MWrDAck : out std_logic_vector(0 to 2);
      PLB_MSSize : out std_logic_vector(0 to 5);
      PLB_PAValid : out std_logic;
      PLB_RNW : out std_logic;
      PLB_SAValid : out std_logic;
      PLB_abort : out std_logic;
      PLB_busLock : out std_logic;
      PLB_TAttribute : out std_logic_vector(0 to 15);
      PLB_lockErr : out std_logic;
      PLB_masterID : out std_logic_vector(0 to 1);
      PLB_MSize : out std_logic_vector(0 to 1);
      PLB_rdPendPri : out std_logic_vector(0 to 1);
      PLB_wrPendPri : out std_logic_vector(0 to 1);
      PLB_rdPendReq : out std_logic;
      PLB_wrPendReq : out std_logic;
      PLB_rdBurst : out std_logic;
      PLB_rdPrim : out std_logic_vector(0 to 13);
      PLB_reqPri : out std_logic_vector(0 to 1);
      PLB_size : out std_logic_vector(0 to 3);
      PLB_type : out std_logic_vector(0 to 2);
      PLB_wrBurst : out std_logic;
      PLB_wrDBus : out std_logic_vector(0 to 63);
      PLB_wrPrim : out std_logic_vector(0 to 13);
      PLB_SaddrAck : out std_logic;
      PLB_SMRdErr : out std_logic_vector(0 to 2);
      PLB_SMWrErr : out std_logic_vector(0 to 2);
      PLB_SMBusy : out std_logic_vector(0 to 2);
      PLB_SrdBTerm : out std_logic;
      PLB_SrdComp : out std_logic;
      PLB_SrdDAck : out std_logic;
      PLB_SrdDBus : out std_logic_vector(0 to 63);
      PLB_SrdWdAddr : out std_logic_vector(0 to 3);
      PLB_Srearbitrate : out std_logic;
      PLB_Sssize : out std_logic_vector(0 to 1);
      PLB_Swait : out std_logic;
      PLB_SwrBTerm : out std_logic;
      PLB_SwrComp : out std_logic;
      PLB_SwrDAck : out std_logic;
      Bus_Error_Det : out std_logic
    );
  end component;

  component rs232_uart_1_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_lockErr : in std_logic;
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_wrBTerm : out std_logic;
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdBTerm : out std_logic;
      Sl_MIRQ : out std_logic_vector(0 to 2);
      RX : in std_logic;
      TX : out std_logic;
      Interrupt : out std_logic
    );
  end component;

  component leds_8bit_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2);
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to 7);
      GPIO_IO_O : out std_logic_vector(0 to 7);
      GPIO_IO_T : out std_logic_vector(0 to 7);
      GPIO2_IO_I : in std_logic_vector(0 to 31);
      GPIO2_IO_O : out std_logic_vector(0 to 31);
      GPIO2_IO_T : out std_logic_vector(0 to 31)
    );
  end component;

  component leds_positions_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2);
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to 4);
      GPIO_IO_O : out std_logic_vector(0 to 4);
      GPIO_IO_T : out std_logic_vector(0 to 4);
      GPIO2_IO_I : in std_logic_vector(0 to 31);
      GPIO2_IO_O : out std_logic_vector(0 to 31);
      GPIO2_IO_T : out std_logic_vector(0 to 31)
    );
  end component;

  component push_buttons_5bit_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2);
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to 4);
      GPIO_IO_O : out std_logic_vector(0 to 4);
      GPIO_IO_T : out std_logic_vector(0 to 4);
      GPIO2_IO_I : in std_logic_vector(0 to 31);
      GPIO2_IO_O : out std_logic_vector(0 to 31);
      GPIO2_IO_T : out std_logic_vector(0 to 31)
    );
  end component;

  component dip_switches_8bit_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2);
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to 7);
      GPIO_IO_O : out std_logic_vector(0 to 7);
      GPIO_IO_T : out std_logic_vector(0 to 7);
      GPIO2_IO_I : in std_logic_vector(0 to 31);
      GPIO2_IO_O : out std_logic_vector(0 to 31);
      GPIO2_IO_T : out std_logic_vector(0 to 31)
    );
  end component;

  component iic_eeprom_wrapper is
    port (
      Sda_I : in std_logic;
      Sda_O : out std_logic;
      Sda_T : out std_logic;
      Scl_I : in std_logic;
      Scl_O : out std_logic;
      Scl_T : out std_logic;
      Gpo : out std_logic_vector(31 to 31);
      IIC2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component iic_fmc_lpc_wrapper is
    port (
      Sda_I : in std_logic;
      Sda_O : out std_logic;
      Sda_T : out std_logic;
      Scl_I : in std_logic;
      Scl_O : out std_logic;
      Scl_T : out std_logic;
      Gpo : out std_logic_vector(31 to 31);
      IIC2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component iic_dvi_wrapper is
    port (
      Sda_I : in std_logic;
      Sda_O : out std_logic;
      Sda_T : out std_logic;
      Scl_I : in std_logic;
      Scl_O : out std_logic;
      Scl_T : out std_logic;
      Gpo : out std_logic_vector(31 to 31);
      IIC2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component iic_sfp_wrapper is
    port (
      Sda_I : in std_logic;
      Sda_O : out std_logic;
      Sda_T : out std_logic;
      Scl_I : in std_logic;
      Scl_O : out std_logic;
      Scl_T : out std_logic;
      Gpo : out std_logic_vector(31 to 31);
      IIC2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component ethernet_mac_wrapper is
    port (
      PHY_tx_clk : in std_logic;
      PHY_rx_clk : in std_logic;
      PHY_crs : in std_logic;
      PHY_dv : in std_logic;
      PHY_rx_data : in std_logic_vector(3 downto 0);
      PHY_col : in std_logic;
      PHY_rx_er : in std_logic;
      PHY_rst_n : out std_logic;
      PHY_tx_en : out std_logic;
      PHY_tx_data : out std_logic_vector(3 downto 0);
      PHY_MDC : out std_logic;
      PHY_MDIO_I : in std_logic;
      PHY_MDIO_O : out std_logic;
      PHY_MDIO_T : out std_logic;
      IP2INTC_Irpt : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component ddr3_sdram_wrapper is
    port (
      FSL0_M_Clk : in std_logic;
      FSL0_M_Write : in std_logic;
      FSL0_M_Data : in std_logic_vector(0 to 31);
      FSL0_M_Control : in std_logic;
      FSL0_M_Full : out std_logic;
      FSL0_S_Clk : in std_logic;
      FSL0_S_Read : in std_logic;
      FSL0_S_Data : out std_logic_vector(0 to 31);
      FSL0_S_Control : out std_logic;
      FSL0_S_Exists : out std_logic;
      FSL0_B_M_Clk : in std_logic;
      FSL0_B_M_Write : in std_logic;
      FSL0_B_M_Data : in std_logic_vector(0 to 31);
      FSL0_B_M_Control : in std_logic;
      FSL0_B_M_Full : out std_logic;
      FSL0_B_S_Clk : in std_logic;
      FSL0_B_S_Read : in std_logic;
      FSL0_B_S_Data : out std_logic_vector(0 to 31);
      FSL0_B_S_Control : out std_logic;
      FSL0_B_S_Exists : out std_logic;
      SPLB0_Clk : in std_logic;
      SPLB0_Rst : in std_logic;
      SPLB0_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB0_PLB_PAValid : in std_logic;
      SPLB0_PLB_SAValid : in std_logic;
      SPLB0_PLB_masterID : in std_logic_vector(0 to 1);
      SPLB0_PLB_RNW : in std_logic;
      SPLB0_PLB_BE : in std_logic_vector(0 to 7);
      SPLB0_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB0_PLB_rdPrim : in std_logic;
      SPLB0_PLB_wrPrim : in std_logic;
      SPLB0_PLB_abort : in std_logic;
      SPLB0_PLB_busLock : in std_logic;
      SPLB0_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB0_PLB_size : in std_logic_vector(0 to 3);
      SPLB0_PLB_type : in std_logic_vector(0 to 2);
      SPLB0_PLB_lockErr : in std_logic;
      SPLB0_PLB_wrPendReq : in std_logic;
      SPLB0_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB0_PLB_rdPendReq : in std_logic;
      SPLB0_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB0_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB0_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB0_PLB_rdBurst : in std_logic;
      SPLB0_PLB_wrBurst : in std_logic;
      SPLB0_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB0_Sl_addrAck : out std_logic;
      SPLB0_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB0_Sl_wait : out std_logic;
      SPLB0_Sl_rearbitrate : out std_logic;
      SPLB0_Sl_wrDAck : out std_logic;
      SPLB0_Sl_wrComp : out std_logic;
      SPLB0_Sl_wrBTerm : out std_logic;
      SPLB0_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB0_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB0_Sl_rdDAck : out std_logic;
      SPLB0_Sl_rdComp : out std_logic;
      SPLB0_Sl_rdBTerm : out std_logic;
      SPLB0_Sl_MBusy : out std_logic_vector(0 to 2);
      SPLB0_Sl_MRdErr : out std_logic_vector(0 to 2);
      SPLB0_Sl_MWrErr : out std_logic_vector(0 to 2);
      SPLB0_Sl_MIRQ : out std_logic_vector(0 to 2);
      SDMA0_Clk : in std_logic;
      SDMA0_Rx_IntOut : out std_logic;
      SDMA0_Tx_IntOut : out std_logic;
      SDMA0_RstOut : out std_logic;
      SDMA0_TX_D : out std_logic_vector(0 to 31);
      SDMA0_TX_Rem : out std_logic_vector(0 to 3);
      SDMA0_TX_SOF : out std_logic;
      SDMA0_TX_EOF : out std_logic;
      SDMA0_TX_SOP : out std_logic;
      SDMA0_TX_EOP : out std_logic;
      SDMA0_TX_Src_Rdy : out std_logic;
      SDMA0_TX_Dst_Rdy : in std_logic;
      SDMA0_RX_D : in std_logic_vector(0 to 31);
      SDMA0_RX_Rem : in std_logic_vector(0 to 3);
      SDMA0_RX_SOF : in std_logic;
      SDMA0_RX_EOF : in std_logic;
      SDMA0_RX_SOP : in std_logic;
      SDMA0_RX_EOP : in std_logic;
      SDMA0_RX_Src_Rdy : in std_logic;
      SDMA0_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL0_Clk : in std_logic;
      SDMA_CTRL0_Rst : in std_logic;
      SDMA_CTRL0_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL0_PLB_PAValid : in std_logic;
      SDMA_CTRL0_PLB_SAValid : in std_logic;
      SDMA_CTRL0_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL0_PLB_RNW : in std_logic;
      SDMA_CTRL0_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL0_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL0_PLB_rdPrim : in std_logic;
      SDMA_CTRL0_PLB_wrPrim : in std_logic;
      SDMA_CTRL0_PLB_abort : in std_logic;
      SDMA_CTRL0_PLB_busLock : in std_logic;
      SDMA_CTRL0_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL0_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL0_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL0_PLB_lockErr : in std_logic;
      SDMA_CTRL0_PLB_wrPendReq : in std_logic;
      SDMA_CTRL0_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL0_PLB_rdPendReq : in std_logic;
      SDMA_CTRL0_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL0_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL0_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL0_PLB_rdBurst : in std_logic;
      SDMA_CTRL0_PLB_wrBurst : in std_logic;
      SDMA_CTRL0_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL0_Sl_addrAck : out std_logic;
      SDMA_CTRL0_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL0_Sl_wait : out std_logic;
      SDMA_CTRL0_Sl_rearbitrate : out std_logic;
      SDMA_CTRL0_Sl_wrDAck : out std_logic;
      SDMA_CTRL0_Sl_wrComp : out std_logic;
      SDMA_CTRL0_Sl_wrBTerm : out std_logic;
      SDMA_CTRL0_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL0_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL0_Sl_rdDAck : out std_logic;
      SDMA_CTRL0_Sl_rdComp : out std_logic;
      SDMA_CTRL0_Sl_rdBTerm : out std_logic;
      SDMA_CTRL0_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL0_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL0_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL0_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM0_Addr : in std_logic_vector(31 downto 0);
      PIM0_AddrReq : in std_logic;
      PIM0_AddrAck : out std_logic;
      PIM0_RNW : in std_logic;
      PIM0_Size : in std_logic_vector(3 downto 0);
      PIM0_RdModWr : in std_logic;
      PIM0_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM0_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM0_WrFIFO_Push : in std_logic;
      PIM0_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM0_RdFIFO_Pop : in std_logic;
      PIM0_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM0_WrFIFO_Empty : out std_logic;
      PIM0_WrFIFO_AlmostFull : out std_logic;
      PIM0_WrFIFO_Flush : in std_logic;
      PIM0_RdFIFO_Empty : out std_logic;
      PIM0_RdFIFO_Flush : in std_logic;
      PIM0_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM0_InitDone : out std_logic;
      PPC440MC0_MIMCReadNotWrite : in std_logic;
      PPC440MC0_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC0_MIMCAddressValid : in std_logic;
      PPC440MC0_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC0_MIMCWriteDataValid : in std_logic;
      PPC440MC0_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC0_MIMCBankConflict : in std_logic;
      PPC440MC0_MIMCRowConflict : in std_logic;
      PPC440MC0_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC0_MCMIReadDataValid : out std_logic;
      PPC440MC0_MCMIReadDataErr : out std_logic;
      PPC440MC0_MCMIAddrReadyToAccept : out std_logic;
      VFBC0_Cmd_Clk : in std_logic;
      VFBC0_Cmd_Reset : in std_logic;
      VFBC0_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC0_Cmd_Write : in std_logic;
      VFBC0_Cmd_End : in std_logic;
      VFBC0_Cmd_Full : out std_logic;
      VFBC0_Cmd_Almost_Full : out std_logic;
      VFBC0_Cmd_Idle : out std_logic;
      VFBC0_Wd_Clk : in std_logic;
      VFBC0_Wd_Reset : in std_logic;
      VFBC0_Wd_Write : in std_logic;
      VFBC0_Wd_End_Burst : in std_logic;
      VFBC0_Wd_Flush : in std_logic;
      VFBC0_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC0_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC0_Wd_Full : out std_logic;
      VFBC0_Wd_Almost_Full : out std_logic;
      VFBC0_Rd_Clk : in std_logic;
      VFBC0_Rd_Reset : in std_logic;
      VFBC0_Rd_Read : in std_logic;
      VFBC0_Rd_End_Burst : in std_logic;
      VFBC0_Rd_Flush : in std_logic;
      VFBC0_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC0_Rd_Empty : out std_logic;
      VFBC0_Rd_Almost_Empty : out std_logic;
      MCB0_cmd_clk : in std_logic;
      MCB0_cmd_en : in std_logic;
      MCB0_cmd_instr : in std_logic_vector(2 downto 0);
      MCB0_cmd_bl : in std_logic_vector(5 downto 0);
      MCB0_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB0_cmd_empty : out std_logic;
      MCB0_cmd_full : out std_logic;
      MCB0_wr_clk : in std_logic;
      MCB0_wr_en : in std_logic;
      MCB0_wr_mask : in std_logic_vector(7 downto 0);
      MCB0_wr_data : in std_logic_vector(63 downto 0);
      MCB0_wr_full : out std_logic;
      MCB0_wr_empty : out std_logic;
      MCB0_wr_count : out std_logic_vector(6 downto 0);
      MCB0_wr_underrun : out std_logic;
      MCB0_wr_error : out std_logic;
      MCB0_rd_clk : in std_logic;
      MCB0_rd_en : in std_logic;
      MCB0_rd_data : out std_logic_vector(63 downto 0);
      MCB0_rd_full : out std_logic;
      MCB0_rd_empty : out std_logic;
      MCB0_rd_count : out std_logic_vector(6 downto 0);
      MCB0_rd_overflow : out std_logic;
      MCB0_rd_error : out std_logic;
      FSL1_M_Clk : in std_logic;
      FSL1_M_Write : in std_logic;
      FSL1_M_Data : in std_logic_vector(0 to 31);
      FSL1_M_Control : in std_logic;
      FSL1_M_Full : out std_logic;
      FSL1_S_Clk : in std_logic;
      FSL1_S_Read : in std_logic;
      FSL1_S_Data : out std_logic_vector(0 to 31);
      FSL1_S_Control : out std_logic;
      FSL1_S_Exists : out std_logic;
      FSL1_B_M_Clk : in std_logic;
      FSL1_B_M_Write : in std_logic;
      FSL1_B_M_Data : in std_logic_vector(0 to 31);
      FSL1_B_M_Control : in std_logic;
      FSL1_B_M_Full : out std_logic;
      FSL1_B_S_Clk : in std_logic;
      FSL1_B_S_Read : in std_logic;
      FSL1_B_S_Data : out std_logic_vector(0 to 31);
      FSL1_B_S_Control : out std_logic;
      FSL1_B_S_Exists : out std_logic;
      SPLB1_Clk : in std_logic;
      SPLB1_Rst : in std_logic;
      SPLB1_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB1_PLB_PAValid : in std_logic;
      SPLB1_PLB_SAValid : in std_logic;
      SPLB1_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB1_PLB_RNW : in std_logic;
      SPLB1_PLB_BE : in std_logic_vector(0 to 7);
      SPLB1_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB1_PLB_rdPrim : in std_logic;
      SPLB1_PLB_wrPrim : in std_logic;
      SPLB1_PLB_abort : in std_logic;
      SPLB1_PLB_busLock : in std_logic;
      SPLB1_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB1_PLB_size : in std_logic_vector(0 to 3);
      SPLB1_PLB_type : in std_logic_vector(0 to 2);
      SPLB1_PLB_lockErr : in std_logic;
      SPLB1_PLB_wrPendReq : in std_logic;
      SPLB1_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB1_PLB_rdPendReq : in std_logic;
      SPLB1_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB1_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB1_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB1_PLB_rdBurst : in std_logic;
      SPLB1_PLB_wrBurst : in std_logic;
      SPLB1_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB1_Sl_addrAck : out std_logic;
      SPLB1_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB1_Sl_wait : out std_logic;
      SPLB1_Sl_rearbitrate : out std_logic;
      SPLB1_Sl_wrDAck : out std_logic;
      SPLB1_Sl_wrComp : out std_logic;
      SPLB1_Sl_wrBTerm : out std_logic;
      SPLB1_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB1_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB1_Sl_rdDAck : out std_logic;
      SPLB1_Sl_rdComp : out std_logic;
      SPLB1_Sl_rdBTerm : out std_logic;
      SPLB1_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB1_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB1_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB1_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA1_Clk : in std_logic;
      SDMA1_Rx_IntOut : out std_logic;
      SDMA1_Tx_IntOut : out std_logic;
      SDMA1_RstOut : out std_logic;
      SDMA1_TX_D : out std_logic_vector(0 to 31);
      SDMA1_TX_Rem : out std_logic_vector(0 to 3);
      SDMA1_TX_SOF : out std_logic;
      SDMA1_TX_EOF : out std_logic;
      SDMA1_TX_SOP : out std_logic;
      SDMA1_TX_EOP : out std_logic;
      SDMA1_TX_Src_Rdy : out std_logic;
      SDMA1_TX_Dst_Rdy : in std_logic;
      SDMA1_RX_D : in std_logic_vector(0 to 31);
      SDMA1_RX_Rem : in std_logic_vector(0 to 3);
      SDMA1_RX_SOF : in std_logic;
      SDMA1_RX_EOF : in std_logic;
      SDMA1_RX_SOP : in std_logic;
      SDMA1_RX_EOP : in std_logic;
      SDMA1_RX_Src_Rdy : in std_logic;
      SDMA1_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL1_Clk : in std_logic;
      SDMA_CTRL1_Rst : in std_logic;
      SDMA_CTRL1_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL1_PLB_PAValid : in std_logic;
      SDMA_CTRL1_PLB_SAValid : in std_logic;
      SDMA_CTRL1_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL1_PLB_RNW : in std_logic;
      SDMA_CTRL1_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL1_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL1_PLB_rdPrim : in std_logic;
      SDMA_CTRL1_PLB_wrPrim : in std_logic;
      SDMA_CTRL1_PLB_abort : in std_logic;
      SDMA_CTRL1_PLB_busLock : in std_logic;
      SDMA_CTRL1_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL1_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL1_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL1_PLB_lockErr : in std_logic;
      SDMA_CTRL1_PLB_wrPendReq : in std_logic;
      SDMA_CTRL1_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL1_PLB_rdPendReq : in std_logic;
      SDMA_CTRL1_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL1_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL1_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL1_PLB_rdBurst : in std_logic;
      SDMA_CTRL1_PLB_wrBurst : in std_logic;
      SDMA_CTRL1_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL1_Sl_addrAck : out std_logic;
      SDMA_CTRL1_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL1_Sl_wait : out std_logic;
      SDMA_CTRL1_Sl_rearbitrate : out std_logic;
      SDMA_CTRL1_Sl_wrDAck : out std_logic;
      SDMA_CTRL1_Sl_wrComp : out std_logic;
      SDMA_CTRL1_Sl_wrBTerm : out std_logic;
      SDMA_CTRL1_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL1_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL1_Sl_rdDAck : out std_logic;
      SDMA_CTRL1_Sl_rdComp : out std_logic;
      SDMA_CTRL1_Sl_rdBTerm : out std_logic;
      SDMA_CTRL1_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL1_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL1_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL1_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM1_Addr : in std_logic_vector(31 downto 0);
      PIM1_AddrReq : in std_logic;
      PIM1_AddrAck : out std_logic;
      PIM1_RNW : in std_logic;
      PIM1_Size : in std_logic_vector(3 downto 0);
      PIM1_RdModWr : in std_logic;
      PIM1_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM1_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM1_WrFIFO_Push : in std_logic;
      PIM1_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM1_RdFIFO_Pop : in std_logic;
      PIM1_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM1_WrFIFO_Empty : out std_logic;
      PIM1_WrFIFO_AlmostFull : out std_logic;
      PIM1_WrFIFO_Flush : in std_logic;
      PIM1_RdFIFO_Empty : out std_logic;
      PIM1_RdFIFO_Flush : in std_logic;
      PIM1_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM1_InitDone : out std_logic;
      PPC440MC1_MIMCReadNotWrite : in std_logic;
      PPC440MC1_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC1_MIMCAddressValid : in std_logic;
      PPC440MC1_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC1_MIMCWriteDataValid : in std_logic;
      PPC440MC1_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC1_MIMCBankConflict : in std_logic;
      PPC440MC1_MIMCRowConflict : in std_logic;
      PPC440MC1_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC1_MCMIReadDataValid : out std_logic;
      PPC440MC1_MCMIReadDataErr : out std_logic;
      PPC440MC1_MCMIAddrReadyToAccept : out std_logic;
      VFBC1_Cmd_Clk : in std_logic;
      VFBC1_Cmd_Reset : in std_logic;
      VFBC1_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC1_Cmd_Write : in std_logic;
      VFBC1_Cmd_End : in std_logic;
      VFBC1_Cmd_Full : out std_logic;
      VFBC1_Cmd_Almost_Full : out std_logic;
      VFBC1_Cmd_Idle : out std_logic;
      VFBC1_Wd_Clk : in std_logic;
      VFBC1_Wd_Reset : in std_logic;
      VFBC1_Wd_Write : in std_logic;
      VFBC1_Wd_End_Burst : in std_logic;
      VFBC1_Wd_Flush : in std_logic;
      VFBC1_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC1_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC1_Wd_Full : out std_logic;
      VFBC1_Wd_Almost_Full : out std_logic;
      VFBC1_Rd_Clk : in std_logic;
      VFBC1_Rd_Reset : in std_logic;
      VFBC1_Rd_Read : in std_logic;
      VFBC1_Rd_End_Burst : in std_logic;
      VFBC1_Rd_Flush : in std_logic;
      VFBC1_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC1_Rd_Empty : out std_logic;
      VFBC1_Rd_Almost_Empty : out std_logic;
      MCB1_cmd_clk : in std_logic;
      MCB1_cmd_en : in std_logic;
      MCB1_cmd_instr : in std_logic_vector(2 downto 0);
      MCB1_cmd_bl : in std_logic_vector(5 downto 0);
      MCB1_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB1_cmd_empty : out std_logic;
      MCB1_cmd_full : out std_logic;
      MCB1_wr_clk : in std_logic;
      MCB1_wr_en : in std_logic;
      MCB1_wr_mask : in std_logic_vector(7 downto 0);
      MCB1_wr_data : in std_logic_vector(63 downto 0);
      MCB1_wr_full : out std_logic;
      MCB1_wr_empty : out std_logic;
      MCB1_wr_count : out std_logic_vector(6 downto 0);
      MCB1_wr_underrun : out std_logic;
      MCB1_wr_error : out std_logic;
      MCB1_rd_clk : in std_logic;
      MCB1_rd_en : in std_logic;
      MCB1_rd_data : out std_logic_vector(63 downto 0);
      MCB1_rd_full : out std_logic;
      MCB1_rd_empty : out std_logic;
      MCB1_rd_count : out std_logic_vector(6 downto 0);
      MCB1_rd_overflow : out std_logic;
      MCB1_rd_error : out std_logic;
      FSL2_M_Clk : in std_logic;
      FSL2_M_Write : in std_logic;
      FSL2_M_Data : in std_logic_vector(0 to 31);
      FSL2_M_Control : in std_logic;
      FSL2_M_Full : out std_logic;
      FSL2_S_Clk : in std_logic;
      FSL2_S_Read : in std_logic;
      FSL2_S_Data : out std_logic_vector(0 to 31);
      FSL2_S_Control : out std_logic;
      FSL2_S_Exists : out std_logic;
      FSL2_B_M_Clk : in std_logic;
      FSL2_B_M_Write : in std_logic;
      FSL2_B_M_Data : in std_logic_vector(0 to 31);
      FSL2_B_M_Control : in std_logic;
      FSL2_B_M_Full : out std_logic;
      FSL2_B_S_Clk : in std_logic;
      FSL2_B_S_Read : in std_logic;
      FSL2_B_S_Data : out std_logic_vector(0 to 31);
      FSL2_B_S_Control : out std_logic;
      FSL2_B_S_Exists : out std_logic;
      SPLB2_Clk : in std_logic;
      SPLB2_Rst : in std_logic;
      SPLB2_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB2_PLB_PAValid : in std_logic;
      SPLB2_PLB_SAValid : in std_logic;
      SPLB2_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB2_PLB_RNW : in std_logic;
      SPLB2_PLB_BE : in std_logic_vector(0 to 7);
      SPLB2_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB2_PLB_rdPrim : in std_logic;
      SPLB2_PLB_wrPrim : in std_logic;
      SPLB2_PLB_abort : in std_logic;
      SPLB2_PLB_busLock : in std_logic;
      SPLB2_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB2_PLB_size : in std_logic_vector(0 to 3);
      SPLB2_PLB_type : in std_logic_vector(0 to 2);
      SPLB2_PLB_lockErr : in std_logic;
      SPLB2_PLB_wrPendReq : in std_logic;
      SPLB2_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB2_PLB_rdPendReq : in std_logic;
      SPLB2_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB2_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB2_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB2_PLB_rdBurst : in std_logic;
      SPLB2_PLB_wrBurst : in std_logic;
      SPLB2_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB2_Sl_addrAck : out std_logic;
      SPLB2_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB2_Sl_wait : out std_logic;
      SPLB2_Sl_rearbitrate : out std_logic;
      SPLB2_Sl_wrDAck : out std_logic;
      SPLB2_Sl_wrComp : out std_logic;
      SPLB2_Sl_wrBTerm : out std_logic;
      SPLB2_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB2_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB2_Sl_rdDAck : out std_logic;
      SPLB2_Sl_rdComp : out std_logic;
      SPLB2_Sl_rdBTerm : out std_logic;
      SPLB2_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB2_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB2_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB2_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA2_Clk : in std_logic;
      SDMA2_Rx_IntOut : out std_logic;
      SDMA2_Tx_IntOut : out std_logic;
      SDMA2_RstOut : out std_logic;
      SDMA2_TX_D : out std_logic_vector(0 to 31);
      SDMA2_TX_Rem : out std_logic_vector(0 to 3);
      SDMA2_TX_SOF : out std_logic;
      SDMA2_TX_EOF : out std_logic;
      SDMA2_TX_SOP : out std_logic;
      SDMA2_TX_EOP : out std_logic;
      SDMA2_TX_Src_Rdy : out std_logic;
      SDMA2_TX_Dst_Rdy : in std_logic;
      SDMA2_RX_D : in std_logic_vector(0 to 31);
      SDMA2_RX_Rem : in std_logic_vector(0 to 3);
      SDMA2_RX_SOF : in std_logic;
      SDMA2_RX_EOF : in std_logic;
      SDMA2_RX_SOP : in std_logic;
      SDMA2_RX_EOP : in std_logic;
      SDMA2_RX_Src_Rdy : in std_logic;
      SDMA2_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL2_Clk : in std_logic;
      SDMA_CTRL2_Rst : in std_logic;
      SDMA_CTRL2_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL2_PLB_PAValid : in std_logic;
      SDMA_CTRL2_PLB_SAValid : in std_logic;
      SDMA_CTRL2_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL2_PLB_RNW : in std_logic;
      SDMA_CTRL2_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL2_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL2_PLB_rdPrim : in std_logic;
      SDMA_CTRL2_PLB_wrPrim : in std_logic;
      SDMA_CTRL2_PLB_abort : in std_logic;
      SDMA_CTRL2_PLB_busLock : in std_logic;
      SDMA_CTRL2_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL2_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL2_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL2_PLB_lockErr : in std_logic;
      SDMA_CTRL2_PLB_wrPendReq : in std_logic;
      SDMA_CTRL2_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL2_PLB_rdPendReq : in std_logic;
      SDMA_CTRL2_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL2_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL2_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL2_PLB_rdBurst : in std_logic;
      SDMA_CTRL2_PLB_wrBurst : in std_logic;
      SDMA_CTRL2_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL2_Sl_addrAck : out std_logic;
      SDMA_CTRL2_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL2_Sl_wait : out std_logic;
      SDMA_CTRL2_Sl_rearbitrate : out std_logic;
      SDMA_CTRL2_Sl_wrDAck : out std_logic;
      SDMA_CTRL2_Sl_wrComp : out std_logic;
      SDMA_CTRL2_Sl_wrBTerm : out std_logic;
      SDMA_CTRL2_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL2_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL2_Sl_rdDAck : out std_logic;
      SDMA_CTRL2_Sl_rdComp : out std_logic;
      SDMA_CTRL2_Sl_rdBTerm : out std_logic;
      SDMA_CTRL2_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL2_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL2_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL2_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM2_Addr : in std_logic_vector(31 downto 0);
      PIM2_AddrReq : in std_logic;
      PIM2_AddrAck : out std_logic;
      PIM2_RNW : in std_logic;
      PIM2_Size : in std_logic_vector(3 downto 0);
      PIM2_RdModWr : in std_logic;
      PIM2_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM2_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM2_WrFIFO_Push : in std_logic;
      PIM2_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM2_RdFIFO_Pop : in std_logic;
      PIM2_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM2_WrFIFO_Empty : out std_logic;
      PIM2_WrFIFO_AlmostFull : out std_logic;
      PIM2_WrFIFO_Flush : in std_logic;
      PIM2_RdFIFO_Empty : out std_logic;
      PIM2_RdFIFO_Flush : in std_logic;
      PIM2_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM2_InitDone : out std_logic;
      PPC440MC2_MIMCReadNotWrite : in std_logic;
      PPC440MC2_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC2_MIMCAddressValid : in std_logic;
      PPC440MC2_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC2_MIMCWriteDataValid : in std_logic;
      PPC440MC2_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC2_MIMCBankConflict : in std_logic;
      PPC440MC2_MIMCRowConflict : in std_logic;
      PPC440MC2_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC2_MCMIReadDataValid : out std_logic;
      PPC440MC2_MCMIReadDataErr : out std_logic;
      PPC440MC2_MCMIAddrReadyToAccept : out std_logic;
      VFBC2_Cmd_Clk : in std_logic;
      VFBC2_Cmd_Reset : in std_logic;
      VFBC2_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC2_Cmd_Write : in std_logic;
      VFBC2_Cmd_End : in std_logic;
      VFBC2_Cmd_Full : out std_logic;
      VFBC2_Cmd_Almost_Full : out std_logic;
      VFBC2_Cmd_Idle : out std_logic;
      VFBC2_Wd_Clk : in std_logic;
      VFBC2_Wd_Reset : in std_logic;
      VFBC2_Wd_Write : in std_logic;
      VFBC2_Wd_End_Burst : in std_logic;
      VFBC2_Wd_Flush : in std_logic;
      VFBC2_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC2_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC2_Wd_Full : out std_logic;
      VFBC2_Wd_Almost_Full : out std_logic;
      VFBC2_Rd_Clk : in std_logic;
      VFBC2_Rd_Reset : in std_logic;
      VFBC2_Rd_Read : in std_logic;
      VFBC2_Rd_End_Burst : in std_logic;
      VFBC2_Rd_Flush : in std_logic;
      VFBC2_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC2_Rd_Empty : out std_logic;
      VFBC2_Rd_Almost_Empty : out std_logic;
      MCB2_cmd_clk : in std_logic;
      MCB2_cmd_en : in std_logic;
      MCB2_cmd_instr : in std_logic_vector(2 downto 0);
      MCB2_cmd_bl : in std_logic_vector(5 downto 0);
      MCB2_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB2_cmd_empty : out std_logic;
      MCB2_cmd_full : out std_logic;
      MCB2_wr_clk : in std_logic;
      MCB2_wr_en : in std_logic;
      MCB2_wr_mask : in std_logic_vector(7 downto 0);
      MCB2_wr_data : in std_logic_vector(63 downto 0);
      MCB2_wr_full : out std_logic;
      MCB2_wr_empty : out std_logic;
      MCB2_wr_count : out std_logic_vector(6 downto 0);
      MCB2_wr_underrun : out std_logic;
      MCB2_wr_error : out std_logic;
      MCB2_rd_clk : in std_logic;
      MCB2_rd_en : in std_logic;
      MCB2_rd_data : out std_logic_vector(63 downto 0);
      MCB2_rd_full : out std_logic;
      MCB2_rd_empty : out std_logic;
      MCB2_rd_count : out std_logic_vector(6 downto 0);
      MCB2_rd_overflow : out std_logic;
      MCB2_rd_error : out std_logic;
      FSL3_M_Clk : in std_logic;
      FSL3_M_Write : in std_logic;
      FSL3_M_Data : in std_logic_vector(0 to 31);
      FSL3_M_Control : in std_logic;
      FSL3_M_Full : out std_logic;
      FSL3_S_Clk : in std_logic;
      FSL3_S_Read : in std_logic;
      FSL3_S_Data : out std_logic_vector(0 to 31);
      FSL3_S_Control : out std_logic;
      FSL3_S_Exists : out std_logic;
      FSL3_B_M_Clk : in std_logic;
      FSL3_B_M_Write : in std_logic;
      FSL3_B_M_Data : in std_logic_vector(0 to 31);
      FSL3_B_M_Control : in std_logic;
      FSL3_B_M_Full : out std_logic;
      FSL3_B_S_Clk : in std_logic;
      FSL3_B_S_Read : in std_logic;
      FSL3_B_S_Data : out std_logic_vector(0 to 31);
      FSL3_B_S_Control : out std_logic;
      FSL3_B_S_Exists : out std_logic;
      SPLB3_Clk : in std_logic;
      SPLB3_Rst : in std_logic;
      SPLB3_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB3_PLB_PAValid : in std_logic;
      SPLB3_PLB_SAValid : in std_logic;
      SPLB3_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB3_PLB_RNW : in std_logic;
      SPLB3_PLB_BE : in std_logic_vector(0 to 7);
      SPLB3_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB3_PLB_rdPrim : in std_logic;
      SPLB3_PLB_wrPrim : in std_logic;
      SPLB3_PLB_abort : in std_logic;
      SPLB3_PLB_busLock : in std_logic;
      SPLB3_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB3_PLB_size : in std_logic_vector(0 to 3);
      SPLB3_PLB_type : in std_logic_vector(0 to 2);
      SPLB3_PLB_lockErr : in std_logic;
      SPLB3_PLB_wrPendReq : in std_logic;
      SPLB3_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB3_PLB_rdPendReq : in std_logic;
      SPLB3_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB3_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB3_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB3_PLB_rdBurst : in std_logic;
      SPLB3_PLB_wrBurst : in std_logic;
      SPLB3_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB3_Sl_addrAck : out std_logic;
      SPLB3_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB3_Sl_wait : out std_logic;
      SPLB3_Sl_rearbitrate : out std_logic;
      SPLB3_Sl_wrDAck : out std_logic;
      SPLB3_Sl_wrComp : out std_logic;
      SPLB3_Sl_wrBTerm : out std_logic;
      SPLB3_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB3_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB3_Sl_rdDAck : out std_logic;
      SPLB3_Sl_rdComp : out std_logic;
      SPLB3_Sl_rdBTerm : out std_logic;
      SPLB3_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB3_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB3_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB3_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA3_Clk : in std_logic;
      SDMA3_Rx_IntOut : out std_logic;
      SDMA3_Tx_IntOut : out std_logic;
      SDMA3_RstOut : out std_logic;
      SDMA3_TX_D : out std_logic_vector(0 to 31);
      SDMA3_TX_Rem : out std_logic_vector(0 to 3);
      SDMA3_TX_SOF : out std_logic;
      SDMA3_TX_EOF : out std_logic;
      SDMA3_TX_SOP : out std_logic;
      SDMA3_TX_EOP : out std_logic;
      SDMA3_TX_Src_Rdy : out std_logic;
      SDMA3_TX_Dst_Rdy : in std_logic;
      SDMA3_RX_D : in std_logic_vector(0 to 31);
      SDMA3_RX_Rem : in std_logic_vector(0 to 3);
      SDMA3_RX_SOF : in std_logic;
      SDMA3_RX_EOF : in std_logic;
      SDMA3_RX_SOP : in std_logic;
      SDMA3_RX_EOP : in std_logic;
      SDMA3_RX_Src_Rdy : in std_logic;
      SDMA3_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL3_Clk : in std_logic;
      SDMA_CTRL3_Rst : in std_logic;
      SDMA_CTRL3_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL3_PLB_PAValid : in std_logic;
      SDMA_CTRL3_PLB_SAValid : in std_logic;
      SDMA_CTRL3_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL3_PLB_RNW : in std_logic;
      SDMA_CTRL3_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL3_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL3_PLB_rdPrim : in std_logic;
      SDMA_CTRL3_PLB_wrPrim : in std_logic;
      SDMA_CTRL3_PLB_abort : in std_logic;
      SDMA_CTRL3_PLB_busLock : in std_logic;
      SDMA_CTRL3_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL3_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL3_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL3_PLB_lockErr : in std_logic;
      SDMA_CTRL3_PLB_wrPendReq : in std_logic;
      SDMA_CTRL3_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL3_PLB_rdPendReq : in std_logic;
      SDMA_CTRL3_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL3_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL3_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL3_PLB_rdBurst : in std_logic;
      SDMA_CTRL3_PLB_wrBurst : in std_logic;
      SDMA_CTRL3_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL3_Sl_addrAck : out std_logic;
      SDMA_CTRL3_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL3_Sl_wait : out std_logic;
      SDMA_CTRL3_Sl_rearbitrate : out std_logic;
      SDMA_CTRL3_Sl_wrDAck : out std_logic;
      SDMA_CTRL3_Sl_wrComp : out std_logic;
      SDMA_CTRL3_Sl_wrBTerm : out std_logic;
      SDMA_CTRL3_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL3_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL3_Sl_rdDAck : out std_logic;
      SDMA_CTRL3_Sl_rdComp : out std_logic;
      SDMA_CTRL3_Sl_rdBTerm : out std_logic;
      SDMA_CTRL3_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL3_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL3_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL3_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM3_Addr : in std_logic_vector(31 downto 0);
      PIM3_AddrReq : in std_logic;
      PIM3_AddrAck : out std_logic;
      PIM3_RNW : in std_logic;
      PIM3_Size : in std_logic_vector(3 downto 0);
      PIM3_RdModWr : in std_logic;
      PIM3_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM3_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM3_WrFIFO_Push : in std_logic;
      PIM3_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM3_RdFIFO_Pop : in std_logic;
      PIM3_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM3_WrFIFO_Empty : out std_logic;
      PIM3_WrFIFO_AlmostFull : out std_logic;
      PIM3_WrFIFO_Flush : in std_logic;
      PIM3_RdFIFO_Empty : out std_logic;
      PIM3_RdFIFO_Flush : in std_logic;
      PIM3_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM3_InitDone : out std_logic;
      PPC440MC3_MIMCReadNotWrite : in std_logic;
      PPC440MC3_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC3_MIMCAddressValid : in std_logic;
      PPC440MC3_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC3_MIMCWriteDataValid : in std_logic;
      PPC440MC3_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC3_MIMCBankConflict : in std_logic;
      PPC440MC3_MIMCRowConflict : in std_logic;
      PPC440MC3_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC3_MCMIReadDataValid : out std_logic;
      PPC440MC3_MCMIReadDataErr : out std_logic;
      PPC440MC3_MCMIAddrReadyToAccept : out std_logic;
      VFBC3_Cmd_Clk : in std_logic;
      VFBC3_Cmd_Reset : in std_logic;
      VFBC3_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC3_Cmd_Write : in std_logic;
      VFBC3_Cmd_End : in std_logic;
      VFBC3_Cmd_Full : out std_logic;
      VFBC3_Cmd_Almost_Full : out std_logic;
      VFBC3_Cmd_Idle : out std_logic;
      VFBC3_Wd_Clk : in std_logic;
      VFBC3_Wd_Reset : in std_logic;
      VFBC3_Wd_Write : in std_logic;
      VFBC3_Wd_End_Burst : in std_logic;
      VFBC3_Wd_Flush : in std_logic;
      VFBC3_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC3_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC3_Wd_Full : out std_logic;
      VFBC3_Wd_Almost_Full : out std_logic;
      VFBC3_Rd_Clk : in std_logic;
      VFBC3_Rd_Reset : in std_logic;
      VFBC3_Rd_Read : in std_logic;
      VFBC3_Rd_End_Burst : in std_logic;
      VFBC3_Rd_Flush : in std_logic;
      VFBC3_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC3_Rd_Empty : out std_logic;
      VFBC3_Rd_Almost_Empty : out std_logic;
      MCB3_cmd_clk : in std_logic;
      MCB3_cmd_en : in std_logic;
      MCB3_cmd_instr : in std_logic_vector(2 downto 0);
      MCB3_cmd_bl : in std_logic_vector(5 downto 0);
      MCB3_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB3_cmd_empty : out std_logic;
      MCB3_cmd_full : out std_logic;
      MCB3_wr_clk : in std_logic;
      MCB3_wr_en : in std_logic;
      MCB3_wr_mask : in std_logic_vector(7 downto 0);
      MCB3_wr_data : in std_logic_vector(63 downto 0);
      MCB3_wr_full : out std_logic;
      MCB3_wr_empty : out std_logic;
      MCB3_wr_count : out std_logic_vector(6 downto 0);
      MCB3_wr_underrun : out std_logic;
      MCB3_wr_error : out std_logic;
      MCB3_rd_clk : in std_logic;
      MCB3_rd_en : in std_logic;
      MCB3_rd_data : out std_logic_vector(63 downto 0);
      MCB3_rd_full : out std_logic;
      MCB3_rd_empty : out std_logic;
      MCB3_rd_count : out std_logic_vector(6 downto 0);
      MCB3_rd_overflow : out std_logic;
      MCB3_rd_error : out std_logic;
      FSL4_M_Clk : in std_logic;
      FSL4_M_Write : in std_logic;
      FSL4_M_Data : in std_logic_vector(0 to 31);
      FSL4_M_Control : in std_logic;
      FSL4_M_Full : out std_logic;
      FSL4_S_Clk : in std_logic;
      FSL4_S_Read : in std_logic;
      FSL4_S_Data : out std_logic_vector(0 to 31);
      FSL4_S_Control : out std_logic;
      FSL4_S_Exists : out std_logic;
      FSL4_B_M_Clk : in std_logic;
      FSL4_B_M_Write : in std_logic;
      FSL4_B_M_Data : in std_logic_vector(0 to 31);
      FSL4_B_M_Control : in std_logic;
      FSL4_B_M_Full : out std_logic;
      FSL4_B_S_Clk : in std_logic;
      FSL4_B_S_Read : in std_logic;
      FSL4_B_S_Data : out std_logic_vector(0 to 31);
      FSL4_B_S_Control : out std_logic;
      FSL4_B_S_Exists : out std_logic;
      SPLB4_Clk : in std_logic;
      SPLB4_Rst : in std_logic;
      SPLB4_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB4_PLB_PAValid : in std_logic;
      SPLB4_PLB_SAValid : in std_logic;
      SPLB4_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB4_PLB_RNW : in std_logic;
      SPLB4_PLB_BE : in std_logic_vector(0 to 7);
      SPLB4_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB4_PLB_rdPrim : in std_logic;
      SPLB4_PLB_wrPrim : in std_logic;
      SPLB4_PLB_abort : in std_logic;
      SPLB4_PLB_busLock : in std_logic;
      SPLB4_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB4_PLB_size : in std_logic_vector(0 to 3);
      SPLB4_PLB_type : in std_logic_vector(0 to 2);
      SPLB4_PLB_lockErr : in std_logic;
      SPLB4_PLB_wrPendReq : in std_logic;
      SPLB4_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB4_PLB_rdPendReq : in std_logic;
      SPLB4_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB4_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB4_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB4_PLB_rdBurst : in std_logic;
      SPLB4_PLB_wrBurst : in std_logic;
      SPLB4_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB4_Sl_addrAck : out std_logic;
      SPLB4_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB4_Sl_wait : out std_logic;
      SPLB4_Sl_rearbitrate : out std_logic;
      SPLB4_Sl_wrDAck : out std_logic;
      SPLB4_Sl_wrComp : out std_logic;
      SPLB4_Sl_wrBTerm : out std_logic;
      SPLB4_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB4_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB4_Sl_rdDAck : out std_logic;
      SPLB4_Sl_rdComp : out std_logic;
      SPLB4_Sl_rdBTerm : out std_logic;
      SPLB4_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB4_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB4_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB4_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA4_Clk : in std_logic;
      SDMA4_Rx_IntOut : out std_logic;
      SDMA4_Tx_IntOut : out std_logic;
      SDMA4_RstOut : out std_logic;
      SDMA4_TX_D : out std_logic_vector(0 to 31);
      SDMA4_TX_Rem : out std_logic_vector(0 to 3);
      SDMA4_TX_SOF : out std_logic;
      SDMA4_TX_EOF : out std_logic;
      SDMA4_TX_SOP : out std_logic;
      SDMA4_TX_EOP : out std_logic;
      SDMA4_TX_Src_Rdy : out std_logic;
      SDMA4_TX_Dst_Rdy : in std_logic;
      SDMA4_RX_D : in std_logic_vector(0 to 31);
      SDMA4_RX_Rem : in std_logic_vector(0 to 3);
      SDMA4_RX_SOF : in std_logic;
      SDMA4_RX_EOF : in std_logic;
      SDMA4_RX_SOP : in std_logic;
      SDMA4_RX_EOP : in std_logic;
      SDMA4_RX_Src_Rdy : in std_logic;
      SDMA4_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL4_Clk : in std_logic;
      SDMA_CTRL4_Rst : in std_logic;
      SDMA_CTRL4_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL4_PLB_PAValid : in std_logic;
      SDMA_CTRL4_PLB_SAValid : in std_logic;
      SDMA_CTRL4_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL4_PLB_RNW : in std_logic;
      SDMA_CTRL4_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL4_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL4_PLB_rdPrim : in std_logic;
      SDMA_CTRL4_PLB_wrPrim : in std_logic;
      SDMA_CTRL4_PLB_abort : in std_logic;
      SDMA_CTRL4_PLB_busLock : in std_logic;
      SDMA_CTRL4_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL4_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL4_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL4_PLB_lockErr : in std_logic;
      SDMA_CTRL4_PLB_wrPendReq : in std_logic;
      SDMA_CTRL4_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL4_PLB_rdPendReq : in std_logic;
      SDMA_CTRL4_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL4_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL4_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL4_PLB_rdBurst : in std_logic;
      SDMA_CTRL4_PLB_wrBurst : in std_logic;
      SDMA_CTRL4_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL4_Sl_addrAck : out std_logic;
      SDMA_CTRL4_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL4_Sl_wait : out std_logic;
      SDMA_CTRL4_Sl_rearbitrate : out std_logic;
      SDMA_CTRL4_Sl_wrDAck : out std_logic;
      SDMA_CTRL4_Sl_wrComp : out std_logic;
      SDMA_CTRL4_Sl_wrBTerm : out std_logic;
      SDMA_CTRL4_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL4_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL4_Sl_rdDAck : out std_logic;
      SDMA_CTRL4_Sl_rdComp : out std_logic;
      SDMA_CTRL4_Sl_rdBTerm : out std_logic;
      SDMA_CTRL4_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL4_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL4_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL4_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM4_Addr : in std_logic_vector(31 downto 0);
      PIM4_AddrReq : in std_logic;
      PIM4_AddrAck : out std_logic;
      PIM4_RNW : in std_logic;
      PIM4_Size : in std_logic_vector(3 downto 0);
      PIM4_RdModWr : in std_logic;
      PIM4_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM4_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM4_WrFIFO_Push : in std_logic;
      PIM4_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM4_RdFIFO_Pop : in std_logic;
      PIM4_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM4_WrFIFO_Empty : out std_logic;
      PIM4_WrFIFO_AlmostFull : out std_logic;
      PIM4_WrFIFO_Flush : in std_logic;
      PIM4_RdFIFO_Empty : out std_logic;
      PIM4_RdFIFO_Flush : in std_logic;
      PIM4_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM4_InitDone : out std_logic;
      PPC440MC4_MIMCReadNotWrite : in std_logic;
      PPC440MC4_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC4_MIMCAddressValid : in std_logic;
      PPC440MC4_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC4_MIMCWriteDataValid : in std_logic;
      PPC440MC4_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC4_MIMCBankConflict : in std_logic;
      PPC440MC4_MIMCRowConflict : in std_logic;
      PPC440MC4_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC4_MCMIReadDataValid : out std_logic;
      PPC440MC4_MCMIReadDataErr : out std_logic;
      PPC440MC4_MCMIAddrReadyToAccept : out std_logic;
      VFBC4_Cmd_Clk : in std_logic;
      VFBC4_Cmd_Reset : in std_logic;
      VFBC4_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC4_Cmd_Write : in std_logic;
      VFBC4_Cmd_End : in std_logic;
      VFBC4_Cmd_Full : out std_logic;
      VFBC4_Cmd_Almost_Full : out std_logic;
      VFBC4_Cmd_Idle : out std_logic;
      VFBC4_Wd_Clk : in std_logic;
      VFBC4_Wd_Reset : in std_logic;
      VFBC4_Wd_Write : in std_logic;
      VFBC4_Wd_End_Burst : in std_logic;
      VFBC4_Wd_Flush : in std_logic;
      VFBC4_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC4_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC4_Wd_Full : out std_logic;
      VFBC4_Wd_Almost_Full : out std_logic;
      VFBC4_Rd_Clk : in std_logic;
      VFBC4_Rd_Reset : in std_logic;
      VFBC4_Rd_Read : in std_logic;
      VFBC4_Rd_End_Burst : in std_logic;
      VFBC4_Rd_Flush : in std_logic;
      VFBC4_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC4_Rd_Empty : out std_logic;
      VFBC4_Rd_Almost_Empty : out std_logic;
      MCB4_cmd_clk : in std_logic;
      MCB4_cmd_en : in std_logic;
      MCB4_cmd_instr : in std_logic_vector(2 downto 0);
      MCB4_cmd_bl : in std_logic_vector(5 downto 0);
      MCB4_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB4_cmd_empty : out std_logic;
      MCB4_cmd_full : out std_logic;
      MCB4_wr_clk : in std_logic;
      MCB4_wr_en : in std_logic;
      MCB4_wr_mask : in std_logic_vector(7 downto 0);
      MCB4_wr_data : in std_logic_vector(63 downto 0);
      MCB4_wr_full : out std_logic;
      MCB4_wr_empty : out std_logic;
      MCB4_wr_count : out std_logic_vector(6 downto 0);
      MCB4_wr_underrun : out std_logic;
      MCB4_wr_error : out std_logic;
      MCB4_rd_clk : in std_logic;
      MCB4_rd_en : in std_logic;
      MCB4_rd_data : out std_logic_vector(63 downto 0);
      MCB4_rd_full : out std_logic;
      MCB4_rd_empty : out std_logic;
      MCB4_rd_count : out std_logic_vector(6 downto 0);
      MCB4_rd_overflow : out std_logic;
      MCB4_rd_error : out std_logic;
      FSL5_M_Clk : in std_logic;
      FSL5_M_Write : in std_logic;
      FSL5_M_Data : in std_logic_vector(0 to 31);
      FSL5_M_Control : in std_logic;
      FSL5_M_Full : out std_logic;
      FSL5_S_Clk : in std_logic;
      FSL5_S_Read : in std_logic;
      FSL5_S_Data : out std_logic_vector(0 to 31);
      FSL5_S_Control : out std_logic;
      FSL5_S_Exists : out std_logic;
      FSL5_B_M_Clk : in std_logic;
      FSL5_B_M_Write : in std_logic;
      FSL5_B_M_Data : in std_logic_vector(0 to 31);
      FSL5_B_M_Control : in std_logic;
      FSL5_B_M_Full : out std_logic;
      FSL5_B_S_Clk : in std_logic;
      FSL5_B_S_Read : in std_logic;
      FSL5_B_S_Data : out std_logic_vector(0 to 31);
      FSL5_B_S_Control : out std_logic;
      FSL5_B_S_Exists : out std_logic;
      SPLB5_Clk : in std_logic;
      SPLB5_Rst : in std_logic;
      SPLB5_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB5_PLB_PAValid : in std_logic;
      SPLB5_PLB_SAValid : in std_logic;
      SPLB5_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB5_PLB_RNW : in std_logic;
      SPLB5_PLB_BE : in std_logic_vector(0 to 7);
      SPLB5_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB5_PLB_rdPrim : in std_logic;
      SPLB5_PLB_wrPrim : in std_logic;
      SPLB5_PLB_abort : in std_logic;
      SPLB5_PLB_busLock : in std_logic;
      SPLB5_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB5_PLB_size : in std_logic_vector(0 to 3);
      SPLB5_PLB_type : in std_logic_vector(0 to 2);
      SPLB5_PLB_lockErr : in std_logic;
      SPLB5_PLB_wrPendReq : in std_logic;
      SPLB5_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB5_PLB_rdPendReq : in std_logic;
      SPLB5_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB5_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB5_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB5_PLB_rdBurst : in std_logic;
      SPLB5_PLB_wrBurst : in std_logic;
      SPLB5_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB5_Sl_addrAck : out std_logic;
      SPLB5_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB5_Sl_wait : out std_logic;
      SPLB5_Sl_rearbitrate : out std_logic;
      SPLB5_Sl_wrDAck : out std_logic;
      SPLB5_Sl_wrComp : out std_logic;
      SPLB5_Sl_wrBTerm : out std_logic;
      SPLB5_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB5_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB5_Sl_rdDAck : out std_logic;
      SPLB5_Sl_rdComp : out std_logic;
      SPLB5_Sl_rdBTerm : out std_logic;
      SPLB5_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB5_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB5_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB5_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA5_Clk : in std_logic;
      SDMA5_Rx_IntOut : out std_logic;
      SDMA5_Tx_IntOut : out std_logic;
      SDMA5_RstOut : out std_logic;
      SDMA5_TX_D : out std_logic_vector(0 to 31);
      SDMA5_TX_Rem : out std_logic_vector(0 to 3);
      SDMA5_TX_SOF : out std_logic;
      SDMA5_TX_EOF : out std_logic;
      SDMA5_TX_SOP : out std_logic;
      SDMA5_TX_EOP : out std_logic;
      SDMA5_TX_Src_Rdy : out std_logic;
      SDMA5_TX_Dst_Rdy : in std_logic;
      SDMA5_RX_D : in std_logic_vector(0 to 31);
      SDMA5_RX_Rem : in std_logic_vector(0 to 3);
      SDMA5_RX_SOF : in std_logic;
      SDMA5_RX_EOF : in std_logic;
      SDMA5_RX_SOP : in std_logic;
      SDMA5_RX_EOP : in std_logic;
      SDMA5_RX_Src_Rdy : in std_logic;
      SDMA5_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL5_Clk : in std_logic;
      SDMA_CTRL5_Rst : in std_logic;
      SDMA_CTRL5_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL5_PLB_PAValid : in std_logic;
      SDMA_CTRL5_PLB_SAValid : in std_logic;
      SDMA_CTRL5_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL5_PLB_RNW : in std_logic;
      SDMA_CTRL5_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL5_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL5_PLB_rdPrim : in std_logic;
      SDMA_CTRL5_PLB_wrPrim : in std_logic;
      SDMA_CTRL5_PLB_abort : in std_logic;
      SDMA_CTRL5_PLB_busLock : in std_logic;
      SDMA_CTRL5_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL5_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL5_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL5_PLB_lockErr : in std_logic;
      SDMA_CTRL5_PLB_wrPendReq : in std_logic;
      SDMA_CTRL5_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL5_PLB_rdPendReq : in std_logic;
      SDMA_CTRL5_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL5_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL5_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL5_PLB_rdBurst : in std_logic;
      SDMA_CTRL5_PLB_wrBurst : in std_logic;
      SDMA_CTRL5_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL5_Sl_addrAck : out std_logic;
      SDMA_CTRL5_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL5_Sl_wait : out std_logic;
      SDMA_CTRL5_Sl_rearbitrate : out std_logic;
      SDMA_CTRL5_Sl_wrDAck : out std_logic;
      SDMA_CTRL5_Sl_wrComp : out std_logic;
      SDMA_CTRL5_Sl_wrBTerm : out std_logic;
      SDMA_CTRL5_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL5_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL5_Sl_rdDAck : out std_logic;
      SDMA_CTRL5_Sl_rdComp : out std_logic;
      SDMA_CTRL5_Sl_rdBTerm : out std_logic;
      SDMA_CTRL5_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL5_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL5_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL5_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM5_Addr : in std_logic_vector(31 downto 0);
      PIM5_AddrReq : in std_logic;
      PIM5_AddrAck : out std_logic;
      PIM5_RNW : in std_logic;
      PIM5_Size : in std_logic_vector(3 downto 0);
      PIM5_RdModWr : in std_logic;
      PIM5_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM5_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM5_WrFIFO_Push : in std_logic;
      PIM5_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM5_RdFIFO_Pop : in std_logic;
      PIM5_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM5_WrFIFO_Empty : out std_logic;
      PIM5_WrFIFO_AlmostFull : out std_logic;
      PIM5_WrFIFO_Flush : in std_logic;
      PIM5_RdFIFO_Empty : out std_logic;
      PIM5_RdFIFO_Flush : in std_logic;
      PIM5_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM5_InitDone : out std_logic;
      PPC440MC5_MIMCReadNotWrite : in std_logic;
      PPC440MC5_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC5_MIMCAddressValid : in std_logic;
      PPC440MC5_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC5_MIMCWriteDataValid : in std_logic;
      PPC440MC5_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC5_MIMCBankConflict : in std_logic;
      PPC440MC5_MIMCRowConflict : in std_logic;
      PPC440MC5_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC5_MCMIReadDataValid : out std_logic;
      PPC440MC5_MCMIReadDataErr : out std_logic;
      PPC440MC5_MCMIAddrReadyToAccept : out std_logic;
      VFBC5_Cmd_Clk : in std_logic;
      VFBC5_Cmd_Reset : in std_logic;
      VFBC5_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC5_Cmd_Write : in std_logic;
      VFBC5_Cmd_End : in std_logic;
      VFBC5_Cmd_Full : out std_logic;
      VFBC5_Cmd_Almost_Full : out std_logic;
      VFBC5_Cmd_Idle : out std_logic;
      VFBC5_Wd_Clk : in std_logic;
      VFBC5_Wd_Reset : in std_logic;
      VFBC5_Wd_Write : in std_logic;
      VFBC5_Wd_End_Burst : in std_logic;
      VFBC5_Wd_Flush : in std_logic;
      VFBC5_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC5_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC5_Wd_Full : out std_logic;
      VFBC5_Wd_Almost_Full : out std_logic;
      VFBC5_Rd_Clk : in std_logic;
      VFBC5_Rd_Reset : in std_logic;
      VFBC5_Rd_Read : in std_logic;
      VFBC5_Rd_End_Burst : in std_logic;
      VFBC5_Rd_Flush : in std_logic;
      VFBC5_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC5_Rd_Empty : out std_logic;
      VFBC5_Rd_Almost_Empty : out std_logic;
      MCB5_cmd_clk : in std_logic;
      MCB5_cmd_en : in std_logic;
      MCB5_cmd_instr : in std_logic_vector(2 downto 0);
      MCB5_cmd_bl : in std_logic_vector(5 downto 0);
      MCB5_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB5_cmd_empty : out std_logic;
      MCB5_cmd_full : out std_logic;
      MCB5_wr_clk : in std_logic;
      MCB5_wr_en : in std_logic;
      MCB5_wr_mask : in std_logic_vector(7 downto 0);
      MCB5_wr_data : in std_logic_vector(63 downto 0);
      MCB5_wr_full : out std_logic;
      MCB5_wr_empty : out std_logic;
      MCB5_wr_count : out std_logic_vector(6 downto 0);
      MCB5_wr_underrun : out std_logic;
      MCB5_wr_error : out std_logic;
      MCB5_rd_clk : in std_logic;
      MCB5_rd_en : in std_logic;
      MCB5_rd_data : out std_logic_vector(63 downto 0);
      MCB5_rd_full : out std_logic;
      MCB5_rd_empty : out std_logic;
      MCB5_rd_count : out std_logic_vector(6 downto 0);
      MCB5_rd_overflow : out std_logic;
      MCB5_rd_error : out std_logic;
      FSL6_M_Clk : in std_logic;
      FSL6_M_Write : in std_logic;
      FSL6_M_Data : in std_logic_vector(0 to 31);
      FSL6_M_Control : in std_logic;
      FSL6_M_Full : out std_logic;
      FSL6_S_Clk : in std_logic;
      FSL6_S_Read : in std_logic;
      FSL6_S_Data : out std_logic_vector(0 to 31);
      FSL6_S_Control : out std_logic;
      FSL6_S_Exists : out std_logic;
      FSL6_B_M_Clk : in std_logic;
      FSL6_B_M_Write : in std_logic;
      FSL6_B_M_Data : in std_logic_vector(0 to 31);
      FSL6_B_M_Control : in std_logic;
      FSL6_B_M_Full : out std_logic;
      FSL6_B_S_Clk : in std_logic;
      FSL6_B_S_Read : in std_logic;
      FSL6_B_S_Data : out std_logic_vector(0 to 31);
      FSL6_B_S_Control : out std_logic;
      FSL6_B_S_Exists : out std_logic;
      SPLB6_Clk : in std_logic;
      SPLB6_Rst : in std_logic;
      SPLB6_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB6_PLB_PAValid : in std_logic;
      SPLB6_PLB_SAValid : in std_logic;
      SPLB6_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB6_PLB_RNW : in std_logic;
      SPLB6_PLB_BE : in std_logic_vector(0 to 7);
      SPLB6_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB6_PLB_rdPrim : in std_logic;
      SPLB6_PLB_wrPrim : in std_logic;
      SPLB6_PLB_abort : in std_logic;
      SPLB6_PLB_busLock : in std_logic;
      SPLB6_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB6_PLB_size : in std_logic_vector(0 to 3);
      SPLB6_PLB_type : in std_logic_vector(0 to 2);
      SPLB6_PLB_lockErr : in std_logic;
      SPLB6_PLB_wrPendReq : in std_logic;
      SPLB6_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB6_PLB_rdPendReq : in std_logic;
      SPLB6_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB6_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB6_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB6_PLB_rdBurst : in std_logic;
      SPLB6_PLB_wrBurst : in std_logic;
      SPLB6_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB6_Sl_addrAck : out std_logic;
      SPLB6_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB6_Sl_wait : out std_logic;
      SPLB6_Sl_rearbitrate : out std_logic;
      SPLB6_Sl_wrDAck : out std_logic;
      SPLB6_Sl_wrComp : out std_logic;
      SPLB6_Sl_wrBTerm : out std_logic;
      SPLB6_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB6_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB6_Sl_rdDAck : out std_logic;
      SPLB6_Sl_rdComp : out std_logic;
      SPLB6_Sl_rdBTerm : out std_logic;
      SPLB6_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB6_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB6_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB6_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA6_Clk : in std_logic;
      SDMA6_Rx_IntOut : out std_logic;
      SDMA6_Tx_IntOut : out std_logic;
      SDMA6_RstOut : out std_logic;
      SDMA6_TX_D : out std_logic_vector(0 to 31);
      SDMA6_TX_Rem : out std_logic_vector(0 to 3);
      SDMA6_TX_SOF : out std_logic;
      SDMA6_TX_EOF : out std_logic;
      SDMA6_TX_SOP : out std_logic;
      SDMA6_TX_EOP : out std_logic;
      SDMA6_TX_Src_Rdy : out std_logic;
      SDMA6_TX_Dst_Rdy : in std_logic;
      SDMA6_RX_D : in std_logic_vector(0 to 31);
      SDMA6_RX_Rem : in std_logic_vector(0 to 3);
      SDMA6_RX_SOF : in std_logic;
      SDMA6_RX_EOF : in std_logic;
      SDMA6_RX_SOP : in std_logic;
      SDMA6_RX_EOP : in std_logic;
      SDMA6_RX_Src_Rdy : in std_logic;
      SDMA6_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL6_Clk : in std_logic;
      SDMA_CTRL6_Rst : in std_logic;
      SDMA_CTRL6_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL6_PLB_PAValid : in std_logic;
      SDMA_CTRL6_PLB_SAValid : in std_logic;
      SDMA_CTRL6_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL6_PLB_RNW : in std_logic;
      SDMA_CTRL6_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL6_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL6_PLB_rdPrim : in std_logic;
      SDMA_CTRL6_PLB_wrPrim : in std_logic;
      SDMA_CTRL6_PLB_abort : in std_logic;
      SDMA_CTRL6_PLB_busLock : in std_logic;
      SDMA_CTRL6_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL6_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL6_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL6_PLB_lockErr : in std_logic;
      SDMA_CTRL6_PLB_wrPendReq : in std_logic;
      SDMA_CTRL6_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL6_PLB_rdPendReq : in std_logic;
      SDMA_CTRL6_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL6_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL6_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL6_PLB_rdBurst : in std_logic;
      SDMA_CTRL6_PLB_wrBurst : in std_logic;
      SDMA_CTRL6_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL6_Sl_addrAck : out std_logic;
      SDMA_CTRL6_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL6_Sl_wait : out std_logic;
      SDMA_CTRL6_Sl_rearbitrate : out std_logic;
      SDMA_CTRL6_Sl_wrDAck : out std_logic;
      SDMA_CTRL6_Sl_wrComp : out std_logic;
      SDMA_CTRL6_Sl_wrBTerm : out std_logic;
      SDMA_CTRL6_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL6_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL6_Sl_rdDAck : out std_logic;
      SDMA_CTRL6_Sl_rdComp : out std_logic;
      SDMA_CTRL6_Sl_rdBTerm : out std_logic;
      SDMA_CTRL6_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL6_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL6_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL6_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM6_Addr : in std_logic_vector(31 downto 0);
      PIM6_AddrReq : in std_logic;
      PIM6_AddrAck : out std_logic;
      PIM6_RNW : in std_logic;
      PIM6_Size : in std_logic_vector(3 downto 0);
      PIM6_RdModWr : in std_logic;
      PIM6_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM6_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM6_WrFIFO_Push : in std_logic;
      PIM6_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM6_RdFIFO_Pop : in std_logic;
      PIM6_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM6_WrFIFO_Empty : out std_logic;
      PIM6_WrFIFO_AlmostFull : out std_logic;
      PIM6_WrFIFO_Flush : in std_logic;
      PIM6_RdFIFO_Empty : out std_logic;
      PIM6_RdFIFO_Flush : in std_logic;
      PIM6_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM6_InitDone : out std_logic;
      PPC440MC6_MIMCReadNotWrite : in std_logic;
      PPC440MC6_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC6_MIMCAddressValid : in std_logic;
      PPC440MC6_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC6_MIMCWriteDataValid : in std_logic;
      PPC440MC6_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC6_MIMCBankConflict : in std_logic;
      PPC440MC6_MIMCRowConflict : in std_logic;
      PPC440MC6_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC6_MCMIReadDataValid : out std_logic;
      PPC440MC6_MCMIReadDataErr : out std_logic;
      PPC440MC6_MCMIAddrReadyToAccept : out std_logic;
      VFBC6_Cmd_Clk : in std_logic;
      VFBC6_Cmd_Reset : in std_logic;
      VFBC6_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC6_Cmd_Write : in std_logic;
      VFBC6_Cmd_End : in std_logic;
      VFBC6_Cmd_Full : out std_logic;
      VFBC6_Cmd_Almost_Full : out std_logic;
      VFBC6_Cmd_Idle : out std_logic;
      VFBC6_Wd_Clk : in std_logic;
      VFBC6_Wd_Reset : in std_logic;
      VFBC6_Wd_Write : in std_logic;
      VFBC6_Wd_End_Burst : in std_logic;
      VFBC6_Wd_Flush : in std_logic;
      VFBC6_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC6_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC6_Wd_Full : out std_logic;
      VFBC6_Wd_Almost_Full : out std_logic;
      VFBC6_Rd_Clk : in std_logic;
      VFBC6_Rd_Reset : in std_logic;
      VFBC6_Rd_Read : in std_logic;
      VFBC6_Rd_End_Burst : in std_logic;
      VFBC6_Rd_Flush : in std_logic;
      VFBC6_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC6_Rd_Empty : out std_logic;
      VFBC6_Rd_Almost_Empty : out std_logic;
      MCB6_cmd_clk : in std_logic;
      MCB6_cmd_en : in std_logic;
      MCB6_cmd_instr : in std_logic_vector(2 downto 0);
      MCB6_cmd_bl : in std_logic_vector(5 downto 0);
      MCB6_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB6_cmd_empty : out std_logic;
      MCB6_cmd_full : out std_logic;
      MCB6_wr_clk : in std_logic;
      MCB6_wr_en : in std_logic;
      MCB6_wr_mask : in std_logic_vector(7 downto 0);
      MCB6_wr_data : in std_logic_vector(63 downto 0);
      MCB6_wr_full : out std_logic;
      MCB6_wr_empty : out std_logic;
      MCB6_wr_count : out std_logic_vector(6 downto 0);
      MCB6_wr_underrun : out std_logic;
      MCB6_wr_error : out std_logic;
      MCB6_rd_clk : in std_logic;
      MCB6_rd_en : in std_logic;
      MCB6_rd_data : out std_logic_vector(63 downto 0);
      MCB6_rd_full : out std_logic;
      MCB6_rd_empty : out std_logic;
      MCB6_rd_count : out std_logic_vector(6 downto 0);
      MCB6_rd_overflow : out std_logic;
      MCB6_rd_error : out std_logic;
      FSL7_M_Clk : in std_logic;
      FSL7_M_Write : in std_logic;
      FSL7_M_Data : in std_logic_vector(0 to 31);
      FSL7_M_Control : in std_logic;
      FSL7_M_Full : out std_logic;
      FSL7_S_Clk : in std_logic;
      FSL7_S_Read : in std_logic;
      FSL7_S_Data : out std_logic_vector(0 to 31);
      FSL7_S_Control : out std_logic;
      FSL7_S_Exists : out std_logic;
      FSL7_B_M_Clk : in std_logic;
      FSL7_B_M_Write : in std_logic;
      FSL7_B_M_Data : in std_logic_vector(0 to 31);
      FSL7_B_M_Control : in std_logic;
      FSL7_B_M_Full : out std_logic;
      FSL7_B_S_Clk : in std_logic;
      FSL7_B_S_Read : in std_logic;
      FSL7_B_S_Data : out std_logic_vector(0 to 31);
      FSL7_B_S_Control : out std_logic;
      FSL7_B_S_Exists : out std_logic;
      SPLB7_Clk : in std_logic;
      SPLB7_Rst : in std_logic;
      SPLB7_PLB_ABus : in std_logic_vector(0 to 31);
      SPLB7_PLB_PAValid : in std_logic;
      SPLB7_PLB_SAValid : in std_logic;
      SPLB7_PLB_masterID : in std_logic_vector(0 to 0);
      SPLB7_PLB_RNW : in std_logic;
      SPLB7_PLB_BE : in std_logic_vector(0 to 7);
      SPLB7_PLB_UABus : in std_logic_vector(0 to 31);
      SPLB7_PLB_rdPrim : in std_logic;
      SPLB7_PLB_wrPrim : in std_logic;
      SPLB7_PLB_abort : in std_logic;
      SPLB7_PLB_busLock : in std_logic;
      SPLB7_PLB_MSize : in std_logic_vector(0 to 1);
      SPLB7_PLB_size : in std_logic_vector(0 to 3);
      SPLB7_PLB_type : in std_logic_vector(0 to 2);
      SPLB7_PLB_lockErr : in std_logic;
      SPLB7_PLB_wrPendReq : in std_logic;
      SPLB7_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SPLB7_PLB_rdPendReq : in std_logic;
      SPLB7_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SPLB7_PLB_reqPri : in std_logic_vector(0 to 1);
      SPLB7_PLB_TAttribute : in std_logic_vector(0 to 15);
      SPLB7_PLB_rdBurst : in std_logic;
      SPLB7_PLB_wrBurst : in std_logic;
      SPLB7_PLB_wrDBus : in std_logic_vector(0 to 63);
      SPLB7_Sl_addrAck : out std_logic;
      SPLB7_Sl_SSize : out std_logic_vector(0 to 1);
      SPLB7_Sl_wait : out std_logic;
      SPLB7_Sl_rearbitrate : out std_logic;
      SPLB7_Sl_wrDAck : out std_logic;
      SPLB7_Sl_wrComp : out std_logic;
      SPLB7_Sl_wrBTerm : out std_logic;
      SPLB7_Sl_rdDBus : out std_logic_vector(0 to 63);
      SPLB7_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SPLB7_Sl_rdDAck : out std_logic;
      SPLB7_Sl_rdComp : out std_logic;
      SPLB7_Sl_rdBTerm : out std_logic;
      SPLB7_Sl_MBusy : out std_logic_vector(0 to 0);
      SPLB7_Sl_MRdErr : out std_logic_vector(0 to 0);
      SPLB7_Sl_MWrErr : out std_logic_vector(0 to 0);
      SPLB7_Sl_MIRQ : out std_logic_vector(0 to 0);
      SDMA7_Clk : in std_logic;
      SDMA7_Rx_IntOut : out std_logic;
      SDMA7_Tx_IntOut : out std_logic;
      SDMA7_RstOut : out std_logic;
      SDMA7_TX_D : out std_logic_vector(0 to 31);
      SDMA7_TX_Rem : out std_logic_vector(0 to 3);
      SDMA7_TX_SOF : out std_logic;
      SDMA7_TX_EOF : out std_logic;
      SDMA7_TX_SOP : out std_logic;
      SDMA7_TX_EOP : out std_logic;
      SDMA7_TX_Src_Rdy : out std_logic;
      SDMA7_TX_Dst_Rdy : in std_logic;
      SDMA7_RX_D : in std_logic_vector(0 to 31);
      SDMA7_RX_Rem : in std_logic_vector(0 to 3);
      SDMA7_RX_SOF : in std_logic;
      SDMA7_RX_EOF : in std_logic;
      SDMA7_RX_SOP : in std_logic;
      SDMA7_RX_EOP : in std_logic;
      SDMA7_RX_Src_Rdy : in std_logic;
      SDMA7_RX_Dst_Rdy : out std_logic;
      SDMA_CTRL7_Clk : in std_logic;
      SDMA_CTRL7_Rst : in std_logic;
      SDMA_CTRL7_PLB_ABus : in std_logic_vector(0 to 31);
      SDMA_CTRL7_PLB_PAValid : in std_logic;
      SDMA_CTRL7_PLB_SAValid : in std_logic;
      SDMA_CTRL7_PLB_masterID : in std_logic_vector(0 to 0);
      SDMA_CTRL7_PLB_RNW : in std_logic;
      SDMA_CTRL7_PLB_BE : in std_logic_vector(0 to 7);
      SDMA_CTRL7_PLB_UABus : in std_logic_vector(0 to 31);
      SDMA_CTRL7_PLB_rdPrim : in std_logic;
      SDMA_CTRL7_PLB_wrPrim : in std_logic;
      SDMA_CTRL7_PLB_abort : in std_logic;
      SDMA_CTRL7_PLB_busLock : in std_logic;
      SDMA_CTRL7_PLB_MSize : in std_logic_vector(0 to 1);
      SDMA_CTRL7_PLB_size : in std_logic_vector(0 to 3);
      SDMA_CTRL7_PLB_type : in std_logic_vector(0 to 2);
      SDMA_CTRL7_PLB_lockErr : in std_logic;
      SDMA_CTRL7_PLB_wrPendReq : in std_logic;
      SDMA_CTRL7_PLB_wrPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL7_PLB_rdPendReq : in std_logic;
      SDMA_CTRL7_PLB_rdPendPri : in std_logic_vector(0 to 1);
      SDMA_CTRL7_PLB_reqPri : in std_logic_vector(0 to 1);
      SDMA_CTRL7_PLB_TAttribute : in std_logic_vector(0 to 15);
      SDMA_CTRL7_PLB_rdBurst : in std_logic;
      SDMA_CTRL7_PLB_wrBurst : in std_logic;
      SDMA_CTRL7_PLB_wrDBus : in std_logic_vector(0 to 63);
      SDMA_CTRL7_Sl_addrAck : out std_logic;
      SDMA_CTRL7_Sl_SSize : out std_logic_vector(0 to 1);
      SDMA_CTRL7_Sl_wait : out std_logic;
      SDMA_CTRL7_Sl_rearbitrate : out std_logic;
      SDMA_CTRL7_Sl_wrDAck : out std_logic;
      SDMA_CTRL7_Sl_wrComp : out std_logic;
      SDMA_CTRL7_Sl_wrBTerm : out std_logic;
      SDMA_CTRL7_Sl_rdDBus : out std_logic_vector(0 to 63);
      SDMA_CTRL7_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      SDMA_CTRL7_Sl_rdDAck : out std_logic;
      SDMA_CTRL7_Sl_rdComp : out std_logic;
      SDMA_CTRL7_Sl_rdBTerm : out std_logic;
      SDMA_CTRL7_Sl_MBusy : out std_logic_vector(0 to 0);
      SDMA_CTRL7_Sl_MRdErr : out std_logic_vector(0 to 0);
      SDMA_CTRL7_Sl_MWrErr : out std_logic_vector(0 to 0);
      SDMA_CTRL7_Sl_MIRQ : out std_logic_vector(0 to 0);
      PIM7_Addr : in std_logic_vector(31 downto 0);
      PIM7_AddrReq : in std_logic;
      PIM7_AddrAck : out std_logic;
      PIM7_RNW : in std_logic;
      PIM7_Size : in std_logic_vector(3 downto 0);
      PIM7_RdModWr : in std_logic;
      PIM7_WrFIFO_Data : in std_logic_vector(63 downto 0);
      PIM7_WrFIFO_BE : in std_logic_vector(7 downto 0);
      PIM7_WrFIFO_Push : in std_logic;
      PIM7_RdFIFO_Data : out std_logic_vector(63 downto 0);
      PIM7_RdFIFO_Pop : in std_logic;
      PIM7_RdFIFO_RdWdAddr : out std_logic_vector(3 downto 0);
      PIM7_WrFIFO_Empty : out std_logic;
      PIM7_WrFIFO_AlmostFull : out std_logic;
      PIM7_WrFIFO_Flush : in std_logic;
      PIM7_RdFIFO_Empty : out std_logic;
      PIM7_RdFIFO_Flush : in std_logic;
      PIM7_RdFIFO_Latency : out std_logic_vector(1 downto 0);
      PIM7_InitDone : out std_logic;
      PPC440MC7_MIMCReadNotWrite : in std_logic;
      PPC440MC7_MIMCAddress : in std_logic_vector(0 to 35);
      PPC440MC7_MIMCAddressValid : in std_logic;
      PPC440MC7_MIMCWriteData : in std_logic_vector(0 to 127);
      PPC440MC7_MIMCWriteDataValid : in std_logic;
      PPC440MC7_MIMCByteEnable : in std_logic_vector(0 to 15);
      PPC440MC7_MIMCBankConflict : in std_logic;
      PPC440MC7_MIMCRowConflict : in std_logic;
      PPC440MC7_MCMIReadData : out std_logic_vector(0 to 127);
      PPC440MC7_MCMIReadDataValid : out std_logic;
      PPC440MC7_MCMIReadDataErr : out std_logic;
      PPC440MC7_MCMIAddrReadyToAccept : out std_logic;
      VFBC7_Cmd_Clk : in std_logic;
      VFBC7_Cmd_Reset : in std_logic;
      VFBC7_Cmd_Data : in std_logic_vector(31 downto 0);
      VFBC7_Cmd_Write : in std_logic;
      VFBC7_Cmd_End : in std_logic;
      VFBC7_Cmd_Full : out std_logic;
      VFBC7_Cmd_Almost_Full : out std_logic;
      VFBC7_Cmd_Idle : out std_logic;
      VFBC7_Wd_Clk : in std_logic;
      VFBC7_Wd_Reset : in std_logic;
      VFBC7_Wd_Write : in std_logic;
      VFBC7_Wd_End_Burst : in std_logic;
      VFBC7_Wd_Flush : in std_logic;
      VFBC7_Wd_Data : in std_logic_vector(31 downto 0);
      VFBC7_Wd_Data_BE : in std_logic_vector(3 downto 0);
      VFBC7_Wd_Full : out std_logic;
      VFBC7_Wd_Almost_Full : out std_logic;
      VFBC7_Rd_Clk : in std_logic;
      VFBC7_Rd_Reset : in std_logic;
      VFBC7_Rd_Read : in std_logic;
      VFBC7_Rd_End_Burst : in std_logic;
      VFBC7_Rd_Flush : in std_logic;
      VFBC7_Rd_Data : out std_logic_vector(31 downto 0);
      VFBC7_Rd_Empty : out std_logic;
      VFBC7_Rd_Almost_Empty : out std_logic;
      MCB7_cmd_clk : in std_logic;
      MCB7_cmd_en : in std_logic;
      MCB7_cmd_instr : in std_logic_vector(2 downto 0);
      MCB7_cmd_bl : in std_logic_vector(5 downto 0);
      MCB7_cmd_byte_addr : in std_logic_vector(29 downto 0);
      MCB7_cmd_empty : out std_logic;
      MCB7_cmd_full : out std_logic;
      MCB7_wr_clk : in std_logic;
      MCB7_wr_en : in std_logic;
      MCB7_wr_mask : in std_logic_vector(7 downto 0);
      MCB7_wr_data : in std_logic_vector(63 downto 0);
      MCB7_wr_full : out std_logic;
      MCB7_wr_empty : out std_logic;
      MCB7_wr_count : out std_logic_vector(6 downto 0);
      MCB7_wr_underrun : out std_logic;
      MCB7_wr_error : out std_logic;
      MCB7_rd_clk : in std_logic;
      MCB7_rd_en : in std_logic;
      MCB7_rd_data : out std_logic_vector(63 downto 0);
      MCB7_rd_full : out std_logic;
      MCB7_rd_empty : out std_logic;
      MCB7_rd_count : out std_logic_vector(6 downto 0);
      MCB7_rd_overflow : out std_logic;
      MCB7_rd_error : out std_logic;
      MPMC_CTRL_Clk : in std_logic;
      MPMC_CTRL_Rst : in std_logic;
      MPMC_CTRL_PLB_ABus : in std_logic_vector(0 to 31);
      MPMC_CTRL_PLB_PAValid : in std_logic;
      MPMC_CTRL_PLB_SAValid : in std_logic;
      MPMC_CTRL_PLB_masterID : in std_logic_vector(0 to 0);
      MPMC_CTRL_PLB_RNW : in std_logic;
      MPMC_CTRL_PLB_BE : in std_logic_vector(0 to 7);
      MPMC_CTRL_PLB_UABus : in std_logic_vector(0 to 31);
      MPMC_CTRL_PLB_rdPrim : in std_logic;
      MPMC_CTRL_PLB_wrPrim : in std_logic;
      MPMC_CTRL_PLB_abort : in std_logic;
      MPMC_CTRL_PLB_busLock : in std_logic;
      MPMC_CTRL_PLB_MSize : in std_logic_vector(0 to 1);
      MPMC_CTRL_PLB_size : in std_logic_vector(0 to 3);
      MPMC_CTRL_PLB_type : in std_logic_vector(0 to 2);
      MPMC_CTRL_PLB_lockErr : in std_logic;
      MPMC_CTRL_PLB_wrPendReq : in std_logic;
      MPMC_CTRL_PLB_wrPendPri : in std_logic_vector(0 to 1);
      MPMC_CTRL_PLB_rdPendReq : in std_logic;
      MPMC_CTRL_PLB_rdPendPri : in std_logic_vector(0 to 1);
      MPMC_CTRL_PLB_reqPri : in std_logic_vector(0 to 1);
      MPMC_CTRL_PLB_TAttribute : in std_logic_vector(0 to 15);
      MPMC_CTRL_PLB_rdBurst : in std_logic;
      MPMC_CTRL_PLB_wrBurst : in std_logic;
      MPMC_CTRL_PLB_wrDBus : in std_logic_vector(0 to 63);
      MPMC_CTRL_Sl_addrAck : out std_logic;
      MPMC_CTRL_Sl_SSize : out std_logic_vector(0 to 1);
      MPMC_CTRL_Sl_wait : out std_logic;
      MPMC_CTRL_Sl_rearbitrate : out std_logic;
      MPMC_CTRL_Sl_wrDAck : out std_logic;
      MPMC_CTRL_Sl_wrComp : out std_logic;
      MPMC_CTRL_Sl_wrBTerm : out std_logic;
      MPMC_CTRL_Sl_rdDBus : out std_logic_vector(0 to 63);
      MPMC_CTRL_Sl_rdWdAddr : out std_logic_vector(0 to 3);
      MPMC_CTRL_Sl_rdDAck : out std_logic;
      MPMC_CTRL_Sl_rdComp : out std_logic;
      MPMC_CTRL_Sl_rdBTerm : out std_logic;
      MPMC_CTRL_Sl_MBusy : out std_logic_vector(0 to 0);
      MPMC_CTRL_Sl_MRdErr : out std_logic_vector(0 to 0);
      MPMC_CTRL_Sl_MWrErr : out std_logic_vector(0 to 0);
      MPMC_CTRL_Sl_MIRQ : out std_logic_vector(0 to 0);
      MPMC_Clk0 : in std_logic;
      MPMC_Clk0_DIV2 : in std_logic;
      MPMC_Clk90 : in std_logic;
      MPMC_Clk_200MHz : in std_logic;
      MPMC_Rst : in std_logic;
      MPMC_Clk_Mem : in std_logic;
      MPMC_Clk_Mem_2x : in std_logic;
      MPMC_Clk_Mem_2x_180 : in std_logic;
      MPMC_Clk_Mem_2x_CE0 : in std_logic;
      MPMC_Clk_Mem_2x_CE90 : in std_logic;
      MPMC_Clk_Rd_Base : in std_logic;
      MPMC_Clk_Mem_2x_bufpll_o : out std_logic;
      MPMC_Clk_Mem_2x_180_bufpll_o : out std_logic;
      MPMC_Clk_Mem_2x_CE0_bufpll_o : out std_logic;
      MPMC_Clk_Mem_2x_CE90_bufpll_o : out std_logic;
      MPMC_PLL_Lock_bufpll_o : out std_logic;
      MPMC_PLL_Lock : in std_logic;
      MPMC_Idelayctrl_Rdy_I : in std_logic;
      MPMC_Idelayctrl_Rdy_O : out std_logic;
      MPMC_InitDone : out std_logic;
      MPMC_ECC_Intr : out std_logic;
      MPMC_DCM_PSEN : out std_logic;
      MPMC_DCM_PSINCDEC : out std_logic;
      MPMC_DCM_PSDONE : in std_logic;
      MPMC_MCB_DRP_Clk : in std_logic;
      SDRAM_Clk : out std_logic_vector(0 to 0);
      SDRAM_CE : out std_logic_vector(0 to 0);
      SDRAM_CS_n : out std_logic_vector(0 to 0);
      SDRAM_RAS_n : out std_logic;
      SDRAM_CAS_n : out std_logic;
      SDRAM_WE_n : out std_logic;
      SDRAM_BankAddr : out std_logic_vector(2 downto 0);
      SDRAM_Addr : out std_logic_vector(12 downto 0);
      SDRAM_DQ : inout std_logic_vector(31 downto 0);
      SDRAM_DM : out std_logic_vector(3 downto 0);
      DDR_Clk : out std_logic_vector(0 to 0);
      DDR_Clk_n : out std_logic_vector(0 to 0);
      DDR_CE : out std_logic_vector(0 to 0);
      DDR_CS_n : out std_logic_vector(0 to 0);
      DDR_RAS_n : out std_logic;
      DDR_CAS_n : out std_logic;
      DDR_WE_n : out std_logic;
      DDR_BankAddr : out std_logic_vector(2 downto 0);
      DDR_Addr : out std_logic_vector(12 downto 0);
      DDR_DQ : inout std_logic_vector(31 downto 0);
      DDR_DM : out std_logic_vector(3 downto 0);
      DDR_DQS : inout std_logic_vector(3 downto 0);
      DDR_DQS_Div_O : out std_logic;
      DDR_DQS_Div_I : in std_logic;
      DDR2_Clk : out std_logic_vector(0 to 0);
      DDR2_Clk_n : out std_logic_vector(0 to 0);
      DDR2_CE : out std_logic_vector(0 to 0);
      DDR2_CS_n : out std_logic_vector(0 to 0);
      DDR2_ODT : out std_logic_vector(0 to 0);
      DDR2_RAS_n : out std_logic;
      DDR2_CAS_n : out std_logic;
      DDR2_WE_n : out std_logic;
      DDR2_BankAddr : out std_logic_vector(2 downto 0);
      DDR2_Addr : out std_logic_vector(12 downto 0);
      DDR2_DQ : inout std_logic_vector(31 downto 0);
      DDR2_DM : out std_logic_vector(3 downto 0);
      DDR2_DQS : inout std_logic_vector(3 downto 0);
      DDR2_DQS_n : inout std_logic_vector(3 downto 0);
      DDR2_DQS_Div_O : out std_logic;
      DDR2_DQS_Div_I : in std_logic;
      DDR3_Clk : out std_logic_vector(0 to 0);
      DDR3_Clk_n : out std_logic_vector(0 to 0);
      DDR3_CE : out std_logic_vector(0 to 0);
      DDR3_CS_n : out std_logic_vector(0 to 0);
      DDR3_ODT : out std_logic_vector(0 to 0);
      DDR3_RAS_n : out std_logic;
      DDR3_CAS_n : out std_logic;
      DDR3_WE_n : out std_logic;
      DDR3_BankAddr : out std_logic_vector(2 downto 0);
      DDR3_Addr : out std_logic_vector(12 downto 0);
      DDR3_DQ : inout std_logic_vector(31 downto 0);
      DDR3_DM : out std_logic_vector(3 downto 0);
      DDR3_Reset_n : out std_logic;
      DDR3_DQS : inout std_logic_vector(3 downto 0);
      DDR3_DQS_n : inout std_logic_vector(3 downto 0);
      mcbx_dram_addr : out std_logic_vector(12 downto 0);
      mcbx_dram_ba : out std_logic_vector(2 downto 0);
      mcbx_dram_ras_n : out std_logic;
      mcbx_dram_cas_n : out std_logic;
      mcbx_dram_we_n : out std_logic;
      mcbx_dram_cke : out std_logic;
      mcbx_dram_clk : out std_logic;
      mcbx_dram_clk_n : out std_logic;
      mcbx_dram_dq : inout std_logic_vector(31 downto 0);
      mcbx_dram_dqs : inout std_logic;
      mcbx_dram_dqs_n : inout std_logic;
      mcbx_dram_udqs : inout std_logic;
      mcbx_dram_udqs_n : inout std_logic;
      mcbx_dram_udm : out std_logic;
      mcbx_dram_ldm : out std_logic;
      mcbx_dram_odt : out std_logic;
      mcbx_dram_ddr3_rst : out std_logic;
      selfrefresh_enter : in std_logic;
      selfrefresh_mode : out std_logic;
      calib_recal : in std_logic;
      rzq : inout std_logic;
      zio : inout std_logic
    );
  end component;

  component flash_ce_inverter_wrapper is
    port (
      Op1 : in std_logic_vector(0 to 0);
      Op2 : in std_logic_vector(0 to 0);
      Res : out std_logic_vector(0 to 0)
    );
  end component;

  component pcie_diff_clk_wrapper is
    port (
      IBUF_DS_P : in std_logic_vector(0 to 0);
      IBUF_DS_N : in std_logic_vector(0 to 0);
      IBUF_OUT : out std_logic_vector(0 to 0);
      OBUF_IN : in std_logic_vector(0 to 0);
      OBUF_DS_P : out std_logic_vector(0 to 0);
      OBUF_DS_N : out std_logic_vector(0 to 0);
      IOBUF_DS_P : inout std_logic_vector(0 to 0);
      IOBUF_DS_N : inout std_logic_vector(0 to 0);
      IOBUF_IO_T : in std_logic_vector(0 to 0);
      IOBUF_IO_I : in std_logic_vector(0 to 0);
      IOBUF_IO_O : out std_logic_vector(0 to 0)
    );
  end component;

  component clock_generator_0_wrapper is
    port (
      CLKIN : in std_logic;
      CLKOUT0 : out std_logic;
      CLKOUT1 : out std_logic;
      CLKOUT2 : out std_logic;
      CLKOUT3 : out std_logic;
      CLKOUT4 : out std_logic;
      CLKOUT5 : out std_logic;
      CLKOUT6 : out std_logic;
      CLKOUT7 : out std_logic;
      CLKOUT8 : out std_logic;
      CLKOUT9 : out std_logic;
      CLKOUT10 : out std_logic;
      CLKOUT11 : out std_logic;
      CLKOUT12 : out std_logic;
      CLKOUT13 : out std_logic;
      CLKOUT14 : out std_logic;
      CLKOUT15 : out std_logic;
      CLKFBIN : in std_logic;
      CLKFBOUT : out std_logic;
      PSCLK : in std_logic;
      PSEN : in std_logic;
      PSINCDEC : in std_logic;
      PSDONE : out std_logic;
      RST : in std_logic;
      LOCKED : out std_logic
    );
  end component;

  component mdm_0_wrapper is
    port (
      Interrupt : out std_logic;
      Debug_SYS_Rst : out std_logic;
      Ext_BRK : out std_logic;
      Ext_NM_BRK : out std_logic;
      S_AXI_ACLK : in std_logic;
      S_AXI_ARESETN : in std_logic;
      S_AXI_AWADDR : in std_logic_vector(31 downto 0);
      S_AXI_AWVALID : in std_logic;
      S_AXI_AWREADY : out std_logic;
      S_AXI_WDATA : in std_logic_vector(31 downto 0);
      S_AXI_WSTRB : in std_logic_vector(3 downto 0);
      S_AXI_WVALID : in std_logic;
      S_AXI_WREADY : out std_logic;
      S_AXI_BRESP : out std_logic_vector(1 downto 0);
      S_AXI_BVALID : out std_logic;
      S_AXI_BREADY : in std_logic;
      S_AXI_ARADDR : in std_logic_vector(31 downto 0);
      S_AXI_ARVALID : in std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA : out std_logic_vector(31 downto 0);
      S_AXI_RRESP : out std_logic_vector(1 downto 0);
      S_AXI_RVALID : out std_logic;
      S_AXI_RREADY : in std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_MIRQ : out std_logic_vector(0 to 2);
      Dbg_Clk_0 : out std_logic;
      Dbg_TDI_0 : out std_logic;
      Dbg_TDO_0 : in std_logic;
      Dbg_Reg_En_0 : out std_logic_vector(0 to 7);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0 : out std_logic;
      Dbg_Update_0 : out std_logic;
      Dbg_Rst_0 : out std_logic;
      Dbg_Clk_1 : out std_logic;
      Dbg_TDI_1 : out std_logic;
      Dbg_TDO_1 : in std_logic;
      Dbg_Reg_En_1 : out std_logic_vector(0 to 7);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1 : out std_logic;
      Dbg_Update_1 : out std_logic;
      Dbg_Rst_1 : out std_logic;
      Dbg_Clk_2 : out std_logic;
      Dbg_TDI_2 : out std_logic;
      Dbg_TDO_2 : in std_logic;
      Dbg_Reg_En_2 : out std_logic_vector(0 to 7);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2 : out std_logic;
      Dbg_Update_2 : out std_logic;
      Dbg_Rst_2 : out std_logic;
      Dbg_Clk_3 : out std_logic;
      Dbg_TDI_3 : out std_logic;
      Dbg_TDO_3 : in std_logic;
      Dbg_Reg_En_3 : out std_logic_vector(0 to 7);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3 : out std_logic;
      Dbg_Update_3 : out std_logic;
      Dbg_Rst_3 : out std_logic;
      Dbg_Clk_4 : out std_logic;
      Dbg_TDI_4 : out std_logic;
      Dbg_TDO_4 : in std_logic;
      Dbg_Reg_En_4 : out std_logic_vector(0 to 7);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4 : out std_logic;
      Dbg_Update_4 : out std_logic;
      Dbg_Rst_4 : out std_logic;
      Dbg_Clk_5 : out std_logic;
      Dbg_TDI_5 : out std_logic;
      Dbg_TDO_5 : in std_logic;
      Dbg_Reg_En_5 : out std_logic_vector(0 to 7);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5 : out std_logic;
      Dbg_Update_5 : out std_logic;
      Dbg_Rst_5 : out std_logic;
      Dbg_Clk_6 : out std_logic;
      Dbg_TDI_6 : out std_logic;
      Dbg_TDO_6 : in std_logic;
      Dbg_Reg_En_6 : out std_logic_vector(0 to 7);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6 : out std_logic;
      Dbg_Update_6 : out std_logic;
      Dbg_Rst_6 : out std_logic;
      Dbg_Clk_7 : out std_logic;
      Dbg_TDI_7 : out std_logic;
      Dbg_TDO_7 : in std_logic;
      Dbg_Reg_En_7 : out std_logic_vector(0 to 7);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7 : out std_logic;
      Dbg_Update_7 : out std_logic;
      Dbg_Rst_7 : out std_logic;
      bscan_tdi : out std_logic;
      bscan_reset : out std_logic;
      bscan_shift : out std_logic;
      bscan_update : out std_logic;
      bscan_capture : out std_logic;
      bscan_sel1 : out std_logic;
      bscan_drck1 : out std_logic;
      bscan_tdo1 : in std_logic;
      Ext_JTAG_DRCK : out std_logic;
      Ext_JTAG_RESET : out std_logic;
      Ext_JTAG_SEL : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT : out std_logic;
      Ext_JTAG_UPDATE : out std_logic;
      Ext_JTAG_TDI : out std_logic;
      Ext_JTAG_TDO : in std_logic
    );
  end component;

  component proc_sys_reset_0_wrapper is
    port (
      Slowest_sync_clk : in std_logic;
      Ext_Reset_In : in std_logic;
      Aux_Reset_In : in std_logic;
      MB_Debug_Sys_Rst : in std_logic;
      Core_Reset_Req_0 : in std_logic;
      Chip_Reset_Req_0 : in std_logic;
      System_Reset_Req_0 : in std_logic;
      Core_Reset_Req_1 : in std_logic;
      Chip_Reset_Req_1 : in std_logic;
      System_Reset_Req_1 : in std_logic;
      Dcm_locked : in std_logic;
      RstcPPCresetcore_0 : out std_logic;
      RstcPPCresetchip_0 : out std_logic;
      RstcPPCresetsys_0 : out std_logic;
      RstcPPCresetcore_1 : out std_logic;
      RstcPPCresetchip_1 : out std_logic;
      RstcPPCresetsys_1 : out std_logic;
      MB_Reset : out std_logic;
      Bus_Struct_Reset : out std_logic_vector(0 to 0);
      Peripheral_Reset : out std_logic_vector(0 to 0);
      Interconnect_aresetn : out std_logic_vector(0 to 0);
      Peripheral_aresetn : out std_logic_vector(0 to 0)
    );
  end component;

  component xps_intc_0_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_lockErr : in std_logic;
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      Sl_wrBTerm : out std_logic;
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdBTerm : out std_logic;
      Sl_MIRQ : out std_logic_vector(0 to 2);
      Intr : in std_logic_vector(5 downto 0);
      Irq : out std_logic
    );
  end component;

  component xps_timer_0_wrapper is
    port (
      CaptureTrig0 : in std_logic;
      CaptureTrig1 : in std_logic;
      GenerateOut0 : out std_logic;
      GenerateOut1 : out std_logic;
      PWM0 : out std_logic;
      Interrupt : out std_logic;
      Freeze : in std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 1);
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrDBus : in std_logic_vector(0 to 63);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 2);
      Sl_MWrErr : out std_logic_vector(0 to 2);
      Sl_MRdErr : out std_logic_vector(0 to 2);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_lockErr : in std_logic;
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_wrBTerm : out std_logic;
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdBTerm : out std_logic;
      Sl_MIRQ : out std_logic_vector(0 to 2)
    );
  end component;

  component fsl_v20_0_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_v20_1_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_v20_2_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_v20_3_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component proc_control_0_wrapper is
    port (
      FSL_Clk : in std_logic;
      FSL_Rst : in std_logic;
      FSL_S_Clk : out std_logic;
      FSL_S_Read : out std_logic;
      FSL_S_Data : in std_logic_vector(0 to 31);
      FSL_S_Control : in std_logic;
      FSL_S_Exists : in std_logic;
      FSL_M_Clk : out std_logic;
      FSL_M_Write : out std_logic;
      FSL_M_Data : out std_logic_vector(0 to 31);
      FSL_M_Control : out std_logic;
      FSL_M_Full : in std_logic;
      reset0 : out std_logic;
      reset1 : out std_logic;
      reset2 : out std_logic;
      reset3 : out std_logic;
      reset4 : out std_logic;
      reset5 : out std_logic;
      reset6 : out std_logic;
      reset7 : out std_logic;
      reset8 : out std_logic;
      reset9 : out std_logic;
      resetA : out std_logic;
      resetB : out std_logic;
      resetC : out std_logic;
      resetD : out std_logic;
      resetE : out std_logic;
      resetF : out std_logic;
      page_fault : in std_logic;
      fault_addr : in std_logic_vector(0 to 31);
      retry : out std_logic;
      pgd : out std_logic_vector(0 to 31);
      reconos_reset : out std_logic
    );
  end component;

  component xps_mem_0_wrapper is
    port (
      MPLB_Clk : in std_logic;
      MPLB_Rst : in std_logic;
      MD_error : out std_logic;
      M_request : out std_logic;
      M_priority : out std_logic_vector(0 to 1);
      M_busLock : out std_logic;
      M_RNW : out std_logic;
      M_BE : out std_logic_vector(0 to 7);
      M_MSize : out std_logic_vector(0 to 1);
      M_size : out std_logic_vector(0 to 3);
      M_type : out std_logic_vector(0 to 2);
      M_TAttribute : out std_logic_vector(0 to 15);
      M_lockErr : out std_logic;
      M_abort : out std_logic;
      M_UABus : out std_logic_vector(0 to 31);
      M_ABus : out std_logic_vector(0 to 31);
      M_wrDBus : out std_logic_vector(0 to 63);
      M_wrBurst : out std_logic;
      M_rdBurst : out std_logic;
      PLB_MAddrAck : in std_logic;
      PLB_MSSize : in std_logic_vector(0 to 1);
      PLB_MRearbitrate : in std_logic;
      PLB_MTimeout : in std_logic;
      PLB_MBusy : in std_logic;
      PLB_MRdErr : in std_logic;
      PLB_MWrErr : in std_logic;
      PLB_MIRQ : in std_logic;
      PLB_MRdDBus : in std_logic_vector(0 to 63);
      PLB_MRdWdAddr : in std_logic_vector(0 to 3);
      PLB_MRdDAck : in std_logic;
      PLB_MRdBTerm : in std_logic;
      PLB_MWrDAck : in std_logic;
      PLB_MWrBTerm : in std_logic;
      FIFO32_S_Clk : out std_logic;
      FIFO32_S_Data : in std_logic_vector(0 to 31);
      FIFO32_S_Rd : out std_logic;
      FIFO32_S_Fill : in std_logic_vector(0 to 15);
      FIFO32_M_Clk : out std_logic;
      FIFO32_M_Data : out std_logic_vector(0 to 31);
      FIFO32_M_Wr : out std_logic;
      FIFO32_M_Rem : in std_logic_vector(0 to 15)
    );
  end component;

  component fifo32_0_wrapper is
    port (
      Rst : in std_logic;
      FIFO32_S_Clk : in std_logic;
      FIFO32_S_Data : out std_logic_vector(0 to 31);
      FIFO32_S_Rd : in std_logic;
      FIFO32_S_Fill : out std_logic_vector(0 to 15);
      FIFO32_M_Clk : in std_logic;
      FIFO32_M_Data : in std_logic_vector(0 to 31);
      FIFO32_M_Wr : in std_logic;
      FIFO32_M_Rem : out std_logic_vector(0 to 15)
    );
  end component;

  component fifo32_1_wrapper is
    port (
      Rst : in std_logic;
      FIFO32_S_Clk : in std_logic;
      FIFO32_S_Data : out std_logic_vector(0 to 31);
      FIFO32_S_Rd : in std_logic;
      FIFO32_S_Fill : out std_logic_vector(0 to 15);
      FIFO32_M_Clk : in std_logic;
      FIFO32_M_Data : in std_logic_vector(0 to 31);
      FIFO32_M_Wr : in std_logic;
      FIFO32_M_Rem : out std_logic_vector(0 to 15)
    );
  end component;

  component hwt_memaccess_0_wrapper is
    port (
      OSFSL_Clk : in std_logic;
      OSFSL_Rst : in std_logic;
      OSFSL_S_Clk : out std_logic;
      OSFSL_S_Read : out std_logic;
      OSFSL_S_Data : in std_logic_vector(0 to 31);
      OSFSL_S_Control : in std_logic;
      OSFSL_S_Exists : in std_logic;
      OSFSL_M_Clk : out std_logic;
      OSFSL_M_Write : out std_logic;
      OSFSL_M_Data : out std_logic_vector(0 to 31);
      OSFSL_M_Control : out std_logic;
      OSFSL_M_Full : in std_logic;
      FIFO32_S_Clk : out std_logic;
      FIFO32_S_Data : in std_logic_vector(0 to 31);
      FIFO32_S_Rd : out std_logic;
      FIFO32_S_Fill : in std_logic_vector(0 to 15);
      FIFO32_M_Clk : out std_logic;
      FIFO32_M_Data : out std_logic_vector(0 to 31);
      FIFO32_M_Wr : out std_logic;
      FIFO32_M_Rem : in std_logic_vector(0 to 15);
      Rst : in std_logic
    );
  end component;

  component mmu_0_wrapper is
    port (
      HWT_FIFO32_S_Clk : out std_logic;
      HWT_FIFO32_S_Data : in std_logic_vector(0 to 31);
      HWT_FIFO32_S_Rd : out std_logic;
      HWT_FIFO32_S_Fill : in std_logic_vector(0 to 15);
      HWT_FIFO32_M_Clk : out std_logic;
      HWT_FIFO32_M_Data : out std_logic_vector(0 to 31);
      HWT_FIFO32_M_Wr : out std_logic;
      HWT_FIFO32_M_Rem : in std_logic_vector(0 to 15);
      MEM_FIFO32_S_Clk : in std_logic;
      MEM_FIFO32_S_Data : out std_logic_vector(0 to 31);
      MEM_FIFO32_S_Rd : in std_logic;
      MEM_FIFO32_S_Fill : out std_logic_vector(0 to 15);
      MEM_FIFO32_M_Clk : in std_logic;
      MEM_FIFO32_M_Data : in std_logic_vector(0 to 31);
      MEM_FIFO32_M_Wr : in std_logic;
      MEM_FIFO32_M_Rem : out std_logic_vector(0 to 15);
      RETRY : in std_logic;
      PAGE_FAULT : out std_logic;
      FAULT_ADDR : out std_logic_vector(0 to 31);
      PGD : in std_logic_vector(0 to 31);
      Rst : in std_logic;
      Clk : in std_logic
    );
  end component;

  component IOBUF is
    port (
      I : in std_logic;
      IO : inout std_logic;
      O : out std_logic;
      T : in std_logic
    );
  end component;

  component IBUFGDS is
    port (
      I : in std_logic;
      IB : in std_logic;
      O : out std_logic
    );
  end component;

  -- Internal signals

  signal Dcm_all_locked : std_logic;
  signal Debug_SYS_Rst : std_logic;
  signal Ethernet_MAC_IP2INTC_Irpt : std_logic;
  signal Ext_BRK : std_logic;
  signal Ext_NM_BRK : std_logic;
  signal MPMC_DCM_PSDONE : std_logic;
  signal MPMC_DCM_PSEN : std_logic;
  signal MPMC_DCM_PSINCDEC : std_logic;
  signal RS232_Uart_1_Interrupt : std_logic;
  signal clk_100_0000MHzMMCM0 : std_logic;
  signal clk_200_0000MHzMMCM0 : std_logic;
  signal clk_400_0000MHzMMCM0 : std_logic;
  signal clk_400_0000MHzMMCM0_nobuf_varphase : std_logic;
  signal dcm_clk_s : std_logic;
  signal fifo32_0_MFIFO32_FIFO32_M_Clk : std_logic;
  signal fifo32_0_MFIFO32_FIFO32_M_Data : std_logic_vector(0 to 31);
  signal fifo32_0_MFIFO32_FIFO32_M_Rem : std_logic_vector(0 to 15);
  signal fifo32_0_MFIFO32_FIFO32_M_Wr : std_logic;
  signal fifo32_0_SFIFO32_FIFO32_S_Clk : std_logic;
  signal fifo32_0_SFIFO32_FIFO32_S_Data : std_logic_vector(0 to 31);
  signal fifo32_0_SFIFO32_FIFO32_S_Fill : std_logic_vector(0 to 15);
  signal fifo32_0_SFIFO32_FIFO32_S_Rd : std_logic;
  signal fifo32_1_MFIFO32_FIFO32_M_Clk : std_logic;
  signal fifo32_1_MFIFO32_FIFO32_M_Data : std_logic_vector(0 to 31);
  signal fifo32_1_MFIFO32_FIFO32_M_Rem : std_logic_vector(0 to 15);
  signal fifo32_1_MFIFO32_FIFO32_M_Wr : std_logic;
  signal fifo32_1_SFIFO32_FIFO32_S_Clk : std_logic;
  signal fifo32_1_SFIFO32_FIFO32_S_Data : std_logic_vector(0 to 31);
  signal fifo32_1_SFIFO32_FIFO32_S_Fill : std_logic_vector(0 to 15);
  signal fifo32_1_SFIFO32_FIFO32_S_Rd : std_logic;
  signal fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I : std_logic_vector(0 to 7);
  signal fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O : std_logic_vector(0 to 7);
  signal fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T : std_logic_vector(0 to 7);
  signal fpga_0_Ethernet_MAC_PHY_MDIO_pin_I : std_logic;
  signal fpga_0_Ethernet_MAC_PHY_MDIO_pin_O : std_logic;
  signal fpga_0_Ethernet_MAC_PHY_MDIO_pin_T : std_logic;
  signal fpga_0_IIC_DVI_Scl_pin_I : std_logic;
  signal fpga_0_IIC_DVI_Scl_pin_O : std_logic;
  signal fpga_0_IIC_DVI_Scl_pin_T : std_logic;
  signal fpga_0_IIC_DVI_Sda_pin_I : std_logic;
  signal fpga_0_IIC_DVI_Sda_pin_O : std_logic;
  signal fpga_0_IIC_DVI_Sda_pin_T : std_logic;
  signal fpga_0_IIC_EEPROM_Scl_pin_I : std_logic;
  signal fpga_0_IIC_EEPROM_Scl_pin_O : std_logic;
  signal fpga_0_IIC_EEPROM_Scl_pin_T : std_logic;
  signal fpga_0_IIC_EEPROM_Sda_pin_I : std_logic;
  signal fpga_0_IIC_EEPROM_Sda_pin_O : std_logic;
  signal fpga_0_IIC_EEPROM_Sda_pin_T : std_logic;
  signal fpga_0_IIC_FMC_LPC_Scl_pin_I : std_logic;
  signal fpga_0_IIC_FMC_LPC_Scl_pin_O : std_logic;
  signal fpga_0_IIC_FMC_LPC_Scl_pin_T : std_logic;
  signal fpga_0_IIC_FMC_LPC_Sda_pin_I : std_logic;
  signal fpga_0_IIC_FMC_LPC_Sda_pin_O : std_logic;
  signal fpga_0_IIC_FMC_LPC_Sda_pin_T : std_logic;
  signal fpga_0_IIC_SFP_Scl_pin_I : std_logic;
  signal fpga_0_IIC_SFP_Scl_pin_O : std_logic;
  signal fpga_0_IIC_SFP_Scl_pin_T : std_logic;
  signal fpga_0_IIC_SFP_Sda_pin_I : std_logic;
  signal fpga_0_IIC_SFP_Sda_pin_O : std_logic;
  signal fpga_0_IIC_SFP_Sda_pin_T : std_logic;
  signal fpga_0_LEDs_8Bit_GPIO_IO_pin_I : std_logic_vector(0 to 7);
  signal fpga_0_LEDs_8Bit_GPIO_IO_pin_O : std_logic_vector(0 to 7);
  signal fpga_0_LEDs_8Bit_GPIO_IO_pin_T : std_logic_vector(0 to 7);
  signal fpga_0_LEDs_Positions_GPIO_IO_pin_I : std_logic_vector(0 to 4);
  signal fpga_0_LEDs_Positions_GPIO_IO_pin_O : std_logic_vector(0 to 4);
  signal fpga_0_LEDs_Positions_GPIO_IO_pin_T : std_logic_vector(0 to 4);
  signal fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I : std_logic_vector(0 to 4);
  signal fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O : std_logic_vector(0 to 4);
  signal fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T : std_logic_vector(0 to 4);
  signal fsl_v20_0_FSL_Has_Data : std_logic;
  signal fsl_v20_0_FSL_M_Control : std_logic;
  signal fsl_v20_0_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_v20_0_FSL_M_Full : std_logic;
  signal fsl_v20_0_FSL_M_Write : std_logic;
  signal fsl_v20_0_FSL_S_Control : std_logic;
  signal fsl_v20_0_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_v20_0_FSL_S_Exists : std_logic;
  signal fsl_v20_0_FSL_S_Read : std_logic;
  signal fsl_v20_1_FSL_M_Control : std_logic;
  signal fsl_v20_1_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_v20_1_FSL_M_Full : std_logic;
  signal fsl_v20_1_FSL_M_Write : std_logic;
  signal fsl_v20_1_FSL_S_Control : std_logic;
  signal fsl_v20_1_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_v20_1_FSL_S_Exists : std_logic;
  signal fsl_v20_1_FSL_S_Read : std_logic;
  signal fsl_v20_2_FSL_Has_Data : std_logic;
  signal fsl_v20_2_FSL_M_Control : std_logic;
  signal fsl_v20_2_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_v20_2_FSL_M_Full : std_logic;
  signal fsl_v20_2_FSL_M_Write : std_logic;
  signal fsl_v20_2_FSL_S_Control : std_logic;
  signal fsl_v20_2_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_v20_2_FSL_S_Exists : std_logic;
  signal fsl_v20_2_FSL_S_Read : std_logic;
  signal fsl_v20_3_FSL_M_Control : std_logic;
  signal fsl_v20_3_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_v20_3_FSL_M_Full : std_logic;
  signal fsl_v20_3_FSL_M_Write : std_logic;
  signal fsl_v20_3_FSL_S_Control : std_logic;
  signal fsl_v20_3_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_v20_3_FSL_S_Exists : std_logic;
  signal fsl_v20_3_FSL_S_Read : std_logic;
  signal mb_plb_MPLB_Rst : std_logic_vector(0 to 2);
  signal mb_plb_M_ABort : std_logic_vector(0 to 2);
  signal mb_plb_M_ABus : std_logic_vector(0 to 95);
  signal mb_plb_M_BE : std_logic_vector(0 to 23);
  signal mb_plb_M_MSize : std_logic_vector(0 to 5);
  signal mb_plb_M_RNW : std_logic_vector(0 to 2);
  signal mb_plb_M_TAttribute : std_logic_vector(0 to 47);
  signal mb_plb_M_UABus : std_logic_vector(0 to 95);
  signal mb_plb_M_busLock : std_logic_vector(0 to 2);
  signal mb_plb_M_lockErr : std_logic_vector(0 to 2);
  signal mb_plb_M_priority : std_logic_vector(0 to 5);
  signal mb_plb_M_rdBurst : std_logic_vector(0 to 2);
  signal mb_plb_M_request : std_logic_vector(0 to 2);
  signal mb_plb_M_size : std_logic_vector(0 to 11);
  signal mb_plb_M_type : std_logic_vector(0 to 8);
  signal mb_plb_M_wrBurst : std_logic_vector(0 to 2);
  signal mb_plb_M_wrDBus : std_logic_vector(0 to 191);
  signal mb_plb_PLB_ABus : std_logic_vector(0 to 31);
  signal mb_plb_PLB_BE : std_logic_vector(0 to 7);
  signal mb_plb_PLB_MAddrAck : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MBusy : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MIRQ : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MRdBTerm : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MRdDAck : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MRdDBus : std_logic_vector(0 to 191);
  signal mb_plb_PLB_MRdErr : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MRdWdAddr : std_logic_vector(0 to 11);
  signal mb_plb_PLB_MRearbitrate : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MSSize : std_logic_vector(0 to 5);
  signal mb_plb_PLB_MSize : std_logic_vector(0 to 1);
  signal mb_plb_PLB_MTimeout : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MWrBTerm : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MWrDAck : std_logic_vector(0 to 2);
  signal mb_plb_PLB_MWrErr : std_logic_vector(0 to 2);
  signal mb_plb_PLB_PAValid : std_logic;
  signal mb_plb_PLB_RNW : std_logic;
  signal mb_plb_PLB_SAValid : std_logic;
  signal mb_plb_PLB_TAttribute : std_logic_vector(0 to 15);
  signal mb_plb_PLB_UABus : std_logic_vector(0 to 31);
  signal mb_plb_PLB_abort : std_logic;
  signal mb_plb_PLB_busLock : std_logic;
  signal mb_plb_PLB_lockErr : std_logic;
  signal mb_plb_PLB_masterID : std_logic_vector(0 to 1);
  signal mb_plb_PLB_rdBurst : std_logic;
  signal mb_plb_PLB_rdPendPri : std_logic_vector(0 to 1);
  signal mb_plb_PLB_rdPendReq : std_logic;
  signal mb_plb_PLB_rdPrim : std_logic_vector(0 to 13);
  signal mb_plb_PLB_reqPri : std_logic_vector(0 to 1);
  signal mb_plb_PLB_size : std_logic_vector(0 to 3);
  signal mb_plb_PLB_type : std_logic_vector(0 to 2);
  signal mb_plb_PLB_wrBurst : std_logic;
  signal mb_plb_PLB_wrDBus : std_logic_vector(0 to 63);
  signal mb_plb_PLB_wrPendPri : std_logic_vector(0 to 1);
  signal mb_plb_PLB_wrPendReq : std_logic;
  signal mb_plb_PLB_wrPrim : std_logic_vector(0 to 13);
  signal mb_plb_SPLB_Rst : std_logic_vector(0 to 13);
  signal mb_plb_Sl_MBusy : std_logic_vector(0 to 41);
  signal mb_plb_Sl_MIRQ : std_logic_vector(0 to 41);
  signal mb_plb_Sl_MRdErr : std_logic_vector(0 to 41);
  signal mb_plb_Sl_MWrErr : std_logic_vector(0 to 41);
  signal mb_plb_Sl_SSize : std_logic_vector(0 to 27);
  signal mb_plb_Sl_addrAck : std_logic_vector(0 to 13);
  signal mb_plb_Sl_rdBTerm : std_logic_vector(0 to 13);
  signal mb_plb_Sl_rdComp : std_logic_vector(0 to 13);
  signal mb_plb_Sl_rdDAck : std_logic_vector(0 to 13);
  signal mb_plb_Sl_rdDBus : std_logic_vector(0 to 895);
  signal mb_plb_Sl_rdWdAddr : std_logic_vector(0 to 55);
  signal mb_plb_Sl_rearbitrate : std_logic_vector(0 to 13);
  signal mb_plb_Sl_wait : std_logic_vector(0 to 13);
  signal mb_plb_Sl_wrBTerm : std_logic_vector(0 to 13);
  signal mb_plb_Sl_wrComp : std_logic_vector(0 to 13);
  signal mb_plb_Sl_wrDAck : std_logic_vector(0 to 13);
  signal mb_reset : std_logic;
  signal microblaze_0_DXCL_FSL_M_Clk : std_logic;
  signal microblaze_0_DXCL_FSL_M_Control : std_logic;
  signal microblaze_0_DXCL_FSL_M_Data : std_logic_vector(0 to 31);
  signal microblaze_0_DXCL_FSL_M_Full : std_logic;
  signal microblaze_0_DXCL_FSL_M_Write : std_logic;
  signal microblaze_0_DXCL_FSL_S_Clk : std_logic;
  signal microblaze_0_DXCL_FSL_S_Control : std_logic;
  signal microblaze_0_DXCL_FSL_S_Data : std_logic_vector(0 to 31);
  signal microblaze_0_DXCL_FSL_S_Exists : std_logic;
  signal microblaze_0_DXCL_FSL_S_Read : std_logic;
  signal microblaze_0_IXCL_FSL_M_Clk : std_logic;
  signal microblaze_0_IXCL_FSL_M_Control : std_logic;
  signal microblaze_0_IXCL_FSL_M_Data : std_logic_vector(0 to 31);
  signal microblaze_0_IXCL_FSL_M_Full : std_logic;
  signal microblaze_0_IXCL_FSL_M_Write : std_logic;
  signal microblaze_0_IXCL_FSL_S_Clk : std_logic;
  signal microblaze_0_IXCL_FSL_S_Control : std_logic;
  signal microblaze_0_IXCL_FSL_S_Data : std_logic_vector(0 to 31);
  signal microblaze_0_IXCL_FSL_S_Exists : std_logic;
  signal microblaze_0_IXCL_FSL_S_Read : std_logic;
  signal microblaze_0_Interrupt : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Capture : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Clk : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Reg_En : std_logic_vector(0 to 7);
  signal microblaze_0_mdm_bus_Dbg_Shift : std_logic;
  signal microblaze_0_mdm_bus_Dbg_TDI : std_logic;
  signal microblaze_0_mdm_bus_Dbg_TDO : std_logic;
  signal microblaze_0_mdm_bus_Dbg_Update : std_logic;
  signal microblaze_0_mdm_bus_Debug_Rst : std_logic;
  signal mmu_0_FAULT_ADDR : std_logic_vector(0 to 31);
  signal mmu_0_MEM_MFIFO32_FIFO32_M_Clk : std_logic;
  signal mmu_0_MEM_MFIFO32_FIFO32_M_Data : std_logic_vector(0 to 31);
  signal mmu_0_MEM_MFIFO32_FIFO32_M_Rem : std_logic_vector(0 to 15);
  signal mmu_0_MEM_MFIFO32_FIFO32_M_Wr : std_logic;
  signal mmu_0_MEM_SFIFO32_FIFO32_S_Clk : std_logic;
  signal mmu_0_MEM_SFIFO32_FIFO32_S_Data : std_logic_vector(0 to 31);
  signal mmu_0_MEM_SFIFO32_FIFO32_S_Fill : std_logic_vector(0 to 15);
  signal mmu_0_MEM_SFIFO32_FIFO32_S_Rd : std_logic;
  signal mmu_0_PAGE_FAULT : std_logic;
  signal net_gnd0 : std_logic;
  signal net_gnd1 : std_logic_vector(0 downto 0);
  signal net_gnd2 : std_logic_vector(1 downto 0);
  signal net_gnd3 : std_logic_vector(0 to 2);
  signal net_gnd4 : std_logic_vector(0 to 3);
  signal net_gnd6 : std_logic_vector(5 downto 0);
  signal net_gnd8 : std_logic_vector(0 to 7);
  signal net_gnd10 : std_logic_vector(0 to 9);
  signal net_gnd16 : std_logic_vector(0 to 15);
  signal net_gnd24 : std_logic_vector(7 to 30);
  signal net_gnd30 : std_logic_vector(29 downto 0);
  signal net_gnd32 : std_logic_vector(0 to 31);
  signal net_gnd36 : std_logic_vector(0 to 35);
  signal net_gnd64 : std_logic_vector(0 to 63);
  signal net_gnd128 : std_logic_vector(0 to 127);
  signal net_vcc0 : std_logic;
  signal net_vcc4 : std_logic_vector(0 to 3);
  signal pgassign1 : std_logic_vector(0 to 0);
  signal pgassign2 : std_logic_vector(0 to 0);
  signal pgassign3 : std_logic_vector(0 to 0);
  signal pgassign4 : std_logic_vector(0 to 0);
  signal pgassign5 : std_logic_vector(0 to 0);
  signal pgassign6 : std_logic_vector(0 to 0);
  signal pgassign7 : std_logic_vector(0 to 0);
  signal pgassign8 : std_logic_vector(0 to 0);
  signal pgassign9 : std_logic_vector(5 downto 0);
  signal proc_control_0_pgd : std_logic_vector(0 to 31);
  signal proc_control_0_reconos_reset : std_logic;
  signal proc_control_0_reset0 : std_logic;
  signal proc_control_0_retry : std_logic;
  signal sys_bus_reset : std_logic_vector(0 to 0);
  signal sys_periph_reset : std_logic_vector(0 to 0);
  signal sys_rst_s : std_logic;
  signal xps_timer_0_Interrupt : std_logic;

  attribute BUFFER_TYPE : STRING;
  attribute BOX_TYPE : STRING;
  attribute BUFFER_TYPE of fpga_0_Ethernet_MAC_PHY_tx_clk_pin : signal is "IBUF";
  attribute BUFFER_TYPE of fpga_0_Ethernet_MAC_PHY_rx_clk_pin : signal is "IBUF";
  attribute BOX_TYPE of microblaze_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of mb_plb_wrapper : component is "user_black_box";
  attribute BOX_TYPE of rs232_uart_1_wrapper : component is "user_black_box";
  attribute BOX_TYPE of leds_8bit_wrapper : component is "user_black_box";
  attribute BOX_TYPE of leds_positions_wrapper : component is "user_black_box";
  attribute BOX_TYPE of push_buttons_5bit_wrapper : component is "user_black_box";
  attribute BOX_TYPE of dip_switches_8bit_wrapper : component is "user_black_box";
  attribute BOX_TYPE of iic_eeprom_wrapper : component is "user_black_box";
  attribute BOX_TYPE of iic_fmc_lpc_wrapper : component is "user_black_box";
  attribute BOX_TYPE of iic_dvi_wrapper : component is "user_black_box";
  attribute BOX_TYPE of iic_sfp_wrapper : component is "user_black_box";
  attribute BOX_TYPE of ethernet_mac_wrapper : component is "user_black_box";
  attribute BOX_TYPE of ddr3_sdram_wrapper : component is "user_black_box";
  attribute BOX_TYPE of flash_ce_inverter_wrapper : component is "user_black_box";
  attribute BOX_TYPE of pcie_diff_clk_wrapper : component is "user_black_box";
  attribute BOX_TYPE of clock_generator_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of mdm_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of proc_sys_reset_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of xps_intc_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of xps_timer_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fsl_v20_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fsl_v20_1_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fsl_v20_2_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fsl_v20_3_wrapper : component is "user_black_box";
  attribute BOX_TYPE of proc_control_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of xps_mem_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fifo32_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of fifo32_1_wrapper : component is "user_black_box";
  attribute BOX_TYPE of hwt_memaccess_0_wrapper : component is "user_black_box";
  attribute BOX_TYPE of mmu_0_wrapper : component is "user_black_box";

begin

  -- Internal assignments

  sys_rst_s <= fpga_0_rst_1_sys_rst_pin;
  fpga_0_DDR3_SDRAM_DDR3_Clk_pin <= pgassign1(0);
  fpga_0_DDR3_SDRAM_DDR3_Clk_n_pin <= pgassign2(0);
  fpga_0_DDR3_SDRAM_DDR3_CE_pin <= pgassign3(0);
  fpga_0_DDR3_SDRAM_DDR3_CS_n_pin <= pgassign4(0);
  fpga_0_DDR3_SDRAM_DDR3_ODT_pin <= pgassign5(0);
  fpga_0_FLASH_CE_inverter_Res_pin <= pgassign6(0);
  pgassign7(0) <= fpga_0_PCIe_Diff_Clk_IBUF_DS_P_pin;
  pgassign8(0) <= fpga_0_PCIe_Diff_Clk_IBUF_DS_N_pin;
  pgassign9(5) <= fpga_0_Ethernet_MAC_MDINT_pin;
  pgassign9(4) <= xps_timer_0_Interrupt;
  pgassign9(3) <= RS232_Uart_1_Interrupt;
  pgassign9(2) <= Ethernet_MAC_IP2INTC_Irpt;
  pgassign9(1) <= fsl_v20_2_FSL_Has_Data;
  pgassign9(0) <= fsl_v20_0_FSL_Has_Data;
  net_gnd0 <= '0';
  net_gnd1(0 downto 0) <= B"0";
  net_gnd10(0 to 9) <= B"0000000000";
  net_gnd128(0 to 127) <= B"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
  net_gnd16(0 to 15) <= B"0000000000000000";
  net_gnd2(1 downto 0) <= B"00";
  net_gnd24(7 to 30) <= B"000000000000000000000000";
  fpga_0_FLASH_Mem_A_pin <= net_gnd24;
  net_gnd3(0 to 2) <= B"000";
  net_gnd30(29 downto 0) <= B"000000000000000000000000000000";
  net_gnd32(0 to 31) <= B"00000000000000000000000000000000";
  net_gnd36(0 to 35) <= B"000000000000000000000000000000000000";
  net_gnd4(0 to 3) <= B"0000";
  net_gnd6(5 downto 0) <= B"000000";
  net_gnd64(0 to 63) <= B"0000000000000000000000000000000000000000000000000000000000000000";
  net_gnd8(0 to 7) <= B"00000000";
  net_vcc0 <= '1';
  net_vcc4(0 to 3) <= B"1111";

  microblaze_0 : microblaze_0_wrapper
    port map (
      CLK => clk_100_0000MHzMMCM0,
      RESET => net_gnd0,
      MB_RESET => mb_reset,
      INTERRUPT => microblaze_0_Interrupt,
      EXT_BRK => Ext_BRK,
      EXT_NM_BRK => Ext_NM_BRK,
      DBG_STOP => net_gnd0,
      MB_Halted => open,
      MB_Error => open,
      INSTR => net_gnd32,
      IREADY => net_gnd0,
      IWAIT => net_gnd0,
      ICE => net_gnd0,
      IUE => net_gnd0,
      INSTR_ADDR => open,
      IFETCH => open,
      I_AS => open,
      IPLB_M_ABort => mb_plb_M_ABort(1),
      IPLB_M_ABus => mb_plb_M_ABus(32 to 63),
      IPLB_M_UABus => mb_plb_M_UABus(32 to 63),
      IPLB_M_BE => mb_plb_M_BE(8 to 15),
      IPLB_M_busLock => mb_plb_M_busLock(1),
      IPLB_M_lockErr => mb_plb_M_lockErr(1),
      IPLB_M_MSize => mb_plb_M_MSize(2 to 3),
      IPLB_M_priority => mb_plb_M_priority(2 to 3),
      IPLB_M_rdBurst => mb_plb_M_rdBurst(1),
      IPLB_M_request => mb_plb_M_request(1),
      IPLB_M_RNW => mb_plb_M_RNW(1),
      IPLB_M_size => mb_plb_M_size(4 to 7),
      IPLB_M_TAttribute => mb_plb_M_TAttribute(16 to 31),
      IPLB_M_type => mb_plb_M_type(3 to 5),
      IPLB_M_wrBurst => mb_plb_M_wrBurst(1),
      IPLB_M_wrDBus => mb_plb_M_wrDBus(64 to 127),
      IPLB_MBusy => mb_plb_PLB_MBusy(1),
      IPLB_MRdErr => mb_plb_PLB_MRdErr(1),
      IPLB_MWrErr => mb_plb_PLB_MWrErr(1),
      IPLB_MIRQ => mb_plb_PLB_MIRQ(1),
      IPLB_MWrBTerm => mb_plb_PLB_MWrBTerm(1),
      IPLB_MWrDAck => mb_plb_PLB_MWrDAck(1),
      IPLB_MAddrAck => mb_plb_PLB_MAddrAck(1),
      IPLB_MRdBTerm => mb_plb_PLB_MRdBTerm(1),
      IPLB_MRdDAck => mb_plb_PLB_MRdDAck(1),
      IPLB_MRdDBus => mb_plb_PLB_MRdDBus(64 to 127),
      IPLB_MRdWdAddr => mb_plb_PLB_MRdWdAddr(4 to 7),
      IPLB_MRearbitrate => mb_plb_PLB_MRearbitrate(1),
      IPLB_MSSize => mb_plb_PLB_MSSize(2 to 3),
      IPLB_MTimeout => mb_plb_PLB_MTimeout(1),
      DATA_READ => net_gnd32,
      DREADY => net_gnd0,
      DWAIT => net_gnd0,
      DCE => net_gnd0,
      DUE => net_gnd0,
      DATA_WRITE => open,
      DATA_ADDR => open,
      D_AS => open,
      READ_STROBE => open,
      WRITE_STROBE => open,
      BYTE_ENABLE => open,
      DPLB_M_ABort => mb_plb_M_ABort(0),
      DPLB_M_ABus => mb_plb_M_ABus(0 to 31),
      DPLB_M_UABus => mb_plb_M_UABus(0 to 31),
      DPLB_M_BE => mb_plb_M_BE(0 to 7),
      DPLB_M_busLock => mb_plb_M_busLock(0),
      DPLB_M_lockErr => mb_plb_M_lockErr(0),
      DPLB_M_MSize => mb_plb_M_MSize(0 to 1),
      DPLB_M_priority => mb_plb_M_priority(0 to 1),
      DPLB_M_rdBurst => mb_plb_M_rdBurst(0),
      DPLB_M_request => mb_plb_M_request(0),
      DPLB_M_RNW => mb_plb_M_RNW(0),
      DPLB_M_size => mb_plb_M_size(0 to 3),
      DPLB_M_TAttribute => mb_plb_M_TAttribute(0 to 15),
      DPLB_M_type => mb_plb_M_type(0 to 2),
      DPLB_M_wrBurst => mb_plb_M_wrBurst(0),
      DPLB_M_wrDBus => mb_plb_M_wrDBus(0 to 63),
      DPLB_MBusy => mb_plb_PLB_MBusy(0),
      DPLB_MRdErr => mb_plb_PLB_MRdErr(0),
      DPLB_MWrErr => mb_plb_PLB_MWrErr(0),
      DPLB_MIRQ => mb_plb_PLB_MIRQ(0),
      DPLB_MWrBTerm => mb_plb_PLB_MWrBTerm(0),
      DPLB_MWrDAck => mb_plb_PLB_MWrDAck(0),
      DPLB_MAddrAck => mb_plb_PLB_MAddrAck(0),
      DPLB_MRdBTerm => mb_plb_PLB_MRdBTerm(0),
      DPLB_MRdDAck => mb_plb_PLB_MRdDAck(0),
      DPLB_MRdDBus => mb_plb_PLB_MRdDBus(0 to 63),
      DPLB_MRdWdAddr => mb_plb_PLB_MRdWdAddr(0 to 3),
      DPLB_MRearbitrate => mb_plb_PLB_MRearbitrate(0),
      DPLB_MSSize => mb_plb_PLB_MSSize(0 to 1),
      DPLB_MTimeout => mb_plb_PLB_MTimeout(0),
      M_AXI_IP_AWID => open,
      M_AXI_IP_AWADDR => open,
      M_AXI_IP_AWLEN => open,
      M_AXI_IP_AWSIZE => open,
      M_AXI_IP_AWBURST => open,
      M_AXI_IP_AWLOCK => open,
      M_AXI_IP_AWCACHE => open,
      M_AXI_IP_AWPROT => open,
      M_AXI_IP_AWQOS => open,
      M_AXI_IP_AWVALID => open,
      M_AXI_IP_AWREADY => net_gnd0,
      M_AXI_IP_WDATA => open,
      M_AXI_IP_WSTRB => open,
      M_AXI_IP_WLAST => open,
      M_AXI_IP_WVALID => open,
      M_AXI_IP_WREADY => net_gnd0,
      M_AXI_IP_BID => net_gnd1(0 downto 0),
      M_AXI_IP_BRESP => net_gnd2,
      M_AXI_IP_BVALID => net_gnd0,
      M_AXI_IP_BREADY => open,
      M_AXI_IP_ARID => open,
      M_AXI_IP_ARADDR => open,
      M_AXI_IP_ARLEN => open,
      M_AXI_IP_ARSIZE => open,
      M_AXI_IP_ARBURST => open,
      M_AXI_IP_ARLOCK => open,
      M_AXI_IP_ARCACHE => open,
      M_AXI_IP_ARPROT => open,
      M_AXI_IP_ARQOS => open,
      M_AXI_IP_ARVALID => open,
      M_AXI_IP_ARREADY => net_gnd0,
      M_AXI_IP_RID => net_gnd1(0 downto 0),
      M_AXI_IP_RDATA => net_gnd32(0 to 31),
      M_AXI_IP_RRESP => net_gnd2,
      M_AXI_IP_RLAST => net_gnd0,
      M_AXI_IP_RVALID => net_gnd0,
      M_AXI_IP_RREADY => open,
      M_AXI_DP_AWID => open,
      M_AXI_DP_AWADDR => open,
      M_AXI_DP_AWLEN => open,
      M_AXI_DP_AWSIZE => open,
      M_AXI_DP_AWBURST => open,
      M_AXI_DP_AWLOCK => open,
      M_AXI_DP_AWCACHE => open,
      M_AXI_DP_AWPROT => open,
      M_AXI_DP_AWQOS => open,
      M_AXI_DP_AWVALID => open,
      M_AXI_DP_AWREADY => net_gnd0,
      M_AXI_DP_WDATA => open,
      M_AXI_DP_WSTRB => open,
      M_AXI_DP_WLAST => open,
      M_AXI_DP_WVALID => open,
      M_AXI_DP_WREADY => net_gnd0,
      M_AXI_DP_BID => net_gnd1(0 downto 0),
      M_AXI_DP_BRESP => net_gnd2,
      M_AXI_DP_BVALID => net_gnd0,
      M_AXI_DP_BREADY => open,
      M_AXI_DP_ARID => open,
      M_AXI_DP_ARADDR => open,
      M_AXI_DP_ARLEN => open,
      M_AXI_DP_ARSIZE => open,
      M_AXI_DP_ARBURST => open,
      M_AXI_DP_ARLOCK => open,
      M_AXI_DP_ARCACHE => open,
      M_AXI_DP_ARPROT => open,
      M_AXI_DP_ARQOS => open,
      M_AXI_DP_ARVALID => open,
      M_AXI_DP_ARREADY => net_gnd0,
      M_AXI_DP_RID => net_gnd1(0 downto 0),
      M_AXI_DP_RDATA => net_gnd32(0 to 31),
      M_AXI_DP_RRESP => net_gnd2,
      M_AXI_DP_RLAST => net_gnd0,
      M_AXI_DP_RVALID => net_gnd0,
      M_AXI_DP_RREADY => open,
      M_AXI_IC_AWID => open,
      M_AXI_IC_AWADDR => open,
      M_AXI_IC_AWLEN => open,
      M_AXI_IC_AWSIZE => open,
      M_AXI_IC_AWBURST => open,
      M_AXI_IC_AWLOCK => open,
      M_AXI_IC_AWCACHE => open,
      M_AXI_IC_AWPROT => open,
      M_AXI_IC_AWQOS => open,
      M_AXI_IC_AWVALID => open,
      M_AXI_IC_AWREADY => net_gnd0,
      M_AXI_IC_WDATA => open,
      M_AXI_IC_WSTRB => open,
      M_AXI_IC_WLAST => open,
      M_AXI_IC_WVALID => open,
      M_AXI_IC_WREADY => net_gnd0,
      M_AXI_IC_BID => net_gnd1(0 downto 0),
      M_AXI_IC_BRESP => net_gnd2,
      M_AXI_IC_BVALID => net_gnd0,
      M_AXI_IC_BREADY => open,
      M_AXI_IC_ARID => open,
      M_AXI_IC_ARADDR => open,
      M_AXI_IC_ARLEN => open,
      M_AXI_IC_ARSIZE => open,
      M_AXI_IC_ARBURST => open,
      M_AXI_IC_ARLOCK => open,
      M_AXI_IC_ARCACHE => open,
      M_AXI_IC_ARPROT => open,
      M_AXI_IC_ARQOS => open,
      M_AXI_IC_ARVALID => open,
      M_AXI_IC_ARREADY => net_gnd0,
      M_AXI_IC_RID => net_gnd1(0 downto 0),
      M_AXI_IC_RDATA => net_gnd32(0 to 31),
      M_AXI_IC_RRESP => net_gnd2,
      M_AXI_IC_RLAST => net_gnd0,
      M_AXI_IC_RVALID => net_gnd0,
      M_AXI_IC_RREADY => open,
      M_AXI_DC_AWID => open,
      M_AXI_DC_AWADDR => open,
      M_AXI_DC_AWLEN => open,
      M_AXI_DC_AWSIZE => open,
      M_AXI_DC_AWBURST => open,
      M_AXI_DC_AWLOCK => open,
      M_AXI_DC_AWCACHE => open,
      M_AXI_DC_AWPROT => open,
      M_AXI_DC_AWQOS => open,
      M_AXI_DC_AWVALID => open,
      M_AXI_DC_AWREADY => net_gnd0,
      M_AXI_DC_WDATA => open,
      M_AXI_DC_WSTRB => open,
      M_AXI_DC_WLAST => open,
      M_AXI_DC_WVALID => open,
      M_AXI_DC_WREADY => net_gnd0,
      M_AXI_DC_BID => net_gnd1(0 downto 0),
      M_AXI_DC_BRESP => net_gnd2,
      M_AXI_DC_BVALID => net_gnd0,
      M_AXI_DC_BREADY => open,
      M_AXI_DC_ARID => open,
      M_AXI_DC_ARADDR => open,
      M_AXI_DC_ARLEN => open,
      M_AXI_DC_ARSIZE => open,
      M_AXI_DC_ARBURST => open,
      M_AXI_DC_ARLOCK => open,
      M_AXI_DC_ARCACHE => open,
      M_AXI_DC_ARPROT => open,
      M_AXI_DC_ARQOS => open,
      M_AXI_DC_ARVALID => open,
      M_AXI_DC_ARREADY => net_gnd0,
      M_AXI_DC_RID => net_gnd1(0 downto 0),
      M_AXI_DC_RDATA => net_gnd32(0 to 31),
      M_AXI_DC_RRESP => net_gnd2,
      M_AXI_DC_RLAST => net_gnd0,
      M_AXI_DC_RVALID => net_gnd0,
      M_AXI_DC_RREADY => open,
      DBG_CLK => microblaze_0_mdm_bus_Dbg_Clk,
      DBG_TDI => microblaze_0_mdm_bus_Dbg_TDI,
      DBG_TDO => microblaze_0_mdm_bus_Dbg_TDO,
      DBG_REG_EN => microblaze_0_mdm_bus_Dbg_Reg_En,
      DBG_SHIFT => microblaze_0_mdm_bus_Dbg_Shift,
      DBG_CAPTURE => microblaze_0_mdm_bus_Dbg_Capture,
      DBG_UPDATE => microblaze_0_mdm_bus_Dbg_Update,
      DEBUG_RST => microblaze_0_mdm_bus_Debug_Rst,
      Trace_Instruction => open,
      Trace_Valid_Instr => open,
      Trace_PC => open,
      Trace_Reg_Write => open,
      Trace_Reg_Addr => open,
      Trace_MSR_Reg => open,
      Trace_PID_Reg => open,
      Trace_New_Reg_Value => open,
      Trace_Exception_Taken => open,
      Trace_Exception_Kind => open,
      Trace_Jump_Taken => open,
      Trace_Delay_Slot => open,
      Trace_Data_Address => open,
      Trace_Data_Access => open,
      Trace_Data_Read => open,
      Trace_Data_Write => open,
      Trace_Data_Write_Value => open,
      Trace_Data_Byte_Enable => open,
      Trace_DCache_Req => open,
      Trace_DCache_Hit => open,
      Trace_DCache_Rdy => open,
      Trace_DCache_Read => open,
      Trace_ICache_Req => open,
      Trace_ICache_Hit => open,
      Trace_ICache_Rdy => open,
      Trace_OF_PipeRun => open,
      Trace_EX_PipeRun => open,
      Trace_MEM_PipeRun => open,
      Trace_MB_Halted => open,
      Trace_Jump_Hit => open,
      FSL0_S_CLK => open,
      FSL0_S_READ => fsl_v20_0_FSL_S_Read,
      FSL0_S_DATA => fsl_v20_0_FSL_S_Data,
      FSL0_S_CONTROL => fsl_v20_0_FSL_S_Control,
      FSL0_S_EXISTS => fsl_v20_0_FSL_S_Exists,
      FSL0_M_CLK => open,
      FSL0_M_WRITE => fsl_v20_1_FSL_M_Write,
      FSL0_M_DATA => fsl_v20_1_FSL_M_Data,
      FSL0_M_CONTROL => fsl_v20_1_FSL_M_Control,
      FSL0_M_FULL => fsl_v20_1_FSL_M_Full,
      FSL1_S_CLK => open,
      FSL1_S_READ => fsl_v20_2_FSL_S_Read,
      FSL1_S_DATA => fsl_v20_2_FSL_S_Data,
      FSL1_S_CONTROL => fsl_v20_2_FSL_S_Control,
      FSL1_S_EXISTS => fsl_v20_2_FSL_S_Exists,
      FSL1_M_CLK => open,
      FSL1_M_WRITE => fsl_v20_3_FSL_M_Write,
      FSL1_M_DATA => fsl_v20_3_FSL_M_Data,
      FSL1_M_CONTROL => fsl_v20_3_FSL_M_Control,
      FSL1_M_FULL => fsl_v20_3_FSL_M_Full,
      FSL2_S_CLK => open,
      FSL2_S_READ => open,
      FSL2_S_DATA => net_gnd32,
      FSL2_S_CONTROL => net_gnd0,
      FSL2_S_EXISTS => net_gnd0,
      FSL2_M_CLK => open,
      FSL2_M_WRITE => open,
      FSL2_M_DATA => open,
      FSL2_M_CONTROL => open,
      FSL2_M_FULL => net_gnd0,
      FSL3_S_CLK => open,
      FSL3_S_READ => open,
      FSL3_S_DATA => net_gnd32,
      FSL3_S_CONTROL => net_gnd0,
      FSL3_S_EXISTS => net_gnd0,
      FSL3_M_CLK => open,
      FSL3_M_WRITE => open,
      FSL3_M_DATA => open,
      FSL3_M_CONTROL => open,
      FSL3_M_FULL => net_gnd0,
      FSL4_S_CLK => open,
      FSL4_S_READ => open,
      FSL4_S_DATA => net_gnd32,
      FSL4_S_CONTROL => net_gnd0,
      FSL4_S_EXISTS => net_gnd0,
      FSL4_M_CLK => open,
      FSL4_M_WRITE => open,
      FSL4_M_DATA => open,
      FSL4_M_CONTROL => open,
      FSL4_M_FULL => net_gnd0,
      FSL5_S_CLK => open,
      FSL5_S_READ => open,
      FSL5_S_DATA => net_gnd32,
      FSL5_S_CONTROL => net_gnd0,
      FSL5_S_EXISTS => net_gnd0,
      FSL5_M_CLK => open,
      FSL5_M_WRITE => open,
      FSL5_M_DATA => open,
      FSL5_M_CONTROL => open,
      FSL5_M_FULL => net_gnd0,
      FSL6_S_CLK => open,
      FSL6_S_READ => open,
      FSL6_S_DATA => net_gnd32,
      FSL6_S_CONTROL => net_gnd0,
      FSL6_S_EXISTS => net_gnd0,
      FSL6_M_CLK => open,
      FSL6_M_WRITE => open,
      FSL6_M_DATA => open,
      FSL6_M_CONTROL => open,
      FSL6_M_FULL => net_gnd0,
      FSL7_S_CLK => open,
      FSL7_S_READ => open,
      FSL7_S_DATA => net_gnd32,
      FSL7_S_CONTROL => net_gnd0,
      FSL7_S_EXISTS => net_gnd0,
      FSL7_M_CLK => open,
      FSL7_M_WRITE => open,
      FSL7_M_DATA => open,
      FSL7_M_CONTROL => open,
      FSL7_M_FULL => net_gnd0,
      FSL8_S_CLK => open,
      FSL8_S_READ => open,
      FSL8_S_DATA => net_gnd32,
      FSL8_S_CONTROL => net_gnd0,
      FSL8_S_EXISTS => net_gnd0,
      FSL8_M_CLK => open,
      FSL8_M_WRITE => open,
      FSL8_M_DATA => open,
      FSL8_M_CONTROL => open,
      FSL8_M_FULL => net_gnd0,
      FSL9_S_CLK => open,
      FSL9_S_READ => open,
      FSL9_S_DATA => net_gnd32,
      FSL9_S_CONTROL => net_gnd0,
      FSL9_S_EXISTS => net_gnd0,
      FSL9_M_CLK => open,
      FSL9_M_WRITE => open,
      FSL9_M_DATA => open,
      FSL9_M_CONTROL => open,
      FSL9_M_FULL => net_gnd0,
      FSL10_S_CLK => open,
      FSL10_S_READ => open,
      FSL10_S_DATA => net_gnd32,
      FSL10_S_CONTROL => net_gnd0,
      FSL10_S_EXISTS => net_gnd0,
      FSL10_M_CLK => open,
      FSL10_M_WRITE => open,
      FSL10_M_DATA => open,
      FSL10_M_CONTROL => open,
      FSL10_M_FULL => net_gnd0,
      FSL11_S_CLK => open,
      FSL11_S_READ => open,
      FSL11_S_DATA => net_gnd32,
      FSL11_S_CONTROL => net_gnd0,
      FSL11_S_EXISTS => net_gnd0,
      FSL11_M_CLK => open,
      FSL11_M_WRITE => open,
      FSL11_M_DATA => open,
      FSL11_M_CONTROL => open,
      FSL11_M_FULL => net_gnd0,
      FSL12_S_CLK => open,
      FSL12_S_READ => open,
      FSL12_S_DATA => net_gnd32,
      FSL12_S_CONTROL => net_gnd0,
      FSL12_S_EXISTS => net_gnd0,
      FSL12_M_CLK => open,
      FSL12_M_WRITE => open,
      FSL12_M_DATA => open,
      FSL12_M_CONTROL => open,
      FSL12_M_FULL => net_gnd0,
      FSL13_S_CLK => open,
      FSL13_S_READ => open,
      FSL13_S_DATA => net_gnd32,
      FSL13_S_CONTROL => net_gnd0,
      FSL13_S_EXISTS => net_gnd0,
      FSL13_M_CLK => open,
      FSL13_M_WRITE => open,
      FSL13_M_DATA => open,
      FSL13_M_CONTROL => open,
      FSL13_M_FULL => net_gnd0,
      FSL14_S_CLK => open,
      FSL14_S_READ => open,
      FSL14_S_DATA => net_gnd32,
      FSL14_S_CONTROL => net_gnd0,
      FSL14_S_EXISTS => net_gnd0,
      FSL14_M_CLK => open,
      FSL14_M_WRITE => open,
      FSL14_M_DATA => open,
      FSL14_M_CONTROL => open,
      FSL14_M_FULL => net_gnd0,
      FSL15_S_CLK => open,
      FSL15_S_READ => open,
      FSL15_S_DATA => net_gnd32,
      FSL15_S_CONTROL => net_gnd0,
      FSL15_S_EXISTS => net_gnd0,
      FSL15_M_CLK => open,
      FSL15_M_WRITE => open,
      FSL15_M_DATA => open,
      FSL15_M_CONTROL => open,
      FSL15_M_FULL => net_gnd0,
      M0_AXIS_TLAST => open,
      M0_AXIS_TDATA => open,
      M0_AXIS_TVALID => open,
      M0_AXIS_TREADY => net_gnd0,
      S0_AXIS_TLAST => net_gnd0,
      S0_AXIS_TDATA => net_gnd32(0 to 31),
      S0_AXIS_TVALID => net_gnd0,
      S0_AXIS_TREADY => open,
      M1_AXIS_TLAST => open,
      M1_AXIS_TDATA => open,
      M1_AXIS_TVALID => open,
      M1_AXIS_TREADY => net_gnd0,
      S1_AXIS_TLAST => net_gnd0,
      S1_AXIS_TDATA => net_gnd32(0 to 31),
      S1_AXIS_TVALID => net_gnd0,
      S1_AXIS_TREADY => open,
      M2_AXIS_TLAST => open,
      M2_AXIS_TDATA => open,
      M2_AXIS_TVALID => open,
      M2_AXIS_TREADY => net_gnd0,
      S2_AXIS_TLAST => net_gnd0,
      S2_AXIS_TDATA => net_gnd32(0 to 31),
      S2_AXIS_TVALID => net_gnd0,
      S2_AXIS_TREADY => open,
      M3_AXIS_TLAST => open,
      M3_AXIS_TDATA => open,
      M3_AXIS_TVALID => open,
      M3_AXIS_TREADY => net_gnd0,
      S3_AXIS_TLAST => net_gnd0,
      S3_AXIS_TDATA => net_gnd32(0 to 31),
      S3_AXIS_TVALID => net_gnd0,
      S3_AXIS_TREADY => open,
      M4_AXIS_TLAST => open,
      M4_AXIS_TDATA => open,
      M4_AXIS_TVALID => open,
      M4_AXIS_TREADY => net_gnd0,
      S4_AXIS_TLAST => net_gnd0,
      S4_AXIS_TDATA => net_gnd32(0 to 31),
      S4_AXIS_TVALID => net_gnd0,
      S4_AXIS_TREADY => open,
      M5_AXIS_TLAST => open,
      M5_AXIS_TDATA => open,
      M5_AXIS_TVALID => open,
      M5_AXIS_TREADY => net_gnd0,
      S5_AXIS_TLAST => net_gnd0,
      S5_AXIS_TDATA => net_gnd32(0 to 31),
      S5_AXIS_TVALID => net_gnd0,
      S5_AXIS_TREADY => open,
      M6_AXIS_TLAST => open,
      M6_AXIS_TDATA => open,
      M6_AXIS_TVALID => open,
      M6_AXIS_TREADY => net_gnd0,
      S6_AXIS_TLAST => net_gnd0,
      S6_AXIS_TDATA => net_gnd32(0 to 31),
      S6_AXIS_TVALID => net_gnd0,
      S6_AXIS_TREADY => open,
      M7_AXIS_TLAST => open,
      M7_AXIS_TDATA => open,
      M7_AXIS_TVALID => open,
      M7_AXIS_TREADY => net_gnd0,
      S7_AXIS_TLAST => net_gnd0,
      S7_AXIS_TDATA => net_gnd32(0 to 31),
      S7_AXIS_TVALID => net_gnd0,
      S7_AXIS_TREADY => open,
      M8_AXIS_TLAST => open,
      M8_AXIS_TDATA => open,
      M8_AXIS_TVALID => open,
      M8_AXIS_TREADY => net_gnd0,
      S8_AXIS_TLAST => net_gnd0,
      S8_AXIS_TDATA => net_gnd32(0 to 31),
      S8_AXIS_TVALID => net_gnd0,
      S8_AXIS_TREADY => open,
      M9_AXIS_TLAST => open,
      M9_AXIS_TDATA => open,
      M9_AXIS_TVALID => open,
      M9_AXIS_TREADY => net_gnd0,
      S9_AXIS_TLAST => net_gnd0,
      S9_AXIS_TDATA => net_gnd32(0 to 31),
      S9_AXIS_TVALID => net_gnd0,
      S9_AXIS_TREADY => open,
      M10_AXIS_TLAST => open,
      M10_AXIS_TDATA => open,
      M10_AXIS_TVALID => open,
      M10_AXIS_TREADY => net_gnd0,
      S10_AXIS_TLAST => net_gnd0,
      S10_AXIS_TDATA => net_gnd32(0 to 31),
      S10_AXIS_TVALID => net_gnd0,
      S10_AXIS_TREADY => open,
      M11_AXIS_TLAST => open,
      M11_AXIS_TDATA => open,
      M11_AXIS_TVALID => open,
      M11_AXIS_TREADY => net_gnd0,
      S11_AXIS_TLAST => net_gnd0,
      S11_AXIS_TDATA => net_gnd32(0 to 31),
      S11_AXIS_TVALID => net_gnd0,
      S11_AXIS_TREADY => open,
      M12_AXIS_TLAST => open,
      M12_AXIS_TDATA => open,
      M12_AXIS_TVALID => open,
      M12_AXIS_TREADY => net_gnd0,
      S12_AXIS_TLAST => net_gnd0,
      S12_AXIS_TDATA => net_gnd32(0 to 31),
      S12_AXIS_TVALID => net_gnd0,
      S12_AXIS_TREADY => open,
      M13_AXIS_TLAST => open,
      M13_AXIS_TDATA => open,
      M13_AXIS_TVALID => open,
      M13_AXIS_TREADY => net_gnd0,
      S13_AXIS_TLAST => net_gnd0,
      S13_AXIS_TDATA => net_gnd32(0 to 31),
      S13_AXIS_TVALID => net_gnd0,
      S13_AXIS_TREADY => open,
      M14_AXIS_TLAST => open,
      M14_AXIS_TDATA => open,
      M14_AXIS_TVALID => open,
      M14_AXIS_TREADY => net_gnd0,
      S14_AXIS_TLAST => net_gnd0,
      S14_AXIS_TDATA => net_gnd32(0 to 31),
      S14_AXIS_TVALID => net_gnd0,
      S14_AXIS_TREADY => open,
      M15_AXIS_TLAST => open,
      M15_AXIS_TDATA => open,
      M15_AXIS_TVALID => open,
      M15_AXIS_TREADY => net_gnd0,
      S15_AXIS_TLAST => net_gnd0,
      S15_AXIS_TDATA => net_gnd32(0 to 31),
      S15_AXIS_TVALID => net_gnd0,
      S15_AXIS_TREADY => open,
      ICACHE_FSL_IN_CLK => microblaze_0_IXCL_FSL_S_Clk,
      ICACHE_FSL_IN_READ => microblaze_0_IXCL_FSL_S_Read,
      ICACHE_FSL_IN_DATA => microblaze_0_IXCL_FSL_S_Data,
      ICACHE_FSL_IN_CONTROL => microblaze_0_IXCL_FSL_S_Control,
      ICACHE_FSL_IN_EXISTS => microblaze_0_IXCL_FSL_S_Exists,
      ICACHE_FSL_OUT_CLK => microblaze_0_IXCL_FSL_M_Clk,
      ICACHE_FSL_OUT_WRITE => microblaze_0_IXCL_FSL_M_Write,
      ICACHE_FSL_OUT_DATA => microblaze_0_IXCL_FSL_M_Data,
      ICACHE_FSL_OUT_CONTROL => microblaze_0_IXCL_FSL_M_Control,
      ICACHE_FSL_OUT_FULL => microblaze_0_IXCL_FSL_M_Full,
      DCACHE_FSL_IN_CLK => microblaze_0_DXCL_FSL_S_Clk,
      DCACHE_FSL_IN_READ => microblaze_0_DXCL_FSL_S_Read,
      DCACHE_FSL_IN_DATA => microblaze_0_DXCL_FSL_S_Data,
      DCACHE_FSL_IN_CONTROL => microblaze_0_DXCL_FSL_S_Control,
      DCACHE_FSL_IN_EXISTS => microblaze_0_DXCL_FSL_S_Exists,
      DCACHE_FSL_OUT_CLK => microblaze_0_DXCL_FSL_M_Clk,
      DCACHE_FSL_OUT_WRITE => microblaze_0_DXCL_FSL_M_Write,
      DCACHE_FSL_OUT_DATA => microblaze_0_DXCL_FSL_M_Data,
      DCACHE_FSL_OUT_CONTROL => microblaze_0_DXCL_FSL_M_Control,
      DCACHE_FSL_OUT_FULL => microblaze_0_DXCL_FSL_M_Full
    );

  mb_plb : mb_plb_wrapper
    port map (
      PLB_Clk => clk_100_0000MHzMMCM0,
      SYS_Rst => sys_bus_reset(0),
      PLB_Rst => open,
      SPLB_Rst => mb_plb_SPLB_Rst,
      MPLB_Rst => mb_plb_MPLB_Rst,
      PLB_dcrAck => open,
      PLB_dcrDBus => open,
      DCR_ABus => net_gnd10,
      DCR_DBus => net_gnd32,
      DCR_Read => net_gnd0,
      DCR_Write => net_gnd0,
      M_ABus => mb_plb_M_ABus,
      M_UABus => mb_plb_M_UABus,
      M_BE => mb_plb_M_BE,
      M_RNW => mb_plb_M_RNW,
      M_abort => mb_plb_M_ABort,
      M_busLock => mb_plb_M_busLock,
      M_TAttribute => mb_plb_M_TAttribute,
      M_lockErr => mb_plb_M_lockErr,
      M_MSize => mb_plb_M_MSize,
      M_priority => mb_plb_M_priority,
      M_rdBurst => mb_plb_M_rdBurst,
      M_request => mb_plb_M_request,
      M_size => mb_plb_M_size,
      M_type => mb_plb_M_type,
      M_wrBurst => mb_plb_M_wrBurst,
      M_wrDBus => mb_plb_M_wrDBus,
      Sl_addrAck => mb_plb_Sl_addrAck,
      Sl_MRdErr => mb_plb_Sl_MRdErr,
      Sl_MWrErr => mb_plb_Sl_MWrErr,
      Sl_MBusy => mb_plb_Sl_MBusy,
      Sl_rdBTerm => mb_plb_Sl_rdBTerm,
      Sl_rdComp => mb_plb_Sl_rdComp,
      Sl_rdDAck => mb_plb_Sl_rdDAck,
      Sl_rdDBus => mb_plb_Sl_rdDBus,
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr,
      Sl_rearbitrate => mb_plb_Sl_rearbitrate,
      Sl_SSize => mb_plb_Sl_SSize,
      Sl_wait => mb_plb_Sl_wait,
      Sl_wrBTerm => mb_plb_Sl_wrBTerm,
      Sl_wrComp => mb_plb_Sl_wrComp,
      Sl_wrDAck => mb_plb_Sl_wrDAck,
      Sl_MIRQ => mb_plb_Sl_MIRQ,
      PLB_MIRQ => mb_plb_PLB_MIRQ,
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MAddrAck => mb_plb_PLB_MAddrAck,
      PLB_MTimeout => mb_plb_PLB_MTimeout,
      PLB_MBusy => mb_plb_PLB_MBusy,
      PLB_MRdErr => mb_plb_PLB_MRdErr,
      PLB_MWrErr => mb_plb_PLB_MWrErr,
      PLB_MRdBTerm => mb_plb_PLB_MRdBTerm,
      PLB_MRdDAck => mb_plb_PLB_MRdDAck,
      PLB_MRdDBus => mb_plb_PLB_MRdDBus,
      PLB_MRdWdAddr => mb_plb_PLB_MRdWdAddr,
      PLB_MRearbitrate => mb_plb_PLB_MRearbitrate,
      PLB_MWrBTerm => mb_plb_PLB_MWrBTerm,
      PLB_MWrDAck => mb_plb_PLB_MWrDAck,
      PLB_MSSize => mb_plb_PLB_MSSize,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_rdPrim => mb_plb_PLB_rdPrim,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrPrim => mb_plb_PLB_wrPrim,
      PLB_SaddrAck => open,
      PLB_SMRdErr => open,
      PLB_SMWrErr => open,
      PLB_SMBusy => open,
      PLB_SrdBTerm => open,
      PLB_SrdComp => open,
      PLB_SrdDAck => open,
      PLB_SrdDBus => open,
      PLB_SrdWdAddr => open,
      PLB_Srearbitrate => open,
      PLB_Sssize => open,
      PLB_Swait => open,
      PLB_SwrBTerm => open,
      PLB_SwrComp => open,
      PLB_SwrDAck => open,
      Bus_Error_Det => open
    );

  RS232_Uart_1 : rs232_uart_1_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(0),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(0),
      PLB_wrPrim => mb_plb_PLB_wrPrim(0),
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(0),
      Sl_SSize => mb_plb_Sl_SSize(0 to 1),
      Sl_wait => mb_plb_Sl_wait(0),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(0),
      Sl_wrDAck => mb_plb_Sl_wrDAck(0),
      Sl_wrComp => mb_plb_Sl_wrComp(0),
      Sl_rdDBus => mb_plb_Sl_rdDBus(0 to 63),
      Sl_rdDAck => mb_plb_Sl_rdDAck(0),
      Sl_rdComp => mb_plb_Sl_rdComp(0),
      Sl_MBusy => mb_plb_Sl_MBusy(0 to 2),
      Sl_MWrErr => mb_plb_Sl_MWrErr(0 to 2),
      Sl_MRdErr => mb_plb_Sl_MRdErr(0 to 2),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(0),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(0 to 3),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(0),
      Sl_MIRQ => mb_plb_Sl_MIRQ(0 to 2),
      RX => fpga_0_RS232_Uart_1_RX_pin,
      TX => fpga_0_RS232_Uart_1_TX_pin,
      Interrupt => RS232_Uart_1_Interrupt
    );

  LEDs_8Bit : leds_8bit_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(1),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(1),
      PLB_wrPrim => mb_plb_PLB_wrPrim(1),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(1),
      Sl_SSize => mb_plb_Sl_SSize(2 to 3),
      Sl_wait => mb_plb_Sl_wait(1),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(1),
      Sl_wrDAck => mb_plb_Sl_wrDAck(1),
      Sl_wrComp => mb_plb_Sl_wrComp(1),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(1),
      Sl_rdDBus => mb_plb_Sl_rdDBus(64 to 127),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(4 to 7),
      Sl_rdDAck => mb_plb_Sl_rdDAck(1),
      Sl_rdComp => mb_plb_Sl_rdComp(1),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(1),
      Sl_MBusy => mb_plb_Sl_MBusy(3 to 5),
      Sl_MWrErr => mb_plb_Sl_MWrErr(3 to 5),
      Sl_MRdErr => mb_plb_Sl_MRdErr(3 to 5),
      Sl_MIRQ => mb_plb_Sl_MIRQ(3 to 5),
      IP2INTC_Irpt => open,
      GPIO_IO_I => fpga_0_LEDs_8Bit_GPIO_IO_pin_I,
      GPIO_IO_O => fpga_0_LEDs_8Bit_GPIO_IO_pin_O,
      GPIO_IO_T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T,
      GPIO2_IO_I => net_gnd32,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  LEDs_Positions : leds_positions_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(2),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(2),
      PLB_wrPrim => mb_plb_PLB_wrPrim(2),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(2),
      Sl_SSize => mb_plb_Sl_SSize(4 to 5),
      Sl_wait => mb_plb_Sl_wait(2),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(2),
      Sl_wrDAck => mb_plb_Sl_wrDAck(2),
      Sl_wrComp => mb_plb_Sl_wrComp(2),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(2),
      Sl_rdDBus => mb_plb_Sl_rdDBus(128 to 191),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(8 to 11),
      Sl_rdDAck => mb_plb_Sl_rdDAck(2),
      Sl_rdComp => mb_plb_Sl_rdComp(2),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(2),
      Sl_MBusy => mb_plb_Sl_MBusy(6 to 8),
      Sl_MWrErr => mb_plb_Sl_MWrErr(6 to 8),
      Sl_MRdErr => mb_plb_Sl_MRdErr(6 to 8),
      Sl_MIRQ => mb_plb_Sl_MIRQ(6 to 8),
      IP2INTC_Irpt => open,
      GPIO_IO_I => fpga_0_LEDs_Positions_GPIO_IO_pin_I,
      GPIO_IO_O => fpga_0_LEDs_Positions_GPIO_IO_pin_O,
      GPIO_IO_T => fpga_0_LEDs_Positions_GPIO_IO_pin_T,
      GPIO2_IO_I => net_gnd32,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  Push_Buttons_5Bit : push_buttons_5bit_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(3),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(3),
      PLB_wrPrim => mb_plb_PLB_wrPrim(3),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(3),
      Sl_SSize => mb_plb_Sl_SSize(6 to 7),
      Sl_wait => mb_plb_Sl_wait(3),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(3),
      Sl_wrDAck => mb_plb_Sl_wrDAck(3),
      Sl_wrComp => mb_plb_Sl_wrComp(3),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(3),
      Sl_rdDBus => mb_plb_Sl_rdDBus(192 to 255),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(12 to 15),
      Sl_rdDAck => mb_plb_Sl_rdDAck(3),
      Sl_rdComp => mb_plb_Sl_rdComp(3),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(3),
      Sl_MBusy => mb_plb_Sl_MBusy(9 to 11),
      Sl_MWrErr => mb_plb_Sl_MWrErr(9 to 11),
      Sl_MRdErr => mb_plb_Sl_MRdErr(9 to 11),
      Sl_MIRQ => mb_plb_Sl_MIRQ(9 to 11),
      IP2INTC_Irpt => open,
      GPIO_IO_I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I,
      GPIO_IO_O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O,
      GPIO_IO_T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T,
      GPIO2_IO_I => net_gnd32,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  DIP_Switches_8Bit : dip_switches_8bit_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(4),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(4),
      PLB_wrPrim => mb_plb_PLB_wrPrim(4),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(4),
      Sl_SSize => mb_plb_Sl_SSize(8 to 9),
      Sl_wait => mb_plb_Sl_wait(4),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(4),
      Sl_wrDAck => mb_plb_Sl_wrDAck(4),
      Sl_wrComp => mb_plb_Sl_wrComp(4),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(4),
      Sl_rdDBus => mb_plb_Sl_rdDBus(256 to 319),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(16 to 19),
      Sl_rdDAck => mb_plb_Sl_rdDAck(4),
      Sl_rdComp => mb_plb_Sl_rdComp(4),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(4),
      Sl_MBusy => mb_plb_Sl_MBusy(12 to 14),
      Sl_MWrErr => mb_plb_Sl_MWrErr(12 to 14),
      Sl_MRdErr => mb_plb_Sl_MRdErr(12 to 14),
      Sl_MIRQ => mb_plb_Sl_MIRQ(12 to 14),
      IP2INTC_Irpt => open,
      GPIO_IO_I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I,
      GPIO_IO_O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O,
      GPIO_IO_T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T,
      GPIO2_IO_I => net_gnd32,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  IIC_EEPROM : iic_eeprom_wrapper
    port map (
      Sda_I => fpga_0_IIC_EEPROM_Sda_pin_I,
      Sda_O => fpga_0_IIC_EEPROM_Sda_pin_O,
      Sda_T => fpga_0_IIC_EEPROM_Sda_pin_T,
      Scl_I => fpga_0_IIC_EEPROM_Scl_pin_I,
      Scl_O => fpga_0_IIC_EEPROM_Scl_pin_O,
      Scl_T => fpga_0_IIC_EEPROM_Scl_pin_T,
      Gpo => open,
      IIC2INTC_Irpt => open,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(5),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(5),
      PLB_wrPrim => mb_plb_PLB_wrPrim(5),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(5),
      Sl_SSize => mb_plb_Sl_SSize(10 to 11),
      Sl_wait => mb_plb_Sl_wait(5),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(5),
      Sl_wrDAck => mb_plb_Sl_wrDAck(5),
      Sl_wrComp => mb_plb_Sl_wrComp(5),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(5),
      Sl_rdDBus => mb_plb_Sl_rdDBus(320 to 383),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(20 to 23),
      Sl_rdDAck => mb_plb_Sl_rdDAck(5),
      Sl_rdComp => mb_plb_Sl_rdComp(5),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(5),
      Sl_MBusy => mb_plb_Sl_MBusy(15 to 17),
      Sl_MWrErr => mb_plb_Sl_MWrErr(15 to 17),
      Sl_MRdErr => mb_plb_Sl_MRdErr(15 to 17),
      Sl_MIRQ => mb_plb_Sl_MIRQ(15 to 17)
    );

  IIC_FMC_LPC : iic_fmc_lpc_wrapper
    port map (
      Sda_I => fpga_0_IIC_FMC_LPC_Sda_pin_I,
      Sda_O => fpga_0_IIC_FMC_LPC_Sda_pin_O,
      Sda_T => fpga_0_IIC_FMC_LPC_Sda_pin_T,
      Scl_I => fpga_0_IIC_FMC_LPC_Scl_pin_I,
      Scl_O => fpga_0_IIC_FMC_LPC_Scl_pin_O,
      Scl_T => fpga_0_IIC_FMC_LPC_Scl_pin_T,
      Gpo => open,
      IIC2INTC_Irpt => open,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(6),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(6),
      PLB_wrPrim => mb_plb_PLB_wrPrim(6),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(6),
      Sl_SSize => mb_plb_Sl_SSize(12 to 13),
      Sl_wait => mb_plb_Sl_wait(6),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(6),
      Sl_wrDAck => mb_plb_Sl_wrDAck(6),
      Sl_wrComp => mb_plb_Sl_wrComp(6),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(6),
      Sl_rdDBus => mb_plb_Sl_rdDBus(384 to 447),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(24 to 27),
      Sl_rdDAck => mb_plb_Sl_rdDAck(6),
      Sl_rdComp => mb_plb_Sl_rdComp(6),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(6),
      Sl_MBusy => mb_plb_Sl_MBusy(18 to 20),
      Sl_MWrErr => mb_plb_Sl_MWrErr(18 to 20),
      Sl_MRdErr => mb_plb_Sl_MRdErr(18 to 20),
      Sl_MIRQ => mb_plb_Sl_MIRQ(18 to 20)
    );

  IIC_DVI : iic_dvi_wrapper
    port map (
      Sda_I => fpga_0_IIC_DVI_Sda_pin_I,
      Sda_O => fpga_0_IIC_DVI_Sda_pin_O,
      Sda_T => fpga_0_IIC_DVI_Sda_pin_T,
      Scl_I => fpga_0_IIC_DVI_Scl_pin_I,
      Scl_O => fpga_0_IIC_DVI_Scl_pin_O,
      Scl_T => fpga_0_IIC_DVI_Scl_pin_T,
      Gpo => open,
      IIC2INTC_Irpt => open,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(7),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(7),
      PLB_wrPrim => mb_plb_PLB_wrPrim(7),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(7),
      Sl_SSize => mb_plb_Sl_SSize(14 to 15),
      Sl_wait => mb_plb_Sl_wait(7),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(7),
      Sl_wrDAck => mb_plb_Sl_wrDAck(7),
      Sl_wrComp => mb_plb_Sl_wrComp(7),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(7),
      Sl_rdDBus => mb_plb_Sl_rdDBus(448 to 511),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(28 to 31),
      Sl_rdDAck => mb_plb_Sl_rdDAck(7),
      Sl_rdComp => mb_plb_Sl_rdComp(7),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(7),
      Sl_MBusy => mb_plb_Sl_MBusy(21 to 23),
      Sl_MWrErr => mb_plb_Sl_MWrErr(21 to 23),
      Sl_MRdErr => mb_plb_Sl_MRdErr(21 to 23),
      Sl_MIRQ => mb_plb_Sl_MIRQ(21 to 23)
    );

  IIC_SFP : iic_sfp_wrapper
    port map (
      Sda_I => fpga_0_IIC_SFP_Sda_pin_I,
      Sda_O => fpga_0_IIC_SFP_Sda_pin_O,
      Sda_T => fpga_0_IIC_SFP_Sda_pin_T,
      Scl_I => fpga_0_IIC_SFP_Scl_pin_I,
      Scl_O => fpga_0_IIC_SFP_Scl_pin_O,
      Scl_T => fpga_0_IIC_SFP_Scl_pin_T,
      Gpo => open,
      IIC2INTC_Irpt => open,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(8),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(8),
      PLB_wrPrim => mb_plb_PLB_wrPrim(8),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(8),
      Sl_SSize => mb_plb_Sl_SSize(16 to 17),
      Sl_wait => mb_plb_Sl_wait(8),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(8),
      Sl_wrDAck => mb_plb_Sl_wrDAck(8),
      Sl_wrComp => mb_plb_Sl_wrComp(8),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(8),
      Sl_rdDBus => mb_plb_Sl_rdDBus(512 to 575),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(32 to 35),
      Sl_rdDAck => mb_plb_Sl_rdDAck(8),
      Sl_rdComp => mb_plb_Sl_rdComp(8),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(8),
      Sl_MBusy => mb_plb_Sl_MBusy(24 to 26),
      Sl_MWrErr => mb_plb_Sl_MWrErr(24 to 26),
      Sl_MRdErr => mb_plb_Sl_MRdErr(24 to 26),
      Sl_MIRQ => mb_plb_Sl_MIRQ(24 to 26)
    );

  Ethernet_MAC : ethernet_mac_wrapper
    port map (
      PHY_tx_clk => fpga_0_Ethernet_MAC_PHY_tx_clk_pin,
      PHY_rx_clk => fpga_0_Ethernet_MAC_PHY_rx_clk_pin,
      PHY_crs => fpga_0_Ethernet_MAC_PHY_crs_pin,
      PHY_dv => fpga_0_Ethernet_MAC_PHY_dv_pin,
      PHY_rx_data => fpga_0_Ethernet_MAC_PHY_rx_data_pin,
      PHY_col => fpga_0_Ethernet_MAC_PHY_col_pin,
      PHY_rx_er => fpga_0_Ethernet_MAC_PHY_rx_er_pin,
      PHY_rst_n => fpga_0_Ethernet_MAC_PHY_rst_n_pin,
      PHY_tx_en => fpga_0_Ethernet_MAC_PHY_tx_en_pin,
      PHY_tx_data => fpga_0_Ethernet_MAC_PHY_tx_data_pin,
      PHY_MDC => fpga_0_Ethernet_MAC_PHY_MDC_pin,
      PHY_MDIO_I => fpga_0_Ethernet_MAC_PHY_MDIO_pin_I,
      PHY_MDIO_O => fpga_0_Ethernet_MAC_PHY_MDIO_pin_O,
      PHY_MDIO_T => fpga_0_Ethernet_MAC_PHY_MDIO_pin_T,
      IP2INTC_Irpt => Ethernet_MAC_IP2INTC_Irpt,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(9),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(9),
      PLB_wrPrim => mb_plb_PLB_wrPrim(9),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(9),
      Sl_SSize => mb_plb_Sl_SSize(18 to 19),
      Sl_wait => mb_plb_Sl_wait(9),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(9),
      Sl_wrDAck => mb_plb_Sl_wrDAck(9),
      Sl_wrComp => mb_plb_Sl_wrComp(9),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(9),
      Sl_rdDBus => mb_plb_Sl_rdDBus(576 to 639),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(36 to 39),
      Sl_rdDAck => mb_plb_Sl_rdDAck(9),
      Sl_rdComp => mb_plb_Sl_rdComp(9),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(9),
      Sl_MBusy => mb_plb_Sl_MBusy(27 to 29),
      Sl_MWrErr => mb_plb_Sl_MWrErr(27 to 29),
      Sl_MRdErr => mb_plb_Sl_MRdErr(27 to 29),
      Sl_MIRQ => mb_plb_Sl_MIRQ(27 to 29)
    );

  DDR3_SDRAM : ddr3_sdram_wrapper
    port map (
      FSL0_M_Clk => net_vcc0,
      FSL0_M_Write => net_gnd0,
      FSL0_M_Data => net_gnd32,
      FSL0_M_Control => net_gnd0,
      FSL0_M_Full => open,
      FSL0_S_Clk => net_gnd0,
      FSL0_S_Read => net_gnd0,
      FSL0_S_Data => open,
      FSL0_S_Control => open,
      FSL0_S_Exists => open,
      FSL0_B_M_Clk => net_vcc0,
      FSL0_B_M_Write => net_gnd0,
      FSL0_B_M_Data => net_gnd32,
      FSL0_B_M_Control => net_gnd0,
      FSL0_B_M_Full => open,
      FSL0_B_S_Clk => net_gnd0,
      FSL0_B_S_Read => net_gnd0,
      FSL0_B_S_Data => open,
      FSL0_B_S_Control => open,
      FSL0_B_S_Exists => open,
      SPLB0_Clk => clk_100_0000MHzMMCM0,
      SPLB0_Rst => mb_plb_SPLB_Rst(10),
      SPLB0_PLB_ABus => mb_plb_PLB_ABus,
      SPLB0_PLB_PAValid => mb_plb_PLB_PAValid,
      SPLB0_PLB_SAValid => mb_plb_PLB_SAValid,
      SPLB0_PLB_masterID => mb_plb_PLB_masterID,
      SPLB0_PLB_RNW => mb_plb_PLB_RNW,
      SPLB0_PLB_BE => mb_plb_PLB_BE,
      SPLB0_PLB_UABus => mb_plb_PLB_UABus,
      SPLB0_PLB_rdPrim => mb_plb_PLB_rdPrim(10),
      SPLB0_PLB_wrPrim => mb_plb_PLB_wrPrim(10),
      SPLB0_PLB_abort => mb_plb_PLB_abort,
      SPLB0_PLB_busLock => mb_plb_PLB_busLock,
      SPLB0_PLB_MSize => mb_plb_PLB_MSize,
      SPLB0_PLB_size => mb_plb_PLB_size,
      SPLB0_PLB_type => mb_plb_PLB_type,
      SPLB0_PLB_lockErr => mb_plb_PLB_lockErr,
      SPLB0_PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      SPLB0_PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      SPLB0_PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      SPLB0_PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      SPLB0_PLB_reqPri => mb_plb_PLB_reqPri,
      SPLB0_PLB_TAttribute => mb_plb_PLB_TAttribute,
      SPLB0_PLB_rdBurst => mb_plb_PLB_rdBurst,
      SPLB0_PLB_wrBurst => mb_plb_PLB_wrBurst,
      SPLB0_PLB_wrDBus => mb_plb_PLB_wrDBus,
      SPLB0_Sl_addrAck => mb_plb_Sl_addrAck(10),
      SPLB0_Sl_SSize => mb_plb_Sl_SSize(20 to 21),
      SPLB0_Sl_wait => mb_plb_Sl_wait(10),
      SPLB0_Sl_rearbitrate => mb_plb_Sl_rearbitrate(10),
      SPLB0_Sl_wrDAck => mb_plb_Sl_wrDAck(10),
      SPLB0_Sl_wrComp => mb_plb_Sl_wrComp(10),
      SPLB0_Sl_wrBTerm => mb_plb_Sl_wrBTerm(10),
      SPLB0_Sl_rdDBus => mb_plb_Sl_rdDBus(640 to 703),
      SPLB0_Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(40 to 43),
      SPLB0_Sl_rdDAck => mb_plb_Sl_rdDAck(10),
      SPLB0_Sl_rdComp => mb_plb_Sl_rdComp(10),
      SPLB0_Sl_rdBTerm => mb_plb_Sl_rdBTerm(10),
      SPLB0_Sl_MBusy => mb_plb_Sl_MBusy(30 to 32),
      SPLB0_Sl_MRdErr => mb_plb_Sl_MRdErr(30 to 32),
      SPLB0_Sl_MWrErr => mb_plb_Sl_MWrErr(30 to 32),
      SPLB0_Sl_MIRQ => mb_plb_Sl_MIRQ(30 to 32),
      SDMA0_Clk => net_gnd0,
      SDMA0_Rx_IntOut => open,
      SDMA0_Tx_IntOut => open,
      SDMA0_RstOut => open,
      SDMA0_TX_D => open,
      SDMA0_TX_Rem => open,
      SDMA0_TX_SOF => open,
      SDMA0_TX_EOF => open,
      SDMA0_TX_SOP => open,
      SDMA0_TX_EOP => open,
      SDMA0_TX_Src_Rdy => open,
      SDMA0_TX_Dst_Rdy => net_vcc0,
      SDMA0_RX_D => net_gnd32,
      SDMA0_RX_Rem => net_vcc4,
      SDMA0_RX_SOF => net_vcc0,
      SDMA0_RX_EOF => net_vcc0,
      SDMA0_RX_SOP => net_vcc0,
      SDMA0_RX_EOP => net_vcc0,
      SDMA0_RX_Src_Rdy => net_vcc0,
      SDMA0_RX_Dst_Rdy => open,
      SDMA_CTRL0_Clk => net_vcc0,
      SDMA_CTRL0_Rst => net_gnd0,
      SDMA_CTRL0_PLB_ABus => net_gnd32,
      SDMA_CTRL0_PLB_PAValid => net_gnd0,
      SDMA_CTRL0_PLB_SAValid => net_gnd0,
      SDMA_CTRL0_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL0_PLB_RNW => net_gnd0,
      SDMA_CTRL0_PLB_BE => net_gnd8,
      SDMA_CTRL0_PLB_UABus => net_gnd32,
      SDMA_CTRL0_PLB_rdPrim => net_gnd0,
      SDMA_CTRL0_PLB_wrPrim => net_gnd0,
      SDMA_CTRL0_PLB_abort => net_gnd0,
      SDMA_CTRL0_PLB_busLock => net_gnd0,
      SDMA_CTRL0_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL0_PLB_size => net_gnd4,
      SDMA_CTRL0_PLB_type => net_gnd3,
      SDMA_CTRL0_PLB_lockErr => net_gnd0,
      SDMA_CTRL0_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL0_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL0_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL0_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL0_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL0_PLB_TAttribute => net_gnd16,
      SDMA_CTRL0_PLB_rdBurst => net_gnd0,
      SDMA_CTRL0_PLB_wrBurst => net_gnd0,
      SDMA_CTRL0_PLB_wrDBus => net_gnd64,
      SDMA_CTRL0_Sl_addrAck => open,
      SDMA_CTRL0_Sl_SSize => open,
      SDMA_CTRL0_Sl_wait => open,
      SDMA_CTRL0_Sl_rearbitrate => open,
      SDMA_CTRL0_Sl_wrDAck => open,
      SDMA_CTRL0_Sl_wrComp => open,
      SDMA_CTRL0_Sl_wrBTerm => open,
      SDMA_CTRL0_Sl_rdDBus => open,
      SDMA_CTRL0_Sl_rdWdAddr => open,
      SDMA_CTRL0_Sl_rdDAck => open,
      SDMA_CTRL0_Sl_rdComp => open,
      SDMA_CTRL0_Sl_rdBTerm => open,
      SDMA_CTRL0_Sl_MBusy => open,
      SDMA_CTRL0_Sl_MRdErr => open,
      SDMA_CTRL0_Sl_MWrErr => open,
      SDMA_CTRL0_Sl_MIRQ => open,
      PIM0_Addr => net_gnd32(0 to 31),
      PIM0_AddrReq => net_gnd0,
      PIM0_AddrAck => open,
      PIM0_RNW => net_gnd0,
      PIM0_Size => net_gnd4(0 to 3),
      PIM0_RdModWr => net_gnd0,
      PIM0_WrFIFO_Data => net_gnd64(0 to 63),
      PIM0_WrFIFO_BE => net_gnd8(0 to 7),
      PIM0_WrFIFO_Push => net_gnd0,
      PIM0_RdFIFO_Data => open,
      PIM0_RdFIFO_Pop => net_gnd0,
      PIM0_RdFIFO_RdWdAddr => open,
      PIM0_WrFIFO_Empty => open,
      PIM0_WrFIFO_AlmostFull => open,
      PIM0_WrFIFO_Flush => net_gnd0,
      PIM0_RdFIFO_Empty => open,
      PIM0_RdFIFO_Flush => net_gnd0,
      PIM0_RdFIFO_Latency => open,
      PIM0_InitDone => open,
      PPC440MC0_MIMCReadNotWrite => net_gnd0,
      PPC440MC0_MIMCAddress => net_gnd36,
      PPC440MC0_MIMCAddressValid => net_gnd0,
      PPC440MC0_MIMCWriteData => net_gnd128,
      PPC440MC0_MIMCWriteDataValid => net_gnd0,
      PPC440MC0_MIMCByteEnable => net_gnd16,
      PPC440MC0_MIMCBankConflict => net_gnd0,
      PPC440MC0_MIMCRowConflict => net_gnd0,
      PPC440MC0_MCMIReadData => open,
      PPC440MC0_MCMIReadDataValid => open,
      PPC440MC0_MCMIReadDataErr => open,
      PPC440MC0_MCMIAddrReadyToAccept => open,
      VFBC0_Cmd_Clk => net_gnd0,
      VFBC0_Cmd_Reset => net_gnd0,
      VFBC0_Cmd_Data => net_gnd32(0 to 31),
      VFBC0_Cmd_Write => net_gnd0,
      VFBC0_Cmd_End => net_gnd0,
      VFBC0_Cmd_Full => open,
      VFBC0_Cmd_Almost_Full => open,
      VFBC0_Cmd_Idle => open,
      VFBC0_Wd_Clk => net_gnd0,
      VFBC0_Wd_Reset => net_gnd0,
      VFBC0_Wd_Write => net_gnd0,
      VFBC0_Wd_End_Burst => net_gnd0,
      VFBC0_Wd_Flush => net_gnd0,
      VFBC0_Wd_Data => net_gnd32(0 to 31),
      VFBC0_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC0_Wd_Full => open,
      VFBC0_Wd_Almost_Full => open,
      VFBC0_Rd_Clk => net_gnd0,
      VFBC0_Rd_Reset => net_gnd0,
      VFBC0_Rd_Read => net_gnd0,
      VFBC0_Rd_End_Burst => net_gnd0,
      VFBC0_Rd_Flush => net_gnd0,
      VFBC0_Rd_Data => open,
      VFBC0_Rd_Empty => open,
      VFBC0_Rd_Almost_Empty => open,
      MCB0_cmd_clk => net_gnd0,
      MCB0_cmd_en => net_gnd0,
      MCB0_cmd_instr => net_gnd3(0 to 2),
      MCB0_cmd_bl => net_gnd6,
      MCB0_cmd_byte_addr => net_gnd30,
      MCB0_cmd_empty => open,
      MCB0_cmd_full => open,
      MCB0_wr_clk => net_gnd0,
      MCB0_wr_en => net_gnd0,
      MCB0_wr_mask => net_gnd8(0 to 7),
      MCB0_wr_data => net_gnd64(0 to 63),
      MCB0_wr_full => open,
      MCB0_wr_empty => open,
      MCB0_wr_count => open,
      MCB0_wr_underrun => open,
      MCB0_wr_error => open,
      MCB0_rd_clk => net_gnd0,
      MCB0_rd_en => net_gnd0,
      MCB0_rd_data => open,
      MCB0_rd_full => open,
      MCB0_rd_empty => open,
      MCB0_rd_count => open,
      MCB0_rd_overflow => open,
      MCB0_rd_error => open,
      FSL1_M_Clk => microblaze_0_IXCL_FSL_M_Clk,
      FSL1_M_Write => microblaze_0_IXCL_FSL_M_Write,
      FSL1_M_Data => microblaze_0_IXCL_FSL_M_Data,
      FSL1_M_Control => microblaze_0_IXCL_FSL_M_Control,
      FSL1_M_Full => microblaze_0_IXCL_FSL_M_Full,
      FSL1_S_Clk => microblaze_0_IXCL_FSL_S_Clk,
      FSL1_S_Read => microblaze_0_IXCL_FSL_S_Read,
      FSL1_S_Data => microblaze_0_IXCL_FSL_S_Data,
      FSL1_S_Control => microblaze_0_IXCL_FSL_S_Control,
      FSL1_S_Exists => microblaze_0_IXCL_FSL_S_Exists,
      FSL1_B_M_Clk => net_vcc0,
      FSL1_B_M_Write => net_gnd0,
      FSL1_B_M_Data => net_gnd32,
      FSL1_B_M_Control => net_gnd0,
      FSL1_B_M_Full => open,
      FSL1_B_S_Clk => net_gnd0,
      FSL1_B_S_Read => net_gnd0,
      FSL1_B_S_Data => open,
      FSL1_B_S_Control => open,
      FSL1_B_S_Exists => open,
      SPLB1_Clk => net_vcc0,
      SPLB1_Rst => net_gnd0,
      SPLB1_PLB_ABus => net_gnd32,
      SPLB1_PLB_PAValid => net_gnd0,
      SPLB1_PLB_SAValid => net_gnd0,
      SPLB1_PLB_masterID => net_gnd1(0 downto 0),
      SPLB1_PLB_RNW => net_gnd0,
      SPLB1_PLB_BE => net_gnd8,
      SPLB1_PLB_UABus => net_gnd32,
      SPLB1_PLB_rdPrim => net_gnd0,
      SPLB1_PLB_wrPrim => net_gnd0,
      SPLB1_PLB_abort => net_gnd0,
      SPLB1_PLB_busLock => net_gnd0,
      SPLB1_PLB_MSize => net_gnd2(1 downto 0),
      SPLB1_PLB_size => net_gnd4,
      SPLB1_PLB_type => net_gnd3,
      SPLB1_PLB_lockErr => net_gnd0,
      SPLB1_PLB_wrPendReq => net_gnd0,
      SPLB1_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB1_PLB_rdPendReq => net_gnd0,
      SPLB1_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB1_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB1_PLB_TAttribute => net_gnd16,
      SPLB1_PLB_rdBurst => net_gnd0,
      SPLB1_PLB_wrBurst => net_gnd0,
      SPLB1_PLB_wrDBus => net_gnd64,
      SPLB1_Sl_addrAck => open,
      SPLB1_Sl_SSize => open,
      SPLB1_Sl_wait => open,
      SPLB1_Sl_rearbitrate => open,
      SPLB1_Sl_wrDAck => open,
      SPLB1_Sl_wrComp => open,
      SPLB1_Sl_wrBTerm => open,
      SPLB1_Sl_rdDBus => open,
      SPLB1_Sl_rdWdAddr => open,
      SPLB1_Sl_rdDAck => open,
      SPLB1_Sl_rdComp => open,
      SPLB1_Sl_rdBTerm => open,
      SPLB1_Sl_MBusy => open,
      SPLB1_Sl_MRdErr => open,
      SPLB1_Sl_MWrErr => open,
      SPLB1_Sl_MIRQ => open,
      SDMA1_Clk => net_gnd0,
      SDMA1_Rx_IntOut => open,
      SDMA1_Tx_IntOut => open,
      SDMA1_RstOut => open,
      SDMA1_TX_D => open,
      SDMA1_TX_Rem => open,
      SDMA1_TX_SOF => open,
      SDMA1_TX_EOF => open,
      SDMA1_TX_SOP => open,
      SDMA1_TX_EOP => open,
      SDMA1_TX_Src_Rdy => open,
      SDMA1_TX_Dst_Rdy => net_vcc0,
      SDMA1_RX_D => net_gnd32,
      SDMA1_RX_Rem => net_vcc4,
      SDMA1_RX_SOF => net_vcc0,
      SDMA1_RX_EOF => net_vcc0,
      SDMA1_RX_SOP => net_vcc0,
      SDMA1_RX_EOP => net_vcc0,
      SDMA1_RX_Src_Rdy => net_vcc0,
      SDMA1_RX_Dst_Rdy => open,
      SDMA_CTRL1_Clk => net_vcc0,
      SDMA_CTRL1_Rst => net_gnd0,
      SDMA_CTRL1_PLB_ABus => net_gnd32,
      SDMA_CTRL1_PLB_PAValid => net_gnd0,
      SDMA_CTRL1_PLB_SAValid => net_gnd0,
      SDMA_CTRL1_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL1_PLB_RNW => net_gnd0,
      SDMA_CTRL1_PLB_BE => net_gnd8,
      SDMA_CTRL1_PLB_UABus => net_gnd32,
      SDMA_CTRL1_PLB_rdPrim => net_gnd0,
      SDMA_CTRL1_PLB_wrPrim => net_gnd0,
      SDMA_CTRL1_PLB_abort => net_gnd0,
      SDMA_CTRL1_PLB_busLock => net_gnd0,
      SDMA_CTRL1_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL1_PLB_size => net_gnd4,
      SDMA_CTRL1_PLB_type => net_gnd3,
      SDMA_CTRL1_PLB_lockErr => net_gnd0,
      SDMA_CTRL1_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL1_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL1_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL1_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL1_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL1_PLB_TAttribute => net_gnd16,
      SDMA_CTRL1_PLB_rdBurst => net_gnd0,
      SDMA_CTRL1_PLB_wrBurst => net_gnd0,
      SDMA_CTRL1_PLB_wrDBus => net_gnd64,
      SDMA_CTRL1_Sl_addrAck => open,
      SDMA_CTRL1_Sl_SSize => open,
      SDMA_CTRL1_Sl_wait => open,
      SDMA_CTRL1_Sl_rearbitrate => open,
      SDMA_CTRL1_Sl_wrDAck => open,
      SDMA_CTRL1_Sl_wrComp => open,
      SDMA_CTRL1_Sl_wrBTerm => open,
      SDMA_CTRL1_Sl_rdDBus => open,
      SDMA_CTRL1_Sl_rdWdAddr => open,
      SDMA_CTRL1_Sl_rdDAck => open,
      SDMA_CTRL1_Sl_rdComp => open,
      SDMA_CTRL1_Sl_rdBTerm => open,
      SDMA_CTRL1_Sl_MBusy => open,
      SDMA_CTRL1_Sl_MRdErr => open,
      SDMA_CTRL1_Sl_MWrErr => open,
      SDMA_CTRL1_Sl_MIRQ => open,
      PIM1_Addr => net_gnd32(0 to 31),
      PIM1_AddrReq => net_gnd0,
      PIM1_AddrAck => open,
      PIM1_RNW => net_gnd0,
      PIM1_Size => net_gnd4(0 to 3),
      PIM1_RdModWr => net_gnd0,
      PIM1_WrFIFO_Data => net_gnd64(0 to 63),
      PIM1_WrFIFO_BE => net_gnd8(0 to 7),
      PIM1_WrFIFO_Push => net_gnd0,
      PIM1_RdFIFO_Data => open,
      PIM1_RdFIFO_Pop => net_gnd0,
      PIM1_RdFIFO_RdWdAddr => open,
      PIM1_WrFIFO_Empty => open,
      PIM1_WrFIFO_AlmostFull => open,
      PIM1_WrFIFO_Flush => net_gnd0,
      PIM1_RdFIFO_Empty => open,
      PIM1_RdFIFO_Flush => net_gnd0,
      PIM1_RdFIFO_Latency => open,
      PIM1_InitDone => open,
      PPC440MC1_MIMCReadNotWrite => net_gnd0,
      PPC440MC1_MIMCAddress => net_gnd36,
      PPC440MC1_MIMCAddressValid => net_gnd0,
      PPC440MC1_MIMCWriteData => net_gnd128,
      PPC440MC1_MIMCWriteDataValid => net_gnd0,
      PPC440MC1_MIMCByteEnable => net_gnd16,
      PPC440MC1_MIMCBankConflict => net_gnd0,
      PPC440MC1_MIMCRowConflict => net_gnd0,
      PPC440MC1_MCMIReadData => open,
      PPC440MC1_MCMIReadDataValid => open,
      PPC440MC1_MCMIReadDataErr => open,
      PPC440MC1_MCMIAddrReadyToAccept => open,
      VFBC1_Cmd_Clk => net_gnd0,
      VFBC1_Cmd_Reset => net_gnd0,
      VFBC1_Cmd_Data => net_gnd32(0 to 31),
      VFBC1_Cmd_Write => net_gnd0,
      VFBC1_Cmd_End => net_gnd0,
      VFBC1_Cmd_Full => open,
      VFBC1_Cmd_Almost_Full => open,
      VFBC1_Cmd_Idle => open,
      VFBC1_Wd_Clk => net_gnd0,
      VFBC1_Wd_Reset => net_gnd0,
      VFBC1_Wd_Write => net_gnd0,
      VFBC1_Wd_End_Burst => net_gnd0,
      VFBC1_Wd_Flush => net_gnd0,
      VFBC1_Wd_Data => net_gnd32(0 to 31),
      VFBC1_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC1_Wd_Full => open,
      VFBC1_Wd_Almost_Full => open,
      VFBC1_Rd_Clk => net_gnd0,
      VFBC1_Rd_Reset => net_gnd0,
      VFBC1_Rd_Read => net_gnd0,
      VFBC1_Rd_End_Burst => net_gnd0,
      VFBC1_Rd_Flush => net_gnd0,
      VFBC1_Rd_Data => open,
      VFBC1_Rd_Empty => open,
      VFBC1_Rd_Almost_Empty => open,
      MCB1_cmd_clk => net_gnd0,
      MCB1_cmd_en => net_gnd0,
      MCB1_cmd_instr => net_gnd3(0 to 2),
      MCB1_cmd_bl => net_gnd6,
      MCB1_cmd_byte_addr => net_gnd30,
      MCB1_cmd_empty => open,
      MCB1_cmd_full => open,
      MCB1_wr_clk => net_gnd0,
      MCB1_wr_en => net_gnd0,
      MCB1_wr_mask => net_gnd8(0 to 7),
      MCB1_wr_data => net_gnd64(0 to 63),
      MCB1_wr_full => open,
      MCB1_wr_empty => open,
      MCB1_wr_count => open,
      MCB1_wr_underrun => open,
      MCB1_wr_error => open,
      MCB1_rd_clk => net_gnd0,
      MCB1_rd_en => net_gnd0,
      MCB1_rd_data => open,
      MCB1_rd_full => open,
      MCB1_rd_empty => open,
      MCB1_rd_count => open,
      MCB1_rd_overflow => open,
      MCB1_rd_error => open,
      FSL2_M_Clk => microblaze_0_DXCL_FSL_M_Clk,
      FSL2_M_Write => microblaze_0_DXCL_FSL_M_Write,
      FSL2_M_Data => microblaze_0_DXCL_FSL_M_Data,
      FSL2_M_Control => microblaze_0_DXCL_FSL_M_Control,
      FSL2_M_Full => microblaze_0_DXCL_FSL_M_Full,
      FSL2_S_Clk => microblaze_0_DXCL_FSL_S_Clk,
      FSL2_S_Read => microblaze_0_DXCL_FSL_S_Read,
      FSL2_S_Data => microblaze_0_DXCL_FSL_S_Data,
      FSL2_S_Control => microblaze_0_DXCL_FSL_S_Control,
      FSL2_S_Exists => microblaze_0_DXCL_FSL_S_Exists,
      FSL2_B_M_Clk => net_vcc0,
      FSL2_B_M_Write => net_gnd0,
      FSL2_B_M_Data => net_gnd32,
      FSL2_B_M_Control => net_gnd0,
      FSL2_B_M_Full => open,
      FSL2_B_S_Clk => net_gnd0,
      FSL2_B_S_Read => net_gnd0,
      FSL2_B_S_Data => open,
      FSL2_B_S_Control => open,
      FSL2_B_S_Exists => open,
      SPLB2_Clk => net_vcc0,
      SPLB2_Rst => net_gnd0,
      SPLB2_PLB_ABus => net_gnd32,
      SPLB2_PLB_PAValid => net_gnd0,
      SPLB2_PLB_SAValid => net_gnd0,
      SPLB2_PLB_masterID => net_gnd1(0 downto 0),
      SPLB2_PLB_RNW => net_gnd0,
      SPLB2_PLB_BE => net_gnd8,
      SPLB2_PLB_UABus => net_gnd32,
      SPLB2_PLB_rdPrim => net_gnd0,
      SPLB2_PLB_wrPrim => net_gnd0,
      SPLB2_PLB_abort => net_gnd0,
      SPLB2_PLB_busLock => net_gnd0,
      SPLB2_PLB_MSize => net_gnd2(1 downto 0),
      SPLB2_PLB_size => net_gnd4,
      SPLB2_PLB_type => net_gnd3,
      SPLB2_PLB_lockErr => net_gnd0,
      SPLB2_PLB_wrPendReq => net_gnd0,
      SPLB2_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB2_PLB_rdPendReq => net_gnd0,
      SPLB2_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB2_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB2_PLB_TAttribute => net_gnd16,
      SPLB2_PLB_rdBurst => net_gnd0,
      SPLB2_PLB_wrBurst => net_gnd0,
      SPLB2_PLB_wrDBus => net_gnd64,
      SPLB2_Sl_addrAck => open,
      SPLB2_Sl_SSize => open,
      SPLB2_Sl_wait => open,
      SPLB2_Sl_rearbitrate => open,
      SPLB2_Sl_wrDAck => open,
      SPLB2_Sl_wrComp => open,
      SPLB2_Sl_wrBTerm => open,
      SPLB2_Sl_rdDBus => open,
      SPLB2_Sl_rdWdAddr => open,
      SPLB2_Sl_rdDAck => open,
      SPLB2_Sl_rdComp => open,
      SPLB2_Sl_rdBTerm => open,
      SPLB2_Sl_MBusy => open,
      SPLB2_Sl_MRdErr => open,
      SPLB2_Sl_MWrErr => open,
      SPLB2_Sl_MIRQ => open,
      SDMA2_Clk => net_gnd0,
      SDMA2_Rx_IntOut => open,
      SDMA2_Tx_IntOut => open,
      SDMA2_RstOut => open,
      SDMA2_TX_D => open,
      SDMA2_TX_Rem => open,
      SDMA2_TX_SOF => open,
      SDMA2_TX_EOF => open,
      SDMA2_TX_SOP => open,
      SDMA2_TX_EOP => open,
      SDMA2_TX_Src_Rdy => open,
      SDMA2_TX_Dst_Rdy => net_vcc0,
      SDMA2_RX_D => net_gnd32,
      SDMA2_RX_Rem => net_vcc4,
      SDMA2_RX_SOF => net_vcc0,
      SDMA2_RX_EOF => net_vcc0,
      SDMA2_RX_SOP => net_vcc0,
      SDMA2_RX_EOP => net_vcc0,
      SDMA2_RX_Src_Rdy => net_vcc0,
      SDMA2_RX_Dst_Rdy => open,
      SDMA_CTRL2_Clk => net_vcc0,
      SDMA_CTRL2_Rst => net_gnd0,
      SDMA_CTRL2_PLB_ABus => net_gnd32,
      SDMA_CTRL2_PLB_PAValid => net_gnd0,
      SDMA_CTRL2_PLB_SAValid => net_gnd0,
      SDMA_CTRL2_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL2_PLB_RNW => net_gnd0,
      SDMA_CTRL2_PLB_BE => net_gnd8,
      SDMA_CTRL2_PLB_UABus => net_gnd32,
      SDMA_CTRL2_PLB_rdPrim => net_gnd0,
      SDMA_CTRL2_PLB_wrPrim => net_gnd0,
      SDMA_CTRL2_PLB_abort => net_gnd0,
      SDMA_CTRL2_PLB_busLock => net_gnd0,
      SDMA_CTRL2_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL2_PLB_size => net_gnd4,
      SDMA_CTRL2_PLB_type => net_gnd3,
      SDMA_CTRL2_PLB_lockErr => net_gnd0,
      SDMA_CTRL2_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL2_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL2_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL2_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL2_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL2_PLB_TAttribute => net_gnd16,
      SDMA_CTRL2_PLB_rdBurst => net_gnd0,
      SDMA_CTRL2_PLB_wrBurst => net_gnd0,
      SDMA_CTRL2_PLB_wrDBus => net_gnd64,
      SDMA_CTRL2_Sl_addrAck => open,
      SDMA_CTRL2_Sl_SSize => open,
      SDMA_CTRL2_Sl_wait => open,
      SDMA_CTRL2_Sl_rearbitrate => open,
      SDMA_CTRL2_Sl_wrDAck => open,
      SDMA_CTRL2_Sl_wrComp => open,
      SDMA_CTRL2_Sl_wrBTerm => open,
      SDMA_CTRL2_Sl_rdDBus => open,
      SDMA_CTRL2_Sl_rdWdAddr => open,
      SDMA_CTRL2_Sl_rdDAck => open,
      SDMA_CTRL2_Sl_rdComp => open,
      SDMA_CTRL2_Sl_rdBTerm => open,
      SDMA_CTRL2_Sl_MBusy => open,
      SDMA_CTRL2_Sl_MRdErr => open,
      SDMA_CTRL2_Sl_MWrErr => open,
      SDMA_CTRL2_Sl_MIRQ => open,
      PIM2_Addr => net_gnd32(0 to 31),
      PIM2_AddrReq => net_gnd0,
      PIM2_AddrAck => open,
      PIM2_RNW => net_gnd0,
      PIM2_Size => net_gnd4(0 to 3),
      PIM2_RdModWr => net_gnd0,
      PIM2_WrFIFO_Data => net_gnd64(0 to 63),
      PIM2_WrFIFO_BE => net_gnd8(0 to 7),
      PIM2_WrFIFO_Push => net_gnd0,
      PIM2_RdFIFO_Data => open,
      PIM2_RdFIFO_Pop => net_gnd0,
      PIM2_RdFIFO_RdWdAddr => open,
      PIM2_WrFIFO_Empty => open,
      PIM2_WrFIFO_AlmostFull => open,
      PIM2_WrFIFO_Flush => net_gnd0,
      PIM2_RdFIFO_Empty => open,
      PIM2_RdFIFO_Flush => net_gnd0,
      PIM2_RdFIFO_Latency => open,
      PIM2_InitDone => open,
      PPC440MC2_MIMCReadNotWrite => net_gnd0,
      PPC440MC2_MIMCAddress => net_gnd36,
      PPC440MC2_MIMCAddressValid => net_gnd0,
      PPC440MC2_MIMCWriteData => net_gnd128,
      PPC440MC2_MIMCWriteDataValid => net_gnd0,
      PPC440MC2_MIMCByteEnable => net_gnd16,
      PPC440MC2_MIMCBankConflict => net_gnd0,
      PPC440MC2_MIMCRowConflict => net_gnd0,
      PPC440MC2_MCMIReadData => open,
      PPC440MC2_MCMIReadDataValid => open,
      PPC440MC2_MCMIReadDataErr => open,
      PPC440MC2_MCMIAddrReadyToAccept => open,
      VFBC2_Cmd_Clk => net_gnd0,
      VFBC2_Cmd_Reset => net_gnd0,
      VFBC2_Cmd_Data => net_gnd32(0 to 31),
      VFBC2_Cmd_Write => net_gnd0,
      VFBC2_Cmd_End => net_gnd0,
      VFBC2_Cmd_Full => open,
      VFBC2_Cmd_Almost_Full => open,
      VFBC2_Cmd_Idle => open,
      VFBC2_Wd_Clk => net_gnd0,
      VFBC2_Wd_Reset => net_gnd0,
      VFBC2_Wd_Write => net_gnd0,
      VFBC2_Wd_End_Burst => net_gnd0,
      VFBC2_Wd_Flush => net_gnd0,
      VFBC2_Wd_Data => net_gnd32(0 to 31),
      VFBC2_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC2_Wd_Full => open,
      VFBC2_Wd_Almost_Full => open,
      VFBC2_Rd_Clk => net_gnd0,
      VFBC2_Rd_Reset => net_gnd0,
      VFBC2_Rd_Read => net_gnd0,
      VFBC2_Rd_End_Burst => net_gnd0,
      VFBC2_Rd_Flush => net_gnd0,
      VFBC2_Rd_Data => open,
      VFBC2_Rd_Empty => open,
      VFBC2_Rd_Almost_Empty => open,
      MCB2_cmd_clk => net_gnd0,
      MCB2_cmd_en => net_gnd0,
      MCB2_cmd_instr => net_gnd3(0 to 2),
      MCB2_cmd_bl => net_gnd6,
      MCB2_cmd_byte_addr => net_gnd30,
      MCB2_cmd_empty => open,
      MCB2_cmd_full => open,
      MCB2_wr_clk => net_gnd0,
      MCB2_wr_en => net_gnd0,
      MCB2_wr_mask => net_gnd8(0 to 7),
      MCB2_wr_data => net_gnd64(0 to 63),
      MCB2_wr_full => open,
      MCB2_wr_empty => open,
      MCB2_wr_count => open,
      MCB2_wr_underrun => open,
      MCB2_wr_error => open,
      MCB2_rd_clk => net_gnd0,
      MCB2_rd_en => net_gnd0,
      MCB2_rd_data => open,
      MCB2_rd_full => open,
      MCB2_rd_empty => open,
      MCB2_rd_count => open,
      MCB2_rd_overflow => open,
      MCB2_rd_error => open,
      FSL3_M_Clk => net_vcc0,
      FSL3_M_Write => net_gnd0,
      FSL3_M_Data => net_gnd32,
      FSL3_M_Control => net_gnd0,
      FSL3_M_Full => open,
      FSL3_S_Clk => net_gnd0,
      FSL3_S_Read => net_gnd0,
      FSL3_S_Data => open,
      FSL3_S_Control => open,
      FSL3_S_Exists => open,
      FSL3_B_M_Clk => net_vcc0,
      FSL3_B_M_Write => net_gnd0,
      FSL3_B_M_Data => net_gnd32,
      FSL3_B_M_Control => net_gnd0,
      FSL3_B_M_Full => open,
      FSL3_B_S_Clk => net_gnd0,
      FSL3_B_S_Read => net_gnd0,
      FSL3_B_S_Data => open,
      FSL3_B_S_Control => open,
      FSL3_B_S_Exists => open,
      SPLB3_Clk => net_vcc0,
      SPLB3_Rst => net_gnd0,
      SPLB3_PLB_ABus => net_gnd32,
      SPLB3_PLB_PAValid => net_gnd0,
      SPLB3_PLB_SAValid => net_gnd0,
      SPLB3_PLB_masterID => net_gnd1(0 downto 0),
      SPLB3_PLB_RNW => net_gnd0,
      SPLB3_PLB_BE => net_gnd8,
      SPLB3_PLB_UABus => net_gnd32,
      SPLB3_PLB_rdPrim => net_gnd0,
      SPLB3_PLB_wrPrim => net_gnd0,
      SPLB3_PLB_abort => net_gnd0,
      SPLB3_PLB_busLock => net_gnd0,
      SPLB3_PLB_MSize => net_gnd2(1 downto 0),
      SPLB3_PLB_size => net_gnd4,
      SPLB3_PLB_type => net_gnd3,
      SPLB3_PLB_lockErr => net_gnd0,
      SPLB3_PLB_wrPendReq => net_gnd0,
      SPLB3_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB3_PLB_rdPendReq => net_gnd0,
      SPLB3_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB3_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB3_PLB_TAttribute => net_gnd16,
      SPLB3_PLB_rdBurst => net_gnd0,
      SPLB3_PLB_wrBurst => net_gnd0,
      SPLB3_PLB_wrDBus => net_gnd64,
      SPLB3_Sl_addrAck => open,
      SPLB3_Sl_SSize => open,
      SPLB3_Sl_wait => open,
      SPLB3_Sl_rearbitrate => open,
      SPLB3_Sl_wrDAck => open,
      SPLB3_Sl_wrComp => open,
      SPLB3_Sl_wrBTerm => open,
      SPLB3_Sl_rdDBus => open,
      SPLB3_Sl_rdWdAddr => open,
      SPLB3_Sl_rdDAck => open,
      SPLB3_Sl_rdComp => open,
      SPLB3_Sl_rdBTerm => open,
      SPLB3_Sl_MBusy => open,
      SPLB3_Sl_MRdErr => open,
      SPLB3_Sl_MWrErr => open,
      SPLB3_Sl_MIRQ => open,
      SDMA3_Clk => net_gnd0,
      SDMA3_Rx_IntOut => open,
      SDMA3_Tx_IntOut => open,
      SDMA3_RstOut => open,
      SDMA3_TX_D => open,
      SDMA3_TX_Rem => open,
      SDMA3_TX_SOF => open,
      SDMA3_TX_EOF => open,
      SDMA3_TX_SOP => open,
      SDMA3_TX_EOP => open,
      SDMA3_TX_Src_Rdy => open,
      SDMA3_TX_Dst_Rdy => net_vcc0,
      SDMA3_RX_D => net_gnd32,
      SDMA3_RX_Rem => net_vcc4,
      SDMA3_RX_SOF => net_vcc0,
      SDMA3_RX_EOF => net_vcc0,
      SDMA3_RX_SOP => net_vcc0,
      SDMA3_RX_EOP => net_vcc0,
      SDMA3_RX_Src_Rdy => net_vcc0,
      SDMA3_RX_Dst_Rdy => open,
      SDMA_CTRL3_Clk => net_vcc0,
      SDMA_CTRL3_Rst => net_gnd0,
      SDMA_CTRL3_PLB_ABus => net_gnd32,
      SDMA_CTRL3_PLB_PAValid => net_gnd0,
      SDMA_CTRL3_PLB_SAValid => net_gnd0,
      SDMA_CTRL3_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL3_PLB_RNW => net_gnd0,
      SDMA_CTRL3_PLB_BE => net_gnd8,
      SDMA_CTRL3_PLB_UABus => net_gnd32,
      SDMA_CTRL3_PLB_rdPrim => net_gnd0,
      SDMA_CTRL3_PLB_wrPrim => net_gnd0,
      SDMA_CTRL3_PLB_abort => net_gnd0,
      SDMA_CTRL3_PLB_busLock => net_gnd0,
      SDMA_CTRL3_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL3_PLB_size => net_gnd4,
      SDMA_CTRL3_PLB_type => net_gnd3,
      SDMA_CTRL3_PLB_lockErr => net_gnd0,
      SDMA_CTRL3_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL3_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL3_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL3_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL3_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL3_PLB_TAttribute => net_gnd16,
      SDMA_CTRL3_PLB_rdBurst => net_gnd0,
      SDMA_CTRL3_PLB_wrBurst => net_gnd0,
      SDMA_CTRL3_PLB_wrDBus => net_gnd64,
      SDMA_CTRL3_Sl_addrAck => open,
      SDMA_CTRL3_Sl_SSize => open,
      SDMA_CTRL3_Sl_wait => open,
      SDMA_CTRL3_Sl_rearbitrate => open,
      SDMA_CTRL3_Sl_wrDAck => open,
      SDMA_CTRL3_Sl_wrComp => open,
      SDMA_CTRL3_Sl_wrBTerm => open,
      SDMA_CTRL3_Sl_rdDBus => open,
      SDMA_CTRL3_Sl_rdWdAddr => open,
      SDMA_CTRL3_Sl_rdDAck => open,
      SDMA_CTRL3_Sl_rdComp => open,
      SDMA_CTRL3_Sl_rdBTerm => open,
      SDMA_CTRL3_Sl_MBusy => open,
      SDMA_CTRL3_Sl_MRdErr => open,
      SDMA_CTRL3_Sl_MWrErr => open,
      SDMA_CTRL3_Sl_MIRQ => open,
      PIM3_Addr => net_gnd32(0 to 31),
      PIM3_AddrReq => net_gnd0,
      PIM3_AddrAck => open,
      PIM3_RNW => net_gnd0,
      PIM3_Size => net_gnd4(0 to 3),
      PIM3_RdModWr => net_gnd0,
      PIM3_WrFIFO_Data => net_gnd64(0 to 63),
      PIM3_WrFIFO_BE => net_gnd8(0 to 7),
      PIM3_WrFIFO_Push => net_gnd0,
      PIM3_RdFIFO_Data => open,
      PIM3_RdFIFO_Pop => net_gnd0,
      PIM3_RdFIFO_RdWdAddr => open,
      PIM3_WrFIFO_Empty => open,
      PIM3_WrFIFO_AlmostFull => open,
      PIM3_WrFIFO_Flush => net_gnd0,
      PIM3_RdFIFO_Empty => open,
      PIM3_RdFIFO_Flush => net_gnd0,
      PIM3_RdFIFO_Latency => open,
      PIM3_InitDone => open,
      PPC440MC3_MIMCReadNotWrite => net_gnd0,
      PPC440MC3_MIMCAddress => net_gnd36,
      PPC440MC3_MIMCAddressValid => net_gnd0,
      PPC440MC3_MIMCWriteData => net_gnd128,
      PPC440MC3_MIMCWriteDataValid => net_gnd0,
      PPC440MC3_MIMCByteEnable => net_gnd16,
      PPC440MC3_MIMCBankConflict => net_gnd0,
      PPC440MC3_MIMCRowConflict => net_gnd0,
      PPC440MC3_MCMIReadData => open,
      PPC440MC3_MCMIReadDataValid => open,
      PPC440MC3_MCMIReadDataErr => open,
      PPC440MC3_MCMIAddrReadyToAccept => open,
      VFBC3_Cmd_Clk => net_gnd0,
      VFBC3_Cmd_Reset => net_gnd0,
      VFBC3_Cmd_Data => net_gnd32(0 to 31),
      VFBC3_Cmd_Write => net_gnd0,
      VFBC3_Cmd_End => net_gnd0,
      VFBC3_Cmd_Full => open,
      VFBC3_Cmd_Almost_Full => open,
      VFBC3_Cmd_Idle => open,
      VFBC3_Wd_Clk => net_gnd0,
      VFBC3_Wd_Reset => net_gnd0,
      VFBC3_Wd_Write => net_gnd0,
      VFBC3_Wd_End_Burst => net_gnd0,
      VFBC3_Wd_Flush => net_gnd0,
      VFBC3_Wd_Data => net_gnd32(0 to 31),
      VFBC3_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC3_Wd_Full => open,
      VFBC3_Wd_Almost_Full => open,
      VFBC3_Rd_Clk => net_gnd0,
      VFBC3_Rd_Reset => net_gnd0,
      VFBC3_Rd_Read => net_gnd0,
      VFBC3_Rd_End_Burst => net_gnd0,
      VFBC3_Rd_Flush => net_gnd0,
      VFBC3_Rd_Data => open,
      VFBC3_Rd_Empty => open,
      VFBC3_Rd_Almost_Empty => open,
      MCB3_cmd_clk => net_gnd0,
      MCB3_cmd_en => net_gnd0,
      MCB3_cmd_instr => net_gnd3(0 to 2),
      MCB3_cmd_bl => net_gnd6,
      MCB3_cmd_byte_addr => net_gnd30,
      MCB3_cmd_empty => open,
      MCB3_cmd_full => open,
      MCB3_wr_clk => net_gnd0,
      MCB3_wr_en => net_gnd0,
      MCB3_wr_mask => net_gnd8(0 to 7),
      MCB3_wr_data => net_gnd64(0 to 63),
      MCB3_wr_full => open,
      MCB3_wr_empty => open,
      MCB3_wr_count => open,
      MCB3_wr_underrun => open,
      MCB3_wr_error => open,
      MCB3_rd_clk => net_gnd0,
      MCB3_rd_en => net_gnd0,
      MCB3_rd_data => open,
      MCB3_rd_full => open,
      MCB3_rd_empty => open,
      MCB3_rd_count => open,
      MCB3_rd_overflow => open,
      MCB3_rd_error => open,
      FSL4_M_Clk => net_vcc0,
      FSL4_M_Write => net_gnd0,
      FSL4_M_Data => net_gnd32,
      FSL4_M_Control => net_gnd0,
      FSL4_M_Full => open,
      FSL4_S_Clk => net_gnd0,
      FSL4_S_Read => net_gnd0,
      FSL4_S_Data => open,
      FSL4_S_Control => open,
      FSL4_S_Exists => open,
      FSL4_B_M_Clk => net_vcc0,
      FSL4_B_M_Write => net_gnd0,
      FSL4_B_M_Data => net_gnd32,
      FSL4_B_M_Control => net_gnd0,
      FSL4_B_M_Full => open,
      FSL4_B_S_Clk => net_gnd0,
      FSL4_B_S_Read => net_gnd0,
      FSL4_B_S_Data => open,
      FSL4_B_S_Control => open,
      FSL4_B_S_Exists => open,
      SPLB4_Clk => net_vcc0,
      SPLB4_Rst => net_gnd0,
      SPLB4_PLB_ABus => net_gnd32,
      SPLB4_PLB_PAValid => net_gnd0,
      SPLB4_PLB_SAValid => net_gnd0,
      SPLB4_PLB_masterID => net_gnd1(0 downto 0),
      SPLB4_PLB_RNW => net_gnd0,
      SPLB4_PLB_BE => net_gnd8,
      SPLB4_PLB_UABus => net_gnd32,
      SPLB4_PLB_rdPrim => net_gnd0,
      SPLB4_PLB_wrPrim => net_gnd0,
      SPLB4_PLB_abort => net_gnd0,
      SPLB4_PLB_busLock => net_gnd0,
      SPLB4_PLB_MSize => net_gnd2(1 downto 0),
      SPLB4_PLB_size => net_gnd4,
      SPLB4_PLB_type => net_gnd3,
      SPLB4_PLB_lockErr => net_gnd0,
      SPLB4_PLB_wrPendReq => net_gnd0,
      SPLB4_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB4_PLB_rdPendReq => net_gnd0,
      SPLB4_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB4_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB4_PLB_TAttribute => net_gnd16,
      SPLB4_PLB_rdBurst => net_gnd0,
      SPLB4_PLB_wrBurst => net_gnd0,
      SPLB4_PLB_wrDBus => net_gnd64,
      SPLB4_Sl_addrAck => open,
      SPLB4_Sl_SSize => open,
      SPLB4_Sl_wait => open,
      SPLB4_Sl_rearbitrate => open,
      SPLB4_Sl_wrDAck => open,
      SPLB4_Sl_wrComp => open,
      SPLB4_Sl_wrBTerm => open,
      SPLB4_Sl_rdDBus => open,
      SPLB4_Sl_rdWdAddr => open,
      SPLB4_Sl_rdDAck => open,
      SPLB4_Sl_rdComp => open,
      SPLB4_Sl_rdBTerm => open,
      SPLB4_Sl_MBusy => open,
      SPLB4_Sl_MRdErr => open,
      SPLB4_Sl_MWrErr => open,
      SPLB4_Sl_MIRQ => open,
      SDMA4_Clk => net_gnd0,
      SDMA4_Rx_IntOut => open,
      SDMA4_Tx_IntOut => open,
      SDMA4_RstOut => open,
      SDMA4_TX_D => open,
      SDMA4_TX_Rem => open,
      SDMA4_TX_SOF => open,
      SDMA4_TX_EOF => open,
      SDMA4_TX_SOP => open,
      SDMA4_TX_EOP => open,
      SDMA4_TX_Src_Rdy => open,
      SDMA4_TX_Dst_Rdy => net_vcc0,
      SDMA4_RX_D => net_gnd32,
      SDMA4_RX_Rem => net_vcc4,
      SDMA4_RX_SOF => net_vcc0,
      SDMA4_RX_EOF => net_vcc0,
      SDMA4_RX_SOP => net_vcc0,
      SDMA4_RX_EOP => net_vcc0,
      SDMA4_RX_Src_Rdy => net_vcc0,
      SDMA4_RX_Dst_Rdy => open,
      SDMA_CTRL4_Clk => net_vcc0,
      SDMA_CTRL4_Rst => net_gnd0,
      SDMA_CTRL4_PLB_ABus => net_gnd32,
      SDMA_CTRL4_PLB_PAValid => net_gnd0,
      SDMA_CTRL4_PLB_SAValid => net_gnd0,
      SDMA_CTRL4_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL4_PLB_RNW => net_gnd0,
      SDMA_CTRL4_PLB_BE => net_gnd8,
      SDMA_CTRL4_PLB_UABus => net_gnd32,
      SDMA_CTRL4_PLB_rdPrim => net_gnd0,
      SDMA_CTRL4_PLB_wrPrim => net_gnd0,
      SDMA_CTRL4_PLB_abort => net_gnd0,
      SDMA_CTRL4_PLB_busLock => net_gnd0,
      SDMA_CTRL4_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL4_PLB_size => net_gnd4,
      SDMA_CTRL4_PLB_type => net_gnd3,
      SDMA_CTRL4_PLB_lockErr => net_gnd0,
      SDMA_CTRL4_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL4_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL4_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL4_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL4_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL4_PLB_TAttribute => net_gnd16,
      SDMA_CTRL4_PLB_rdBurst => net_gnd0,
      SDMA_CTRL4_PLB_wrBurst => net_gnd0,
      SDMA_CTRL4_PLB_wrDBus => net_gnd64,
      SDMA_CTRL4_Sl_addrAck => open,
      SDMA_CTRL4_Sl_SSize => open,
      SDMA_CTRL4_Sl_wait => open,
      SDMA_CTRL4_Sl_rearbitrate => open,
      SDMA_CTRL4_Sl_wrDAck => open,
      SDMA_CTRL4_Sl_wrComp => open,
      SDMA_CTRL4_Sl_wrBTerm => open,
      SDMA_CTRL4_Sl_rdDBus => open,
      SDMA_CTRL4_Sl_rdWdAddr => open,
      SDMA_CTRL4_Sl_rdDAck => open,
      SDMA_CTRL4_Sl_rdComp => open,
      SDMA_CTRL4_Sl_rdBTerm => open,
      SDMA_CTRL4_Sl_MBusy => open,
      SDMA_CTRL4_Sl_MRdErr => open,
      SDMA_CTRL4_Sl_MWrErr => open,
      SDMA_CTRL4_Sl_MIRQ => open,
      PIM4_Addr => net_gnd32(0 to 31),
      PIM4_AddrReq => net_gnd0,
      PIM4_AddrAck => open,
      PIM4_RNW => net_gnd0,
      PIM4_Size => net_gnd4(0 to 3),
      PIM4_RdModWr => net_gnd0,
      PIM4_WrFIFO_Data => net_gnd64(0 to 63),
      PIM4_WrFIFO_BE => net_gnd8(0 to 7),
      PIM4_WrFIFO_Push => net_gnd0,
      PIM4_RdFIFO_Data => open,
      PIM4_RdFIFO_Pop => net_gnd0,
      PIM4_RdFIFO_RdWdAddr => open,
      PIM4_WrFIFO_Empty => open,
      PIM4_WrFIFO_AlmostFull => open,
      PIM4_WrFIFO_Flush => net_gnd0,
      PIM4_RdFIFO_Empty => open,
      PIM4_RdFIFO_Flush => net_gnd0,
      PIM4_RdFIFO_Latency => open,
      PIM4_InitDone => open,
      PPC440MC4_MIMCReadNotWrite => net_gnd0,
      PPC440MC4_MIMCAddress => net_gnd36,
      PPC440MC4_MIMCAddressValid => net_gnd0,
      PPC440MC4_MIMCWriteData => net_gnd128,
      PPC440MC4_MIMCWriteDataValid => net_gnd0,
      PPC440MC4_MIMCByteEnable => net_gnd16,
      PPC440MC4_MIMCBankConflict => net_gnd0,
      PPC440MC4_MIMCRowConflict => net_gnd0,
      PPC440MC4_MCMIReadData => open,
      PPC440MC4_MCMIReadDataValid => open,
      PPC440MC4_MCMIReadDataErr => open,
      PPC440MC4_MCMIAddrReadyToAccept => open,
      VFBC4_Cmd_Clk => net_gnd0,
      VFBC4_Cmd_Reset => net_gnd0,
      VFBC4_Cmd_Data => net_gnd32(0 to 31),
      VFBC4_Cmd_Write => net_gnd0,
      VFBC4_Cmd_End => net_gnd0,
      VFBC4_Cmd_Full => open,
      VFBC4_Cmd_Almost_Full => open,
      VFBC4_Cmd_Idle => open,
      VFBC4_Wd_Clk => net_gnd0,
      VFBC4_Wd_Reset => net_gnd0,
      VFBC4_Wd_Write => net_gnd0,
      VFBC4_Wd_End_Burst => net_gnd0,
      VFBC4_Wd_Flush => net_gnd0,
      VFBC4_Wd_Data => net_gnd32(0 to 31),
      VFBC4_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC4_Wd_Full => open,
      VFBC4_Wd_Almost_Full => open,
      VFBC4_Rd_Clk => net_gnd0,
      VFBC4_Rd_Reset => net_gnd0,
      VFBC4_Rd_Read => net_gnd0,
      VFBC4_Rd_End_Burst => net_gnd0,
      VFBC4_Rd_Flush => net_gnd0,
      VFBC4_Rd_Data => open,
      VFBC4_Rd_Empty => open,
      VFBC4_Rd_Almost_Empty => open,
      MCB4_cmd_clk => net_gnd0,
      MCB4_cmd_en => net_gnd0,
      MCB4_cmd_instr => net_gnd3(0 to 2),
      MCB4_cmd_bl => net_gnd6,
      MCB4_cmd_byte_addr => net_gnd30,
      MCB4_cmd_empty => open,
      MCB4_cmd_full => open,
      MCB4_wr_clk => net_gnd0,
      MCB4_wr_en => net_gnd0,
      MCB4_wr_mask => net_gnd8(0 to 7),
      MCB4_wr_data => net_gnd64(0 to 63),
      MCB4_wr_full => open,
      MCB4_wr_empty => open,
      MCB4_wr_count => open,
      MCB4_wr_underrun => open,
      MCB4_wr_error => open,
      MCB4_rd_clk => net_gnd0,
      MCB4_rd_en => net_gnd0,
      MCB4_rd_data => open,
      MCB4_rd_full => open,
      MCB4_rd_empty => open,
      MCB4_rd_count => open,
      MCB4_rd_overflow => open,
      MCB4_rd_error => open,
      FSL5_M_Clk => net_vcc0,
      FSL5_M_Write => net_gnd0,
      FSL5_M_Data => net_gnd32,
      FSL5_M_Control => net_gnd0,
      FSL5_M_Full => open,
      FSL5_S_Clk => net_gnd0,
      FSL5_S_Read => net_gnd0,
      FSL5_S_Data => open,
      FSL5_S_Control => open,
      FSL5_S_Exists => open,
      FSL5_B_M_Clk => net_vcc0,
      FSL5_B_M_Write => net_gnd0,
      FSL5_B_M_Data => net_gnd32,
      FSL5_B_M_Control => net_gnd0,
      FSL5_B_M_Full => open,
      FSL5_B_S_Clk => net_gnd0,
      FSL5_B_S_Read => net_gnd0,
      FSL5_B_S_Data => open,
      FSL5_B_S_Control => open,
      FSL5_B_S_Exists => open,
      SPLB5_Clk => net_vcc0,
      SPLB5_Rst => net_gnd0,
      SPLB5_PLB_ABus => net_gnd32,
      SPLB5_PLB_PAValid => net_gnd0,
      SPLB5_PLB_SAValid => net_gnd0,
      SPLB5_PLB_masterID => net_gnd1(0 downto 0),
      SPLB5_PLB_RNW => net_gnd0,
      SPLB5_PLB_BE => net_gnd8,
      SPLB5_PLB_UABus => net_gnd32,
      SPLB5_PLB_rdPrim => net_gnd0,
      SPLB5_PLB_wrPrim => net_gnd0,
      SPLB5_PLB_abort => net_gnd0,
      SPLB5_PLB_busLock => net_gnd0,
      SPLB5_PLB_MSize => net_gnd2(1 downto 0),
      SPLB5_PLB_size => net_gnd4,
      SPLB5_PLB_type => net_gnd3,
      SPLB5_PLB_lockErr => net_gnd0,
      SPLB5_PLB_wrPendReq => net_gnd0,
      SPLB5_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB5_PLB_rdPendReq => net_gnd0,
      SPLB5_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB5_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB5_PLB_TAttribute => net_gnd16,
      SPLB5_PLB_rdBurst => net_gnd0,
      SPLB5_PLB_wrBurst => net_gnd0,
      SPLB5_PLB_wrDBus => net_gnd64,
      SPLB5_Sl_addrAck => open,
      SPLB5_Sl_SSize => open,
      SPLB5_Sl_wait => open,
      SPLB5_Sl_rearbitrate => open,
      SPLB5_Sl_wrDAck => open,
      SPLB5_Sl_wrComp => open,
      SPLB5_Sl_wrBTerm => open,
      SPLB5_Sl_rdDBus => open,
      SPLB5_Sl_rdWdAddr => open,
      SPLB5_Sl_rdDAck => open,
      SPLB5_Sl_rdComp => open,
      SPLB5_Sl_rdBTerm => open,
      SPLB5_Sl_MBusy => open,
      SPLB5_Sl_MRdErr => open,
      SPLB5_Sl_MWrErr => open,
      SPLB5_Sl_MIRQ => open,
      SDMA5_Clk => net_gnd0,
      SDMA5_Rx_IntOut => open,
      SDMA5_Tx_IntOut => open,
      SDMA5_RstOut => open,
      SDMA5_TX_D => open,
      SDMA5_TX_Rem => open,
      SDMA5_TX_SOF => open,
      SDMA5_TX_EOF => open,
      SDMA5_TX_SOP => open,
      SDMA5_TX_EOP => open,
      SDMA5_TX_Src_Rdy => open,
      SDMA5_TX_Dst_Rdy => net_vcc0,
      SDMA5_RX_D => net_gnd32,
      SDMA5_RX_Rem => net_vcc4,
      SDMA5_RX_SOF => net_vcc0,
      SDMA5_RX_EOF => net_vcc0,
      SDMA5_RX_SOP => net_vcc0,
      SDMA5_RX_EOP => net_vcc0,
      SDMA5_RX_Src_Rdy => net_vcc0,
      SDMA5_RX_Dst_Rdy => open,
      SDMA_CTRL5_Clk => net_vcc0,
      SDMA_CTRL5_Rst => net_gnd0,
      SDMA_CTRL5_PLB_ABus => net_gnd32,
      SDMA_CTRL5_PLB_PAValid => net_gnd0,
      SDMA_CTRL5_PLB_SAValid => net_gnd0,
      SDMA_CTRL5_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL5_PLB_RNW => net_gnd0,
      SDMA_CTRL5_PLB_BE => net_gnd8,
      SDMA_CTRL5_PLB_UABus => net_gnd32,
      SDMA_CTRL5_PLB_rdPrim => net_gnd0,
      SDMA_CTRL5_PLB_wrPrim => net_gnd0,
      SDMA_CTRL5_PLB_abort => net_gnd0,
      SDMA_CTRL5_PLB_busLock => net_gnd0,
      SDMA_CTRL5_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL5_PLB_size => net_gnd4,
      SDMA_CTRL5_PLB_type => net_gnd3,
      SDMA_CTRL5_PLB_lockErr => net_gnd0,
      SDMA_CTRL5_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL5_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL5_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL5_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL5_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL5_PLB_TAttribute => net_gnd16,
      SDMA_CTRL5_PLB_rdBurst => net_gnd0,
      SDMA_CTRL5_PLB_wrBurst => net_gnd0,
      SDMA_CTRL5_PLB_wrDBus => net_gnd64,
      SDMA_CTRL5_Sl_addrAck => open,
      SDMA_CTRL5_Sl_SSize => open,
      SDMA_CTRL5_Sl_wait => open,
      SDMA_CTRL5_Sl_rearbitrate => open,
      SDMA_CTRL5_Sl_wrDAck => open,
      SDMA_CTRL5_Sl_wrComp => open,
      SDMA_CTRL5_Sl_wrBTerm => open,
      SDMA_CTRL5_Sl_rdDBus => open,
      SDMA_CTRL5_Sl_rdWdAddr => open,
      SDMA_CTRL5_Sl_rdDAck => open,
      SDMA_CTRL5_Sl_rdComp => open,
      SDMA_CTRL5_Sl_rdBTerm => open,
      SDMA_CTRL5_Sl_MBusy => open,
      SDMA_CTRL5_Sl_MRdErr => open,
      SDMA_CTRL5_Sl_MWrErr => open,
      SDMA_CTRL5_Sl_MIRQ => open,
      PIM5_Addr => net_gnd32(0 to 31),
      PIM5_AddrReq => net_gnd0,
      PIM5_AddrAck => open,
      PIM5_RNW => net_gnd0,
      PIM5_Size => net_gnd4(0 to 3),
      PIM5_RdModWr => net_gnd0,
      PIM5_WrFIFO_Data => net_gnd64(0 to 63),
      PIM5_WrFIFO_BE => net_gnd8(0 to 7),
      PIM5_WrFIFO_Push => net_gnd0,
      PIM5_RdFIFO_Data => open,
      PIM5_RdFIFO_Pop => net_gnd0,
      PIM5_RdFIFO_RdWdAddr => open,
      PIM5_WrFIFO_Empty => open,
      PIM5_WrFIFO_AlmostFull => open,
      PIM5_WrFIFO_Flush => net_gnd0,
      PIM5_RdFIFO_Empty => open,
      PIM5_RdFIFO_Flush => net_gnd0,
      PIM5_RdFIFO_Latency => open,
      PIM5_InitDone => open,
      PPC440MC5_MIMCReadNotWrite => net_gnd0,
      PPC440MC5_MIMCAddress => net_gnd36,
      PPC440MC5_MIMCAddressValid => net_gnd0,
      PPC440MC5_MIMCWriteData => net_gnd128,
      PPC440MC5_MIMCWriteDataValid => net_gnd0,
      PPC440MC5_MIMCByteEnable => net_gnd16,
      PPC440MC5_MIMCBankConflict => net_gnd0,
      PPC440MC5_MIMCRowConflict => net_gnd0,
      PPC440MC5_MCMIReadData => open,
      PPC440MC5_MCMIReadDataValid => open,
      PPC440MC5_MCMIReadDataErr => open,
      PPC440MC5_MCMIAddrReadyToAccept => open,
      VFBC5_Cmd_Clk => net_gnd0,
      VFBC5_Cmd_Reset => net_gnd0,
      VFBC5_Cmd_Data => net_gnd32(0 to 31),
      VFBC5_Cmd_Write => net_gnd0,
      VFBC5_Cmd_End => net_gnd0,
      VFBC5_Cmd_Full => open,
      VFBC5_Cmd_Almost_Full => open,
      VFBC5_Cmd_Idle => open,
      VFBC5_Wd_Clk => net_gnd0,
      VFBC5_Wd_Reset => net_gnd0,
      VFBC5_Wd_Write => net_gnd0,
      VFBC5_Wd_End_Burst => net_gnd0,
      VFBC5_Wd_Flush => net_gnd0,
      VFBC5_Wd_Data => net_gnd32(0 to 31),
      VFBC5_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC5_Wd_Full => open,
      VFBC5_Wd_Almost_Full => open,
      VFBC5_Rd_Clk => net_gnd0,
      VFBC5_Rd_Reset => net_gnd0,
      VFBC5_Rd_Read => net_gnd0,
      VFBC5_Rd_End_Burst => net_gnd0,
      VFBC5_Rd_Flush => net_gnd0,
      VFBC5_Rd_Data => open,
      VFBC5_Rd_Empty => open,
      VFBC5_Rd_Almost_Empty => open,
      MCB5_cmd_clk => net_gnd0,
      MCB5_cmd_en => net_gnd0,
      MCB5_cmd_instr => net_gnd3(0 to 2),
      MCB5_cmd_bl => net_gnd6,
      MCB5_cmd_byte_addr => net_gnd30,
      MCB5_cmd_empty => open,
      MCB5_cmd_full => open,
      MCB5_wr_clk => net_gnd0,
      MCB5_wr_en => net_gnd0,
      MCB5_wr_mask => net_gnd8(0 to 7),
      MCB5_wr_data => net_gnd64(0 to 63),
      MCB5_wr_full => open,
      MCB5_wr_empty => open,
      MCB5_wr_count => open,
      MCB5_wr_underrun => open,
      MCB5_wr_error => open,
      MCB5_rd_clk => net_gnd0,
      MCB5_rd_en => net_gnd0,
      MCB5_rd_data => open,
      MCB5_rd_full => open,
      MCB5_rd_empty => open,
      MCB5_rd_count => open,
      MCB5_rd_overflow => open,
      MCB5_rd_error => open,
      FSL6_M_Clk => net_vcc0,
      FSL6_M_Write => net_gnd0,
      FSL6_M_Data => net_gnd32,
      FSL6_M_Control => net_gnd0,
      FSL6_M_Full => open,
      FSL6_S_Clk => net_gnd0,
      FSL6_S_Read => net_gnd0,
      FSL6_S_Data => open,
      FSL6_S_Control => open,
      FSL6_S_Exists => open,
      FSL6_B_M_Clk => net_vcc0,
      FSL6_B_M_Write => net_gnd0,
      FSL6_B_M_Data => net_gnd32,
      FSL6_B_M_Control => net_gnd0,
      FSL6_B_M_Full => open,
      FSL6_B_S_Clk => net_gnd0,
      FSL6_B_S_Read => net_gnd0,
      FSL6_B_S_Data => open,
      FSL6_B_S_Control => open,
      FSL6_B_S_Exists => open,
      SPLB6_Clk => net_vcc0,
      SPLB6_Rst => net_gnd0,
      SPLB6_PLB_ABus => net_gnd32,
      SPLB6_PLB_PAValid => net_gnd0,
      SPLB6_PLB_SAValid => net_gnd0,
      SPLB6_PLB_masterID => net_gnd1(0 downto 0),
      SPLB6_PLB_RNW => net_gnd0,
      SPLB6_PLB_BE => net_gnd8,
      SPLB6_PLB_UABus => net_gnd32,
      SPLB6_PLB_rdPrim => net_gnd0,
      SPLB6_PLB_wrPrim => net_gnd0,
      SPLB6_PLB_abort => net_gnd0,
      SPLB6_PLB_busLock => net_gnd0,
      SPLB6_PLB_MSize => net_gnd2(1 downto 0),
      SPLB6_PLB_size => net_gnd4,
      SPLB6_PLB_type => net_gnd3,
      SPLB6_PLB_lockErr => net_gnd0,
      SPLB6_PLB_wrPendReq => net_gnd0,
      SPLB6_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB6_PLB_rdPendReq => net_gnd0,
      SPLB6_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB6_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB6_PLB_TAttribute => net_gnd16,
      SPLB6_PLB_rdBurst => net_gnd0,
      SPLB6_PLB_wrBurst => net_gnd0,
      SPLB6_PLB_wrDBus => net_gnd64,
      SPLB6_Sl_addrAck => open,
      SPLB6_Sl_SSize => open,
      SPLB6_Sl_wait => open,
      SPLB6_Sl_rearbitrate => open,
      SPLB6_Sl_wrDAck => open,
      SPLB6_Sl_wrComp => open,
      SPLB6_Sl_wrBTerm => open,
      SPLB6_Sl_rdDBus => open,
      SPLB6_Sl_rdWdAddr => open,
      SPLB6_Sl_rdDAck => open,
      SPLB6_Sl_rdComp => open,
      SPLB6_Sl_rdBTerm => open,
      SPLB6_Sl_MBusy => open,
      SPLB6_Sl_MRdErr => open,
      SPLB6_Sl_MWrErr => open,
      SPLB6_Sl_MIRQ => open,
      SDMA6_Clk => net_gnd0,
      SDMA6_Rx_IntOut => open,
      SDMA6_Tx_IntOut => open,
      SDMA6_RstOut => open,
      SDMA6_TX_D => open,
      SDMA6_TX_Rem => open,
      SDMA6_TX_SOF => open,
      SDMA6_TX_EOF => open,
      SDMA6_TX_SOP => open,
      SDMA6_TX_EOP => open,
      SDMA6_TX_Src_Rdy => open,
      SDMA6_TX_Dst_Rdy => net_vcc0,
      SDMA6_RX_D => net_gnd32,
      SDMA6_RX_Rem => net_vcc4,
      SDMA6_RX_SOF => net_vcc0,
      SDMA6_RX_EOF => net_vcc0,
      SDMA6_RX_SOP => net_vcc0,
      SDMA6_RX_EOP => net_vcc0,
      SDMA6_RX_Src_Rdy => net_vcc0,
      SDMA6_RX_Dst_Rdy => open,
      SDMA_CTRL6_Clk => net_vcc0,
      SDMA_CTRL6_Rst => net_gnd0,
      SDMA_CTRL6_PLB_ABus => net_gnd32,
      SDMA_CTRL6_PLB_PAValid => net_gnd0,
      SDMA_CTRL6_PLB_SAValid => net_gnd0,
      SDMA_CTRL6_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL6_PLB_RNW => net_gnd0,
      SDMA_CTRL6_PLB_BE => net_gnd8,
      SDMA_CTRL6_PLB_UABus => net_gnd32,
      SDMA_CTRL6_PLB_rdPrim => net_gnd0,
      SDMA_CTRL6_PLB_wrPrim => net_gnd0,
      SDMA_CTRL6_PLB_abort => net_gnd0,
      SDMA_CTRL6_PLB_busLock => net_gnd0,
      SDMA_CTRL6_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL6_PLB_size => net_gnd4,
      SDMA_CTRL6_PLB_type => net_gnd3,
      SDMA_CTRL6_PLB_lockErr => net_gnd0,
      SDMA_CTRL6_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL6_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL6_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL6_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL6_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL6_PLB_TAttribute => net_gnd16,
      SDMA_CTRL6_PLB_rdBurst => net_gnd0,
      SDMA_CTRL6_PLB_wrBurst => net_gnd0,
      SDMA_CTRL6_PLB_wrDBus => net_gnd64,
      SDMA_CTRL6_Sl_addrAck => open,
      SDMA_CTRL6_Sl_SSize => open,
      SDMA_CTRL6_Sl_wait => open,
      SDMA_CTRL6_Sl_rearbitrate => open,
      SDMA_CTRL6_Sl_wrDAck => open,
      SDMA_CTRL6_Sl_wrComp => open,
      SDMA_CTRL6_Sl_wrBTerm => open,
      SDMA_CTRL6_Sl_rdDBus => open,
      SDMA_CTRL6_Sl_rdWdAddr => open,
      SDMA_CTRL6_Sl_rdDAck => open,
      SDMA_CTRL6_Sl_rdComp => open,
      SDMA_CTRL6_Sl_rdBTerm => open,
      SDMA_CTRL6_Sl_MBusy => open,
      SDMA_CTRL6_Sl_MRdErr => open,
      SDMA_CTRL6_Sl_MWrErr => open,
      SDMA_CTRL6_Sl_MIRQ => open,
      PIM6_Addr => net_gnd32(0 to 31),
      PIM6_AddrReq => net_gnd0,
      PIM6_AddrAck => open,
      PIM6_RNW => net_gnd0,
      PIM6_Size => net_gnd4(0 to 3),
      PIM6_RdModWr => net_gnd0,
      PIM6_WrFIFO_Data => net_gnd64(0 to 63),
      PIM6_WrFIFO_BE => net_gnd8(0 to 7),
      PIM6_WrFIFO_Push => net_gnd0,
      PIM6_RdFIFO_Data => open,
      PIM6_RdFIFO_Pop => net_gnd0,
      PIM6_RdFIFO_RdWdAddr => open,
      PIM6_WrFIFO_Empty => open,
      PIM6_WrFIFO_AlmostFull => open,
      PIM6_WrFIFO_Flush => net_gnd0,
      PIM6_RdFIFO_Empty => open,
      PIM6_RdFIFO_Flush => net_gnd0,
      PIM6_RdFIFO_Latency => open,
      PIM6_InitDone => open,
      PPC440MC6_MIMCReadNotWrite => net_gnd0,
      PPC440MC6_MIMCAddress => net_gnd36,
      PPC440MC6_MIMCAddressValid => net_gnd0,
      PPC440MC6_MIMCWriteData => net_gnd128,
      PPC440MC6_MIMCWriteDataValid => net_gnd0,
      PPC440MC6_MIMCByteEnable => net_gnd16,
      PPC440MC6_MIMCBankConflict => net_gnd0,
      PPC440MC6_MIMCRowConflict => net_gnd0,
      PPC440MC6_MCMIReadData => open,
      PPC440MC6_MCMIReadDataValid => open,
      PPC440MC6_MCMIReadDataErr => open,
      PPC440MC6_MCMIAddrReadyToAccept => open,
      VFBC6_Cmd_Clk => net_gnd0,
      VFBC6_Cmd_Reset => net_gnd0,
      VFBC6_Cmd_Data => net_gnd32(0 to 31),
      VFBC6_Cmd_Write => net_gnd0,
      VFBC6_Cmd_End => net_gnd0,
      VFBC6_Cmd_Full => open,
      VFBC6_Cmd_Almost_Full => open,
      VFBC6_Cmd_Idle => open,
      VFBC6_Wd_Clk => net_gnd0,
      VFBC6_Wd_Reset => net_gnd0,
      VFBC6_Wd_Write => net_gnd0,
      VFBC6_Wd_End_Burst => net_gnd0,
      VFBC6_Wd_Flush => net_gnd0,
      VFBC6_Wd_Data => net_gnd32(0 to 31),
      VFBC6_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC6_Wd_Full => open,
      VFBC6_Wd_Almost_Full => open,
      VFBC6_Rd_Clk => net_gnd0,
      VFBC6_Rd_Reset => net_gnd0,
      VFBC6_Rd_Read => net_gnd0,
      VFBC6_Rd_End_Burst => net_gnd0,
      VFBC6_Rd_Flush => net_gnd0,
      VFBC6_Rd_Data => open,
      VFBC6_Rd_Empty => open,
      VFBC6_Rd_Almost_Empty => open,
      MCB6_cmd_clk => net_gnd0,
      MCB6_cmd_en => net_gnd0,
      MCB6_cmd_instr => net_gnd3(0 to 2),
      MCB6_cmd_bl => net_gnd6,
      MCB6_cmd_byte_addr => net_gnd30,
      MCB6_cmd_empty => open,
      MCB6_cmd_full => open,
      MCB6_wr_clk => net_gnd0,
      MCB6_wr_en => net_gnd0,
      MCB6_wr_mask => net_gnd8(0 to 7),
      MCB6_wr_data => net_gnd64(0 to 63),
      MCB6_wr_full => open,
      MCB6_wr_empty => open,
      MCB6_wr_count => open,
      MCB6_wr_underrun => open,
      MCB6_wr_error => open,
      MCB6_rd_clk => net_gnd0,
      MCB6_rd_en => net_gnd0,
      MCB6_rd_data => open,
      MCB6_rd_full => open,
      MCB6_rd_empty => open,
      MCB6_rd_count => open,
      MCB6_rd_overflow => open,
      MCB6_rd_error => open,
      FSL7_M_Clk => net_vcc0,
      FSL7_M_Write => net_gnd0,
      FSL7_M_Data => net_gnd32,
      FSL7_M_Control => net_gnd0,
      FSL7_M_Full => open,
      FSL7_S_Clk => net_gnd0,
      FSL7_S_Read => net_gnd0,
      FSL7_S_Data => open,
      FSL7_S_Control => open,
      FSL7_S_Exists => open,
      FSL7_B_M_Clk => net_vcc0,
      FSL7_B_M_Write => net_gnd0,
      FSL7_B_M_Data => net_gnd32,
      FSL7_B_M_Control => net_gnd0,
      FSL7_B_M_Full => open,
      FSL7_B_S_Clk => net_gnd0,
      FSL7_B_S_Read => net_gnd0,
      FSL7_B_S_Data => open,
      FSL7_B_S_Control => open,
      FSL7_B_S_Exists => open,
      SPLB7_Clk => net_vcc0,
      SPLB7_Rst => net_gnd0,
      SPLB7_PLB_ABus => net_gnd32,
      SPLB7_PLB_PAValid => net_gnd0,
      SPLB7_PLB_SAValid => net_gnd0,
      SPLB7_PLB_masterID => net_gnd1(0 downto 0),
      SPLB7_PLB_RNW => net_gnd0,
      SPLB7_PLB_BE => net_gnd8,
      SPLB7_PLB_UABus => net_gnd32,
      SPLB7_PLB_rdPrim => net_gnd0,
      SPLB7_PLB_wrPrim => net_gnd0,
      SPLB7_PLB_abort => net_gnd0,
      SPLB7_PLB_busLock => net_gnd0,
      SPLB7_PLB_MSize => net_gnd2(1 downto 0),
      SPLB7_PLB_size => net_gnd4,
      SPLB7_PLB_type => net_gnd3,
      SPLB7_PLB_lockErr => net_gnd0,
      SPLB7_PLB_wrPendReq => net_gnd0,
      SPLB7_PLB_wrPendPri => net_gnd2(1 downto 0),
      SPLB7_PLB_rdPendReq => net_gnd0,
      SPLB7_PLB_rdPendPri => net_gnd2(1 downto 0),
      SPLB7_PLB_reqPri => net_gnd2(1 downto 0),
      SPLB7_PLB_TAttribute => net_gnd16,
      SPLB7_PLB_rdBurst => net_gnd0,
      SPLB7_PLB_wrBurst => net_gnd0,
      SPLB7_PLB_wrDBus => net_gnd64,
      SPLB7_Sl_addrAck => open,
      SPLB7_Sl_SSize => open,
      SPLB7_Sl_wait => open,
      SPLB7_Sl_rearbitrate => open,
      SPLB7_Sl_wrDAck => open,
      SPLB7_Sl_wrComp => open,
      SPLB7_Sl_wrBTerm => open,
      SPLB7_Sl_rdDBus => open,
      SPLB7_Sl_rdWdAddr => open,
      SPLB7_Sl_rdDAck => open,
      SPLB7_Sl_rdComp => open,
      SPLB7_Sl_rdBTerm => open,
      SPLB7_Sl_MBusy => open,
      SPLB7_Sl_MRdErr => open,
      SPLB7_Sl_MWrErr => open,
      SPLB7_Sl_MIRQ => open,
      SDMA7_Clk => net_gnd0,
      SDMA7_Rx_IntOut => open,
      SDMA7_Tx_IntOut => open,
      SDMA7_RstOut => open,
      SDMA7_TX_D => open,
      SDMA7_TX_Rem => open,
      SDMA7_TX_SOF => open,
      SDMA7_TX_EOF => open,
      SDMA7_TX_SOP => open,
      SDMA7_TX_EOP => open,
      SDMA7_TX_Src_Rdy => open,
      SDMA7_TX_Dst_Rdy => net_vcc0,
      SDMA7_RX_D => net_gnd32,
      SDMA7_RX_Rem => net_vcc4,
      SDMA7_RX_SOF => net_vcc0,
      SDMA7_RX_EOF => net_vcc0,
      SDMA7_RX_SOP => net_vcc0,
      SDMA7_RX_EOP => net_vcc0,
      SDMA7_RX_Src_Rdy => net_vcc0,
      SDMA7_RX_Dst_Rdy => open,
      SDMA_CTRL7_Clk => net_vcc0,
      SDMA_CTRL7_Rst => net_gnd0,
      SDMA_CTRL7_PLB_ABus => net_gnd32,
      SDMA_CTRL7_PLB_PAValid => net_gnd0,
      SDMA_CTRL7_PLB_SAValid => net_gnd0,
      SDMA_CTRL7_PLB_masterID => net_gnd1(0 downto 0),
      SDMA_CTRL7_PLB_RNW => net_gnd0,
      SDMA_CTRL7_PLB_BE => net_gnd8,
      SDMA_CTRL7_PLB_UABus => net_gnd32,
      SDMA_CTRL7_PLB_rdPrim => net_gnd0,
      SDMA_CTRL7_PLB_wrPrim => net_gnd0,
      SDMA_CTRL7_PLB_abort => net_gnd0,
      SDMA_CTRL7_PLB_busLock => net_gnd0,
      SDMA_CTRL7_PLB_MSize => net_gnd2(1 downto 0),
      SDMA_CTRL7_PLB_size => net_gnd4,
      SDMA_CTRL7_PLB_type => net_gnd3,
      SDMA_CTRL7_PLB_lockErr => net_gnd0,
      SDMA_CTRL7_PLB_wrPendReq => net_gnd0,
      SDMA_CTRL7_PLB_wrPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL7_PLB_rdPendReq => net_gnd0,
      SDMA_CTRL7_PLB_rdPendPri => net_gnd2(1 downto 0),
      SDMA_CTRL7_PLB_reqPri => net_gnd2(1 downto 0),
      SDMA_CTRL7_PLB_TAttribute => net_gnd16,
      SDMA_CTRL7_PLB_rdBurst => net_gnd0,
      SDMA_CTRL7_PLB_wrBurst => net_gnd0,
      SDMA_CTRL7_PLB_wrDBus => net_gnd64,
      SDMA_CTRL7_Sl_addrAck => open,
      SDMA_CTRL7_Sl_SSize => open,
      SDMA_CTRL7_Sl_wait => open,
      SDMA_CTRL7_Sl_rearbitrate => open,
      SDMA_CTRL7_Sl_wrDAck => open,
      SDMA_CTRL7_Sl_wrComp => open,
      SDMA_CTRL7_Sl_wrBTerm => open,
      SDMA_CTRL7_Sl_rdDBus => open,
      SDMA_CTRL7_Sl_rdWdAddr => open,
      SDMA_CTRL7_Sl_rdDAck => open,
      SDMA_CTRL7_Sl_rdComp => open,
      SDMA_CTRL7_Sl_rdBTerm => open,
      SDMA_CTRL7_Sl_MBusy => open,
      SDMA_CTRL7_Sl_MRdErr => open,
      SDMA_CTRL7_Sl_MWrErr => open,
      SDMA_CTRL7_Sl_MIRQ => open,
      PIM7_Addr => net_gnd32(0 to 31),
      PIM7_AddrReq => net_gnd0,
      PIM7_AddrAck => open,
      PIM7_RNW => net_gnd0,
      PIM7_Size => net_gnd4(0 to 3),
      PIM7_RdModWr => net_gnd0,
      PIM7_WrFIFO_Data => net_gnd64(0 to 63),
      PIM7_WrFIFO_BE => net_gnd8(0 to 7),
      PIM7_WrFIFO_Push => net_gnd0,
      PIM7_RdFIFO_Data => open,
      PIM7_RdFIFO_Pop => net_gnd0,
      PIM7_RdFIFO_RdWdAddr => open,
      PIM7_WrFIFO_Empty => open,
      PIM7_WrFIFO_AlmostFull => open,
      PIM7_WrFIFO_Flush => net_gnd0,
      PIM7_RdFIFO_Empty => open,
      PIM7_RdFIFO_Flush => net_gnd0,
      PIM7_RdFIFO_Latency => open,
      PIM7_InitDone => open,
      PPC440MC7_MIMCReadNotWrite => net_gnd0,
      PPC440MC7_MIMCAddress => net_gnd36,
      PPC440MC7_MIMCAddressValid => net_gnd0,
      PPC440MC7_MIMCWriteData => net_gnd128,
      PPC440MC7_MIMCWriteDataValid => net_gnd0,
      PPC440MC7_MIMCByteEnable => net_gnd16,
      PPC440MC7_MIMCBankConflict => net_gnd0,
      PPC440MC7_MIMCRowConflict => net_gnd0,
      PPC440MC7_MCMIReadData => open,
      PPC440MC7_MCMIReadDataValid => open,
      PPC440MC7_MCMIReadDataErr => open,
      PPC440MC7_MCMIAddrReadyToAccept => open,
      VFBC7_Cmd_Clk => net_gnd0,
      VFBC7_Cmd_Reset => net_gnd0,
      VFBC7_Cmd_Data => net_gnd32(0 to 31),
      VFBC7_Cmd_Write => net_gnd0,
      VFBC7_Cmd_End => net_gnd0,
      VFBC7_Cmd_Full => open,
      VFBC7_Cmd_Almost_Full => open,
      VFBC7_Cmd_Idle => open,
      VFBC7_Wd_Clk => net_gnd0,
      VFBC7_Wd_Reset => net_gnd0,
      VFBC7_Wd_Write => net_gnd0,
      VFBC7_Wd_End_Burst => net_gnd0,
      VFBC7_Wd_Flush => net_gnd0,
      VFBC7_Wd_Data => net_gnd32(0 to 31),
      VFBC7_Wd_Data_BE => net_gnd4(0 to 3),
      VFBC7_Wd_Full => open,
      VFBC7_Wd_Almost_Full => open,
      VFBC7_Rd_Clk => net_gnd0,
      VFBC7_Rd_Reset => net_gnd0,
      VFBC7_Rd_Read => net_gnd0,
      VFBC7_Rd_End_Burst => net_gnd0,
      VFBC7_Rd_Flush => net_gnd0,
      VFBC7_Rd_Data => open,
      VFBC7_Rd_Empty => open,
      VFBC7_Rd_Almost_Empty => open,
      MCB7_cmd_clk => net_gnd0,
      MCB7_cmd_en => net_gnd0,
      MCB7_cmd_instr => net_gnd3(0 to 2),
      MCB7_cmd_bl => net_gnd6,
      MCB7_cmd_byte_addr => net_gnd30,
      MCB7_cmd_empty => open,
      MCB7_cmd_full => open,
      MCB7_wr_clk => net_gnd0,
      MCB7_wr_en => net_gnd0,
      MCB7_wr_mask => net_gnd8(0 to 7),
      MCB7_wr_data => net_gnd64(0 to 63),
      MCB7_wr_full => open,
      MCB7_wr_empty => open,
      MCB7_wr_count => open,
      MCB7_wr_underrun => open,
      MCB7_wr_error => open,
      MCB7_rd_clk => net_gnd0,
      MCB7_rd_en => net_gnd0,
      MCB7_rd_data => open,
      MCB7_rd_full => open,
      MCB7_rd_empty => open,
      MCB7_rd_count => open,
      MCB7_rd_overflow => open,
      MCB7_rd_error => open,
      MPMC_CTRL_Clk => net_vcc0,
      MPMC_CTRL_Rst => net_gnd0,
      MPMC_CTRL_PLB_ABus => net_gnd32,
      MPMC_CTRL_PLB_PAValid => net_gnd0,
      MPMC_CTRL_PLB_SAValid => net_gnd0,
      MPMC_CTRL_PLB_masterID => net_gnd1(0 downto 0),
      MPMC_CTRL_PLB_RNW => net_gnd0,
      MPMC_CTRL_PLB_BE => net_gnd8,
      MPMC_CTRL_PLB_UABus => net_gnd32,
      MPMC_CTRL_PLB_rdPrim => net_gnd0,
      MPMC_CTRL_PLB_wrPrim => net_gnd0,
      MPMC_CTRL_PLB_abort => net_gnd0,
      MPMC_CTRL_PLB_busLock => net_gnd0,
      MPMC_CTRL_PLB_MSize => net_gnd2(1 downto 0),
      MPMC_CTRL_PLB_size => net_gnd4,
      MPMC_CTRL_PLB_type => net_gnd3,
      MPMC_CTRL_PLB_lockErr => net_gnd0,
      MPMC_CTRL_PLB_wrPendReq => net_gnd0,
      MPMC_CTRL_PLB_wrPendPri => net_gnd2(1 downto 0),
      MPMC_CTRL_PLB_rdPendReq => net_gnd0,
      MPMC_CTRL_PLB_rdPendPri => net_gnd2(1 downto 0),
      MPMC_CTRL_PLB_reqPri => net_gnd2(1 downto 0),
      MPMC_CTRL_PLB_TAttribute => net_gnd16,
      MPMC_CTRL_PLB_rdBurst => net_gnd0,
      MPMC_CTRL_PLB_wrBurst => net_gnd0,
      MPMC_CTRL_PLB_wrDBus => net_gnd64,
      MPMC_CTRL_Sl_addrAck => open,
      MPMC_CTRL_Sl_SSize => open,
      MPMC_CTRL_Sl_wait => open,
      MPMC_CTRL_Sl_rearbitrate => open,
      MPMC_CTRL_Sl_wrDAck => open,
      MPMC_CTRL_Sl_wrComp => open,
      MPMC_CTRL_Sl_wrBTerm => open,
      MPMC_CTRL_Sl_rdDBus => open,
      MPMC_CTRL_Sl_rdWdAddr => open,
      MPMC_CTRL_Sl_rdDAck => open,
      MPMC_CTRL_Sl_rdComp => open,
      MPMC_CTRL_Sl_rdBTerm => open,
      MPMC_CTRL_Sl_MBusy => open,
      MPMC_CTRL_Sl_MRdErr => open,
      MPMC_CTRL_Sl_MWrErr => open,
      MPMC_CTRL_Sl_MIRQ => open,
      MPMC_Clk0 => clk_200_0000MHzMMCM0,
      MPMC_Clk0_DIV2 => net_vcc0,
      MPMC_Clk90 => net_vcc0,
      MPMC_Clk_200MHz => clk_200_0000MHzMMCM0,
      MPMC_Rst => sys_periph_reset(0),
      MPMC_Clk_Mem => clk_400_0000MHzMMCM0,
      MPMC_Clk_Mem_2x => net_vcc0,
      MPMC_Clk_Mem_2x_180 => net_vcc0,
      MPMC_Clk_Mem_2x_CE0 => net_vcc0,
      MPMC_Clk_Mem_2x_CE90 => net_vcc0,
      MPMC_Clk_Rd_Base => clk_400_0000MHzMMCM0_nobuf_varphase,
      MPMC_Clk_Mem_2x_bufpll_o => open,
      MPMC_Clk_Mem_2x_180_bufpll_o => open,
      MPMC_Clk_Mem_2x_CE0_bufpll_o => open,
      MPMC_Clk_Mem_2x_CE90_bufpll_o => open,
      MPMC_PLL_Lock_bufpll_o => open,
      MPMC_PLL_Lock => net_gnd0,
      MPMC_Idelayctrl_Rdy_I => net_vcc0,
      MPMC_Idelayctrl_Rdy_O => open,
      MPMC_InitDone => open,
      MPMC_ECC_Intr => open,
      MPMC_DCM_PSEN => MPMC_DCM_PSEN,
      MPMC_DCM_PSINCDEC => MPMC_DCM_PSINCDEC,
      MPMC_DCM_PSDONE => MPMC_DCM_PSDONE,
      MPMC_MCB_DRP_Clk => net_vcc0,
      SDRAM_Clk => open,
      SDRAM_CE => open,
      SDRAM_CS_n => open,
      SDRAM_RAS_n => open,
      SDRAM_CAS_n => open,
      SDRAM_WE_n => open,
      SDRAM_BankAddr => open,
      SDRAM_Addr => open,
      SDRAM_DQ => open,
      SDRAM_DM => open,
      DDR_Clk => open,
      DDR_Clk_n => open,
      DDR_CE => open,
      DDR_CS_n => open,
      DDR_RAS_n => open,
      DDR_CAS_n => open,
      DDR_WE_n => open,
      DDR_BankAddr => open,
      DDR_Addr => open,
      DDR_DQ => open,
      DDR_DM => open,
      DDR_DQS => open,
      DDR_DQS_Div_O => open,
      DDR_DQS_Div_I => net_gnd0,
      DDR2_Clk => open,
      DDR2_Clk_n => open,
      DDR2_CE => open,
      DDR2_CS_n => open,
      DDR2_ODT => open,
      DDR2_RAS_n => open,
      DDR2_CAS_n => open,
      DDR2_WE_n => open,
      DDR2_BankAddr => open,
      DDR2_Addr => open,
      DDR2_DQ => open,
      DDR2_DM => open,
      DDR2_DQS => open,
      DDR2_DQS_n => open,
      DDR2_DQS_Div_O => open,
      DDR2_DQS_Div_I => net_gnd0,
      DDR3_Clk => pgassign1(0 to 0),
      DDR3_Clk_n => pgassign2(0 to 0),
      DDR3_CE => pgassign3(0 to 0),
      DDR3_CS_n => pgassign4(0 to 0),
      DDR3_ODT => pgassign5(0 to 0),
      DDR3_RAS_n => fpga_0_DDR3_SDRAM_DDR3_RAS_n_pin,
      DDR3_CAS_n => fpga_0_DDR3_SDRAM_DDR3_CAS_n_pin,
      DDR3_WE_n => fpga_0_DDR3_SDRAM_DDR3_WE_n_pin,
      DDR3_BankAddr => fpga_0_DDR3_SDRAM_DDR3_BankAddr_pin,
      DDR3_Addr => fpga_0_DDR3_SDRAM_DDR3_Addr_pin,
      DDR3_DQ => fpga_0_DDR3_SDRAM_DDR3_DQ_pin,
      DDR3_DM => fpga_0_DDR3_SDRAM_DDR3_DM_pin,
      DDR3_Reset_n => fpga_0_DDR3_SDRAM_DDR3_Reset_n_pin,
      DDR3_DQS => fpga_0_DDR3_SDRAM_DDR3_DQS_pin,
      DDR3_DQS_n => fpga_0_DDR3_SDRAM_DDR3_DQS_n_pin,
      mcbx_dram_addr => open,
      mcbx_dram_ba => open,
      mcbx_dram_ras_n => open,
      mcbx_dram_cas_n => open,
      mcbx_dram_we_n => open,
      mcbx_dram_cke => open,
      mcbx_dram_clk => open,
      mcbx_dram_clk_n => open,
      mcbx_dram_dq => open,
      mcbx_dram_dqs => open,
      mcbx_dram_dqs_n => open,
      mcbx_dram_udqs => open,
      mcbx_dram_udqs_n => open,
      mcbx_dram_udm => open,
      mcbx_dram_ldm => open,
      mcbx_dram_odt => open,
      mcbx_dram_ddr3_rst => open,
      selfrefresh_enter => net_gnd0,
      selfrefresh_mode => open,
      calib_recal => net_gnd0,
      rzq => open,
      zio => open
    );

  FLASH_CE_inverter : flash_ce_inverter_wrapper
    port map (
      Op1 => net_gnd1(0 downto 0),
      Op2 => net_gnd1(0 downto 0),
      Res => pgassign6(0 to 0)
    );

  PCIe_Diff_Clk : pcie_diff_clk_wrapper
    port map (
      IBUF_DS_P => pgassign7(0 to 0),
      IBUF_DS_N => pgassign8(0 to 0),
      IBUF_OUT => open,
      OBUF_IN => net_gnd1(0 downto 0),
      OBUF_DS_P => open,
      OBUF_DS_N => open,
      IOBUF_DS_P => open,
      IOBUF_DS_N => open,
      IOBUF_IO_T => net_gnd1(0 downto 0),
      IOBUF_IO_I => net_gnd1(0 downto 0),
      IOBUF_IO_O => open
    );

  clock_generator_0 : clock_generator_0_wrapper
    port map (
      CLKIN => dcm_clk_s,
      CLKOUT0 => clk_100_0000MHzMMCM0,
      CLKOUT1 => clk_200_0000MHzMMCM0,
      CLKOUT2 => clk_400_0000MHzMMCM0,
      CLKOUT3 => clk_400_0000MHzMMCM0_nobuf_varphase,
      CLKOUT4 => open,
      CLKOUT5 => open,
      CLKOUT6 => open,
      CLKOUT7 => open,
      CLKOUT8 => open,
      CLKOUT9 => open,
      CLKOUT10 => open,
      CLKOUT11 => open,
      CLKOUT12 => open,
      CLKOUT13 => open,
      CLKOUT14 => open,
      CLKOUT15 => open,
      CLKFBIN => net_gnd0,
      CLKFBOUT => open,
      PSCLK => clk_200_0000MHzMMCM0,
      PSEN => MPMC_DCM_PSEN,
      PSINCDEC => MPMC_DCM_PSINCDEC,
      PSDONE => MPMC_DCM_PSDONE,
      RST => sys_rst_s,
      LOCKED => Dcm_all_locked
    );

  mdm_0 : mdm_0_wrapper
    port map (
      Interrupt => open,
      Debug_SYS_Rst => Debug_SYS_Rst,
      Ext_BRK => Ext_BRK,
      Ext_NM_BRK => Ext_NM_BRK,
      S_AXI_ACLK => net_gnd0,
      S_AXI_ARESETN => net_gnd0,
      S_AXI_AWADDR => net_gnd32(0 to 31),
      S_AXI_AWVALID => net_gnd0,
      S_AXI_AWREADY => open,
      S_AXI_WDATA => net_gnd32(0 to 31),
      S_AXI_WSTRB => net_gnd4(0 to 3),
      S_AXI_WVALID => net_gnd0,
      S_AXI_WREADY => open,
      S_AXI_BRESP => open,
      S_AXI_BVALID => open,
      S_AXI_BREADY => net_gnd0,
      S_AXI_ARADDR => net_gnd32(0 to 31),
      S_AXI_ARVALID => net_gnd0,
      S_AXI_ARREADY => open,
      S_AXI_RDATA => open,
      S_AXI_RRESP => open,
      S_AXI_RVALID => open,
      S_AXI_RREADY => net_gnd0,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(11),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(11),
      PLB_wrPrim => mb_plb_PLB_wrPrim(11),
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(11),
      Sl_SSize => mb_plb_Sl_SSize(22 to 23),
      Sl_wait => mb_plb_Sl_wait(11),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(11),
      Sl_wrDAck => mb_plb_Sl_wrDAck(11),
      Sl_wrComp => mb_plb_Sl_wrComp(11),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(11),
      Sl_rdDBus => mb_plb_Sl_rdDBus(704 to 767),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(44 to 47),
      Sl_rdDAck => mb_plb_Sl_rdDAck(11),
      Sl_rdComp => mb_plb_Sl_rdComp(11),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(11),
      Sl_MBusy => mb_plb_Sl_MBusy(33 to 35),
      Sl_MWrErr => mb_plb_Sl_MWrErr(33 to 35),
      Sl_MRdErr => mb_plb_Sl_MRdErr(33 to 35),
      Sl_MIRQ => mb_plb_Sl_MIRQ(33 to 35),
      Dbg_Clk_0 => microblaze_0_mdm_bus_Dbg_Clk,
      Dbg_TDI_0 => microblaze_0_mdm_bus_Dbg_TDI,
      Dbg_TDO_0 => microblaze_0_mdm_bus_Dbg_TDO,
      Dbg_Reg_En_0 => microblaze_0_mdm_bus_Dbg_Reg_En,
      Dbg_Capture_0 => microblaze_0_mdm_bus_Dbg_Capture,
      Dbg_Shift_0 => microblaze_0_mdm_bus_Dbg_Shift,
      Dbg_Update_0 => microblaze_0_mdm_bus_Dbg_Update,
      Dbg_Rst_0 => microblaze_0_mdm_bus_Debug_Rst,
      Dbg_Clk_1 => open,
      Dbg_TDI_1 => open,
      Dbg_TDO_1 => net_gnd0,
      Dbg_Reg_En_1 => open,
      Dbg_Capture_1 => open,
      Dbg_Shift_1 => open,
      Dbg_Update_1 => open,
      Dbg_Rst_1 => open,
      Dbg_Clk_2 => open,
      Dbg_TDI_2 => open,
      Dbg_TDO_2 => net_gnd0,
      Dbg_Reg_En_2 => open,
      Dbg_Capture_2 => open,
      Dbg_Shift_2 => open,
      Dbg_Update_2 => open,
      Dbg_Rst_2 => open,
      Dbg_Clk_3 => open,
      Dbg_TDI_3 => open,
      Dbg_TDO_3 => net_gnd0,
      Dbg_Reg_En_3 => open,
      Dbg_Capture_3 => open,
      Dbg_Shift_3 => open,
      Dbg_Update_3 => open,
      Dbg_Rst_3 => open,
      Dbg_Clk_4 => open,
      Dbg_TDI_4 => open,
      Dbg_TDO_4 => net_gnd0,
      Dbg_Reg_En_4 => open,
      Dbg_Capture_4 => open,
      Dbg_Shift_4 => open,
      Dbg_Update_4 => open,
      Dbg_Rst_4 => open,
      Dbg_Clk_5 => open,
      Dbg_TDI_5 => open,
      Dbg_TDO_5 => net_gnd0,
      Dbg_Reg_En_5 => open,
      Dbg_Capture_5 => open,
      Dbg_Shift_5 => open,
      Dbg_Update_5 => open,
      Dbg_Rst_5 => open,
      Dbg_Clk_6 => open,
      Dbg_TDI_6 => open,
      Dbg_TDO_6 => net_gnd0,
      Dbg_Reg_En_6 => open,
      Dbg_Capture_6 => open,
      Dbg_Shift_6 => open,
      Dbg_Update_6 => open,
      Dbg_Rst_6 => open,
      Dbg_Clk_7 => open,
      Dbg_TDI_7 => open,
      Dbg_TDO_7 => net_gnd0,
      Dbg_Reg_En_7 => open,
      Dbg_Capture_7 => open,
      Dbg_Shift_7 => open,
      Dbg_Update_7 => open,
      Dbg_Rst_7 => open,
      bscan_tdi => open,
      bscan_reset => open,
      bscan_shift => open,
      bscan_update => open,
      bscan_capture => open,
      bscan_sel1 => open,
      bscan_drck1 => open,
      bscan_tdo1 => net_gnd0,
      Ext_JTAG_DRCK => open,
      Ext_JTAG_RESET => open,
      Ext_JTAG_SEL => open,
      Ext_JTAG_CAPTURE => open,
      Ext_JTAG_SHIFT => open,
      Ext_JTAG_UPDATE => open,
      Ext_JTAG_TDI => open,
      Ext_JTAG_TDO => net_gnd0
    );

  proc_sys_reset_0 : proc_sys_reset_0_wrapper
    port map (
      Slowest_sync_clk => clk_100_0000MHzMMCM0,
      Ext_Reset_In => sys_rst_s,
      Aux_Reset_In => net_gnd0,
      MB_Debug_Sys_Rst => Debug_SYS_Rst,
      Core_Reset_Req_0 => net_gnd0,
      Chip_Reset_Req_0 => net_gnd0,
      System_Reset_Req_0 => net_gnd0,
      Core_Reset_Req_1 => net_gnd0,
      Chip_Reset_Req_1 => net_gnd0,
      System_Reset_Req_1 => net_gnd0,
      Dcm_locked => Dcm_all_locked,
      RstcPPCresetcore_0 => open,
      RstcPPCresetchip_0 => open,
      RstcPPCresetsys_0 => open,
      RstcPPCresetcore_1 => open,
      RstcPPCresetchip_1 => open,
      RstcPPCresetsys_1 => open,
      MB_Reset => mb_reset,
      Bus_Struct_Reset => sys_bus_reset(0 to 0),
      Peripheral_Reset => sys_periph_reset(0 to 0),
      Interconnect_aresetn => open,
      Peripheral_aresetn => open
    );

  xps_intc_0 : xps_intc_0_wrapper
    port map (
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(12),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(12),
      PLB_wrPrim => mb_plb_PLB_wrPrim(12),
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_addrAck => mb_plb_Sl_addrAck(12),
      Sl_SSize => mb_plb_Sl_SSize(24 to 25),
      Sl_wait => mb_plb_Sl_wait(12),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(12),
      Sl_wrDAck => mb_plb_Sl_wrDAck(12),
      Sl_wrComp => mb_plb_Sl_wrComp(12),
      Sl_rdDBus => mb_plb_Sl_rdDBus(768 to 831),
      Sl_rdDAck => mb_plb_Sl_rdDAck(12),
      Sl_rdComp => mb_plb_Sl_rdComp(12),
      Sl_MBusy => mb_plb_Sl_MBusy(36 to 38),
      Sl_MWrErr => mb_plb_Sl_MWrErr(36 to 38),
      Sl_MRdErr => mb_plb_Sl_MRdErr(36 to 38),
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(12),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(48 to 51),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(12),
      Sl_MIRQ => mb_plb_Sl_MIRQ(36 to 38),
      Intr => pgassign9,
      Irq => microblaze_0_Interrupt
    );

  xps_timer_0 : xps_timer_0_wrapper
    port map (
      CaptureTrig0 => net_gnd0,
      CaptureTrig1 => net_gnd0,
      GenerateOut0 => open,
      GenerateOut1 => open,
      PWM0 => open,
      Interrupt => xps_timer_0_Interrupt,
      Freeze => net_gnd0,
      SPLB_Clk => clk_100_0000MHzMMCM0,
      SPLB_Rst => mb_plb_SPLB_Rst(13),
      PLB_ABus => mb_plb_PLB_ABus,
      PLB_PAValid => mb_plb_PLB_PAValid,
      PLB_masterID => mb_plb_PLB_masterID,
      PLB_RNW => mb_plb_PLB_RNW,
      PLB_BE => mb_plb_PLB_BE,
      PLB_size => mb_plb_PLB_size,
      PLB_type => mb_plb_PLB_type,
      PLB_wrDBus => mb_plb_PLB_wrDBus,
      Sl_addrAck => mb_plb_Sl_addrAck(13),
      Sl_SSize => mb_plb_Sl_SSize(26 to 27),
      Sl_wait => mb_plb_Sl_wait(13),
      Sl_rearbitrate => mb_plb_Sl_rearbitrate(13),
      Sl_wrDAck => mb_plb_Sl_wrDAck(13),
      Sl_wrComp => mb_plb_Sl_wrComp(13),
      Sl_rdDBus => mb_plb_Sl_rdDBus(832 to 895),
      Sl_rdDAck => mb_plb_Sl_rdDAck(13),
      Sl_rdComp => mb_plb_Sl_rdComp(13),
      Sl_MBusy => mb_plb_Sl_MBusy(39 to 41),
      Sl_MWrErr => mb_plb_Sl_MWrErr(39 to 41),
      Sl_MRdErr => mb_plb_Sl_MRdErr(39 to 41),
      PLB_UABus => mb_plb_PLB_UABus,
      PLB_SAValid => mb_plb_PLB_SAValid,
      PLB_rdPrim => mb_plb_PLB_rdPrim(13),
      PLB_wrPrim => mb_plb_PLB_wrPrim(13),
      PLB_abort => mb_plb_PLB_abort,
      PLB_busLock => mb_plb_PLB_busLock,
      PLB_MSize => mb_plb_PLB_MSize,
      PLB_lockErr => mb_plb_PLB_lockErr,
      PLB_wrBurst => mb_plb_PLB_wrBurst,
      PLB_rdBurst => mb_plb_PLB_rdBurst,
      PLB_wrPendReq => mb_plb_PLB_wrPendReq,
      PLB_rdPendReq => mb_plb_PLB_rdPendReq,
      PLB_wrPendPri => mb_plb_PLB_wrPendPri,
      PLB_rdPendPri => mb_plb_PLB_rdPendPri,
      PLB_reqPri => mb_plb_PLB_reqPri,
      PLB_TAttribute => mb_plb_PLB_TAttribute,
      Sl_wrBTerm => mb_plb_Sl_wrBTerm(13),
      Sl_rdWdAddr => mb_plb_Sl_rdWdAddr(52 to 55),
      Sl_rdBTerm => mb_plb_Sl_rdBTerm(13),
      Sl_MIRQ => mb_plb_Sl_MIRQ(39 to 41)
    );

  fsl_v20_0 : fsl_v20_0_wrapper
    port map (
      FSL_Clk => clk_100_0000MHzMMCM0,
      SYS_Rst => proc_control_0_reset0,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_v20_0_FSL_M_Data,
      FSL_M_Control => fsl_v20_0_FSL_M_Control,
      FSL_M_Write => fsl_v20_0_FSL_M_Write,
      FSL_M_Full => fsl_v20_0_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_v20_0_FSL_S_Data,
      FSL_S_Control => fsl_v20_0_FSL_S_Control,
      FSL_S_Read => fsl_v20_0_FSL_S_Read,
      FSL_S_Exists => fsl_v20_0_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => fsl_v20_0_FSL_Has_Data,
      FSL_Control_IRQ => open
    );

  fsl_v20_1 : fsl_v20_1_wrapper
    port map (
      FSL_Clk => clk_100_0000MHzMMCM0,
      SYS_Rst => proc_control_0_reset0,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_v20_1_FSL_M_Data,
      FSL_M_Control => fsl_v20_1_FSL_M_Control,
      FSL_M_Write => fsl_v20_1_FSL_M_Write,
      FSL_M_Full => fsl_v20_1_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_v20_1_FSL_S_Data,
      FSL_S_Control => fsl_v20_1_FSL_S_Control,
      FSL_S_Read => fsl_v20_1_FSL_S_Read,
      FSL_S_Exists => fsl_v20_1_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_v20_2 : fsl_v20_2_wrapper
    port map (
      FSL_Clk => clk_100_0000MHzMMCM0,
      SYS_Rst => proc_control_0_reconos_reset,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_v20_2_FSL_M_Data,
      FSL_M_Control => fsl_v20_2_FSL_M_Control,
      FSL_M_Write => fsl_v20_2_FSL_M_Write,
      FSL_M_Full => fsl_v20_2_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_v20_2_FSL_S_Data,
      FSL_S_Control => fsl_v20_2_FSL_S_Control,
      FSL_S_Read => fsl_v20_2_FSL_S_Read,
      FSL_S_Exists => fsl_v20_2_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => fsl_v20_2_FSL_Has_Data,
      FSL_Control_IRQ => open
    );

  fsl_v20_3 : fsl_v20_3_wrapper
    port map (
      FSL_Clk => clk_100_0000MHzMMCM0,
      SYS_Rst => proc_control_0_reconos_reset,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_v20_3_FSL_M_Data,
      FSL_M_Control => fsl_v20_3_FSL_M_Control,
      FSL_M_Write => fsl_v20_3_FSL_M_Write,
      FSL_M_Full => fsl_v20_3_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_v20_3_FSL_S_Data,
      FSL_S_Control => fsl_v20_3_FSL_S_Control,
      FSL_S_Read => fsl_v20_3_FSL_S_Read,
      FSL_S_Exists => fsl_v20_3_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  proc_control_0 : proc_control_0_wrapper
    port map (
      FSL_Clk => clk_100_0000MHzMMCM0,
      FSL_Rst => net_gnd0,
      FSL_S_Clk => open,
      FSL_S_Read => fsl_v20_3_FSL_S_Read,
      FSL_S_Data => fsl_v20_3_FSL_S_Data,
      FSL_S_Control => fsl_v20_3_FSL_S_Control,
      FSL_S_Exists => fsl_v20_3_FSL_S_Exists,
      FSL_M_Clk => open,
      FSL_M_Write => fsl_v20_2_FSL_M_Write,
      FSL_M_Data => fsl_v20_2_FSL_M_Data,
      FSL_M_Control => fsl_v20_2_FSL_M_Control,
      FSL_M_Full => fsl_v20_2_FSL_M_Full,
      reset0 => proc_control_0_reset0,
      reset1 => open,
      reset2 => open,
      reset3 => open,
      reset4 => open,
      reset5 => open,
      reset6 => open,
      reset7 => open,
      reset8 => open,
      reset9 => open,
      resetA => open,
      resetB => open,
      resetC => open,
      resetD => open,
      resetE => open,
      resetF => open,
      page_fault => mmu_0_PAGE_FAULT,
      fault_addr => mmu_0_FAULT_ADDR,
      retry => proc_control_0_retry,
      pgd => proc_control_0_pgd,
      reconos_reset => proc_control_0_reconos_reset
    );

  xps_mem_0 : xps_mem_0_wrapper
    port map (
      MPLB_Clk => clk_100_0000MHzMMCM0,
      MPLB_Rst => mb_plb_MPLB_Rst(2),
      MD_error => open,
      M_request => mb_plb_M_request(2),
      M_priority => mb_plb_M_priority(4 to 5),
      M_busLock => mb_plb_M_busLock(2),
      M_RNW => mb_plb_M_RNW(2),
      M_BE => mb_plb_M_BE(16 to 23),
      M_MSize => mb_plb_M_MSize(4 to 5),
      M_size => mb_plb_M_size(8 to 11),
      M_type => mb_plb_M_type(6 to 8),
      M_TAttribute => mb_plb_M_TAttribute(32 to 47),
      M_lockErr => mb_plb_M_lockErr(2),
      M_abort => mb_plb_M_ABort(2),
      M_UABus => mb_plb_M_UABus(64 to 95),
      M_ABus => mb_plb_M_ABus(64 to 95),
      M_wrDBus => mb_plb_M_wrDBus(128 to 191),
      M_wrBurst => mb_plb_M_wrBurst(2),
      M_rdBurst => mb_plb_M_rdBurst(2),
      PLB_MAddrAck => mb_plb_PLB_MAddrAck(2),
      PLB_MSSize => mb_plb_PLB_MSSize(4 to 5),
      PLB_MRearbitrate => mb_plb_PLB_MRearbitrate(2),
      PLB_MTimeout => mb_plb_PLB_MTimeout(2),
      PLB_MBusy => mb_plb_PLB_MBusy(2),
      PLB_MRdErr => mb_plb_PLB_MRdErr(2),
      PLB_MWrErr => mb_plb_PLB_MWrErr(2),
      PLB_MIRQ => mb_plb_PLB_MIRQ(2),
      PLB_MRdDBus => mb_plb_PLB_MRdDBus(128 to 191),
      PLB_MRdWdAddr => mb_plb_PLB_MRdWdAddr(8 to 11),
      PLB_MRdDAck => mb_plb_PLB_MRdDAck(2),
      PLB_MRdBTerm => mb_plb_PLB_MRdBTerm(2),
      PLB_MWrDAck => mb_plb_PLB_MWrDAck(2),
      PLB_MWrBTerm => mb_plb_PLB_MWrBTerm(2),
      FIFO32_S_Clk => mmu_0_MEM_SFIFO32_FIFO32_S_Clk,
      FIFO32_S_Data => mmu_0_MEM_SFIFO32_FIFO32_S_Data,
      FIFO32_S_Rd => mmu_0_MEM_SFIFO32_FIFO32_S_Rd,
      FIFO32_S_Fill => mmu_0_MEM_SFIFO32_FIFO32_S_Fill,
      FIFO32_M_Clk => mmu_0_MEM_MFIFO32_FIFO32_M_Clk,
      FIFO32_M_Data => mmu_0_MEM_MFIFO32_FIFO32_M_Data,
      FIFO32_M_Wr => mmu_0_MEM_MFIFO32_FIFO32_M_Wr,
      FIFO32_M_Rem => mmu_0_MEM_MFIFO32_FIFO32_M_Rem
    );

  fifo32_0 : fifo32_0_wrapper
    port map (
      Rst => proc_control_0_reconos_reset,
      FIFO32_S_Clk => fifo32_0_SFIFO32_FIFO32_S_Clk,
      FIFO32_S_Data => fifo32_0_SFIFO32_FIFO32_S_Data,
      FIFO32_S_Rd => fifo32_0_SFIFO32_FIFO32_S_Rd,
      FIFO32_S_Fill => fifo32_0_SFIFO32_FIFO32_S_Fill,
      FIFO32_M_Clk => fifo32_0_MFIFO32_FIFO32_M_Clk,
      FIFO32_M_Data => fifo32_0_MFIFO32_FIFO32_M_Data,
      FIFO32_M_Wr => fifo32_0_MFIFO32_FIFO32_M_Wr,
      FIFO32_M_Rem => fifo32_0_MFIFO32_FIFO32_M_Rem
    );

  fifo32_1 : fifo32_1_wrapper
    port map (
      Rst => proc_control_0_reconos_reset,
      FIFO32_S_Clk => fifo32_1_SFIFO32_FIFO32_S_Clk,
      FIFO32_S_Data => fifo32_1_SFIFO32_FIFO32_S_Data,
      FIFO32_S_Rd => fifo32_1_SFIFO32_FIFO32_S_Rd,
      FIFO32_S_Fill => fifo32_1_SFIFO32_FIFO32_S_Fill,
      FIFO32_M_Clk => fifo32_1_MFIFO32_FIFO32_M_Clk,
      FIFO32_M_Data => fifo32_1_MFIFO32_FIFO32_M_Data,
      FIFO32_M_Wr => fifo32_1_MFIFO32_FIFO32_M_Wr,
      FIFO32_M_Rem => fifo32_1_MFIFO32_FIFO32_M_Rem
    );

  hwt_memaccess_0 : hwt_memaccess_0_wrapper
    port map (
      OSFSL_Clk => clk_100_0000MHzMMCM0,
      OSFSL_Rst => net_gnd0,
      OSFSL_S_Clk => open,
      OSFSL_S_Read => fsl_v20_1_FSL_S_Read,
      OSFSL_S_Data => fsl_v20_1_FSL_S_Data,
      OSFSL_S_Control => fsl_v20_1_FSL_S_Control,
      OSFSL_S_Exists => fsl_v20_1_FSL_S_Exists,
      OSFSL_M_Clk => open,
      OSFSL_M_Write => fsl_v20_0_FSL_M_Write,
      OSFSL_M_Data => fsl_v20_0_FSL_M_Data,
      OSFSL_M_Control => fsl_v20_0_FSL_M_Control,
      OSFSL_M_Full => fsl_v20_0_FSL_M_Full,
      FIFO32_S_Clk => fifo32_1_SFIFO32_FIFO32_S_Clk,
      FIFO32_S_Data => fifo32_1_SFIFO32_FIFO32_S_Data,
      FIFO32_S_Rd => fifo32_1_SFIFO32_FIFO32_S_Rd,
      FIFO32_S_Fill => fifo32_1_SFIFO32_FIFO32_S_Fill,
      FIFO32_M_Clk => fifo32_0_MFIFO32_FIFO32_M_Clk,
      FIFO32_M_Data => fifo32_0_MFIFO32_FIFO32_M_Data,
      FIFO32_M_Wr => fifo32_0_MFIFO32_FIFO32_M_Wr,
      FIFO32_M_Rem => fifo32_0_MFIFO32_FIFO32_M_Rem,
      Rst => proc_control_0_reset0
    );

  mmu_0 : mmu_0_wrapper
    port map (
      HWT_FIFO32_S_Clk => fifo32_0_SFIFO32_FIFO32_S_Clk,
      HWT_FIFO32_S_Data => fifo32_0_SFIFO32_FIFO32_S_Data,
      HWT_FIFO32_S_Rd => fifo32_0_SFIFO32_FIFO32_S_Rd,
      HWT_FIFO32_S_Fill => fifo32_0_SFIFO32_FIFO32_S_Fill,
      HWT_FIFO32_M_Clk => fifo32_1_MFIFO32_FIFO32_M_Clk,
      HWT_FIFO32_M_Data => fifo32_1_MFIFO32_FIFO32_M_Data,
      HWT_FIFO32_M_Wr => fifo32_1_MFIFO32_FIFO32_M_Wr,
      HWT_FIFO32_M_Rem => fifo32_1_MFIFO32_FIFO32_M_Rem,
      MEM_FIFO32_S_Clk => mmu_0_MEM_SFIFO32_FIFO32_S_Clk,
      MEM_FIFO32_S_Data => mmu_0_MEM_SFIFO32_FIFO32_S_Data,
      MEM_FIFO32_S_Rd => mmu_0_MEM_SFIFO32_FIFO32_S_Rd,
      MEM_FIFO32_S_Fill => mmu_0_MEM_SFIFO32_FIFO32_S_Fill,
      MEM_FIFO32_M_Clk => mmu_0_MEM_MFIFO32_FIFO32_M_Clk,
      MEM_FIFO32_M_Data => mmu_0_MEM_MFIFO32_FIFO32_M_Data,
      MEM_FIFO32_M_Wr => mmu_0_MEM_MFIFO32_FIFO32_M_Wr,
      MEM_FIFO32_M_Rem => mmu_0_MEM_MFIFO32_FIFO32_M_Rem,
      RETRY => proc_control_0_retry,
      PAGE_FAULT => mmu_0_PAGE_FAULT,
      FAULT_ADDR => mmu_0_FAULT_ADDR,
      PGD => proc_control_0_pgd,
      Rst => proc_control_0_reconos_reset,
      Clk => clk_100_0000MHzMMCM0
    );

  iobuf_0 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(0),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(0),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(0),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(0)
    );

  iobuf_1 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(1),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(1),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(1),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(1)
    );

  iobuf_2 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(2),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(2),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(2),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(2)
    );

  iobuf_3 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(3),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(3),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(3),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(3)
    );

  iobuf_4 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(4),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(4),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(4),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(4)
    );

  iobuf_5 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(5),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(5),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(5),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(5)
    );

  iobuf_6 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(6),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(6),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(6),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(6)
    );

  iobuf_7 : IOBUF
    port map (
      I => fpga_0_LEDs_8Bit_GPIO_IO_pin_O(7),
      IO => fpga_0_LEDs_8Bit_GPIO_IO_pin(7),
      O => fpga_0_LEDs_8Bit_GPIO_IO_pin_I(7),
      T => fpga_0_LEDs_8Bit_GPIO_IO_pin_T(7)
    );

  iobuf_8 : IOBUF
    port map (
      I => fpga_0_LEDs_Positions_GPIO_IO_pin_O(0),
      IO => fpga_0_LEDs_Positions_GPIO_IO_pin(0),
      O => fpga_0_LEDs_Positions_GPIO_IO_pin_I(0),
      T => fpga_0_LEDs_Positions_GPIO_IO_pin_T(0)
    );

  iobuf_9 : IOBUF
    port map (
      I => fpga_0_LEDs_Positions_GPIO_IO_pin_O(1),
      IO => fpga_0_LEDs_Positions_GPIO_IO_pin(1),
      O => fpga_0_LEDs_Positions_GPIO_IO_pin_I(1),
      T => fpga_0_LEDs_Positions_GPIO_IO_pin_T(1)
    );

  iobuf_10 : IOBUF
    port map (
      I => fpga_0_LEDs_Positions_GPIO_IO_pin_O(2),
      IO => fpga_0_LEDs_Positions_GPIO_IO_pin(2),
      O => fpga_0_LEDs_Positions_GPIO_IO_pin_I(2),
      T => fpga_0_LEDs_Positions_GPIO_IO_pin_T(2)
    );

  iobuf_11 : IOBUF
    port map (
      I => fpga_0_LEDs_Positions_GPIO_IO_pin_O(3),
      IO => fpga_0_LEDs_Positions_GPIO_IO_pin(3),
      O => fpga_0_LEDs_Positions_GPIO_IO_pin_I(3),
      T => fpga_0_LEDs_Positions_GPIO_IO_pin_T(3)
    );

  iobuf_12 : IOBUF
    port map (
      I => fpga_0_LEDs_Positions_GPIO_IO_pin_O(4),
      IO => fpga_0_LEDs_Positions_GPIO_IO_pin(4),
      O => fpga_0_LEDs_Positions_GPIO_IO_pin_I(4),
      T => fpga_0_LEDs_Positions_GPIO_IO_pin_T(4)
    );

  iobuf_13 : IOBUF
    port map (
      I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O(0),
      IO => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin(0),
      O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I(0),
      T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T(0)
    );

  iobuf_14 : IOBUF
    port map (
      I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O(1),
      IO => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin(1),
      O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I(1),
      T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T(1)
    );

  iobuf_15 : IOBUF
    port map (
      I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O(2),
      IO => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin(2),
      O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I(2),
      T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T(2)
    );

  iobuf_16 : IOBUF
    port map (
      I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O(3),
      IO => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin(3),
      O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I(3),
      T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T(3)
    );

  iobuf_17 : IOBUF
    port map (
      I => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_O(4),
      IO => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin(4),
      O => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_I(4),
      T => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin_T(4)
    );

  iobuf_18 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(0),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(0),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(0),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(0)
    );

  iobuf_19 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(1),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(1),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(1),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(1)
    );

  iobuf_20 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(2),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(2),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(2),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(2)
    );

  iobuf_21 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(3),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(3),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(3),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(3)
    );

  iobuf_22 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(4),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(4),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(4),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(4)
    );

  iobuf_23 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(5),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(5),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(5),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(5)
    );

  iobuf_24 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(6),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(6),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(6),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(6)
    );

  iobuf_25 : IOBUF
    port map (
      I => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_O(7),
      IO => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin(7),
      O => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_I(7),
      T => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin_T(7)
    );

  iobuf_26 : IOBUF
    port map (
      I => fpga_0_IIC_EEPROM_Sda_pin_O,
      IO => fpga_0_IIC_EEPROM_Sda_pin,
      O => fpga_0_IIC_EEPROM_Sda_pin_I,
      T => fpga_0_IIC_EEPROM_Sda_pin_T
    );

  iobuf_27 : IOBUF
    port map (
      I => fpga_0_IIC_EEPROM_Scl_pin_O,
      IO => fpga_0_IIC_EEPROM_Scl_pin,
      O => fpga_0_IIC_EEPROM_Scl_pin_I,
      T => fpga_0_IIC_EEPROM_Scl_pin_T
    );

  iobuf_28 : IOBUF
    port map (
      I => fpga_0_IIC_FMC_LPC_Sda_pin_O,
      IO => fpga_0_IIC_FMC_LPC_Sda_pin,
      O => fpga_0_IIC_FMC_LPC_Sda_pin_I,
      T => fpga_0_IIC_FMC_LPC_Sda_pin_T
    );

  iobuf_29 : IOBUF
    port map (
      I => fpga_0_IIC_FMC_LPC_Scl_pin_O,
      IO => fpga_0_IIC_FMC_LPC_Scl_pin,
      O => fpga_0_IIC_FMC_LPC_Scl_pin_I,
      T => fpga_0_IIC_FMC_LPC_Scl_pin_T
    );

  iobuf_30 : IOBUF
    port map (
      I => fpga_0_IIC_DVI_Sda_pin_O,
      IO => fpga_0_IIC_DVI_Sda_pin,
      O => fpga_0_IIC_DVI_Sda_pin_I,
      T => fpga_0_IIC_DVI_Sda_pin_T
    );

  iobuf_31 : IOBUF
    port map (
      I => fpga_0_IIC_DVI_Scl_pin_O,
      IO => fpga_0_IIC_DVI_Scl_pin,
      O => fpga_0_IIC_DVI_Scl_pin_I,
      T => fpga_0_IIC_DVI_Scl_pin_T
    );

  iobuf_32 : IOBUF
    port map (
      I => fpga_0_IIC_SFP_Sda_pin_O,
      IO => fpga_0_IIC_SFP_Sda_pin,
      O => fpga_0_IIC_SFP_Sda_pin_I,
      T => fpga_0_IIC_SFP_Sda_pin_T
    );

  iobuf_33 : IOBUF
    port map (
      I => fpga_0_IIC_SFP_Scl_pin_O,
      IO => fpga_0_IIC_SFP_Scl_pin,
      O => fpga_0_IIC_SFP_Scl_pin_I,
      T => fpga_0_IIC_SFP_Scl_pin_T
    );

  iobuf_34 : IOBUF
    port map (
      I => fpga_0_Ethernet_MAC_PHY_MDIO_pin_O,
      IO => fpga_0_Ethernet_MAC_PHY_MDIO_pin,
      O => fpga_0_Ethernet_MAC_PHY_MDIO_pin_I,
      T => fpga_0_Ethernet_MAC_PHY_MDIO_pin_T
    );

  ibufgds_35 : IBUFGDS
    port map (
      I => fpga_0_clk_1_sys_clk_p_pin,
      IB => fpga_0_clk_1_sys_clk_n_pin,
      O => dcm_clk_s
    );

end architecture STRUCTURE;

