

-- @module : fifo32_demux
-- @author : meise
-- @date   : 23.05.2016


library ieee;
use ieee.std_logic_1164.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32_demux is 
generic (FIFO32_PORTS     : integer := 16); 
port (
    -- Single FIFO32 Input
    IN_FIFO32_S_Data : in std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill : in std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd   : out std_logic;

    IN_FIFO32_M_Data : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr   : out std_logic;

    -- Multiple FIFO32 Outputs
    OUT_FIFO32_S_Data : out std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic_vector(FIFO32_PORTS-1 downto 0);

    OUT_FIFO32_M_Data : in  std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic_vector(FIFO32_PORTS-1 downto 0);
    
    SEL : in std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0)
    );
end fifo32_demux;     
        

architecture synth of fifo32_demux is
               
begin  


-- Demuxer
  demux_S_DATA : entity work.demux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_S_DATA,
      sel    => SEL,
      output => OUT_FIFO32_S_DATA
      );   

  demux_S_FILL : entity work.demux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_S_Fill,
      sel    => SEL,
      output => OUT_FIFO32_S_Fill
      );   

  mux_S_Rd : entity work.mux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input => OUT_FIFO32_S_Rd,
      sel      => SEL,
      output(0)   => IN_FIFO32_S_Rd
      );   

  -- Master part of fifo link

  mux_M_Data : entity work.mux
    generic map (
      element_width => 32,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => OUT_FIFO32_M_Data,
      sel    => SEL,
      output => IN_FIFO32_M_Data
      );   

  demux_M_Rem : entity work.demux
    generic map (
      element_width => 16,
      element_count => FIFO32_PORTS
      )
    port map (
      input  => IN_FIFO32_M_Rem,
      sel    => SEL,
      output => OUT_FIFO32_M_Rem
      );   

  mux_M_Wr : entity work.mux
    generic map (
      element_width => 1,
      element_count => FIFO32_PORTS
      )
    port map (
      input => OUT_FIFO32_M_Wr,
      sel      => SEL,
      output(0)   => IN_FIFO32_M_Wr
      );   



end synth;








