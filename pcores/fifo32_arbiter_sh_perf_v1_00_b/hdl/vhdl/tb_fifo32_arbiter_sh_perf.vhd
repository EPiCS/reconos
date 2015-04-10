library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity tb_fifo32_arbiter_sh_perf is
end entity;

architecture testbench of tb_fifo32_arbiter_sh_perf is
--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
  component fifo32
    generic (
      C_FIFO32_DEPTH : integer := 16
      );
    port (
      Rst           : in  std_logic;
      FIFO32_S_Clk  : in  std_logic;
      FIFO32_M_Clk  : in  std_logic;
      FIFO32_S_Data : out std_logic_vector(31 downto 0);
      FIFO32_M_Data : in  std_logic_vector(31 downto 0);
      FIFO32_S_Fill : out std_logic_vector(15 downto 0);
      FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
      FIFO32_S_Rd   : in  std_logic;
      FIFO32_M_Wr   : in  std_logic
      );
  end component;

component proc_control is
  generic (
    C_ENABLE_ILA          : integer := 0
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- Request FSL
    FSLA_Rst       : in  std_logic;
    FSLA_S_Read    : out std_logic;  -- Read signal, requiring next available input to be read
    FSLA_S_Data    : in  std_logic_vector(0 to 31);  -- Input data
    FSLA_S_Control : in  std_logic;  -- Control Bit, indicating the input data are control word
    FSLA_S_Exists  : in  std_logic;  -- Data Exist Bit, indicating data exist in the input FSL bus
    FSLA_M_Write   : out std_logic;  -- Write signal, enabling writing to output FSL bus
    FSLA_M_Data    : out std_logic_vector(0 to 31);  -- Output data
    FSLA_M_Control : out std_logic;  -- Control Bit, indicating the output data are contol word
    FSLA_M_Full    : in  std_logic;  -- Full Bit, indicating output FSL bus is full

    -- Reply FSL
    FSLB_Rst       : in  std_logic;
    FSLB_S_Read    : out std_logic;  -- Read signal, requiring next available input to be read
    FSLB_S_Data    : in  std_logic_vector(0 to 31);  -- Input data
    FSLB_S_Control : in  std_logic;  -- Control Bit, indicating the input data are control word
    FSLB_S_Exists  : in  std_logic;  -- Data Exist Bit, indicating data exist in the input FSL bus
    FSLB_M_Write   : out std_logic;  -- Write signal, enabling writing to output FSL bus
    FSLB_M_Data    : out std_logic_vector(0 to 31);  -- Output data
    FSLB_M_Control : out std_logic;  -- Control Bit, indicating the output data are contol word
    FSLB_M_Full    : in  std_logic;  -- Full Bit, indicating output FSL bus is full


    -- 16 individual reset outputs (mhs does not support vector indexing)
    reset0 : out std_logic;
    reset1 : out std_logic;
    reset2 : out std_logic;
    reset3 : out std_logic;
    reset4 : out std_logic;
    reset5 : out std_logic;
    reset6 : out std_logic;
    reset7 : out std_logic;
    reset8 : out std_logic;
    reset9 : out std_logic;
    resetA : out std_logic;
    resetB : out std_logic;
    resetC : out std_logic;
    resetD : out std_logic;
    resetE : out std_logic;
    resetF : out std_logic;

    -- MMU related ports
    page_fault : in  std_logic;
    fault_addr : in  std_logic_vector(31 downto 0);
    retry      : out std_logic;
    pgd        : out std_logic_vector(31 downto 0);
    tlb_hits   : in  std_logic_vector(31 downto 0);
    tlb_misses : in  std_logic_vector(31 downto 0);

    -- Fault injection related ports
    fault_sa0 : out std_logic_vector(31 downto 0);
    fault_sa1 : out std_logic_vector(31 downto 0);
    
    -- Arbiter run-time options
	ARB_RUNTIME_OPTIONS: out std_logic_vector(15 downto 0);

    -- Error signals from arbiter
    ERROR_REQ : in  std_logic;
    ERROR_ACK : out std_logic;
    ERROR_TYP : in  std_logic_vector(7 downto 0);
    ERROR_ADR : in  std_logic_vector(31 downto 0);

    -- ReconOS reset
    reconos_reset : out std_logic
    );
