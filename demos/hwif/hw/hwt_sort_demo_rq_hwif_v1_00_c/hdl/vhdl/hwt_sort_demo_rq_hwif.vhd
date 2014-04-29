library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_sort_demo_rq_hwif is
  generic(
      C_SLV_DWIDTH        : integer                       := 32
      );
  port (
    -- OSIF FSL

    OSFSL_S_Read    : out std_logic;  -- Read signal, requiring next available input to be read
    OSFSL_S_Data    : in  std_logic_vector(0 to 31);  -- Input data
    OSFSL_S_Control : in  std_logic;  -- Control Bit, indicating the input data are control word
    OSFSL_S_Exists  : in  std_logic;  -- Data Exist Bit, indicating data exist in the input FSL bus

    OSFSL_M_Write   : out std_logic;  -- Write signal, enabling writing to output FSL bus
    OSFSL_M_Data    : out std_logic_vector(0 to 31);  -- Output data
    OSFSL_M_Control : out std_logic;  -- Control Bit, indicating the output data are contol word
    OSFSL_M_Full    : in  std_logic;  -- Full Bit, indicating output FSL bus is full

    -- FIFO Interface
    FIFO32_S_Data : in  std_logic_vector(31 downto 0);
    FIFO32_M_Data : out std_logic_vector(31 downto 0);
    FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
    FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
    FIFO32_S_Rd   : out std_logic;
    FIFO32_M_Wr   : out std_logic;

    -- Hardware Interface HWIF
    HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
    HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    HWIF2DEC_RdCE  : in  std_logic;
    HWIF2DEC_WrCE  : in  std_logic;
    DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2HWIF_RdAck : out std_logic;
    DEC2HWIF_WrAck : out std_logic;

    debug: out std_logic_vector(209 downto 0);
    
    -- HWT reset and clock
    clk : in std_logic;
    rst : in std_logic
    );

end entity;

architecture implementation of hwt_sort_demo_rq_hwif is
  type STATE_TYPE is (
    STATE_GET_LENGTH, STATE_SET_RAM_ADDRESS, STATE_READ_RAM,
    STATE_READ, STATE_SORTING, STATE_WRITE, STATE_THREAD_YIELD,
    STATE_THREAD_EXIT);

  component bubble_sorter is
    generic (
      G_LEN    : integer := 512;        -- number of words to sort
      G_AWIDTH : integer := 9;          -- in bits
      G_DWIDTH : integer := 32          -- in bits
      );

    port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      -- local ram interface
      o_RAMAddr : out std_logic_vector(0 to G_AWIDTH-1);
      o_RAMData : out std_logic_vector(0 to G_DWIDTH-1);
      i_RAMData : in  std_logic_vector(0 to G_DWIDTH-1);
      o_RAMWE   : out std_logic;
      start     : in  std_logic;
      done      : out std_logic
      );
  end component;

  component hwif_subsystem is
    generic(
      C_HWT_ID            : std_logic_vector(31 downto 0) := X"DEADDEAD";  -- Unique ID number of this module
      C_VERSION           : std_logic_vector(31 downto 0) := X"00000100";  -- Version Identifier
      C_CAPABILITIES      : std_logic_vector(31 downto 0) := X"00000001";  --Every Bit specifies a capability like performance monitoring etc.
      C_Perf_Counters_Num : integer                       := 8;  -- How many performance counters do you want?
      C_SLV_DWIDTH        : integer                       := 32
      );
    port (
      -- HWIF interface
      HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
      HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      HWIF2DEC_RdCE  : in  std_logic;
      HWIF2DEC_WrCE  : in  std_logic;
      DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
      DEC2HWIF_RdAck : out std_logic;
      DEC2HWIF_WrAck : out std_logic;

      -- in-/outputs of internal submodules
      increments : in std_logic_vector (C_Perf_Counters_Num-1 downto 0);
      -- other
      debug      : out std_logic_vector(109 downto 0);
      clk        : in std_logic;
      rst        : in std_logic);
  end component;

  -- The sorting application reads 'C_LOCAL_RAM_SIZE' 32-bit words into the local RAM,
  -- from a given address (send in a message box), sorts them and writes them back into main memory.

  -- IMPORTANT: define size of local RAM here!!!! 
  constant C_LOCAL_RAM_SIZE          : integer := 2048;
  constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
  constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

  type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);

  constant RQ_RECV : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
  constant RQ_SEND : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

  constant C_Perf_Counters_Num : integer := 8;  -- How many performance counters do you want?
  
  signal data_len : std_logic_vector(31 downto 0);
  signal result   : std_logic_vector(31 downto 0);
  signal state    : STATE_TYPE;
  signal i_osif   : i_osif_t;
  signal o_osif   : o_osif_t;
  signal i_memif  : i_memif_t;
  signal o_memif  : o_memif_t;
  signal i_ram    : i_ram_t;
  signal o_ram    : o_ram_t;

  signal o_RAMAddr_sorter : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
  signal o_RAMData_sorter : std_logic_vector(0 to 31);
  signal o_RAMWE_sorter   : std_logic;
  signal i_RAMData_sorter : std_logic_vector(0 to 31);

  signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
  signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
  signal o_RAMData_reconos   : std_logic_vector(0 to 31);
  signal o_RAMWE_reconos     : std_logic;
  signal i_RAMData_reconos   : std_logic_vector(0 to 31);

  constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others => '1');

  shared variable local_ram : LOCAL_MEMORY_T;

  signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

  signal sort_start : std_logic := '0';
  signal sort_done  : std_logic := '0';

  signal increments : std_logic_vector (C_Perf_Counters_Num-1 downto 0);

  signal debugged_DEC2HWIF_Data : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal debugged_DEC2HWIF_RdAck: std_logic;
  signal debugged_DEC2HWIF_WrAck: std_logic;
  signal hwif_subsystem_rst : std_logic := '0';  -- decouple hwif reset from hw
                                               -- thread reset
  
