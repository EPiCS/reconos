library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;


entity hwt_add is
-- generic (
-- destination : std_logic_vector(5 downto 0);
-- sender : std_logic
-- );
port (
-- OSIF FSL
OSFSL_Clk : in std_logic; -- Synchronous clock
OSFSL_Rst : in std_logic;
OSFSL_S_Clk : out std_logic; -- Slave asynchronous clock
OSFSL_S_Read : out std_logic; -- Read signal, requiring next available input to be read
OSFSL_S_Data : in std_logic_vector(0 to 31); -- Input data
OSFSL_S_Control : in std_logic; -- Control Bit, indicating the input data are control word
OSFSL_S_Exists : in std_logic; -- Data Exist Bit, indicating data exist in the input FSL bus
OSFSL_M_Clk : out std_logic; -- Master asynchronous clock
OSFSL_M_Write : out std_logic; -- Write signal, enabling writing to output FSL bus
OSFSL_M_Data : out std_logic_vector(0 to 31); -- Output data
OSFSL_M_Control : out std_logic; -- Control Bit, indicating the output data are contol word
OSFSL_M_Full : in std_logic; -- Full Bit, indicating output FSL bus is full

-- FIFO Interface
--FIFO32_S_Clk : out std_logic;
--FIFO32_M_Clk : out std_logic;
FIFO32_S_Data : in std_logic_vector(31 downto 0);
FIFO32_M_Data : out std_logic_vector(31 downto 0);
FIFO32_S_Fill : in std_logic_vector(15 downto 0);
FIFO32_M_Rem : in std_logic_vector(15 downto 0);
FIFO32_S_Rd : out std_logic;
FIFO32_M_Wr : out std_logic;

-- HWT reset
rst : in std_logic;

switch_data_rdy	: in std_logic;
switch_data	: in std_logic_vector(dataWidth downto 0);
thread_read_rdy	: out std_logic;
switch_read_rdy	: in std_logic;
thread_data	: out std_logic_vector(dataWidth downto 0);
thread_data_rdy : out std_logic

-- downstreamReadEnable : out std_logic; --downstream: from switch to thread
-- downstreamEmpty : in std_logic;
-- downstreamData : in std_logic_vector(8 downto 0);
-- downstreamReadClock : out std_logic;
-- upstreamWriteEnable : out std_logic; -- upstream: from thread to switch
-- upstreamData : out std_logic_vector(8 downto 0);
-- upstreamFull : in std_logic;
-- upstreamWriteClock : out std_logic


-- rx_ll_sof : in std_logic;
-- rx_ll_eof : in std_logic;
-- rx_ll_data : in std_logic_vector(7 downto 0);
-- rx_ll_src_rdy : in std_logic;
-- rx_ll_dst_rdy : out std_logic;
--
-- tx_ll_sof : out std_logic;
-- tx_ll_eof : out std_logic;
-- tx_ll_data : out std_logic_vector(7 downto 0);
-- tx_ll_src_rdy : out std_logic;
-- tx_ll_dst_rdy : in std_logic


);

end hwt_add;

architecture implementation of hwt_add is
type STATE_TYPE is ( STATE_GET, STATE_PUT, STATE_PUT2, STATE_PUT3, STATE_PUT4, STATE_PUT5, STATE_THREAD_EXIT );

-- PUT YOUR OWN COMPONENTS HERE

    -- END OF YOUR OWN COMPONENTS


    -- ADD YOUR CONSTANTS, TYPES AND SIGNALS BELOW

constant MBOX_RECV : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
constant MBOX_SEND : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

signal data : std_logic_vector(31 downto 0);
signal state : STATE_TYPE;
signal i_osif : i_osif_t;
signal o_osif : o_osif_t;
signal i_memif : i_memif_t;
signal o_memif : o_memif_t;
signal i_ram : i_ram_t;
signal o_ram : o_ram_t;

signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
signal testing_state : testing_state_t;
signal testing_state_next : testing_state_t;

type sending_state_t is (S_STATE_INIT, S_STATE_SOF, S_STATE_DATA, S_STATE_EOF, S_STATE_WAIT);
signal sending_state	: sending_state_t;
signal sending_state_next	: sending_state_t;


signal rx_packet_count : std_logic_vector(31 downto 0);
signal rx_packet_count_next : std_logic_vector(31 downto 0);

