--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - OSIF - Top level entity
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  A AXI slave which maps the FIFOs of the HWTs to
--                 registers accessible from the AXI-Bus.
--                   Reg0: Read data
--                   Reg1: Write data
--                   Reg2: Fill - number of elements in receive-FIFO
--                   Reg3: Rem - free space in send-FIFO
--
--                 REMARK: The FIFOs must have the same clock than the
--                         AXI-Bus.
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
		C_NUM_FIFOS    : integer   := 1;
		C_FIFO_WIDTH   : integer   := 32;

		-- Bus protocol parameters
		C_SLV_DWIDTH   : integer   := 32
	);
	port (
		-- FIFO ports
		-- ## BEGIN GENERATE LOOP ##
		FIFO_S_Data_#i#   : in  std_logic_vector(31 downto 0);
		FIFO_S_Fill_#i#   : in  std_logic_vector(15 downto 0);
		FIFO_S_Empty_#i#  : in  std_logic;
		FIFO_S_RE_#i#     : out std_logic;
		
		FIFO_M_Data_#i#   : out std_logic_vector(31 downto 0);
		FIFO_M_Rem_#i#    : in  std_logic_vector(15 downto 0);
		FIFO_M_Full_#i#   : in  std_logic;
		FIFO_M_WE_#i#     : out std_logic;
		-- ## END GENERATE LOOP ##

		-- Bus protocol ports
		Bus2IP_Clk      : in  std_logic;
		Bus2IP_Resetn   : in  std_logic;
		Bus2IP_Data     : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		Bus2IP_BE       : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
		Bus2IP_Addr     : in  std_logic_vector(31 downto 0);
		Bus2IP_RNW      : in  std_logic;
		Bus2IP_CS       : in  std_logic_vector(0 downto 0);
		IP2Bus_Data     : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		IP2Bus_RdAck    : out std_logic;
		IP2Bus_WrAck    : out std_logic;
		IP2Bus_Error    : out std_logic
	);

	attribute MAX_FANOUT   : string;
	attribute SIGIS        : string;

	attribute SIGIS of Bus2IP_Clk           : signal is "Clk";
	attribute SIGIS of Bus2IP_Resetn        : signal is "Rst";

end entity user_logic;


architecture implementation of user_logic is

	-- Signals for user logic slave model s/w accessible register
	signal slv_ip2bus_data     : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal slv_bus2ip_data     : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal slv_read_ack        : std_logic;
	signal slv_write_ack       : std_logic;
	signal slv_addr            : std_logic_vector(31 downto 0);
	signal slv_rnw             : std_logic;
	signal slv_cs              : std_logic;

	type fifo_bi_t is record
		s_data   : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		s_fill   : std_logic_vector(15 downto 0);
		s_empty  : std_logic;
		s_re     : std_logic;
		m_data   : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		m_rem    : std_logic_vector(15 downto 0);
		m_full   : std_logic;
		m_we     : std_logic;
	end record;

	signal s_data  : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
	signal s_fill  : std_logic_vector(15 downto 0);
	signal s_empty : std_logic;
	signal s_re    : std_logic;
	signal m_data  : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
	signal m_rem   : std_logic_vector(15 downto 0);
	signal m_full  : std_logic;
	signal m_we    : std_logic;

	-- Array which contains all connected FIFOs
	type fifos_t is array(0 to C_NUM_FIFOS - 1) of fifo_bi_t;
	signal fifos : fifos_t;

	signal fifo_bi_select : integer range 0 to C_NUM_FIFOS - 1;
	signal reg_select     : integer range 0 to 3;

	signal pad_31 : std_logic_vector(14 downto 0);
	
	signal clk : std_logic;
	signal rst : std_logic;

