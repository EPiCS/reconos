library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library unisim;
use unisim.vcomponents.STARTUP_VIRTEX6;


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
                      STATE_FINISHED, STATE_ERROR, STATE_FETCH_MEM);

  constant MBOX_RECV                 : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
  constant MBOX_SEND                 : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";
  constant RESULT_OK                 : std_logic_vector(31 downto 0)            := x"00001337";
  constant RESULT_FAIL               : std_logic_vector(31 downto 0)            := x"00000666";
  constant ICAP_WIDTH                : integer                                  := 32;
  constant C_LOCAL_RAM_ADDRESS_WIDTH : integer                                  := 32;

  signal state   : STATE_TYPE;
  signal i_osif  : i_osif_t;
  signal o_osif  : o_osif_t;
  signal i_memif : i_memif_t;
  signal o_memif : o_memif_t;
  signal i_ram   : i_ram_t;
  signal o_ram   : o_ram_t;

  -- reconos RAM signals
  signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
  signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
  signal o_RAMData_reconos   : std_logic_vector(0 to 31);
  signal o_RAMWE_reconos     : std_logic;
  signal i_RAMData_reconos   : std_logic_vector(0 to 31);

  constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others => '1');

  signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

  -- registers
  signal AddrxD : std_logic_vector(31 downto 0);  -- in bytes
  signal LenxD  : std_logic_vector(31 downto 0);  -- in bytes

  -- icap signals
  signal ICAPCExSB          : std_logic;
  signal ICAPDataInxD       : std_logic_vector(0 to ICAP_WIDTH-1);
  signal ICAPDataOutxD      : std_logic_vector(0 to ICAP_WIDTH-1);
  signal ICAPErrorxS        : std_logic;
  signal ErrorClearxS       : std_logic;
  signal ErrorxSP, ErrorxSN : std_logic;

begin

  -- setup osif, memif, local ram
  fsl_setup(i_osif, o_osif, OSFSL_S_Data, OSFSL_S_Exists, OSFSL_M_Full, OSFSL_M_Data, OSFSL_S_Read, OSFSL_M_Write, OSFSL_M_Control);
  memif_setup(i_memif, o_memif, FIFO32_S_Data, FIFO32_S_Fill, FIFO32_S_Rd, FIFO32_M_Data, FIFO32_M_Rem, FIFO32_M_Wr);
  ram_setup(i_ram, o_ram, o_RAMAddr_reconos_2, o_RAMData_reconos, i_RAMData_reconos, o_RAMWE_reconos);

  o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);

  -----------------------------------------------------------------------------
  -- Reconos FSM
  -- os and memory synchronisation state machine
  -----------------------------------------------------------------------------
  reconos_fsm : process (clk, rst, o_osif, o_memif, o_ram) is
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
    elsif rising_edge(clk) then
      ErrorClearxS <= '0';

      case state is
        -----------------------------------------------------------------------
        -- get mem address
        -----------------------------------------------------------------------
        when STATE_GET_BITSTREAM_ADDR =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, AddrxD, done);

          ErrorClearxS <= '1';

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
              state <= STATE_FETCH_MEM;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- Copy data from main memory to our local memory
          ---------------------------------------------------------------------
        when STATE_FETCH_MEM =>
          memif_read(i_ram, o_ram, i_memif, o_memif, AddrxD, X"00000000", LenxD(23 downto 0), done);

          if done then
            if ErrorxSP = '1' then
              state <= STATE_ERROR;
            else
              state <= STATE_FINISHED;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- Oops, an error occurred! Tell the software that we are in trouble
          ---------------------------------------------------------------------
        when STATE_ERROR =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND, RESULT_FAIL, ignore, done);

          if done then
            state <= STATE_GET_BITSTREAM_ADDR;
          end if;

          ---------------------------------------------------------------------
          -- We are finished, send a message
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
      rdwrb => '0',                     -- active low
      i     => ICAPDataInxD,
      busy  => open,
      o     => ICAPDataOutxD);

  -----------------------------------------------------------------------------
  -- Error register
  -- we cannot directly look at ICAPErrorxS as this signal is cleared multiple
  -- times by the ICAP interface
  -----------------------------------------------------------------------------
  errorReg : process (clk, rst)
  begin  -- process errorReg
    if rst = '1' then                   -- asynchronous reset (active high)
      ErrorxSP <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      ErrorxSP <= ErrorxSN;
    end if;
  end process errorReg;

  errorComb : process (ErrorClearxS, ErrorxSP, ICAPErrorxS)
  begin  -- process errorComb
    ErrorxSN <= ErrorxSP;

    if ErrorClearxS = '1' then
      ErrorxSN <= '0';
    elsif ICAPErrorxS = '1' then
      ErrorxSN <= '1';
    end if;
  end process errorComb;

  -----------------------------------------------------------------------------
  -- concurrent signal assignments
  -----------------------------------------------------------------------------

  ICAPDataInxD <= o_RAMData_reconos;
  ICAPCExSB    <= not o_RAMWE_reconos;
  ICAPErrorxS  <= not ICAPDataOutxD(24);

end architecture;

