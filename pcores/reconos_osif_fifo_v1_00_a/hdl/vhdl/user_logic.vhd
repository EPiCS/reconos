--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - OSIF FIFO - FIFO implementation
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  A simple bidirectional FIFO accessible from the AXI-Bus
--                 and from other hardware via the known FIFO interface.
--                 This FIFO is used to connect the hwts to the AXI-Bus
--                 and therefore to the processing system.
--                 Register Definition (as seen from Bus):
--                   Reg0: Read data
--                   Reg1: Write data
--                   Reg2: Fill - number of elements in receive-FIFO
--                   Reg3: Rem - free space in send-FIFO
--
--                 REMARK: Different clocks for AXI, FIFO-Rd and FIFO-Wr
--                         are not supported yet. S_AXI_ACKL is used and
--                         FIFO_**_Clk are just added for the future.
--
--   known issues: Because reading of the first word must happen one clock
--                 cycle after RE has been set (RE must propagate to the
--                 fifo) the bus transaction should be delayed one clock
--                 cycle too. Since one bus transaction takes longer than
--                 one clock cycle everything is totaly fine.
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;


entity user_logic is
	generic (
		-- FIFO parameters
		C_FIFO_DEPTH   : integer   := 32;

		-- Bus protocol parameters
		C_NUM_REG      : integer   := 4;
		C_SLV_DWIDTH   : integer   := 32
	);
	port (
		-- FIFO ports
		OSIF_FIFO_Sw2Hw_Clk    : in  std_logic;
		OSIF_FIFO_Sw2Hw_Data   : out std_logic_vector(31 downto 0);
		OSIF_FIFO_Sw2Hw_Fill   : out std_logic_vector(15 downto 0);
		OSIF_FIFO_Sw2Hw_Empty  : out std_logic;
		OSIF_FIFO_Sw2Hw_RE     : in  std_logic;
		
		OSIF_FIFO_Hw2Sw_Clk    : in  std_logic;
		OSIF_FIFO_Hw2Sw_Data   : in  std_logic_vector(31 downto 0);
		OSIF_FIFO_Hw2Sw_Rem    : out std_logic_vector(15 downto 0);
		OSIF_FIFO_Hw2Sw_Full   : out std_logic;
		OSIF_FIFO_Hw2Sw_WE     : in  std_logic;

		OSIF_FIFO_Rst   : in  std_logic;

		-- Bus protocol ports
		Bus2IP_Clk      : in  std_logic;
		Bus2IP_Resetn   : in  std_logic;
		Bus2IP_Data     : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		Bus2IP_BE       : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
		Bus2IP_RdCE     : in  std_logic_vector(C_NUM_REG-1 downto 0);
		Bus2IP_WrCE     : in  std_logic_vector(C_NUM_REG-1 downto 0);
		IP2Bus_Data     : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		IP2Bus_RdAck    : out std_logic;
		IP2Bus_WrAck    : out std_logic;
		IP2Bus_Error    : out std_logic;
		
		-- Interrupt for Bus (only hw2bus)
		OSIF_FIFO_Has_Data   : out std_logic
	);

	attribute MAX_FANOUT   : string;
	attribute SIGIS        : string;

	attribute SIGIS of Bus2IP_Clk           : signal is "Clk";
	attribute SIGIS of OSIF_FIFO_Sw2Hw_Clk  : signal is "Clk";
	attribute SIGIS of OSIF_FIFO_Hw2Sw_Clk  : signal is "Clk";
	attribute SIGIS of Bus2IP_Resetn        : signal is "Rst";
	attribute SIGIS of OSIF_FIFO_Rst        : signal is "Rst";
	attribute SIGIS of OSIF_FIFO_Has_Data   : signal is "Intr_Level_High";

end entity user_logic;


