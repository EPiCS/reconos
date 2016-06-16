----------------------------------------------------------------------------------
-- Company: Universit Paderborn, Arbeitsgruppe Datentechnik
-- Engineer: Sebastian Meisner meise@upb.de
-- 
-- Create Date:    09:47:04 01/14/2009 
-- Design Name: 
-- Module Name:    rr-arbiter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This module implements a round-robin algorithm on the request inputs.
--              It consists of an Register called "last_served" that stores the index
--              of the last accepted request and an if-cascade block, that determines
--              which next request should be selected.
--              This module ensures a fair selection of request and avoids a deadlock
--              on the out_port.
--
-- Dependencies: none
--
-- Revision:
-- Revision 0.05 - Sebastian Meisner, 19.03.2009; -added doxygen documentation
-- Revision 0.04 - Removed enbale Signal:
--                 The arbiter now decides on his own, when to choose a new request.
--                 See the enable_proc process for details.
-- Revision 0.03 - Added an enable signal and got the timing right!
-- Revision 0.02 - It finally works as expected and is configurable via
--                 the generic parameter "request_width_exponent"
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

--Doxygen
--! @file rr_arbiter.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        uses a round-robin style selection mechanism.


library IEEE; --! Use the standard IEEE libraries for logic
use IEEE.STD_LOGIC_1164.all; --! For logic
use ieee.numeric_std.all; --! For signed and unsigned arithmetic.

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! @brief Entity declaration of an arbiter that
--!        uses a round-robin style selection mechanism.
--! @details If no select line is active, this entity will set the
--!          'sel' signal to the position 'request_width'. So if request_width
--!          is 5 for example and no select line is active, the 'sel' signal will be set
--!          to position 5. This position shall be used by the (de)multiplexers to go
--!          into a save state, where no data is forwarded
entity rr_arbiter is
  generic(
    request_width : positive := 16  --! How many request inputs do you want?
    );
  port (
    clk      : in  std_logic;           --! Clock signal
    reset    : in  std_logic;           --! Reset signal
    requests : in  std_logic_vector (request_width-1 downto 0);  --! Input lines from the requestors.
    sel      : out std_logic_vector (clog2(request_width)-1 downto 0));  --! Who of the requesters will be served?
end rr_arbiter;

--! @brief Architecture of an arbiter that uses a round-robin style selection mechanism.
architecture Behavioral of rr_arbiter is
  --! @brief This constant will be a number of the form 2**n. This is important for
  --! the int_requests signal.
  constant upper_bound : positive := 2**(clog2(request_width));

  --! @brief We need to extent the requests input vector, so that its width will fit
  --!        2**n.
  --! @details That is needed to wrap around the vector with a modulo
  --!          operation. Unfortunately the Xilinx synthesizer can only synthesize the
  --!          modulo operator if its operand is of the form 2**n.
  signal int_requests : std_logic_vector (upper_bound-1 downto 0);

  --! Register to save the last served requestor.
  signal last_served, next_served : natural range upper_bound-1 downto 0 := 0;

  --! @brief This signals enables the round robin process. If it is 'true', a new
  --! requestor will be choosen to be served.
  signal enable : boolean := true;
  
begin -- of architecture -------------------------------------------------------

  -- This signal assignments adopt the requests vector size to our internal int_requests vector
  -- size, which may be bigger.
  int_requests(request_width-1 downto 0)           <= requests(requests'range);
  
  -- Fill rest of the internal requests vector with zeros.
  -- This line can cause a warning messages like:
  -- WARNING:Xst:2096 - "/home/meise/svn/meise/hardware/noc/switch/switch_out_port/rr_arbiter.vhd" line 96: Use of null array slice on signal <int_requests> is not supported.
  -- Or with ISE 12.3:
  -- WARNING:HDLCompiler:746 - "/home/meise/ise_projects/fifo32_arbiter/../../git/reconos_v3/pcores/fifo32_arbiter_v1_00_a/hdl/vhdl/rr_arbiter.vhd" Line 99: Range is empty (null range)
  -- WARNING:HDLCompiler:220 - "/home/meise/ise_projects/fifo32_arbiter/../../git/reconos_v3/pcores/fifo32_arbiter_v1_00_a/hdl/vhdl/rr_arbiter.vhd" Line 99: Assignment ignored
  -- Up to now, no negative consequences of this warning message have been observed.
  int_requests(upper_bound-1 downto request_width) <= (others => '0');

  --! @brief This process controls, when the arbiter should choose a new request.
  --! @details As soon as the actually served requestor lowers his request
  --!          line, a new requestor will be chosen to be served.
  --!          When no requestor wants to send data, a new decision will be
  --!          made every clock cycle, until a request is made.
  enable_proc : process (reset, int_requests, last_served)
  begin
    if int_requests(last_served) = '0' or reset = '1'
    then
      enable <= true;
    else
      enable <= false;
    end if;
  end process;

  --! @brief This process only determines which request line is next to be served.
  --! @details This process is only activated, if 'enable' is true. See process
  --!          enable_proc. It chooses the next requestor to be served by
  --!          applying a round-robin scheme. That means that the search for the next
  --!          requestor starts at the old one, at position int_requests(last_served).
  --!         
  --! The result of this process is stored in the signal next_served.
  arbiter : process(int_requests, last_served, enable)
  begin
    if enable = true then
      for offset in 1 to upper_bound+1 loop
        --! If we worked through all request lines, and there is no request, set the output to 0.
        if offset = upper_bound+1 then
          next_served <= last_served;
          exit;
        end if;
        --! We look through all requests to find the next in turn.
        --! A modulo calculation is needed to "wrap around" the signal vector.
        if int_requests((last_served+offset) mod (upper_bound)) = '1' then
          next_served <= ((last_served+offset) mod (upper_bound));
          exit;  -- exit the for loop, as soon as we have found the first request
        end if;
      end loop;
    else
      next_served <= last_served;
    end if;
  end process arbiter;

  --! @brief This process cares about the registers, storing the last served request.
  registers : process(clk, reset, next_served)
  begin
    if clk'event and clk = '1' then
      if reset = '1' then
        last_served <= 0;
      else
        last_served <= next_served;
      end if;
    end if;
  end process;

  --! @brief This process handles the sel signal.
  --! @details As long as enable is true, that means as long as we calculate
  --!          the next request to be served, it puts the muxes into a save state.
  sel_proc : process (clk, reset, enable, next_served)
  begin
    if reset = '1' then
      -- If enable is true, then no select signal is '1'. Therefore we have
      -- to prevent, that data gets accidentally forwarded.
      -- For this reason, we set the sel line to the request_width's position,
      -- which will put all (de)multiplexers in a save state.
      sel <= (others => '0');
    elsif clk'event and clk='1' then
      sel <= std_logic_vector(to_unsigned(next_served, sel'length));
    end if;
  end process sel_proc;

end Behavioral;

