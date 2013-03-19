library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity proc_control is
	generic (
		C_ENABLE_ILA : integer := 0;
    C_FAULT_CHANNEL_WIDTH: Natural := 2 -- 2^2 = 4 channels
	);
	port (
		clk : in std_logic;
		rst : in std_logic;

		-- Request FSL
		FSLA_Rst       : in std_logic;
		FSLA_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		FSLA_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		FSLA_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		FSLA_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		FSLA_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		FSLA_M_Data    : out std_logic_vector(0 to 31); -- Output data
		FSLA_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		FSLA_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full

		-- Reply FSL
		FSLB_Rst       : in std_logic;
		FSLB_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		FSLB_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		FSLB_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		FSLB_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		FSLB_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		FSLB_M_Data    : out std_logic_vector(0 to 31); -- Output data
		FSLB_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		FSLB_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		
		-- 16 individual reset outputs (mhs does not support vector indexing)
		reset0         : out std_logic;
		reset1         : out std_logic;
		reset2         : out std_logic;
		reset3         : out std_logic;
		reset4         : out std_logic;
		reset5         : out std_logic;
		reset6         : out std_logic;
		reset7         : out std_logic;
		reset8         : out std_logic;
		reset9         : out std_logic;
		resetA         : out std_logic;
		resetB         : out std_logic;
		resetC         : out std_logic;
		resetD         : out std_logic;
		resetE         : out std_logic;
		resetF         : out std_logic;
		
		-- MMU related ports
		page_fault     : in std_logic;
		fault_addr     : in std_logic_vector(31 downto 0);
		retry          : out std_logic;
		pgd            : out std_logic_vector(31 downto 0);
		tlb_hits       : in std_logic_vector(31 downto 0);
		tlb_misses     : in std_logic_vector(31 downto 0);

    -- Fault injection related ports
    fault_sa0     : out std_logic_vector(32*(2**C_FAULT_CHANNEL_WIDTH)-1 downto 0 );
    fault_sa1     : out std_logic_vector(32*(2**C_FAULT_CHANNEL_WIDTH)-1 downto 0 );

		-- ReconOS reset
		reconos_reset  : out std_logic
	);
end entity;

