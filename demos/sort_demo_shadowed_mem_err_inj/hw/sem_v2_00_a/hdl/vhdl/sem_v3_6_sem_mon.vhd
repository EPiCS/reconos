-----------------------------------------------------------------------------
--
--
--
-----------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /
-- \   \   \/    Core:          sem
--  \   \        Entity:        sem_v3_6_sem_mon
--  /   /        Filename:      sem_v3_6_sem_mon.vhd
-- /___/   /\    Purpose:       MON Shim for RS232 Port.
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
-- This entity is a MON Shim implementation for communication with external
-- RS232 devices.  Examples of external devices include a desktop or laptop
-- computer, or an embedded processor system.  This shim may be replaced with
-- a custom user-supplied design to enable communication with other devices.
--
-----------------------------------------------------------------------------
--
-- Port Definition:
--
-- Name                          Type   Description
-- ============================= ====== ====================================
-- icap_clk                      input  The system clock signal.
--
-- monitor_tx                    output Serial status output.  Synchronous
--                                      to icap_clk, but received externally
--                                      by another device as an asynchronous
--                                      signal, perceived as lower bitrate.
--                                      Uses 8N1 protocol.
--
-- monitor_rx                    input  Serial command input.  Asynchronous
--                                      signal provided by another device at
--                                      a lower bitrate, synchronized to the
--                                      icap_clk and oversampled.  Uses 8N1
--                                      protocol.
--
-- monitor_txdata[7:0]           input  Output data from controller,
--                                      qualified by monitor_txwrite.
--                                      Synchronous to icap_clk.
--
-- monitor_txwrite               input  Write strobe, used by peripheral
--                                      to capture data.  Synchronous to
--                                      icap_clk.
--
-- monitor_txfull                output Flow control signal indicating the
--                                      peripheral is not ready to receive
--                                      additional data writes.  Synchronous
--                                      to icap_clk.
--
-- monitor_rxdata[7:0]           output Input data to controller qualified
--                                      by monitor_rxread. Synchronous to
--                                      icap_clk.
--
-- monitor_rxread                input  Read strobe, used by peripheral
--                                      to change state.  Synchronous to
--                                      icap_clk.
--
-- monitor_rxempty               output Flow control signal indicating the
--                                      peripheral is not ready to service
--                                      additional data reads.  Synchronous
--                                      to icap_clk.
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
-- V_ENABLETIME                  int    This sets communication baud rate;
--                                      see user guide for additional detail.
--
-----------------------------------------------------------------------------
--
-- Entity Dependencies:
--
-- sem_v3_6_sem_mon
-- |
-- +- sem_v3_6_sem_mon_fifo
-- |
-- +- sem_v3_6_sem_mon_piso
-- |
-- \- sem_v3_6_sem_mon_sipo
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

entity sem_v3_6_sem_mon is
port (
  icap_clk                      : in    std_logic;
  monitor_tx                    : out   std_logic;
  monitor_rx                    : in    std_logic;
  monitor_txdata                : in    std_logic_vector(7 downto 0);
  monitor_txwrite               : in    std_logic;
  monitor_txfull                : out   std_logic;
  monitor_rxdata                : out   std_logic_vector(7 downto 0);
  monitor_rxread                : in    std_logic;
  monitor_rxempty               : out   std_logic
  );
end entity sem_v3_6_sem_mon;

-----------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------

architecture xilinx of sem_v3_6_sem_mon is

  ---------------------------------------------------------------------------
  -- Define local constants.
  ---------------------------------------------------------------------------

  constant TCQ : time := 1 ps;
  constant V_ENABLETIME : integer := 650;

  ---------------------------------------------------------------------------
  -- Declare non-library components.
  ---------------------------------------------------------------------------

  component sem_v3_6_sem_mon_fifo
  port (
    icap_clk                    : in    std_logic;
    data_in                     : in    std_logic_vector(7 downto 0);
    data_out                    : out   std_logic_vector(7 downto 0);
    write                       : in    std_logic;
    read                        : in    std_logic;
    full                        : out   std_logic;
    data_present                : out   std_logic
    );
  end component;

  component sem_v3_6_sem_mon_sipo
  port (
    icap_clk                    : in    std_logic;
    data_out                    : out   std_logic_vector(7 downto 0);
    serial_in                   : in    std_logic;
    en_16_x_baud                : in    std_logic;
    data_strobe                 : out   std_logic
    );
  end component;

  component sem_v3_6_sem_mon_piso
  port (
    icap_clk                    : in    std_logic;
    data_in                     : in    std_logic_vector(7 downto 0);
    send_character              : in    std_logic;
    en_16_x_baud                : in    std_logic;
    serial_out                  : out   std_logic;
    tx_complete                 : out   std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- Declare signals.
  ---------------------------------------------------------------------------

  signal en_16_x_counter        : std_logic_vector(11 downto 0) := X"000";
  signal en_16_x_baud           : std_logic;
  signal fifo_read              : std_logic;
  signal fifo_data_present      : std_logic;
  signal fifo_data_out          : std_logic_vector(7 downto 0);
  signal txfull_p               : std_logic;
  signal fifo_write             : std_logic;
  signal fifo_data_in           : std_logic_vector(7 downto 0);
  signal fifo_unused            : std_logic;
  signal rxempty_n              : std_logic;

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

  begin

  ---------------------------------------------------------------------------
  -- Create the 16x enable signal for baud rate generation.  This has an
  -- initial value, but no functional reset; it runs continuously.
  ---------------------------------------------------------------------------

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      if (en_16_x_baud = '1') then
        en_16_x_counter <= X"000" after TCQ;
      else
        en_16_x_counter <= en_16_x_counter + X"001" after TCQ;
      end if;
    end if;
  end process;

  en_16_x_baud <= '1' when (en_16_x_counter = conv_std_logic_vector(V_ENABLETIME,12)) else '0';

  ---------------------------------------------------------------------------
  -- Implement the transmit channel with a FIFO and PISO.
  ---------------------------------------------------------------------------

  example_mon_fifo_tx : sem_v3_6_sem_mon_fifo
  port map (
    data_in => monitor_txdata,
    data_out => fifo_data_out,
    write => monitor_txwrite,
    read => fifo_read,
    full => txfull_p,
    data_present => fifo_data_present,
    icap_clk => icap_clk
    );

  example_mon_piso : sem_v3_6_sem_mon_piso
  port map (
    data_in => fifo_data_out,
    send_character => fifo_data_present,
    en_16_x_baud => en_16_x_baud,
    serial_out => monitor_tx,
    tx_complete => fifo_read,
    icap_clk => icap_clk
    );

  monitor_txfull <= txfull_p;

  ---------------------------------------------------------------------------
  -- Implement the receive channel with a SIPO and FIFO.
  ---------------------------------------------------------------------------

  example_mon_sipo : sem_v3_6_sem_mon_sipo
  port map (
    serial_in => monitor_rx,
    data_out => fifo_data_in,
    data_strobe => fifo_write,
    en_16_x_baud => en_16_x_baud,
    icap_clk => icap_clk
    );

  example_mon_fifo_rx : sem_v3_6_sem_mon_fifo
  port map (
    data_in => fifo_data_in,
    data_out => monitor_rxdata,
    write => fifo_write,
    read => monitor_rxread,
    full => fifo_unused,
    data_present => rxempty_n,
    icap_clk => icap_clk
    );

  monitor_rxempty <= not (rxempty_n);

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

end architecture xilinx;

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
