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

entity fifo32_arbiter_sh_rel is
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

    -- Run-time options
    RUNTIME_OPTIONS : in std_logic_vector(15 downto 0 );

    -- Error reporting
    ERROR_REQ : out std_logic;
    ERROR_ACK : in  std_logic;
    ERROR_TYP : out std_logic_vector(7 downto 0);
    ERROR_ADR : out std_logic_vector(31 downto 0);

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
architecture behavioural of fifo32_arbiter_sh_rel is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
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

  constant C_CHECKSUM_NUM_CHANNELS : integer := FIFO32_PORTS;

  constant ERROR_TYP_NONE    : std_logic_vector(7 downto 0) := X"00";
  constant ERROR_TYP_HEADER1 : std_logic_vector(7 downto 0) := X"01";
  constant ERROR_TYP_HEADER2 : std_logic_vector(7 downto 0) := X"02";
  constant ERROR_TYP_DATA    : std_logic_vector(7 downto 0) := X"03";

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
  --! Registers for storing error information 
  signal error_typ_reg : std_logic_vector(7 downto 0);
  signal error_adr_reg : std_logic_vector(31 downto 0);

  -- These state definition belongs to process fsm_p. Because ISE Simulator
  -- can't access process local variables, the state signal is defined here.
  type FSM_STATE_T is (
    -- Synchronization
    WAIT_THREADS,
    UPDATE_RUNTIME_OPTIONS,
    -- Packet handling
    READ_MODE_LENGTH, READ_ADDRESS, WRITE_MODE_LENGTH, SYNC_READ, SYNC_WRITE, COMP_REQ,
    WRITE_ADDRESS, DATA_READ, DATA_WRITE,
    -- Error Handling:
    DELETE_REQUEST_TUO, DELETE_REQUEST_ST,  COMPLETE_WRITE,
    REPORT_ERROR, WAIT_ERROR_ACK);
  signal state_tuo : FSM_STATE_T;
  signal state_st : FSM_STATE_T;

  --! For storing the first packet word
  type reg_vector_t is array (natural range<>) of std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal mode_length_reg : reg_vector_t(0 to 1);
  signal address_reg     : reg_vector_t(0 to 1);

  --! Internal signal vectors to unify all 16 FIFO32 ports
  signal IN_FIFO32_S_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Fill : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_S_Rd   : std_logic_vector(FIFO32_PORTS-1 downto 0);

  signal IN_FIFO32_M_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Rem  : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
  signal IN_FIFO32_M_Wr   : std_logic_vector(FIFO32_PORTS-1 downto 0);

  --! Translates FIFO fill levels into a single bit request per port.
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

  -- run-time options registers
  signal error_detection_on_reg: std_logic;

  -- GPIO 
  signal write_inhibit : std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- Aliases