architecture implementation of proc_control is
  -- commands
	constant C_RESET          : std_logic_vector(7 downto 0) := x"01";
	constant C_PGD            : std_logic_vector(7 downto 0) := x"02";
	constant C_PAGE_READY     : std_logic_vector(7 downto 0) := x"03";
	constant C_RECONOS_RESET  : std_logic_vector(7 downto 0) := x"04";
	constant C_GET_TLB_STATS  : std_logic_vector(7 downto 0) := x"05";
	constant C_SELFTEST       : std_logic_vector(7 downto 0) := x"06";
  
  constant C_FAULT_INJECTION: std_logic_vector(7 downto 0) := x"F0";

  -- return values
	constant C_RETURN_ADDR       : std_logic_vector(31 downto 0) := x"00000001";
	constant C_RETURN_SELFTEST   : std_logic_Vector(31 downto 0) := x"00000002";
	
	type ASTATE_TYPE is (A_WAIT, A_SELFTEST, A_PAGE_FAULT_0, A_PAGE_FAULT_1, A_WAIT_PAGE_READY_0, A_WAIT_PAGE_READY_1);
	type BSTATE_TYPE is (B_WAIT, B_BRANCH, B_SELFTEST, B_SELFTEST_REQ, B_RESET, B_TLB_HITS, B_TLB_MISSES, B_PGD, B_RECONOS_RESET,
                        B_FAULT_SA0, B_FAULT_SA1);

	
	constant C_ILA_WIDTH : integer := 200;
	
	component proc_control_icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
	end component;

	component proc_control_ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(C_ILA_WIDTH-1 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	end component;
	
	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal CSDATA    : STD_LOGIC_VECTOR(C_ILA_WIDTH-1 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	signal hwt_reset : std_logic_vector(15 downto 0);
	signal reset_counter : std_logic_vector(11 downto 0);
	signal reconos_reset_dup : std_logic;
	signal data   : std_logic_Vector(C_FSL_WIDTH-1 downto 0);
	signal ignore : std_logic_Vector(C_FSL_WIDTH-1 downto 0);
	signal selftest_initiate_req  : std_logic;
	signal selftest_req_initiated : std_logic;
	signal astate  : ASTATE_TYPE;
	signal bstate  : BSTATE_TYPE;
	signal i_fsla    : i_fsl_t;
	signal o_fsla    : o_fsl_t;
	signal i_fslb    : i_fsl_t;
	signal o_fslb    : o_fsl_t;
  
  signal fault_channel : std_logic_vector(C_FAULT_CHANNEL_WIDTH-1 downto 0);
  
begin


--------------------- CHIPSCOPE -------------------------
	
	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

	icon_i : proc_control_icon
	port map (
		CONTROL0 => CONTROL
	);
	
	ila_i : proc_control_ila
	port map (
		CONTROL => CONTROL,
		CLK => Clk,
		DATA => CSDATA,
		TRIG0 => TRIG
	);

	end generate;

	
	CSDATA(0) <= '1' when astate = A_WAIT else '0';
	CSDATA(1) <= '1' when astate = A_SELFTEST else '0';
	CSDATA(2) <= '1' when astate = A_PAGE_FAULT_0 else '0';
	CSDATA(3) <= '1' when astate = A_PAGE_FAULT_1 else '0';
	CSDATA(4) <= '1' when astate = A_WAIT_PAGE_READY_0 else '0';
	
	CSDATA(16) <= '1' when bstate = B_WAIT else '0';
	CSDATA(17) <= '1' when bstate = B_BRANCH else '0';
	CSDATA(18) <= '1' when bstate = B_SELFTEST else '0';
	CSDATA(19) <= '1' when bstate = B_SELFTEST_REQ else '0';
	CSDATA(20) <= '1' when bstate = B_RESET else '0';
	CSDATA(21) <= '1' when bstate = B_TLB_HITS else '0';
	CSDATA(22) <= '1' when bstate = B_TLB_MISSES else '0';
	CSDATA(23) <= '1' when bstate = B_PGD else '0';
	CSDATA(24) <= '1' when bstate = B_RECONOS_RESET else '0';
	
	CSDATA(63 downto 32) <= FSLA_S_Data;
	CSDATA(64) <= Rst;
	CSDATA(65) <= FSLA_S_Exists;
	CSDATA(66) <= FSLA_M_Full;
	CSDATA(98 downto 67) <= FSLB_S_Data;
	CSDATA(99) <= Rst;
	CSDATA(100) <= FSLB_S_Exists;
	CSDATA(101) <= FSLB_M_Full;
	
	CSDATA(133 downto 102) <= data;
	CSDATA(165 downto 134) <= ignore;
	CSDATA(181 downto 166) <= hwt_reset;
	CSDATA(193 downto 182) <= reset_counter;
	CSDATA(194) <= page_fault;
	CSDATA(195) <= reconos_reset_dup;
	CSDATA(196) <= selftest_initiate_req;
	CSDATA(197) <= selftest_req_initiated;
	
	CSDATA(C_ILA_WIDTH-1 downto 198) <= (others => '0');
	
	TRIG <= CSDATA(4 downto 0) & CSDATA(24 downto 16) & CSDATA(65) & CSDATA(100);

	
---------------------------------------------------------


	fsl_setup(
		i_fsla,
		o_fsla,
		FSLA_S_Data,
		FSLA_S_Exists,
		FSLA_M_Full,
		FSLA_M_Data,
		FSLA_S_Read,
		FSLA_M_Write,
		FSLA_M_Control
	);

	fsl_setup(
		i_fslb,
		o_fslb,
		FSLB_S_Data,
		FSLB_S_Exists,
		FSLB_M_Full,
		FSLB_M_Data,
		FSLB_S_Read,
		FSLB_M_Write,
		FSLB_M_Control
	);

	reconos_reset <= reconos_reset_dup;

	reset0 <= hwt_reset( 0); reset1 <= hwt_reset( 1); reset2 <= hwt_reset( 2); reset3 <= hwt_reset(3);
	reset4 <= hwt_reset( 4); reset5 <= hwt_reset( 5); reset6 <= hwt_reset( 6); reset7 <= hwt_reset(7);
	reset8 <= hwt_reset( 8); reset9 <= hwt_reset( 9); resetA <= hwt_reset(10); resetB <= hwt_reset(11);
	resetC <= hwt_reset(12); resetD <= hwt_reset(13); resetE <= hwt_reset(14); resetF <= hwt_reset(15);

	-- this process initiates requests and handles incoming replys
	FSLA_PROC : process (clk,rst) is
		variable done : boolean;
	begin
		if rst = '1' or reconos_reset_dup = '1' then
			fsl_reset(o_fsla);
			astate <= A_WAIT;
			ignore <= (others => '0');
			done := False;
			retry <= '0';
			selftest_req_initiated <= '0';
		elsif rising_edge(clk) then
			case astate is
				when A_WAIT =>
					if page_fault = '1' then
						astate <= A_PAGE_FAULT_0;
					elsif selftest_initiate_req = '1' then
						selftest_req_initiated <= '1';
						astate <= A_SELFTEST;
					end if;
				
				when A_SELFTEST =>
					selftest_req_initiated <= '0';		
					fsl_write_word(i_fsla,o_fsla,C_RETURN_SELFTEST,done);
					if done then astate <= A_WAIT; end if;
				
				when A_PAGE_FAULT_0 =>
					fsl_write_word(i_fsla,o_fsla,C_RETURN_ADDR,done);
					if done then astate <= A_PAGE_FAULT_1; end if;
				
				when A_PAGE_FAULT_1 =>
					fsl_write_word(i_fsla,o_fsla,fault_addr,done);
					if done then astate <= A_WAIT_PAGE_READY_0; end if;
					
				when A_WAIT_PAGE_READY_0 =>
					fsl_read_word(i_fsla,o_fsla,ignore,done);
					if done then
						retry <= '1';
						astate <= A_WAIT_PAGE_READY_1;
					end if;

				when A_WAIT_PAGE_READY_1 =>
					if page_fault = '0' then
						retry <= '0';
						astate <= A_WAIT;
					end if;
			end case;
		end if;
	end process;

	-- this process replies to incoming requests
	FSLB_PROC : process (clk,rst) is
		variable done : boolean;
	begin
		if rst = '1' then
			fsl_reset(o_fslb);
			bstate <= B_WAIT;
			data <= (others => '0');
			done := False;
			hwt_reset <= (others => '1');
			pgd <= (others => '0');
			reset_counter <= (others => '0');
			reconos_reset_dup <= '1';
			selftest_initiate_req <= '0';
      fault_sa0 <= (others => '0');
      fault_sa1 <= (others => '0');
		elsif rising_edge(clk) then
			reconos_reset_dup <= '0';
			case bstate is
				when B_WAIT =>
					fsl_read_word(i_fslb,o_fslb,data,done);
					if done then bstate <= B_BRANCH; end if;
					
				when B_BRANCH =>
					case data(31 downto 24) is
						when C_RESET =>
							bstate <= B_RESET;
						when C_PGD =>
							bstate <= B_PGD;
						when C_RECONOS_RESET =>
							bstate <= B_RECONOS_RESET;
						when C_GET_TLB_STATS =>
							bstate <= B_TLB_HITS;
						when C_SELFTEST =>
							bstate <= B_SELFTEST;
            when C_FAULT_INJECTION=>
              bstate <= B_FAULT_SA0;
              fault_channel <= data(C_FAULT_CHANNEL_WIDTH-1 downto 0);
						when others =>
							bstate <= B_WAIT; -- ignore everything else
					end case;

				when B_SELFTEST =>
					fsl_write_word(i_fslb,o_fslb,x"5E1F7E57",done);
					if done then bstate <= B_SELFTEST_REQ; end if;

				when B_SELFTEST_REQ =>
					selftest_initiate_req <= '1';
					if selftest_req_initiated = '1' then
						selftest_initiate_req <= '0';
						bstate <= B_WAIT;
					end if;			

				when B_RESET =>
					hwt_reset <= data(15 downto 0);
					bstate <= B_WAIT;
				
				when B_PGD =>
					fsl_read_word(i_fslb,o_fslb,pgd,done);
					if done then bstate <= B_WAIT; end if;

				when B_TLB_HITS =>
					fsl_write_word(i_fslb,o_fslb,tlb_hits,done);
					if done then bstate <= B_TLB_MISSES; end if;

				when B_TLB_MISSES =>
					fsl_write_word(i_fslb,o_fslb,tlb_misses,done);
					if done then bstate <= B_WAIT; end if;

				when B_RECONOS_RESET =>
					data <= (others => '0');
					done := False;
					hwt_reset <= (others => '1');
					pgd <= (others => '0');
					reconos_reset_dup <= '1';
					if reset_counter = x"FFF" then
						reset_counter <= (others => '0');
						reconos_reset_dup <= '0';
						bstate <= B_WAIT;
					else
						reset_counter <= reset_counter + 1;
					end if;
          
        when B_FAULT_SA0 =>
          fsl_read_word(i_fslb,o_fslb,data,done);
          if done then 
            bstate <= B_FAULT_SA1; 
            fault_sa0((32*(to_integer(ieee.numeric_std.unsigned(fault_channel))+1))-1 
                          downto (32*to_integer(ieee.numeric_std.unsigned(fault_channel))) ) <= data;
          end if;
        
        when B_FAULT_SA1 =>
          fsl_read_word(i_fslb,o_fslb,data,done);
          if done then
            bstate <= B_WAIT; 
            fault_sa1( (32*(to_integer(ieee.numeric_std.unsigned(fault_channel))+1))-1 
                        downto (32*to_integer(ieee.numeric_std.unsigned(fault_channel))) ) <= data; 
          end if;  
         
			end case;
		end if;
	end process;

	
end architecture;

