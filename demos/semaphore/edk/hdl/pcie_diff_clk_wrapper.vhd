-------------------------------------------------------------------------------
-- pcie_diff_clk_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library util_ds_buf_v1_01_a;
use util_ds_buf_v1_01_a.all;

entity pcie_diff_clk_wrapper is
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

  attribute x_core_info : STRING;
  attribute x_core_info of pcie_diff_clk_wrapper : entity is "util_ds_buf_v1_01_a";

end pcie_diff_clk_wrapper;

architecture STRUCTURE of pcie_diff_clk_wrapper is

  component util_ds_buf is
    generic (
      C_BUF_TYPE : STRING;
      C_SIZE : INTEGER
    );
    port (
      IBUF_DS_P : in std_logic_vector(0 to (C_SIZE-1));
      IBUF_DS_N : in std_logic_vector(0 to (C_SIZE-1));
      IBUF_OUT : out std_logic_vector(0 to (C_SIZE-1));
      OBUF_IN : in std_logic_vector(0 to (C_SIZE-1));
      OBUF_DS_P : out std_logic_vector(0 to (C_SIZE-1));
      OBUF_DS_N : out std_logic_vector(0 to (C_SIZE-1));
      IOBUF_DS_P : inout std_logic_vector(0 to (C_SIZE-1));
      IOBUF_DS_N : inout std_logic_vector(0 to (C_SIZE-1));
      IOBUF_IO_T : in std_logic_vector(0 to (C_SIZE-1));
      IOBUF_IO_I : in std_logic_vector(0 to (C_SIZE-1));
      IOBUF_IO_O : out std_logic_vector(0 to (C_SIZE-1))
    );
  end component;

begin

  PCIe_Diff_Clk : util_ds_buf
    generic map (
      C_BUF_TYPE => "IBUFDSGTXE",
      C_SIZE => 1
    )
    port map (
      IBUF_DS_P => IBUF_DS_P,
      IBUF_DS_N => IBUF_DS_N,
      IBUF_OUT => IBUF_OUT,
      OBUF_IN => OBUF_IN,
      OBUF_DS_P => OBUF_DS_P,
      OBUF_DS_N => OBUF_DS_N,
      IOBUF_DS_P => IOBUF_DS_P,
      IOBUF_DS_N => IOBUF_DS_N,
      IOBUF_IO_T => IOBUF_IO_T,
      IOBUF_IO_I => IOBUF_IO_I,
      IOBUF_IO_O => IOBUF_IO_O
    );

end architecture STRUCTURE;