signal rx_packet_count1 : std_logic_vector(31 downto 0);
signal rx_packet_count1_next : std_logic_vector(31 downto 0);
signal rx_packet_count2 : std_logic_vector(31 downto 0);
signal rx_packet_count2_next : std_logic_vector(31 downto 0);
signal rx_packet_count3 : std_logic_vector(31 downto 0);
signal rx_packet_count3_next : std_logic_vector(31 downto 0);

signal tx_testing_state : testing_state_t;
signal tx_testing_state_next : testing_state_t;

signal tx_packet_count : std_logic_vector(31 downto 0);
signal tx_packet_count_next : std_logic_vector(31 downto 0);

signal rx_ll_dst_rdy_local	: std_logic;

signal tx_ll_sof	: std_logic;
signal tx_ll_eof	: std_logic;
signal tx_ll_data	: std_logic_vector(7 downto 0);
signal tx_ll_src_rdy	: std_logic;
signal tx_ll_dst_rdy	: std_logic;

signal rx_ll_sof	: std_logic;
signal rx_ll_eof	: std_logic;
signal rx_ll_data	: std_logic_vector(7 downto 0);
signal rx_ll_src_rdy	: std_logic;
signal rx_ll_dst_rdy	: std_logic;

signal payload_count : integer range 0 to 1500;
signal payload_count_next : integer range 0 to 1500;

signal direction : std_logic;
signal priority : std_logic_vector(1 downto 0);
signal latency_critical : std_logic;
signal srcIdp : std_logic_vector(31 downto 0);
signal dstIdp : std_logic_vector(31 downto 0);
signal global_addr : std_logic_vector(3 downto 0);
signal local_addr : std_logic_vector(1 downto 0);

begin


    -- PUT YOUR OWN INSTANCES HERE

decoder_inst : packetDecoder
port map (
clk => i_osif.clk,
reset => rst,

-- Signals from the switch
switch_data_rdy	=> switch_data_rdy,
switch_data	=> switch_data,
thread_read_rdy	=> thread_read_rdy,

-- Decoded values of the packet
noc_rx_sof	=> rx_ll_sof,	-- Indicates the start of a new packet
noc_rx_eof	=> rx_ll_eof,	-- Indicates the end of the packet
noc_rx_data	=> rx_ll_data,	-- The current data byte
noc_rx_src_rdy	=> rx_ll_src_rdy, -- '1' if the data are valid, '0' else
noc_rx_direction	=> direction, -- '1' for egress, '0' for ingress
noc_rx_priority	=> priority,	-- The priority of the packet
noc_rx_latencyCritical	=> latency_critical,	-- '1' if this packet is latency critical
noc_rx_srcIdp	=> srcIdp,	-- The source IDP
noc_rx_dstIdp	=> dstIdp,	-- The destination IDP
noc_rx_dst_rdy	=> rx_ll_dst_rdy	-- Read enable for the functional block
);

encoder_inst : packetEncoder
port map(
clk => i_osif.clk,	
reset => rst,	
-- Signals to the switch
switch_read_rdy => switch_read_rdy,
thread_data => thread_data,	
thread_data_rdy => thread_data_rdy,
-- Decoded values of the packet
noc_tx_sof => tx_ll_sof,
noc_tx_eof => tx_ll_eof,
noc_tx_data	=> tx_ll_data,	
noc_tx_src_rdy => tx_ll_src_rdy,	
noc_tx_globalAddress => global_addr, --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)
noc_tx_localAddress => local_addr, --"01",-- (others => '0'), --2 bits
noc_tx_direction => direction,	
noc_tx_priority => priority,	
noc_tx_latencyCritical => latency_critical,	
noc_tx_srcIdp => srcIdp,	
noc_tx_dstIdp => dstIdp,
noc_tx_dst_rdy	=> tx_ll_dst_rdy
);



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
-- FIFO32_S_Clk,
FIFO32_S_Data,
FIFO32_S_Fill,
FIFO32_S_Rd,
-- FIFO32_M_Clk,
FIFO32_M_Data,
FIFO32_M_Rem,
FIFO32_M_Wr
);

    -- PUT YOUR OWN PROCESSES HERE

--simply forward everything...
tx_ll_src_rdy <= rx_ll_src_rdy;
tx_ll_data(7 downto 1) <= rx_ll_data(7 downto 1);
tx_ll_data(0) <= not rx_ll_data(0);
tx_ll_sof <= rx_ll_sof;
tx_ll_eof <= rx_ll_eof;
rx_ll_dst_rdy <= tx_ll_dst_rdy;



--count all rx packets
test_counting : process(rx_ll_sof, rx_ll_src_rdy, rx_ll_dst_rdy, rx_packet_count, testing_state) is
variable tmp : unsigned(31 downto 0);
begin
rx_packet_count_next <= rx_packet_count;
     testing_state_next <= testing_state;
