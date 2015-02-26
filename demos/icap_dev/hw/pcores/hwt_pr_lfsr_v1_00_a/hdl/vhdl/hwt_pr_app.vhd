-------------------------------------------------------------------------------
-- Title      : HWT for LFSR Test
-- Project    : 
-------------------------------------------------------------------------------
-- File       : hwt_pr_app.vhd
-- Author     : atraber  <atraber@pc-10080>
-- Company    : Computer Engineering and Networks Laboratory, ETH Zurich
-- Created    : 2014-05-19
-- Last update: 2014-05-23
-- Platform   : Xilinx ISIM (simulation), Xilinx (synthesis)
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 Computer Engineering and Networks Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-05-19  1.0      atraber Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

entity hwt_pr_app is
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

architecture implementation of hwt_pr_app is
  type STATE_TYPE is (STATE_GET_VALS, STATE_WRITE, STATE_READ, STATE_THREAD_EXIT,
                      STATE_MEM_READ, STATE_MEM_WRITE, STATE_FINISHED,
                      STATE_SAVE_TO_REG, STATE_LOAD_FROM_REG);

  constant MBOX_RECV : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
  constant MBOX_SEND : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

  constant C_LOCAL_RAM_SIZE          : integer := 2048;  -- in words
  constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
  constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

  constant LFSR_NUM : integer := 4;

  type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);

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

  shared variable local_ram : LOCAL_MEMORY_T := (others => x"FFFFFFFF");

  signal ignore : std_logic_vector(C_FSL_WIDTH-1 downto 0);

  signal vals : std_logic_vector(31 downto 0);
  signal msg  : std_logic_vector(31 downto 0);

  -----------------------------------------------------------------------------
  -- LFSR signals
  -----------------------------------------------------------------------------
  signal LFSRCmdLoadxS    : std_logic;
  signal LFSRCmdCapturexS : std_logic;
  signal LFSRCmdDonexS    : std_logic;
  signal LFSRCapturingxS  : std_logic;
  signal LFSRLoadingxS    : std_logic;

  type lfsr_state_t is (LFSR_IDLE, LFSR_LOAD, LFSR_CAPTURE, LFSR_CAPTURE_WAIT,
                        LFSR_RUN_LOAD, LFSR_RUN_EX, LFSR_RUN_SAVE, LFSR_RUN_WAIT);
  signal LFSRStatexDP, LFSRStatexDN           : lfsr_state_t;
  signal LFSRCounterxDP, LFSRCounterxDN       : unsigned(1 downto 0);
  signal LFSRIterationsxDP, LFSRIterationsxDN : unsigned(31 downto 0);

  -- Encoding: 00: idle, 01: ram->reg, 10: reg->ram, 11: running
  signal LFSRRegModexS          : std_logic_vector(1 downto 0);
  signal LFSRRegxDP, LFSRRegxDN : std_logic_vector(31 downto 0);
  signal LFSRRegNextxD          : std_logic_vector(31 downto 0);

  -- ram
  signal RamWExS   : std_logic;
  signal RamAddrxD : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
  signal RamInxD   : std_logic_vector(31 downto 0);
  signal RamOutxD  : std_logic_vector(31 downto 0);

  -----------------------------------------------------------------------------
  -- registers
  -----------------------------------------------------------------------------
  type   reg_t is array (0 to LFSR_NUM) of std_logic_vector(31 downto 0);
  signal RegistersxD : reg_t;
