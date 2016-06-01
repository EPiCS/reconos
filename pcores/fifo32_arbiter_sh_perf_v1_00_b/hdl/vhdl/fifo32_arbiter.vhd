--Doxygen
--! @file fifo32_arbiter.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        can connect multipe hardware threads with fifo32 interfaces to a 
--!        single xps_mem module.

library ieee;              --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library plb2hwif_v1_00_a;
use plb2hwif_v1_00_a.hwif_pck.all;

entity fifo32_arbiter is
  generic (
    C_SLV_DWIDTH     : integer := 32;
    FIFO32_PORTS     : integer := 16;   --! 1 to 16 allowed
    ARBITRATION_ALGO : integer := 0  --! 0= Round Robin, others not available atm.
    );
  port (
    -- Multiple FIFO32 Inputs
    IN_FIFO32_S_Data : in  std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_S_Fill : in  std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_S_Rd   : out std_logic_vector(FIFO32_PORTS-1 downto 0);

    IN_FIFO32_M_Data : out std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_M_Rem  : in  std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_M_Wr   : out std_logic_vector(FIFO32_PORTS-1 downto 0);

    -- Single FIFO32 Output
    OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic;

    OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic;

    -- Which HWT is currently selected?
    HWT_INDEX : out unsigned(clog2(FIFO32_PORTS)-1 downto 0);
    START_OF_NEW_PACKET : out std_logic;

    -- Misc
    Rst : in std_logic;
    clk : in std_logic;                 -- separate clock for control logic

    -- Debug signals to ILA
    ila_signals : out std_logic_vector(130 downto 0)
    );
end entity;

--! Notes to implementor:
--! This Multiplexer may only switch to another input stream, when a complete
--! packet was transmitted. As we don't have any signals telling us the end or
--! start of a packet, we have to track the protocol to decide when to switch.
architecture behavioural of fifo32_arbiter is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
  component rr_arbiter
    generic(
      request_width : positive := 6  --! How many request inputs do you want?
      );
    port (
      clk      : in  std_logic;         --! Clock signal
      reset    : in  std_logic;         --! Reset signal
      requests : in  std_logic_vector (request_width-1 downto 0);  --! Input lines from the requestors.
      sel      : out std_logic_vector (clog2(request_width)-1 downto 0));  --! Who of the requesters will be served?
  end component;

  component mux
    generic (
      element_width : positive := 32;  --! Width in bits of the input and output ports
      element_count : positive := 16    --! Demux how many ports?
      );
    port (
      input  : in  std_logic_vector(element_width*element_count-1 downto 0);  --! An array of input vectors
      sel    : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! The select signals to choose the input to be forwarded
      output : out std_logic_vector(element_width-1 downto 0)  --! The output of the multiplexer
      );
  end component;

  component demux
    generic (
      element_width : positive := 32;  --! The width in bits of the input and output ports
      element_count : positive := 16    --! Demux to how many ports?
      );

    port (
      sel    : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! Select signal: which output register shall be updated?
      input  : in  std_logic_vector(element_width-1 downto 0);  --! Data input
      output : out std_logic_vector(element_width*element_count-1 downto 0)  --! Data output
      );
  end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

  constant C_CHECKSUM_NUM_CHANNELS : integer := 16;
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  --! Select signal from arbiter to the fsm.
  signal sel2mux : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);

  --! Select signal from fsm to the (de-)multiplexers.
  signal sel2fsm : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);

  --! 
  signal requests : std_logic_vector(FIFO32_PORTS-1 downto 0);

  --! Tap slave data output to memory controller
  signal INT_OUT_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal INT_OUT_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal INT_OUT_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  
