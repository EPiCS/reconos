library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library reconos_v3_01_a;
use reconos_v3_01_a.reconos_pkg.all;

entity hwt is
	port (
		-- OSIF FIFO ports
		OSIF_Sw2Hw_Data    : in  std_logic_vector(31 downto 0);
		OSIF_Sw2Hw_Empty   : in  std_logic;
		OSIF_Sw2Hw_RE      : out std_logic;

		OSIF_Hw2Sw_Data    : out std_logic_vector(31 downto 0);
		OSIF_Hw2Sw_Full    : in  std_logic;
		OSIF_Hw2Sw_WE      : out std_logic;

		-- MEMIF FIFO ports
		MEMIF_Mem2Hwt_Data    : in  std_logic_vector(31 downto 0);
		MEMIF_Mem2Hwt_Empty   : in  std_logic;
		MEMIF_Mem2Hwt_RE      : out std_logic;

		MEMIF_Hwt2Mem_Data    : out std_logic_vector(31 downto 0);
		MEMIF_Hwt2Mem_Full    : in  std_logic;
		MEMIF_Hwt2Mem_WE      : out std_logic;

		HWT_Clk    : in  std_logic;
		HWT_Rst    : in  std_logic;
		HWT_Signal : in  std_logic
	);
end entity hwt;

architecture hwt of hwt is
	type state_type is (STATE_INIT, STATE_EXEC, STATE_EXIT);
	signal state : state_type;

	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	type ram_type is array (0 to 15) of std_logic_vector(31 downto 0);
	signal ram : ram_type := (x"AFFE0000", x"AFFE0001", x"AFFE0002", x"AFFE0003", x"AFFE0004", x"AFFE0005", x"AFFE0006", x"AFFE0007",x"AFFE0008", x"AFFE0009", x"AFFE000A", x"AFFE000B", x"AFFE000C", x"AFFE000D", x"AFFE000E", x"AFFE000F");
	signal ram_addr  : std_logic_vector(31 downto 0);
	signal ram_we    : std_logic;
	signal ram_i_data : std_logic_vector(31 downto 0);
	signal ram_o_data : std_logic_vector(31 downto 0);
	
	signal ignore   : std_logic_vector(31 downto 0);
begin
	ram_ctrl : process (HWT_Clk) is
	begin
		if rising_edge(HWT_Clk) then
			if ram_we = '1' then
				ram(to_integer(unsigned(ram_addr))) <= ram_i_data;
			else
				ram_o_data <= ram(to_integer(unsigned(ram_addr)));
			end if;
		end if;
	end process ram_ctrl;

	osif_setup (
		i_osif,
		o_osif,
		OSIF_Sw2Hw_Data,
		OSIF_Sw2Hw_Empty,
		OSIF_Sw2Hw_RE,
		OSIF_Hw2Sw_Data,
		OSIF_Hw2Sw_Full,
		OSIF_Hw2Sw_WE
	);

	memif_setup (
		i_memif,
		o_memif,
		MEMIF_Mem2Hwt_Data,
		MEMIF_Mem2Hwt_Empty,
		MEMIF_Mem2Hwt_RE,
		MEMIF_Hwt2Mem_Data,
		MEMIF_Hwt2Mem_Full,
		MEMIF_Hwt2Mem_WE
	);
	
	ram_setup (
		i_ram,
		o_ram,
		ram_addr,
		ram_i_data,
		ram_o_data,
		ram_we
	);

	os_fsm: process (HWT_Clk,HWT_Rst,o_osif,o_memif) is
		variable done  : boolean;
	begin
		if HWT_Rst = '1' then
			state <= STATE_INIT;
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
		elsif rising_edge(HWT_Clk) then
			case state is
				when STATE_INIT =>
					osif_read(i_osif, o_osif, ignore, done);
					if done then
						state <= STATE_EXEC;
					end if;

				when STATE_EXEC =>
					osif_mbox_put(i_osif, o_osif, x"00000000", x"AFFEDEAD", ignore, done);
					--osif_mbox_get(i_osif, o_osif, x"00000000", ignore, done);
					--memif_write_word(i_memif, o_memif, x"00000000", x"AFFEDEAD", done);
					--memif_read_word(i_memif, o_memif, x"00000000", ignore, done);
					--memif_read(i_ram, o_ram, i_memif, o_memif, x"00000000", x"00000000", x"00000018", done);
					--memif_write(i_ram, o_ram, i_memif, o_memif, x"00000000", x"00000010", x"00000018", done);
					if done then
						state <= STATE_EXIT;
					end if;

				when STATE_EXIT =>
					osif_thread_exit(i_osif, o_osif);
			end case;
		end if;
	end process;
	
end architecture hwt;
