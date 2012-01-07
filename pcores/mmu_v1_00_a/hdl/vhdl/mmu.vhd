library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library mmu_v1_00_a;
use mmu_v1_00_a.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity mmu is
	generic (
		C_ENABLE_ILA : integer := 0;
		C_TLB_SIZE   : integer := 32
	);
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
	
		retry         : in std_logic;
		page_fault    : out std_logic;
		fault_addr    : out std_logic_vector(31 downto 0);
		tlb_hits      : out std_logic_vector(31 downto 0);
		tlb_misses    : out std_logic_vector(31 downto 0);
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
		DATA : IN STD_LOGIC_VECTOR(524 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	end component;
	
	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal DATA    : STD_LOGIC_VECTOR(524 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	signal HWT_FIFO32_M_Data_dup : std_logic_vector(31 downto 0);
	signal MEM_FIFO32_S_Data_dup : std_logic_vector(31 downto 0);
	signal HWT_FIFO32_S_Rd_dup   : std_logic;
	signal HWT_FIFO32_M_Wr_dup   : std_logic;
	signal MEM_FIFO32_S_Fill_dup : std_logic_vector(15 downto 0);
	signal MEM_FIFO32_M_Rem_dup  : std_logic_vector(15 downto 0);
	signal page_fault_dup        : std_logic;
	signal fault_addr_dup        : std_logic_vector(31 downto 0);

	type STATE_TYPE is (STATE_WAIT_HEADER, STATE_READ_CMD, STATE_READ_ADDR, STATE_READ_PGDE_0, STATE_READ_PGDE_1, STATE_READ_PGDE_2,
	                    STATE_READ_PTE_0,STATE_READ_PTE_1,STATE_READ_PTE_2, STATE_WRITE_HEADER_0, STATE_WRITE_HEADER_1, STATE_COPY,
							  STATE_PAGE_FAULT);
	
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

	signal tlb_tag   : std_logic_vector(19 downto 0);
	signal tlb_di    : std_logic_vector(19 downto 0);
	signal tlb_do    : std_logic_vector(19 downto 0);
	signal tlb_we    : std_logic;
	signal tlb_match : std_logic;

	signal tlb_hits_dup   : std_logic_vector(31 downto 0);
	signal tlb_misses_dup : std_logic_vector(31 downto 0);
	

begin

--------------------- CHIPSCOPE -------------------------
	
	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

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

	end generate;
	
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
	DATA(491) <= page_fault_dup;
	DATA(492) <= retry;

	DATA(524 downto 493) <= fault_addr_dup;
	--DATA(1023 downto 525) <= (others => '0');
	
	TRIG(14 downto 0) <= HWT_FIFO32_S_Fill(14 downto 0);
	TRIG(15) <= retry;

	
---------------------------------------------------------

	HWT_FIFO32_S_Clk <= clk;
	HWT_FIFO32_M_Clk <= clk;

	HWT_FIFO32_M_Data <= HWT_FIFO32_M_Data_dup;
	HWT_FIFO32_S_Rd   <= HWT_FIFO32_S_Rd_dup;
	HWT_FIFO32_M_Wr   <= HWT_FIFO32_M_Wr_dup;
	MEM_FIFO32_S_Data <= MEM_FIFO32_S_Data_dup;
	MEM_FIFO32_S_Fill <= MEM_FIFO32_S_Fill_dup;
	MEM_FIFO32_M_Rem  <= MEM_FIFO32_M_Rem_dup;
	fault_addr        <= fault_addr_dup;
	page_fault        <= page_fault_dup;
	
	pgde_addr <= "00" &  pgd(29 downto 12) & vaddr(31 downto 22) & "00";
	pte_addr  <= "00" & pgde(29 downto 12) & vaddr(21 downto 12) & "00";
	paddr     <= pte(31 downto 12) & vaddr(11 downto 0);

	tlb_hits   <= tlb_hits_dup;
	tlb_misses <= tlb_misses_dup;

	HWT_FIFO32_S_Clk <= clk;
	HWT_FIFO32_M_Clk <= clk;
	
	ctrl_proc : process(clk) is
	begin
	end process;

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
	
	pt_walk : process (clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			HWT_S_Rd <= '0';
			HWT_M_Wr <= '0';
			MEM_S_Data <= (others => '0');
			MEM_S_Fill <= (others => '0');
			MEM_M_Rem <= x"0001";
			state <= STATE_WAIT_HEADER;
			counter <= (others => '0');
			copy <= '0';
			len <= (others => '0');
			cmd <= (others => '0');
			pgde <= (others => '0');
			pte <= (others => '0');
			vaddr <= (others => '0');
			page_fault_dup <= '0';
			tlb_we <= '0';
			tlb_hits_dup <= (others => '0');
			tlb_misses_dup <= (others => '0');
			fault_addr_dup <= (others => '0');
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
					if tlb_match = '1' then
						tlb_hits_dup <= tlb_hits_dup + 1;
						pte(31 downto 12) <= tlb_do;
						state <= STATE_WRITE_HEADER_0;
					else
						MEM_S_Fill <= x"0002";
						MEM_S_Data <= x"00000004";
						if MEM_FIFO32_S_Rd = '1' then
							MEM_S_Fill <= x"0001";
							MEM_S_Data <= pgde_addr;
							tlb_misses_dup <= tlb_misses_dup + 1;
							state <= STATE_READ_PGDE_1;
						end if;
					end if;
				
				when STATE_READ_PGDE_1 =>
					if MEM_FIFO32_S_Rd = '1' then
						MEM_S_Fill <= x"0000";
						state <= STATE_READ_PGDE_2;
					end if;
					
				when STATE_READ_PGDE_2 =>
					if MEM_FIFO32_M_Wr = '1' then
						pgde <= MEM_FIFO32_M_Data;
						if MEM_FIFO32_M_DATA = x"00000000" then
							state <= STATE_PAGE_FAULT;
						else
							state <= STATE_READ_PTE_0;
						end if;
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
						if MEM_FIFO32_M_Data(1) = '0' then
							state <= STATE_PAGE_FAULT;
						else
							tlb_we <= '1';
							state <= STATE_WRITE_HEADER_0;
						end if;
					end if;
					
				when STATE_WRITE_HEADER_0 =>
					tlb_we <= '0';
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
	
				when STATE_PAGE_FAULT =>
					page_fault_dup <= '1';
					fault_addr_dup <= vaddr;
					if retry = '1' then
						page_fault_dup <= '0';
						state <= STATE_READ_PGDE_0;
					end if;
					
			end case;
		end if;
	end process;

	tlb_tag <= vaddr(31 downto 12);
	tlb_di  <= paddr(31 downto 12);

	tlb_gen : if C_TLB_SIZE > 0 generate
		tlb_i : entity mmu_v1_00_a.tlb
		generic map (
			C_TLB_LOGSIZE => clog2(C_TLB_SIZE),
			C_TAG_SIZE => 20,
			C_DATA_SIZE => 20
		)
		port map (
			clk        => clk,
			rst        => rst,
			tag        => tlb_tag,
			di         => tlb_di,
			do         => tlb_do,
			we         => tlb_we,
			match      => tlb_match
		);
	end generate;

end architecture;

-- These are the PTE flags as defined in arch/microblaze/include/asm/pgtable.h
--
-- /* Definitions for MicroBlaze. */
-- #define _PAGE_GUARDED   0x001   /* G: page is guarded from prefetch */
-- #define _PAGE_FILE      0x001   /* when !present: nonlinear file mapping */
-- #define _PAGE_PRESENT   0x002   /* software: PTE contains a translation */
-- #define _PAGE_NO_CACHE  0x004   /* I: caching is inhibited */
-- #define _PAGE_WRITETHRU 0x008   /* W: caching is write-through */
-- #define _PAGE_USER      0x010   /* matches one of the zone permission bits */
-- #define _PAGE_RW        0x040   /* software: Writes permitted */
-- #define _PAGE_DIRTY     0x080   /* software: dirty page */
-- #define _PAGE_HWWRITE   0x100   /* hardware: Dirty & RW, set in exception */
-- #define _PAGE_HWEXEC    0x200   /* hardware: EX permission */
-- #define _PAGE_ACCESSED  0x400   /* software: R: page referenced */


-- This is the TLB data miss exception handler taken straight from the microblaze kernel
-- sources (arch/microblaze/kernel/hw_exception_handler.S) We are basically doing the
-- same in hardware:
--
--        /* 0x12 - Data TLB Miss Exception
--         * As the name implies, translation is not in the MMU, so search the
--         * page tables and fix it. The only purpose of this function is to
--         * load TLB entries from the page table if they exist.
--         */
--        handle_data_tlb_miss_exception:
--                /* Working registers already saved: R3, R4, R5, R6
--                 * R3 = EAR, R4 = ESR
--                 */
--                mfs     r11, rpid
--                nop
--
--                /* If we are faulting a kernel address, we have to use the
--                 * kernel page tables. */
--                ori     r6, r0, CONFIG_KERNEL_START
--                cmpu    r4, r3, r6
--                bgti    r4, ex5
--                ori     r4, r0, swapper_pg_dir
--                mts     rpid, r0                /* TLB will have 0 TID */
--                nop
--                bri     ex6
--
--               /* Get the PGD for the current thread. */
--        ex5:
--                /* get current task address */
--                addi    r4 ,CURRENT_TASK, TOPHYS(0);
--                lwi     r4, r4, TASK_THREAD+PGDIR
--        ex6:
--                tophys(r4,r4)
--                BSRLI(r5,r3,20)         /* Create L1 (pgdir/pmd) address */
--                andi    r5, r5, 0xffc
--/* Assume pgdir aligned on 4K boundary, no need for "andi r4,r4,0xfffff003" */
--                or      r4, r4, r5
--                lwi     r4, r4, 0               /* Get L1 entry */
--                andi    r5, r4, 0xfffff000 /* Extract L2 (pte) base address */
--                beqi    r5, ex7                 /* Bail if no table */
--                tophys(r5,r5)
--                BSRLI(r6,r3,10)                 /* Compute PTE address */
--                andi    r6, r6, 0xffc
--                andi    r5, r5, 0xfffff003
--                or      r5, r5, r6
--                lwi     r4, r5, 0               /* Get Linux PTE */
--
--                andi    r6, r4, _PAGE_PRESENT
--                beqi    r6, ex7
--
--                ori     r4, r4, _PAGE_ACCESSED
--                swi     r4, r5, 0
--
--                /* Most of the Linux PTE is ready to load into the TLB LO.
--                 * We set ZSEL, where only the LS-bit determines user access.
--                 * We set execute, because we don't have the granularity to
--                 * properly set this at the page level (Linux problem).
--                 * If shared is set, we cause a zero PID->TID load.
--                 * Many of these bits are software only. Bits we don't set
--                 * here we (properly should) assume have the appropriate value.
--                 */
--                brid    finish_tlb_load
--                andni   r4, r4, 0x0ce2          /* Make sure 20, 21 are zero */
--        ex7:
--                /* The bailout. Restore registers to pre-exception conditions
--                 * and call the heavyweights to help us out.
--                 */
--                mts     rpid, r11
--                nop
--                bri     4
--                RESTORE_STATE;
--                bri     page_fault_data_trap