begin

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
      if (RamWExS = '1') then
        local_ram(conv_integer(unsigned(RamAddrxD))) := RamInxD;
      else
        RamOutxD <= local_ram(conv_integer(unsigned(RamAddrxD)));
      end if;
    end if;
  end process;


  -----------------------------------------------------------------------------
  -- LFSR FSM
  -----------------------------------------------------------------------------
  LFSRFsmComb : process (LFSRCmdCapturexS, LFSRCmdLoadxS, LFSRCounterxDN,
                         LFSRCounterxDP, LFSRIterationsxDP, LFSRStatexDN,
                         LFSRStatexDP)
  begin  -- process LFSRFsmComb
    LFSRStatexDN      <= LFSRStatexDP;
    LFSRRegModexS     <= "00";          -- idle
    LFSRCounterxDN    <= LFSRCounterxDP;
    LFSRIterationsxDN <= LFSRIterationsxDP;
    LFSRCmdDonexS     <= '0';
    LFSRCapturingxS   <= '0';
    LFSRLoadingxS     <= '0';
    RamWExS           <= '0';

    case LFSRStatexDP is
      -------------------------------------------------------------------------
      when LFSR_IDLE =>
        if LFSRCmdLoadxS = '1' then
          LFSRStatexDN <= LFSR_LOAD;
        elsif LFSRCmdCapturexS = '1' then
          LFSRStatexDN <= LFSR_CAPTURE;
        else
          LFSRStatexDN <= LFSR_RUN_LOAD;
        end if;

        LFSRCounterxDN <= conv_unsigned(0, LFSRCounterxDN'length);

        -----------------------------------------------------------------------
      when LFSR_LOAD =>
        LFSRIterationsxDN <= conv_unsigned(0, LFSRIterationsxDN'length);
        LFSRLoadingxS     <= '1';
        RamWExS           <= '1';
        LFSRCounterxDN    <= LFSRCounterxDP + 1;

        if LFSRCounterxDP = conv_unsigned(LFSR_NUM-1, LFSRCounterxDN'length) then
          LFSRStatexDN  <= LFSR_IDLE;
          LFSRCmdDonexS <= '1';
        end if;

        -----------------------------------------------------------------------
      when LFSR_CAPTURE_WAIT =>
        LFSRCounterxDN <= LFSRCounterxDP + 1;
        LFSRStatexDN   <= LFSR_CAPTURE;

        -----------------------------------------------------------------------
      when LFSR_CAPTURE =>
        LFSRCounterxDN  <= LFSRCounterxDP + 1;
        LFSRCapturingxS <= '1';

        if LFSRCounterxDP = conv_unsigned(LFSR_NUM-1, LFSRCounterxDP'length) then
          LFSRStatexDN  <= LFSR_IDLE;
          LFSRCmdDonexS <= '1';
        end if;

        -----------------------------------------------------------------------
      when LFSR_RUN_WAIT =>
        LFSRStatexDN <= LFSR_RUN_LOAD;

        -----------------------------------------------------------------------
      when LFSR_RUN_LOAD =>
        LFSRRegModexS <= "01";          -- ram->reg
        LFSRStatexDN  <= LFSR_RUN_EX;

        -----------------------------------------------------------------------
      when LFSR_RUN_EX =>
        LFSRRegModexS <= "11";          -- ram->reg
        LFSRStatexDN  <= LFSR_RUN_SAVE;

        -----------------------------------------------------------------------
      when LFSR_RUN_SAVE =>
        LFSRRegModexS <= "10";          -- reg->ram
        RamWExS       <= '1';

        if LFSRCounterxDP = conv_unsigned(LFSR_NUM-1, LFSRCounterxDP'length) then
          if LFSRIterationsxDP = conv_unsigned(2**16 - 2, LFSRIterationsxDP'length) then
            LFSRIterationsxDN <= conv_unsigned(0, LFSRIterationsxDN'length);
          else
            LFSRIterationsxDN <= LFSRIterationsxDP + 1;
          end if;

          LFSRStatexDN <= LFSR_IDLE;
        else
          LFSRCounterxDN <= LFSRCounterxDP + 1;
          LFSRStatexDN   <= LFSR_RUN_WAIT;
        end if;

        -----------------------------------------------------------------------
      when others => null;
    end case;
  end process LFSRFsmComb;

  -- registers
  LFSRFsmReg : process (clk, rst)
  begin  -- process LFSRFsmReg
    if rst = '1' then                   -- asynchronous reset (active high)
      LFSRStatexDP      <= LFSR_IDLE;
      LFSRIterationsxDP <= conv_unsigned(0, LFSRIterationsxDP'length);
    elsif clk'event and clk = '1' then  -- rising clock edge
      LFSRStatexDP      <= LFSRStatexDN;
      LFSRCounterxDP    <= LFSRCounterxDN;
      LFSRIterationsxDP <= LFSRIterationsxDN;
      LFSRRegxDP        <= LFSRRegxDN;
    end if;
  end process LFSRFsmReg;

  -- concurrent signal assignments
  RamAddrxD <= "000000000" & std_logic_vector(LFSRCounterxDP);

  RamInxD <= RegistersxD(conv_integer(LFSRCounterxDP) + 1) when LFSRLoadingxS = '1'
             else LFSRRegxDP;

  LFSRRegNextxD(31 downto 16) <= (others => '0');

  lfsrNextGen : for i in 0 to 14 generate
    LFSRRegNextxD(i + 1) <= LFSRRegxDP(i);
  end generate lfsrNextGen;

  LFSRRegNextxD(0) <= LFSRRegxDP(10) xor LFSRRegxDP(12) xor LFSRRegxDP(13) xor LFSRRegxDP(15);

  with LFSRRegModexS select
    LFSRRegxDN <=
    RamOutxD      when "01",
    LFSRRegNextxD when "11",
    LFSRRegxDP    when others;

  -----------------------------------------------------------------------------
  -- os and memory synchronisation state machine
  -----------------------------------------------------------------------------
  reconos_fsm : process (clk, rst, o_osif, o_memif, o_ram) is
    variable done : boolean;
  begin
    if rst = '1' then
      vals  <= (others => '0');
      osif_reset(o_osif);
      memif_reset(o_memif);
      ram_reset(o_ram);
      state <= STATE_GET_VALS;
      done  := false;
    elsif rising_edge(clk) then

      -- default assignment
      if LFSRCapturingxS = '1' then
        RegistersxD(0) <= std_logic_vector(LFSRIterationsxDP);

        RegistersxD(conv_integer(LFSRCounterxDP) + 1) <= RamOutxD;
      end if;

      LFSRCmdLoadxS    <= '0';
      LFSRCmdCapturexS <= '0';

      case state is
        -----------------------------------------------------------------------
        -- get first message from OS
        -----------------------------------------------------------------------
        when STATE_GET_VALS =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, vals, done);
          if done then
            if (vals = X"FFFFFFFF") then
              state <= STATE_THREAD_EXIT;
            else
              case vals(31 downto 30) is
                when "00" =>
                  state <= STATE_WRITE;
                when "01" =>
                  state <= STATE_MEM_WRITE;
                when "10" =>
                  state <= STATE_READ;
                when "11" =>
                  state <= STATE_MEM_READ;
                when others =>
                  state <= STATE_GET_VALS;
              end case;
            end if;

            vals(31 downto 30) <= "00";  -- reset the last two bits, so that we
                                         -- can use it as address
          end if;


          ---------------------------------------------------------------------
          -- get second message from OS
          ---------------------------------------------------------------------
        when STATE_WRITE =>
          osif_mbox_get(i_osif, o_osif, MBOX_RECV, msg, done);
          if done then
            if msg = X"FFFFFFFF" then
              state <= STATE_THREAD_EXIT;
            elsif vals(2 downto 0) = "000" then
              -- control command
              if msg = X"00000001" then
                -- load LFSR
                state <= STATE_LOAD_FROM_REG;
              elsif msg = X"00000002" then
                -- save LFSR to registers
                state <= STATE_SAVE_TO_REG;
              else
                state <= STATE_GET_VALS;
              end if;
            else
              RegistersxD(conv_integer(unsigned(vals(2 downto 0)))) <= msg;

              state <= STATE_GET_VALS;
            end if;
          end if;

          ---------------------------------------------------------------------
          -- send msg with register content to OS
          ---------------------------------------------------------------------
        when STATE_READ =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND,
                        RegistersxD(conv_integer(unsigned(vals(2 downto 0)))),
                        ignore, done);
          if done then
            state <= STATE_GET_VALS;
          end if;

          ---------------------------------------------------------------------
          -- Copy main memory to local memory
          ---------------------------------------------------------------------
        when STATE_MEM_READ =>
          memif_read(i_ram, o_ram, i_memif, o_memif, vals, X"00000000",
                     conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24), done);

          if done then
            state <= STATE_FINISHED;
          end if;

          ---------------------------------------------------------------------
          -- Copy local memory to main memory
          ---------------------------------------------------------------------
        when STATE_MEM_WRITE =>
          memif_write(i_ram, o_ram, i_memif, o_memif, X"00000000", vals,
                      conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES, 24), done);

          if done then
            state <= STATE_FINISHED;
          end if;

          ---------------------------------------------------------------------
          -- Load new values from registers to memory which is then used for LFSR
          ---------------------------------------------------------------------
        when STATE_LOAD_FROM_REG =>
          if LFSRCmdDonexS = '1' then
            state <= STATE_GET_VALS;
          else
            LFSRCmdLoadxS <= '1';
          end if;

          ---------------------------------------------------------------------
          -- Save values from memory (LFSR) to registers
          ---------------------------------------------------------------------
        when STATE_SAVE_TO_REG =>
          if LFSRCmdDonexS = '1' then
            state <= STATE_GET_VALS;
          else
            LFSRCmdCapturexS <= '1';
          end if;

          ---------------------------------------------------------------------
          -- Send finished message
          ---------------------------------------------------------------------
        when STATE_FINISHED =>
          osif_mbox_put(i_osif, o_osif, MBOX_SEND,
                        X"00000001",
                        ignore, done);
          if done then
            state <= STATE_GET_VALS;
          end if;

          ---------------------------------------------------------------------
          -- thread exit
          ---------------------------------------------------------------------
        when STATE_THREAD_EXIT =>
          osif_thread_exit(i_osif, o_osif);
      end case;
    end if;
  end process;

end architecture;