begin
	-- this has the intended effect in sythesis (it is infact the same signal)
	-- but causes a different behaviour in simulation
	clk <= Bus2Ip_Clk;
	rst <= not Bus2IP_Resetn;

	pad_31 <= (others => '0');

	IP2Bus_Data     <= slv_ip2bus_data;
	slv_bus2ip_data <= Bus2IP_Data;

	slv_addr <= Bus2IP_Addr;
	slv_rnw  <= Bus2IP_RNW;
	slv_cs   <= Bus2IP_CS(0);

	IP2Bus_WrAck <= slv_write_ack;
	IP2Bus_RdAck <= slv_read_ack;
	IP2Bus_Error <= '0';

	fifo_bi_select  <= CONV_INTEGER(slv_addr(19 downto 4));
	reg_select      <= CONV_INTEGER(slv_addr(3 downto 2));


	mux_proc : process(fifos,fifo_bi_select,pad_31,
	                   -- ## BEGIN GENERATE LOOP ##
	                   FIFO_S_Data_#i#,FIFO_S_Fill_#i#,FIFO_S_Empty_#i#,
	                   FIFO_M_Rem_#i#,FIFO_M_Full_#i#,
                           -- ## END GENERATE LOOP ##
                           s_re,m_data,m_we) is
	begin
		-- Assign FIFOs to array
		-- ## BEGIN GENERATE LOOP ##
		fifos(#i#).s_data  <= FIFO_S_Data_#i#;
		fifos(#i#).s_fill  <= FIFO_S_Fill_#i#;
		fifos(#i#).s_empty <= FIFO_S_Empty_#i#;
		FIFO_S_RE_#i#      <= fifos(#i#).s_re;

		FIFO_M_Data_#i#   <= fifos(#i#).m_data;
		fifos(#i#).m_rem  <= FIFO_M_Rem_#i#;
		fifos(#i#).m_full <= FIFO_M_Full_#i#;
		FIFO_M_WE_#i#     <= fifos(#i#).m_we;
		-- ## END GENERATE LOOP ##

		-- default values for not connected ports
                -- later assignments will override this defaults
		for i in 0 to C_NUM_FIFOS - 1 loop
			fifos(i).s_re <= '0';
			fifos(i).m_we <= '0';

			fifos(i).m_data <= (others => '0');
		end loop;

		s_data                       <= fifos(fifo_bi_select).s_data;
		s_fill                       <= fifos(fifo_bi_select).s_fill;
		s_empty                      <= fifos(fifo_bi_select).s_empty;
		fifos(fifo_bi_select).s_re   <= s_re;

		fifos(fifo_bi_select).m_data <= m_data;
		m_rem                        <= fifos(fifo_bi_select).m_rem;
		m_full                       <= fifos(fifo_bi_select).m_full;
		fifos(fifo_bi_select).m_we   <= m_we;
	end process;


	slv_read_ack  <= '1' when slv_cs = '1' and slv_rnw = '1' else '0';
	slv_write_ack <= '1' when slv_cs = '1' and slv_rnw = '0' else '0';

	-- REMARK: This is not totally right. Normally we need to
	--         set the RE of the FIFO and read the next cycle.
	--         Since we do not read data in the next cycle this
	--         is totally fine.
	s_re <= '1' when slv_cs = '1' and (reg_select = 0 and slv_rnw = '1') else '0';
	m_we <= '1' when slv_cs = '1' and (reg_select = 1 and slv_rnw = '0') else '0';

	bus_reg_read_proc : process(reg_select,s_data,
	                            s_empty,s_fill,
	                            m_full,m_rem) is
	begin
		case reg_select is
			when 0 => slv_ip2bus_data <= s_data;
			when 1 => slv_ip2bus_data <= (others => '0');
			when 2 => slv_ip2bus_data <= s_empty & pad_31 & s_fill;
			when 3 => slv_ip2bus_data <= m_full & pad_31 & m_rem;
		end case;
	end process bus_reg_read_proc;

	bus_reg_write_proc : process(reg_select,slv_bus2ip_data) is
	begin
		case reg_select is
			when 1 => m_data <= slv_bus2ip_data;
			when others => m_data <= (others => '0');
		end case;
	end process bus_reg_write_proc;

end implementation;