begin

  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------

  
  debug(99 downto 68) <=  HWIF2DEC_Addr;
  debug(67 downto 36 ) <= HWIF2DEC_Data;
  debug(35) <= HWIF2DEC_RdCE;
  debug(34) <= HWIF2DEC_WrCE;
  debug(33 downto 2 ) <= debugged_DEC2HWIF_Data;
  debug(1) <= debugged_DEC2HWIF_RdAck;
  debug(0) <= debugged_DEC2HWIF_WrAck;

  DEC2HWIF_Data  <= debugged_DEC2HWIF_Data  ;
  DEC2HWIF_RdAck <= debugged_DEC2HWIF_RdAck ;
  DEC2HWIF_WrAck <= debugged_DEC2HWIF_WrAck ; 
  
  -- local dual-port RAM
  local_ram_ctrl_1 : process (clk) is
  begin
    if (rising_edge(clk)) then
      if (o_RAMWE_reconos = '1') then
        local_ram(conv_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
      else
        i_RAMData_reconos <= local_ram(conv_integer(unsigned(o_RAMAddr_reconos)));
      end if;
    end if;
  end process;

  local_ram_ctrl_2 : process (clk) is
  begin
    if (rising_edge(clk)) then
      if (o_RAMWE_sorter = '1') then
        local_ram(conv_integer(unsigned(o_RAMAddr_sorter))) := o_RAMData_sorter;
      else
        i_RAMData_sorter <= local_ram(conv_integer(unsigned(o_RAMAddr_sorter)));
      end if;
    end if;
  end process;


  -- instantiate bubble_sorter module
  sorter_i : bubble_sorter
    generic map (
      G_LEN    => C_LOCAL_RAM_SIZE,
      G_AWIDTH => C_LOCAL_RAM_ADDRESS_WIDTH,
      G_DWIDTH => 32
      )
    port map (
      clk       => clk,
      reset     => rst,
      o_RAMAddr => o_RAMAddr_sorter,
      o_RAMData => o_RAMData_sorter,
      i_RAMData => i_RAMData_sorter,
      o_RAMWE   => o_RAMWE_sorter,
      start     => sort_start,
      done      => sort_done
      );

  hwif : hwif_subsystem
    generic map(
      C_HWT_ID            => X"DEADDEAD",  -- Unique ID number of this module
      C_VERSION           => X"00000100",  -- Version Identifier
      C_CAPABILITIES      => X"00000001",  --Every Bit specifies a capability like performance monitoring etc.
      C_Perf_Counters_Num => C_Perf_Counters_Num,  -- How many performance counters do you want?
      C_SLV_DWIDTH        => 32
      )
  port map(
    -- HWIF interface
    HWIF2DEC_Addr  => HWIF2DEC_Addr,
    HWIF2DEC_Data  => HWIF2DEC_Data,
    HWIF2DEC_RdCE  => HWIF2DEC_RdCE,
    HWIF2DEC_WrCE  => HWIF2DEC_WrCE,
    DEC2HWIF_Data  => debugged_DEC2HWIF_Data,
    DEC2HWIF_RdAck => debugged_DEC2HWIF_RdAck,
    DEC2HWIF_WrAck => debugged_DEC2HWIF_WrAck,

    -- in-/outputs of internal submodules
    increments => increments,
    -- other
    debug      => debug(209 downto 100),
    clk        => clk,
    rst        => hwif_subsystem_rst);
 

fsl_setup(
  i_osif,
  o_osif,
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
  FIFO32_S_Data,
  FIFO32_S_Fill,
  FIFO32_S_Rd,
  FIFO32_M_Data,
  FIFO32_M_Rem,
  FIFO32_M_Wr
  );

ram_setup(
  i_ram,
  o_ram,
  o_RAMAddr_reconos_2,
  o_RAMData_reconos,
  i_RAMData_reconos,
  o_RAMWE_reconos
  );

o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);

