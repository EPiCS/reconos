library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity reconos_hwt_idle is
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
		HWT_Rst   : in  std_logic
	);

	attribute SIGIS   : string;

	attribute SIGIS of HWT_Clk   : signal is "Clk";
	attribute SIGIS of HWT_Rst   : signal is "Rst";

end entity reconos_hwt_idle;

architecture implementation of reconos_hwt_idle is
begin

	OSIF_FIFO_Sw2Hw_RE      <= '0';
	OSIF_FIFO_Hw2Sw_WE      <= '0';
	OSIF_FIFO_Hw2Sw_Data    <= (others => '0');

	MEMIF_FIFO_Mem2Hwt_RE   <= '0';
	MEMIF_FIFO_Hwt2Mem_WE   <= '0';
	MEMIF_FIFO_Hwt2Mem_Data <= (others => '0');

end architecture;
