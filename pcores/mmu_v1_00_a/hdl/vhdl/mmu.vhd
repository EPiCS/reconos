library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity mmu is
	port (
		-- FIFO Interface to HWT
		HWT_FIFO32_S_Clk : out std_logic;
		HWT_FIFO32_M_Clk : out std_logic;
		HWT_FIFO32_S_Data : in std_logic_vector(31 downto 0);
		HWT_FIFO32_M_Data : out std_logic_vector(31 downto 0);
		HWT_FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		HWT_FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		HWT_FIFO32_S_Rd : out std_logic;
		HWT_FIFO32_M_Wr : out std_logic;
		
		-- FIFO interface to memory
		MEM_FIFO32_S_Clk : in std_logic;
		MEM_FIFO32_M_Clk : in std_logic;
		MEM_FIFO32_S_Data : out std_logic_vector(31 downto 0);
		MEM_FIFO32_M_Data : in std_logic_vector(31 downto 0);
		MEM_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
		MEM_FIFO32_M_Rem : out std_logic_vector(15 downto 0);
		MEM_FIFO32_S_Rd : in std_logic;
		MEM_FIFO32_M_Wr : in std_logic;
	
		pgd           : in std_logic_vector(31 downto 0);
		rst           : in std_logic;
		clk           : in std_logic
	);

end entity;

