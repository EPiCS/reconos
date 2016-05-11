library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library fifo32_v1_00_b;
use fifo32_v1_00_b.all;

entity tb_fifo32_ringbus_with_stubs is
end entity;

architecture testbench of tb_fifo32_ringbus_with_stubs is
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant half_cycle : time := 5 ns;
  constant full_cycle : time := 2 * half_cycle;

  constant ARB_PORT_COUNT : integer                           := 16;
  constant HWT_COUNT      : integer range 1 to ARB_PORT_COUNT := 1;
  constant C_SLV_DWIDTH   : integer                           := 32;
--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

  -- FIFO32 interface between hardware and fifos.
  signal H2F_FIFO32_S_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Fill : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_S_Rd   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  signal H2F_FIFO32_M_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Rem  : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal H2F_FIFO32_M_Wr   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  -- FIFO32 interface between fifos and arbiter
  signal F2A_FIFO32_S_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0) := (others => '0');
  signal F2A_FIFO32_S_Fill : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0) := (others => '0');
  signal F2A_FIFO32_S_Rd   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  signal F2A_FIFO32_M_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Rem  : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0) := (others => '0');
  signal F2A_FIFO32_M_Wr   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  -- FIFO32 interface between arbiter and memory controller.
  signal A2M_FIFO32_S_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_S_Fill : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_S_Rd   : std_logic;

  signal A2M_FIFO32_M_Data : std_logic_vector(31 downto 0);
  signal A2M_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
  signal A2M_FIFO32_M_Wr   : std_logic;

  -- FIFO32 interface to proc_control
  signal FSLA_Rst       : std_logic;   
  signal FSLA_S_Read    : std_logic;
  signal FSLA_S_Data    : std_logic_vector(31 downto 0);
  signal FSLA_S_Control : std_logic;
  signal FSLA_S_Exists  : std_logic;
  signal FSLA_M_Write   : std_logic;
  signal FSLA_M_Data    : std_logic_vector(31 downto 0);
  signal FSLA_M_Control : std_logic;
  signal FSLA_M_Full    : std_logic;
                       
  signal FSLB_Rst       : std_logic;
  signal FSLB_S_Read    : std_logic;
  signal FSLB_S_Data    : std_logic_vector(31 downto 0);
  signal FSLB_S_Control : std_logic;
  signal FSLB_S_Exists  : std_logic;
  signal FSLB_M_Write   : std_logic;
  signal FSLB_M_Data    : std_logic_vector(31 downto 0);
  signal FSLB_M_Control : std_logic;
  signal FSLB_M_Full    : std_logic;


  -- Run-time options
  signal RUNTIME_OPTIONS: std_logic_vector(15 downto 0);

  -- Error reporting
  signal ERROR_REQ : std_logic;
  signal ERROR_ACK : std_logic;
  signal ERROR_TYP : std_logic_vector(7 downto 0);
  signal ERROR_ADR : std_logic_vector(31 downto 0);

  -- Misc
  signal Rst           : std_logic;
  signal clk           : std_logic;

  signal test_desc : string(1 to 16) := "None            ";


  -- Debug
  signal ila_signals : std_logic_vector(255 downto 0);
  signal fault_control:std_logic_vector(31 downto 0):= (others=>'0');
  signal transfer_size_sig    : natural range 0 to 2**24;

