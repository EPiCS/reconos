library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity tb_fifo32_burst_converter is
end entity;

architecture testbench of tb_fifo32_burst_converter is
--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

  component fifo32_burst_converter
    generic (
      C_PAGE_SIZE  : natural := 4096;  -- In Bytes; Dictated by Linux Memory Management;
      -- must be power of 2
      C_BURST_SIZE : natural := 16      -- 16 words á 32 bits
      );
    port (
      -- FIFO32 Input
      IN_FIFO32_S_Clk  : out std_logic;
      IN_FIFO32_S_Data : in  std_logic_vector(31 downto 0);
      IN_FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
      IN_FIFO32_S_Rd   : out std_logic;

      IN_FIFO32_M_Clk  : out std_logic;
      IN_FIFO32_M_Data : out std_logic_vector(31 downto 0);
      IN_FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
      IN_FIFO32_M_Wr   : out std_logic;

      -- FIFO32 Output
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
      clk : in std_logic                -- separate clock for control logic
      );
  end component;

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
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant half_cycle : time := 5 ns;
  constant full_cycle : time := 2 * half_cycle;

  type mem_request_t is record
    mode_length : std_logic_vector(31 downto 0);
    address     : std_logic_vector(31 downto 0);
  end record;
  type mem_request_array_t is array (natural range <>) of mem_request_t;
  constant requests : mem_request_array_t := (
    (X"00000004", X"00000000"),  -- 1 word read from beginning of first page
    (X"00000004", X"00000FFC"),  -- 1 word read from end       of first page
    (X"00000008", X"00000000"),  -- 2 word read from beginning of first page
    (X"00000008", X"00000FFC")   -- 2 word read from end       of first page
    );

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- FIFO32 interface between testbench and fifo.
  signal T2F_FIFO32_S_Clk  : std_logic;
  signal T2F_FIFO32_S_Data : std_logic_vector(32-1 downto 0);
  signal T2F_FIFO32_S_Fill : std_logic_vector(16-1 downto 0);
  signal T2F_FIFO32_S_Rd   : std_logic;

  signal T2F_FIFO32_M_Clk  : std_logic;
  signal T2F_FIFO32_M_Data : std_logic_vector(32-1 downto 0);
  signal T2F_FIFO32_M_Rem  : std_logic_vector(16-1 downto 0);
  signal T2F_FIFO32_M_Wr   : std_logic;

  -- FIFO32 interface between fifo and burst converter.
  signal F2B_FIFO32_S_Clk  : std_logic;
  signal F2B_FIFO32_S_Data : std_logic_vector(32-1 downto 0);
  signal F2B_FIFO32_S_Fill : std_logic_vector(16-1 downto 0);
  signal F2B_FIFO32_S_Rd   : std_logic;

  signal F2B_FIFO32_M_Clk  : std_logic;
  signal F2B_FIFO32_M_Data : std_logic_vector(32-1 downto 0);
  signal F2B_FIFO32_M_Rem  : std_logic_vector(16-1 downto 0);
  signal F2B_FIFO32_M_Wr   : std_logic;

  -- FIFO32 interface between burst converter and testbench
  signal B2T_FIFO32_S_Clk  : std_logic;
  signal B2T_FIFO32_S_Data : std_logic_vector(32-1 downto 0);
  signal B2T_FIFO32_S_Fill : std_logic_vector(16-1 downto 0);
  signal B2T_FIFO32_S_Rd   : std_logic;

  signal B2T_FIFO32_M_Clk  : std_logic;
  signal B2T_FIFO32_M_Data : std_logic_vector(32-1 downto 0);
  signal B2T_FIFO32_M_Rem  : std_logic_vector(16-1 downto 0);
  signal B2T_FIFO32_M_Wr   : std_logic;

  -- memif interface signals
  signal T2F_MEMIF_IN  : i_memif_t;
  signal T2F_MEMIF_OUT : o_memif_t;

  --signal F2B_MEMIF_IN  : i_memif_t;
  --signal F2B_MEMIF_OUT : o_memif_t;

  signal B2T_MEMIF_IN  : i_memif_t;
  signal B2T_MEMIF_OUT : o_memif_t;

  type payload_t is array (natural range <>) of std_logic_vector(31 downto 0);
  signal data : payload_t(0 downto 0) := (0 => (X"00000000"));

  -- Misc
  signal Rst : std_logic;
  signal clk : std_logic;



