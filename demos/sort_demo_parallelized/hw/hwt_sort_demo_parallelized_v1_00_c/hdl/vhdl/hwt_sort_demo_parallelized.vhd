library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_01_a;
use reconos_v3_01_a.reconos_pkg.all;

-- Available Slice LUTs: 150720
-- C_NUM_ENGINES  Max MHz Slice LUTs
--             1  249.688 671
--             2  233.427 1002
--             4  192.976 1617
--             8  188.005 2640
--            16  171.409 4682
--            32  157.418 9913
--            64  144.602 22063
--           128  143.936 43268
entity hwt_sort_demo_parallelized is
  generic (
    C_NUM_ENGINES    : integer := 4;  -- How many parallel working engines do you want?
    C_LOCAL_RAM_SIZE : integer := 2048  -- Blocksize every engine operates
                                        -- on (in words).
    );
  port (
    -- OSIF FIFO ports
    OSIF_FIFO_Sw2Hw_Data  : in  std_logic_vector(31 downto 0);
    OSIF_FIFO_Sw2Hw_Fill  : in  std_logic_vector(15 downto 0);
    OSIF_FIFO_Sw2Hw_Empty : in  std_logic;
    OSIF_FIFO_Sw2Hw_RE    : out std_logic;

    OSIF_FIFO_Hw2Sw_Data : out std_logic_vector(31 downto 0);
    OSIF_FIFO_Hw2Sw_Rem  : in  std_logic_vector(15 downto 0);
    OSIF_FIFO_Hw2Sw_Full : in  std_logic;
    OSIF_FIFO_Hw2Sw_WE   : out std_logic;

    -- MEMIF FIFO ports
    MEMIF_FIFO_Hwt2Mem_Data : out std_logic_vector(31 downto 0);
    MEMIF_FIFO_Hwt2Mem_Rem  : in  std_logic_vector(15 downto 0);
    MEMIF_FIFO_Hwt2Mem_Full : in  std_logic;
    MEMIF_FIFO_Hwt2Mem_WE   : out std_logic;

    MEMIF_FIFO_Mem2Hwt_Data  : in  std_logic_vector(31 downto 0);
    MEMIF_FIFO_Mem2Hwt_Fill  : in  std_logic_vector(15 downto 0);
    MEMIF_FIFO_Mem2Hwt_Empty : in  std_logic;
    MEMIF_FIFO_Mem2Hwt_RE    : out std_logic;

    HWT_Clk : in std_logic;
    HWT_Rst : in std_logic;

    DEBUG_DATA : out std_logic_vector(5 downto 0)
    );

  attribute SIGIS : string;

  attribute SIGIS of HWT_Clk : signal is "Clk";
  attribute SIGIS of HWT_Rst : signal is "Rst";

end entity hwt_sort_demo_parallelized;

