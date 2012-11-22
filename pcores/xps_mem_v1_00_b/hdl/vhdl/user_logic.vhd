------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.srl_fifo_f;


entity user_logic is
	generic
	(
		C_ENABLE_ILA                   : integer              := 0;
		C_MST_AWIDTH                   : integer              := 32;-- Master interface address bus width
		C_MST_DWIDTH                   : integer              := 32;-- Master interface data bus width
		C_NUM_REG                      : integer              := 4-- Number of software accessible registers
	);
	port
	(
		-- PLB Master Local Link and Command Interface
		Bus2IP_Clk                     : in  std_logic; -- Bus to IP clock
		Bus2IP_Reset                   : in  std_logic; -- Bus to IP reset
		IP2Bus_RdAck                   : out std_logic;-- IP to Bus read transfer acknowledgement
		IP2Bus_WrAck                   : out std_logic;-- IP to Bus write transfer acknowledgement
		IP2Bus_Error                   : out std_logic;-- IP to Bus error response
		IP2Bus_MstRd_Req               : out std_logic;-- IP to Bus master read request
		IP2Bus_MstWr_Req               : out std_logic;-- IP to Bus master write request
		IP2Bus_Mst_Addr                : out std_logic_vector(0 to C_MST_AWIDTH-1);-- IP to Bus master address bus
		IP2Bus_Mst_BE                  : out std_logic_vector(0 to C_MST_DWIDTH/8-1);-- IP to Bus master byte enables
		IP2Bus_Mst_Length              : out std_logic_vector(0 to 11);-- IP to Bus master transfer length
		IP2Bus_Mst_Type                : out std_logic;-- IP to Bus master transfer type
		IP2Bus_Mst_Lock                : out std_logic;-- IP to Bus master lock
		IP2Bus_Mst_Reset               : out std_logic;-- IP to Bus master reset
		Bus2IP_Mst_CmdAck              : in  std_logic;-- Bus to IP master command acknowledgement
		Bus2IP_Mst_Cmplt               : in  std_logic;-- Bus to IP master transfer completion
		Bus2IP_Mst_Error               : in  std_logic;-- Bus to IP master error response
		Bus2IP_Mst_Rearbitrate         : in  std_logic; -- Bus to IP master re-arbitrate
		Bus2IP_Mst_Cmd_Timeout         : in  std_logic;-- Bus to IP master command timeout
		Bus2IP_MstRd_d                 : in  std_logic_vector(0 to C_MST_DWIDTH-1);-- Bus to IP master read data bus
		Bus2IP_MstRd_rem               : in  std_logic_vector(0 to C_MST_DWIDTH/8-1);-- Bus to IP master read remainder
		Bus2IP_MstRd_sof_n             : in  std_logic;-- Bus to IP master read start of frame
		Bus2IP_MstRd_eof_n             : in  std_logic;-- Bus to IP master read end of frame
		Bus2IP_MstRd_src_rdy_n         : in  std_logic;-- Bus to IP master read source ready
		Bus2IP_MstRd_src_dsc_n         : in  std_logic;-- Bus to IP master read source discontinue
		IP2Bus_MstRd_dst_rdy_n         : out std_logic;-- IP to Bus master read destination ready
		IP2Bus_MstRd_dst_dsc_n         : out std_logic;-- IP to Bus master read destination discontinue
		IP2Bus_MstWr_d                 : out std_logic_vector(0 to C_MST_DWIDTH-1);-- IP to Bus master write data bus
		IP2Bus_MstWr_rem               : out std_logic_vector(0 to C_MST_DWIDTH/8-1);-- IP to Bus master write remainder
		IP2Bus_MstWr_sof_n             : out std_logic;-- IP to Bus master write start of frame
		IP2Bus_MstWr_eof_n             : out std_logic;-- IP to Bus master write end of frame
		IP2Bus_MstWr_src_rdy_n         : out std_logic;-- IP to Bus master write source ready
		IP2Bus_MstWr_src_dsc_n         : out std_logic;-- IP to Bus master write source discontinue
		Bus2IP_MstWr_dst_rdy_n         : in  std_logic;-- Bus to IP master write destination ready
		Bus2IP_MstWr_dst_dsc_n         : in  std_logic;-- Bus to IP master write destination discontinue
		
		-- FIFO Interface
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_M_Wr : out std_logic
	);
	
	attribute SIGIS : string;
	attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
	attribute SIGIS of Bus2IP_Reset  : signal is "RST";
	attribute SIGIS of IP2Bus_Mst_Reset: signal is "RST";

end entity user_logic;

