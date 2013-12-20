--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - FIFO
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  A simple unidirectional FIFO accessible on both sides
--                 from the hardware via the known FIFO interface.
--
--                 REMARK: Different clocks for FIFO-Rd and FIFO-Wr are
--                         not supported yet. FIFO_S_Clk is used and
--                         FIFO_M_Clk are just added for the future.
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;


entity reconos_fifo is
	generic (
		-- FIFO parameters
		C_FIFO_DEPTH   : integer   := 32;
		C_FIFO_WIDTH   : integer   := 32
	);
	port (
		-- FIFO ports
		FIFO_S_Clk    : in  std_logic;
		FIFO_S_Data   : out std_logic_vector(31 downto 0);
		FIFO_S_Fill   : out std_logic_vector(15 downto 0);
		FIFO_S_Empty  : out std_logic;
		FIFO_S_RE     : in  std_logic;

		FIFO_M_Clk    : in  std_logic;
		FIFO_M_Data   : in  std_logic_vector(31 downto 0);
		FIFO_M_Rem    : out std_logic_vector(15 downto 0);
		FIFO_M_Full   : out std_logic;
		FIFO_M_WE     : in  std_logic;

		FIFO_Rst      : in  std_logic;

		FIFO_Has_Data : out std_logic
	);

	attribute MAX_FANOUT   : string;
	attribute SIGIS        : string;

	attribute SIGIS of FIFO_S_Clk    : signal is "Clk";
	attribute SIGIS of FIFO_M_Clk    : signal is "Clk";
	attribute SIGIS of FIFO_Rst      : signal is "Rst";
	attribute SIGIS of FIFO_Has_Data : signal is "Intr_Level_High";

end entity reconos_fifo;


architecture implementation of reconos_fifo is

	-- Definition of FIFO-Memory
	-- No Block-RAM because the FIFO depth should be small (around 32)
	type MEM_T is array (0 to C_FIFO_DEPTH - 1) of std_logic_vector(31 downto 0);
	signal fifo   : MEM_T;
	
	signal m_wrptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal s_rdptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal s_fill    : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal m_rem     : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal s_empty   : std_logic;
	signal m_full    : std_logic;
	
	signal s_dout    : std_logic_vector(31 downto 0);
	signal m_din     : std_logic_vector(31 downto 0);

	signal pad_16   : std_logic_vector(15 - clog2(C_FIFO_DEPTH) downto 0);

	signal clk   : std_logic;
	signal rst   : std_logic;

begin
	-- this has the intended effect in sythesis (it is infact the same signal)
	-- but causes a different behaviour in simulation
	clk <= FIFO_S_Clk;
	rst <= FIFO_Rst;
	pad_16 <= (others => '0');

	FIFO_Has_Data <= not s_empty;
	
	FIFO_S_Data <= s_dout;
	m_din <= FIFO_M_Data;
	
	FIFO_S_Fill <= pad_16 & s_fill;
	FIFO_M_Rem  <= pad_16 & m_rem;
	
	FIFO_S_Empty  <= s_empty;
	FIFO_M_Full   <= m_full;

	s_fill <= m_wrptr - s_rdptr - 1;
	m_rem  <= s_rdptr - m_wrptr - 1;

fifo_proc : process(clk,rst) is
	begin
		if rst = '1' then
			s_rdptr <= (others => '0');
			m_wrptr <= (others => '0');
			s_empty <= '1';
			m_full  <= '0';
		elsif rising_edge(clk) then		
			-- writing into fifo which is not full
			if FIFO_M_WE = '1' and m_full = '0' then
				fifo(CONV_INTEGER(m_wrptr)) <= m_din;
				m_wrptr <= m_wrptr + 1;
				
				if or_reduce(m_rem) = '0' then
					m_full <= '1';
				end if;
			
				-- since reading from an empty FIFO has no effect
				-- after writing into a FIFO its never empty
				s_empty <= '0';
			end if;
			
			-- reading from fifo which is not empty
			if FIFO_S_RE = '1' and s_empty = '0' then
				s_rdptr <= s_rdptr + 1;
				
				if or_reduce(s_fill) = '0' then
					s_empty <= '1';
				end if;
				
				-- since writing into a full FIFO has no effect
				-- after reading from a FIFO its never full
				m_full <= '0';
			end if;

			-- do not change status if reading and writing concurrently
			if     (FIFO_M_WE = '1' and m_full = '0')
			   and (FIFO_S_RE = '1' and s_empty = '0') then
				s_empty <= s_empty;
				m_full  <= m_full;
			end if;
		end if;
	end process fifo_proc;

	s_dout <= fifo(CONV_INTEGER(s_rdptr));

end implementation;