architecture implementation of hwt_sort_demo_parallelized is
  -- just for simpler use
  signal clk : std_logic;
  signal rst : std_logic;

  type STATE_TYPE is (
    STATE_GET_ADDR, STATE_READ, STATE_SORTING,
    STATE_WRITE, STATE_ACK, STATE_THREAD_EXIT);

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


  -- The sorting application reads 'C_LOCAL_RAM_SIZE' 32-bit words into the local RAM,
  -- from a given address (send in a message box), sorts them and writes them back into main memory.

  -- IMPORTANT: define size of local RAM here!!!! 
  --constant C_LOCAL_RAM_SIZE          : integer := 2048;
  constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
  constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

  type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
  type LOCAL_MEMORY_ARRAY_T is array (0 to C_NUM_ENGINES) of LOCAL_MEMORY_T;

  constant MBOX_RECV : std_logic_vector(31 downto 0) := x"00000000";
  constant MBOX_SEND : std_logic_vector(31 downto 0) := x"00000001";

  signal addr    : std_logic_vector(31 downto 0);
  signal len     : std_logic_vector(23 downto 0);
  signal state   : STATE_TYPE;
  signal i_osif  : i_osif_t;
  signal o_osif  : o_osif_t;
  signal i_memif : i_memif_t;
  signal o_memif : o_memif_t;

  type i_ram_array_t is array (integer range<>) of i_ram_t;
  type o_ram_array_t is array (integer range<>) of o_ram_t;
  signal i_ram : i_ram_array_t(0 to C_NUM_ENGINES-1);
  signal o_ram : o_ram_array_t(0 to C_NUM_ENGINES-1);

  type ENGINE_ARRAY_T is array (0 to C_NUM_ENGINES-1) of std_logic_vector(0 to 31);
  type ENGINE_ARRAY_LOCAL_ADDR_T is array (0 to C_NUM_ENGINES-1) of std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
  type ENGINE_T is array (0 to C_NUM_ENGINES-1) of std_logic;

  signal o_RAMAddr_sorter : ENGINE_ARRAY_LOCAL_ADDR_T;
  signal o_RAMData_sorter : ENGINE_ARRAY_T;
  signal o_RAMWE_sorter   : ENGINE_T;
  signal i_RAMData_sorter : ENGINE_ARRAY_T;

  signal o_RAMAddr_reconos   : ENGINE_ARRAY_LOCAL_ADDR_T;
  signal o_RAMAddr_reconos_2 : ENGINE_ARRAY_T;
  signal o_RAMData_reconos   : ENGINE_ARRAY_T;
  signal o_RAMWE_reconos     : ENGINE_T;
  signal i_RAMData_reconos   : ENGINE_ARRAY_T;

  constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others => '1');

  shared variable local_ram : LOCAL_MEMORY_ARRAY_T;

  signal ignore : std_logic_vector(31 downto 0);

  signal sort_start : ENGINE_T;
  signal sort_done  : ENGINE_T;
