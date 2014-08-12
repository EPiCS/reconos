library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- This module allows to look a C_FIFO32_PEEK_DEPTH words into the contents of
-- a FIFO32 module, when attached to the slave side of a fifo. It does this by
-- transparently forwarding the fifo signals and prefetching
-- C_FIFO32_PEEK_DEPTH words into internal registers. These registers are then
-- accessible via the XXXX signal. The total fifo depth of a fifo32 and
-- fifo32_peek is therefore C_FIFO32_DEPTH+C_FIFO32_PEEK_DEPTH.
--
-- Keep C_FIFO32_PEEK_DEPTH as small as possible, because resource usage grows
-- square!
entity fifo32_peek is
  generic (
    C_FIFO32_PEEK_DEPTH : integer := 3
    );
  port (
    Rst          : in std_logic;
    FIFO32_S_Clk : in std_logic;
    FIFO32_M_Clk : in std_logic;

    -- Active side: fetches data from fifo
    FIFO32_S_IN_Data : in  std_logic_vector(31 downto 0);
    FIFO32_S_IN_Fill : in  std_logic_vector(15 downto 0);
    FIFO32_S_OUT_Rd  : out std_logic;

    -- passive side: will provide data on FIFO32_S_Rd = '1'
    FIFO32_S_OUT_Data : out std_logic_vector(31 downto 0);
    FIFO32_S_OUT_Fill : out std_logic_vector(15 downto 0);
    FIFO32_S_IN_Rd    : in  std_logic;

    FIFO32_PEEK_DATA : out std_logic_vector((C_FIFO32_PEEK_DEPTH*32)-1 downto 0);
    FIFO32_PEEK_DATA_FILL : out std_logic_vector(15 downto 0)
    );
end entity;

architecture implementation of fifo32_peek is
  
  function incptr(v : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector (v'length-1 downto 0);
  begin
    if v = C_FIFO32_PEEK_DEPTH-1 then
      result := (others => '0');
    else
      result := v + 1;
    end if;
    return result;
  end;

  function sat_add (
    signal a : std_logic_vector(15 downto 0);
    signal b : std_logic_vector(15 downto 0))
    return std_logic_vector
  is
    variable a_ext  : std_logic_vector(16 downto 0);
    variable b_ext  : std_logic_vector(16 downto 0);
    variable result : std_logic_vector(16 downto 0);
  begin
    -- extend summands
    a_ext := '0' & a;
    b_ext := '0' & b;

    -- extended addition
    result := a_ext + b_ext;

    -- check for overflow and saturate
    if result(16) = '1' then
      result := (others => '1');
    end if;

    -- return non-extended part of potentially saturated result
    return result(15 downto 0);
  end function;

  type MEM_T is array (0 to C_FIFO32_PEEK_DEPTH-1) of std_logic_vector(31 downto 0);
  signal mem : MEM_T;

  signal wrptr     : std_logic_vector(clog2(C_FIFO32_PEEK_DEPTH)-1 downto 0);
  signal rdptr     : std_logic_vector(clog2(C_FIFO32_PEEK_DEPTH)-1 downto 0);
  signal remainder : std_logic_vector(clog2(C_FIFO32_PEEK_DEPTH) downto 0);
  signal fill      : std_logic_vector(clog2(C_FIFO32_PEEK_DEPTH) downto 0);
  signal pad       : std_logic_vector(14 - clog2(C_FIFO32_PEEK_DEPTH) downto 0);
  signal clk       : std_logic;

  signal INT_FIFO32_S_OUT_Rd   : std_logic;
  signal INT_FIFO32_S_OUT_DATA : std_logic_vector(31 downto 0);
  signal INT_FIFO32_S_OUT_Fill : std_logic_vector(15 downto 0);


  
begin

  PEEK_DATA : for i in 0 to C_FIFO32_PEEK_DEPTH-1 generate
    FIFO32_PEEK_DATA(((i+1)*32)-1 downto i*32) <= mem((conv_integer(rdptr)+i) mod C_FIFO32_PEEK_DEPTH);
  end generate PEEK_DATA;

  FIFO32_S_OUT_Rd   <= INT_FIFO32_S_OUT_Rd;
  FIFO32_S_OUT_Data <= INT_FIFO32_S_OUT_DATA;
  FIFO32_S_OUT_Fill <= sat_add(INT_FIFO32_S_OUT_Fill, FIFO32_S_IN_Fill) when
                         fill >  CONV_STD_LOGIC_VECTOR(0, fill'length) else
                       (others => '0');
  FIFO32_PEEK_DATA_FILL <= INT_FIFO32_S_OUT_Fill;

  clk <= FIFO32_M_Clk;

  pad <= (others => '0');

  INT_FIFO32_S_OUT_Fill <= pad & fill;


  --fillAndRemainder : process(rst, clk)
  --begin
  --  if rst = '1' then
  --    fill      <= (others => '0');
  --    remainder <= CONV_STD_LOGIC_VECTOR(C_FIFO32_PEEK_DEPTH, remainder'length);
  --  elsif rising_edge(clk) then
  --    -- FIFO empties when read
  --    if INT_FIFO32_S_OUT_Rd = '0' and FIFO32_S_IN_Rd = '1' then
  --      fill      <= fill - 1;
  --      remainder <= remainder + 1;
  --    end if;

  --    -- FIFO fills when written
  --    if INT_FIFO32_S_OUT_Rd = '1' and FIFO32_S_IN_Rd = '0' then
  --      fill      <= fill + 1;
  --      remainder <= remainder - 1;
  --    end if;

  --  -- In all other cases FIFO fill level remains the same.
  --  end if;
  --end process;

  
  -- Read signal is asynchronous to be able to directly react 
  INT_FIFO32_S_OUT_Rd      <= '0' when rst = '1' else
                              '1' when  FIFO32_S_IN_Fill /= X"0000" and
                                        remainder > CONV_STD_LOGIC_VECTOR(0, remainder'length) else
                              '0';
  -- fetches autonomously data into internal fifo until it is full
  write2ram : process(clk, rst)
  begin
    if rst = '1' then
      wrptr               <= (others => '0');

      fill      <= (others => '0');
      remainder <= CONV_STD_LOGIC_VECTOR(C_FIFO32_PEEK_DEPTH, remainder'length);

    elsif rising_edge(clk) then
      if FIFO32_S_IN_Fill /= X"0000" and remainder > CONV_STD_LOGIC_VECTOR(0, remainder'length)
 
      then
        -- Read in data
        mem(CONV_INTEGER(wrptr)) <= FIFO32_S_IN_Data;
        wrptr                    <= incptr(wrptr);

        -- FIFO fills when written
        if FIFO32_S_IN_Rd = '0' then
          fill      <= fill + 1;
          remainder <= remainder - 1;
        end if;
      else

        -- FIFO empties when read
        if FIFO32_S_IN_Rd = '1' then
          fill      <= fill - 1;
          remainder <= remainder + 1;
        end if;
      end if;
    end if;
  end process;


  INT_FIFO32_S_OUT_DATA <= mem(CONV_INTEGER(rdptr));
  readFromRam : process(clk, rst)
  begin
    if rst = '1' then
      rdptr <= (others => '0');
      
    elsif rising_edge(clk) then

      if FIFO32_S_IN_Rd = '1' then
        rdptr <= incptr(rdptr);
      end if;
    end if;
  end process;

end architecture;