begin  -- of architecture -------------------------------------------------------

  
  fifos : for i in 0 to HWT_COUNT-1 generate
  begin

    master_fifo32_i : entity fifo32_v1_00_b.fifo32
      generic map(
        C_FIFO32_DEPTH => 128
        )
      port map(
        Rst           => rst,
        FIFO32_S_Clk  => clk,
        FIFO32_M_Clk  => clk,
        FIFO32_S_Data => F2A_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
        FIFO32_M_Data => H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
        FIFO32_S_Fill => F2A_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
        FIFO32_M_Rem  => H2F_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
        FIFO32_S_Rd   => F2A_FIFO32_S_Rd(i),
        FIFO32_M_Wr   => H2F_FIFO32_M_Wr(i)
        );

    slave_fifo32_i : entity fifo32_v1_00_b.fifo32
      generic map(
        C_FIFO32_DEPTH => 128
        )
      port map(
        Rst           => rst,
        FIFO32_S_Clk  => clk,
        FIFO32_M_Clk  => clk,
        FIFO32_S_Data => H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
        FIFO32_M_Data => F2A_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
        FIFO32_S_Fill => H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
        FIFO32_M_Rem  => F2A_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
        FIFO32_S_Rd   => H2F_FIFO32_S_Rd(i),
        FIFO32_M_Wr   => F2A_FIFO32_M_Wr(i)
        );


    -- sort_demo_stub instantiation for mimicking a working hardware thread
    sort_demo_stub_i:entity work.hwt_sort_demo_stub 
		port    map (
		FIFO32_S_Data    => H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
		FIFO32_M_Data    => H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
		FIFO32_S_Fill    => H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
		FIFO32_M_Rem     => H2F_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
		FIFO32_S_Rd      => H2F_FIFO32_S_Rd(i),
		FIFO32_M_Wr      => H2F_FIFO32_M_Wr(i),
		fault_control    => fault_control,
		debug            => open,  
		clk              => clk,    
		rst              => rst);

  end generate;

-- Instantiate proc_control, which communicates error data to the main system
  FSLA_M_Full <= '0'; -- let proc_control think we always accept incoming data
