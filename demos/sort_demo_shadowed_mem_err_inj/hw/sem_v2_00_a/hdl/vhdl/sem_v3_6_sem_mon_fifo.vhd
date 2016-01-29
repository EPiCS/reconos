-----------------------------------------------------------------------------
--
--
--
-----------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /
-- \   \   \/    Core:          sem
--  \   \        Entity:        sem_v3_6_sem_mon_fifo
--  /   /        Filename:      sem_v3_6_sem_mon_fifo.vhd
-- /___/   /\    Purpose:       MON Shim 32x8 FIFO.
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
-- This entity contains a 32x8 synchronous FIFO implementation.
--
-----------------------------------------------------------------------------
--
-- Port Definition:
--
-- Name                          Type   Description
-- ============================= ====== ====================================
-- icap_clk                      input  The system clock signal.
--
-- data_in[7:0]                  input  Input to the FIFO. Synchronous
--                                      to icap_clk.
--
-- data_out[7:0]                 output Output from the FIFO.  Synchronous
--                                      to icap_clk.
--
-- write                         input  Write strobe, used to enable data
--                                      capture.  Synchronous to icap_clk.
--
-- read                          input  Read strobe, used to advance data
--                                      output to next value.  Synchronous
--                                      to icap_clk.
--
-- full                          output Indicates when the FIFO is full.
--                                      Synchronous to icap_clk.
--
-- data_present                  output Indicates when the FIFO has data
--                                      (not empty). Synchronous to icap_clk.
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
-- sem_v3_6_sem_mon_fifo
-- |
-- \- SRLC32E (unisim)
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

entity sem_v3_6_sem_mon_fifo is
port (
  icap_clk                      : in    std_logic;
  data_in                       : in    std_logic_vector(7 downto 0);
  data_out                      : out   std_logic_vector(7 downto 0);
  write                         : in    std_logic;
  read                          : in    std_logic;
  full                          : out   std_logic;
  data_present                  : out   std_logic
  );
end entity sem_v3_6_sem_mon_fifo;

-----------------------------------------------------------------------------
-- Architecture
-----------------------------------------------------------------------------

architecture xilinx of sem_v3_6_sem_mon_fifo is

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

  signal augend                 : std_logic_vector(5 downto 0) := "011111";
  signal addend                 : std_logic_vector(5 downto 0);
  signal addsel                 : std_logic_vector(1 downto 0);

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

  begin

  ---------------------------------------------------------------------------
  -- Data storage.
  ---------------------------------------------------------------------------

  data_srl_0 : SRLC32E
  port map (
    D => data_in(0),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(0),
    Q31 => open
    );

  data_srl_1 : SRLC32E
  port map (
    D => data_in(1),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(1),
    Q31 => open
    );

  data_srl_2 : SRLC32E
  port map (
    D => data_in(2),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(2),
    Q31 => open
    );

  data_srl_3 : SRLC32E
  port map (
    D => data_in(3),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(3),
    Q31 => open
    );

  data_srl_4 : SRLC32E
  port map (
    D => data_in(4),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(4),
    Q31 => open
    );

  data_srl_5 : SRLC32E
  port map (
    D => data_in(5),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(5),
    Q31 => open
    );

  data_srl_6 : SRLC32E
  port map (
    D => data_in(6),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(6),
    Q31 => open
    );

  data_srl_7 : SRLC32E
  port map (
    D => data_in(7),
    CE => write,
    CLK => icap_clk,
    A => augend(4 downto 0),
    Q => data_out(7),
    Q31 => open
    );

  ---------------------------------------------------------------------------
  -- Buffer management; this does not check for illegal reads and writes,
  -- it is the responsibility of the data producer to stop writing when
  -- "full" is logic one and the responsibility of the data consumer to
  -- stop reading when "data_present" is logic zero.
  ---------------------------------------------------------------------------

  addsel <= read & write;

  process (addsel)
  begin
    case addsel is
      when "01" => addend <= "000001";
      when "10" => addend <= "111111";
      when others => addend <= "000000";
    end case;
  end process;

  process (icap_clk)
  begin
    if rising_edge (icap_clk) then
      augend <= (augend + addend) after TCQ;
    end if;
  end process;

  data_present <= augend(5);
  full <= '1' when (augend = "111111") else '0';

  ---------------------------------------------------------------------------
  --
  ---------------------------------------------------------------------------

end architecture xilinx;

-----------------------------------------------------------------------------
--
-----------------------------------------------------------------------------
