library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity proc_control is
	port (
		-- FSL
		FSL_Clk       : in  std_logic;                 -- Synchronous clock
		FSL_Rst       : in  std_logic;                 -- System reset, should always come from FSL bus
		FSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		FSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		FSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		FSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		FSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		FSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		FSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		FSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		FSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		FSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
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

		-- ReconOS reset
		reconos_reset  : out std_logic
	);
end entity;

architecture implementation of proc_control is
	constant C_RESET          : std_logic_vector(7 downto 0) := x"01";
	constant C_PGD            : std_logic_vector(7 downto 0) := x"02";
	constant C_PAGE_READY     : std_logic_vector(7 downto 0) := x"03";
	constant C_RECONOS_RESET  : std_logic_vector(7 downto 0) := x"04";

	type STATE_TYPE is (STATE_WAIT, STATE_BRANCH, STATE_RESET, STATE_PGD, STATE_PAGE_FAULT, STATE_PAGE_READY, STATE_RECONOS_RESET);

	signal reset_counter : std_logic_vector(11 downto 0);
	signal page_fault_handled : std_logic;
	signal data   : std_logic_Vector(C_FSL_WIDTH-1 downto 0);
	signal state  :STATE_TYPE;
	signal fsl    : fsl_t;
begin

	fsl_setup(
		fsl,
		FSL_Clk,
		FSL_Rst,
		FSL_S_Data,
		FSL_S_Exists,
		FSL_M_Full,
		FSL_M_Data,
		FSL_S_Read,
		FSL_M_Write,
		FSL_M_Control
	);
	
--	fsl.hwt2fsl_data <= (others => '0');
--	fsl.hwt2fsl_writing <= '0';

	process (fsl.clk,fsl.rst) is
		variable done : boolean;
	begin
		if fsl.rst = '1' then
			fsl_reset(fsl);
			state <= STATE_WAIT;
			data <= (others => '0');
			done := False;
			reset0 <= '1';
			reset1 <= '1';
			reset2 <= '1';
			reset3 <= '1';
			reset4 <= '1';
			reset5 <= '1';
			reset6 <= '1';
			reset7 <= '1';
			reset8 <= '1';
			reset9 <= '1';
			resetA <= '1';
			resetB <= '1';
			resetC <= '1';
			resetD <= '1';
			resetE <= '1';
			resetF <= '1';
			pgd <= (others => '0');
			retry <= '0';
			page_fault_handled <= '0';
			reset_counter <= (others => '0');
			reconos_reset <= '1';
		elsif rising_edge(fsl.clk) then
			reconos_reset <= '0';
			case state is
				when STATE_WAIT =>
					if FSL_S_Exists = '0' and page_fault = '1' and page_fault_handled = '0' then
						state <= STATE_PAGE_FAULT;
					end if;
					fsl_read_word(fsl,data,done);
					if done then state <= STATE_BRANCH; end if;
					
				when STATE_BRANCH =>
					case data(31 downto 24) is
						when C_RESET =>
							state <= STATE_RESET;
						when C_PGD =>
							state <= STATE_PGD;
						when c_PAGE_READY =>
							state <= STATE_PAGE_READY;
						when C_RECONOS_RESET =>
							state <= STATE_RECONOS_RESET;
						when others =>
							state <= STATE_WAIT; -- ignore everything else
					end case;
					
				when STATE_RESET =>
					reset0 <= data(0);
					reset1 <= data(1);
					reset2 <= data(2);
					reset3 <= data(3);
					reset4 <= data(4);
					reset5 <= data(5);
					reset6 <= data(6);
					reset7 <= data(7);
					reset8 <= data(8);
					reset9 <= data(9);
					resetA <= data(10);
					resetB <= data(11);
					resetC <= data(12);
					resetD <= data(13);
					resetE <= data(14);
					resetF <= data(15);
					state <= STATE_WAIT;
				
				when STATE_PGD =>
					fsl_read_word(fsl,pgd,done);
					if done then state <= STATE_WAIT; end if;

				when STATE_PAGE_READY =>
					retry <= '1';
					if page_fault = '0' then
						page_fault_handled <= '0';
						retry <= '0';
						state <= STATE_WAIT;
					end if;

				when STATE_PAGE_FAULT =>
					page_fault_handled <= '1';
					fsl_write_word(fsl,fault_addr,done);
					if done then state <= STATE_WAIT; end if;

				when STATE_RECONOS_RESET =>
					data <= (others => '0');
					done := False;
					reset0 <= '1';
					reset1 <= '1';
					reset2 <= '1';
					reset3 <= '1';
					reset4 <= '1';
					reset5 <= '1';
					reset6 <= '1';
					reset7 <= '1';
					reset8 <= '1';
					reset9 <= '1';
					resetA <= '1';
					resetB <= '1';
					resetC <= '1';
					resetD <= '1';
					resetE <= '1';
					resetF <= '1';
					pgd <= (others => '0');
					retry <= '0';
					page_fault_handled <= '0';
					reconos_reset <= '1';
					if reset_counter = x"FFF" then
						reset_counter <= (others => '0');
						reconos_reset <= '0';
						state <= STATE_WAIT;
					else
						reset_counter <= reset_counter + 1;
					end if;
			end case;
		end if;
	end process;

end architecture;