proc_control_i: entity work.proc_control 
  port map(
    clk => clk,
    rst => rst,

    -- Request FSL
    FSLA_Rst       => FSLA_Rst,      
    FSLA_S_Read    => FSLA_S_Read,   
    FSLA_S_Data    => FSLA_S_Data,   
    FSLA_S_Control => FSLA_S_Control,
    FSLA_S_Exists  => FSLA_S_Exists, 
    FSLA_M_Write   => FSLA_M_Write,  
    FSLA_M_Data    => FSLA_M_Data,   
    FSLA_M_Control => FSLA_M_Control,
    FSLA_M_Full    => FSLA_M_Full,   
                                     
    -- Reply FSL                     
    FSLB_Rst       => FSLB_Rst,      
    FSLB_S_Read    => FSLB_S_Read,   
    FSLB_S_Data    => FSLB_S_Data,   
    FSLB_S_Control => FSLB_S_Control,
    FSLB_S_Exists  => FSLB_S_Exists, 
    FSLB_M_Write   => FSLB_M_Write,  
    FSLB_M_Data    => FSLB_M_Data,   
    FSLB_M_Control => FSLB_M_Control,
    FSLB_M_Full    => FSLB_M_Full,   


    -- 16 individual reset outputs (mhs does not support vector indexing)
    reset0 => open,
    reset1 => open,
    reset2 => open,
    reset3 => open,
    reset4 => open,
    reset5 => open,
    reset6 => open,
    reset7 => open,
    reset8 => open,
    reset9 => open,
    resetA => open,
    resetB => open,
    resetC => open,
    resetD => open,
    resetE => open,
    resetF => open,

    -- MMU related ports
    page_fault => '0',
    fault_addr => (others =>'0'),
    retry      => open,
    pgd        => open,
    tlb_hits   => (others =>'0'),
    tlb_misses => (others =>'0'),

    -- Fault injection related ports
    fault_sa0 => open,
    fault_sa1 => open,

    -- Arbiter run-time options
	ARB_RUNTIME_OPTIONS => RUNTIME_OPTIONS,

    -- Error signals from arbiter
    ERROR_REQ  => ERROR_REQ,
    ERROR_ACK  => ERROR_ACK,
    ERROR_TYP  => ERROR_TYP,
    ERROR_ADR  => ERROR_ADR,

    -- ReconOS reset
    reconos_reset => open
    );
  
  fifo32_ringbus_i : entity work.fifo32_ringbus
    generic map(
        G_FIFO32_PORTS   =>14,   --! 1 to 16 allowed
        G_SHADOW_UNITS	 =>7		
      )
    port map(
      -- Multiple FIFO32 Inputs
      IN_FIFO32_S_Data_A => F2A_FIFO32_S_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_S_Fill_A => F2A_FIFO32_S_Fill(16*(0+1)-1 downto 16*0),
      IN_FIFO32_S_Rd_A   => F2A_FIFO32_S_Rd(0),

      IN_FIFO32_M_Data_A => F2A_FIFO32_M_Data(32*(0+1)-1 downto 32*0),
      IN_FIFO32_M_Rem_A  => F2A_FIFO32_M_Rem(16*(0+1)-1 downto 16*0),
      IN_FIFO32_M_Wr_A   => F2A_FIFO32_M_Wr(0),

      IN_FIFO32_S_Data_B => F2A_FIFO32_S_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_S_Fill_B => F2A_FIFO32_S_Fill(16*(1+1)-1 downto 16*1),
      IN_FIFO32_S_Rd_B   => F2A_FIFO32_S_Rd(1),

      IN_FIFO32_M_Data_B => F2A_FIFO32_M_Data(32*(1+1)-1 downto 32*1),
      IN_FIFO32_M_Rem_B  => F2A_FIFO32_M_Rem(16*(1+1)-1 downto 16*1),
      IN_FIFO32_M_Wr_B   => F2A_FIFO32_M_Wr(1),

      IN_FIFO32_S_Data_C => F2A_FIFO32_S_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_S_Fill_C => F2A_FIFO32_S_Fill(16*(2+1)-1 downto 16*2),
      IN_FIFO32_S_Rd_C   => F2A_FIFO32_S_Rd(2),

      IN_FIFO32_M_Data_C => F2A_FIFO32_M_Data(32*(2+1)-1 downto 32*2),
      IN_FIFO32_M_Rem_C  => F2A_FIFO32_M_Rem(16*(2+1)-1 downto 16*2),
      IN_FIFO32_M_Wr_C   => F2A_FIFO32_M_Wr(2),

      IN_FIFO32_S_Data_D => F2A_FIFO32_S_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_S_Fill_D => F2A_FIFO32_S_Fill(16*(3+1)-1 downto 16*3),
      IN_FIFO32_S_Rd_D   => F2A_FIFO32_S_Rd(3),

      IN_FIFO32_M_Data_D => F2A_FIFO32_M_Data(32*(3+1)-1 downto 32*3),
      IN_FIFO32_M_Rem_D  => F2A_FIFO32_M_Rem(16*(3+1)-1 downto 16*3),
      IN_FIFO32_M_Wr_D   => F2A_FIFO32_M_Wr(3),

      IN_FIFO32_S_Data_E => F2A_FIFO32_S_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_S_Fill_E => F2A_FIFO32_S_Fill(16*(4+1)-1 downto 16*4),
      IN_FIFO32_S_Rd_E   => F2A_FIFO32_S_Rd(4),

      IN_FIFO32_M_Data_E => F2A_FIFO32_M_Data(32*(4+1)-1 downto 32*4),
      IN_FIFO32_M_Rem_E  => F2A_FIFO32_M_Rem(16*(4+1)-1 downto 16*4),
      IN_FIFO32_M_Wr_E   => F2A_FIFO32_M_Wr(4),

      IN_FIFO32_S_Data_F => F2A_FIFO32_S_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_S_Fill_F => F2A_FIFO32_S_Fill(16*(5+1)-1 downto 16*5),
      IN_FIFO32_S_Rd_F   => F2A_FIFO32_S_Rd(5),

      IN_FIFO32_M_Data_F => F2A_FIFO32_M_Data(32*(5+1)-1 downto 32*5),
      IN_FIFO32_M_Rem_F  => F2A_FIFO32_M_Rem(16*(5+1)-1 downto 16*5),
      IN_FIFO32_M_Wr_F   => F2A_FIFO32_M_Wr(5),

      IN_FIFO32_S_Data_G => F2A_FIFO32_S_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_S_Fill_G => F2A_FIFO32_S_Fill(16*(6+1)-1 downto 16*6),
      IN_FIFO32_S_Rd_G   => F2A_FIFO32_S_Rd(6),

      IN_FIFO32_M_Data_G => F2A_FIFO32_M_Data(32*(6+1)-1 downto 32*6),
      IN_FIFO32_M_Rem_G  => F2A_FIFO32_M_Rem(16*(6+1)-1 downto 16*6),
      IN_FIFO32_M_Wr_G   => F2A_FIFO32_M_Wr(6),

      IN_FIFO32_S_Data_H => F2A_FIFO32_S_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_S_Fill_H => F2A_FIFO32_S_Fill(16*(7+1)-1 downto 16*7),
      IN_FIFO32_S_Rd_H   => F2A_FIFO32_S_Rd(7),

      IN_FIFO32_M_Data_H => F2A_FIFO32_M_Data(32*(7+1)-1 downto 32*7),
      IN_FIFO32_M_Rem_H  => F2A_FIFO32_M_Rem(16*(7+1)-1 downto 16*7),
      IN_FIFO32_M_Wr_H   => F2A_FIFO32_M_Wr(7),

      IN_FIFO32_S_Data_I => F2A_FIFO32_S_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_S_Fill_I => F2A_FIFO32_S_Fill(16*(8+1)-1 downto 16*8),
      IN_FIFO32_S_Rd_I   => F2A_FIFO32_S_Rd(8),

      IN_FIFO32_M_Data_I => F2A_FIFO32_M_Data(32*(8+1)-1 downto 32*8),
      IN_FIFO32_M_Rem_I  => F2A_FIFO32_M_Rem(16*(8+1)-1 downto 16*8),
      IN_FIFO32_M_Wr_I   => F2A_FIFO32_M_Wr(8),

      IN_FIFO32_S_Data_J => F2A_FIFO32_S_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_S_Fill_J => F2A_FIFO32_S_Fill(16*(9+1)-1 downto 16*9),
      IN_FIFO32_S_Rd_J   => F2A_FIFO32_S_Rd(9),

      IN_FIFO32_M_Data_J => F2A_FIFO32_M_Data(32*(9+1)-1 downto 32*9),
      IN_FIFO32_M_Rem_J  => F2A_FIFO32_M_Rem(16*(9+1)-1 downto 16*9),
      IN_FIFO32_M_Wr_J   => F2A_FIFO32_M_Wr(9),

      IN_FIFO32_S_Data_K => F2A_FIFO32_S_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_S_Fill_K => F2A_FIFO32_S_Fill(16*(10+1)-1 downto 16*10),
      IN_FIFO32_S_Rd_K   => F2A_FIFO32_S_Rd(10),

      IN_FIFO32_M_Data_K => F2A_FIFO32_M_Data(32*(10+1)-1 downto 32*10),
      IN_FIFO32_M_Rem_K  => F2A_FIFO32_M_Rem(16*(10+1)-1 downto 16*10),
      IN_FIFO32_M_Wr_K   => F2A_FIFO32_M_Wr(10),

      IN_FIFO32_S_Data_L => F2A_FIFO32_S_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_S_Fill_L => F2A_FIFO32_S_Fill(16*(11+1)-1 downto 16*11),
      IN_FIFO32_S_Rd_L   => F2A_FIFO32_S_Rd(11),

      IN_FIFO32_M_Data_L => F2A_FIFO32_M_Data(32*(11+1)-1 downto 32*11),
      IN_FIFO32_M_Rem_L  => F2A_FIFO32_M_Rem(16*(11+1)-1 downto 16*11),
      IN_FIFO32_M_Wr_L   => F2A_FIFO32_M_Wr(11),

      IN_FIFO32_S_Data_M => F2A_FIFO32_S_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_S_Fill_M => F2A_FIFO32_S_Fill(16*(12+1)-1 downto 16*12),
      IN_FIFO32_S_Rd_M   => F2A_FIFO32_S_Rd(12),

      IN_FIFO32_M_Data_M => F2A_FIFO32_M_Data(32*(12+1)-1 downto 32*12),
      IN_FIFO32_M_Rem_M  => F2A_FIFO32_M_Rem(16*(12+1)-1 downto 16*12),
      IN_FIFO32_M_Wr_M   => F2A_FIFO32_M_Wr(12),

      IN_FIFO32_S_Data_N => F2A_FIFO32_S_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_S_Fill_N => F2A_FIFO32_S_Fill(16*(13+1)-1 downto 16*13),
      IN_FIFO32_S_Rd_N   => F2A_FIFO32_S_Rd(13),

      IN_FIFO32_M_Data_N => F2A_FIFO32_M_Data(32*(13+1)-1 downto 32*13),
      IN_FIFO32_M_Rem_N  => F2A_FIFO32_M_Rem(16*(13+1)-1 downto 16*13),
      IN_FIFO32_M_Wr_N   => F2A_FIFO32_M_Wr(13),

      IN_FIFO32_S_Data_O => F2A_FIFO32_S_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_S_Fill_O => F2A_FIFO32_S_Fill(16*(14+1)-1 downto 16*14),
      IN_FIFO32_S_Rd_O   => F2A_FIFO32_S_Rd(14),

      IN_FIFO32_M_Data_O => F2A_FIFO32_M_Data(32*(14+1)-1 downto 32*14),
      IN_FIFO32_M_Rem_O  => F2A_FIFO32_M_Rem(16*(14+1)-1 downto 16*14),
      IN_FIFO32_M_Wr_O   => F2A_FIFO32_M_Wr(14),

      IN_FIFO32_S_Data_P => F2A_FIFO32_S_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_S_Fill_P => F2A_FIFO32_S_Fill(16*(15+1)-1 downto 16*15),
      IN_FIFO32_S_Rd_P   => F2A_FIFO32_S_Rd(15),

      IN_FIFO32_M_Data_P => F2A_FIFO32_M_Data(32*(15+1)-1 downto 32*15),
      IN_FIFO32_M_Rem_P  => F2A_FIFO32_M_Rem(16*(15+1)-1 downto 16*15),
      IN_FIFO32_M_Wr_P   => F2A_FIFO32_M_Wr(15),

      -- Single FIFO32 Output
      OUT_FIFO32_S_Data => A2M_FIFO32_S_Data,
      OUT_FIFO32_S_Fill => A2M_FIFO32_S_Fill,
      OUT_FIFO32_S_Rd   => A2M_FIFO32_S_Rd,

      OUT_FIFO32_M_Data => A2M_FIFO32_M_Data,
      OUT_FIFO32_M_Rem  => A2M_FIFO32_M_Rem,
      OUT_FIFO32_M_Wr   => A2M_FIFO32_M_Wr,

	  -- Run-time options	  
	  RUNTIME_OPTIONS => RUNTIME_OPTIONS,
	  
      -- Error reporting
      ERROR_REQ => ERROR_REQ,
      ERROR_ACK => ERROR_ACK,
      ERROR_TYP => ERROR_TYP,
      ERROR_ADR => ERROR_ADR,

      -- Misc
      Rst => rst,
      clk => clk,

      -- Debug signals to ILA
      ila_signals => ila_signals
      );


  mem_ctrl : process(clk, rst, A2M_FIFO32_S_Data,A2M_FIFO32_S_Fill,A2M_FIFO32_M_Rem, A2M_FIFO32_S_Rd, A2M_FIFO32_M_Wr)
    is
    type FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;

    type mode_t is (READ, WRITE);
    variable transfer_mode    : mode_t := READ;
    variable transfer_size    : natural range 0 to 2**24;
    variable transfer_address : std_logic_vector(31 downto 0);
    variable data             : unsigned(31 downto 0);
  begin
    if rst = '1' then
      state                := IDLE;
      transfer_mode        := READ;
      A2M_FIFO32_S_Rd   <= '0';
      A2M_FIFO32_M_Wr   <= '0';
      A2M_FIFO32_M_Data <= (others => '0');
      data              := X"DEADBEEF";
    elsif clk'event and clk='1' then
      -- default is to hold all outputs.
      state              := state;
      A2M_FIFO32_S_Rd <= A2M_FIFO32_S_Rd;
      A2M_FIFO32_M_Wr <= A2M_FIFO32_M_Wr;
      transfer_mode      := transfer_mode;
      transfer_size      := transfer_size;
      case state is
        
        when IDLE =>
          A2M_FIFO32_S_Rd <= '0';
          A2M_FIFO32_M_Wr <= '0';
          if to_integer(unsigned(A2M_FIFO32_S_Fill)) > 1 then
            state              := MODE_LENGTH;
            
          end if;
          
          
        when MODE_LENGTH =>
          state := ADDRESS;
          A2M_FIFO32_S_Rd <= '1';
          case A2M_FIFO32_S_Data(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          transfer_size := to_integer(unsigned(A2M_FIFO32_S_Data(23 downto 0)));
          
        when ADDRESS =>
          transfer_address := A2M_FIFO32_S_Data;
          case transfer_mode is
            when READ =>
              state              := DATA_READ;
              A2M_FIFO32_S_Rd <= '1';
              A2M_FIFO32_M_Wr <= '1';
              A2M_FIFO32_M_Data <= std_logic_vector(data);
            when WRITE =>
              state := DATA_WRITE;
              A2M_FIFO32_S_Rd <= '1';
              --transfer_size := transfer_size - 4;
            when others => null;
          end case;
          
        when DATA_WRITE =>
          if (A2M_FIFO32_S_Fill = X"0001" and transfer_size /= 4) or
             (A2M_FIFO32_S_Fill = X"0000") 
          then
            A2M_FIFO32_S_Rd <= '0';
          else
	        A2M_FIFO32_S_Rd <= '1';
            transfer_size := transfer_size - 4;
          end if;
          
          if transfer_size = 0 then
            state              := IDLE;
            --A2M_FIFO32_S_Rd <= '0';
          end if;
          
        when DATA_READ =>
          A2M_FIFO32_S_Rd <= '0';
          -- following line determines read data
          A2M_FIFO32_M_Data <= std_logic_vector(data); 
          --data := data +1; -- more realistic data, but sorting takes ages
          if A2M_FIFO32_M_Rem = X"0001" or
             A2M_FIFO32_M_Rem = X"0000" 
          then
			A2M_FIFO32_M_Wr <= '0';
          else
            A2M_FIFO32_M_Wr <= '1';
            transfer_size      := transfer_size - 4;	          
          end if;

          if transfer_size = 0 then
            state                := IDLE;
            A2M_FIFO32_M_Wr   <= '0';
            A2M_FIFO32_M_Data <= X"00000000";
          end if;
          
        when others =>
          state := IDLE;
      end case;
      transfer_size_sig <= transfer_size;
    end if;
  end process;


  reset : process is
  begin
    rst <= '1';
    wait for 5 * full_cycle;
    rst <= '0';
    wait;
  end process;

-- All clocks are the same.
  clock : process is
  begin
    clk <= '1';
    wait for half_cycle;
    clk <= '0';
    wait for half_cycle;
  end process;


end architecture;

