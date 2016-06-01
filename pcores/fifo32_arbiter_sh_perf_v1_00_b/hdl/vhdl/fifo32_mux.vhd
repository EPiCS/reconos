

-- @module : fifo32_mux
-- @author : meise
-- @date   : 23.05.2016


library ieee;
use ieee.std_logic_1164.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32_mux is
generic (FIFO32_PORTS     : integer := 16); 
port (
    -- Multiple FIFO32 Inputs
    IN_FIFO32_S_Data : in std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_S_Fill : in std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_S_Rd   : out std_logic_vector(FIFO32_PORTS-1 downto 0);

    IN_FIFO32_M_Data : out std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_M_Rem  : in  std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    IN_FIFO32_M_Wr   : out std_logic_vector(FIFO32_PORTS-1 downto 0);

    -- Single FIFO32 Output
    OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic;

    OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic;
    
    SEL : in std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0)
    ); 
     
end fifo32_mux;     
        

architecture synth of fifo32_mux is
               
begin  

  mux_S_DATA : entity work.mux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_S_Data,
      sel    => SEL,
      output => OUT_FIFO32_S_DATA
      );   

  mux_S_FILL : entity work.mux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_S_FILL,
      sel    => SEL,
      output => OUT_FIFO32_S_Fill
      );   

  demux_S_Rd : entity work.demux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input(0) => OUT_FIFO32_S_Rd,
      sel      => SEL,
      output   => IN_FIFO32_S_Rd
      );   

  -- Master part of fifo link

  demux_M_Data : entity work.demux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => OUT_FIFO32_M_Data,
      sel    => SEL,
      output => IN_FIFO32_M_Data
      );   

  mux_M_Rem : entity work.mux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_M_Rem,
      sel    => SEL,
      output => OUT_FIFO32_M_Rem
      );   

  demux_M_Wr : entity work.demux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input(0) => OUT_FIFO32_M_Wr,
      sel      => SEL,
      output   => IN_FIFO32_M_Wr
      );   

end synth;








