-----------------------------------------------------------------------------
--
--
--
-----------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /
-- \   \   \/    Core:          sem
--  \   \        Entity:        sem_v3_6_sem_mon_piso
--  /   /        Filename:      sem_v3_6_sem_mon_piso.vhd
-- /___/   /\    Purpose:       MON Shim 8N1 PISO.
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
-- This entity contains an 8N1 PISO implementation.
--
-----------------------------------------------------------------------------
--
-- Port Definition:
--
-- Name                          Type   Description
-- ============================= ====== ====================================
-- icap_clk                      input  The system clock signal.
--
-- data_in[7:0]                  input  Input to the PISO. Synchronous
--                                      to icap_clk.
--
-- send_character                input  Qualifies availability of valid
--                                      data on data_in port.  Synchronous
--                                      to icap_clk.
--
-- en_16_x_baud                  input  Enable signal with periodic single
--                                      cycle pulses at 16 times baud rate.
--                                      Synchronous to icap_clk.
--
-- serial_out                    output Serialized output.  Synchronous
--                                      to icap_clk.
--
-- tx_complete                   output Indicates transmission complete.
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
-- sem_v3_6_sem_mon_piso
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

entity sem_v3_6_sem_mon_piso is
port (
  icap_clk                      : in    std_logic;
  data_in                       : in    std_logic_vector(7 downto 0);
  send_character                : in    std_logic;
  en_16_x_baud                  : in    std_logic;
  serial_out                    : out   std_logic;
  tx_complete                   : out   std_logic
  );
end entity sem_v3_6_sem_mon_piso;

-----------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------

architecture xilinx of sem_v3_6_sem_mon_piso is

  ---------------------------------------------------------------------------
  -- Define local constants.
  ---------------------------------------------------------------------------

  constant TCQ : time := 1 ps;

  ---------------------------------------------------------------------------
  -- Declare non-library components.
  ---------------------------------------------------------------------------

  -- None

  ---------------------------------------------------------------------------
  -- Declare signals.
  ---------------------------------------------------------------------------

  signal hot_delay              : std_logic_vector(15 downto 0) := X"0000";
  signal bit_select             : std_logic_vector(2 downto 0) := "000";
  signal piso_out               : std_logic := '1';
  signal all_done               : std_logic := '0';
  signal tx_start               : std_logic := '0';
  signal tx_stop                : std_logic := '0';
  signal tx_run                 : std_logic := '0';
  signal tx_bit                 : std_logic;

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

  begin

  ---------------------------------------------------------------------------
  -- Convert parallel data to serial data with provision for stop and start.
  -- Follow this by a flip-flop instance specifically for packing to pin.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (tx_start = '1') then
        piso_out <= '0' after TCQ;
      elsif (tx_stop = '1') then
        piso_out <= '1' after TCQ;
      elsif (tx_run = '1') then
        piso_out <= data_in(conv_integer(bit_select)) after TCQ;
      else
        piso_out <= '1' after TCQ;
      end if;
    end if;
  end process;

  pipeline_serial : FD
  generic map (INIT => '1')
  port map (
    D => piso_out,
    Q => serial_out,
    C => icap_clk
    );

  ---------------------------------------------------------------------------
  -- Transmit bit counter.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (tx_start = '1') then
        bit_select <= "000" after TCQ;
      elsif ((en_16_x_baud = '1') and (tx_run = '1') and (tx_bit = '1')) then
        bit_select <= bit_select + "001" after TCQ;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Start bit enable.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        tx_start <= (
          (not tx_start and     (send_character and not tx_start and not tx_run) and not tx_stop and not tx_bit) or
          (not tx_start and     (send_character and not tx_start and not tx_run) and     tx_stop and     tx_bit) or
          (    tx_start and not (send_character and not tx_start and not tx_run) and not tx_stop and not tx_bit) )
          after TCQ;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Stop bit enable.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        tx_stop <= (
          (not tx_stop and     (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0))) and     tx_run and     tx_bit) or
          (    tx_stop and not (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0))) and not tx_run and not tx_bit) )
          after TCQ;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Run bit enable.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        tx_run <= (
          (not tx_run and     tx_start and     tx_bit and not (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0)))) or
          (    tx_run and not tx_start and not tx_bit and not (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0)))) or
          (    tx_run and not tx_start and     tx_bit and not (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0)))) or
          (    tx_run and     tx_start and not tx_bit and not (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0)))) )
          after TCQ;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Bit rate enable.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        hot_delay(0) <= (
          (not tx_stop and not (send_character and not tx_start and not tx_run) and     tx_bit) or
          (    tx_stop and     (send_character and not tx_start and not tx_run) and     tx_bit) or
          (not tx_stop and     (send_character and not tx_start and not tx_run) and not tx_bit) )
          after TCQ;
        hot_delay(15 downto 1) <= hot_delay(14 downto 0) after TCQ;
      end if;
    end if;
  end process;

  tx_bit <= hot_delay(15);

  ---------------------------------------------------------------------------
  -- Transmit complete strobe.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      all_done <= (en_16_x_baud and (tx_bit and (bit_select(2) and bit_select(1) and bit_select(0)))) after TCQ;
    end if;
  end process;

  tx_complete <= all_done;

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

end architecture xilinx;

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