end component;
  
  component fifo32_arbiter_sh_perf
    generic (
      C_SLV_DWIDTH     : integer := 32;
      FIFO32_PORTS     : integer := 16;  --! 1 to 16 allowed
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
      clk : in std_logic;               -- separate clock for control logic

      -- Debug signals to ILA
      ila_signals : out std_logic_vector(3 downto 0)
      );
  end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant half_cycle : time := 5 ns;
  constant full_cycle : time := 2 * half_cycle;

  constant ARB_PORT_COUNT : integer                           := 16;
  constant HWT_COUNT      : integer range 1 to ARB_PORT_COUNT := 2;
  constant C_SLV_DWIDTH   : integer                           := 32;
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- FIFO32 interface between hardware and fifos.
  signal H2F_FIFO32_S_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Fill : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Rd   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  signal H2F_FIFO32_M_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Rem  : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Wr   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  -- FIFO32 interface between fifos and arbiter
  signal F2A_FIFO32_S_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Fill : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Rd   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  signal F2A_FIFO32_M_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Rem  : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Wr   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  -- FIFO32 interface between arbiter and memory controller.
  signal A2M_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_S_Rd   : std_logic;

  signal A2M_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_M_Wr   : std_logic;

  -- FIFO32 interface to proc_control
  signal FSLA_Rst       : std_logic;   
  signal FSLA_S_Read    : std_logic;
  signal FSLA_S_Data    : std_logic_vector(31 downto 0);
  signal FSLA_S_Control : std_logic;
  signal FSLA_S_Exists  : std_logic;
  signal FSLA_M_Write   : std_logic;
  signal FSLA_M_Data    : std_logic_vector(31 downto 0);
  signal FSLA_M_Control : std_logic;
  signal FSLA_M_Full    : std_logic;
                       
  signal FSLB_Rst       : std_logic;
  signal FSLB_S_Read    : std_logic;
  signal FSLB_S_Data    : std_logic_vector(31 downto 0);
  signal FSLB_S_Control : std_logic;
  signal FSLB_S_Exists  : std_logic;
  signal FSLB_M_Write   : std_logic;
  signal FSLB_M_Data    : std_logic_vector(31 downto 0);
  signal FSLB_M_Control : std_logic;
  signal FSLB_M_Full    : std_logic;


  
  -- Hardware Interface HWIF
  signal HWIF2DEC_Addr  : std_logic_vector(0 to 31);
  signal HWIF2DEC_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal HWIF2DEC_RdCE  : std_logic;
  signal HWIF2DEC_WrCE  : std_logic;
  signal DEC2HWIF_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal DEC2HWIF_RdAck : std_logic;
  signal DEC2HWIF_WrAck : std_logic;

  -- Run-time options
  signal RUNTIME_OPTIONS: std_logic_vector(15 downto 0);

  -- Error reporting
  signal ERROR_REQ : std_logic;
  signal ERROR_ACK : std_logic;
  signal ERROR_TYP : std_logic_vector(7 downto 0);
  signal ERROR_ADR : std_logic_vector(31 downto 0);

  -- memif interface signals
  type memif_out_array_t is array(natural range <>) of o_memif_t;
  type memif_in_array_t is array(natural range <>) of i_memif_t;
  signal H2F_MEMIF_OUT : memif_out_array_t(0 to ARB_PORT_COUNT-1);
  signal H2F_MEMIF_IN  : memif_in_array_t(0 to ARB_PORT_COUNT-1);

  signal A2M_MEMIF_OUT : o_memif_t;
  signal A2M_MEMIF_IN  : i_memif_t;
  -- Misc
  signal Rst           : std_logic;
  signal clk           : std_logic;

  signal test_desc : string(1 to 16) := "None            ";

  -- This signal gives a human readable description of what the testbench is
  -- currently testing. Implemented as a signal, because Xilinx ISim can't
  -- track variables. 
  type tb_phase_t is (READ1, WRITE1, READ128, WRITE128, REQUEST_ERROR, LENGTH_ERROR, DATA_ERROR, DONE);
  type tb_phase_vector_t is array  (natural range<>) of tb_phase_t;
  signal tb_phase : tb_phase_vector_t(0 to HWT_COUNT-1);


  signal transfer_size_sig    : natural range 0 to 2**24;