begin

  DEBUG_DATA(5) <= '1' when state = STATE_GET_ADDR    else '0';
  DEBUG_DATA(4) <= '1' when state = STATE_READ        else '0';
  DEBUG_DATA(3) <= '1' when state = STATE_SORTING     else '0';
  DEBUG_DATA(2) <= '1' when state = STATE_WRITE       else '0';
  DEBUG_DATA(1) <= '1' when state = STATE_ACK         else '0';
  DEBUG_DATA(0) <= '1' when state = STATE_THREAD_EXIT else '0';

  clk <= HWT_Clk;
  rst <= HWT_Rst;

  memories : for i in 0 to C_NUM_ENGINES-1 generate

    -- local dual-port RAM
    local_ram_ctrl_1 : process (clk) is
    begin
      if (rising_edge(clk)) then
        if (o_RAMWE_reconos(i) = '1') then
          local_ram(i)(conv_integer(unsigned(o_RAMAddr_reconos(i)))) := o_RAMData_reconos(i);
        else
          i_RAMData_reconos(i) <= local_ram(i)(conv_integer(unsigned(o_RAMAddr_reconos(i))));
        end if;
      end if;
    end process;

    local_ram_ctrl_2 : process (clk) is
    begin
      if (rising_edge(clk)) then
        if (o_RAMWE_sorter(i) = '1') then
          local_ram(i)(conv_integer(unsigned(o_RAMAddr_sorter(i)))) := o_RAMData_sorter(i);
        else
          i_RAMData_sorter(i) <= local_ram(i)(conv_integer(unsigned(o_RAMAddr_sorter(i))));
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
        o_RAMAddr => o_RAMAddr_sorter(i),
        o_RAMData => o_RAMData_sorter(i),
        i_RAMData => i_RAMData_sorter(i),
        o_RAMWE   => o_RAMWE_sorter(i),
        start     => sort_start(i),
        done      => sort_done(i)
        );

    ram_setup (
      i_ram(i),
      o_ram(i),
      o_RAMAddr_reconos_2(i),
      o_RAMWE_reconos(i),
      o_RAMData_reconos(i),
      i_RAMData_reconos(i)
      );

    o_RAMAddr_reconos(i)(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2(i)((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);
  end generate memories;

  -- ReconOS initilization
  osif_setup (
    i_osif,
    o_osif,
    OSIF_FIFO_Sw2Hw_Data,
    OSIF_FIFO_Sw2Hw_Fill,
    OSIF_FIFO_Sw2Hw_Empty,
    OSIF_FIFO_Hw2Sw_Rem,
    OSIF_FIFO_Hw2Sw_Full,
    OSIF_FIFO_Sw2Hw_RE,
    OSIF_FIFO_Hw2Sw_Data,
    OSIF_FIFO_Hw2Sw_WE
    );

  memif_setup (
    i_memif,
    o_memif,
    MEMIF_FIFO_Mem2Hwt_Data,
    MEMIF_FIFO_Mem2Hwt_Fill,
    MEMIF_FIFO_Mem2Hwt_Empty,
    MEMIF_FIFO_Hwt2Mem_Rem,
    MEMIF_FIFO_Hwt2Mem_Full,
    MEMIF_FIFO_Mem2Hwt_RE,
    MEMIF_FIFO_Hwt2Mem_Data,
    MEMIF_FIFO_Hwt2Mem_WE
    );

  -- os and memory synchronisation state machine
  reconos_fsm : process (clk, rst, o_osif, o_memif, o_ram) is
    variable done   : boolean;
    variable engine : integer := 0;
  begin
    if rst = '1' then
      osif_reset(o_osif);
      memif_reset(o_memif);
      for i in 0 to C_NUM_ENGINES-1 loop
        ram_reset(o_ram(i));
      end loop;  -- i
      state      <= STATE_GET_ADDR;
      done       := false;
      engine     := 0;
      addr       <= (others => '0');
      len        <= (others => '0');
      sort_start <= (others => '0');
    elsif rising_edge(clk) then
      case state is

        -- get address via mbox: the data will be copied from this address to the local ram in the next states
        when STATE_GET_ADDR =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr, done);
          if done then
            if (addr = X"FFFFFFFF") then
              state <= STATE_THREAD_EXIT;
            else
              len   <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24);
              addr  <= addr(31 downto 2) & "00";
              state <= STATE_READ;
            end if;
          end if;

        -- copy data from main memory to local memory
        when STATE_READ =>
          memif_read(i_ram(engine), o_ram(engine), i_memif, o_memif, addr+engine*C_LOCAL_RAM_SIZE_IN_BYTES, X"00000000", len, done);
          if done then
            engine := engine +1;
            len    <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24);
          end if;
          if engine >= C_NUM_ENGINES then
            sort_start <= (others => '1');
            state      <= STATE_SORTING;
            engine     := 0;
          end if;

        -- sort the words in local RAM
        when STATE_SORTING =>
          sort_start <= (others  => '0');
                                        --o_ram.addr <= (others => '0');
          if sort_done = (others => '1') then
            len   <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24);
                                        --state  <= STATE_WRITE_REQ;
            state <= STATE_WRITE;
          end if;

        -- copy data from local memory to main memory
        when STATE_WRITE =>
          memif_write(i_ram(engine), o_ram(engine), i_memif, o_memif, X"00000000", addr+engine*C_LOCAL_RAM_SIZE_IN_BYTES, len, done);
          if done then
            engine := engine +1;
            len    <= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24);
          end if;
          if engine >= C_NUM_ENGINES then
            state <= STATE_ACK;
          end if;

        -- send mbox that signals that the sorting is finished
        when STATE_ACK =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND, addr, ignore, done);
          if done then state <= STATE_GET_ADDR; end if;

        -- thread exit
        when STATE_THREAD_EXIT =>
          osif_thread_exit(i_osif, o_osif);
          
      end case;
    end if;
  end process;
  
end architecture;
