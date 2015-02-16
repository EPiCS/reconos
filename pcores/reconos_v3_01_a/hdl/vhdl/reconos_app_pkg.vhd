--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        VHDL App Package - ReconOS
--
--   project:      ReconOS
--   author:       Enno Lübbers, University of Paderborn
--                 Andreas Agne, University of Paderborn
--                 Christoph Rüthing, University of Paderborn
--   description:  Auto-generated application specific package.
--
-- ======================================================================

<<reconos_preproc>>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package reconos_app_pkg is
	<<generate for RESOURCES>>
	constant <<FqnUpper>> : std_logic_vector(31 downto 0) := x"<<HexId>>";
	<<end generate>>
end package reconos_app_pkg;