architecture IMP of user_logic is

        attribute keep_hierarchy : string;
        attribute keep_hierarchy of IMP: architecture is "true";



	type state_t is (STATE_WAIT_HEADER,STATE_READ_CMD,STATE_READ_ADDR,STATE_WAIT_FIFO_REM,
	                 STATE_WAIT_FIFO_FILL,STATE_READ_REQ,STATE_READ,STATE_WRITE_REQ,
						  STATE_WRITE,STATE_WAIT_COMPLETE);	
	signal state : state_t;
	
	signal cmd : std_logic_vector(31 downto 0);
	signal out_counter : std_logic_vector(11 downto 0);
	signal in_counter : std_logic_vector(11 downto 0);
	signal header_read : std_logic;
	
-- begin chipscope

	component chipscope_icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
	end component;

	component chipscope_ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(299 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
	end component;

	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal DATA    : STD_LOGIC_VECTOR(299 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	signal fifo_burst : std_logic;
	signal FIFO32_S_Rd_alt : std_logic;

	-- braindead signal duplications
	
	signal IP2Bus_MstRd_Req_cs : std_logic;
	signal IP2Bus_MstWr_Req_cs : std_logic;
	signal IP2Bus_Mst_Type_cs : std_logic;
	signal IP2Bus_Mst_Addr_cs : std_logic_vector(31 downto 0);
	signal IP2Bus_Mst_BE_cs : std_logic_vector(3 downto 0);
	signal IP2Bus_Mst_Length_cs : std_logic_vector(11 downto 0);
	signal IP2Bus_Mst_Lock_cs : std_logic;
	signal IP2Bus_Mst_Reset_cs : std_logic;
	signal IP2Bus_MstRd_dst_rdy_n_cs : std_logic;
	signal IP2Bus_MstRd_dst_dsc_n_cs : std_logic;
	signal IP2Bus_MstWr_d_cs : std_logic_vector(31 downto 0);
	signal IP2Bus_MstWr_REM_cs : std_logic_vector(3 downto 0);
	signal IP2Bus_MstWr_sof_n_cs : std_logic;
	signal IP2Bus_MstWr_eof_n_cs : std_logic;
	signal IP2Bus_MstWr_src_rdy_n_cs : std_logic;
	signal IP2Bus_MstWr_src_dsc_n_cs : std_logic;
	
	signal FIFO32_S_Rd_cs    : std_logic;
	signal FIFO32_M_Wr_cs   : std_logic;
	signal FIFO32_M_Data_cs    : std_logic_vector(31 downto 0);
	
-- end chipscope
	
	
begin

-- begin chipscope

	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

	icon_i : chipscope_icon
	port map (
		CONTROL0 => CONTROL
	);
	
	ila_i : chipscope_ila
	port map (
		CONTROL => CONTROL,
		CLK => Bus2IP_Clk,
		DATA => DATA,
		TRIG0 => TRIG
	);

	end generate;

	--TRIG(0) <= Bus2IP_Reset;
	TRIG <= FIFO32_S_Fill(7 downto 0);
	
	-- Bus Master Command
	DATA(0) <= IP2Bus_MstRd_Req_cs;
	DATA(1) <= IP2Bus_MstWr_Req_cs;
	DATA(2) <= IP2Bus_Mst_Type_cs;
	DATA(34 downto 3) <= IP2Bus_Mst_Addr_cs;
	DATA(38 downto 35) <= IP2Bus_Mst_BE_cs;
	DATA(50 downto 39) <= IP2Bus_Mst_Length_cs;
	DATA(51) <= IP2Bus_Mst_Lock_cs;
	DATA(52) <= IP2Bus_Mst_Reset_cs;	
	DATA(53) <= Bus2IP_Mst_CmdAck;
	DATA(54) <= Bus2IP_Mst_Cmplt;
	DATA(55) <= Bus2IP_Mst_Error;
	DATA(56) <= Bus2IP_Mst_Rearbitrate;
	DATA(57) <= Bus2IP_Mst_Cmd_Timeout;
	
	-- Master Read Local Link 
	DATA(89 downto 58) <= Bus2IP_MstRd_d;
	DATA(93 downto 90) <= Bus2IP_MstRd_REM;
	DATA(94) <= Bus2IP_MstRd_sof_n;
	DATA(95) <= Bus2IP_MstRd_eof_n;
	DATA(96) <= Bus2IP_MstRd_src_rdy_n;
	DATA(97) <= Bus2IP_MstRd_src_dsc_n;
	DATA(98) <= IP2Bus_MstRd_dst_rdy_n_cs;
	DATA(99) <= IP2Bus_MstRd_dst_dsc_n_cs;
	
	-- Master Write Local Link
	DATA(131 downto 100) <= IP2Bus_MstWr_d_cs;
	DATA(135 downto 132) <= IP2Bus_MstWr_REM_cs;
	DATA(136) <= IP2Bus_MstWr_sof_n_cs;
	DATA(137) <= IP2Bus_MstWr_eof_n_cs;
	DATA(138) <= IP2Bus_MstWr_src_rdy_n_cs;
	DATA(139) <= IP2Bus_MstWr_src_dsc_n_cs;
	DATA(140) <= Bus2IP_MstWr_dst_rdy_n;
	DATA(141) <= Bus2IP_MstWr_dst_dsc_n;
	
	-- burst counters
	DATA(153 downto 142)  <= in_counter;
	DATA(165 downto 154)  <= out_counter;
	
	-- FSL
	DATA(166) <= FIFO32_S_Rd_cs;
	DATA(198 downto 167) <= FIFO32_S_Data;
	DATA(214 downto 199) <= FIFO32_S_Fill;
	
	
	DATA(215) <= FIFO32_M_Wr_cs;
	DATA(247 downto 216) <= FIFO32_M_Data_cs;
	DATA(263 downto 248) <= FIFO32_M_Rem;
	DATA(271 downto 264)  <= TRIG;
	DATA(272) <= fifo_burst;
	DATA(273) <= FIFO32_S_Rd_alt;

	IP2Bus_MstRd_Req <= IP2Bus_MstRd_Req_cs;
	IP2Bus_MstWr_Req <= IP2Bus_MstWr_Req_cs;
	IP2Bus_Mst_Type <= IP2Bus_Mst_Type_cs;
	IP2Bus_Mst_Addr <= IP2Bus_Mst_Addr_cs;
	IP2Bus_Mst_BE <= IP2Bus_Mst_BE_cs;
	IP2Bus_Mst_Length <= IP2Bus_Mst_Length_cs;
	IP2Bus_Mst_Lock <= IP2Bus_Mst_Lock_cs;
	IP2Bus_Mst_Reset <= IP2Bus_Mst_Reset_cs;
	IP2Bus_MstRd_dst_rdy_n <= IP2Bus_MstRd_dst_rdy_n_cs;
	IP2Bus_MstRd_dst_dsc_n <= IP2Bus_MstRd_dst_dsc_n_cs;
	IP2Bus_MstWr_d <= IP2Bus_MstWr_d_cs;
	IP2Bus_MstWr_REM <= IP2Bus_MstWr_REM_cs;
	IP2Bus_MstWr_sof_n <= IP2Bus_MstWr_sof_n_cs;
	IP2Bus_MstWr_eof_n <= IP2Bus_MstWr_eof_n_cs;
	IP2Bus_MstWr_src_rdy_n <= IP2Bus_MstWr_src_rdy_n_cs;
	IP2Bus_MstWr_src_dsc_n <= IP2Bus_MstWr_src_dsc_n_cs;
	
	FIFO32_S_Rd    <= FIFO32_S_Rd_cs;
	FIFO32_M_Wr   <= FIFO32_M_Wr_cs;
	FIFO32_M_Data    <= FIFO32_M_Data_cs;
	
-- end chipscope

	IP2Bus_Mst_Type_cs <= '1'; -- burst
	IP2Bus_Mst_BE_cs <= "1111";
	IP2Bus_MstWr_src_dsc_n_cs <= '1';
	IP2Bus_MstRd_dst_dsc_n_cs <= '1';
	--IP2Bus_MstWr_d_cs <= x"AFFE1234";--mem(CONV_INTEGER(out_counter));
	--IP2Bus_MstRd_dst_rdy_n_cs <= '0';
	
	IP2Bus_Mst_Length_cs <=  cmd(11 downto 2) & "00";
	IP2Bus_Error <= '0';
	
	IP2Bus_MstWr_sof_n_cs <= '0' when out_counter = 0 else '1';
	IP2Bus_MstWr_eof_n_cs <= '0' when (out_counter = (IP2Bus_Mst_Length_cs(11 downto 2) - 1)) and (IP2Bus_MstWr_src_rdy_n_cs = '0') else '1';
	
	-- since the Bus2IP_MstWr_dst_rdy_n signal stays low(active) for one cycle too long we
	-- we deassert ready for this cycle.
--	fix_source_ready_proc : process (Bus2IP_Clk)
--	begin
--		if rising_edge(Bus2IP_Clk) then
--			if Bus2IP_MstWr_dst_rdy_n = '0' then
--				IP2Bus_MstWr_src_rdy_n_cs <= not IP2Bus_MstWr_eof_n_cs;
--			else
--				IP2Bus_MstWr_src_rdy_n_cs <= '0';
--			end if;
--		end if;
--	end process;
	
	-- 1: receive command (r/w, burst length)
	-- 2: receive addr
	-- 3: set read req
	-- 4: 
	
	--IP2Bus_MstRd_dst_rdy_n_cs <= FSL_M_Full;
	IP2Bus_MstWr_d_cs <= FIFO32_S_Data;
	
	WR_BURST_PROC : process
	begin
		if fifo_burst = '0' then
			FIFO32_S_Rd_cs <= FIFO32_S_Rd_alt;
		else
			FIFO32_S_Rd_cs <= not Bus2IP_MstWr_dst_rdy_n;
		end if;
	end process;

	cmd_proc : process (Bus2IP_Clk, Bus2IP_Reset)
		variable delay : std_logic_vector(31 downto 0);
	begin
		if Bus2IP_Reset = '1' then
			state <= STATE_WAIT_HEADER;
			IP2Bus_MstRd_Req_cs <= '0';
			IP2Bus_MstWr_Req_cs <= '0';
			IP2Bus_Mst_Addr_cs <= x"00000000";
			delay := (others => '0');
			fifo_burst <= '0';
		elsif rising_edge(Bus2IP_Clk) then
			DATA(299 downto 280) <= (others => '0');
			FIFO32_S_Rd_alt <= '0';
			FIFO32_M_Wr_cs <= '0';
			IP2Bus_MstWr_src_rdy_n_cs <= '1';
			IP2Bus_MstRd_dst_rdy_n_cs <= '1';
			
			if Bus2IP_Mst_CmdAck = '1' then
				IP2Bus_MstWr_Req_cs <= '0';
				IP2Bus_MstRd_Req_cs <= '0';
			end if;
			
			case state is
				when STATE_WAIT_HEADER =>
					DATA(280) <= '1';
					if FIFO32_S_Fill >= 2 then
						state <= STATE_READ_CMD;
						FIFO32_S_Rd_alt <= '1';
					end if;
				
				when STATE_READ_CMD =>
					DATA(281) <= '1';
					FIFO32_S_Rd_alt <= '1';
					cmd <= FIFO32_S_Data;
					state <= STATE_READ_ADDR;
					
				when STATE_READ_ADDR =>
					DATA(282) <= '1';
					FIFO32_S_Rd_alt <= '0';
					IP2Bus_Mst_Addr_cs <= FIFO32_S_Data;
					if cmd(31) = '0' then -- burst read
						state <= STATE_WAIT_FIFO_REM;
					else -- burst write
						state <= STATE_WAIT_FIFO_FILL;
					end if;

				when STATE_WAIT_FIFO_REM =>
					DATA(283) <= '1';
					if FIFO32_M_Rem >= cmd(11 downto 2) then
						state <= STATE_READ_REQ;
					end if;
					
				when STATE_WAIT_FIFO_FILL =>
					DATA(284) <= '1';
					if FIFO32_S_Fill >= cmd(11 downto 2) then
						state <= STATE_WRITE_REQ;
					end if;
					
				when STATE_READ_REQ =>
					DATA(285) <= '1';
					IP2Bus_MstRd_Req_cs <= '1';
					in_counter <= (others => '0');
					IP2Bus_MstRd_dst_rdy_n_cs <= '0';
					state <= STATE_READ;

				when STATE_READ =>
					DATA(286) <= '1';
					FIFO32_M_Data_cs <= Bus2IP_MstRd_d;
					IP2Bus_MstRd_dst_rdy_n_cs <= '0';
					if Bus2IP_MstRd_src_rdy_n = '0' then
						
						FIFO32_M_Wr_cs <= '1';
						if in_counter = IP2Bus_Mst_Length_cs(11 downto 2) - 1 then
							IP2Bus_MstRd_dst_rdy_n_cs <= '1';
							--FSL_M_Write_cs <= '0';
							in_counter <= (others => '0');
							state <= STATE_WAIT_COMPLETE;
						else
							in_counter <= in_counter + 1;
						end if;
					end if;
					
				when STATE_WRITE_REQ =>
					DATA(287) <= '1';
					IP2Bus_MstWr_Req_cs <= '1';
					IP2Bus_MstWr_src_rdy_n_cs <= '0';
					out_counter <= (others => '0');
					state <= STATE_WRITE;
					

				when STATE_WRITE =>
					DATA(288) <= '1';
					fifo_burst <= '1';
					IP2Bus_MstWr_src_rdy_n_cs <= '0';
					if Bus2IP_MstWr_dst_rdy_n = '0' then
						--FIFO32_S_Rd_cs <= '1';
						if out_counter = IP2Bus_Mst_Length_cs(11 downto 2) - 1 then
							out_counter <= (others => '0');
							IP2Bus_MstWr_src_rdy_n_cs <= '1';
							state <= STATE_WAIT_COMPLETE;
						else
							out_counter <= out_counter + 1;
						end if;
					end if;

				when STATE_WAIT_COMPLETE =>
					DATA(289) <= '1';
					if Bus2IP_Mst_Cmplt = '1' then
						state <= STATE_WAIT_HEADER;
						fifo_burst <= '0';
					end if;
			
			end case;
		end if;
	end process;
	
end IMP;

