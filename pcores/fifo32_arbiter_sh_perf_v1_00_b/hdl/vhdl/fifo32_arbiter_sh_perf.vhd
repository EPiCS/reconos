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

--library fifo32_v1_00_b;
--use fifo32_v1_00_b.fifo32;

entity fifo32_arbiter_sh_perf is
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
-- 		HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
-- 		HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
-- 		HWIF2DEC_RdCE  : in  std_logic;
-- 		HWIF2DEC_WrCE  : in  std_logic;
-- 		DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
-- 		DEC2HWIF_RdAck : out std_logic;
-- 		DEC2HWIF_WrAck : out std_logic;

    	-- Run-time options
    	RUNTIME_OPTIONS : in std_logic_vector(59 downto 0 );
    	
		-- Error reporting
		ERROR_REQ : out std_logic;
		ERROR_ACK : in  std_logic;
		ERROR_PRT : out std_logic_vector(7 downto 0);
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
architecture behavioural of fifo32_arbiter_sh_perf is
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

  -- Connection between arbiter and shadowing system
  signal INT_FIFO32_S_Data          : std_logic_vector(31 downto 0);
  signal INT_FIFO32_S_Fill          : std_logic_vector(15 downto 0);
  signal INT_FIFO32_S_Rd            : std_logic;

  signal INT_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal INT_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal INT_FIFO32_M_Wr   : std_logic;
    
  signal HWT_INDEX : unsigned(clog2(FIFO32_PORTS)-1 downto 0);
  signal START_OF_NEW_PACKET : std_logic;
  
  type ila_signals_t is array (1 downto 0) of std_logic_vector(130 downto 0);
  signal INT_ILA_SIGNALS: ila_signals_t;
begin  -- of architecture -------------------------------------------------------


	ila_signals <= INT_ILA_SIGNALS(0) when RUNTIME_OPTIONS(0) = '1' else
					INT_ILA_SIGNALS(1);

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

--------------------------------------------------------------------------------
-- Instantiation
--------------------------------------------------------------------------------

--! First stage: arbiter select a HWT that may transfer data.
my_fifo32_arbiter: entity work.fifo32_arbiter 
  generic map(
    C_SLV_DWIDTH     => C_SLV_DWIDTH,
    FIFO32_PORTS     => FIFO32_PORTS,
    ARBITRATION_ALGO => ARBITRATION_ALGO
    )
  port map(
    -- Multiple FIFO32 Inputs
    IN_FIFO32_S_Data => IN_FIFO32_S_Data,
    IN_FIFO32_S_Fill => IN_FIFO32_S_Fill,
    IN_FIFO32_S_Rd => IN_FIFO32_S_Rd,

    IN_FIFO32_M_Data => IN_FIFO32_M_Data,
    IN_FIFO32_M_Rem => IN_FIFO32_M_Rem,
    IN_FIFO32_M_Wr => IN_FIFO32_M_Wr,

    -- Single FIFO32 Output
    OUT_FIFO32_S_Data => INT_FIFO32_S_Data,
    OUT_FIFO32_S_Fill => INT_FIFO32_S_Fill,
    OUT_FIFO32_S_Rd => INT_FIFO32_S_Rd,

    OUT_FIFO32_M_Data => INT_FIFO32_M_Data,
    OUT_FIFO32_M_Rem => INT_FIFO32_M_Rem,
    OUT_FIFO32_M_Wr => INT_FIFO32_M_Wr,

    -- Which HWT is currently selected?
    HWT_INDEX => HWT_INDEX,
    START_OF_NEW_PACKET => START_OF_NEW_PACKET,
    -- Misc
    Rst => Rst,
    clk => Clk,

    -- Debug signals to ILA
    ila_signals => INT_ILA_SIGNALS(0)
    );


--! Second stage checks if shadowing is set for that thread and performs memory
--! access comparison between TUO and ST.
my_shadowing : entity work.shadowing 
		generic map (
		C_SLV_DWIDTH     => C_SLV_DWIDTH,
		FIFO32_PORTS     => FIFO32_PORTS, -- 1 to 16 allowed

		SHADOW_UNITS     => 1,
		FIFO_DEPTH       => 4096)
		port    map (
		IN_FIFO32_S_Data => INT_FIFO32_S_Data,
		IN_FIFO32_S_Fill => INT_FIFO32_S_Fill,
		IN_FIFO32_S_Rd   => INT_FIFO32_S_Rd,
		
		IN_FIFO32_M_Data => INT_FIFO32_M_Data,
		IN_FIFO32_M_Rem  => INT_FIFO32_M_Rem,
		IN_FIFO32_M_Wr   => INT_FIFO32_M_Wr,
		
		OUT_FIFO32_S_Data => OUT_FIFO32_S_Data,
		OUT_FIFO32_S_Fill => OUT_FIFO32_S_Fill,
		OUT_FIFO32_S_Rd  => OUT_FIFO32_S_Rd,
		
		OUT_FIFO32_M_Data => OUT_FIFO32_M_Data,
		OUT_FIFO32_M_Rem => OUT_FIFO32_M_Rem,
		OUT_FIFO32_M_Wr  => OUT_FIFO32_M_Wr,
		
		HWT_INDEX        => HWT_INDEX,
		START_OF_NEW_PACKET => START_OF_NEW_PACKET,
		RUNTIME_OPTIONS  => RUNTIME_OPTIONS(3 downto 1),
		SHADOWING_OPTIONS => RUNTIME_OPTIONS(59 downto 4),
		
		ERROR_PRT		 => ERROR_PRT,
		ERROR_REQ        => ERROR_REQ,
		ERROR_ACK        => ERROR_ACK,
		ERROR_TYP        => ERROR_TYP,
		ERROR_ADR        => ERROR_ADR,
		
		Rst              => Rst,    
		clk              => clk,     -- separate clock for control logic

		ila_signals      => INT_ILA_SIGNALS(1));

end architecture;
