-----------------------------------------------------------------------------
--
--
--
-----------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /
-- \   \   \/    Core:          sem
--  \   \        Entity:        sem_v3_6_sem_mon_sipo
--  /   /        Filename:      sem_v3_6_sem_mon_sipo.vhd
-- /___/   /\    Purpose:       MON Shim 8N1 SIPO.
-- \   \  /  \
--  \___\/\___\
--
-----------------------------------------------------------------------------
--
-- (c) Copyright 2010 - 2013 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-----------------------------------------------------------------------------
--
-- Entity Description:
--
-- This entity contains an 8N1 SIPO implementation.
--
-----------------------------------------------------------------------------
--
-- Port Definition:
--
-- Name                          Type   Description
-- ============================= ====== ====================================
-- icap_clk                      input  The system clock signal.
--
-- data_out[7:0]                 output Output from the SIPO.  Synchronous
--                                      to icap_clk.
--
-- serial_in                     output Asynchronous serial input.
--
-- en_16_x_baud                  input  Enable signal with periodic single
--                                      cycle pulses at 16 times baud rate.
--                                      Synchronous to icap_clk.
--
-- data_strobe                   output Indicates reception complete.
--                                      Synchronous to icap_clk.
--
-----------------------------------------------------------------------------
--
-- Generic and Constant Definition:
--
-- Name                          Type   Description
-- ============================= ====== ====================================
-- TCQ                           int    Sets the clock-to-out for behavioral
--                                      descriptions of sequential logic.
--
-----------------------------------------------------------------------------
--
-- Entity Dependencies:
--
-- sem_v3_6_sem_mon_sipo
-- |
-- \- FD (unisim)
--
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

-----------------------------------------------------------------------------
-- Entity
-----------------------------------------------------------------------------

entity sem_v3_6_sem_mon_sipo is
port (
  icap_clk                      : in    std_logic;
  data_out                      : out   std_logic_vector(7 downto 0);
  serial_in                     : in    std_logic;
  en_16_x_baud                  : in    std_logic;
  data_strobe                   : out   std_logic
  );
end entity sem_v3_6_sem_mon_sipo;

-----------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------

architecture xilinx of sem_v3_6_sem_mon_sipo is

  ---------------------------------------------------------------------------
  -- Define local constants.
  ---------------------------------------------------------------------------

  constant TCQ : time := 1 ps;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of sync_reg : label is "TRUE";

  ---------------------------------------------------------------------------
  -- Declare non-library components.
  ---------------------------------------------------------------------------

  -- None

  ---------------------------------------------------------------------------
  -- Declare signals.
  ---------------------------------------------------------------------------

  signal sync_serial            : std_logic;
  signal stop_bit               : std_logic;
  signal edge_delay             : std_logic;
  signal start_edge             : std_logic;
  signal delay_line             : std_logic_vector(150 downto 0) := (others => '0');
  signal valid_delay            : std_logic_vector(151 downto 0) := (others => '0');
  signal data_strobe_int        : std_logic := '0';
  signal valid_char             : std_logic := '0';
  signal purge                  : std_logic := '0';

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

  begin

  ---------------------------------------------------------------------------
  -- Synchronize serial input.  The first flip flop is tagged ASYNC_REG to
  -- avoid generation of X during simulation if any timing requirements are
  -- violated.
  ---------------------------------------------------------------------------

  sync_reg : FD
  port map (
    D => serial_in,
    Q => sync_serial,
    C => icap_clk
    );

  stop_reg : FD
  port map (
    D => sync_serial,
    Q => stop_bit,
    C => icap_clk
    );

  ---------------------------------------------------------------------------
  -- Create a delay line to pick out various bits of the serial signal by
  -- capturing the incoming signal at 16 times the baud rate.  This block
  -- also delays the valid_char pulse, the length of time equivalent to
  -- purge the data shift register.  This is used to generate purge signal
  -- which locks out additional strobes that might otherwise occur while
  -- the most recent captured data makes it way out of the shift register.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        delay_line <= (delay_line(149 downto 0) & stop_bit) after TCQ;
        valid_char <= (not edge_delay and start_edge and stop_bit and not purge) after TCQ;
        valid_delay <= (valid_delay(150 downto 0) & valid_char) after TCQ;
        purge <= ((purge or valid_char) and not valid_delay(151)) after TCQ;
      end if;
    end if;
  end process;

  data_out   <= (delay_line( 15) &
                 delay_line( 31) &
                 delay_line( 47) &
                 delay_line( 63) &
                 delay_line( 79) &
                 delay_line( 95) &
                 delay_line(111) &
                 delay_line(127));
  edge_delay  <= delay_line(149);
  start_edge  <= delay_line(150);

  ---------------------------------------------------------------------------
  -- Generate a single-cycle output data strobe when the character is valid.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      data_strobe_int <= (valid_char and en_16_x_baud) after TCQ;
    end if;
  end process;

  data_strobe <= data_strobe_int;

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

end architecture xilinx;

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
