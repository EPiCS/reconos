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

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity fifo32_burst_converter is
  generic (
    C_PAGE_SIZE : natural := 4096;      -- Dictated by Linux Memory Management;
                                        -- must be power of 2
    C_BURST_SIZE: natural := 2048      -- 512 words á 32 bits
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
end entity;

architecture behavioural of fifo32_burst_converter is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

begin  -- of architecture -------------------------------------------------------

    IN_FIFO32_M_Clk   <= OUT_FIFO32_M_Clk; 
    IN_FIFO32_M_Data  <= OUT_FIFO32_M_Data;
    OUT_FIFO32_M_Rem  <= IN_FIFO32_M_Rem;  
    IN_FIFO32_M_Wr    <= OUT_FIFO32_M_Wr;

    IN_FIFO32_S_Clk <= OUT_FIFO32_S_Clk;
    
  fsm_p : process (clk, rst)
    is
    type FSM_STATE_T is (STATE_MODE_LENGTH, STATE_ADDRESS, STATE_CALC_SIZE,
                         STATE_CALC_ADDRESS, STATE_DATA_READ, STATE_DATA_WRITE);
    variable state : FSM_STATE_T;

    type TRANSFER_MODE_T is (READ, WRITE);
    variable transfer_mode : TRANSFER_MODE_T;
    variable transfer_size : natural range 0 to 2**24;
    variable transfer_address : natural;
    variable next_address : natural;
    variable transfer_offset : natural;
    
    variable calc_size : natural range 0 to 2**24;
    variable calc_address : natural;
    
    function calc_transfer_size (
      constant page_size  : natural;
      constant burst_size : natural;
      constant offset     : natural;
      constant length     : natural)
      return natural
    is
      variable offset_length : natural;
      variable final_length : natural;
    begin  -- function calc_transfer_size
     offset_length := page_size - offset;
     if offset_length < burst_size then
       final_length := offset_length;
     else
       final_length := burst_size;
     end if;

     if final_length > length then
       final_length := length;
     end if;

     return final_length;
    end function;
    
  begin
    if rst = '1' then
      state         := STATE_MODE_LENGTH;
      transfer_mode := READ;
    elsif clk'event and clk = '1' then
      -- default is to hold all outputs.
      state         := state;
      transfer_mode := transfer_mode;
      transfer_size := transfer_size;
      transfer_address := transfer_address;
      transfer_offset  := transfer_offset;

      calc_size := calc_size;
      calc_address:= calc_address;

      IN_FIFO32_S_Rd <= '0';
      
      OUT_FIFO32_S_Data <= IN_FIFO32_S_Data;
      OUT_FIFO32_S_Fill <= IN_FIFO32_S_Fill;

      
      case state is
        when STATE_MODE_LENGTH =>
          -- Read in first word of header for analysis.
          -- Outputs are in "no data" state
          if to_integer(unsigned(IN_FIFO32_S_Fill)) > 1 then
            state := STATE_ADDRESS;
          end if;
          case IN_FIFO32_S_DATA(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;                 
          end case;
          -- lower 24 bits of first word are defined to be the length
          -- of the transfer.
          transfer_size := to_integer(unsigned(IN_FIFO32_S_DATA(23 downto 0)));
          IN_FIFO32_S_Rd <= '1';
          OUT_FIFO32_S_Data <= (others => '0');
          OUT_FIFO32_S_Fill <= (others => '0');
          
        when STATE_ADDRESS =>
          -- Read in second word of header for analysis.
          -- Outputs are in "no data" state          
          state:= STATE_CALC_SIZE;
          transfer_address := to_integer(unsigned(IN_FIFO32_S_DATA));
          transfer_offset  := to_integer(unsigned(IN_FIFO32_S_DATA(clog2(C_PAGE_SIZE)-1 downto 0)));
          OUT_FIFO32_S_Data <= (others => '0');
          OUT_FIFO32_S_Fill <= (others => '0');
        when STATE_CALC_SIZE =>
          -- Inputs are not read.
          -- New address and size of header is calculated and put on the outputs.
          if OUT_FIFO32_S_rd = '1' then
            state := STATE_CALC_ADDRESS;  
          end if;

          calc_size :=  calc_transfer_size(C_PAGE_SIZE, C_BURST_SIZE,transfer_offset, transfer_size);
          calc_address := next_address;
          next_address := calc_address + calc_size;
                          
          case transfer_mode is
            when READ  =>
              OUT_FIFO32_S_Data <= MEMIF_CMD_READ  or std_logic_vector(to_unsigned(calc_size,32));
            when WRITE =>
              OUT_FIFO32_S_Data <= MEMIF_CMD_WRITE or std_logic_vector(to_unsigned(calc_size,32));
          end case;
          
          
        when STATE_CALC_ADDRESS =>
          if OUT_FIFO32_S_rd = '1' then          
            case transfer_mode is
              when READ  => state := STATE_DATA_READ;
              when WRITE => state := STATE_DATA_WRITE;
            end case;
          end if;
          OUT_FIFO32_S_Data <= std_logic_vector(to_unsigned(calc_size,32));
          
        when STATE_DATA_READ =>
          if OUT_FIFO32_M_Wr = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state := STATE_MODE_LENGTH;
          end if;
          
        when STATE_DATA_WRITE =>
          if OUT_FIFO32_S_Rd = '1' then
            transfer_size := transfer_size-4;
          end if;
          if transfer_size = 0 then
            state := STATE_MODE_LENGTH;
          end if;
        when others =>
          state     := STATE_MODE_LENGTH;
      end case;
    end if;
  end process;

end architecture;
