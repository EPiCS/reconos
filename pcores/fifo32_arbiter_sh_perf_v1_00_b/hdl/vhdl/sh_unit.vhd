

-- @module : sh_unit
-- @author : meise
-- @date   : 23.05.2016


library ieee;
use ieee.std_logic_1164.all;

entity sh_unit is
  generic (
    C_SLV_DWIDTH : integer := 32;
    FIFO_DEPTH   : integer := 8192  -- should be big enough to hold biggest request of a HWT. 
   -- Around 32000 synthesis tools have a hard time implementing it.
    );
  port (
    -- One FIFO32 Input
    IN_FIFO32_S_Data : in  std_logic_vector(31 downto 0);
    IN_FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
    IN_FIFO32_S_Rd   : out std_logic;

    IN_FIFO32_M_Data : out std_logic_vector(31 downto 0);
    IN_FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
    IN_FIFO32_M_Wr   : out std_logic;

    -- Single FIFO32 Output
    OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
    OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
    OUT_FIFO32_S_Rd   : in  std_logic;

    OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
    OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
    OUT_FIFO32_M_Wr   : in  std_logic;

    TUO_NOT_ST          : in std_logic;
    START_OF_NEW_PACKET : in std_logic;

    -- Run-time options
    RUNTIME_OPTIONS : in std_logic_vector(15 downto 0);

    -- Error reporting
    ERROR_REQ : out std_logic;
    ERROR_ACK : in  std_logic;
    ERROR_TYP : out std_logic_vector(7 downto 0);
    ERROR_ADR : out std_logic_vector(31 downto 0);

    -- Misc
    Rst : in std_logic;
    clk : in std_logic;                 -- separate clock for control logic

    -- Debug signals to ILA
    ila_signals : out std_logic_vector(130 downto 0)
    );
end sh_unit;


architecture synth of sh_unit is
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant LEADER_PORT   : std_logic := '0';
  constant FOLLOWER_PORT : std_logic := '1';

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
  -- Internal connection from Demux to sh_unit_comp
  signal INT_FIFO32_S_Data : std_logic_vector(63 downto 0);
  signal INT_FIFO32_S_Fill : std_logic_vector(31 downto 0);
  signal INT_FIFO32_S_Rd   : std_logic_vector(1 downto 0);

  signal INT_FIFO32_M_Data : std_logic_vector(63 downto 0);
  signal INT_FIFO32_M_Rem  : std_logic_vector(31 downto 0);
  signal INT_FIFO32_M_Wr   : std_logic_vector(1 downto 0);

  -- demux control signals
  signal sel      : std_logic;
  signal tuo_lead : integer;
  
begin
--------------------------------------------------------------------------------
-- Processes
--------------------------------------------------------------------------------
  demux_control : process (tuo_lead, TUO_NOT_ST) is
  begin
    -- Depending on which HWT is leading and which one is currently sending,
    -- we have to switch the demuxer.
    if tuo_lead >= 0 and TUO_NOT_ST = '1' then
      sel <= LEADER_PORT;
    elsif tuo_lead >= 0 and TUO_NOT_ST = '0' then
      sel <= FOLLOWER_PORT;
    elsif tuo_lead < 0 and TUO_NOT_ST = '1' then
      sel <= FOLLOWER_PORT;
    else --if tuo_lead < 0 and TUO_NOT_ST = '0' then
      sel <= LEADER_PORT;
    end if;
  end process;


  tuo_leads_control : process (rst, clk) is
  begin
    if Rst = '1' then
      tuo_lead <= 0;
    elsif clk'event and clk = '1' then
      if TUO_NOT_ST = '1' and START_OF_NEW_PACKET = '1' then
        tuo_lead <= tuo_lead + 1;
      elsif TUO_NOT_ST = '0' and START_OF_NEW_PACKET = '1' then
        tuo_lead <= tuo_lead - 1;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Instantiations
--------------------------------------------------------------------------------
-- 1 to 2 fifo32 mux
  my_fifo32_demux : entity work.fifo32_demux
    generic map (
      FIFO32_PORTS => 2)
    port map (
      IN_FIFO32_S_Data  => IN_FIFO32_S_Data,
      IN_FIFO32_S_Fill  => IN_FIFO32_S_Fill,
      IN_FIFO32_S_Rd    => IN_FIFO32_S_Rd,
      IN_FIFO32_M_Data  => IN_FIFO32_M_Data,
      IN_FIFO32_M_Rem   => IN_FIFO32_M_Rem,
      IN_FIFO32_M_Wr    => IN_FIFO32_M_Wr,
      OUT_FIFO32_S_Data => INT_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => INT_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => INT_FIFO32_S_Rd,
      OUT_FIFO32_M_Data => INT_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => INT_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => INT_FIFO32_M_Wr,
      SEL(0)            => SEL);

-- sh_unit_comp
  my_sh_unit_comp : entity work.sh_unit_comp
    generic map (
      C_SLV_DWIDTH => C_SLV_DWIDTH,
      FIFO_DEPTH   => FIFO_DEPTH)
    port map (
      IN_FIFO32_S_Data_A => INT_FIFO32_S_Data(31 downto 0),
      IN_FIFO32_S_Fill_A => INT_FIFO32_S_Fill(15 downto 0),
      IN_FIFO32_S_Rd_A   => INT_FIFO32_S_Rd(0),
      IN_FIFO32_M_Data_A => INT_FIFO32_M_Data(31 downto 0),
      IN_FIFO32_M_Rem_A  => INT_FIFO32_M_Rem(15 downto 0),
      IN_FIFO32_M_Wr_A   => INT_FIFO32_M_Wr(0),

      IN_FIFO32_S_Data_B => INT_FIFO32_S_Data(63 downto 32),
      IN_FIFO32_S_Fill_B => INT_FIFO32_S_Fill(31 downto 16),
      IN_FIFO32_S_Rd_B   => INT_FIFO32_S_Rd(1),
      IN_FIFO32_M_Data_B => INT_FIFO32_M_Data(63 downto 32),
      IN_FIFO32_M_Rem_B  => INT_FIFO32_M_Rem(31 downto 16),
      IN_FIFO32_M_Wr_B   => INT_FIFO32_M_Wr(1),
      OUT_FIFO32_S_Data  => OUT_FIFO32_S_Data,
      OUT_FIFO32_S_Fill  => OUT_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd    => OUT_FIFO32_S_Rd,
      OUT_FIFO32_M_Data  => OUT_FIFO32_M_Data,
      OUT_FIFO32_M_Rem   => OUT_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr    => OUT_FIFO32_M_Wr,
      RUNTIME_OPTIONS    => RUNTIME_OPTIONS,
      ERROR_REQ          => ERROR_REQ,
      ERROR_ACK          => ERROR_ACK,
      ERROR_TYP          => ERROR_TYP,
      ERROR_ADR          => ERROR_ADR,
      Rst                => Rst,
      clk                => clk,        -- separate clock for control logic
      ila_signals        => ila_signals);

-- control process

end synth;


