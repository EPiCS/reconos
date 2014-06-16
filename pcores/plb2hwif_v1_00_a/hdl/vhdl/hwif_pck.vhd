library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package hwif_pck is
  constant C_SLV_DWIDTH : natural := 32;
  
  type master2slave_t is record
    address: std_logic_vector(0 to 31);
    data_in: std_logic_vector(C_SLV_DWIDTH-1 downto 0);  
    write_ce: std_logic;
    read_ce:  std_logic;
  end record;
  
  type slave2master_t is record
    data_out:  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    write_ack: std_logic;
    read_ack:  std_logic;
  end record;
  
  type master2slave_array_t is array (integer range<>) of master2slave_t;
  type slave2master_array_t is array (integer range<>) of slave2master_t;

  constant M2S_ALL_ZEROS : master2slave_t := ((others=>'0'), (others=>'0'), '0', '0');
  constant S2M_ALL_ZEROS : slave2master_t := ((others=>'0'), '0', '0');

  -- Submodule IDs
  constant C_ID_PERFMON  : std_logic_vector(31 downto 0) := X"DEADAFFE";
  constant C_ID_IDENTITY : std_logic_vector(31 downto 0) := X"DEADBEEF";

  -- Hardware thread IDs
  constant C_ID_SORT_DEMO_RQ : std_logic_vector(31 downto 0) := X"DEADDEAD";
  constant C_ID_ARBITER : std_logic_vector(31 downto 0) := X"BA5EB055";

  constant C_CAP_PERFMON : std_logic_vector(31 downto 0) := X"00000001";
  
  function ceil_power_of_2(x : natural) return natural;
  
end hwif_pck;

package body hwif_pck is

  -- Used to calculate how much address space your submdoule needs.
  -- If you need 6 registers (x=6), this function will return 3, because 
  -- 8 would be the next biggest power of two and 2^3 = 8.
  function ceil_power_of_2(x : natural) return natural
  is
    variable i : natural := 0;
  begin
    while 2**i < x loop
      i := i+1;
    end loop;
    return i;
  end function;
  
end hwif_pck;
