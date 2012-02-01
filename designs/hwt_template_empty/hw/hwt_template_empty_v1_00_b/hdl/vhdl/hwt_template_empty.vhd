library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_template_empty is
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Clk : out std_logic;
		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset
		rst           : in std_logic
	);

end hwt_template_empty;

architecture implementation of hwt_template_empty is
	type STATE_TYPE is ( STATE_GET, STATE_PUT, STATE_THREAD_EXIT );

	-- PUT YOUR OWN COMPONENTS HERE

    -- END OF YOUR OWN COMPONENTS
	

    -- ADD YOUR CONSTANTS, TYPES AND SIGNALS BELOW

	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal data     : std_logic_vector(31 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);

	signal sort_start : std_logic := '0';
	signal sort_done  : std_logic := '0';
begin
	

    -- PUT YOUR OWN INSTANCES HERE

    -- END OF YOUR OWN INSTANCES

	fsl_setup(
		i_osif,
		o_osif,
		OSFSL_Clk,
		OSFSL_Rst,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
		
	memif_setup(
		i_memif,
		o_memif,
		OSFSL_Clk,
		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
    -- PUT YOUR OWN PROCESSES HERE
	
	-- END OF YOUR OWN PROCESSES


    -- ADJUST THE RECONOS_FSM TO YOUR NEEDS.		
	-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			state <= STATE_GET;


            -- RESET YOUR OWN SIGNALS HERE

		elsif rising_edge(i_osif.clk) then
			case state is

                -- EXAMPLE STATE MACHINE - ADD YOUR STATES AS NEEDED

				-- Get some data
				when STATE_GET =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
					if done then
						if (data = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							state <= STATE_PUT;
						end if;
					end if;
				
				
				-- Echo the data
				when STATE_PUT =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, data, ignore, done);
					if done then state <= STATE_GET; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
			
			end case;
		end if;
	end process;
	
end architecture;
