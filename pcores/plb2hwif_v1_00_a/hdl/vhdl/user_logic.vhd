------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Thu Mar 20 11:35:58 2014 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
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

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

--library work;
--use work.hwif_pck.all;
library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;


------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_AWIDTH                 -- Slave interface address bus width
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_MEM                    -- Number of memory spaces
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Addr                  -- Bus to IP address bus
--   Bus2IP_CS                    -- Bus to IP chip select for user logic memory selection
--   Bus2IP_RNW                   -- Bus to IP read/not write
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    C_IPIF_ARD_ADDR_RANGE_ARRAY    : SLV64_ARRAY_TYPE     := ((others => '0'),(others => '1'));
    C_HWIF_IF_COUNT                   : integer              := 16;
    -- Default: 16 Bit ^= 64Kbyte Address Space per interface:
    C_HWIF_ADDRESS_SPACE_BITS         : integer              := 16; 
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_AWIDTH                   : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_MEM                      : integer              := 1
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
    (
      -- ADD USER PORTS BELOW THIS LINE ------------------
      --USER ports added here
      IP2HWT_Addr_A  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_A  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_A  : out std_logic;
      IP2HWT_WrCE_A  : out std_logic;
      HWT2IP_Data_A  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_A : in  std_logic;
      HWT2IP_WrAck_A : in  std_logic;

      IP2HWT_Addr_B  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_B  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_B  : out std_logic;
      IP2HWT_WrCE_B  : out std_logic;
      HWT2IP_Data_B  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_B : in  std_logic;
      HWT2IP_WrAck_B : in  std_logic;

      IP2HWT_Addr_C  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_C  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_C  : out std_logic;
      IP2HWT_WrCE_C  : out std_logic;
      HWT2IP_Data_C  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_C : in  std_logic;
      HWT2IP_WrAck_C : in  std_logic;

      IP2HWT_Addr_D  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_D  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_D  : out std_logic;
      IP2HWT_WrCE_D  : out std_logic;
      HWT2IP_Data_D  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_D : in  std_logic;
      HWT2IP_WrAck_D : in  std_logic;

      IP2HWT_Addr_E  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_E  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_E  : out std_logic;
      IP2HWT_WrCE_E  : out std_logic;
      HWT2IP_Data_E  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_E : in  std_logic;
      HWT2IP_WrAck_E : in  std_logic;

      IP2HWT_Addr_F  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_F  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_F  : out std_logic;
      IP2HWT_WrCE_F  : out std_logic;
      HWT2IP_Data_F  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_F : in  std_logic;
      HWT2IP_WrAck_F : in  std_logic;

      IP2HWT_Addr_G  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_G  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_G  : out std_logic;
      IP2HWT_WrCE_G  : out std_logic;
      HWT2IP_Data_G  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_G : in  std_logic;
      HWT2IP_WrAck_G : in  std_logic;

      IP2HWT_Addr_H  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_H  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_H  : out std_logic;
      IP2HWT_WrCE_H  : out std_logic;
      HWT2IP_Data_H  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_H : in  std_logic;
      HWT2IP_WrAck_H : in  std_logic;

      IP2HWT_Addr_I  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_I  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_I  : out std_logic;
      IP2HWT_WrCE_I  : out std_logic;
      HWT2IP_Data_I  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_I : in  std_logic;
      HWT2IP_WrAck_I : in  std_logic;

      IP2HWT_Addr_J  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_J  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_J  : out std_logic;
      IP2HWT_WrCE_J  : out std_logic;
      HWT2IP_Data_J  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_J : in  std_logic;
      HWT2IP_WrAck_J : in  std_logic;

      IP2HWT_Addr_K  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_K  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_K  : out std_logic;
      IP2HWT_WrCE_K  : out std_logic;
      HWT2IP_Data_K  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_K : in  std_logic;
      HWT2IP_WrAck_K : in  std_logic;

      IP2HWT_Addr_L  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_L  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_L  : out std_logic;
      IP2HWT_WrCE_L  : out std_logic;
      HWT2IP_Data_L  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_L : in  std_logic;
      HWT2IP_WrAck_L : in  std_logic;

      IP2HWT_Addr_M  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_M  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_M  : out std_logic;
      IP2HWT_WrCE_M  : out std_logic;
      HWT2IP_Data_M  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_M : in  std_logic;
      HWT2IP_WrAck_M : in  std_logic;

      IP2HWT_Addr_N  : out std_logic_vector(0 to C_SLV_AWIDTH-1);
      IP2HWT_Data_N  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      IP2HWT_RdCE_N  : out std_logic;
      IP2HWT_WrCE_N  : out std_logic;
      HWT2IP_Data_N  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWT2IP_RdAck_N : in  std_logic;
      HWT2IP_WrAck_N : in  std_logic;

      
      -- ADD USER PORTS ABOVE THIS LINE ------------------
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Addr                    : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
    Bus2IP_CS                      : in  std_logic_vector(0 to C_NUM_MEM-1);
    Bus2IP_RNW                     : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  signal mux_in: std_logic_vector(0 to (C_HWIF_IF_COUNT)-1);
  
  signal BUS2IP : master2slave_t;
  signal IP2HWT : master2slave_array_t(0 to C_HWIF_IF_COUNT-1);

  signal HWT2IP : slave2master_array_t(0 to C_HWIF_IF_COUNT-1);
  signal IP2BUS : slave2master_t;
  
begin

  BUS2IP.address  <= BUS2IP_Addr;
  BUS2IP.data_in  <= BUS2IP_Data;
  BUS2IP.read_ce  <= '1' when BUS2IP_CS /= (BUS2IP_CS'range => '0') and Bus2IP_RNW = '1'  else '0';
  BUS2IP.write_ce <= '1' when BUS2IP_CS /= (BUS2IP_CS'range => '0') and Bus2IP_RNW = '0' else '0';
  IP2BUS_Data     <= IP2BUS.data_out;
  IP2BUS_RdAck    <= IP2BUS.read_ack;
  IP2BUS_WrAck    <= IP2BUS.write_ack;

  A : if C_HWIF_IF_COUNT > 0 generate
    IP2HWT_Addr_A       <= IP2HWT(0).address;
    IP2HWT_Data_A       <= IP2HWT(0).data_in;
    IP2HWT_RdCE_A       <= IP2HWT(0).read_ce;
    IP2HWT_WrCE_A       <= IP2HWT(0).write_ce;
    HWT2IP(0).data_out  <= HWT2IP_Data_A;
    HWT2IP(0).read_ack  <= HWT2IP_RdAck_A;
    HWT2IP(0).write_ack <= HWT2IP_WrAck_A;
  end generate;

  B : if C_HWIF_IF_COUNT > 1 generate
    IP2HWT_Addr_B       <= IP2HWT(1).address;
    IP2HWT_Data_B       <= IP2HWT(1).data_in;
    IP2HWT_RdCE_B       <= IP2HWT(1).read_ce;
    IP2HWT_WrCE_B       <= IP2HWT(1).write_ce;
    HWT2IP(1).data_out  <= HWT2IP_Data_B;
    HWT2IP(1).read_ack  <= HWT2IP_RdAck_B;
    HWT2IP(1).write_ack <= HWT2IP_WrAck_B;
  end generate;

  C : if C_HWIF_IF_COUNT > 2 generate
    IP2HWT_Addr_C       <= IP2HWT(2).address;
    IP2HWT_Data_C       <= IP2HWT(2).data_in;
    IP2HWT_RdCE_C       <= IP2HWT(2).read_ce;
    IP2HWT_WrCE_C       <= IP2HWT(2).write_ce;
    HWT2IP(2).data_out  <= HWT2IP_Data_C;
    HWT2IP(2).read_ack  <= HWT2IP_RdAck_C;
    HWT2IP(2).write_ack <= HWT2IP_WrAck_C;
  end generate;

  D : if C_HWIF_IF_COUNT > 3 generate
    IP2HWT_Addr_D       <= IP2HWT(3).address;
    IP2HWT_Data_D       <= IP2HWT(3).data_in;
    IP2HWT_RdCE_D       <= IP2HWT(3).read_ce;
    IP2HWT_WrCE_D       <= IP2HWT(3).write_ce;
    HWT2IP(3).data_out  <= HWT2IP_Data_D;
    HWT2IP(3).read_ack  <= HWT2IP_RdAck_D;
    HWT2IP(3).write_ack <= HWT2IP_WrAck_D;
  end generate;

  E : if C_HWIF_IF_COUNT > 4 generate
    IP2HWT_Addr_E       <= IP2HWT(4).address;
    IP2HWT_Data_E       <= IP2HWT(4).data_in;
    IP2HWT_RdCE_E       <= IP2HWT(4).read_ce;
    IP2HWT_WrCE_E       <= IP2HWT(4).write_ce;
    HWT2IP(4).data_out  <= HWT2IP_Data_E;
    HWT2IP(4).read_ack  <= HWT2IP_RdAck_E;
    HWT2IP(4).write_ack <= HWT2IP_WrAck_E;
  end generate;

  F : if C_HWIF_IF_COUNT > 5 generate
    IP2HWT_Addr_F       <= IP2HWT(5).address;
    IP2HWT_Data_F       <= IP2HWT(5).data_in;
    IP2HWT_RdCE_F       <= IP2HWT(5).read_ce;
    IP2HWT_WrCE_F       <= IP2HWT(5).write_ce;
    HWT2IP(5).data_out  <= HWT2IP_Data_F;
    HWT2IP(5).read_ack  <= HWT2IP_RdAck_F;
    HWT2IP(5).write_ack <= HWT2IP_WrAck_F;
  end generate;

  G : if C_HWIF_IF_COUNT > 6 generate
    IP2HWT_Addr_G       <= IP2HWT(6).address;
    IP2HWT_Data_G       <= IP2HWT(6).data_in;
    IP2HWT_RdCE_G       <= IP2HWT(6).read_ce;
    IP2HWT_WrCE_G       <= IP2HWT(6).write_ce;
    HWT2IP(6).data_out  <= HWT2IP_Data_G;
    HWT2IP(6).read_ack  <= HWT2IP_RdAck_G;
    HWT2IP(6).write_ack <= HWT2IP_WrAck_G;
  end generate;

  H : if C_HWIF_IF_COUNT > 7 generate
    IP2HWT_Addr_H       <= IP2HWT(7).address;
    IP2HWT_Data_H       <= IP2HWT(7).data_in;
    IP2HWT_RdCE_H       <= IP2HWT(7).read_ce;
    IP2HWT_WrCE_H       <= IP2HWT(7).write_ce;
    HWT2IP(7).data_out  <= HWT2IP_Data_H;
    HWT2IP(7).read_ack  <= HWT2IP_RdAck_H;
    HWT2IP(7).write_ack <= HWT2IP_WrAck_H;
  end generate;

  I : if C_HWIF_IF_COUNT > 8 generate
    IP2HWT_Addr_I       <= IP2HWT(8).address;
    IP2HWT_Data_I       <= IP2HWT(8).data_in;
    IP2HWT_RdCE_I       <= IP2HWT(8).read_ce;
    IP2HWT_WrCE_I       <= IP2HWT(8).write_ce;
    HWT2IP(8).data_out  <= HWT2IP_Data_I;
    HWT2IP(8).read_ack  <= HWT2IP_RdAck_I;
    HWT2IP(8).write_ack <= HWT2IP_WrAck_I;
  end generate;

  J : if C_HWIF_IF_COUNT > 9 generate
    IP2HWT_Addr_J       <= IP2HWT(9).address;
    IP2HWT_Data_J       <= IP2HWT(9).data_in;
    IP2HWT_RdCE_J       <= IP2HWT(9).read_ce;
    IP2HWT_WrCE_J       <= IP2HWT(9).write_ce;
    HWT2IP(9).data_out  <= HWT2IP_Data_J;
    HWT2IP(9).read_ack  <= HWT2IP_RdAck_J;
    HWT2IP(9).write_ack <= HWT2IP_WrAck_J;
  end generate;

  K : if C_HWIF_IF_COUNT > 10 generate
    IP2HWT_Addr_K       <= IP2HWT(10).address;
    IP2HWT_Data_K       <= IP2HWT(10).data_in;
    IP2HWT_RdCE_K       <= IP2HWT(10).read_ce;
    IP2HWT_WrCE_K       <= IP2HWT(10).write_ce;
    HWT2IP(10).data_out  <= HWT2IP_Data_K;
    HWT2IP(10).read_ack  <= HWT2IP_RdAck_K;
    HWT2IP(10).write_ack <= HWT2IP_WrAck_K;
  end generate;

  L : if C_HWIF_IF_COUNT > 11 generate
    IP2HWT_Addr_L       <= IP2HWT(11).address;
    IP2HWT_Data_L       <= IP2HWT(11).data_in;
    IP2HWT_RdCE_L       <= IP2HWT(11).read_ce;
    IP2HWT_WrCE_L       <= IP2HWT(11).write_ce;
    HWT2IP(11).data_out  <= HWT2IP_Data_L;
    HWT2IP(11).read_ack  <= HWT2IP_RdAck_L;
    HWT2IP(11).write_ack <= HWT2IP_WrAck_L;
  end generate;

  M : if C_HWIF_IF_COUNT > 12 generate
    IP2HWT_Addr_M       <= IP2HWT(12).address;
    IP2HWT_Data_M       <= IP2HWT(12).data_in;
    IP2HWT_RdCE_M       <= IP2HWT(12).read_ce;
    IP2HWT_WrCE_M       <= IP2HWT(12).write_ce;
    HWT2IP(12).data_out  <= HWT2IP_Data_M;
    HWT2IP(12).read_ack  <= HWT2IP_RdAck_M;
    HWT2IP(12).write_ack <= HWT2IP_WrAck_M;
  end generate;

  N : if C_HWIF_IF_COUNT > 13 generate
    IP2HWT_Addr_N       <= IP2HWT(13).address;
    IP2HWT_Data_N       <= IP2HWT(13).data_in;
    IP2HWT_RdCE_N       <= IP2HWT(13).read_ce;
    IP2HWT_WrCE_N       <= IP2HWT(13).write_ce;
    HWT2IP(13).data_out  <= HWT2IP_Data_N;
    HWT2IP(13).read_ack  <= HWT2IP_RdAck_N;
    HWT2IP(13).write_ack <= HWT2IP_WrAck_N;
  end generate;

-- analyze address according to address map
-- mux_in is one-hot coded
mux_control: process (BUS2IP_Addr)
  variable idx : natural := 0;

  function log2_ceil (
    constant x : natural)
    return natural is
    variable e : integer := 1;
  begin  -- function log2_ceil
    while 2**e < x loop
      e := e+1;
    end loop;
    return e;
  end function log2_ceil;
  
begin
  idx := to_integer(unsigned(BUS2IP_Addr(C_SLV_AWIDTH-1-C_HWIF_ADDRESS_SPACE_BITS-log2_ceil(C_HWIF_IF_COUNT) to
                     C_SLV_AWIDTH-1-C_HWIF_ADDRESS_SPACE_BITS)));
  mux_in <= (others => '0');
  mux_in(idx) <= '1';
end process;

  -- route request to specified port
  mux : process(Bus2IP, HWT2IP, mux_in)
  begin
    IP2BUS <= S2M_ALL_ZEROS;
    for i in 0 to C_HWIF_IF_COUNT-1 loop
      IP2HWT(i) <= M2S_ALL_ZEROS;
      if mux_in(i) = '1' then
        IP2HWT(i) <= BUS2IP;
        IP2HWT(i).address(0 to C_SLV_AWIDTH-1-C_HWIF_ADDRESS_SPACE_BITS) <= (others => '0');
        IP2HWT(i).address(C_SLV_AWIDTH - C_HWIF_ADDRESS_SPACE_BITS to C_SLV_AWIDTH-1) <= BUS2IP.address(C_SLV_AWIDTH - C_HWIF_ADDRESS_SPACE_BITS to C_SLV_AWIDTH-1);
        IP2BUS  <= HWT2IP(i);
      end if;
    end loop;
  end process;
  
end IMP;
