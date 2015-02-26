library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_icap is
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

    -- HWT reset and clock
    clk : in std_logic;
    rst : in std_logic
    );
end entity;

architecture implementation of hwt_icap is
  -----------------------------------------------------------------------------
  -- components
  -----------------------------------------------------------------------------
  component ICAPFsm
    generic (
      ADDR_WIDTH : natural);
    port (
      ClkxCI        : in  std_logic;
      ResetxRI      : in  std_logic;
      StartxSI      : in  std_logic;
      DonexSO       : out std_logic;
      ErrorxSO      : out std_logic;
      LenxDI        : in  std_logic_vector(0 to ADDR_WIDTH);
      RamAddrxDO    : out std_logic_vector(0 to ADDR_WIDTH-1);
      ICAPCExSBO    : out std_logic;
      ICAPWExSBO    : out std_logic;
      ICAPStatusxDI : in  std_logic_vector(0 to 31));
  end component;

  component ICAPWrapper
    generic (
      ICAP_WIDTH : natural);
    port (
      clk   : in  std_logic;
      csb   : in  std_logic;
      rdwrb : in  std_logic;
      i     : in  std_logic_vector(0 to ICAP_WIDTH-1);
      busy  : out std_logic;
      o     : out std_logic_vector(0 to ICAP_WIDTH-1));
  end component;

  -----------------------------------------------------------------------------
  -- signals
  -----------------------------------------------------------------------------
  type STATE_TYPE is (STATE_GET_BITSTREAM_ADDR, STATE_GET_BITSTREAM_SIZE, STATE_THREAD_EXIT,
                      STATE_FINISHED, STATE_ERROR, STATE_CMPLEN, STATE_FETCH_MEM,
                      STATE_ICAP_TRANSFER, STATE_MEM_CALC);

  constant MBOX_RECV   : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
  constant MBOX_SEND   : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";
  constant RESULT_OK   : std_logic_vector(31 downto 0)            := x"00001337";
  constant RESULT_FAIL : std_logic_vector(31 downto 0)            := x"00000666";
  constant ICAP_WIDTH  : integer                                  := 32;

  constant C_LOCAL_RAM_SIZE          : integer := 2048;  -- in words
  constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
  constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

  type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);

  signal state   : STATE_TYPE;
  signal i_osif  : i_osif_t;
  signal o_osif  : o_osif_t;
  signal i_memif : i_memif_t;
  signal o_memif : o_memif_t;
  signal i_ram   : i_ram_t;
  signal o_ram   : o_ram_t;

  -- local FSM RAM signals
  signal ICAPRamAddrxD : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);  -- in words
  signal ICAPRamOutxD  : std_logic_vector(0 to 31);
  signal ICAPRamWExD   : std_logic;
  signal ICAPRamInxD   : std_logic_vector(0 to 31);

  -- reconos RAM signals
  signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
  signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
  signal o_RAMData_reconos   : std_logic_vector(0 to 31);
  signal o_RAMWE_reconos     : std_logic;
  signal i_RAMData_reconos   : std_logic_vector(0 to 31);

  constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others => '1');

  shared variable local_ram : LOCAL_MEMORY_T;

  signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

  -- registers
  signal AddrxD : std_logic_vector(31 downto 0);  -- in bytes
  signal LenxD  : std_logic_vector(31 downto 0);  -- in bytes
  signal LastxD : std_logic;

  -- icap signals
  signal ICAPBusyxS    : std_logic;
  signal ICAPCExSB     : std_logic;
  signal ICAPWExSB     : std_logic;
  signal ICAPDataOutxD : std_logic_vector(0 to ICAP_WIDTH-1);

  signal ICAPFsmStartxS : std_logic;
  signal ICAPFsmDonexS  : std_logic;
  signal ICAPFsmErrorxS : std_logic;
  signal ICAPFsmLenxD   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH);  -- in words

