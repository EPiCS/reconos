-------------------------------------------------------------------------------
-- system_stub.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity system_stub is
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
end system_stub;

architecture STRUCTURE of system_stub is

  component system is
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
  end component;

  attribute BUFFER_TYPE : STRING;
  attribute BOX_TYPE : STRING;
  attribute BUFFER_TYPE of fpga_0_Ethernet_MAC_PHY_tx_clk_pin : signal is "IBUF";
  attribute BUFFER_TYPE of fpga_0_Ethernet_MAC_PHY_rx_clk_pin : signal is "IBUF";
  attribute BOX_TYPE of system : component is "user_black_box";

begin

  system_i : system
    port map (
      fpga_0_RS232_Uart_1_RX_pin => fpga_0_RS232_Uart_1_RX_pin,
      fpga_0_RS232_Uart_1_TX_pin => fpga_0_RS232_Uart_1_TX_pin,
      fpga_0_LEDs_8Bit_GPIO_IO_pin => fpga_0_LEDs_8Bit_GPIO_IO_pin,
      fpga_0_LEDs_Positions_GPIO_IO_pin => fpga_0_LEDs_Positions_GPIO_IO_pin,
      fpga_0_Push_Buttons_5Bit_GPIO_IO_pin => fpga_0_Push_Buttons_5Bit_GPIO_IO_pin,
      fpga_0_DIP_Switches_8Bit_GPIO_IO_pin => fpga_0_DIP_Switches_8Bit_GPIO_IO_pin,
      fpga_0_IIC_EEPROM_Sda_pin => fpga_0_IIC_EEPROM_Sda_pin,
      fpga_0_IIC_EEPROM_Scl_pin => fpga_0_IIC_EEPROM_Scl_pin,
      fpga_0_IIC_FMC_LPC_Sda_pin => fpga_0_IIC_FMC_LPC_Sda_pin,
      fpga_0_IIC_FMC_LPC_Scl_pin => fpga_0_IIC_FMC_LPC_Scl_pin,
      fpga_0_IIC_DVI_Sda_pin => fpga_0_IIC_DVI_Sda_pin,
      fpga_0_IIC_DVI_Scl_pin => fpga_0_IIC_DVI_Scl_pin,
      fpga_0_IIC_SFP_Sda_pin => fpga_0_IIC_SFP_Sda_pin,
      fpga_0_IIC_SFP_Scl_pin => fpga_0_IIC_SFP_Scl_pin,
      fpga_0_FLASH_Mem_A_pin => fpga_0_FLASH_Mem_A_pin,
      fpga_0_Ethernet_MAC_PHY_tx_clk_pin => fpga_0_Ethernet_MAC_PHY_tx_clk_pin,
      fpga_0_Ethernet_MAC_PHY_rx_clk_pin => fpga_0_Ethernet_MAC_PHY_rx_clk_pin,
      fpga_0_Ethernet_MAC_PHY_crs_pin => fpga_0_Ethernet_MAC_PHY_crs_pin,
      fpga_0_Ethernet_MAC_PHY_dv_pin => fpga_0_Ethernet_MAC_PHY_dv_pin,
      fpga_0_Ethernet_MAC_PHY_rx_data_pin => fpga_0_Ethernet_MAC_PHY_rx_data_pin,
      fpga_0_Ethernet_MAC_PHY_col_pin => fpga_0_Ethernet_MAC_PHY_col_pin,
      fpga_0_Ethernet_MAC_PHY_rx_er_pin => fpga_0_Ethernet_MAC_PHY_rx_er_pin,
      fpga_0_Ethernet_MAC_PHY_rst_n_pin => fpga_0_Ethernet_MAC_PHY_rst_n_pin,
      fpga_0_Ethernet_MAC_PHY_tx_en_pin => fpga_0_Ethernet_MAC_PHY_tx_en_pin,
      fpga_0_Ethernet_MAC_PHY_tx_data_pin => fpga_0_Ethernet_MAC_PHY_tx_data_pin,
      fpga_0_Ethernet_MAC_PHY_MDC_pin => fpga_0_Ethernet_MAC_PHY_MDC_pin,
      fpga_0_Ethernet_MAC_PHY_MDIO_pin => fpga_0_Ethernet_MAC_PHY_MDIO_pin,
      fpga_0_Ethernet_MAC_MDINT_pin => fpga_0_Ethernet_MAC_MDINT_pin,
      fpga_0_DDR3_SDRAM_DDR3_Clk_pin => fpga_0_DDR3_SDRAM_DDR3_Clk_pin,
      fpga_0_DDR3_SDRAM_DDR3_Clk_n_pin => fpga_0_DDR3_SDRAM_DDR3_Clk_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_CE_pin => fpga_0_DDR3_SDRAM_DDR3_CE_pin,
      fpga_0_DDR3_SDRAM_DDR3_CS_n_pin => fpga_0_DDR3_SDRAM_DDR3_CS_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_ODT_pin => fpga_0_DDR3_SDRAM_DDR3_ODT_pin,
      fpga_0_DDR3_SDRAM_DDR3_RAS_n_pin => fpga_0_DDR3_SDRAM_DDR3_RAS_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_CAS_n_pin => fpga_0_DDR3_SDRAM_DDR3_CAS_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_WE_n_pin => fpga_0_DDR3_SDRAM_DDR3_WE_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_BankAddr_pin => fpga_0_DDR3_SDRAM_DDR3_BankAddr_pin,
      fpga_0_DDR3_SDRAM_DDR3_Addr_pin => fpga_0_DDR3_SDRAM_DDR3_Addr_pin,
      fpga_0_DDR3_SDRAM_DDR3_DQ_pin => fpga_0_DDR3_SDRAM_DDR3_DQ_pin,
      fpga_0_DDR3_SDRAM_DDR3_DM_pin => fpga_0_DDR3_SDRAM_DDR3_DM_pin,
      fpga_0_DDR3_SDRAM_DDR3_Reset_n_pin => fpga_0_DDR3_SDRAM_DDR3_Reset_n_pin,
      fpga_0_DDR3_SDRAM_DDR3_DQS_pin => fpga_0_DDR3_SDRAM_DDR3_DQS_pin,
      fpga_0_DDR3_SDRAM_DDR3_DQS_n_pin => fpga_0_DDR3_SDRAM_DDR3_DQS_n_pin,
      fpga_0_clk_1_sys_clk_p_pin => fpga_0_clk_1_sys_clk_p_pin,
      fpga_0_clk_1_sys_clk_n_pin => fpga_0_clk_1_sys_clk_n_pin,
      fpga_0_rst_1_sys_rst_pin => fpga_0_rst_1_sys_rst_pin,
      fpga_0_FLASH_CE_inverter_Res_pin => fpga_0_FLASH_CE_inverter_Res_pin,
      fpga_0_PCIe_Diff_Clk_IBUF_DS_P_pin => fpga_0_PCIe_Diff_Clk_IBUF_DS_P_pin,
      fpga_0_PCIe_Diff_Clk_IBUF_DS_N_pin => fpga_0_PCIe_Diff_Clk_IBUF_DS_N_pin,
      fsl_ila_0_FSL_S_Read_pin => fsl_ila_0_FSL_S_Read_pin
    );

end architecture STRUCTURE;

