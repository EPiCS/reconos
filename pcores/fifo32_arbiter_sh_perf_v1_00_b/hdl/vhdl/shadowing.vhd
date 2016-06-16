

-- @module : shadowing
-- @author : meise
-- @date   : 19.05.2016


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity shadowing is
  generic (
    C_SLV_DWIDTH : integer := 32;
    FIFO32_PORTS     : integer := 16;   --! 1 to 16 allowed
    SHADOW_UNITS : integer := 1;
    FIFO_DEPTH       : integer := 8192 -- should be big enough to hold biggest request of a HWT. 
                                       -- Around 32000 bytes synthesis tools have a hard time implementing it,
                                       -- because currently it's implemented in distributed memory. @TODO
    );
  port (
    -- Multiple FIFO32 Inputs
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

    -- Which HWT is currently selected?
    HWT_INDEX : in unsigned(clog2(FIFO32_PORTS)-1 downto 0);
    START_OF_NEW_PACKET : in std_logic;
    
    -- Run-time options
    RUNTIME_OPTIONS : in std_logic_vector(2 downto 0);
    SHADOWING_OPTIONS: in std_logic_vector(55 downto 0);
    
    -- Error reporting
    ERROR_REQ : out std_logic;
    ERROR_ACK : in  std_logic;
    ERROR_PRT : out std_logic_vector(7 downto 0);
    ERROR_TYP : out std_logic_vector(7 downto 0);
    ERROR_ADR : out std_logic_vector(31 downto 0);
	
    -- Misc
    Rst : in std_logic;
    clk : in std_logic;                 -- separate clock for control logic

    -- Debug signals to ILA
    ila_signals : out std_logic_vector(130 downto 0)
    );
end shadowing;