--------------------------------------------------------------------------------
  alias error_detection_on : std_logic is RUNTIME_OPTIONS(0);

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
  function minimum (a : unsigned; b : unsigned)
    return unsigned is
  begin
    if a > b then return b;
    else return a;
    end if;
  end function;
    
  -- Returns the minimum of two stripes of a std_logic_vector. 
  -- Optionally an offset is added to that minimum.
  function my_minimum( 	v: std_logic_vector; 
						stripe_length: integer;
						stripe_a: integer; 
						stripe_b: integer;
						offset  : integer := 0)
	return std_logic_vector is
  begin
	return std_logic_vector(minimum(
            unsigned(v((stripe_length * (1 + stripe_a))-1 downto 16 * stripe_a)),
            unsigned(v((stripe_length * (1 + stripe_b))-1 downto 16 * stripe_b)))
            + offset);
  end function;
  
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


  -- Analyzes all fill levels of input FIFOS and sets the request vector accordingly.
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

  -- This process controlls non registered state machine outputs.
  -- If we don't register all outputs, the state machine reacts faster to
  -- changing inputs and state machine design is easier.
  fsm_outputs_tuo_p: process (state_tuo, IN_FIFO32_M_Rem, mode_length_reg, address_reg,
                          OUT_FIFO32_M_Data, OUT_FIFO32_M_Wr, OUT_FIFO32_S_Rd,
                          IN_FIFO32_S_Data, IN_FIFO32_S_Fill, IN_FIFO32_S_Rd, REQUESTS, 
                          int_out_fifo32_s_data,int_out_fifo32_s_fill, int_out_fifo32_m_rem, 
                          error_detection_on_reg )
  is

  begin
      -- for ILA debug
      ila_signals <= (others => '0');
      case state_tuo is
	      when WAIT_THREADS       => ila_signals(3 downto 0) <= "0000"; --0
	      when READ_MODE_LENGTH   => ila_signals(3 downto 0) <= "0001"; --1
	      when READ_ADDRESS       => ila_signals(3 downto 0) <= "0010"; --2
	      when WRITE_MODE_LENGTH  => ila_signals(3 downto 0) <= "0011"; --3
	      when COMP_REQ           => ila_signals(3 downto 0) <= "0100"; --4
	      when WRITE_ADDRESS      => ila_signals(3 downto 0) <= "0101"; --5
	      when DATA_READ          => ila_signals(3 downto 0) <= "0110"; --6
	      when DATA_WRITE         => ila_signals(3 downto 0) <= "0111"; --7
	      when DELETE_REQUEST_TUO => ila_signals(3 downto 0) <= "1000"; --8
	      when DELETE_REQUEST_ST  => ila_signals(3 downto 0) <= "1001"; --9
	      when COMPLETE_WRITE     => ila_signals(3 downto 0) <= "1010"; --A
	      when REPORT_ERROR       => ila_signals(3 downto 0) <= "1011"; --B
	      when WAIT_ERROR_ACK     => ila_signals(3 downto 0) <= "1100"; --C
        when others      => null;
      end case;
      --ila_signals (15 downto 4)
      ila_signals (7 downto 4) <= IN_FIFO32_S_Fill(3 downto 0); -- lower 4 bits of port A
      ila_signals (11 downto 8) <= IN_FIFO32_S_Fill(19 downto 16); -- lower 4 bits of Port B
      ila_signals(13 downto 12) <= IN_FIFO32_S_Rd(1 downto 0); -- read signal of ports A and B
      --ila_signals (15 dowto 12) <= 
      
      
      ila_signals(FIFO32_PORTS-1+16 downto 16) <= requests;
      ila_signals(32 downto FIFO32_PORTS+16)   <= (others => '0');

      ila_signals(64 downto 33) <= INT_OUT_FIFO32_S_Data;
      ila_signals(80 downto 65) <= INT_OUT_FIFO32_S_Fill;
      ila_signals(81)           <= OUT_FIFO32_S_Rd;

      ila_signals(113 downto 82)  <= OUT_FIFO32_M_Data;
      ila_signals(129 downto 114) <= INT_OUT_FIFO32_M_Rem;
      ila_signals(130)            <= OUT_FIFO32_M_Wr;
  
    -- defaults
    IN_FIFO32_S_Rd(0) 			        <= '0';
    IN_FIFO32_M_Wr(0)                   <= '0';
    IN_FIFO32_M_Data(31 downto 0)      <= (others => '0');
    INT_OUT_FIFO32_M_Rem(15 downto 0)  <= (others => '0');
    INT_OUT_FIFO32_S_Data(31 downto 0) <= (others => '0');
    INT_OUT_FIFO32_S_Fill(15 downto 0) <= (others => '0');
    case state_tuo is
      ------------------
      -- Synchronization
      ------------------
      when WAIT_THREADS => -- does nothing
      when UPDATE_RUNTIME_OPTIONS => -- does nothing
      ------------------
      -- Packet handling
      ------------------
      when READ_MODE_LENGTH =>
        IN_FIFO32_S_Rd(0 downto 0) <= "1";
		
      when READ_ADDRESS =>
        IN_FIFO32_S_Rd(0 downto 0) <= "1";
        
	  when SYNC_READ =>
		    
	  when SYNC_WRITE =>
		    
	  when COMP_REQ =>
		    
      when WRITE_MODE_LENGTH =>
        -- fill_level handling: +2 for unwritten mode_length and address word
        if (error_detection_on_reg = '1') then
			INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,0,1, offset=> 2);
        	INT_OUT_FIFO32_S_Data <= mode_length_reg(0);
        else 
	        INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,1,1, offset=> 2);
        	INT_OUT_FIFO32_S_Data <= mode_length_reg(0);
        end if;

      when WRITE_ADDRESS =>
        -- fill_level handling: +1 for unwritten address word
        if (error_detection_on_reg = '1') then
			INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,0,1, offset=> 1);
        	INT_OUT_FIFO32_S_Data <= address_reg(0);
        else 
	        INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,1,1, offset=> 1);
        	INT_OUT_FIFO32_S_Data <= address_reg(0);
        end if;
          
      when DATA_READ =>
        -- synchronize mem port with thread ports
        IN_FIFO32_M_Data((32 * (1 + 0))-1 downto 32 * 0) <= OUT_FIFO32_M_Data;
        IN_FIFO32_M_Wr(0 downto 0)                       <= (others => OUT_FIFO32_M_Wr);

        -- fill_level handling
        -- reads have to be always synchronized
        INT_OUT_FIFO32_M_Rem <= my_minimum(IN_FIFO32_M_Rem, 16, 0, 1);
                
      when DATA_WRITE =>
        IN_FIFO32_S_Rd(0)     <= OUT_FIFO32_S_Rd;
        INT_OUT_FIFO32_S_DATA <= IN_FIFO32_S_Data(31 downto 0);
        
        -- Writes are only synchronized and checked for error when error detection is on
        if (error_detection_on_reg = '1') then
        	INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,0,1);
        else
	        -- with no error detection let TUO determine write speed
	        INT_OUT_FIFO32_S_Fill <= IN_FIFO32_S_Fill(15 downto 0);
        end if;
               
      -----------------
      -- Error handling
      -----------------
      when DELETE_REQUEST_TUO =>
        case mode_length_reg(0)(31) is
          when '0' =>
            -- thread reads
            if unsigned(IN_FIFO32_M_Rem((16 * (1 + 0))-1 downto 16 * 0)) > 0 then
              IN_FIFO32_M_Wr(0) <= '1';
            else
              IN_FIFO32_M_Wr(0) <= '0';              
            end if;
            
          when '1' =>
            -- thread writes
            if unsigned(IN_FIFO32_S_Fill((16 * (1 + 0))-1 downto 16 * 0)) > 0 then
              IN_FIFO32_S_Rd(0) <= '1';
            else
              IN_FIFO32_S_Rd(0) <= '0';
            end if;
            
          when others =>
            report "Request mode undefined!" severity ERROR;
        end case;

      when DELETE_REQUEST_ST =>
	      -- handled by st state machine

	  when COMPLETE_WRITE =>
		-- forwards TUO data    
        IN_FIFO32_S_Rd(0)     <= OUT_FIFO32_S_Rd;
        INT_OUT_FIFO32_S_DATA <= IN_FIFO32_S_Data(31 downto 0);
		INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,0,1);
        
      when REPORT_ERROR =>
        
      when WAIT_ERROR_ACK =>
    end case;
  end process;
  
  -- State machine for request selection, packet tracking and shadowing
  fsm_states_tuo_p : process (clk, rst) is
    type TRANSFER_MODE_T is (READ, WRITE);
    variable transfer_mode : TRANSFER_MODE_T;
    variable transfer_size : natural range 0 to 2**24;
    
  begin
    if rst = '1' then
      state_tuo          <= WAIT_THREADS;
      mode_length_reg(0) <= (others => '0');
      address_reg(0)     <= (others => '0');
      transfer_mode   := READ;
      transfer_size   := 0;

      error_detection_on_reg <= '1';

      ERROR_REQ <= '0';
      ERROR_TYP <= (others => '0');
      ERROR_ADR <= (others => '0');
    elsif clk'event and clk = '1' then

      -- default is to hold all outputs.
      state_tuo         <= state_tuo;
      transfer_mode := transfer_mode;
      transfer_size := transfer_size;

      -----------------------------------------------------------------------
      -- INFO: We expect TUO to be connected to port 0 and ST to be connected
      -- to port 1. No other ports are served.
      -----------------------------------------------------------------------
      case state_tuo is
        ------------------
        -- Synchronization
        ------------------
		    
		when WAIT_THREADS =>
          -- TODO: fill_level handling!
          -- TUO and ST read in headers seperatley and then synchronize 
          if requests(0 downto 0) = "1" then
            state_tuo                      <= UPDATE_RUNTIME_OPTIONS;
          end if;

	    when UPDATE_RUNTIME_OPTIONS =>
		    error_detection_on_reg <= error_detection_on;		    
		    state_tuo <= READ_MODE_LENGTH;
        ------------------
        -- Packet handling
        ------------------
        when READ_MODE_LENGTH =>
          -- TODO: fill_level handling!
          -- Read in first word of header from both threads
            mode_length_reg(0)            <= IN_FIFO32_S_Data(31 downto 0);
            state_tuo                      <= READ_ADDRESS;

          -- Take information from TUO
          case IN_FIFO32_S_DATA(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          -- lower 24 bits of first word are defined to be the length
          -- of the transfer.
          transfer_size := to_integer(unsigned(IN_FIFO32_S_DATA(23 downto 0)));

          
        when READ_ADDRESS =>
          -- TODO: fill_level handling!
          -- Read in second  word of header from both threads 
            address_reg(0) <= IN_FIFO32_S_Data(31 downto 0);
            if transfer_mode = READ then
            	state_tuo       <= SYNC_READ;
            else
	            state_tuo       <= SYNC_WRITE;
            end if;
            
	    when SYNC_READ =>
		      -- do we sync every time?
		      -- when we are here we either have a read ar write request.
		      -- on a read request we always have to sync.
		      -- on a write request only if error detection is on
		      -- We also need to check if the other thread has the same request as we have!
		    if  ( (state_st = SYNC_READ) or 
			     (state_st = SYNC_WRITE and error_detection_on_reg = '1') ) 
			then
				state_tuo <= COMP_REQ;		    
		    end if;
		
	    when SYNC_WRITE =>
			if ( error_detection_on_reg = '1' and (state_st = SYNC_WRITE or state_st = SYNC_READ) ) OR
			    (error_detection_on_reg = '0' )
			then
				state_tuo <= COMP_REQ;		    
			end if;  
			
        when COMP_REQ =>
          -- TODO: fill_level handling!
          -- Compare both headers. If same continue normally, if not, go to
          -- error handling.
          if
	        (error_detection_on_reg = '0') OR -- override error checks if runtime options says so
            ( (mode_length_reg(0) = mode_length_reg(1))AND(address_reg(0) = address_reg(1)) )            
          then
            state_tuo       <= WRITE_MODE_LENGTH;

          --------------------
          -- ERROR HANDLING
          --------------------
          elsif mode_length_reg(0) /= mode_length_reg(1) then
            state_tuo         <= DELETE_REQUEST_TUO;
            error_typ_reg <= ERROR_TYP_HEADER1;
            error_adr_reg <= (others => '0');
          elsif address_reg(0) /= address_reg(1)then
            state_tuo         <= DELETE_REQUEST_TUO;
            error_typ_reg <= ERROR_TYP_HEADER2;
            error_adr_reg <= (others => '0');
          end if;
            
	    when WRITE_MODE_LENGTH =>
		  -- wait for header word being read
          if OUT_FIFO32_S_Rd = '1' then
            state_tuo                 <= WRITE_ADDRESS;
          end if;
          
	    when WRITE_ADDRESS =>
		  -- wait for header word being read
		  -- and then jump to read or write data
          if OUT_FIFO32_S_Rd = '1' then
            case transfer_mode is
              when READ =>
                state_tuo <= DATA_READ;
              when WRITE =>
                state_tuo <= DATA_WRITE;              
            end case;
          end if;
          

        when DATA_READ =>
          if OUT_FIFO32_M_Wr = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_tuo <= WAIT_THREADS;
          end if;
          
        when DATA_WRITE =>
          -- TODO: What data do we write on error? TUO Data? ST Data? All
          -- zeros? Special Marker?
          -- TODO: What about forever stalling thread?
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_tuo <= WAIT_THREADS;
          end if;

          -- Lesson learned: error handling has to outvote everything else, so we
          -- have to put error handling last in the VHDL code.
          if  (error_detection_on_reg = '1') AND -- override error checks if runtime options says so
	          ( IN_FIFO32_S_Data(31 downto 0) /= IN_FIFO32_S_Data(63 downto 32) ) 
	      then
            state_tuo         <= COMPLETE_WRITE;
            error_typ_reg <= ERROR_TYP_DATA;
            error_adr_reg <= std_logic_vector(unsigned(mode_length_reg(0)(23 downto 0)) - transfer_size+ unsigned(address_reg(0))-4);
          end if;
        -----------------
        -- Error handling
        -----------------
        when DELETE_REQUEST_TUO =>
          -- TODO: What about forever stalling thread?
          -- Handle threads seperately: they might have different request types and
          -- lengths, so we have to delete the request individually

          if (unsigned(IN_FIFO32_S_Fill((16 * (1 + 0))-1 downto 16 * 0)) > 0 and mode_length_reg(0)(31) = '1') or
             (unsigned(IN_FIFO32_M_Rem((16 * (1 + 0))-1 downto 16 * 0)) > 0 and mode_length_reg(0)(31) = '0')
          then
            transfer_size              := transfer_size-4;          
          end if;

          if transfer_size = 0 then
            state_tuo <= DELETE_REQUEST_ST;
            transfer_size := to_integer(unsigned(mode_length_reg(1)(23 downto 0)));
          end if;

        when DELETE_REQUEST_ST =>
          if (unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) > 0 and mode_length_reg(1)(31) = '1') or
             (unsigned(IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1)) > 0 and mode_length_reg(1)(31) = '0')
          then
            transfer_size              := transfer_size-4;          
          end if;

          if transfer_size = 0 then
            state_tuo <= REPORT_ERROR;
          end if;
          
        when COMPLETE_WRITE =>
          -- TODO: What data do we write on error? TUO Data? ST Data? All
          -- zeros? Special Marker?
          -- TODO: What about forever stalling thread?
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_tuo <= REPORT_ERROR;
          end if;

        when REPORT_ERROR =>
          ERROR_REQ <= '1';
          ERROR_TYP <= error_typ_reg;
          ERROR_ADR <= error_adr_reg;
          state_tuo <= WAIT_ERROR_ACK;
          
        when WAIT_ERROR_ACK =>
          if ERROR_ACK = '1' then
            state_tuo <= WAIT_THREADS;

            -- reset error interface
            ERROR_REQ <= '0';
            ERROR_TYP <= ERROR_TYP_NONE;
            ERROR_ADR <= (others => '0');
          end if;
          
        when others =>
          state_tuo <= WAIT_THREADS;
      end case;
    end if;
  end process;



 -- This process controll non registered state machine outputs.
  -- If we don't register all outputs, the state machine reacts faster to
  -- changing inputs and state machine design is easier.
  fsm_outputs_st_p: process (state_st, IN_FIFO32_M_Rem, mode_length_reg, address_reg,
                          OUT_FIFO32_M_Data, OUT_FIFO32_M_Wr, OUT_FIFO32_S_Rd,
                          IN_FIFO32_S_Data, IN_FIFO32_S_Fill)
  is

  begin
  
    -- defaults
    IN_FIFO32_S_Rd(1)        <= '0';
    IN_FIFO32_M_Wr(1)        <= '0';
    IN_FIFO32_M_Data(63 downto 32)     <= (others => '0');
    
    -- Following signals are handled by TUO state machine
    --INT_OUT_FIFO32_M_Rem(31 downto 15)  <= (others => '0');
    --INT_OUT_FIFO32_S_Data(63 downto 32) <= (others => '0');
    --INT_OUT_FIFO32_S_Fill(31 downto 15) <= (others => '0');
    case state_st is
      ------------------
      -- Synchronization
      ------------------
      when WAIT_THREADS => -- does nothing
      when UPDATE_RUNTIME_OPTIONS => -- does nothing
      ------------------
      -- Packet handling
      ------------------
      when READ_MODE_LENGTH =>
        IN_FIFO32_S_Rd(1 downto 1) <= "1";
		
      when READ_ADDRESS =>
        IN_FIFO32_S_Rd(1 downto 1) <= "1";

	  when SYNC_READ =>
		    
	  when SYNC_WRITE =>
		    
      when COMP_REQ =>
      
      when WRITE_MODE_LENGTH =>
        -- fill_level handling: +2 for unwritten mode_length and address word
	    -- empty for st, because st writes are discarded
  
      when WRITE_ADDRESS =>
        -- fill_level handling: +1 for unwritten address word
		-- empty for st, because st writes are discarded
          
      when DATA_READ =>
        -- synchronize mem port with thread ports
        IN_FIFO32_M_Data((32 * (1 + 1))-1 downto 32 * 1) <= OUT_FIFO32_M_Data;
        IN_FIFO32_M_Wr(1 downto 1)                       <= (others => OUT_FIFO32_M_Wr);

        -- fill_level handling
        -- controlled by tuo state machine
        --INT_OUT_FIFO32_M_Rem <= my_minimum(IN_FIFO32_M_Rem, 16, 0, 1);
                
      when DATA_WRITE =>
        IN_FIFO32_S_Rd(1)     <= OUT_FIFO32_S_Rd;
        -- TUO state machine writes outputs
        --INT_OUT_FIFO32_S_DATA <= IN_FIFO32_S_Data(31 downto 0);
        --if (error_detection_on_reg = '1') then
        --	INT_OUT_FIFO32_S_Fill <= my_minimum(IN_FIFO32_S_Fill, 16,0,1);
        --else
	        -- with no error detection let TUO determine write speed
	    --    INT_OUT_FIFO32_S_Fill <= IN_FIFO32_S_Fill(15 downto 0);
        --end if;
               
      -----------------
      -- Error handling
      -----------------
      when DELETE_REQUEST_TUO =>
	      -- handled by tuo state machine

      when DELETE_REQUEST_ST =>
        case mode_length_reg(1)(31) is
          when '0' =>
            -- thread reads
            if unsigned(IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1)) > 0 then
              IN_FIFO32_M_Wr(1) <= '1';
            else
              IN_FIFO32_M_Wr(1) <= '0';              
            end if;
            
          when '1' =>
            -- thread writes
            if unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) > 0 then
              IN_FIFO32_S_Rd(1) <= '1';
            else
              IN_FIFO32_S_Rd(1) <= '0';
            end if;

          when others =>
            report "Request mode undefined!" severity ERROR;
        end case;
        
	  when COMPLETE_WRITE =>
		-- tuo state machine handles rest of signals
		-- TUO data is forwarded, ST data is discarded
        IN_FIFO32_S_Rd(1)     <= OUT_FIFO32_S_Rd;
        
      when REPORT_ERROR =>
        
      when WAIT_ERROR_ACK =>
    end case;   
  end process;
  
  -- State machine for request selection, packet tracking and shadowing
  fsm_states_st_p : process (clk, rst) is
    type TRANSFER_MODE_T is (READ, WRITE);
    variable transfer_mode : TRANSFER_MODE_T;
    variable transfer_size : natural range 0 to 2**24;
    
  begin
    if rst = '1' then
      state_st           <= WAIT_THREADS;
      mode_length_reg(1) <= (others => '0');
      address_reg(1)     <= (others => '0');
      transfer_mode   := READ;
      transfer_size   := 0;

      -- controlled by tuo state machine
      --error_detection_on_reg <= '1';
      --ERROR_REQ <= '0';
      --ERROR_TYP <= (others => '0');
      --ERROR_ADR <= (others => '0');
    elsif clk'event and clk = '1' then

      -- default is to hold all outputs.
      state_st         <= state_st;
      transfer_mode := transfer_mode;
      transfer_size := transfer_size;

      -----------------------------------------------------------------------
      -- INFO: We expect TUO to be connected to port 0 and ST to be connected
      -- to port 1. No other ports are served.
      -----------------------------------------------------------------------
      case state_st is
        ------------------
        -- Synchronization
        ------------------
		    
		when WAIT_THREADS =>
          -- TODO: fill_level handling!
          -- TUO and ST read in headers seperatley and then synchronize 
          if requests(1 downto 1) = "1" then
            state_st                      <= UPDATE_RUNTIME_OPTIONS;
          end if;

	    when UPDATE_RUNTIME_OPTIONS =>
		    -- done by tuo state machine  
		    --error_detection_on_reg <= error_detection_on;		    
		    state_st <= READ_MODE_LENGTH;
        ------------------
        -- Packet handling
        ------------------
        when READ_MODE_LENGTH =>
          -- TODO: fill_level handling!
          -- Read in first word of header from both threads
            mode_length_reg(1)            <= IN_FIFO32_S_Data(63 downto 32);
            state_st                      <= READ_ADDRESS;

          -- Take information from TUO
          case IN_FIFO32_S_DATA(63) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          -- lower 24 bits of first word are defined to be the length
          -- of the transfer.
          transfer_size := to_integer(unsigned(IN_FIFO32_S_DATA(55 downto 32)));

          
        when READ_ADDRESS =>
          -- TODO: fill_level handling!
          -- Read in second  word of header from both threads 
            address_reg(1) <= IN_FIFO32_S_Data(63 downto 32);            
            if transfer_mode = READ then
            	state_st       <= SYNC_READ;
            else
	            state_st       <= SYNC_WRITE;
            end if;
            
	    when SYNC_READ =>
	      -- do we sync every time?
		      -- when we are here we either have a read ar write request.
		      -- on a read request we always have to sync.
		      -- on a write request only if error detection is on
		      -- We also need to check if the other thread has the same request as we have!
		    if  ( (state_tuo = SYNC_READ) or 
			     (state_tuo = SYNC_WRITE and error_detection_on_reg = '1') )  
			then
				state_st <= COMP_REQ;		    
		    end if; 

	    when SYNC_WRITE =>
			if ( error_detection_on_reg = '1' and (state_tuo = SYNC_WRITE or state_tuo = SYNC_READ) ) OR
			    (error_detection_on_reg = '0' )
			then
				state_st <= COMP_REQ;		    
			end if;
				
        when COMP_REQ =>
          -- TODO: fill_level handling!
          -- Compare both headers. If same continue normally, if not, go to
          -- error handling.
	      -- copy/pasted from TUO state machine.
	      if
	        (error_detection_on_reg = '0') OR -- override error checks if runtime options says so
            ( (mode_length_reg(0) = mode_length_reg(1))AND(address_reg(0) = address_reg(1)) )            
          then
            state_st       <= WRITE_MODE_LENGTH;

          --------------------
          -- ERROR HANDLING
          --------------------
          elsif mode_length_reg(0) /= mode_length_reg(1) then
            state_st         <= DELETE_REQUEST_TUO;            
          elsif address_reg(0) /= address_reg(1)then
            state_st         <= DELETE_REQUEST_TUO;            
          end if;

        when WRITE_MODE_LENGTH =>
	      -- wait for header word being read 
          if OUT_FIFO32_S_Rd = '1' then
            state_st                 <= WRITE_ADDRESS;
          end if;
          
	    when WRITE_ADDRESS =>
		  -- wait for header word being read
		  -- and then jump to read or write data
          if OUT_FIFO32_S_Rd = '1' then
            case transfer_mode is
              when READ =>
                state_st <= DATA_READ;
              when WRITE =>
                state_st <= DATA_WRITE;              
            end case;
          end if;
          

        when DATA_READ =>
          if OUT_FIFO32_M_Wr = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_st <= WAIT_THREADS;
          end if;
          
        when DATA_WRITE =>
          -- TODO: What data do we write on error? TUO Data? ST Data? All
          -- zeros? Special Marker?
          -- TODO: What about forever stalling thread?
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_st <= WAIT_THREADS;
          end if;

          -- Lesson learned: error handling has to outvote everything else, so we
          -- have to put error handling last in the VHDL code.
          if  (error_detection_on_reg = '1') AND -- override error checks if runtime options says so
	          ( IN_FIFO32_S_Data(31 downto 0) /= IN_FIFO32_S_Data(63 downto 32) ) 
	      then
            state_st         <= COMPLETE_WRITE;
            -- Setting error signals is a TUO state machine task
            --error_typ_reg <= ERROR_TYP_DATA;
            --error_adr_reg <= std_logic_vector(unsigned(mode_length_reg(0)(23 downto 0)) - transfer_size+ unsigned(address_reg(0))-4);
          end if;
        -----------------
        -- Error handling
        -----------------
        when DELETE_REQUEST_TUO =>
          -- TODO: What about forever stalling thread?
          -- Handle threads seperately: they might have different request types and
          -- lengths, so we have to delete the request individually

          if (unsigned(IN_FIFO32_S_Fill((16 * (1 + 0))-1 downto 16 * 0)) > 0 and mode_length_reg(0)(31) = '1') or
             (unsigned(IN_FIFO32_M_Rem((16 * (1 + 0))-1 downto 16 * 0)) > 0 and mode_length_reg(0)(31) = '0')
          then
            transfer_size              := transfer_size-4;          
          end if;

          if transfer_size = 0 then
            state_st <= DELETE_REQUEST_ST;
            transfer_size := to_integer(unsigned(mode_length_reg(1)(23 downto 0)));
          end if;

        when DELETE_REQUEST_ST =>
          if (unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) > 0 and mode_length_reg(1)(31) = '1') or
             (unsigned(IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1)) > 0 and mode_length_reg(1)(31) = '0')
          then
            transfer_size              := transfer_size-4;          
          end if;

          if transfer_size = 0 then
            state_st <= REPORT_ERROR;
          end if;
          
        when COMPLETE_WRITE =>
          -- TODO: What data do we write on error? TUO Data? ST Data? All
          -- zeros? Special Marker?
          -- TODO: What about forever stalling thread?
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state_st <= REPORT_ERROR;
          end if;

	    when REPORT_ERROR =>
		  -- TUO state machine handles error signals 
          --ERROR_REQ <= '1';
          --ERROR_TYP <= error_typ_reg;
          --ERROR_ADR <= error_adr_reg;
          state_st <= WAIT_ERROR_ACK;
          
        when WAIT_ERROR_ACK =>
          if ERROR_ACK = '1' then
            state_st <= WAIT_THREADS;

            -- reset error interface
            -- TUO state machine handles error signals
            --ERROR_REQ <= '0';
            --ERROR_TYP <= ERROR_TYP_NONE;
            --ERROR_ADR <= (others => '0');
          end if;
          
        when others =>
          state_st <= WAIT_THREADS;
      end case;
    end if;
  end process;



--  checksum : process(clk, rst) is
--  begin
  read_data       <= OUT_FIFO32_M_Data;
  read_data_valid <= OUT_FIFO32_M_Wr;
  read_channel    <= (others => '0');

  write_data       <= INT_OUT_FIFO32_S_Data;
  write_data_valid <= OUT_FIFO32_S_Rd;
  write_channel    <= (others => '0');
--  end process;
  
end architecture;
