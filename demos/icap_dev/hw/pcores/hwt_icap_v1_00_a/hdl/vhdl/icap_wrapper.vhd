-------------------------------------------------------------------------------
-- Title      : ICAP Wrapper
-- Project    : 
-------------------------------------------------------------------------------
-- File       : icap_wrapper.vhd
-- Author     : atraber  <atraber@student.ethz.ch>
-- Company    : Computer Engineering and Networks Laboratory, ETH Zurich
-- Created    : 2014-04-06
-- Last update: 2014-04-11
-- Platform   : Xilinx ISIM (simulation), Xilinx (synthesis)
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: This wrapper just passes through the signals and mainly exists
-- to make simulation easier.
-- It also takes care of the bit swapping for ICAP signals
-------------------------------------------------------------------------------
-- Copyright (c) 2014 Computer Engineering and Networks Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-04-06  1.0      atraber Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity ICAPWrapper is
  
  generic (
    ICAP_WIDTH : natural := 32
    );

  port (
    clk   : in  std_logic;
    csb   : in  std_logic;
    rdwrb : in  std_logic;
    i     : in  std_logic_vector(0 to ICAP_WIDTH-1);
    busy  : out std_logic;
    o     : out std_logic_vector(0 to ICAP_WIDTH-1)
    );

end ICAPWrapper;

architecture rtl of ICAPWrapper is
  signal ICAPIxD : std_logic_vector(0 to ICAP_WIDTH-1);
  signal ICAPOxD : std_logic_vector(0 to ICAP_WIDTH-1);
begin  -- rtl

  ICAP_VERTEX6_I : ICAP_VIRTEX6
    generic map (
      ICAP_WIDTH => "X32"
      )
    port map (
      clk   => clk,
      csb   => csb,
      rdwrb => rdwrb,
      i     => ICAPIxD,
      busy  => busy,
      o     => ICAPOxD);

  -- bit swapping of RAM output so that it matches the input format of the ICAP
  -- interface, see pg 43 of UG360 (v3.7)
  swapGen : for k in 0 to 3 generate
    bitSwapGen : for j in 0 to 7 generate
      ICAPIxD(k * 8 + j) <= i((k + 1) * 8 - 1 - j);
    end generate bitSwapGen;
  end generate swapGen;

  -- bit swapping of RAM input
  swapRamInGen : for k in 0 to 3 generate
    bitSwapRamInGen : for j in 0 to 7 generate
      o(k * 8 + j) <= ICAPOxD((k + 1) * 8 - 1 - j);
    end generate bitSwapRamInGen;
  end generate swapRamInGen;

end rtl;
