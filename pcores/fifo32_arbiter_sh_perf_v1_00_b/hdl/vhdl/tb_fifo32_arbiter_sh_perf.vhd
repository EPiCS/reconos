library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library work;
use work.pck_packets.all;
use work.pck_string.all;

entity tb_fifo32_arbiter_sh_perf is
end entity;

architecture testbench of tb_fifo32_arbiter_sh_perf is
--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
  constant half_cycle : time := 5 ns;
  constant full_cycle : time := 2 * half_cycle;

  constant ARB_PORT_COUNT : integer                           := 16;
  constant HWT_COUNT      : integer range 1 to ARB_PORT_COUNT := 2;
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
  signal F2A_FIFO32_S_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Fill : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_S_Rd   : std_logic_vector(ARB_PORT_COUNT-1 downto 0);

  signal F2A_FIFO32_M_Data : std_logic_vector((32*ARB_PORT_COUNT)-1 downto 0);
  signal F2A_FIFO32_M_Rem  : std_logic_vector((16*ARB_PORT_COUNT)-1 downto 0);
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


  
  -- Hardware Interface HWIF
  signal HWIF2DEC_Addr  : std_logic_vector(0 to 31);
  signal HWIF2DEC_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal HWIF2DEC_RdCE  : std_logic;
  signal HWIF2DEC_WrCE  : std_logic;
  signal DEC2HWIF_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal DEC2HWIF_RdAck : std_logic;
  signal DEC2HWIF_WrAck : std_logic;

  -- Run-time options
  signal RUNTIME_OPTIONS: std_logic_vector(15 downto 0);

  -- Error reporting
  signal ERROR_REQ : std_logic;
  signal ERROR_ACK : std_logic;
  signal ERROR_TYP : std_logic_vector(7 downto 0);
  signal ERROR_ADR : std_logic_vector(31 downto 0);

  -- memif interface signals
  type memif_out_array_t is array(natural range <>) of o_memif_t;
  type memif_in_array_t is array(natural range <>) of i_memif_t;
  signal H2F_MEMIF_OUT : memif_out_array_t(0 to ARB_PORT_COUNT-1);
  signal H2F_MEMIF_IN  : memif_in_array_t(0 to ARB_PORT_COUNT-1);

  signal A2M_MEMIF_OUT : o_memif_t;
  signal A2M_MEMIF_IN  : i_memif_t;
  -- Misc
  signal Rst           : std_logic;
  signal clk           : std_logic;

  signal test_desc : string(1 to 16) := "None            ";

  -- This signal gives a human readable description of what the testbench is
  -- currently testing. Implemented as a signal, because Xilinx ISim can't
  -- track variables. 
  type tb_phase_t is (READ1, WRITE1, READ8K_1, WRITE8K_1,READ8K_2, WRITE8K_2,READ8K_3, WRITE8K_4, REQUEST_ERROR, LENGTH_ERROR, DATA_ERROR, DONE);
  type tb_phase_vector_t is array  (natural range<>) of tb_phase_t;
  signal tb_phase : tb_phase_vector_t(0 to HWT_COUNT-1);


  signal transfer_size_sig    : natural range 0 to 2**24;

    procedure memif_fifo_pull_fast (
        signal i_memif : in  i_memif_t;
        signal o_memif : out o_memif_t;
        variable data : out std_logic_vector(31 downto 0);
        variable done : out boolean
    ) is begin
        o_memif.m_wr <= '0';
        o_memif.s_rd <= '0';
        done := False;
        case i_memif.step is
            when 0 =>
                if unsigned(i_memif.s_fill) > 0 then
                    o_memif.step <= 1;
                end if;
            when 1 =>
                o_memif.s_rd <= '1';
                data := i_memif.s_data;
                o_memif.step <= 2;
            when others =>
                o_memif.step <= 0;
                done := True;
        end case;
    end procedure;

	procedure memif_fifo_push_fast (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		variable data : in std_logic_vector(31 downto 0);
		variable done : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		
		if unsigned(i_memif.m_remainder) > 0 then
			o_memif.m_wr <= '1';
			o_memif.m_data <= data;
			done := True;
		end if;
	end procedure;

	procedure memif_fifo_end_fast (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		o_memif.m_data <= (others => '0');
	end procedure;

begin  -- of architecture -------------------------------------------------------

  
  fifos : for i in 0 to HWT_COUNT-1 generate
    
  begin

    memif_setup (
      H2F_MEMIF_IN(i),
      H2F_MEMIF_OUT(i),
      H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
      H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
      H2F_FIFO32_S_Rd(i),
      H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
      H2F_FIFO32_M_Rem (16*(i+1)-1 downto 16*i),
      H2F_FIFO32_M_Wr(i)
      );

    master_fifo32_i : entity work.fifo32
      generic map(
        C_FIFO32_DEPTH => 100
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

    slave_fifo32_i : entity work.fifo32
      generic map(
        C_FIFO32_DEPTH => 100
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


    hwt_process : process(clk, H2F_MEMIF_IN)
      is
      
      type state_t is (SET_PAUSE, PAUSE, SEND_PACKET, RECEIVE_PACKET, END_STATE_MESSAGE, END_STATE);
      variable state : state_t;

      constant MAX_PACKETS  : natural:= 11;

      variable packet        : packet_ptr;
      variable packet_nr     : natural := 0;
      variable pause_counter : natural := 0;
      variable length_counter: natural := 0;
      variable error         : natural := 0;
      variable done          : boolean := false;
      
      variable data_write    : std_logic_vector(31 downto 0);
      variable data_read     : std_logic_vector(31 downto 0);
      
    begin
      if rst = '1' then
        state := SET_PAUSE;
        -- init interface 
        memif_reset(H2F_MEMIF_OUT(i));
        done  := false;
        data_read := (others => '0');
        data_write := (others => '0');
      elsif rising_edge(clk) then
        case state is
          when SET_PAUSE =>
            memif_fifo_end_fast ( H2F_MEMIF_IN(i),H2F_MEMIF_OUT(i) );
            packet_nr := packet_nr + 1;
            tb_phase(i) <= tb_phase_t'val(packet_nr-1);
            packet := packet_generate(0, packet_nr-1); -- 0 was i
            if packet_get_mode(packet.all) = PACKET_MODE_NONE then
              state := END_STATE_MESSAGE;
            else
              pause_counter := packet_get_pause(packet.all);
              state         := PAUSE;
            end if;
            
          when PAUSE =>
            pause_counter    := pause_counter - 1;
            if pause_counter <= 0 then
              state := SEND_PACKET;
              length_counter := packet_get_length(packet.all);
              report "HWT " & to_string(i) & " " & packet_get_description(packet.all) severity note;
            end if;
            
          when SEND_PACKET =>
            --
            -- Manual Error Injection. 
            --
            --if i = 0 and length_counter = 8 and packet_nr = 7 then
            --if i = 0 and length_counter = 4 and packet_nr = 1 then
            --if i = 0 and length_counter = 2 and packet_nr = 4 then
            --  error := 1;
            --  report "Inserting DATA error!" severity note;
            --else 
            --  error := 0;
            --end if;
            
            data_write := packet_get_data(packet.all, packet_get_length(packet.all)-length_counter);
            memif_fifo_push_fast (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data_write,
              done
              );
            if done then
              length_counter := length_counter -1;
            end if;
            if length_counter = 0 then
              if packet_get_mode(packet.all) = PACKET_MODE_WRITE then
                report "HWT " & to_string(i) & " sending done!";
                state := SET_PAUSE;
              else
                report "HWT " & to_string(i) & " receiving data...";
                state := RECEIVE_PACKET;
                length_counter := packet_get_request_length(packet.all);
              end if;
            end if;
            
          when RECEIVE_PACKET=>
            memif_fifo_pull_fast (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data_read,                     -- data
              done
              );
            if done then
              length_counter := length_counter -1;
            end if;
            if length_counter = 0 then
              state := SET_PAUSE;
              report "HWT " & to_string(i) & " receiving done! Last read word: "& to_hstring(data_read);
            end if;
            
          when END_STATE_MESSAGE =>
            report "HWT " & to_string(i) & " PACKET GENERATION DONE!" severity note;
            state := END_STATE;
          
          when END_STATE=>
            state := END_STATE;
            
        end case;
      end if;
    end process;

  end generate;

silence: for i in HWT_COUNT to ARB_PORT_COUNT-1 generate
begin
    F2A_FIFO32_S_Fill(16*(i+1)-1 downto 16*i) <= (others => '0');
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
  
  fifo32_arbiter_sh_perf_i : entity work.fifo32_arbiter_sh_perf
    generic map(
      FIFO32_PORTS     => ARB_PORT_COUNT,  -- setting it to something else than
                                           -- 16 breaks it at the moment:
                                           -- automate address map generation
                                           -- for HWIF!
      ARBITRATION_ALGO => 0
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

      -- Hardware Interface HWIF
      HWIF2DEC_Addr  => HWIF2DEC_Addr,
      HWIF2DEC_Data  => HWIF2DEC_Data,
      HWIF2DEC_RdCE  => HWIF2DEC_RdCE,
      HWIF2DEC_WrCE  => HWIF2DEC_WrCE,
      DEC2HWIF_Data  => DEC2HWIF_Data,
      DEC2HWIF_RdAck => DEC2HWIF_RdAck,
      DEC2HWIF_WrAck => DEC2HWIF_WrAck,

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
      ila_signals => open
      );

  memif_setup (
    A2M_MEMIF_IN,
    A2M_MEMIF_OUT,
    A2M_FIFO32_S_Data,
    A2M_FIFO32_S_Fill,
    A2M_FIFO32_S_Rd,
    A2M_FIFO32_M_Data,
    A2M_FIFO32_M_Rem,
    A2M_FIFO32_M_Wr
    );

  mem_ctrl : process(clk, rst, a2m_memif_in)
    is
    type FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    variable state : FSM_STATE_T;

    type mode_t is (READ, WRITE);
    variable transfer_mode    : mode_t := READ;
    variable transfer_size    : natural range 0 to 2**24;
    variable transfer_address : std_logic_vector(31 downto 0);
    
    function to_string(m: mode_t) return string is
    begin
        case m is
            when READ => return "00";
            when WRITE=> return "80";
            when others=>return "UU";
        end case;
    end function;
    
  begin
    if rst = '1' then
      state                := IDLE;
      transfer_mode        := READ;
      a2m_memif_out.s_rd   <= '0';
      a2m_memif_out.m_wr   <= '0';
      a2m_memif_out.m_data <= X"00000000";
    elsif rising_edge(clk) then
      -- default is to hold all outputs.
      state              := state;
      a2m_memif_out.s_rd <= a2m_memif_out.s_rd;
      a2m_memif_out.m_wr <= a2m_memif_out.m_wr;
      transfer_mode      := transfer_mode;
      transfer_size      := transfer_size;
      case state is
        
        when IDLE =>
          a2m_memif_out.s_rd <= '0';
          a2m_memif_out.m_wr <= '0';
          if to_integer(unsigned(a2m_memif_in.s_fill)) > 1 then
            state              := MODE_LENGTH;
            a2m_memif_out.s_rd <= '1';
          end if;
          
          
        when MODE_LENGTH =>
          state := ADDRESS;
          case a2m_memif_in.s_data(31) is
            when '0'    => transfer_mode := READ;
            when others => transfer_mode := WRITE;
          end case;
          transfer_size := to_integer(unsigned(a2m_memif_in.s_data(23 downto 0)));
          
        when ADDRESS =>
          transfer_address := a2m_memif_in.s_data;
          case transfer_mode is
            when READ =>
              state              := DATA_READ;
              a2m_memif_out.s_rd <= '0';
              a2m_memif_out.m_wr <= '1';
              a2m_memif_out.m_data <= transfer_address;
            when WRITE =>
              state := DATA_WRITE;
              a2m_memif_out.s_rd <= '0';
              --transfer_size := transfer_size - 4;
            when others => null;
          end case;
          report "        MEM    Packet: pause ??? mode " & to_string(transfer_mode) & 
                 " length " & to_string(transfer_size) &
                 " address " & to_hstring(transfer_address);
          
        when DATA_WRITE =>
          if (a2m_memif_in.s_fill = X"0001" and transfer_size /= 4) or
             (a2m_memif_in.s_fill = X"0000") 
          then
            a2m_memif_out.s_rd <= '0';
          else
	        a2m_memif_out.s_rd <= '1';
            transfer_size := transfer_size - 4;
          end if;
          
          if transfer_size = 0 then
            report "        MEM    Write to mem done";
            state              := IDLE;
            --a2m_memif_out.s_rd <= '0';
          end if;
          
        when DATA_READ =>
          -- following line determines read data
          a2m_memif_out.m_data <= transfer_address;
          if a2m_memif_in.m_remainder = X"0001" or
             a2m_memif_in.m_remainder = X"0000" 
          then
			a2m_memif_out.m_wr <= '0';
          else
            a2m_memif_out.m_wr <= '1';
            transfer_size      := transfer_size - 4;	          
          end if;

          if transfer_size = 0 then
            report "        MEM    Read from mem done";
            state                := IDLE;
            a2m_memif_out.m_wr   <= '0';
            a2m_memif_out.m_data <= X"00000000";
          end if;
          
        when others =>
          state := IDLE;
      end case;
      transfer_size_sig <= transfer_size;
    end if;
  end process;

  hwif_proc : process is
    procedure hwif_write(addr, data : std_logic_vector(31 downto 0))
    is

    begin
      HWIF2DEC_Addr <= addr;
      HWIF2DEC_Data <= data;
      HWIF2DEC_WrCE <= '1';
      wait for full_cycle;
      HWIF2DEC_Addr <= (others => '0');
      HWIF2DEC_Data <= (others => '0');
      HWIF2DEC_WrCE <= '0';
      wait for full_cycle;
    end procedure;
  begin
    -- set Defaults
    HWIF2DEC_Addr <= (others => '0');
    HWIF2DEC_Data <= (others => '0');
    HWIF2DEC_RdCE <= '0';
    HWIF2DEC_WrCE <= '0';
    wait for 200 ns;

    test_desc <= "enable chksum rd";
    hwif_write(X"00000070", X"FFFFFFFF");

    test_desc <= "enable chksum wr";
    hwif_write(X"000000F0", X"FFFFFFFF");
    wait for 50*full_cycle;

    test_desc <= "reset  chksum   ";
    hwif_write(X"000000EC", X"FFFFFFFF");
    wait for 10*full_cycle;

    test_desc <= "enable chksum   ";
    hwif_write(X"000000F0", X"FFFFFFFF");
    wait for 50*full_cycle;
    test_desc <= "end of testbench";
    wait;
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

