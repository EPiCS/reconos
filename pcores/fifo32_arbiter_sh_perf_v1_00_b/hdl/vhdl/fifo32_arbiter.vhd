--Doxygen
--! @file fifo32_arbiter.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        can connect multipe hardware threads with fifo32 interfaces to a 
--!        single xps_mem module.

library ieee;              --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
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
    IN_FIFO32_S_Data_A : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_A : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_A   : out std_logic;

    IN_FIFO32_M_Data_A : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_A  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_A   : out std_logic;

    IN_FIFO32_S_Data_B : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_B : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_B   : out std_logic;

    IN_FIFO32_M_Data_B : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_B  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_B   : out std_logic;

    IN_FIFO32_S_Data_C : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_C : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_C   : out std_logic;

    IN_FIFO32_M_Data_C : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_C  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_C   : out std_logic;

    IN_FIFO32_S_Data_D : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_D : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_D   : out std_logic;

    IN_FIFO32_M_Data_D : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_D  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_D   : out std_logic;

    IN_FIFO32_S_Data_E : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_E : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_E   : out std_logic;

    IN_FIFO32_M_Data_E : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_E  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_E   : out std_logic;

    IN_FIFO32_S_Data_F : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_F : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_F   : out std_logic;

    IN_FIFO32_M_Data_F : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_F  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_F   : out std_logic;

    IN_FIFO32_S_Data_G : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_G : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_G   : out std_logic;

    IN_FIFO32_M_Data_G : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_G  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_G   : out std_logic;

    IN_FIFO32_S_Data_H : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_H : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_H   : out std_logic;

    IN_FIFO32_M_Data_H : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_H  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_H   : out std_logic;

    IN_FIFO32_S_Data_I : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_I : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_I   : out std_logic;

    IN_FIFO32_M_Data_I : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_I  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_I   : out std_logic;

    IN_FIFO32_S_Data_J : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_J : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_J   : out std_logic;

    IN_FIFO32_M_Data_J : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_J  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_J   : out std_logic;

    IN_FIFO32_S_Data_K : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_K : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_K   : out std_logic;

    IN_FIFO32_M_Data_K : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_K  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_K   : out std_logic;

    IN_FIFO32_S_Data_L : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_L : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_L   : out std_logic;

    IN_FIFO32_M_Data_L : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_L  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_L   : out std_logic;

    IN_FIFO32_S_Data_M : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_M : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_M   : out std_logic;

    IN_FIFO32_M_Data_M : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_M  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_M   : out std_logic;

    IN_FIFO32_S_Data_N : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_N : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_N   : out std_logic;

    IN_FIFO32_M_Data_N : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_N  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_N   : out std_logic;

    IN_FIFO32_S_Data_O : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_O : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_O   : out std_logic;

    IN_FIFO32_M_Data_O : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_O  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_O   : out std_logic;

    IN_FIFO32_S_Data_P : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill_P : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd_P   : out std_logic;

    IN_FIFO32_M_Data_P : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem_P  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr_P   : out std_logic;

    -- Single FIFO32 Output
    OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic;

    OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic;

    -- Hardware Interface HWIF
    HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
    HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    HWIF2DEC_RdCE  : in  std_logic;
    HWIF2DEC_WrCE  : in  std_logic;
    DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2HWIF_RdAck : out std_logic;
    DEC2HWIF_WrAck : out std_logic;

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
  component fifo32_peek is
    generic (
      C_FIFO32_PEEK_DEPTH : integer := 64
      );
    port (
      Rst              : in  std_logic;
      FIFO32_S_Clk     : in  std_logic;
      FIFO32_M_Clk     : in  std_logic;
      FIFO32_S_Data    : out std_logic_vector(31 downto 0);
      FIFO32_M_Data    : in  std_logic_vector(31 downto 0);
      FIFO32_S_Fill    : out std_logic_vector(15 downto 0);
      FIFO32_M_Rem     : out std_logic_vector(15 downto 0);
      FIFO32_S_Rd      : in  std_logic;
      FIFO32_M_Wr      : in  std_logic;
      FIFO32_PEEK_DATA : out std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0)
      );
  end component;

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


  component hwif_subsystem is
    generic(
      C_HWT_ID                : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
      C_VERSION               : std_logic_vector(31 downto 0) := X"00000100";  -- Version Identifier
      C_CAPABILITIES          : std_logic_vector(31 downto 0) := X"00000001";  --Every Bit specifies a capability like performance monitoring etc.
      C_Perf_Counters_Num     : integer                       := 8;  -- How many performance counters do you want?
      C_CHECKSUM_NUM_CHANNELS : integer                       := 32;
      C_CHECKSUM_ALGO         : integer                       := 0;
      C_SLV_DWIDTH            : integer                       := 32
      );
    port (
      -- HWIF interface
      HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
      HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWIF2DEC_RdCE  : in  std_logic;
      HWIF2DEC_WrCE  : in  std_logic;
      DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      DEC2HWIF_RdAck : out std_logic;
      DEC2HWIF_WrAck : out std_logic;

      -- In-/outputs of internal submodules
      -- Performance Monitors custom signals
      increments : in std_logic_vector (C_Perf_Counters_Num-1 downto 0);

      -- Checksum generators custom signals
      read_data       : in std_logic_vector(31 downto 0);
      read_data_valid : in std_logic;
      read_channel    : in std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

      write_data       : in std_logic_vector(31 downto 0);
      write_data_valid : in std_logic;
      write_channel    : in std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

      -- GPIO 
      write_inhibit : in std_logic_vector(31 downto 0);

      -- other
      debug : out std_logic_vector(109 downto 0);

      clk : in std_logic;
      rst : in std_logic);
  end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

  constant C_CHECKSUM_NUM_CHANNELS : integer := 16;
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
  -- Internal signal vectors to unify all 16 FIFO32 ports
  signal IN_FIFO32_S_Data          : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Fill          : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Rd            : std_logic_vector(FIFO32_PORTS-1 downto 0);

  signal IN_FIFO32_M_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Rem  : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Wr   : std_logic_vector(FIFO32_PORTS-1 downto 0);

  -- Outputs of fifo32_peek stage:
  signal IN_PEEK_FIFO32_S_Data          : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_PEEK_FIFO32_S_Fill          : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_PEEK_FIFO32_S_Rd            : std_logic_vector(FIFO32_PORTS-1 downto 0);

  signal IN_PEEK_FIFO32_M_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_PEEK_FIFO32_M_Rem  : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_PEEK_FIFO32_M_Wr   : std_logic_vector(FIFO32_PORTS-1 downto 0);
  
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

  --! Signals from/to the HWIF subsystem
  constant C_Perf_Counters_Num : integer   := 8;  -- How many performance counters do you want?
  signal increments            : std_logic_vector (C_Perf_Counters_Num-1 downto 0);
  signal hwif_subsystem_rst    : std_logic := '0';  -- decouple hwif reset from hw
                                                    -- thread reset


  signal read_data       : std_logic_vector(31 downto 0);
  signal read_data_valid : std_logic;
  signal read_channel    : std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

  signal write_data       : std_logic_vector(31 downto 0);
  signal write_data_valid : std_logic;
  signal write_channel    : std_logic_vector(clog2(C_CHECKSUM_NUM_CHANNELS)-1 downto 0);

  -- GPIO 
  signal write_inhibit : std_logic_vector(31 downto 0);
  
