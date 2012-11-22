--Doxygen
--! @file fifo32_burst_converter.vhd
--! @brief This file contains the entity and architecture of a burst converter.
--!        This converter transforms the hardware threads requests into  
--!        compatible ones for the memory controller and mmu.

library ieee;              --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity fifo32_burst_converter is
  generic (
    C_PAGE_SIZE  : natural := 4096;  -- In Bytes; Dictated by Linux Memory Management;
                                     -- must be power of 2
    C_BURST_SIZE : natural := 1023*4    -- In Bytes. PLB Burst size is 1023
                                        -- words maximum. 1 word = 4 byte. Must
                                        -- be multiple of 4!
    );
  port (
    -- FIFO32 Input
    IN_FIFO32_S_Data : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd   : out std_logic;

    IN_FIFO32_M_Data : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr   : out std_logic;

    -- FIFO32 Output
    OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic;

    OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic;

    -- Misc
    Rst : in std_logic;
    clk : in std_logic;                  -- separate clock for control logic

    -- Debug
    ila_signals : out std_logic_vector(205 downto 0)
    );
end entity;

architecture behavioural of fifo32_burst_converter is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

 -- Mux select
  signal mux_sel : std_logic;           -- '0' is input, '1' is fsm
  
 -- Internal output signals from FSM
 signal OUT_FIFO32_S_Data_int : std_logic_vector(31 downto 0);
 signal OUT_FIFO32_S_Fill_int : std_logic_vector(15 downto 0);
 signal IN_FIFO32_S_Rd_int    : std_logic;
 
