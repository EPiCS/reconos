-------------------------------------------------------------------------------
-- Title      : ICAP Wrapper
-- Project    : 
-------------------------------------------------------------------------------
-- File       : icap_wrapper.vhd
-- Author     : atraber  <atraber@student.ethz.ch>
-- Company    : Computer Engineering and Networks Laboratory, ETH Zurich
-- Created    : 2014-04-06
-- Last update: 2014-04-06
-- Platform   : Xilinx ISIM (simulation), Xilinx (synthesis)
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: This wrapper just passes through the signals and mainly exists
-- to make simulation easier
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

begin  -- rtl

  ICAP_VERTEX6_I : ICAP_VIRTEX6
    generic map (
      ICAP_WIDTH => "X32"
      )
    port map (
      clk   => clk,
      csb   => csb,
      rdwrb => rdwrb,
      i     => i,
      busy  => busy,
      o     => o);

end rtl;
