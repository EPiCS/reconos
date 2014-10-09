----------------------------------------------------------------------------------
-- Company: Universität Paderborn - AG Datentechnik
-- Engineer: Rüdiger Ibers
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
-- Revision 0.05 - Sebastian Meisner, 12.03.10:
--                      - reworked entity to not use the data_array_type for intput_array
--                      - now it is really generic
-- Revision 0.04 - Sebastian Meisner, 02.09.09:
--                      - removed warning message by removing the statement:
--                        vector((2**log2(mux_width))-1 downto mux_width) <= (others => (others =>'0'));
--                        It is unneccessary.
--                      - entity now handles error, if inputs are 'U', 'X' etc
-- Revision 0.03 - Sebastian Meisner, 11.03.09:
--                      - generalised multiplexer
--                      - added doxygen documentation
-- Revision 0.02 - Sebastian Meisner, 05.11.08: added 'Packet' input, for packet generator
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 
----------------------------------------------------------------------------------

-- Doxygen:
-- @file mux.vhd
-- @brief Contains entity and architecture of a generalised multiplexer.


library ieee; --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all; --! For logic
use ieee.numeric_std.all; --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

--! @brief Entity of the generalized multiplexer

--! @details <p>With the port_width and mux_width generics one can control the
--!          number of ports and their width.</p>
--!
--!          <p>The sel signal controls which of the inputs will be forwarded to
--!          the output. If you need something like /dev/zero, a source of '0's,
--!          then add an input by incrementing mux_width and connect the last input
--!          input(mux_width) to ground.</p>
entity mux is
  generic (
    element_width : positive := 32;  --! Width in bits of the input and output ports
    element_count  : positive := 16   --! Demux how many ports?
    );
  port (
    input : in  std_logic_vector(element_width*element_count-1 downto 0);  --! An array of input vectors
    sel         : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! The select signals to choose the input to be forwarded
    output      : out std_logic_vector(element_width-1 downto 0)  --! The output of the multiplexer
    );
end mux;

--! @brief Architecture of the generalised multiplexer
--! @details This implementation synthesizes into a multiplexer macro of XST
--!     and is therefore the most space and time efficient implementation.
--!     As we want to implement the multiplexer in a generic way, we can't
--!     use a case statement to describe its behaviour. Instead we convert the 'sel'
--!     input into an unsigned integer using the 'to_integer' conversion function and
--!     then use this number as an index to the array  'input'.
--!     But there is one problem to solve: if 'element_count' is e.g.  5 then 'sel' will have a
--!     width of 3 bit. But with 3 bit we can index 8 positions, although
--!     'input' can be indexed only up to 4! The solution is to create a
--!     temporary signal ('vector') that is always wide enough to be fully indexable
--!     by the 'sel' signal. We connect the 'input' to the lower part of the
--!     'vector' signal and set every unused index to zero. This way, if one does set
--!     'sel' to an invalid position, output will be just '0'.
architecture Behavioral of mux is

  --! @brief Internal type for forming the multiplexer inputs.
  type array_type is array ((2**sel'length)-1 downto 0) of std_logic_vector(element_width-1 downto 0);
  
  --! @brief This is a internal signal to transform the external plan
  --!        std_logic_vector into a 2 dimensional array with mus_width elements of each
  --!        element_width size.
  signal vector : array_type := (others => (others => '0'));

  --! Stores the integer value of sel.
  signal index : natural range 0 to (2**sel'length)-1 := 0;
  
begin
  --! Here we assign the input to the internal mux input array.
  input_to_array: process (input)
  begin
    -- Connect input to the lower indices of vector.
    for i in 0 to element_count-1 loop
      vector(i) <= input((element_width*(i+1))-1 downto element_width*i);
    end loop;

    -- If there are some indices left, fill them with zeros.
    -- This prevents Warning messages.
    if ((2**sel'length)-1) - element_count > 0 then
      for i in element_count to (2**sel'length)-1 loop
        vector(i) <= (others => '0');
      end loop;
    end if;    
  end process;

  --! After that, we assign to the output from the internal array.
  index <= 0 when is_X(sel) else
           to_integer(unsigned(sel));
  output <= (others => '0') when is_X(sel) else
            (others => '0') when is_X(vector(index)) else
            vector(index);
            
end Behavioral;


