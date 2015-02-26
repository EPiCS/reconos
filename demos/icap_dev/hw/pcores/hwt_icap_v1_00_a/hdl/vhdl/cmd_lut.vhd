-------------------------------------------------------------------------------
-- Title      : Lookup Table for ICAP commands
-- Project    : 
-------------------------------------------------------------------------------
-- File       : lut.vhd
-- Author     : atraber  <atraber@pc-10080>
-- Company    : Computer Engineering and Networks Laboratory, ETH Zurich
-- Created    : 2014-04-07
-- Last update: 2014-04-07
-- Platform   : ModelSim (simulation), Synopsys (synthesis)
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: This entity implements a lookup table for ICAP commands. Right
-- now only commands for RCRC are available.
-------------------------------------------------------------------------------
-- Copyright (c) 2014 Computer Engineering and Networks Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-04-07  1.0      atraber Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity CmdLut is
  
  port (
    ClkxCI  : in  std_logic;
    AddrxDI : in  std_logic_vector(0 to 3);
    OutxDO  : out std_logic_vector(0 to 31)
    );

end CmdLut;

architecture rtl of CmdLut is
  -----------------------------------------------------------------------------
  -- Lookup-Table for CRC Reset
  -----------------------------------------------------------------------------
  type lut_t is array(0 to 2**4-1) of std_logic_vector(0 to 31);
  constant RCRC_LUT : lut_t := (
    X"FFFFFFFF",                        -- Dummy Word
    X"000000BB",                        -- Bus Width Sync Word
    X"11220044",                        -- Bus Width Detect
    X"FFFFFFFF",                        -- Dummy Word
    X"AA995566",                        -- Sync Word
    X"20000000",                        -- NOOP
    X"30008001",                        -- Type 1 write to CMD
    X"00000007",                        -- RCRC
    X"20000000",                        -- NOOP
    X"30008001",                        -- Type 1 write to CMD
    X"0000000D",                        -- DESYNC
    X"20000000",                        -- NOOP
    X"20000000",                        -- NOOP
    X"00000000",                        -- unused
    X"00000000",                        -- unused
    X"00000000"                         -- unused
    );

  -------------------------------------------------------------------------------
  -- registers
  -------------------------------------------------------------------------------
  signal OutxDP, OutxDN : std_logic_vector(0 to 31);

begin  -- rtl

  -----------------------------------------------------------------------------
  -- registers
  -----------------------------------------------------------------------------
  regFF : process (ClkxCI)
  begin  -- process regFF
    if ClkxCI'event and ClkxCI = '1' then  -- rising clock edge
      OutxDP <= OutxDN;
    end if;
  end process regFF;

  -----------------------------------------------------------------------------
  -- signal assignments
  -----------------------------------------------------------------------------
  OutxDN <= RCRC_LUT(conv_integer(unsigned(AddrxDI)));

  -----------------------------------------------------------------------------
  -- output assignments
  -----------------------------------------------------------------------------
  OutxDO <= OutxDP;

end rtl;
