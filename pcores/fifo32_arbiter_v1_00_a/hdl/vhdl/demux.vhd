----------------------------------------------------------------------------------
-- Company: Universität Paderborn, AG Datentechnik 
-- Engineer: Sebastian Meisner (meise@upb.de)
-- 
-- Create Date:    18:45:04 03/16/2007 
-- Design Name: 
-- Module Name:    mux - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision:
-- Revision 0.05 - Sebastian Meisner, 02.04.09:
--                  - changed behavior of register 0: it is now always '0' and
--                    updates to it are discarded
-- Revision 0.04 - Sebastian Meisner, 11.03.09:
--                  - generalised demux, number of outputs now controllable via
--                    mux_width generic
--                  - added async reset
--                  - addes doxygen documentation
-- Revision 0.03 - Sebastian Meisner, 09.03.09:
--                  - removed reset of registers, saves a lot of logic ressources
-- Revision 0.02 - Sebastian Meisner, 05.11.08: 
--                  - Mux uses constants now, constants imported from pack_switch.vhd
--                  - cleaned up code and rewrote mux: looks better now and works the same :-)
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--
--
-- Constants defined in pack_switch.vhd.
-- 
----------------------------------------------------------------------------------

-- Doxygen:
--! @file demux.vhd
--! @brief Generalised demultiplexer with registered outputs and asynchronous reset


library ieee;              --! Use the standard IEEE libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;


--! @brief Entity of the generalised demultiplexer
entity demux is
  generic (
    element_width : positive := 32;  --! The width in bits of the input and output ports
    element_count : positive := 16       --! Demux to how many ports?
    );

  port (
    sel    : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! Select signal: which output register shall be updated?
    input  : in  std_logic_vector(element_width-1 downto 0);  --! Data input
    output : out std_logic_vector(element_width*element_count-1 downto 0)  --! Data output
    );
end entity;

--! @brief Architecture of of the generalised demultiplexer
architecture Behavioral of demux is

begin

  --! @brief These assignments update the outputs of the entity.
  update_outputs : process (sel, input)
    variable index : natural;
  begin
    index := to_integer(unsigned(sel));

    for i in 0 to element_count-1 loop
      if i = index then
          output(element_width*(i+1)-1 downto element_width*i) <= input;
      else
          output(element_width*(i+1)-1 downto element_width*i) <= (others => '0');
      end if;
    end loop;
  end process;

end architecture;


