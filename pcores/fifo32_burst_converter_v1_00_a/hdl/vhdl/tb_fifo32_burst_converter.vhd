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
    C_PAGE_SIZE : natural := 4096;      -- In Bytes; Dictated by Linux Memory Management;
                                        -- must be power of 2
    C_BURST_SIZE: natural := 16         -- 16 words á 32 bits
    );
  port (
    -- FIFO32 Input
    IN_FIFO32_S_Clk   : out std_logic;
    IN_FIFO32_S_Data  : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd    : out std_logic;

    IN_FIFO32_M_Clk   : out std_logic;
    IN_FIFO32_M_Data  : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem   : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr    : out std_logic;
       
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
    clk : in std_logic                  -- separate clock for control logic
    );
  end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant half_cycle : time := 5 ns;
  constant full_cycle : time := 2 * half_cycle;

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- FIFO32 interface between testbench and burst converter.
  signal T2B_FIFO32_S_Clk  : std_logic;
  signal T2B_FIFO32_S_Data : std_logic_vector(32-1 downto 0);
  signal T2B_FIFO32_S_Fill : std_logic_vector(16-1 downto 0);
  signal T2B_FIFO32_S_Rd   : std_logic;

  signal T2B_FIFO32_M_Clk  : std_logic;
  signal T2B_FIFO32_M_Data : std_logic_vector(32-1 downto 0);
  signal T2B_FIFO32_M_Rem  : std_logic_vector(16-1 downto 0);
  signal T2B_FIFO32_M_Wr   : std_logic;

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
  signal T2B_MEMIF : memif_t;

  signal B2T_MEMIF : memif_t;

  type payload_t is array (natural range <>) of std_logic_vector(31 downto 0);
  signal data : payload_t(0 downto 0) := ( 0 => (X"00000000") );
  
  -- Misc
  signal Rst           : std_logic;
  signal clk           : std_logic;



begin  -- of architecture -------------------------------------------------------

  
  -- for reading a word of data in hwt process
  memif_setup (
    T2B_MEMIF,
    clk,
    T2B_FIFO32_S_Clk,
    T2B_FIFO32_S_Data,
    T2B_FIFO32_S_Fill,
    T2B_FIFO32_S_Rd,
    T2B_FIFO32_M_Clk,
    T2B_FIFO32_M_Data,
    T2B_FIFO32_M_Rem,
    T2B_FIFO32_M_Wr
    );




    input_process : process(clk, T2B_MEMIF)
    is
      --! @brief First of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned      
      variable seed1 : positive:= 1;
      --! @brief Second of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned
      variable seed2 : positive:= 2;


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
                       STATE_READ_REQUEST, STATE_READ_DATA);
      variable state : state_t;
      variable done : boolean := false;
      variable request_length : natural;
      variable rnd : unsigned(31 downto 0);
      variable waste_bin : std_logic_vector(31 downto 0);
      
      type mem_request_t is record
                              mode_length : std_logic_vector(31 downto 0);
                              address     : std_logic_vector(31 downto 0);
      end record;
      type mem_request_array_t is array (natural range <>) of mem_request_t;
      constant requests : mem_request_array_t := (
        (X"00000001",X"00000000"),      -- 1 word read from beginning of first page
        (X"00000001",X"00000FFF"),      -- 1 word read from end       of first page
        (X"00000002",X"00000000"),      -- 2 word read from beginning of first page
        (X"00000002",X"00000FFF")       -- 2 word read from end       of first page
      );

      variable request_nr : natural := 0;
      
    begin
      if rst = '1' then
        state := STATE_PREPARE;
        -- init interface 
        memif_reset(T2B_MEMIF);
        done := false;
        request_nr := 0;
        request_length := 0;
      elsif rising_edge(clk) then
        -- defaults
        state := state;
        
        case state is
          when STATE_PREPARE =>
            request_length := to_integer(unsigned(requests(request_nr).mode_length(23 downto 0)));
            if requests(request_nr).mode_length(31) = '1' then
              state := STATE_WRITE_REQUEST;
            else
              state := STATE_READ_REQUEST;
            end if;
            
          when STATE_WRITE_REQUEST =>
            --memif_write_request();
            if done then state := STATE_WRITE_DATA; end if;

          when STATE_WRITE_DATA =>
            
            memif_fifo_push (
              T2B_MEMIF,
              data(0),  -- address
              done
            );
            if done then request_length := request_length - 4; end if;
            if request_length = 0 then state := STATE_PREPARE; end if;
            
          when STATE_READ_REQUEST =>
            --memif_read_request();
            if done then state := STATE_READ_DATA; end if;
            
          when STATE_READ_DATA =>
            memif_fifo_pull (
              T2B_MEMIF,
              data(0),  -- address
              done
            );
            if done then state := STATE_PREPARE; end if;
            
          when others => null;
        end case;
      end if;
  end process;


  fifo32_burst_converter_i : fifo32_burst_converter
    generic map(
      C_PAGE_SIZE  => 4096,
      C_BURST_SIZE => 16
      )
    port map(
      -- FIFO32 Input
      IN_FIFO32_S_Clk  => T2B_FIFO32_S_Clk,
      IN_FIFO32_S_Data => T2B_FIFO32_S_Data,
      IN_FIFO32_S_Fill => T2B_FIFO32_S_Fill,
      IN_FIFO32_S_Rd   => T2B_FIFO32_S_Rd,

      IN_FIFO32_M_Clk  => T2B_FIFO32_M_Clk,
      IN_FIFO32_M_Data => T2B_FIFO32_M_Data,
      IN_FIFO32_M_Rem  => T2B_FIFO32_M_Rem,
      IN_FIFO32_M_Wr   => T2B_FIFO32_M_Wr,

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

  memif_setup (
    B2T_MEMIF,
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

  output_process : process(clk, b2t_memif)
  is
    type FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;
    
  begin
    if rst = '1' then
      state := IDLE;
    
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state := state;
    
      case state is
        when IDLE =>
          
          
        when MODE_LENGTH =>
    
        when ADDRESS =>
    
        when DATA_WRITE =>
    
        when DATA_READ =>
    
        when others =>
    
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