begin

  -- setup osif, memif, local ram
  fsl_setup(i_osif, o_osif, OSFSL_S_Data, OSFSL_S_Exists, OSFSL_M_Full, OSFSL_M_Data, OSFSL_S_Read, OSFSL_M_Write, OSFSL_M_Control);
  memif_setup(i_memif, o_memif, FIFO32_S_Data, FIFO32_S_Fill, FIFO32_S_Rd, FIFO32_M_Data, FIFO32_M_Rem, FIFO32_M_Wr);
  ram_setup(i_ram, o_ram, o_RAMAddr_reconos_2, o_RAMData_reconos, i_RAMData_reconos, o_RAMWE_reconos);

  -----------------------------------------------------------------------------
  -- local dual-port ram
  -----------------------------------------------------------------------------

  -- reconos port
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

  o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);

  -- local FSM port
  local_ram_ctrl_2 : process (clk) is
  begin
    if (rising_edge(clk)) then
      if (ICAPRamWExD = '1') then
        local_ram(conv_integer(unsigned(ICAPRamAddrxD))) := ICAPRamInxD;
      else
        ICAPRamOutxD <= local_ram(conv_integer(unsigned(ICAPRamAddrxD)));
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Reconos FSM
  -- os and memory synchronisation state machine
  -----------------------------------------------------------------------------
  reconos_fsm : process (clk, rst, o_osif) is
    variable done : boolean;
  begin
    if rst = '1' then
      osif_reset(o_osif);
      memif_reset(o_memif);
      ram_reset(o_ram);
      state <= STATE_GET_BITSTREAM_ADDR;
      done  := false;

      AddrxD <= (others => '0');
      LenxD  <= (others => '0');
      LastxD <= '0';
    elsif rising_edge(clk) then

      -- default assignments
      ICAPFsmLenxD   <= conv_std_logic_vector(C_LOCAL_RAM_SIZE, C_LOCAL_RAM_ADDRESS_WIDTH + 1);
      ICAPFsmStartxS <= '0';

      case state is
        -----------------------------------------------------------------------
        -- get mem address
        -----------------------------------------------------------------------
        when STATE_GET_BITSTREAM_ADDR =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, AddrxD, done);

          if done then
            if (AddrxD = X"FFFFFFFF") then
              state <= STATE_THREAD_EXIT;
            else
              state <= STATE_GET_BITSTREAM_SIZE;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- get bitstream len
          ---------------------------------------------------------------------
        when STATE_GET_BITSTREAM_SIZE =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, LenxD, done);

          if done then
            if (LenxD = X"FFFFFFFF") then
              state <= STATE_THREAD_EXIT;
            else
              state <= STATE_CMPLEN;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- Compare the remaining length of the bitstream with the size of our
          -- memory
          ---------------------------------------------------------------------
        when STATE_CMPLEN =>
          if LenxD <= C_LOCAL_RAM_SIZE_IN_BYTES then
            LastxD <= '1';
          else
            LastxD <= '0';
          end if;

          state <= STATE_FETCH_MEM;

          ---------------------------------------------------------------------
          -- Copy data from main memory to our local memory
          ---------------------------------------------------------------------
        when STATE_FETCH_MEM =>
          if LastxD = '1' then
            -- LenxD is smaller than the size of local memory, so we only fill
            -- it partially
            memif_read(i_ram, o_ram, i_memif, o_memif, AddrxD, X"00000000",
                       LenxD(23 downto 0), done);
          else
            -- completely fill our local memory
            memif_read(i_ram, o_ram, i_memif, o_memif, AddrxD, X"00000000",
                       conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24), done);
          end if;

          if done then
            state <= STATE_ICAP_TRANSFER;
          end if;

          ---------------------------------------------------------------------
          -- Send the data in our local memory to the ICAP port
          ---------------------------------------------------------------------
        when STATE_ICAP_TRANSFER =>
          ICAPFsmStartxS <= '1';

          if LastxD = '1' then
            -- the remaining size is less than our local memory size
            -- convert length from bytes to words here
            ICAPFsmLenxD <= LenxD(C_LOCAL_RAM_ADDRESS_WIDTH + 2 downto 2);
          else
            -- transfer the content of the full memory to ICAP
            ICAPFsmLenxD <= conv_std_logic_vector(C_LOCAL_RAM_SIZE, C_LOCAL_RAM_ADDRESS_WIDTH + 1);
          end if;

          if ICAPFsmErrorxS = '1' then
            state <= STATE_ERROR;
          else
            if ICAPFsmDonexS = '1' then
              if LastxD = '1' then
                state <= STATE_FINISHED;
              else
                state <= STATE_MEM_CALC;
              end if;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- Calculate the remaining length of the bitfile and the new address
          ---------------------------------------------------------------------
        when STATE_MEM_CALC =>
          AddrxD <= AddrxD + C_LOCAL_RAM_SIZE_IN_BYTES;
          LenxD  <= LenxD - C_LOCAL_RAM_SIZE_IN_BYTES;

          state <= STATE_CMPLEN;

          ---------------------------------------------------------------------
          -- Oops, an error occurred! Tell the software that we are in trouble
          ---------------------------------------------------------------------
        when STATE_ERROR =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND, RESULT_FAIL, ignore, done);

          if done then
            state <= STATE_GET_BITSTREAM_ADDR;
          end if;

          ---------------------------------------------------------------------
          -- We are finished, send message
          ---------------------------------------------------------------------
        when STATE_FINISHED =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND, RESULT_OK, ignore, done);

          if done then
            state <= STATE_GET_BITSTREAM_ADDR;
          end if;

          ---------------------------------------------------------------------
          -- thread exit
          ---------------------------------------------------------------------
        when STATE_THREAD_EXIT =>
          osif_thread_exit(i_osif, o_osif);
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- ICAP wrapper, the wrapper just passes through the signals
  -- It mainly exists to make simulation easier as we can just replace the
  -- wrapper for simulation runs
  -----------------------------------------------------------------------------
  icapWrapperInst : ICAPWrapper
    generic map (
      ICAP_WIDTH => ICAP_WIDTH
      )
    port map (
      clk   => clk,
      csb   => ICAPCExSB,               -- active low
      rdwrb => ICAPWExSB,               -- active low
      i     => ICAPRamOutxD,
      busy  => ICAPBusyxS,
      o     => ICAPDataOutxD);

  -----------------------------------------------------------------------------
  -- ICAPFsm
  -----------------------------------------------------------------------------
  ICAPFsmInst : ICAPFsm
    generic map (
      ADDR_WIDTH => C_LOCAL_RAM_ADDRESS_WIDTH)
    port map (
      ClkxCI        => clk,
      ResetxRI      => rst,
      StartxSI      => ICAPFsmStartxS,
      DonexSO       => ICAPFsmDonexS,
      ErrorxSO      => ICAPFsmErrorxS,
      LenxDI        => ICAPFsmLenxD,
      RamAddrxDO    => ICAPRamAddrxD,
      ICAPCExSBO    => ICAPCExSB,
      ICAPWExSBO    => ICAPWExSB,
      ICAPStatusxDI => ICAPDataOutxD);


  -----------------------------------------------------------------------------
  -- concurrent signal assignments
  -----------------------------------------------------------------------------

  ICAPRamInxD <= (others => '0');
  ICAPRamWExD <= '0';

end architecture;

