--
-- sort8k.vhd
-- eCos hardware thread using the bubble_sort module and mailboxes to
-- sort 8k-sized blocks of data in main memory. The incoming messages
-- on C_MB_START contain the addresses of the blocks, and an arbitrary
-- message sent to C_MB_DONE signals completion of the sorting process. 
--
-- Author:     Enno Luebbers   <luebbers@reconos.de>
-- Date:       28.09.2007
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group.
--
-- (C) Copyright University of Paderborn 2007.
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sort8k is

  generic (
    C_BURST_AWIDTH : integer := 11;
    C_BURST_DWIDTH : integer := 32
    );

  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    i_osif : in  osif_os2task_t;
    o_osif : out osif_task2os_t;

    -- burst ram interface
    o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
    o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
    i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
    o_RAMWE   : out std_logic;
    o_RAMClk  : out std_logic
    );
end sort8k;

architecture Behavioral of sort8k is

  component bubble_sorter is

                            generic (
                              G_LEN    : integer := 2048;  -- number of words to sort
                              G_AWIDTH : integer := 11;  -- in bits
                              G_DWIDTH : integer := 32  -- in bits
                              );

                          port (
                            clk   : in std_logic;
                            reset : in std_logic;

                            -- burst ram interface
                            o_RAMAddr : out std_logic_vector(0 to G_AWIDTH-1);
                            o_RAMData : out std_logic_vector(0 to G_DWIDTH-1);
                            i_RAMData : in  std_logic_vector(0 to G_DWIDTH-1);
                            o_RAMWE   : out std_logic;
                            start     : in  std_logic;
                            done      : out std_logic
                            );
  end component;

  -- ReconOS thread-local mailbox handles
  constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";

  -- OS synchronization state machine states
  type t_state is (STATE_GET, STATE_READ, STATE_SORT, STATE_WAIT, STATE_WRITE, STATE_PUT);
  signal state : t_state := STATE_GET;

  -- address of data to sort in main memory
  signal address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -- handshaking signals
  signal sort_start : std_logic := '0';
  signal sort_done  : std_logic;

  -- RAM address
  signal RAMAddr : std_logic_vector(0 to C_BURST_AWIDTH-1);
begin

  -- instantiate bubble_sorter module
  sorter_i : bubble_sorter
    generic map (
      G_LEN     => 2048,
      G_AWIDTH  => C_BURST_AWIDTH,
      G_DWIDTH  => C_BURST_DWIDTH
      )
    port map (
      clk       => clk,
      reset     => reset,
      o_RAMAddr => RAMAddr,
      o_RAMData => o_RAMData,
      i_RAMData => i_RAMData,
      o_RAMWE   => o_RAMWE,
      start     => sort_start,
      done      => sort_done
      );

  -- hook up RAM signals
  o_RAMClk  <= clk;
  o_RAMAddr <= RAMAddr(0 to C_BURST_AWIDTH-2) & not RAMAddr(C_BURST_AWIDTH-1);  -- invert LSB of address to get the word ordering right


  -- OS synchronization state machine
  state_proc               : process(clk, reset)
    variable done          : boolean;
    variable success       : boolean;
    variable burst_counter : natural range 0 to 8192/128 - 1;
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      sort_start <= '0';
      state      <= STATE_GET;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

          -- wait for/get data address. No error checking is done here.
          when STATE_GET =>
            reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_START, address);
            if done then
              burst_counter := 0;
              state <= STATE_READ;
            end if;

            -- read data from main memory into local burst RAM.
          when STATE_READ =>
            reconos_read_burst (done, o_osif, i_osif, std_logic_vector(TO_UNSIGNED(burst_counter*128, C_OSIF_DATA_WIDTH)), address+(burst_counter*128));
            if done then
              if burst_counter = 8192/128 - 1 then
                state <= STATE_SORT;
              else
                burst_counter := burst_counter + 1;
              end if;
            end if;

            -- start sorting module
          when STATE_SORT =>
            sort_start <= '1';
            state      <= STATE_WAIT;

            -- wait for sort completion
          when STATE_WAIT =>
            sort_start <= '0';
            if sort_done = '1' then
              burst_counter := 0;
              state    <= STATE_WRITE;
            end if;

            -- write sorted data back to main memory
          when STATE_WRITE =>
            reconos_write_burst (done, o_osif, i_osif, std_logic_vector(TO_UNSIGNED(burst_counter*128, C_OSIF_DATA_WIDTH)), address+(burst_counter*128));
            if done then
              if burst_counter = 8192/128 - 1 then
                state <= STATE_PUT;
              else
                burst_counter := burst_counter + 1;
              end if;
            end if;
            
            -- write message to DONE mailbox
          when STATE_PUT =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_DONE, address);
            if done then
              state <= STATE_GET;
            end if;

          when others =>
            state <= STATE_GET;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


