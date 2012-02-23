library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity gnd2int is
	port (
		GND0 : out std_logic;
		GND1 : out std_logic;
		GND2 : out std_logic;
		GND3 : out std_logic;
		GND4 : out std_logic;
		GND5 : out std_logic;
		GND6 : out std_logic;
		GND7 : out std_logic;
		GND8 : out std_logic;
		GND9 : out std_logic;
		GNDA : out std_logic;
		GNDB : out std_logic;
		GNDC : out std_logic;
		GNDD : out std_logic;
		GNDE : out std_logic;
		GNDF : out std_logic
	);

end entity;

architecture implementation of gnd2int is
        
	attribute keep_hierarchy : string;
        attribute keep_hierarchy of implementation : architecture is "true";

begin
	GND0 <= '0';
	GND1 <= '0';
	GND2 <= '0';
	GND3 <= '0';
	GND4 <= '0';
	GND5 <= '0';
	GND6 <= '0';
	GND7 <= '0';
	GND8 <= '0';
	GND9 <= '0';
	GNDA <= '0';
	GNDB <= '0';
	GNDC <= '0';
	GNDD <= '0';
	GNDE <= '0';
	GNDF <= '0';
end architecture;