begin  -- of architecture -------------------------------------------------------

  
  fifos : for i in 0 to HWT_COUNT-1 generate

    -- for reading a word of data in hwt process
    signal data : std_logic_vector(31 downto 0) := X"AAAAAAAA";
    
  begin

    memif_setup (
      H2F_MEMIF_IN(i),
      H2F_MEMIF_OUT(i),
      H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
      H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
      H2F_FIFO32_S_Rd(i),
      H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
      H2F_FIFO32_M_Rem (16*(i+1)-1 downto 16*i),
      H2F_FIFO32_M_Wr(i)
      );

    master_fifo32_i : fifo32
      generic map(
        C_FIFO32_DEPTH => 16
        )
      port map(
        Rst           => rst,
        FIFO32_S_Clk  => clk,
        FIFO32_M_Clk  => clk,
        FIFO32_S_Data => F2A_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
        FIFO32_M_Data => H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
        FIFO32_S_Fill => F2A_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
        FIFO32_M_Rem  => H2F_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
        FIFO32_S_Rd   => F2A_FIFO32_S_Rd(i),
        FIFO32_M_Wr   => H2F_FIFO32_M_Wr(i)
        );

    slave_fifo32_i : fifo32
      generic map(
        C_FIFO32_DEPTH => 16
        )
      port map(
        Rst           => rst,
        FIFO32_S_Clk  => clk,
        FIFO32_M_Clk  => clk,
        FIFO32_S_Data => H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
        FIFO32_M_Data => F2A_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
        FIFO32_S_Fill => H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
        FIFO32_M_Rem  => F2A_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
        FIFO32_S_Rd   => H2F_FIFO32_S_Rd(i),
        FIFO32_M_Wr   => F2A_FIFO32_M_Wr(i)
        );


    hwt_process : process(clk, H2F_MEMIF_IN)
      is
      --! @brief First of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned      
      variable seed1 : positive := 1; --i+1;
      --! @brief Second of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned
      variable seed2 : positive := 2; --i+i+1;


      --! @brief This function generates a random unsigned number
      --! @details This is an impure function, because it uses the global
      --!          variables seed1 and seed2, although this variables are not
      --!          specified in its interface.
      --! @param[in] min_value This gives the lower limit of the random number 
      --! @param[in] max_value This gives the upper limit of the random number
      --! @param[in] bitwidth The unsigend type is based on standard_logic_vector,
      --!            so we need to know what width in bits the result shall have.
      --! @return A random unsigned number of type unsigned with a width of bitwidth.
      impure function get_rand_unsigned(constant min_value : natural;
                                        constant max_value : natural;
                                        constant bitwidth  : positive)
        return unsigned is
        variable rand_int : integer := 0;
        -- Variable that holds the result of the uniform function
        variable rand     : real;
      begin
        uniform(seed1, seed2, rand);
        rand_int := integer(TRUNC(rand*real(max_value+1-min_value)))+min_value;
        return to_unsigned(rand_int, bitwidth);
      end function;

      type state_t is (SET_PAUSE, PAUSE, WRITE_HEADER, WRITE_DATA, READ_DATA, END_STATE);
      variable state : state_t;

      type MODE is (READ, WRITE);
      type MODE_VECTOR is array (natural range<>) of MODE;
      type LENGTH_VECTOR is array (natural range<>) of natural range 1 to 2**16-1;
      type ADDRESS_VECTOR is array (natural range<>) of std_logic_vector(31 downto 0);
      
      constant MAX_PACKETS  : natural                          := 7;
     
      variable PAUSE_LIST   : LENGTH_VECTOR(1 to MAX_PACKETS*2)  := (
        20, 20, 20, 20,  -- TUO pauses
        20, 20, 20,  
        20, 20, 20, 20,  -- ST  pauses
        20, 20, 20 );
      
      variable MODE_LIST    : MODE_VECTOR(1 to MAX_PACKETS*2)    := (
         READ, WRITE, READ, WRITE, -- TUO, all good
         WRITE,READ, WRITE,                     -- TUO, intentional discrepancy to ST
         READ, WRITE, READ, WRITE, -- ST, equal to TUO
         READ, READ, WRITE);                    -- ST,  intentional discrepancy to ST
         
      variable LENGTH_LIST  : LENGTH_VECTOR(1 to MAX_PACKETS*2)  := (
        4, 4, 128, 128, -- TUO lengths
        128, 128, 128,
        4, 4, 128, 128, -- ST  lengths
        128, 124, 128);
      
      variable ADDRESS_LIST : ADDRESS_VECTOR(1 to MAX_PACKETS*2) := (
        X"DEADDEAD", X"DEADDEAD", X"AFFEAFFE", X"AFFEAFFE", -- TUO addresses
        X"BEEFBEEF",X"BEEFBEEF", X"BEEFBEEF",
        X"DEADDEAD", X"DEADDEAD", X"AFFEAFFE", X"AFFEAFFE", -- ST  addresses
        X"BEEFBEEF", X"BEEFBEEF", X"BEEFBEEF");

      variable packet_nr     : natural := 0;
      variable pause_counter : natural := 0;
      variable length_counter: natural := 0;
      variable done          : boolean := false;
      
    begin
      if rst = '1' then
        state := SET_PAUSE;
        -- init interface 
        memif_reset(H2F_MEMIF_OUT(i));
        done  := false;
        data  <= std_logic_vector(get_rand_unsigned(0, 2**16-1, 32));
      elsif rising_edge(clk) then
        case state is
          when SET_PAUSE =>
            packet_nr := packet_nr + 1;
            tb_phase(i) <= tb_phase_t'val(packet_nr-1);
            if packet_nr > MAX_PACKETS then
              state := END_STATE;
            else
              pause_counter := PAUSE_LIST((MAX_PACKETS*i)+packet_nr);
              state         := PAUSE;
            end if;
            
          when PAUSE =>
            pause_counter    := pause_counter - 1;
            if pause_counter <= 0 then
              state := WRITE_HEADER;
            end if;
            
          when WRITE_HEADER =>
            case MODE_LIST((MAX_PACKETS*i)+packet_nr) is
              when READ =>
                memif_read_request(
                  H2F_MEMIF_IN(i),
                  H2F_MEMIF_OUT(i),
                  ADDRESS_LIST((MAX_PACKETS*i)+packet_nr),  -- address
                  std_logic_vector(to_unsigned(LENGTH_LIST((MAX_PACKETS*i)+packet_nr), 24)),  -- length
                  done
                  );
                if done then
                  length_counter := LENGTH_LIST((MAX_PACKETS*i)+packet_nr);
                  state := READ_DATA;
                end if;
              when WRITE =>
                memif_write_request(
                  H2F_MEMIF_IN(i),
                  H2F_MEMIF_OUT(i),
                  ADDRESS_LIST((MAX_PACKETS*i)+packet_nr),  -- address
                  std_logic_vector(to_unsigned(LENGTH_LIST((MAX_PACKETS*i)+packet_nr), 24)),  -- length
                  done
                  );
                if done then
                  length_counter := LENGTH_LIST((MAX_PACKETS*i)+packet_nr);
                  state := WRITE_DATA;
                end if;
            end case;

          when WRITE_DATA =>
            data <= std_logic_vector(get_rand_unsigned(0, 2**16-1, 32));
            if i = 0 and length_counter = 8 and packet_nr = 7 then
              data <= X"DEADBEEF";
            end if;
            memif_fifo_push (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data,                     -- data
              done
              );
            if done then
              length_counter := length_counter -4;
            end if;
            if length_counter = 0 then
              state := SET_PAUSE;
            end if;
            
          when READ_DATA =>
            memif_fifo_pull (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data,                     -- data
              done
              );
            if done then
              length_counter := length_counter -4;
            end if;
            if length_counter = 0 then
              state := SET_PAUSE;
            end if;
            
          when END_STATE =>
            report "Packet generation done!" severity note;
        end case;
      end if;
    end process;

  end generate;