architecture implementation of user_logic is

	-- Definition of FIFO-Memory
	-- No Block-RAM because the FIFO depth should be small (around 32)
	type MEM_T is array (0 to C_FIFO_DEPTH - 1) of std_logic_vector(31 downto 0);
	signal hw2bus_fifo   : MEM_T;
	signal bus2hw_fifo   : MEM_T;
	
	signal hw2bus_wrptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal hw2bus_rdptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal hw2bus_fill    : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal hw2bus_rem     : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal hw2bus_empty   : std_logic;
	signal hw2bus_full    : std_logic;
	
	signal bus2hw_wrptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal bus2hw_rdptr   : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal bus2hw_fill    : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal bus2hw_rem     : std_logic_vector(clog2(C_FIFO_DEPTH) - 1 downto 0);
	signal bus2hw_empty   : std_logic;
	signal bus2hw_full    : std_logic;
	
	signal bus2hw_dout    : std_logic_vector(31 downto 0);
	signal bus2hw_din     : std_logic_vector(31 downto 0);
	signal hw2bus_dout    : std_logic_vector(31 downto 0);
	signal hw2bus_din     : std_logic_vector(31 downto 0);

	signal pad_16   : std_logic_vector(15 - clog2(C_FIFO_DEPTH) downto 0);
	signal pad_31   : std_logic_vector(30 - clog2(C_FIFO_DEPTH) downto 0);

	-- Signals for user logic slave model s/w accessible register
	signal slv_reg_write_sel   : std_logic_vector(3 downto 0);
	signal slv_reg_read_sel    : std_logic_vector(3 downto 0);
	signal slv_ip2bus_data     : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal slv_read_ack        : std_logic;
	signal slv_write_ack       : std_logic;
	
	signal clk : std_logic;
	signal rst : std_logic;