architecture implementation of mmu is
        
	attribute keep_hierarchy : string;
        attribute keep_hierarchy of implementation : architecture is "true";

	component mmu_icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
	end component;

	component mmu_ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	end component;
	
	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal DATA    : STD_LOGIC_VECTOR(511 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	signal HWT_FIFO32_M_Data_dup : std_logic_vector(31 downto 0);
	signal MEM_FIFO32_S_Data_dup : std_logic_vector(31 downto 0);
	signal HWT_FIFO32_S_Rd_dup   : std_logic;
	signal HWT_FIFO32_M_Wr_dup   : std_logic;
	signal MEM_FIFO32_S_Fill_dup : std_logic_vector(15 downto 0);
	signal MEM_FIFO32_M_Rem_dup  : std_logic_vector(15 downto 0);
	

	type STATE_TYPE is (STATE_WAIT_HEADER, STATE_READ_CMD, STATE_READ_ADDR, STATE_READ_PGDE_0, STATE_READ_PGDE_1, STATE_READ_PGDE_2,
	                    STATE_READ_PTE_0,STATE_READ_PTE_1,STATE_READ_PTE_2, STATE_WRITE_HEADER_0, STATE_WRITE_HEADER_1, STATE_COPY);
	
	signal state     : STATE_TYPE;
	
	signal HWT_M_Data     : std_logic_vector(31 downto 0);
	signal MEM_S_Data     : std_logic_vector(31 downto 0);
	signal HWT_S_Rd       : std_logic;
	signal HWT_M_Wr       : std_logic;
	signal MEM_S_Fill     : std_logic_vector(15 downto 0);
	signal MEM_M_Rem      : std_logic_vector(15 downto 0);
	
	
	signal vaddr     : std_logic_vector(31 downto 0);
	signal pgde_addr : std_logic_vector(31 downto 0);
	signal pte_addr  : std_logic_vector(31 downto 0);
	signal paddr     : std_logic_vector(31 downto 0);
	
	signal pgde      : std_logic_vector(31 downto 0);
	signal pte       : std_logic_vector(31 downto 0);
	
	signal len       : std_logic_vector(23 downto 0);
	signal counter   : std_logic_vector(23 downto 0);
	signal cmd       : std_logic_vector(7 downto 0);
	signal copy      : std_logic;
begin

--------------------- CHIPSCOPE -------------------------
	
	icon_i : mmu_icon
	port map (
		CONTROL0 => CONTROL
	);
	
	ila_i : mmu_ila
	port map (
		CONTROL => CONTROL,
		CLK => clk,
		DATA => DATA,
		TRIG0 => TRIG
	);
	
	DATA(31 downto 0)  <= HWT_FIFO32_S_Data;
	DATA(63 downto 32) <= HWT_FIFO32_M_Data_dup;
	DATA(79 downto 64) <= HWT_FIFO32_S_Fill;
	DATA(95 downto 80) <= HWT_FIFO32_M_Rem;
	DATA(96) <= HWT_FIFO32_S_Rd_dup;
	DATA(97) <= HWT_FIFO32_M_Wr_dup;
	
	DATA(129 downto 98) <= MEM_FIFO32_S_Data_dup;
	DATA(161 downto 130) <= MEM_FIFO32_M_Data;
	DATA(177 downto 162) <= MEM_FIFO32_S_Fill_dup;
	DATA(193 downto 178) <= MEM_FIFO32_M_Rem_dup;
	DATA(194) <= MEM_FIFO32_S_Rd;
	DATA(195) <= MEM_FIFO32_M_Wr;
	
	DATA(227 downto 196) <= pgd;
	DATA(228) <= rst;
	
	DATA(229) <= '1' when state = STATE_WAIT_HEADER else '0';
	DATA(230) <= '1' when state = STATE_READ_CMD else '0';
	DATA(231) <= '1' when state = STATE_READ_ADDR else '0';
	DATA(232) <= '1' when state = STATE_READ_PGDE_0 else '0';
	DATA(233) <= '1' when state = STATE_READ_PGDE_1 else '0';
	DATA(234) <= '1' when state = STATE_READ_PGDE_2 else '0';
	DATA(235) <= '1' when state = STATE_READ_PTE_0 else '0';
	DATA(236) <= '1' when state = STATE_READ_PTE_1 else '0';
	DATA(237) <= '1' when state = STATE_READ_PTE_2 else '0';
	DATA(238) <= '1' when state = STATE_WRITE_HEADER_0 else '0';
	DATA(239) <= '1' when state = STATE_WRITE_HEADER_1 else '0';
	DATA(240) <= '1' when state = STATE_COPY else '0';

	DATA(272 downto 241) <= vaddr;
	DATA(304 downto 273) <= pgde_addr;
	DATA(336 downto 305) <= pte_addr;
	DATA(368 downto 337) <= paddr;
	
	DATA(401 downto 370) <= pgde;
	DATA(433 downto 402) <= pte;
	DATA(457 downto 434) <= len;
	DATA(481 downto 458) <= counter;
	DATA(489 downto 482) <= cmd;
	DATA(490) <= copy;
	DATA(511 downto 491) <= (others => '0');
	
	TRIG <= HWT_FIFO32_S_Fill;

	
---------------------------------------------------------

	HWT_FIFO32_S_Clk <= clk;
	HWT_FIFO32_M_Clk <= clk;

	HWT_FIFO32_M_Data <= HWT_FIFO32_M_Data_dup;
	HWT_FIFO32_S_Rd   <= HWT_FIFO32_S_Rd_dup;
	HWT_FIFO32_M_Wr   <= HWT_FIFO32_M_Wr_dup;
	MEM_FIFO32_S_Data <= MEM_FIFO32_S_Data_dup;
	MEM_FIFO32_S_Fill <= MEM_FIFO32_S_Fill_dup;
	MEM_FIFO32_M_Rem  <= MEM_FIFO32_M_Rem_dup;

	
	pgde_addr <= "00" &  pgd(29 downto 12) & vaddr(31 downto 22) & "00";
	pte_addr  <= "00" & pgde(29 downto 12) & vaddr(21 downto 12) & "00";
	paddr     <= pte(31 downto 12) & vaddr(11 downto 0);

	HWT_FIFO32_S_Clk <= clk;
	HWT_FIFO32_M_Clk <= clk;
	
	fifo_mux : process is
	begin
		if copy = '0' then
			HWT_FIFO32_M_Data_dup <= HWT_M_Data;
			HWT_FIFO32_S_Rd_dup   <= HWT_S_Rd;
			HWT_FIFO32_M_Wr_dup   <= HWT_M_Wr;
			MEM_FIFO32_S_Data_dup <= MEM_S_Data;
			MEM_FIFO32_S_Fill_dup <= MEM_S_Fill;
			MEM_FIFO32_M_Rem_dup  <= MEM_M_Rem;
		else
			HWT_FIFO32_M_Data_dup <= MEM_FIFO32_M_Data;
			HWT_FIFO32_S_Rd_dup   <= MEM_FIFO32_S_Rd;
			HWT_FIFO32_M_Wr_dup   <= MEM_FIFO32_M_Wr;
			MEM_FIFO32_S_Data_dup <= HWT_FIFO32_S_Data;
			MEM_FIFO32_S_Fill_dup <= HWT_FIFO32_S_Fill;
			MEM_FIFO32_M_Rem_dup  <= HWT_FIFO32_M_Rem;
		end if;
	end process;
	
	process (clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			HWT_S_Rd <= '0';
			HWT_M_Wr <= '0';
			MEM_S_Data <= (others => '0');
			MEM_S_Fill <= (others => '0');
			MEM_M_Rem <= (others => '1');
			state <= STATE_WAIT_HEADER;
			counter <= (others => '0');
			copy <= '0';
			len <= (others => '0');
			cmd <= (others => '0');
			pgde <= (others => '0');
			pte <= (others => '0');
			vaddr <= (others => '0');
		elsif rising_edge(clk) then
			case state is
				when STATE_WAIT_HEADER =>
					if HWT_FIFO32_S_Fill > 1 then
						HWT_S_Rd <= '1';
						state <= STATE_READ_CMD;
					end if;
					
				when STATE_READ_CMD =>
					cmd <= HWT_FIFO32_S_Data(31 downto 24);
					len <= HWT_FIFO32_S_Data(23 downto 0);
					state <= STATE_READ_ADDR;
					
				when STATE_READ_ADDR =>
					vaddr <= HWT_FIFO32_S_Data;
					HWT_S_Rd <= '0';
					state <= STATE_READ_PGDE_0;
					
				when STATE_READ_PGDE_0 =>
					MEM_S_Fill <= x"0002";
					MEM_S_Data <= x"00000004";
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0001";
						MEM_S_Data <= pgde_addr;
						state <= STATE_READ_PGDE_1;
					end if;
				
				when STATE_READ_PGDE_1 =>
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0000";
						state <= STATE_READ_PGDE_2;
					end if;
					
				when STATE_READ_PGDE_2 =>
					if MEM_FIFO32_M_Wr = '1' then
						pgde <= MEM_FIFO32_M_Data;
						state <= STATE_READ_PTE_0;
					end if;
					
				when STATE_READ_PTE_0 =>
					MEM_S_Fill <= x"0002";
					MEM_S_Data <= x"00000004";
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0001";
						MEM_S_Data <= pte_addr;
						state <= STATE_READ_PTE_1;
					end if;
				
				when STATE_READ_PTE_1 =>
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0000";
						state <= STATE_READ_PTE_2;
					end if;
					
				when STATE_READ_PTE_2 =>
					if MEM_FIFO32_M_Wr = '1' then
						pte <= MEM_FIFO32_M_Data;
						state <= STATE_WRITE_HEADER_0;
					end if;
					
				when STATE_WRITE_HEADER_0 =>
					MEM_S_Fill <= x"0002";
					MEM_S_Data <= cmd & len;
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0001";
						MEM_S_Data <= paddr;
						state <= STATE_WRITE_HEADER_1;
					end if;
				
				when STATE_WRITE_HEADER_1 =>
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0000";
						state <= STATE_COPY;
						copy <= '1';
						counter <= (others => '0');
					end if;
					
				when STATE_COPY =>
					if MEM_FIFO32_M_Wr = '1' or MEM_FIFO32_S_Rd = '1' then
						counter <= counter + 4;
					end if;
					if counter(23 downto 2) = len(23 downto 2) then
						copy <= '0';
						state <= STATE_WAIT_HEADER;
					end if;
					
			end case;
		end if;
	end process;
	
end architecture;