case testing_state is
         when T_STATE_INIT =>
rx_packet_count_next <= (others => '0');
testing_state_next <= T_STATE_RCV;
when T_STATE_RCV =>
if rx_ll_src_rdy = '1' and rx_ll_sof = '1' and rx_ll_dst_rdy = '1' then
tmp := unsigned(rx_packet_count) + 1;
rx_packet_count_next <= std_logic_vector(tmp);
end if;
if rx_ll_sof = '1' then
tmp := unsigned(rx_packet_count1) + 1;
rx_packet_count1_next <= std_logic_vector(tmp);
end if;
if rx_ll_src_rdy = '1' then
tmp := unsigned(rx_packet_count2) + 1;
rx_packet_count2_next <= std_logic_vector(tmp);
end if;
if tx_ll_dst_rdy = '1' then
tmp := unsigned(rx_packet_count3) + 1;
rx_packet_count3_next <= std_logic_vector(tmp);
end if;
when others =>
testing_state_next <= T_STATE_INIT;
end case;
end process;

--count all tx packets
tx_test_counting : process(rx_ll_eof, rx_ll_src_rdy, rx_ll_dst_rdy, tx_packet_count, tx_testing_state) is
variable tmp : unsigned(31 downto 0);
begin
tx_packet_count_next <= tx_packet_count;
     tx_testing_state_next <= tx_testing_state;
case tx_testing_state is
         when T_STATE_INIT =>
tx_packet_count_next <= (others => '0');
tx_testing_state_next <= T_STATE_RCV;
when T_STATE_RCV =>
if rx_ll_src_rdy = '1' and rx_ll_eof = '1' and rx_ll_dst_rdy = '1' then
tmp := unsigned(tx_packet_count) + 1;
tx_packet_count_next <= std_logic_vector(tmp);
end if;
when others =>
tx_testing_state_next <= T_STATE_INIT;
end case;
end process;


--creates flipflops
memzing: process(i_osif.clk, rst) is
begin
if rst = '1' then
rx_packet_count <= (others => '0');	
rx_packet_count1 <= (others => '0');
rx_packet_count2 <= (others => '0');
rx_packet_count3 <= (others => '0');


testing_state <= T_STATE_INIT;
      tx_packet_count <= (others => '0');
tx_testing_state <= T_STATE_INIT;
sending_state <= S_STATE_INIT;
payload_count <= 0;
elsif rising_edge(i_osif.clk) then
rx_packet_count <= rx_packet_count_next;
    rx_packet_count1 <= rx_packet_count1_next;
    rx_packet_count2 <= rx_packet_count2_next;
    rx_packet_count3 <= rx_packet_count3_next;

testing_state <= testing_state_next;
   tx_packet_count <= tx_packet_count_next;
tx_testing_state <= tx_testing_state_next;
sending_state <= sending_state_next;
payload_count <= payload_count_next;
end if;
end process;


-- END OF YOUR OWN PROCESSES
 -- ADJUST THE RECONOS_FSM TO YOUR NEEDS.
-- os and memory synchronisation state machine
reconos_fsm: process (i_osif.clk,rst,o_osif,o_memif,o_ram) is
variable done : boolean;
begin
if rst = '1' then
osif_reset(o_osif);
memif_reset(o_memif);
state <= STATE_GET;
global_addr <= "0001"; --default: send it to the ethernet block
local_addr <= "00";

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
global_addr <= data(5 downto 2);
local_addr <= data(1 downto 0);
state <= STATE_PUT;
end if;
end if;


-- Echo the data
when STATE_PUT =>
osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count, ignore, done);
if done then state <= STATE_PUT2; end if;
when STATE_PUT2 =>
osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count1, ignore, done);
if done then state <= STATE_PUT3; end if;
when STATE_PUT3 =>
osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count2, ignore, done);
if done then state <= STATE_PUT4; end if;
when STATE_PUT4 =>
osif_mbox_put(i_osif, o_osif, MBOX_SEND, rx_packet_count3, ignore, done);
if done then state <= STATE_PUT5; end if;

when STATE_PUT5 =>
osif_mbox_put(i_osif, o_osif, MBOX_SEND, tx_packet_count, ignore, done);
if done then state <= STATE_GET; end if;

-- thread exit
when STATE_THREAD_EXIT =>
osif_thread_exit(i_osif,o_osif);

end case;
end if;
end process;



end architecture;