begin
	-- this has the intended effect in sythesis (it is infact the same signal)
	-- but causes a different behaviour in simulation
	clk <= Bus2Ip_Clk;
	rst <= OSIF_FIFO_Rst or not Bus2IP_Resetn;
	pad_16 <= (others => '0');
	pad_31 <= (others => '0');
	
	OSIF_FIFO_Sw2Hw_Data <= bus2hw_dout;
	hw2bus_din  <= OSIF_FIFO_Hw2Sw_Data;
	
	IP2Bus_Data <= slv_ip2bus_data;
	bus2hw_din  <= Bus2IP_Data;
	
	OSIF_FIFO_Sw2Hw_Fill <= pad_16 & bus2hw_fill;
	OSIF_FIFO_Hw2Sw_Rem  <= pad_16 & hw2bus_rem;
	
	OSIF_FIFO_Sw2Hw_Empty  <= bus2hw_empty;
	OSIF_FIFO_Hw2Sw_Full   <= hw2bus_full;
	OSIF_FIFO_Has_Data <= not hw2bus_empty;


	slv_reg_write_sel <= Bus2IP_WrCE(3 downto 0);
	slv_reg_read_sel  <= Bus2IP_RdCE(3 downto 0);
	slv_write_ack     <= or_reduce(Bus2IP_WrCE);
	slv_read_ack      <= or_reduce(Bus2IP_RdCE);

	IP2Bus_WrAck <= slv_write_ack;
	IP2Bus_RdAck <= slv_read_ack;
	IP2Bus_Error <= '0';


	fifo_hw2bus_proc : process(clk,rst) is
	begin
		if rst = '1' then
			hw2bus_rdptr <= (others => '0');
			hw2bus_wrptr <= (others => '0');
			hw2bus_fill  <= (others => '0');
			hw2bus_rem   <= (others => '1');
			hw2bus_empty <= '1';
			hw2bus_full  <= '0';
		elsif rising_edge(clk) then		
			-- writing into fifo which is not full
			if OSIF_FIFO_Hw2Sw_WE = '1' and hw2bus_full = '0' then
				hw2bus_fifo(CONV_INTEGER(hw2bus_wrptr)) <= hw2bus_din;
				hw2bus_wrptr <= hw2bus_wrptr + 1;
				
				if hw2bus_empty = '1' then
					hw2bus_empty <= '0';
				else
					hw2bus_fill <= hw2bus_fill + 1;
				end if;
				
				if or_reduce(hw2bus_rem) = '0' then
					hw2bus_full <= '1';
				else
					hw2bus_rem  <= hw2bus_rem - 1;
				end if;
			end if;
			
			-- reading from fifo which is not empty
			if slv_reg_read_sel = "1000" and hw2bus_empty = '0' then
				hw2bus_rdptr <= hw2bus_rdptr + 1;
				
				if or_reduce(hw2bus_fill) = '0' then
					hw2bus_empty <= '1';
				else
					hw2bus_fill <= hw2bus_fill - 1;
				end if;
				
				if hw2bus_full = '1' then
					hw2bus_full <= '0';
				else
					hw2bus_rem  <= hw2bus_rem + 1;
				end if;
			end if;

			-- do not change status if reading and writing concurrently
			if     (OSIF_FIFO_Hw2Sw_WE = '1' and hw2bus_full = '0')
			   and (slv_reg_read_sel = "1000" and hw2bus_empty = '0') then
				hw2bus_fill  <= hw2bus_fill;
				hw2bus_rem   <= hw2bus_rem;
				hw2bus_empty <= hw2bus_empty;
				hw2bus_full  <= hw2bus_full;
			end if;
		end if;
	end process fifo_hw2bus_proc;
	hw2bus_dout <= hw2bus_fifo(CONV_INTEGER(hw2bus_rdptr));
	
	
	fifo_bus2hw_proc : process(clk,rst) is
	begin
		if rst = '1' then
			bus2hw_rdptr <= (others => '0');
			bus2hw_wrptr <= (others => '0');
			bus2hw_fill  <= (others => '0');
			bus2hw_rem   <= (others => '1');
			bus2hw_empty <= '1';
			bus2hw_full  <= '0';
		elsif rising_edge(clk) then
			-- writing into fifo which is not full
			if slv_reg_write_sel = "0100" and bus2hw_full = '0' then
				-- ignoring byte enable
				bus2hw_fifo(CONV_INTEGER(bus2hw_wrptr)) <= bus2hw_din;
				bus2hw_wrptr <= bus2hw_wrptr + 1;
				
				if bus2hw_empty = '1' then
					bus2hw_empty <= '0';
				else
					bus2hw_fill <= bus2hw_fill + 1;
				end if;
				
				if or_reduce(bus2hw_rem) = '0' then
					bus2hw_full <= '1';
				else
					bus2hw_rem  <= bus2hw_rem - 1;
				end if;
			end if;
		
			-- reading from fifo which is not empty
			if OSIF_FIFO_Sw2Hw_RE = '1' and bus2hw_empty = '0' then
				bus2hw_rdptr <= bus2hw_rdptr + 1;
				
				if or_reduce(bus2hw_fill) = '0' then
					bus2hw_empty <= '1';
				else
					bus2hw_fill <= bus2hw_fill - 1;
				end if;
				
				if bus2hw_full = '1' then
					bus2hw_full <= '0';
				else
					bus2hw_rem  <= bus2hw_rem + 1;
				end if;
			end if;

			-- do not change fill and rem if reading and writing concurrently
			if     (slv_reg_write_sel = "0100" and bus2hw_full = '0')
			   and (OSIF_FIFO_Sw2Hw_RE = '1' and bus2hw_empty = '0') then
				bus2hw_fill  <= bus2hw_fill;
				bus2hw_rem   <= bus2hw_rem;
				bus2hw_empty <= bus2hw_empty;
				bus2hw_full  <= bus2hw_full;
			end if;
		end if;
	end process fifo_bus2hw_proc;
	bus2hw_dout <= bus2hw_fifo(CONV_INTEGER(bus2hw_rdptr));
	
	
	--    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
	--                     "1000"   C_BASEADDR + 0x0
	--                     "0100"   C_BASEADDR + 0x4
	--                     "0010"   C_BASEADDR + 0x8
	--                     "0001"   C_BASEADDR + 0xC
	
	bus_reg_read_proc : process(slv_reg_read_sel,hw2bus_dout,
	                            hw2bus_empty,hw2bus_fill,
	                            bus2hw_full,bus2hw_rem) is
	begin
		case slv_reg_read_sel is
			when "1000" => slv_ip2bus_data <= hw2bus_dout;
			when "0010" => slv_ip2bus_data <= hw2bus_empty & pad_31 & hw2bus_fill;
			when "0001" => slv_ip2bus_data <= bus2hw_full & pad_31 & bus2hw_rem;
			when others => slv_ip2bus_data <= (others => '0');
		end case;
	end process bus_reg_read_proc;

end implementation;