begin  -- of architecture -------------------------------------------------------

  -- connect separate entity ports to internal signal vectors
  A : if FIFO32_PORTS > 0 generate
    IN_FIFO32_S_Data((32 * (1 + 0))-1 downto 32 * 0) <= IN_FIFO32_S_Data_A;
    IN_FIFO32_S_Fill((16 * (1 + 0))-1 downto 16 * 0) <= IN_FIFO32_S_Fill_A;
    IN_FIFO32_S_Rd_A                                 <= IN_FIFO32_S_Rd(0);

    IN_FIFO32_M_Data_A                              <= IN_FIFO32_M_Data((32 * (1 + 0))-1 downto 32 * 0);
    IN_FIFO32_M_Rem((16 * (1 + 0))-1 downto 16 * 0) <= IN_FIFO32_M_Rem_A;
    IN_FIFO32_M_Wr_A                                <= IN_FIFO32_M_Wr(0);
  end generate;

  B : if FIFO32_PORTS > 1 generate
    IN_FIFO32_S_Data((32 * (1 + 1))-1 downto 32 * 1) <= IN_FIFO32_S_Data_B;
    IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1) <= IN_FIFO32_S_Fill_B;
    IN_FIFO32_S_Rd_B                                 <= IN_FIFO32_S_Rd(1);

    IN_FIFO32_M_Data_B                              <= IN_FIFO32_M_Data((32 * (1 + 1))-1 downto 32 * 1);
    IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1) <= IN_FIFO32_M_Rem_B;
    IN_FIFO32_M_Wr_B                                <= IN_FIFO32_M_Wr(1);
  end generate;

  C : if FIFO32_PORTS > 2 generate
    IN_FIFO32_S_Data((32 * (1 + 2))-1 downto 32 * 2) <= IN_FIFO32_S_Data_C;
    IN_FIFO32_S_Fill((16 * (1 + 2))-1 downto 16 * 2) <= IN_FIFO32_S_Fill_C;
    IN_FIFO32_S_Rd_C                                 <= IN_FIFO32_S_Rd(2);

    IN_FIFO32_M_Data_C                              <= IN_FIFO32_M_Data((32 * (1 + 2))-1 downto 32 * 2);
    IN_FIFO32_M_Rem((16 * (1 + 2))-1 downto 16 * 2) <= IN_FIFO32_M_Rem_C;
    IN_FIFO32_M_Wr_C                                <= IN_FIFO32_M_Wr(2);
  end generate;

  D : if FIFO32_PORTS > 3 generate
    IN_FIFO32_S_Data((32 * (1 + 3))-1 downto 32 * 3) <= IN_FIFO32_S_Data_D;
    IN_FIFO32_S_Fill((16 * (1 + 3))-1 downto 16 * 3) <= IN_FIFO32_S_Fill_D;
    IN_FIFO32_S_Rd_D                                 <= IN_FIFO32_S_Rd(3);

    IN_FIFO32_M_Data_D                              <= IN_FIFO32_M_Data((32 * (1 + 3))-1 downto 32 * 3);
    IN_FIFO32_M_Rem((16 * (1 + 3))-1 downto 16 * 3) <= IN_FIFO32_M_Rem_D;
    IN_FIFO32_M_Wr_D                                <= IN_FIFO32_M_Wr(3);
  end generate;

  E : if FIFO32_PORTS > 4 generate
    IN_FIFO32_S_Data((32 * (1 + 4))-1 downto 32 * 4) <= IN_FIFO32_S_Data_E;
    IN_FIFO32_S_Fill((16 * (1 + 4))-1 downto 16 * 4) <= IN_FIFO32_S_Fill_E;
    IN_FIFO32_S_Rd_E                                 <= IN_FIFO32_S_Rd(4);

    IN_FIFO32_M_Data_E                              <= IN_FIFO32_M_Data((32 * (1 + 4))-1 downto 32 * 4);
    IN_FIFO32_M_Rem((16 * (1 + 4))-1 downto 16 * 4) <= IN_FIFO32_M_Rem_E;
    IN_FIFO32_M_Wr_E                                <= IN_FIFO32_M_Wr(4);
  end generate;

  F : if FIFO32_PORTS > 5 generate
    IN_FIFO32_S_Data((32 * (1 + 5))-1 downto 32 * 5) <= IN_FIFO32_S_Data_F;
    IN_FIFO32_S_Fill((16 * (1 + 5))-1 downto 16 * 5) <= IN_FIFO32_S_Fill_F;
    IN_FIFO32_S_Rd_F                                 <= IN_FIFO32_S_Rd(5);

    IN_FIFO32_M_Data_F                              <= IN_FIFO32_M_Data((32 * (1 + 5))-1 downto 32 * 5);
    IN_FIFO32_M_Rem((16 * (1 + 5))-1 downto 16 * 5) <= IN_FIFO32_M_Rem_F;
    IN_FIFO32_M_Wr_F                                <= IN_FIFO32_M_Wr(5);
  end generate;

  G : if FIFO32_PORTS > 6 generate
    IN_FIFO32_S_Data((32 * (1 + 6))-1 downto 32 * 6) <= IN_FIFO32_S_Data_G;
    IN_FIFO32_S_Fill((16 * (1 + 6))-1 downto 16 * 6) <= IN_FIFO32_S_Fill_G;
    IN_FIFO32_S_Rd_G                                 <= IN_FIFO32_S_Rd(6);

    IN_FIFO32_M_Data_G                              <= IN_FIFO32_M_Data((32 * (1 + 6))-1 downto 32 * 6);
    IN_FIFO32_M_Rem((16 * (1 + 6))-1 downto 16 * 6) <= IN_FIFO32_M_Rem_G;
    IN_FIFO32_M_Wr_G                                <= IN_FIFO32_M_Wr(6);
  end generate;

  H : if FIFO32_PORTS > 7 generate
    IN_FIFO32_S_Data((32 * (1 + 7))-1 downto 32 * 7) <= IN_FIFO32_S_Data_H;
    IN_FIFO32_S_Fill((16 * (1 + 7))-1 downto 16 * 7) <= IN_FIFO32_S_Fill_H;
    IN_FIFO32_S_Rd_H                                 <= IN_FIFO32_S_Rd(7);

    IN_FIFO32_M_Data_H                              <= IN_FIFO32_M_Data((32 * (1 + 7))-1 downto 32 * 7);
    IN_FIFO32_M_Rem((16 * (1 + 7))-1 downto 16 * 7) <= IN_FIFO32_M_Rem_H;
    IN_FIFO32_M_Wr_H                                <= IN_FIFO32_M_Wr(7);
  end generate;

  I : if FIFO32_PORTS > 8 generate
    IN_FIFO32_S_Data((32 * (1 + 8))-1 downto 32 * 8) <= IN_FIFO32_S_Data_I;
    IN_FIFO32_S_Fill((16 * (1 + 8))-1 downto 16 * 8) <= IN_FIFO32_S_Fill_I;
    IN_FIFO32_S_Rd_I                                 <= IN_FIFO32_S_Rd(8);

    IN_FIFO32_M_Data_I                              <= IN_FIFO32_M_Data((32 * (1 + 8))-1 downto 32 * 8);
    IN_FIFO32_M_Rem((16 * (1 + 8))-1 downto 16 * 8) <= IN_FIFO32_M_Rem_I;
    IN_FIFO32_M_Wr_I                                <= IN_FIFO32_M_Wr(8);
  end generate;

  J : if FIFO32_PORTS > 9 generate
    IN_FIFO32_S_Data((32 * (1 + 9))-1 downto 32 * 9) <= IN_FIFO32_S_Data_J;
    IN_FIFO32_S_Fill((16 * (1 + 9))-1 downto 16 * 9) <= IN_FIFO32_S_Fill_J;
    IN_FIFO32_S_Rd_J                                 <= IN_FIFO32_S_Rd(9);

    IN_FIFO32_M_Data_J                              <= IN_FIFO32_M_Data((32 * (1 + 9))-1 downto 32 * 9);
    IN_FIFO32_M_Rem((16 * (1 + 9))-1 downto 16 * 9) <= IN_FIFO32_M_Rem_J;
    IN_FIFO32_M_Wr_J                                <= IN_FIFO32_M_Wr(9);
  end generate;

  K : if FIFO32_PORTS > 10 generate
    IN_FIFO32_S_Data((32 * (1 + 10))-1 downto 32 * 10) <= IN_FIFO32_S_Data_K;
    IN_FIFO32_S_Fill((16 * (1 + 10))-1 downto 16 * 10) <= IN_FIFO32_S_Fill_K;
    IN_FIFO32_S_Rd_K                                   <= IN_FIFO32_S_Rd(10);

    IN_FIFO32_M_Data_K                                <= IN_FIFO32_M_Data((32 * (1 + 10))-1 downto 32 * 10);
    IN_FIFO32_M_Rem((16 * (1 + 10))-1 downto 16 * 10) <= IN_FIFO32_M_Rem_K;
    IN_FIFO32_M_Wr_K                                  <= IN_FIFO32_M_Wr(10);
  end generate;

  L : if FIFO32_PORTS > 11 generate
    IN_FIFO32_S_Data((32 * (1 + 11))-1 downto 32 * 11) <= IN_FIFO32_S_Data_L;
    IN_FIFO32_S_Fill((16 * (1 + 11))-1 downto 16 * 11) <= IN_FIFO32_S_Fill_L;
    IN_FIFO32_S_Rd_L                                   <= IN_FIFO32_S_Rd(11);

    IN_FIFO32_M_Data_L                                <= IN_FIFO32_M_Data((32 * (1 + 11))-1 downto 32 * 11);
    IN_FIFO32_M_Rem((16 * (1 + 11))-1 downto 16 * 11) <= IN_FIFO32_M_Rem_L;
    IN_FIFO32_M_Wr_L                                  <= IN_FIFO32_M_Wr(11);
  end generate;

  M : if FIFO32_PORTS > 12 generate
    IN_FIFO32_S_Data((32 * (1 + 12))-1 downto 32 * 12) <= IN_FIFO32_S_Data_M;
    IN_FIFO32_S_Fill((16 * (1 + 12))-1 downto 16 * 12) <= IN_FIFO32_S_Fill_M;
    IN_FIFO32_S_Rd_M                                   <= IN_FIFO32_S_Rd(12);

    IN_FIFO32_M_Data_M                                <= IN_FIFO32_M_Data((32 * (1 + 12))-1 downto 32 * 12);
    IN_FIFO32_M_Rem((16 * (1 + 12))-1 downto 16 * 12) <= IN_FIFO32_M_Rem_M;
    IN_FIFO32_M_Wr_M                                  <= IN_FIFO32_M_Wr(12);
  end generate;

  N : if FIFO32_PORTS > 13 generate
    IN_FIFO32_S_Data((32 * (1 + 13))-1 downto 32 * 13) <= IN_FIFO32_S_Data_N;
    IN_FIFO32_S_Fill((16 * (1 + 13))-1 downto 16 * 13) <= IN_FIFO32_S_Fill_N;
    IN_FIFO32_S_Rd_N                                   <= IN_FIFO32_S_Rd(13);

    IN_FIFO32_M_Data_N                                <= IN_FIFO32_M_Data((32 * (1 + 13))-1 downto 32 * 13);
    IN_FIFO32_M_Rem((16 * (1 + 13))-1 downto 16 * 13) <= IN_FIFO32_M_Rem_N;
    IN_FIFO32_M_Wr_N                                  <= IN_FIFO32_M_Wr(13);
  end generate;

  O : if FIFO32_PORTS > 14 generate
    IN_FIFO32_S_Data((32 * (1 + 14))-1 downto 32 * 14) <= IN_FIFO32_S_Data_O;
    IN_FIFO32_S_Fill((16 * (1 + 14))-1 downto 16 * 14) <= IN_FIFO32_S_Fill_O;
    IN_FIFO32_S_Rd_O                                   <= IN_FIFO32_S_Rd(14);

    IN_FIFO32_M_Data_O                                <= IN_FIFO32_M_Data((32 * (1 + 14))-1 downto 32 * 14);
    IN_FIFO32_M_Rem((16 * (1 + 14))-1 downto 16 * 14) <= IN_FIFO32_M_Rem_O;
    IN_FIFO32_M_Wr_O                                  <= IN_FIFO32_M_Wr(14);
  end generate;

  P : if FIFO32_PORTS > 15 generate
    IN_FIFO32_S_Data((32 * (1 + 15))-1 downto 32 * 15) <= IN_FIFO32_S_Data_P;
    IN_FIFO32_S_Fill((16 * (1 + 15))-1 downto 16 * 15) <= IN_FIFO32_S_Fill_P;
    IN_FIFO32_S_Rd_P                                   <= IN_FIFO32_S_Rd(15);

    IN_FIFO32_M_Data_P                                <= IN_FIFO32_M_Data((32 * (1 + 15))-1 downto 32 * 15);
    IN_FIFO32_M_Rem((16 * (1 + 15))-1 downto 16 * 15) <= IN_FIFO32_M_Rem_P;
    IN_FIFO32_M_Wr_P                                  <= IN_FIFO32_M_Wr(15);
  end generate;

  OUT_FIFO32_S_Fill <= INT_OUT_FIFO32_S_Fill;
  OUT_FIFO32_M_Rem  <= INT_OUT_FIFO32_M_Rem;
  -- Slave part of fifo link

  OUT_FIFO32_S_Data <= INT_OUT_FIFO32_S_Data;
  OUT_FIFO32_S_Fill <= INT_OUT_FIFO32_S_Fill;
  OUT_FIFO32_M_Rem  <= INT_OUT_FIFO32_M_Rem;

  -- In receiving direction, install fifo32_peeks, to be able to look at
  -- complete header.
  -- In sending direction, just pass the signals.
  fifo32_peeks: for i in 0 to FIFO32_PORTS generate
    fifo32_peek_i: fifo32_peek
      port map (
      Rst              => rst, 
      FIFO32_S_Clk     => clk,
      FIFO32_M_Clk     => clk,
      FIFO32_S_Data    => 
      FIFO32_M_Data    => 
      FIFO32_S_Fill    => 
      FIFO32_M_Rem     => 
      FIFO32_S_Rd      => 
      FIFO32_M_Wr      => 
      FIFO32_PEEK_DATA => 
         );
      
  end generate fifo32_peeks;
  
  mux_S_DATA : mux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_PEEK_FIFO32_S_Data,
      sel    => sel2mux,
      output => INT_OUT_FIFO32_S_DATA
      );   

  mux_S_FILL : mux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_PEEK_FIFO32_S_FILL,
      sel    => sel2mux,
      output => INT_OUT_FIFO32_S_Fill
      );   

  demux_S_Rd : demux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input(0) => OUT_FIFO32_S_Rd,
      sel      => sel2mux,
      output   => IN_PEEK_FIFO32_S_Rd
      );   

  -- Master part of fifo link

  demux_M_Data : demux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => OUT_FIFO32_M_Data,
      sel    => sel2mux,
      output => IN_PEEK_FIFO32_M_Data
      );   

  mux_M_Rem : mux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_PEEK_FIFO32_M_Rem,
      sel    => sel2mux,
      output => INT_OUT_FIFO32_M_Rem
      );   

  demux_M_Wr : demux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input(0) => OUT_FIFO32_M_Wr,
      sel      => sel2mux,
      output   => IN_PEEK_FIFO32_M_Wr
      );   

  -- Arbiter controls sel signal
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


  hwif : hwif_subsystem
    generic map(
      C_HWT_ID                => C_ID_ARBITER,  -- Unique ID number of this module
      C_VERSION               => X"00000100",   -- Version Identifier
      C_CAPABILITIES          => C_CAP_PERFMON,  --Every Bit specifies a capability like performance monitoring etc.
      C_Perf_Counters_Num     => C_Perf_Counters_Num,  -- How many performance counters do you want?
      C_CHECKSUM_NUM_CHANNELS => C_CHECKSUM_NUM_CHANNELS,
      C_CHECKSUM_ALGO         => 0,
      C_SLV_DWIDTH            => 32
      )
    port map(
      -- HWIF interface
      HWIF2DEC_Addr  => HWIF2DEC_Addr,
      HWIF2DEC_Data  => HWIF2DEC_Data,
      HWIF2DEC_RdCE  => HWIF2DEC_RdCE,
      HWIF2DEC_WrCE  => HWIF2DEC_WrCE,
      DEC2HWIF_Data  => DEC2HWIF_Data,
      DEC2HWIF_RdAck => DEC2HWIF_RdAck,
      DEC2HWIF_WrAck => DEC2HWIF_WrAck,

      -- In-/outputs of internal submodules
      -- Performance Monitors custom signals
      increments => increments,

      -- Checksum generators custom signals
      read_data       => read_data,
      read_data_valid => read_data_valid,
      read_channel    => read_channel,

      write_data       => write_data,
      write_data_valid => write_data_valid,
      write_channel    => write_channel,

      -- GPIO 
      write_inhibit => write_inhibit,

      -- other
      debug => open,
      clk   => clk,
      rst   => hwif_subsystem_rst);

  hwif_subsystem_rst <= rst;

  request_p : process (clk, rst, in_fifo32_s_fill)
    is

  begin
    --if Rst = '1' then
    --    requests <= (others => '0');
    --else --if clk'event and clk = '1' then
    for i in 0 to FIFO32_PORTS-1 loop
      if to_integer(unsigned(IN_PEEK_FIFO32_S_Fill((16*(i+1))-1 downto 16*i))) > 1 then
        requests(i) <= '1';
      else
        requests(i) <= '0';
      end if;
    end loop;
    --end if;

  end process;

  fsm_p : process (clk, rst, sel2fsm)
    is
    type FSM_STATE_T is (MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;

    variable selection : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);

    type TRANSFER_MODE_T is (READ, WRITE);
    variable transfer_mode : TRANSFER_MODE_T;
    variable transfer_size : natural range 0 to 2**24;

  begin
    if rst = '1' then
      state         := MODE_LENGTH;
      selection     := (others => '0');
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

      -- default is to hold all outputs.
      state         := state;
      selection     := selection;
      sel2mux       <= sel2mux;
      transfer_mode := transfer_mode;
      transfer_size := transfer_size;
      case state is
        when MODE_LENGTH =>
          if OUT_FIFO32_S_Rd = '1' then
            state := ADDRESS;
          end if;
          selection := sel2fsm;
          sel2mux   <= selection;
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
          state     := MODE_LENGTH;
          selection := selection;
          sel2mux   <= sel2mux;
      end case;
    end if;
  end process;

  checksum : process(clk, rst)
    is
    
  begin
    read_data       <= OUT_FIFO32_M_Data;
    read_data_valid <= OUT_FIFO32_M_Wr;
    read_channel    <= sel2mux;

    write_data       <= INT_OUT_FIFO32_S_Data;
    write_data_valid <= OUT_FIFO32_S_Rd;
    write_channel    <= sel2mux;
  end process;
  
end architecture;
