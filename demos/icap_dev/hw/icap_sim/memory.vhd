library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;  -- read and write overloaded for std_logic
use ieee.numeric_std.all;

library std;
use std.textio.all;
use std.standard.all;

entity memory is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    addr : in  std_logic_vector(31 downto 0);
    di   : in  std_logic_vector(31 downto 0);
    do   : out std_logic_vector(31 downto 0);
    we   : in  std_logic
    );
end memory;

architecture Behavioral of memory is
  constant C_MEM_SIZE      : natural := 2048;
  constant C_ADDRESS_WIDTH : integer := 11;  -- TODO: clog2(C_MEM_SIZE);
  type     MEM_T is array (0 to C_MEM_SIZE-1) of std_logic_vector(31 downto 0);
  signal   mem             : MEM_T;

  signal memFirstValid : integer := 0;
  signal memLastValid  : integer := 0;

  file file_stim  : text open read_mode is "./partial_stim.hex";  -- open the frame file for reading
  file file_check : text open read_mode is "./partial_check.hex";  -- open the frame file for reading

  -----------------------------------------------------------------------------
  -- functions
  -----------------------------------------------------------------------------
  function to_hex_string(s : in std_logic_vector)
    return string
  is
    variable result : string (1 to s'length/4);
    --- A subtype to keep the VHDL compiler happy
    --- (the rules about data types in a CASE are quite strict)
    subtype  slv4 is std_logic_vector(1 to 4);
  begin
    assert (s'length mod 4) = 0
      report "SLV must be a multiple of 4 bits"
      severity failure;
    for i in s'length/4-1 downto 0 loop
      case slv4'(s(i*4+3 downto i*4)) is
        when "0000" => result(i+1) := '0';
        when "0001" => result(i+1) := '1';
        when "0010" => result(i+1) := '2';
        when "0011" => result(i+1) := '3';
        when "0100" => result(i+1) := '4';
        when "0101" => result(i+1) := '5';
        when "0110" => result(i+1) := '6';
        when "0111" => result(i+1) := '7';
        when "1000" => result(i+1) := '8';
        when "1001" => result(i+1) := '9';
        when "1010" => result(i+1) := 'A';
        when "1011" => result(i+1) := 'B';
        when "1100" => result(i+1) := 'C';
        when "1101" => result(i+1) := 'D';
        when "1110" => result(i+1) := 'E';
        when "1111" => result(i+1) := 'F';
        when others => result(i+1) := 'x';
      end case;
    end loop;
    return result;
  end;
begin

  do <= mem(to_integer(unsigned(addr(C_ADDRESS_WIDTH-1 downto 0))));

  process(clk, rst)
    variable i       : natural := 0;
    variable j       : natural := 0;
    variable line    : line;
    variable vec     : std_logic_vector(31 downto 0);
    variable read_ok : boolean;
  begin
    if rising_edge(clk) then
      if we = '0' then
        -----------------------------------------------------------------------
        -- read access
        -----------------------------------------------------------------------
        if addr /= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" and to_integer(unsigned(addr)) < memFirstValid then
          report "Memory access does not seem to be sequential, only sequential memory access is supported"
            severity failure;
        end if;

        if to_integer(unsigned(addr)) >= memLastValid and not (endfile(file_stim)) then
          -----------------------------------------------------------------------------
          -- read from bit file and place it in memory
          -----------------------------------------------------------------------------
          i := 0;

          readLoop : while not (endfile(file_stim)) and i < C_MEM_SIZE loop
            readline(file_stim, line);
            hread(line, vec, read_ok);
            mem(i) <= vec;

            i := i + 1;
          end loop readLoop;

          -- TODO
          --        if to_integer(unsigned(addr)) >= memLastvalid + i then
          --          report "Memory access does not seem to be sequential, only sequential memory access is supported"
          --            severity failure;
          --        end if;

          memFirstValid <= memLastValid;
          memLastValid  <= memLastValid + i;

          report "Memory reloaded" severity note;
        end if;
      elsif we = '1' then
        -----------------------------------------------------------------------
        -- write access
        -----------------------------------------------------------------------
        mem(to_integer(unsigned(addr(C_ADDRESS_WIDTH-1 downto 0)))) <= di;

        if endfile(file_check) then
          report "End of response file reached" severity failure;
        end if;

        -- check with bit file if this is correct
        readline(file_check, line);
        hread(line, vec, read_ok);

        if vec /= di then
          report "not equal" severity note;
          report "bitstream not equal, is " & to_hex_string(di)
            & " while expected " & to_hex_string(vec) severity note;
        end if;

        if endfile(file_check) then
          report "This was the last response" severity note;
        end if;

        if to_integer(unsigned(addr)) /= j then
          report "Write access is not sequential, this testbench can only handle sequential ram access" &
            integer'image(j)
            severity note;
        end if;

        j := j + 1;
      end if;

    end if;
  end process;

end Behavioral;