-- Instantiate proc_control, which communicates error data to the main system
  FSLA_M_Full <= '0'; -- let proc_control think we always accept incoming data
proc_control_i: proc_control 
  port map(
    clk => clk,
    rst => rst,

    -- Request FSL
    FSLA_Rst       => FSLA_Rst,      
    FSLA_S_Read    => FSLA_S_Read,   
    FSLA_S_Data    => FSLA_S_Data,   
    FSLA_S_Control => FSLA_S_Control,
    FSLA_S_Exists  => FSLA_S_Exists, 
    FSLA_M_Write   => FSLA_M_Write,  
    FSLA_M_Data    => FSLA_M_Data,   
    FSLA_M_Control => FSLA_M_Control,
    FSLA_M_Full    => FSLA_M_Full,   
                                     
    -- Reply FSL                     
    FSLB_Rst       => FSLB_Rst,      
    FSLB_S_Read    => FSLB_S_Read,   
    FSLB_S_Data    => FSLB_S_Data,   
    FSLB_S_Control => FSLB_S_Control,
    FSLB_S_Exists  => FSLB_S_Exists, 
    FSLB_M_Write   => FSLB_M_Write,  
    FSLB_M_Data    => FSLB_M_Data,   
    FSLB_M_Control => FSLB_M_Control,
    FSLB_M_Full    => FSLB_M_Full,   


    -- 16 individual reset outputs (mhs does not support vector indexing)
    reset0 => open,
    reset1 => open,
    reset2 => open,
    reset3 => open,
    reset4 => open,
    reset5 => open,
    reset6 => open,
    reset7 => open,
    reset8 => open,
    reset9 => open,
    resetA => open,
    resetB => open,
    resetC => open,
    resetD => open,
    resetE => open,
    resetF => open,

    -- MMU related ports
    page_fault => '0',
    fault_addr => (others =>'0'),
    retry      => open,
    pgd        => open,
    tlb_hits   => (others =>'0'),
    tlb_misses => (others =>'0'),

    -- Fault injection related ports
    fault_sa0 => open,
    fault_sa1 => open,

    -- Arbiter run-time options
	ARB_RUNTIME_OPTIONS => RUNTIME_OPTIONS,

    -- Error signals from arbiter
    ERROR_REQ  => ERROR_REQ,
    ERROR_ACK  => ERROR_ACK,
    ERROR_TYP  => ERROR_TYP,
    ERROR_ADR  => ERROR_ADR,

    -- ReconOS reset
    reconos_reset => open
    );
  
  fifo32_arbiter_sh_perf_i : fifo32_arbiter_sh_perf
    generic map(
      FIFO32_PORTS     => ARB_PORT_COUNT,  -- setting it to something else than
                                           -- 16 breaks it at the moment:
                                           -- automate address map generation
                                           -- for HWIF!
      ARBITRATION_ALGO => 0
      )
    port map(
      -- Multiple FIFO32 Inputs
      IN_FIFO32_S_Data_A => F2A_FIFO32_S_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_S_Fill_A => F2A_FIFO32_S_Fill(16*(0+1)-1 downto 16*0),
      IN_FIFO32_S_Rd_A   => F2A_FIFO32_S_Rd(0),

      IN_FIFO32_M_Data_A => F2A_FIFO32_M_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_M_Rem_A  => F2A_FIFO32_M_Rem(16*(0+1)-1 downto 16*0),
      IN_FIFO32_M_Wr_A   => F2A_FIFO32_M_Wr(0),

      IN_FIFO32_S_Data_B => F2A_FIFO32_S_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_S_Fill_B => F2A_FIFO32_S_Fill(16*(1+1)-1 downto 16*1),
      IN_FIFO32_S_Rd_B   => F2A_FIFO32_S_Rd(1),

      IN_FIFO32_M_Data_B => F2A_FIFO32_M_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_M_Rem_B  => F2A_FIFO32_M_Rem(16*(1+1)-1 downto 16*1),
      IN_FIFO32_M_Wr_B   => F2A_FIFO32_M_Wr(1),

      IN_FIFO32_S_Data_C => F2A_FIFO32_S_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_S_Fill_C => F2A_FIFO32_S_Fill(16*(2+1)-1 downto 16*2),
      IN_FIFO32_S_Rd_C   => F2A_FIFO32_S_Rd(2),

      IN_FIFO32_M_Data_C => F2A_FIFO32_M_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_M_Rem_C  => F2A_FIFO32_M_Rem(16*(2+1)-1 downto 16*2),
      IN_FIFO32_M_Wr_C   => F2A_FIFO32_M_Wr(2),

      IN_FIFO32_S_Data_D => F2A_FIFO32_S_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_S_Fill_D => F2A_FIFO32_S_Fill(16*(3+1)-1 downto 16*3),
      IN_FIFO32_S_Rd_D   => F2A_FIFO32_S_Rd(3),

      IN_FIFO32_M_Data_D => F2A_FIFO32_M_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_M_Rem_D  => F2A_FIFO32_M_Rem(16*(3+1)-1 downto 16*3),
      IN_FIFO32_M_Wr_D   => F2A_FIFO32_M_Wr(3),

      IN_FIFO32_S_Data_E => F2A_FIFO32_S_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_S_Fill_E => F2A_FIFO32_S_Fill(16*(4+1)-1 downto 16*4),
      IN_FIFO32_S_Rd_E   => F2A_FIFO32_S_Rd(4),

      IN_FIFO32_M_Data_E => F2A_FIFO32_M_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_M_Rem_E  => F2A_FIFO32_M_Rem(16*(4+1)-1 downto 16*4),
      IN_FIFO32_M_Wr_E   => F2A_FIFO32_M_Wr(4),

      IN_FIFO32_S_Data_F => F2A_FIFO32_S_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_S_Fill_F => F2A_FIFO32_S_Fill(16*(5+1)-1 downto 16*5),
      IN_FIFO32_S_Rd_F   => F2A_FIFO32_S_Rd(5),

      IN_FIFO32_M_Data_F => F2A_FIFO32_M_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_M_Rem_F  => F2A_FIFO32_M_Rem(16*(5+1)-1 downto 16*5),
      IN_FIFO32_M_Wr_F   => F2A_FIFO32_M_Wr(5),

      IN_FIFO32_S_Data_G => F2A_FIFO32_S_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_S_Fill_G => F2A_FIFO32_S_Fill(16*(6+1)-1 downto 16*6),
      IN_FIFO32_S_Rd_G   => F2A_FIFO32_S_Rd(6),

      IN_FIFO32_M_Data_G => F2A_FIFO32_M_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_M_Rem_G  => F2A_FIFO32_M_Rem(16*(6+1)-1 downto 16*6),
      IN_FIFO32_M_Wr_G   => F2A_FIFO32_M_Wr(6),

      IN_FIFO32_S_Data_H => F2A_FIFO32_S_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_S_Fill_H => F2A_FIFO32_S_Fill(16*(7+1)-1 downto 16*7),
      IN_FIFO32_S_Rd_H   => F2A_FIFO32_S_Rd(7),

      IN_FIFO32_M_Data_H => F2A_FIFO32_M_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_M_Rem_H  => F2A_FIFO32_M_Rem(16*(7+1)-1 downto 16*7),
      IN_FIFO32_M_Wr_H   => F2A_FIFO32_M_Wr(7),

      IN_FIFO32_S_Data_I => F2A_FIFO32_S_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_S_Fill_I => F2A_FIFO32_S_Fill(16*(8+1)-1 downto 16*8),
      IN_FIFO32_S_Rd_I   => F2A_FIFO32_S_Rd(8),

      IN_FIFO32_M_Data_I => F2A_FIFO32_M_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_M_Rem_I  => F2A_FIFO32_M_Rem(16*(8+1)-1 downto 16*8),
      IN_FIFO32_M_Wr_I   => F2A_FIFO32_M_Wr(8),

      IN_FIFO32_S_Data_J => F2A_FIFO32_S_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_S_Fill_J => F2A_FIFO32_S_Fill(16*(9+1)-1 downto 16*9),
      IN_FIFO32_S_Rd_J   => F2A_FIFO32_S_Rd(9),

      IN_FIFO32_M_Data_J => F2A_FIFO32_M_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_M_Rem_J  => F2A_FIFO32_M_Rem(16*(9+1)-1 downto 16*9),
      IN_FIFO32_M_Wr_J   => F2A_FIFO32_M_Wr(9),

      IN_FIFO32_S_Data_K => F2A_FIFO32_S_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_S_Fill_K => F2A_FIFO32_S_Fill(16*(10+1)-1 downto 16*10),
      IN_FIFO32_S_Rd_K   => F2A_FIFO32_S_Rd(10),

      IN_FIFO32_M_Data_K => F2A_FIFO32_M_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_M_Rem_K  => F2A_FIFO32_M_Rem(16*(10+1)-1 downto 16*10),
      IN_FIFO32_M_Wr_K   => F2A_FIFO32_M_Wr(10),

      IN_FIFO32_S_Data_L => F2A_FIFO32_S_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_S_Fill_L => F2A_FIFO32_S_Fill(16*(11+1)-1 downto 16*11),
      IN_FIFO32_S_Rd_L   => F2A_FIFO32_S_Rd(11),

      IN_FIFO32_M_Data_L => F2A_FIFO32_M_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_M_Rem_L  => F2A_FIFO32_M_Rem(16*(11+1)-1 downto 16*11),
      IN_FIFO32_M_Wr_L   => F2A_FIFO32_M_Wr(11),

      IN_FIFO32_S_Data_M => F2A_FIFO32_S_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_S_Fill_M => F2A_FIFO32_S_Fill(16*(12+1)-1 downto 16*12),
      IN_FIFO32_S_Rd_M   => F2A_FIFO32_S_Rd(12),

      IN_FIFO32_M_Data_M => F2A_FIFO32_M_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_M_Rem_M  => F2A_FIFO32_M_Rem(16*(12+1)-1 downto 16*12),
      IN_FIFO32_M_Wr_M   => F2A_FIFO32_M_Wr(12),

      IN_FIFO32_S_Data_N => F2A_FIFO32_S_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_S_Fill_N => F2A_FIFO32_S_Fill(16*(13+1)-1 downto 16*13),
      IN_FIFO32_S_Rd_N   => F2A_FIFO32_S_Rd(13),

      IN_FIFO32_M_Data_N => F2A_FIFO32_M_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_M_Rem_N  => F2A_FIFO32_M_Rem(16*(13+1)-1 downto 16*13),
      IN_FIFO32_M_Wr_N   => F2A_FIFO32_M_Wr(13),

      IN_FIFO32_S_Data_O => F2A_FIFO32_S_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_S_Fill_O => F2A_FIFO32_S_Fill(16*(14+1)-1 downto 16*14),
      IN_FIFO32_S_Rd_O   => F2A_FIFO32_S_Rd(14),

      IN_FIFO32_M_Data_O => F2A_FIFO32_M_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_M_Rem_O  => F2A_FIFO32_M_Rem(16*(14+1)-1 downto 16*14),
      IN_FIFO32_M_Wr_O   => F2A_FIFO32_M_Wr(14),

      IN_FIFO32_S_Data_P => F2A_FIFO32_S_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_S_Fill_P => F2A_FIFO32_S_Fill(16*(15+1)-1 downto 16*15),
      IN_FIFO32_S_Rd_P   => F2A_FIFO32_S_Rd(15),

      IN_FIFO32_M_Data_P => F2A_FIFO32_M_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_M_Rem_P  => F2A_FIFO32_M_Rem(16*(15+1)-1 downto 16*15),
      IN_FIFO32_M_Wr_P   => F2A_FIFO32_M_Wr(15),

      -- Single FIFO32 Output
      OUT_FIFO32_S_Data => A2M_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => A2M_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => A2M_FIFO32_S_Rd,

      OUT_FIFO32_M_Data => A2M_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => A2M_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => A2M_FIFO32_M_Wr,

      -- Hardware Interface HWIF
      HWIF2DEC_Addr  => HWIF2DEC_Addr,
      HWIF2DEC_Data  => HWIF2DEC_Data,
      HWIF2DEC_RdCE  => HWIF2DEC_RdCE,
      HWIF2DEC_WrCE  => HWIF2DEC_WrCE,
      DEC2HWIF_Data  => DEC2HWIF_Data,
      DEC2HWIF_RdAck => DEC2HWIF_RdAck,
      DEC2HWIF_WrAck => DEC2HWIF_WrAck,

	  -- Run-time options	  
	  RUNTIME_OPTIONS => RUNTIME_OPTIONS,
	  
      -- Error reporting
      ERROR_REQ => ERROR_REQ,
      ERROR_ACK => ERROR_ACK,
      ERROR_TYP => ERROR_TYP,
      ERROR_ADR => ERROR_ADR,

      -- Misc
      Rst => rst,
      clk => clk,

      -- Debug signals to ILA
      ila_signals => open
      );

  memif_setup (
    A2M_MEMIF_IN,
    A2M_MEMIF_OUT,
    A2M_FIFO32_S_Data,
    A2M_FIFO32_S_Fill,
    A2M_FIFO32_S_Rd,
    A2M_FIFO32_M_Data,
    A2M_FIFO32_M_Rem,
    A2M_FIFO32_M_Wr
    );

  mem_ctrl : process(clk, rst, a2m_memif_in)
    is
    type FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;

    type mode_t is (READ, WRITE);
    variable transfer_mode    : mode_t := READ;
    variable transfer_size    : natural range 0 to 2**24;
    variable transfer_address : std_logic_vector(31 downto 0);
  begin
    if rst = '1' then
      state                := IDLE;
      transfer_mode        := READ;
      a2m_memif_out.s_rd   <= '0';
      a2m_memif_out.m_wr   <= '0';
      a2m_memif_out.m_data <= X"00000000";
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state              := state;
      a2m_memif_out.s_rd <= a2m_memif_out.s_rd;
      a2m_memif_out.m_wr <= a2m_memif_out.m_wr;
      transfer_mode      := transfer_mode;
      transfer_size      := transfer_size;
      case state is
        
        when IDLE =>
          a2m_memif_out.s_rd <= '0';
          a2m_memif_out.m_wr <= '0';
          if to_integer(unsigned(a2m_memif_in.s_fill)) > 1 then
            state              := MODE_LENGTH;
            a2m_memif_out.s_rd <= '1';
          end if;
          
          
        when MODE_LENGTH =>
          state := ADDRESS;
          case a2m_memif_in.s_data(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          transfer_size := to_integer(unsigned(a2m_memif_in.s_data(23 downto 0)));
          
        when ADDRESS =>
          transfer_address := a2m_memif_in.s_data;
          case transfer_mode is
            when READ =>
              state              := DATA_READ;
              a2m_memif_out.s_rd <= '0';
              a2m_memif_out.m_wr <= '1';
              a2m_memif_out.m_data <= transfer_address;
            when WRITE =>
              state := DATA_WRITE;
              a2m_memif_out.s_rd <= '0';
              --transfer_size := transfer_size - 4;
            when others => null;
          end case;
          
        when DATA_WRITE =>
          if (a2m_memif_in.s_fill = X"0001" and transfer_size /= 4) or
             (a2m_memif_in.s_fill = X"0000") 
          then
            a2m_memif_out.s_rd <= '0';
          else
	        a2m_memif_out.s_rd <= '1';
            transfer_size := transfer_size - 4;
          end if;
          
          if transfer_size = 0 then
            state              := IDLE;
            --a2m_memif_out.s_rd <= '0';
          end if;
          
        when DATA_READ =>
          -- following line determines read data
          a2m_memif_out.m_data <= transfer_address;
          if a2m_memif_in.m_remainder = X"0001" or
             a2m_memif_in.m_remainder = X"0000" 
          then
			a2m_memif_out.m_wr <= '0';
          else
            a2m_memif_out.m_wr <= '1';
            transfer_size      := transfer_size - 4;	          
          end if;

          if transfer_size = 0 then
            state                := IDLE;
            a2m_memif_out.m_wr   <= '0';
            a2m_memif_out.m_data <= X"00000000";
          end if;
          
        when others =>
          state := IDLE;
      end case;
      transfer_size_sig <= transfer_size;
    end if;
  end process;

  hwif_proc : process is
    procedure hwif_write(addr, data : std_logic_vector(31 downto 0))
    is

    begin
      HWIF2DEC_Addr <= addr;
      HWIF2DEC_Data <= data;
      HWIF2DEC_WrCE <= '1';
      wait for full_cycle;
      HWIF2DEC_Addr <= (others => '0');
      HWIF2DEC_Data <= (others => '0');
      HWIF2DEC_WrCE <= '0';
      wait for full_cycle;
    end procedure;
  begin
    -- set Defaults
    HWIF2DEC_Addr <= (others => '0');
    HWIF2DEC_Data <= (others => '0');
    HWIF2DEC_RdCE <= '0';
    HWIF2DEC_WrCE <= '0';
    wait for 200 ns;

    test_desc <= "enable chksum rd";
    hwif_write(X"00000070", X"FFFFFFFF");

    test_desc <= "enable chksum wr";
    hwif_write(X"000000F0", X"FFFFFFFF");
    wait for 50*full_cycle;

    test_desc <= "reset  chksum   ";
    hwif_write(X"000000EC", X"FFFFFFFF");
    wait for 10*full_cycle;

    test_desc <= "enable chksum   ";
    hwif_write(X"000000F0", X"FFFFFFFF");
    wait for 50*full_cycle;
    test_desc <= "end of testbench";
    wait;
  end process;

  reset : process is
  begin
    rst <= '1';
    wait for 5 * full_cycle;
    rst <= '0';
    wait;
  end process;

-- All clocks are the same.
  clock : process is
  begin
    clk <= '1';
    wait for half_cycle;
    clk <= '0';
    wait for half_cycle;
  end process;


end architecture;