-- os and memory synchronisation state machine
reconos_fsm : process (clk, rst, o_osif, o_memif, o_ram) is
  variable done : boolean;
begin
  if rst = '1' then
    osif_reset(o_osif);
    memif_reset(o_memif);
    ram_reset(o_ram);
    state      <= STATE_THREAD_YIELD;
    done       := false;
    data_len   <= (others => '0');
    result     <= (others => '0');
    sort_start <= '0';
  elsif rising_edge(clk) then
    case state is
      -- signal to runtime system we don't have any state now and are ready to be replaced
      -- with another thread
      when STATE_THREAD_YIELD =>
        increments <= (7 => '1', others=>'0');
        -- return value is stored to data_len, because it is not needed and data_len will 
        -- be overwritten in next state.
        osif_thread_yield(i_osif, o_osif, data_len, done);
        if done then
          state <= STATE_GET_LENGTH;
        end if;

      -- get data length via reconos queue
      when STATE_GET_LENGTH =>
        increments <= (6 => '1', others=>'0');
        osif_rq_receive (i_osif, o_osif, i_ram, o_ram, RQ_RECV, X"00000004", X"00000000", result, done);
        if done then
          o_ram.addr <= (others => '0');
          state      <= STATE_SET_RAM_ADDRESS;
        end if;

      -- length parameter is now in RAM; set RAM Address to get it back
      when STATE_SET_RAM_ADDRESS =>
        increments <= (5 => '1', others=>'0');
        o_ram.addr <= (others => '0');
        state      <= STATE_READ_RAM;

      -- length parameter is in RAM; address set, now read it
      when STATE_READ_RAM =>
        increments <= (4 => '1', others=>'0');
        data_len <= i_ram.data;
        if (i_ram.data = X"FFFFFFFF") then
          -- exit command received
          state <= STATE_THREAD_EXIT;
        else
          o_ram.addr <= (others => '0');
          state      <= STATE_READ;
        end if;

      -- copy data via reconos queue
      when STATE_READ =>
        increments <= (3 => '1', others=>'0');
        osif_rq_receive (i_osif, o_osif, i_ram, o_ram, RQ_RECV, data_len, X"00000000", result, done);
        if done then
          sort_start <= '1';
          state      <= STATE_SORTING;
        end if;

      -- sort the words in local RAM
      when STATE_SORTING =>
        increments <= (2 => '1', others=>'0');
        sort_start <= '0';
        if sort_done = '1' then
          state <= STATE_WRITE;
        end if;

      -- copy data from local memory to main memory
      when STATE_WRITE =>
        increments <= (1 => '1', others=>'0');
        osif_rq_send (i_osif, o_osif, i_ram, o_ram, RQ_SEND, data_len, X"00000000", result, done);
        if done then
          state <= STATE_THREAD_YIELD;
        end if;

      -- thread exit
      when STATE_THREAD_EXIT =>
        increments <= (0 => '1', others=>'0');
        osif_thread_exit(i_osif, o_osif);
        
    end case;
  end if;
end process;

end architecture;