architecture synth of shadowing is
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- shadow units have two FIFO32 input ports 
  signal INT_IN_FIFO32_S_Data : std_logic_vector((32*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_IN_FIFO32_S_Fill : std_logic_vector((16*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_IN_FIFO32_S_Rd   : std_logic_vector((SHADOW_UNITS+1)-1 downto 0);

  signal INT_IN_FIFO32_M_Data : std_logic_vector((32*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_IN_FIFO32_M_Rem  : std_logic_vector((16*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_IN_FIFO32_M_Wr   : std_logic_vector((SHADOW_UNITS+1)-1 downto 0);

  -- shadow units have one FIFO32 output ports
  signal INT_OUT_FIFO32_S_Data : std_logic_vector((32*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_OUT_FIFO32_S_Fill : std_logic_vector((16*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_OUT_FIFO32_S_Rd   : std_logic_vector((SHADOW_UNITS+1)-1 downto 0);

  signal INT_OUT_FIFO32_M_Data : std_logic_vector((32*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_OUT_FIFO32_M_Rem  : std_logic_vector((16*(SHADOW_UNITS+1))-1 downto 0);
  signal INT_OUT_FIFO32_M_Wr   : std_logic_vector((SHADOW_UNITS+1)-1 downto 0);

  signal TUO_NOT_ST : std_logic_vector(SHADOW_UNITS-1 downto 0);
  signal START_OF_NEW_PACKET_ARRAY : std_logic_vector(SHADOW_UNITS downto 0);

  -- mux and demux control signals
  signal sel2mux : std_logic_vector(clog2(SHADOW_UNITS+1)-1 downto 0);
  
    -- Error reporting
  signal INT_ERROR_REQ : std_logic_vector(SHADOW_UNITS-1 downto 0);
  signal INT_ERROR_ACK : std_logic_vector(SHADOW_UNITS-1 downto 0);
  signal INT_ERROR_PRT : std_logic_vector((SHADOW_UNITS*8)-1 downto 0);
  signal INT_ERROR_TYP : std_logic_vector((SHADOW_UNITS*8)-1 downto 0);
  signal INT_ERROR_ADR : std_logic_vector((SHADOW_UNITS*32)-1 downto 0);
  
  type ila_signals_t is array (SHADOW_UNITS-1 downto 0) of std_logic_vector(130 downto 0);
  signal INT_ILA_SIGNALS: ila_signals_t;

begin
  ila_signals <= INT_ILA_SIGNALS(0);

-- bypass when no shadowing is needed
  INT_OUT_FIFO32_S_Data((32 * (1 + SHADOW_UNITS))-1 downto 32 * SHADOW_UNITS) <= INT_IN_FIFO32_S_Data((32 * (1 + SHADOW_UNITS))-1 downto 32 * SHADOW_UNITS);
  INT_OUT_FIFO32_S_Fill((16 * (1 + SHADOW_UNITS))-1 downto 16 * SHADOW_UNITS) <= INT_IN_FIFO32_S_Fill((16 * (1 + SHADOW_UNITS))-1 downto 16 * SHADOW_UNITS);
  INT_IN_FIFO32_S_Rd(SHADOW_UNITS) <= INT_OUT_FIFO32_S_Rd(SHADOW_UNITS);
  
  INT_IN_FIFO32_M_Data((32 * (1 + SHADOW_UNITS))-1 downto 32 * SHADOW_UNITS) <= INT_OUT_FIFO32_M_Data((32 * (1 + SHADOW_UNITS))-1 downto 32 * SHADOW_UNITS);
  INT_OUT_FIFO32_M_Rem ((16 * (1 + SHADOW_UNITS))-1 downto 16 * SHADOW_UNITS)  <= INT_IN_FIFO32_M_Rem((16 * (1 + SHADOW_UNITS))-1 downto 16 * SHADOW_UNITS);
  INT_IN_FIFO32_M_Wr(SHADOW_UNITS) <= INT_OUT_FIFO32_M_Wr(SHADOW_UNITS);
  
--------------------------------------------------------------------------------
-- Processes
--------------------------------------------------------------------------------
  
  
  
  control: process (HWT_INDEX, SHADOWING_OPTIONS, START_OF_NEW_PACKET) is
      variable shadow_port: integer range 0 to 7;
  begin
    -- Shadowing options is divided into 14 fields with 4 bit width.
    -- Every fields highest bit indicates TUO ('1') or ST('0') status.
    -- The remaining 3 bit select one of up to 7 shadow units(0-6) or the 
    -- bypass (7).
    shadow_port := to_integer(unsigned(SHADOWING_OPTIONS(to_integer(HWT_INDEX)*4+2 downto
                                     to_integer(HWT_INDEX)*4)));
    -- Limit to highest available port
    if shadow_port=7 then shadow_port := SHADOW_UNITS; end if;
    
    -- This broadcasts the current selected threads status to every shadow unit
    for i in TUO_NOT_ST'LENGTH-1 downto 0 loop
      TUO_NOT_ST(i)<= SHADOWING_OPTIONS(4*to_integer(HWT_INDEX)+3);
    end loop;

    -- This selects the current shadowing unit based on the configuration
    -- Here, we copy the appropiate number of bits to the sel2mux signal. 
    for i in sel2mux'LENGTH-1 downto 0 loop
      sel2mux(i) <= SHADOWING_OPTIONS(to_integer(HWT_INDEX)*4+i);
    end loop;
    
    START_OF_NEW_PACKET_ARRAY <= (shadow_port => START_OF_NEW_PACKET, others => '0');
    
  end process;
  
--------------------------------------------------------------------------------
-- Instantiations
--------------------------------------------------------------------------------

my_fifo32_demux : entity work.fifo32_demux 
		generic map (
		FIFO32_PORTS     => SHADOW_UNITS+1)
		port    map (
		IN_FIFO32_S_Data => IN_FIFO32_S_Data,
		IN_FIFO32_S_Fill => IN_FIFO32_S_Fill,
		IN_FIFO32_S_Rd   => IN_FIFO32_S_Rd,
		IN_FIFO32_M_Data => IN_FIFO32_M_Data,
		IN_FIFO32_M_Rem  => IN_FIFO32_M_Rem,
		IN_FIFO32_M_Wr   => IN_FIFO32_M_Wr,
		OUT_FIFO32_S_Data => INT_IN_FIFO32_S_Data,
		OUT_FIFO32_S_Fill => INT_IN_FIFO32_S_Fill,
		OUT_FIFO32_S_Rd  => INT_IN_FIFO32_S_Rd,
		OUT_FIFO32_M_Data => INT_IN_FIFO32_M_Data,
		OUT_FIFO32_M_Rem => INT_IN_FIFO32_M_Rem,
		OUT_FIFO32_M_Wr  => INT_IN_FIFO32_M_Wr,
		SEL              => sel2mux);   

-- Shadowing units and bypass
sh_units: for i in SHADOW_UNITS-1 downto 0 generate 

  sh : entity work.sh_unit
    generic map(
      C_SLV_DWIDTH =>C_SLV_DWIDTH, 
      FIFO_DEPTH => FIFO_DEPTH
      )
    port map(
      -- Multiple FIFO32 Inputs
      IN_FIFO32_S_Data => INT_IN_FIFO32_S_Data((32 * (1 + i))-1 downto 32 * i),
      IN_FIFO32_S_Fill => INT_IN_FIFO32_S_Fill((16 * (1 + i))-1 downto 16 * i),
      IN_FIFO32_S_Rd   => INT_IN_FIFO32_S_Rd(i*2),

      IN_FIFO32_M_Data => INT_IN_FIFO32_M_Data((32 * (1 + i))-1 downto 32 * i),
      IN_FIFO32_M_Rem  => INT_IN_FIFO32_M_Rem((16 * (1 + i))-1 downto 16 * i),
      IN_FIFO32_M_Wr   => INT_IN_FIFO32_M_Wr(i*2),

      -- Single FIFO32 Output
      OUT_FIFO32_S_Data => INT_OUT_FIFO32_S_Data((32 * (1 + i))-1 downto 32 * i),
      OUT_FIFO32_S_Fill => INT_OUT_FIFO32_S_Fill((16 * (1 + i))-1 downto 16 * i),
      OUT_FIFO32_S_Rd   => INT_OUT_FIFO32_S_Rd(i),

      OUT_FIFO32_M_Data => INT_OUT_FIFO32_M_Data((32 * (1 + i))-1 downto 32 * i),
      OUT_FIFO32_M_Rem  => INT_OUT_FIFO32_M_Rem((16 * (1 + i))-1 downto 16 * i),
      OUT_FIFO32_M_Wr   => INT_OUT_FIFO32_M_Wr(i),

      TUO_NOT_ST          => TUO_NOT_ST(i),
      START_OF_NEW_PACKET => START_OF_NEW_PACKET_ARRAY(i),

      -- Run-time options
      RUNTIME_OPTIONS => RUNTIME_OPTIONS, -- same for all

      -- Error reporting
      ERROR_REQ => INT_ERROR_REQ(i),
      ERROR_ACK => INT_ERROR_ACK(i),
      ERROR_TYP => INT_ERROR_TYP((8 * (1 + i))-1 downto 8 * i),
      ERROR_ADR => INT_ERROR_ADR((32 * (1 + i))-1 downto 32 * i),

      -- Misc
      Rst => rst,
      clk => clk,

      -- Debug signals to ILA
      ila_signals => int_ila_signals(i)
      );

end generate;

INT_ERROR_ACK(0) <= ERROR_ACK;
ERROR_ADR <= INT_ERROR_ADR(31 downto 0);
ERROR_PRT <= (others =>'0');
ERROR_REQ <= INT_ERROR_REQ(0);
ERROR_TYP <= INT_ERROR_TYP(7 downto 0);

my_fifo32_mux : entity work.fifo32_mux 
		generic map (
		FIFO32_PORTS     => SHADOW_UNITS+1)
		port    map (
		IN_FIFO32_S_Data => INT_OUT_FIFO32_S_Data,
		IN_FIFO32_S_Fill => INT_OUT_FIFO32_S_Fill,
		IN_FIFO32_S_Rd   => INT_OUT_FIFO32_S_Rd,
		IN_FIFO32_M_Data => INT_OUT_FIFO32_M_Data,
		IN_FIFO32_M_Rem  => INT_OUT_FIFO32_M_Rem,
		IN_FIFO32_M_Wr   => INT_OUT_FIFO32_M_Wr,
		OUT_FIFO32_S_Data => OUT_FIFO32_S_Data,
		OUT_FIFO32_S_Fill => OUT_FIFO32_S_Fill,
		OUT_FIFO32_S_Rd  => OUT_FIFO32_S_Rd,
		OUT_FIFO32_M_Data => OUT_FIFO32_M_Data,
		OUT_FIFO32_M_Rem => OUT_FIFO32_M_Rem,
		OUT_FIFO32_M_Wr  => OUT_FIFO32_M_Wr,
		SEL              => sel2mux);   


end synth;