begin  -- of architecture -------------------------------------------------------

  OUT_FIFO32_S_Data <= INT_OUT_FIFO32_S_Data;
  OUT_FIFO32_S_Fill <= INT_OUT_FIFO32_S_Fill;
  OUT_FIFO32_M_Rem  <= INT_OUT_FIFO32_M_Rem;

  HWT_INDEX <= unsigned(sel2mux);

  my_fifo32_mux : entity work.fifo32_mux
    generic map (
      FIFO32_PORTS => FIFO32_PORTS)
    port map (
      IN_FIFO32_S_Data  => IN_FIFO32_S_Data,
      IN_FIFO32_S_Fill  => IN_FIFO32_S_Fill,
      IN_FIFO32_S_Rd    => IN_FIFO32_S_Rd,
      IN_FIFO32_M_Data  => IN_FIFO32_M_Data,
      IN_FIFO32_M_Rem   => IN_FIFO32_M_Rem,
      IN_FIFO32_M_Wr    => IN_FIFO32_M_Wr,
      OUT_FIFO32_S_Data => INT_OUT_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => INT_OUT_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => OUT_FIFO32_S_Rd,
      OUT_FIFO32_M_Data => OUT_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => INT_OUT_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => OUT_FIFO32_M_Wr,
      SEL               => sel2mux);

  -- Arbiter controls sel2fsm signal
  rr_arbiter_i : rr_arbiter
    generic map(
      request_width => FIFO32_PORTS
      )
    port map(
      clk      => clk,
      reset    => Rst,
      requests => requests,
      sel      => sel2fsm
      );


  request_p : process (clk, rst, in_fifo32_s_fill) is
  begin
    for i in 0 to FIFO32_PORTS-1 loop
      if to_integer(unsigned(IN_FIFO32_S_Fill((16*(i+1))-1 downto 16*i))) > 1 then
        requests(i) <= '1';
      else
        requests(i) <= '0';
      end if;
    end loop;
  end process;

  fsm_p : process (clk, rst, sel2fsm) is
    type FSM_STATE_T is (MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;

    type TRANSFER_MODE_T is (READ, WRITE);
    variable transfer_mode : TRANSFER_MODE_T;
    variable transfer_size : natural range 0 to 2**24;

  begin
    if rst = '1' then
      state         := MODE_LENGTH;
      sel2mux       <= (others => '0');
      transfer_mode := READ;
    elsif clk'event and clk = '1' then
      -- for ILA debug

      case state is
        when MODE_LENGTH => ila_signals(3 downto 2) <= "00";
        when ADDRESS     => ila_signals(3 downto 2) <= "01";
        when DATA_READ   => ila_signals(3 downto 2) <= "10";
        when DATA_WRITE  => ila_signals(3 downto 2) <= "11";
        when others      => null;
      end case;

      -- ila signals 0 to 7 are always present, but only available sel2fsm
      -- signals are connected. ila_signals(7) is a buffer to prevent an
      -- illegal assignment.
      ila_signals(clog2(FIFO32_PORTS)-1 downto 0) <= sel2fsm;
      ila_signals(7 downto clog2(FIFO32_PORTS))   <= (others => '0');

      -- ila signals 8 to 15 are always present, but only available sel2mux
      -- signals are connected. ila_signals(15) is a buffer to prevent an
      -- illegal assignment.
      ila_signals(clog2(FIFO32_PORTS)-1+8 downto 8) <= sel2mux;
      ila_signals(15 downto clog2(FIFO32_PORTS)+8)  <= (others => '0');

      ila_signals(FIFO32_PORTS-1+16 downto 16) <= requests;
      ila_signals(32 downto FIFO32_PORTS+16)   <= (others => '0');

      ila_signals(64 downto 33) <= INT_OUT_FIFO32_S_Data;
      ila_signals(80 downto 65) <= INT_OUT_FIFO32_S_Fill;
      ila_signals(81)           <= OUT_FIFO32_S_Rd;

      ila_signals(113 downto 82)  <= OUT_FIFO32_M_Data;
      ila_signals(129 downto 114) <= INT_OUT_FIFO32_M_Rem;
      ila_signals(130)            <= OUT_FIFO32_M_Wr;

      START_OF_NEW_PACKET <= '0';
      case state is
        when MODE_LENGTH =>
          if OUT_FIFO32_S_Rd = '1' then
            state := ADDRESS;
            START_OF_NEW_PACKET <= '1'; --@BUG: Maybe too late?
          end if;
          sel2mux <= sel2fsm;
          case INT_OUT_FIFO32_S_DATA(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
                           
          end case;
          -- lower 24 bits of first word are defined to be the length
          -- of the transfer.
          transfer_size := to_integer(unsigned(INT_OUT_FIFO32_S_DATA(23 downto 0)));
        when ADDRESS =>
          case transfer_mode is
            when READ  => state := DATA_READ;
            when WRITE => state := DATA_WRITE;
          end case;
        when DATA_READ =>
          if OUT_FIFO32_M_Wr = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state := MODE_LENGTH;
          end if;
        when DATA_WRITE =>
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state := MODE_LENGTH;
          end if;
        when others =>
          state := MODE_LENGTH;
      end case;
    end if;
  end process;

end architecture;
