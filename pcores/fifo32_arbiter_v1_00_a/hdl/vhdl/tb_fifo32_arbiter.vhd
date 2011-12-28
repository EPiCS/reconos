library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity tb_fifo32_arbiter is
end entity;

architecture testbench of tb_fifo32_arbiter is
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

  component fifo32_arbiter
    generic (
      FIFO32_PORTS     : integer := 16;  --! 1 to 16 allowed
      ARBITRATION_ALGO : integer := 0  --! 0= Round Robin, others not available atm.
      );
    port (
      -- Multiple FIFO32 Inputs
      IN_FIFO32_S_Clk_A  : out std_logic;
      IN_FIFO32_S_Data_A : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_A : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_A   : out std_logic;

      IN_FIFO32_M_Clk_A  : out std_logic;
      IN_FIFO32_M_Data_A : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_A  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_A   : out std_logic;

      IN_FIFO32_S_Clk_B  : out std_logic;
      IN_FIFO32_S_Data_B : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_B : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_B   : out std_logic;

      IN_FIFO32_M_Clk_B  : out std_logic;
      IN_FIFO32_M_Data_B : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_B  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_B   : out std_logic;

      IN_FIFO32_S_Clk_C  : out std_logic;
      IN_FIFO32_S_Data_C : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_C : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_C   : out std_logic;

      IN_FIFO32_M_Clk_C  : out std_logic;
      IN_FIFO32_M_Data_C : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_C  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_C   : out std_logic;

      IN_FIFO32_S_Clk_D  : out std_logic;
      IN_FIFO32_S_Data_D : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_D : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_D   : out std_logic;

      IN_FIFO32_M_Clk_D  : out std_logic;
      IN_FIFO32_M_Data_D : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_D  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_D   : out std_logic;

      IN_FIFO32_S_Clk_E  : out std_logic;
      IN_FIFO32_S_Data_E : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_E : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_E   : out std_logic;

      IN_FIFO32_M_Clk_E  : out std_logic;
      IN_FIFO32_M_Data_E : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_E  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_E   : out std_logic;

      IN_FIFO32_S_Clk_F  : out std_logic;
      IN_FIFO32_S_Data_F : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_F : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_F   : out std_logic;

      IN_FIFO32_M_Clk_F  : out std_logic;
      IN_FIFO32_M_Data_F : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_F  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_F   : out std_logic;

      IN_FIFO32_S_Clk_G  : out std_logic;
      IN_FIFO32_S_Data_G : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_G : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_G   : out std_logic;

      IN_FIFO32_M_Clk_G  : out std_logic;
      IN_FIFO32_M_Data_G : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_G  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_G   : out std_logic;

      IN_FIFO32_S_Clk_H  : out std_logic;
      IN_FIFO32_S_Data_H : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_H : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_H   : out std_logic;

      IN_FIFO32_M_Clk_H  : out std_logic;
      IN_FIFO32_M_Data_H : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_H  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_H   : out std_logic;

      IN_FIFO32_S_Clk_I  : out std_logic;
      IN_FIFO32_S_Data_I : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_I : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_I   : out std_logic;

      IN_FIFO32_M_Clk_I  : out std_logic;
      IN_FIFO32_M_Data_I : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_I  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_I   : out std_logic;

      IN_FIFO32_S_Clk_J  : out std_logic;
      IN_FIFO32_S_Data_J : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_J : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_J   : out std_logic;

      IN_FIFO32_M_Clk_J  : out std_logic;
      IN_FIFO32_M_Data_J : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_J  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_J   : out std_logic;

      IN_FIFO32_S_Clk_K  : out std_logic;
      IN_FIFO32_S_Data_K : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_K : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_K   : out std_logic;

      IN_FIFO32_M_Clk_K  : out std_logic;
      IN_FIFO32_M_Data_K : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_K  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_K   : out std_logic;

      IN_FIFO32_S_Clk_L  : out std_logic;
      IN_FIFO32_S_Data_L : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_L : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_L   : out std_logic;

      IN_FIFO32_M_Clk_L  : out std_logic;
      IN_FIFO32_M_Data_L : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_L  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_L   : out std_logic;

      IN_FIFO32_S_Clk_M  : out std_logic;
      IN_FIFO32_S_Data_M : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_M : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_M   : out std_logic;

      IN_FIFO32_M_Clk_M  : out std_logic;
      IN_FIFO32_M_Data_M : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_M  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_M   : out std_logic;

      IN_FIFO32_S_Clk_N  : out std_logic;
      IN_FIFO32_S_Data_N : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_N : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_N   : out std_logic;

      IN_FIFO32_M_Clk_N  : out std_logic;
      IN_FIFO32_M_Data_N : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_N  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_N   : out std_logic;

      IN_FIFO32_S_Clk_O  : out std_logic;
      IN_FIFO32_S_Data_O : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_O : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_O   : out std_logic;

      IN_FIFO32_M_Clk_O  : out std_logic;
      IN_FIFO32_M_Data_O : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_O  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_O   : out std_logic;

      IN_FIFO32_S_Clk_P  : out std_logic;
      IN_FIFO32_S_Data_P : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill_P : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd_P   : out std_logic;

      IN_FIFO32_M_Clk_P  : out std_logic;
      IN_FIFO32_M_Data_P : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem_P  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr_P   : out std_logic;

      -- Single FIFO32 Output
      OUT_FIFO32_S_Clk  : in  std_logic;
      OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
      OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
      OUT_FIFO32_S_Rd   : in  std_logic;

      OUT_FIFO32_M_Clk  : in  std_logic;
      OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
      OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
      OUT_FIFO32_M_Wr   : in  std_logic;

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

  constant HWT_COUNT : integer range 1 to 16 := 16;

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- FIFO32 interface between hardware and fifos.
  signal H2F_FIFO32_S_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
  signal H2F_FIFO32_S_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Fill : std_logic_vector((16*HWT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Rd   : std_logic_vector(HWT_COUNT-1 downto 0);

  signal H2F_FIFO32_M_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
  signal H2F_FIFO32_M_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Rem  : std_logic_vector((16*HWT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Wr   : std_logic_vector(HWT_COUNT-1 downto 0);

  -- FIFO32 interface between fifos and arbiter
  signal F2A_FIFO32_S_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
  signal F2A_FIFO32_S_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Fill : std_logic_vector((16*HWT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Rd   : std_logic_vector(HWT_COUNT-1 downto 0);

  signal F2A_FIFO32_M_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
  signal F2A_FIFO32_M_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Rem  : std_logic_vector((16*HWT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Wr   : std_logic_vector(HWT_COUNT-1 downto 0);

  -- FIFO32 interface between arbiter and memory controller.
  signal A2M_FIFO32_S_Clk  : std_logic;
  signal A2M_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_S_Rd   : std_logic;

  signal A2M_FIFO32_M_Clk  : std_logic;
  signal A2M_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_M_Wr   : std_logic;

  -- memif interface signals
  type memif_out_array_t is array(natural range <>) of memif_out_t;
  type memif_in_array_t is array(natural range <>) of memif_in_t;
  signal H2F_MEMIF_OUT : memif_out_array_t(0 to HWT_COUNT-1);
  signal H2F_MEMIF_IN  : memif_in_array_t(0 to HWT_COUNT-1);

  signal A2M_MEMIF_OUT : memif_out_t;
  signal A2M_MEMIF_IN  : memif_in_t;
  -- Misc
  signal Rst           : std_logic;
  signal clk           : std_logic;



begin  -- of architecture -------------------------------------------------------

  fifos : for i in 0 to HWT_COUNT-1 generate

    -- for reading a word of data in hwt process
    signal data : std_logic_vector(31 downto 0) := X"AAAAAAAA";
    
  begin

    memif_setup (
      H2F_MEMIF_OUT(i),
      H2F_MEMIF_IN(i),
      clk,
      H2F_FIFO32_S_Clk(i),
      H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
      H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
      H2F_FIFO32_S_Rd(i),
      H2F_FIFO32_M_Clk(i),
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
        FIFO32_S_Clk  => F2A_FIFO32_S_Clk(i),
        FIFO32_M_Clk  => H2F_FIFO32_M_Clk(i),
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
        FIFO32_S_Clk  => H2F_FIFO32_S_Clk(i),
        FIFO32_M_Clk  => F2A_FIFO32_M_Clk(i),
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
      variable seed1 : positive := i+1;
      --! @brief Second of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned
      variable seed2 : positive := i+i+1;


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

      type state_t is (GEN_DATA, WRITE_DATA, READ_DATA, COMP_ADDRESS, ERROR_STATE);
      variable state : state_t;
      variable done  : boolean := false;
      variable rnd   : unsigned(31 downto 0);
      
    begin
      if rst = '1' then
        state := GEN_DATA;
        -- init interface 
        memif_reset(H2F_MEMIF_OUT(i), H2F_MEMIF_IN(i));
        done  := false;
      elsif rising_edge(clk) then
        case state is
          when GEN_DATA =>
            rnd   := get_rand_unsigned(0, 2**30, 32);
            state := WRITE_DATA;
          when WRITE_DATA =>
            memif_write (
              H2F_MEMIF_OUT(i),
              H2F_MEMIF_IN(i),
              std_logic_vector(to_unsigned(i, 32)),  -- address
              std_logic_vector(rnd),                 -- data
              done
              );
            if done then state := READ_DATA; end if;
          when READ_DATA =>
            memif_read (
              H2F_MEMIF_OUT(i),
              H2F_MEMIF_IN(i),
              --std_logic_vector(to_unsigned(i, 32)),  -- address
              std_logic_vector(rnd),                 -- address
              data,                                  -- data
              done
              );
            if done then state := COMP_ADDRESS; end if;
          when COMP_ADDRESS =>
            -- we expect to read back the address in the data word, we asked for.
            if data = std_logic_vector(rnd) then
              state := GEN_DATA;
            else
              state := ERROR_STATE;
            end if;
          when ERROR_STATE =>
            null;                                    -- should not happen
          when others => null;
        end case;

        case rnd(0) is
          when '0' =>

          when '1' =>

          when others => null;
        end case;
      end if;
    end process;

  end generate;

  fifo32_arbiter_i : fifo32_arbiter
    generic map(
      FIFO32_PORTS     => HWT_COUNT,
      ARBITRATION_ALGO => 0
      )
    port map(
      -- Multiple FIFO32 Inputs
      IN_FIFO32_S_Clk_A  => F2A_FIFO32_S_Clk(0),
      IN_FIFO32_S_Data_A => F2A_FIFO32_S_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_S_Fill_A => F2A_FIFO32_S_Fill(16*(0+1)-1 downto 16*0),
      IN_FIFO32_S_Rd_A   => F2A_FIFO32_S_Rd(0),

      IN_FIFO32_M_Clk_A  => F2A_FIFO32_M_Clk(0),
      IN_FIFO32_M_Data_A => F2A_FIFO32_M_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_M_Rem_A  => F2A_FIFO32_M_Rem(16*(0+1)-1 downto 16*0),
      IN_FIFO32_M_Wr_A   => F2A_FIFO32_M_Wr(0),

      IN_FIFO32_S_Clk_B  => F2A_FIFO32_S_Clk(1),
      IN_FIFO32_S_Data_B => F2A_FIFO32_S_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_S_Fill_B => F2A_FIFO32_S_Fill(16*(1+1)-1 downto 16*1),
      IN_FIFO32_S_Rd_B   => F2A_FIFO32_S_Rd(1),

      IN_FIFO32_M_Clk_B  => F2A_FIFO32_M_Clk(1),
      IN_FIFO32_M_Data_B => F2A_FIFO32_M_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_M_Rem_B  => F2A_FIFO32_M_Rem(16*(1+1)-1 downto 16*1),
      IN_FIFO32_M_Wr_B   => F2A_FIFO32_M_Wr(1),

      IN_FIFO32_S_Clk_C  => F2A_FIFO32_S_Clk(2),
      IN_FIFO32_S_Data_C => F2A_FIFO32_S_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_S_Fill_C => F2A_FIFO32_S_Fill(16*(2+1)-1 downto 16*2),
      IN_FIFO32_S_Rd_C   => F2A_FIFO32_S_Rd(2),

      IN_FIFO32_M_Clk_C  => F2A_FIFO32_M_Clk(2),
      IN_FIFO32_M_Data_C => F2A_FIFO32_M_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_M_Rem_C  => F2A_FIFO32_M_Rem(16*(2+1)-1 downto 16*2),
      IN_FIFO32_M_Wr_C   => F2A_FIFO32_M_Wr(2),

      IN_FIFO32_S_Clk_D  => F2A_FIFO32_S_Clk(3),
      IN_FIFO32_S_Data_D => F2A_FIFO32_S_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_S_Fill_D => F2A_FIFO32_S_Fill(16*(3+1)-1 downto 16*3),
      IN_FIFO32_S_Rd_D   => F2A_FIFO32_S_Rd(3),

      IN_FIFO32_M_Clk_D  => F2A_FIFO32_M_Clk(3),
      IN_FIFO32_M_Data_D => F2A_FIFO32_M_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_M_Rem_D  => F2A_FIFO32_M_Rem(16*(3+1)-1 downto 16*3),
      IN_FIFO32_M_Wr_D   => F2A_FIFO32_M_Wr(3),

      IN_FIFO32_S_Clk_E  => F2A_FIFO32_S_Clk(4),
      IN_FIFO32_S_Data_E => F2A_FIFO32_S_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_S_Fill_E => F2A_FIFO32_S_Fill(16*(4+1)-1 downto 16*4),
      IN_FIFO32_S_Rd_E   => F2A_FIFO32_S_Rd(4),

      IN_FIFO32_M_Clk_E  => F2A_FIFO32_M_Clk(4),
      IN_FIFO32_M_Data_E => F2A_FIFO32_M_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_M_Rem_E  => F2A_FIFO32_M_Rem(16*(4+1)-1 downto 16*4),
      IN_FIFO32_M_Wr_E   => F2A_FIFO32_M_Wr(4),

      IN_FIFO32_S_Clk_F  => F2A_FIFO32_S_Clk(5),
      IN_FIFO32_S_Data_F => F2A_FIFO32_S_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_S_Fill_F => F2A_FIFO32_S_Fill(16*(5+1)-1 downto 16*5),
      IN_FIFO32_S_Rd_F   => F2A_FIFO32_S_Rd(5),

      IN_FIFO32_M_Clk_F  => F2A_FIFO32_M_Clk(5),
      IN_FIFO32_M_Data_F => F2A_FIFO32_M_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_M_Rem_F  => F2A_FIFO32_M_Rem(16*(5+1)-1 downto 16*5),
      IN_FIFO32_M_Wr_F   => F2A_FIFO32_M_Wr(5),

      IN_FIFO32_S_Clk_G  => F2A_FIFO32_S_Clk(6),
      IN_FIFO32_S_Data_G => F2A_FIFO32_S_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_S_Fill_G => F2A_FIFO32_S_Fill(16*(6+1)-1 downto 16*6),
      IN_FIFO32_S_Rd_G   => F2A_FIFO32_S_Rd(6),

      IN_FIFO32_M_Clk_G  => F2A_FIFO32_M_Clk(6),
      IN_FIFO32_M_Data_G => F2A_FIFO32_M_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_M_Rem_G  => F2A_FIFO32_M_Rem(16*(6+1)-1 downto 16*6),
      IN_FIFO32_M_Wr_G   => F2A_FIFO32_M_Wr(6),

      IN_FIFO32_S_Clk_H  => F2A_FIFO32_S_Clk(7),
      IN_FIFO32_S_Data_H => F2A_FIFO32_S_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_S_Fill_H => F2A_FIFO32_S_Fill(16*(7+1)-1 downto 16*7),
      IN_FIFO32_S_Rd_H   => F2A_FIFO32_S_Rd(7),

      IN_FIFO32_M_Clk_H  => F2A_FIFO32_M_Clk(7),
      IN_FIFO32_M_Data_H => F2A_FIFO32_M_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_M_Rem_H  => F2A_FIFO32_M_Rem(16*(7+1)-1 downto 16*7),
      IN_FIFO32_M_Wr_H   => F2A_FIFO32_M_Wr(7),

      IN_FIFO32_S_Clk_I  => F2A_FIFO32_S_Clk(8),
      IN_FIFO32_S_Data_I => F2A_FIFO32_S_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_S_Fill_I => F2A_FIFO32_S_Fill(16*(8+1)-1 downto 16*8),
      IN_FIFO32_S_Rd_I   => F2A_FIFO32_S_Rd(8),

      IN_FIFO32_M_Clk_I  => F2A_FIFO32_M_Clk(8),
      IN_FIFO32_M_Data_I => F2A_FIFO32_M_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_M_Rem_I  => F2A_FIFO32_M_Rem(16*(8+1)-1 downto 16*8),
      IN_FIFO32_M_Wr_I   => F2A_FIFO32_M_Wr(8),

      IN_FIFO32_S_Clk_J  => F2A_FIFO32_S_Clk(9),
      IN_FIFO32_S_Data_J => F2A_FIFO32_S_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_S_Fill_J => F2A_FIFO32_S_Fill(16*(9+1)-1 downto 16*9),
      IN_FIFO32_S_Rd_J   => F2A_FIFO32_S_Rd(9),

      IN_FIFO32_M_Clk_J  => F2A_FIFO32_M_Clk(9),
      IN_FIFO32_M_Data_J => F2A_FIFO32_M_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_M_Rem_J  => F2A_FIFO32_M_Rem(16*(9+1)-1 downto 16*9),
      IN_FIFO32_M_Wr_J   => F2A_FIFO32_M_Wr(9),

      IN_FIFO32_S_Clk_K  => F2A_FIFO32_S_Clk(10),
      IN_FIFO32_S_Data_K => F2A_FIFO32_S_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_S_Fill_K => F2A_FIFO32_S_Fill(16*(10+1)-1 downto 16*10),
      IN_FIFO32_S_Rd_K   => F2A_FIFO32_S_Rd(10),

      IN_FIFO32_M_Clk_K  => F2A_FIFO32_M_Clk(10),
      IN_FIFO32_M_Data_K => F2A_FIFO32_M_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_M_Rem_K  => F2A_FIFO32_M_Rem(16*(10+1)-1 downto 16*10),
      IN_FIFO32_M_Wr_K   => F2A_FIFO32_M_Wr(10),

      IN_FIFO32_S_Clk_L  => F2A_FIFO32_S_Clk(11),
      IN_FIFO32_S_Data_L => F2A_FIFO32_S_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_S_Fill_L => F2A_FIFO32_S_Fill(16*(11+1)-1 downto 16*11),
      IN_FIFO32_S_Rd_L   => F2A_FIFO32_S_Rd(11),

      IN_FIFO32_M_Clk_L  => F2A_FIFO32_M_Clk(11),
      IN_FIFO32_M_Data_L => F2A_FIFO32_M_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_M_Rem_L  => F2A_FIFO32_M_Rem(16*(11+1)-1 downto 16*11),
      IN_FIFO32_M_Wr_L   => F2A_FIFO32_M_Wr(11),

      IN_FIFO32_S_Clk_M  => F2A_FIFO32_S_Clk(12),
      IN_FIFO32_S_Data_M => F2A_FIFO32_S_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_S_Fill_M => F2A_FIFO32_S_Fill(16*(12+1)-1 downto 16*12),
      IN_FIFO32_S_Rd_M   => F2A_FIFO32_S_Rd(12),

      IN_FIFO32_M_Clk_M  => F2A_FIFO32_M_Clk(12),
      IN_FIFO32_M_Data_M => F2A_FIFO32_M_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_M_Rem_M  => F2A_FIFO32_M_Rem(16*(12+1)-1 downto 16*12),
      IN_FIFO32_M_Wr_M   => F2A_FIFO32_M_Wr(12),

      IN_FIFO32_S_Clk_N  => F2A_FIFO32_S_Clk(13),
      IN_FIFO32_S_Data_N => F2A_FIFO32_S_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_S_Fill_N => F2A_FIFO32_S_Fill(16*(13+1)-1 downto 16*13),
      IN_FIFO32_S_Rd_N   => F2A_FIFO32_S_Rd(13),

      IN_FIFO32_M_Clk_N  => F2A_FIFO32_M_Clk(13),
      IN_FIFO32_M_Data_N => F2A_FIFO32_M_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_M_Rem_N  => F2A_FIFO32_M_Rem(16*(13+1)-1 downto 16*13),
      IN_FIFO32_M_Wr_N   => F2A_FIFO32_M_Wr(13),

      IN_FIFO32_S_Clk_O  => F2A_FIFO32_S_Clk(14), 
      IN_FIFO32_S_Data_O => F2A_FIFO32_S_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_S_Fill_O => F2A_FIFO32_S_Fill(16*(14+1)-1 downto 16*14),
      IN_FIFO32_S_Rd_O   => F2A_FIFO32_S_Rd(14),

      IN_FIFO32_M_Clk_O  => F2A_FIFO32_M_Clk(14), 
      IN_FIFO32_M_Data_O => F2A_FIFO32_M_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_M_Rem_O  => F2A_FIFO32_M_Rem(16*(14+1)-1 downto 16*14),
      IN_FIFO32_M_Wr_O   => F2A_FIFO32_M_Wr(14),

      IN_FIFO32_S_Clk_P  => F2A_FIFO32_S_Clk(15),
      IN_FIFO32_S_Data_P => F2A_FIFO32_S_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_S_Fill_P => F2A_FIFO32_S_Fill(16*(15+1)-1 downto 16*15),
      IN_FIFO32_S_Rd_P   => F2A_FIFO32_S_Rd(15), 

      IN_FIFO32_M_Clk_P  => F2A_FIFO32_M_Clk(15),
      IN_FIFO32_M_Data_P => F2A_FIFO32_M_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_M_Rem_P  => F2A_FIFO32_M_Rem(16*(15+1)-1 downto 16*15),
      IN_FIFO32_M_Wr_P   => F2A_FIFO32_M_Wr(15),

      -- Single FIFO32 Output
      OUT_FIFO32_S_Clk  => A2M_FIFO32_S_Clk,
      OUT_FIFO32_S_Data => A2M_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => A2M_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => A2M_FIFO32_S_Rd,

      OUT_FIFO32_M_Clk  => A2M_FIFO32_M_Clk,
      OUT_FIFO32_M_Data => A2M_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => A2M_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => A2M_FIFO32_M_Wr,

      -- Misc
      Rst => rst,
      clk => clk,

      -- Debug signals to ILA
      ila_signals => open
      );

  memif_setup (
    A2M_MEMIF_OUT,
    A2M_MEMIF_IN,
    clk,
    A2M_FIFO32_S_Clk,
    A2M_FIFO32_S_Data,
    A2M_FIFO32_S_Fill,
    A2M_FIFO32_S_Rd,
    A2M_FIFO32_M_Clk,
    A2M_FIFO32_M_Data,
    A2M_FIFO32_M_Rem,
    A2M_FIFO32_M_Wr
    );

  mem_ctrl : process(clk, a2m_memif_in)
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
      a2m_memif_out.s_rd   <= '0';
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
              state                := DATA_READ;
              a2m_memif_out.s_rd   <= '0';
              a2m_memif_out.m_wr   <= '1';
              a2m_memif_out.m_data <= transfer_address;
            when WRITE =>
              state := DATA_WRITE;
            when others => null;
          end case;
        when DATA_WRITE =>
          transfer_size := transfer_size - 4;
          if transfer_size = 0 then
            state              := IDLE;
            a2m_memif_out.s_rd <= '0';
          end if;
        when DATA_READ =>
          a2m_memif_out.m_data <= transfer_address;
          transfer_size        := transfer_size - 4;
          if transfer_size = 0 then
            state                := IDLE;
            a2m_memif_out.m_wr   <= '0';
            a2m_memif_out.m_data <= X"00000000";
          end if;
        when others =>
          state := IDLE;
      end case;
    end if;
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