begin  -- of architecture -------------------------------------------------------

  memif_setup (
    T2F_MEMIF_IN,
    T2F_MEMIF_OUT,
    clk,
    T2F_FIFO32_S_Clk,
    T2F_FIFO32_S_Data,
    T2F_FIFO32_S_Fill,
    T2F_FIFO32_S_Rd,
    T2F_FIFO32_M_Clk,
    T2F_FIFO32_M_Data,
    T2F_FIFO32_M_Rem,
    T2F_FIFO32_M_Wr
    );


  --memif_setup (
  --  F2B_MEMIF_IN,
  --  F2B_MEMIF_OUT,
  --  clk,
  --  F2B_FIFO32_S_Clk,
  --  F2B_FIFO32_S_Data,
  --  F2B_FIFO32_S_Fill,
  --  F2B_FIFO32_S_Rd,
  --  F2B_FIFO32_M_Clk,
  --  F2B_FIFO32_M_Data,
  --  F2B_FIFO32_M_Rem,
  --  F2B_FIFO32_M_Wr
  --  );

  memif_setup (
    B2T_MEMIF_IN,
    B2T_MEMIF_OUT,
    clk,
    B2T_FIFO32_S_Clk,
    B2T_FIFO32_S_Data,
    B2T_FIFO32_S_Fill,
    B2T_FIFO32_S_Rd,
    B2T_FIFO32_M_Clk,
    B2T_FIFO32_M_Data,
    B2T_FIFO32_M_Rem,
    B2T_FIFO32_M_Wr
    );



  input_process : process(clk, rst, T2F_MEMIF_IN)
    is
    --! @brief First of two global variables needed for random number functions,
    --!        e.g. get_rand_unsigned      
    variable seed1 : positive := 1;
    --! @brief Second of two global variables needed for random number functions,
    --!        e.g. get_rand_unsigned
    variable seed2 : positive := 2;


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

    type state_t is (STATE_PREPARE, STATE_WRITE_REQUEST, STATE_WRITE_DATA,
                     STATE_READ_REQUEST, STATE_READ_DATA, STATE_STOP);
    variable state          : state_t;
    variable done           : boolean := false;
    variable request_length : natural;
    variable rnd            : unsigned(31 downto 0);
    variable waste_bin      : std_logic_vector(31 downto 0);
    variable request_nr     : natural := 0;
    
  begin
    if rst = '1' then
      state          := STATE_PREPARE;
      -- init interface 
      memif_reset(T2F_MEMIF_OUT);
      done           := false;
      request_nr     := 0;
      request_length := 0;
    elsif rising_edge(clk) then
      -- defaults
      state := state;

      case state is
        when STATE_PREPARE =>
          memif_reset(T2F_MEMIF_OUT);

          if request_nr >= requests'length then
            state := STATE_STOP;
          else
            request_length := to_integer(unsigned(requests(request_nr).mode_length(23 downto 0)));
            if requests(request_nr).mode_length(31) = '1' then
              state := STATE_WRITE_REQUEST;
            else
              state := STATE_READ_REQUEST;
            end if;
          end if;
          
        when STATE_WRITE_REQUEST =>
          memif_write_request(
            T2F_MEMIF_IN,
            T2F_MEMIF_OUT,
            requests(request_nr).address,
            requests(request_nr).mode_length(23 downto 0),
            done
            );
          if done then state := STATE_WRITE_DATA; end if;

        when STATE_WRITE_DATA =>
          
          memif_fifo_push (
            T2F_MEMIF_IN,
            T2F_MEMIF_OUT,
            data(0),
            done
            );
          if done then request_length := request_length - 4; end if;
          if request_length = 0 then
            state      := STATE_PREPARE;
            request_nr := request_nr + 1;
          end if;
          
        when STATE_READ_REQUEST =>
          memif_read_request(
            T2F_MEMIF_IN,
            T2F_MEMIF_OUT,
            requests(request_nr).address,
            requests(request_nr).mode_length(23 downto 0),
            done
            );
          if done then state := STATE_READ_DATA; end if;
          
        when STATE_READ_DATA =>
          memif_fifo_pull (
            T2F_MEMIF_IN,
            T2F_MEMIF_OUT,
            data(0),
            done
            );
          if done then
            state      := STATE_PREPARE;
            request_nr := request_nr + 1;
          end if;

        when STATE_STOP =>
          null;
          
        when others => null;
      end case;
    end if;
  end process;

  t2b_fifo_i : fifo32
    generic map(
      C_FIFO32_DEPTH => 1024
      )
    port map(
      Rst           => rst,
      FIFO32_S_Clk  => F2B_FIFO32_S_Clk,
      FIFO32_M_Clk  => T2F_FIFO32_M_Clk,
      FIFO32_S_Data => F2B_FIFO32_S_Data,
      FIFO32_M_Data => T2F_FIFO32_M_Data,
      FIFO32_S_Fill => F2B_FIFO32_S_Fill,
      FIFO32_M_Rem  => T2F_FIFO32_M_Rem,
      FIFO32_S_Rd   => F2B_FIFO32_S_Rd,
      FIFO32_M_Wr   => T2F_FIFO32_M_Wr
      );

  b2t_fifo_i : fifo32
    generic map(
      C_FIFO32_DEPTH => 1024
      )
    port map(
      Rst           => rst,
      FIFO32_S_Clk  => T2F_FIFO32_S_Clk,
      FIFO32_M_Clk  => F2B_FIFO32_M_Clk,
      FIFO32_S_Data => T2F_FIFO32_S_Data,
      FIFO32_M_Data => F2B_FIFO32_M_Data,
      FIFO32_S_Fill => T2F_FIFO32_S_Fill,
      FIFO32_M_Rem  => F2B_FIFO32_M_Rem,
      FIFO32_S_Rd   => T2F_FIFO32_S_Rd,
      FIFO32_M_Wr   => F2B_FIFO32_M_Wr
      );

  fifo32_burst_converter_i : fifo32_burst_converter
    generic map(
      C_PAGE_SIZE  => 4096,
      C_BURST_SIZE => 16
      )
    port map(
      -- FIFO32 Input
      IN_FIFO32_S_Clk  => F2B_FIFO32_S_Clk,
      IN_FIFO32_S_Data => F2B_FIFO32_S_Data,
      IN_FIFO32_S_Fill => F2B_FIFO32_S_Fill,
      IN_FIFO32_S_Rd   => F2B_FIFO32_S_Rd,

      IN_FIFO32_M_Clk  => F2B_FIFO32_M_Clk,
      IN_FIFO32_M_Data => F2B_FIFO32_M_Data,
      IN_FIFO32_M_Rem  => F2B_FIFO32_M_Rem,
      IN_FIFO32_M_Wr   => F2B_FIFO32_M_Wr,

      -- FIFO32 Output
      OUT_FIFO32_S_Clk  => B2T_FIFO32_S_Clk,
      OUT_FIFO32_S_Data => B2T_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => B2T_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => B2T_FIFO32_S_Rd,

      OUT_FIFO32_M_Clk  => B2T_FIFO32_M_Clk,
      OUT_FIFO32_M_Data => B2T_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => B2T_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => B2T_FIFO32_M_wr,

      -- Misc
      Rst => rst,
      clk => clk
      );


  output_process : process(clk, rst, b2t_memif_in)
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
      b2t_memif_out.s_rd   <= '0';
      b2t_memif_out.s_rd   <= '0';
      b2t_memif_out.m_data <= X"00000000";
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state              := state;
      b2t_memif_out.s_rd <= b2t_memif_out.s_rd;
      b2t_memif_out.m_wr <= b2t_memif_out.m_wr;
      transfer_mode      := transfer_mode;
      transfer_size      := transfer_size;
      case state is
        when IDLE =>
          b2t_memif_out.s_rd <= '0';
          b2t_memif_out.m_wr <= '0';
          if to_integer(unsigned(b2t_memif_in.s_fill)) > 1 then
            state              := MODE_LENGTH;
            b2t_memif_out.s_rd <= '1';
          end if;
          
          
        when MODE_LENGTH =>
          state := ADDRESS;
          case b2t_memif_in.s_data(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          transfer_size := to_integer(unsigned(b2t_memif_in.s_data(23 downto 0)));
        when ADDRESS =>
          transfer_address := b2t_memif_in.s_data;
          case transfer_mode is
            when READ =>
              state                := DATA_READ;
              b2t_memif_out.s_rd   <= '0';
              b2t_memif_out.m_wr   <= '1';
              b2t_memif_out.m_data <= transfer_address;
            when WRITE =>
              state := DATA_WRITE;
            when others => null;
          end case;
        when DATA_WRITE =>
          transfer_size := transfer_size - 4;
          if transfer_size = 0 then
            state              := IDLE;
            b2t_memif_out.s_rd <= '0';
          end if;
        when DATA_READ =>
          b2t_memif_out.m_data <= transfer_address;
          transfer_size        := transfer_size - 4;
          if transfer_size = 0 then
            state                := IDLE;
            b2t_memif_out.m_wr   <= '0';
            b2t_memif_out.m_data <= X"00000000";
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