begin  -- of architecture -------------------------------------------------------

  -- Master ports are just directly connected.
  IN_FIFO32_M_Data <= OUT_FIFO32_M_Data;
  OUT_FIFO32_M_Rem <= IN_FIFO32_M_Rem;
  IN_FIFO32_M_Wr   <= OUT_FIFO32_M_Wr;

  OUT_FIFO32_S_Data <= OUT_FIFO32_S_Data_int when mux_sel = '1'
                       else IN_FIFO32_S_Data;
  OUT_FIFO32_S_Fill <= OUT_FIFO32_S_Fill_int when mux_sel = '1'
                       else IN_FIFO32_S_FILL;
  -- The "after 1 ns" statement is needed for correct timing in simulation.
  IN_FIFO32_S_Rd    <= IN_FIFO32_S_Rd_int after 1 ns when mux_sel = '1'
                       else OUT_FIFO32_S_Rd after 1 ns;
  
  fsm_p : process (clk, rst)
    is
    type FSM_STATE_T is (STATE_IDLE, STATE_MODE_LENGTH, STATE_ADDRESS, STATE_CALC, STATE_WRITE_MODE_LENGTH,
                         STATE_WRITE_ADDRESS, STATE_DATA_READ, STATE_DATA_WRITE);
    variable state : FSM_STATE_T;

    variable transfer_mode    : unsigned(7 downto 0);
    variable remaining_size    : unsigned(23 downto 2);
    variable next_address     : unsigned(31 downto 2);
    
    variable calc_size    : unsigned(23 downto 2);
    variable calc_address : unsigned(31 downto 2);
    
    function calc_transfer_size (
      constant page_size  : unsigned;
      constant burst_size : unsigned;
      constant offset     : unsigned;
      constant length     : unsigned)
      return unsigned
    is
      variable offset_length : unsigned(page_size'range);
      variable final_length  : unsigned(23 downto 2);
    begin  -- function calc_transfer_size
      assert page_size > 0 report "page_size can't be 0!" severity failure;
      assert burst_size > 0 report "burst_size can't be 0!" severity failure;
      
      final_length := (others => '0');
      offset_length := page_size - offset;
      if offset_length < burst_size then
        final_length(offset_length'range) := offset_length;
      else
        final_length(burst_size'range) := burst_size;
      end if;

      if final_length > length then
        final_length(length'range) := length;
      end if;

      return final_length;
    end function;
    
  begin
    if rst = '1' then
      state            := STATE_IDLE;
      transfer_mode    := (others => '0');
      remaining_size    := (others => '0');

      calc_size      := (others => '0');
      calc_address   := (others => '0');
      next_address   := (others => '0');
      IN_FIFO32_S_Rd_int <= '0';

      mux_sel <= '1';
      
      ila_signals <= (others => '0');
      
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state            := state;
      transfer_mode    := transfer_mode;
      remaining_size   := remaining_size;

      calc_size      := calc_size;
      calc_address   := calc_address;
      next_address   := next_address;

      mux_sel        <= mux_sel;
      
      IN_FIFO32_S_Rd_int <= '0';

      OUT_FIFO32_S_Data_int <= IN_FIFO32_S_Data;
      OUT_FIFO32_S_Fill_int <= IN_FIFO32_S_Fill;

      case state is
        when STATE_IDLE              => ila_signals(2 downto 0) <= "000";
        when STATE_MODE_LENGTH       => ila_signals(2 downto 0) <= "001";
        when STATE_ADDRESS           => ila_signals(2 downto 0) <= "010";
        when STATE_CALC              => ila_signals(2 downto 0) <= "011";
        when STATE_WRITE_MODE_LENGTH => ila_signals(2 downto 0) <= "100";
        when STATE_WRITE_ADDRESS     => ila_signals(2 downto 0) <= "101";
        when STATE_DATA_READ         => ila_signals(2 downto 0) <= "110";
        when STATE_DATA_WRITE        => ila_signals(2 downto 0) <= "111";
        when others                  => ila_signals(2 downto 0) <= "111";
      end case;
      ila_signals(24  downto 3)   <= std_logic_vector(calc_size);       -- 22 Bits
      ila_signals(54  downto 25)  <= std_logic_vector(calc_address);    -- 30 Bits
      ila_signals(84  downto 55)  <= std_logic_vector(next_address);    -- 30 Bits
      ila_signals(106 downto 85)  <= std_logic_vector(remaining_size);  -- 22 Bits
      ila_signals(122 downto 107) <= IN_FIFO32_S_Fill;  -- 16 Bits
      ila_signals(154 downto 123) <= IN_FIFO32_S_Data;  -- 32 Bits
      ila_signals(170 downto 155) <= OUT_FIFO32_S_Fill_int;  -- 16 Bits
      ila_signals(202 downto 171) <= OUT_FIFO32_S_Data_int;  -- 32 Bits
      ila_signals(203)            <= IN_FIFO32_S_Rd_int;
      ila_signals(204)            <= OUT_FIFO32_S_Rd;
      ila_signals(205)            <= mux_sel;
      
      case state is
        when STATE_IDLE =>
          -- Wait for header to appear in FIFO
          -- Outputs are in "no data" state
          if to_integer(unsigned(IN_FIFO32_S_Fill)) > 1 then
            state          := STATE_MODE_LENGTH;
            IN_FIFO32_S_Rd_int <= '1';
          end if;
          
          OUT_FIFO32_S_Data_int <= (others => '0');
          OUT_FIFO32_S_Fill_int <= (others => '0');
          
        when STATE_MODE_LENGTH =>
          -- Read in first word of header for analysis.
          -- Outputs are in "no data" state

          state          := STATE_ADDRESS;
          IN_FIFO32_S_Rd_int <= '1';
          transfer_mode := unsigned(IN_FIFO32_S_DATA(31 downto 24));
          -- lower 24 bits of first word are defined to be the length
          -- of the transfer.
          remaining_size := unsigned(IN_FIFO32_S_DATA(23 downto 2));

          -- reset calculated values
          calc_size         := (others => '0');
          calc_address      := (others => '0');
          next_address      := (others => '0');
          OUT_FIFO32_S_Data_int <= (others => '0');
          OUT_FIFO32_S_Fill_int <= (others => '0');
          
        when STATE_ADDRESS =>
          -- Read in second word of header for analysis.
          -- Outputs are in "no data" state          
          state             := STATE_CALC;
          next_address      := unsigned(IN_FIFO32_S_DATA(31 downto 2));
          IN_FIFO32_S_Rd_int    <= '0';
          OUT_FIFO32_S_Data_int <= (others => '0');
          OUT_FIFO32_S_Fill_int <= (others => '0');

        when STATE_CALC =>
          -- Calculate how long the request may be
          state        := STATE_WRITE_MODE_LENGTH;
          calc_size    := calc_transfer_size(to_unsigned(C_PAGE_SIZE,clog2(C_PAGE_SIZE+1))(clog2(C_PAGE_SIZE+1)-1 downto 2),
                                             to_unsigned(C_BURST_SIZE,clog2(C_BURST_SIZE+1))(clog2(C_BURST_SIZE+1)-1 downto 2),
                                             next_address(clog2(C_PAGE_SIZE)-1 downto 2),
                                             remaining_size);
          calc_address := next_address;
          next_address := calc_address + calc_size;

          case transfer_mode is
            when unsigned(MEMIF_CMD_READ)  =>
              OUT_FIFO32_S_Data_int <= MEMIF_CMD_READ & std_logic_vector(calc_size)& "00" ;
            when unsigned(MEMIF_CMD_WRITE) =>
              OUT_FIFO32_S_Data_int <= MEMIF_CMD_WRITE & std_logic_vector(calc_size)& "00";
            when others =>
              OUT_FIFO32_S_Data_int <= MEMIF_CMD_READ & std_logic_vector(calc_size)& "00";
          end case;
          OUT_FIFO32_S_Fill_int <= std_logic_vector(to_unsigned(to_integer(unsigned(IN_FIFO32_S_Fill)) + 2, 16));
          
        when STATE_WRITE_MODE_LENGTH =>
          -- Inputs are not read.
          -- First word of header is put on the outputs.
          if OUT_FIFO32_S_rd = '1' then
            state             := STATE_WRITE_ADDRESS;
            OUT_FIFO32_S_Data_int <= std_logic_vector(calc_address) & "00";
            OUT_FIFO32_S_Fill_int <= std_logic_vector(to_unsigned(to_integer(unsigned(IN_FIFO32_S_Fill)) + 1, 16));
          else
            case transfer_mode is
              when unsigned(MEMIF_CMD_READ)  =>
                OUT_FIFO32_S_Data_int <= MEMIF_CMD_READ & std_logic_vector(calc_size)& "00" ;
              when unsigned(MEMIF_CMD_WRITE) =>
                OUT_FIFO32_S_Data_int <= MEMIF_CMD_WRITE & std_logic_vector(calc_size)& "00";
              when others =>
                OUT_FIFO32_S_Data_int <= MEMIF_CMD_READ & std_logic_vector(calc_size)& "00";
            end case;
            OUT_FIFO32_S_Fill_int <= std_logic_vector(to_unsigned(to_integer(unsigned(IN_FIFO32_S_Fill)) + 2, 16));
          end if;
          
          
        when STATE_WRITE_ADDRESS =>
          -- Inputs are not read.
          -- Second word of header is put on the outputs.
          if OUT_FIFO32_S_rd = '1' then
            case transfer_mode is
              when unsigned(MEMIF_CMD_READ)  => state := STATE_DATA_READ;
              when unsigned(MEMIF_CMD_WRITE) => state := STATE_DATA_WRITE;
                                                mux_sel <= '0';
              when others => state := STATE_DATA_READ;
            end case;
            OUT_FIFO32_S_Data_int <= IN_FIFO32_S_Data;
            OUT_FIFO32_S_Fill_int <= std_logic_vector(to_unsigned(to_integer(unsigned(IN_FIFO32_S_Fill)), 16));
          else
            OUT_FIFO32_S_Data_int <= std_logic_vector(calc_address) & "00";
            OUT_FIFO32_S_Fill_int <= std_logic_vector(to_unsigned(to_integer(unsigned(IN_FIFO32_S_Fill)) + 1, 16));
          end if;
          
        when STATE_DATA_READ =>
          -- Waits until current data chunk has been read.
          if OUT_FIFO32_M_Wr = '1' then
            remaining_size := remaining_size - 1;
            calc_size     := calc_size - 1;
          end if;
          if remaining_size = 0 then
            state := STATE_IDLE;
          elsif calc_size = 0 then
            state := STATE_CALC;
          end if;
          -- While in read mode, we signal to the next module in chain, that no
          -- new words are available for reading, because we can't handle
          -- parallel slave and master at the moment.
          OUT_FIFO32_S_Data_int <= (others => '0');
          OUT_FIFO32_S_Fill_int <= (others => '0');
          
        when STATE_DATA_WRITE =>
          -- Waits until current data chunk has been written.
          if OUT_FIFO32_S_Rd = '1' then
            remaining_size := remaining_size - 1;
            calc_size     := calc_size - 1;
          end if;
          if remaining_size = 0 then
            state := STATE_IDLE;
            mux_sel <= '1';
          elsif calc_size = 0 then
            state := STATE_CALC;
            mux_sel <= '1';
          end if;
          OUT_FIFO32_S_Data_int <= (others => '0');
          OUT_FIFO32_S_Fill_int <= (others => '0');
          
        when others =>
          state := STATE_IDLE;
      end case;
    end if;
  end process;

end architecture;
