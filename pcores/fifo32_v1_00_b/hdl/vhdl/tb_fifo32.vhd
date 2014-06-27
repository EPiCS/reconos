--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:34:17 06/25/2014
-- Design Name:   
-- Module Name:   /home/meise/git/reconos_epics/pcores/fifo32_v1_00_b/hdl/vhdl/tb_fifo32.vhd
-- Project Name:  fifo32
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo32
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

entity tb_fifo32 is
end tb_fifo32;

architecture behavior of tb_fifo32 is

  -- Component Declaration for the Unit Under Test (UUT)
  
  component fifo32
    generic (
      C_FIFO32_DEPTH : integer := 2048;
      C_ENABLE_ILA   : integer := 0
      );
    port(
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



  -- FIFO32 interface between hardware and fifos.
  signal H2F_MEMIF_OUT : o_memif_t;
  signal H2F_MEMIF_IN  : i_memif_t;

  signal H2F_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal H2F_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal H2F_FIFO32_S_Rd   : std_logic;

  signal H2F_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal H2F_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal H2F_FIFO32_M_Wr   : std_logic;

  -- FIFO32 interface between fifos and arbiter
  signal F2A_MEMIF_OUT : o_memif_t;
  signal F2A_MEMIF_IN  : i_memif_t;

  signal F2A_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal F2A_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal F2A_FIFO32_S_Rd   : std_logic;

  signal F2A_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal F2A_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal F2A_FIFO32_M_Wr   : std_logic;

  -- for reading a word of data in hwt process
  signal data : std_logic_vector(31 downto 0) := X"AAAAAAAA";
  
  -- Clock, clock period and reset definitions
  signal clk                   : std_logic := '1';
  signal Rst                   : std_logic := '0';
  constant FIFO32_S_Clk_period : time      := 10 ns;
  constant FIFO32_M_Clk_period : time      := 10 ns;
  
begin

  memif_setup (
    H2F_MEMIF_IN,
    H2F_MEMIF_OUT,
    H2F_FIFO32_S_Data,
    H2F_FIFO32_S_Fill,
    H2F_FIFO32_S_Rd,
    H2F_FIFO32_M_Data,
    H2F_FIFO32_M_Rem,
    H2F_FIFO32_M_Wr
    );

  -- Instantiate the Unit Under Test (UUT)
  master_fifo : fifo32
    generic map (
      C_FIFO32_DEPTH => 4
      )
    port map (
      Rst           => Rst,
      FIFO32_S_Clk  => clk,
      FIFO32_M_Clk  => clk,
      FIFO32_S_Data => F2A_FIFO32_S_Data,
      FIFO32_M_Data => H2F_FIFO32_M_Data,
      FIFO32_S_Fill => F2A_FIFO32_S_Fill,
      FIFO32_M_Rem  => H2F_FIFO32_M_Rem,
      FIFO32_S_Rd   => F2A_FIFO32_S_Rd,
      FIFO32_M_Wr   => H2F_FIFO32_M_Wr
      );

  slave_fifo : fifo32
    generic map (
      C_FIFO32_DEPTH => 16
      )
    port map (
      Rst           => Rst,
      FIFO32_S_Clk  => clk,
      FIFO32_M_Clk  => clk,
      FIFO32_S_Data => H2F_FIFO32_S_Data,
      FIFO32_M_Data => F2A_FIFO32_M_Data,
      FIFO32_S_Fill => H2F_FIFO32_S_Fill,
      FIFO32_M_Rem  => F2A_FIFO32_M_Rem,
      FIFO32_S_Rd   => H2F_FIFO32_S_Rd,
      FIFO32_M_Wr   => F2A_FIFO32_M_Wr
      );

  hwt_process : process(clk, H2F_MEMIF_IN)
    is
    --! @brief First of two global variables needed for random number functions,
    --!        e.g. get_rand_unsigned      
    variable seed1 : positive := 1;
    --! @brief Second of two global variables needed for random number functions,
    --!        e.g. get_rand_unsigned
    variable seed2 : positive := 1;


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

    constant C_WRITE_LENGTH : integer := 8;
    
    --type state_t is (GEN_DATA, WRITE_DATA, READ_DATA, COMP_ADDRESS, ERROR_STATE);
    type state_t is (GEN_DATA, WRITE_REQUEST, WRITE_DATA,  READ_DATA, COMP_ADDRESS, ERROR_STATE);
    variable state : state_t;
    variable done  : boolean := false;
    variable rnd   : unsigned(31 downto 0);
    variable counter : integer := C_WRITE_LENGTH;
    
  begin
    if rst = '1' then
      state := GEN_DATA;
      -- init interface 
      memif_reset(H2F_MEMIF_OUT);
      done  := false;
    elsif rising_edge(clk) then
      case state is
        when GEN_DATA =>
          rnd   := get_rand_unsigned(0, 2**30, 32);
          state := WRITE_REQUEST;
          counter := C_WRITE_LENGTH;
        when WRITE_REQUEST =>
          memif_write_word (
            H2F_MEMIF_IN,
            H2F_MEMIF_OUT,
            std_logic_vector(to_unsigned(0, 32)),  -- address
            std_logic_vector(to_unsigned(C_WRITE_LENGTH, 32)),  -- length
            done
            );
          if done then state := WRITE_DATA; end if;
        when WRITE_DATA =>
          data <= std_logic_vector(to_unsigned(counter, 32));
          memif_fifo_push (
            H2F_MEMIF_IN,
            H2F_MEMIF_OUT,
            data,                 -- data
            done
            );
          if done then counter := counter -1; end if;
          if counter = 0 then state := READ_DATA; end if;
        when READ_DATA =>
          memif_read_word (
            H2F_MEMIF_IN,
            H2F_MEMIF_OUT,
            std_logic_vector(rnd),                 -- address
            data,                                  -- data
            done
            );
          if done then state := COMP_ADDRESS; end if;
        when COMP_ADDRESS =>
          -- we expect to read back the address in the data word, we asked for.
          if data = std_logic_vector(rnd) then
            state := GEN_DATA;
            report "Write/read succeded!" severity note;
          else
            state := ERROR_STATE;
            report "Found write/read error!" severity error;
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


  memif_setup (
    F2A_MEMIF_IN,
    F2A_MEMIF_OUT,
    F2A_FIFO32_S_Data,
    F2A_FIFO32_S_Fill,
    F2A_FIFO32_S_Rd,
    F2A_FIFO32_M_Data,
    F2A_FIFO32_M_Rem,
    F2A_FIFO32_M_Wr
    );

  mem_ctrl : process(clk, rst, f2a_memif_in)
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
      f2a_memif_out.s_rd   <= '0';
      f2a_memif_out.m_wr   <= '0';
      f2a_memif_out.m_data <= X"00000000";
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state              := state;
      f2a_memif_out.s_rd <= f2a_memif_out.s_rd;
      f2a_memif_out.m_wr <= f2a_memif_out.m_wr;
      transfer_mode      := transfer_mode;
      transfer_size      := transfer_size;
      case state is
        when IDLE =>
          f2a_memif_out.s_rd <= '0';
          f2a_memif_out.m_wr <= '0';
          if to_integer(unsigned(f2a_memif_in.s_fill)) > 1 then
            state              := MODE_LENGTH;
            f2a_memif_out.s_rd <= '1';
          end if;
          
          
        when MODE_LENGTH =>
          state := ADDRESS;
          case f2a_memif_in.s_data(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          transfer_size := to_integer(unsigned(f2a_memif_in.s_data(23 downto 0)));
        when ADDRESS =>
          transfer_address := f2a_memif_in.s_data;
          case transfer_mode is
            when READ =>
              state                := DATA_READ;
              f2a_memif_out.s_rd   <= '0';
              f2a_memif_out.m_wr   <= '1';
              f2a_memif_out.m_data <= transfer_address;
            when WRITE =>
              state := DATA_WRITE;
            when others => null;
          end case;
        when DATA_WRITE =>
           if f2a_memif_in.s_fill > X"0001" then
            f2a_memif_out.s_rd   <= '1';
            transfer_size        := transfer_size - 4;
          else
            f2a_memif_out.s_rd   <= '0';
          end if;
          if transfer_size = 0 then
            state              := IDLE;
            f2a_memif_out.s_rd <= '0';
          end if;
        when DATA_READ =>
          if f2a_memif_in.m_remainder > X"0001" then
            f2a_memif_out.m_wr   <= '1';
            transfer_size        := transfer_size - 4;
          else
            f2a_memif_out.m_wr   <= '0';
          end if;
          f2a_memif_out.m_data <= transfer_address;
          if transfer_size = 0 then
            state                := IDLE;
            f2a_memif_out.m_wr   <= '0';
            f2a_memif_out.m_data <= X"00000000";
          end if;
        when others =>
          state := IDLE;
      end case;
    end if;
  end process;

  -- Clock process definitions
  --FIFO32_S_Clk <= clk;
  --FIFO32_M_Clk <= clk;

  Clk_process : process
  begin
    clk <= '0';
    wait for FIFO32_M_Clk_period/2;
    clk <= '1';
    wait for FIFO32_M_Clk_period/2;
  end process;

  reset_process : process
  begin
    Rst <= '1';
    wait for FIFO32_M_Clk_period*5;
    Rst <= '0';
    wait;
  end process;


  
end;
