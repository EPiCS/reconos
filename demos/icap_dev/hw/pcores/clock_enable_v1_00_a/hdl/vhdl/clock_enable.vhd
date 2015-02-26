library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity clock_enable is
  port (
    clk     : in  std_logic;
    clk_en  : in  std_logic;
    clk_out : out std_logic
    );
end entity;

architecture implementation of clock_enable is
  signal ClkEnRegxSP : std_logic := '1';
begin
  -----------------------------------------------------------------------------
  -- Clock Buffer with Enable
  -----------------------------------------------------------------------------
  BUFGCE_inst : BUFGCE
    port map (
      O  => clk_out,                    -- Clock buffer ouptput
      CE => ClkEnRegxSP,                -- Clock enable input
      I  => clk                         -- Clock buffer input
      );

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  clkEnReg : process (clk)
  begin  -- process clkEnReg
    if clk'event and clk = '1' then     -- rising clock edge
      ClkEnRegxSP <= clk_en;
    end if;
  end process clkEnReg;


end architecture;
