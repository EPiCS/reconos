library ieee;            --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

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

  -- Run-time options
  signal RUNTIME_OPTIONS: std_logic_vector(59 downto 0);

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

  -- This signal gives a human readable description of what the testbench is
  -- currently testing. Implemented as a signal, because Xilinx ISim can't
  -- track variables. 
  type tb_phase_t is (READ1, WRITE1, READ8K_1, WRITE8K_1,READ8K_2, WRITE8K_2,READ8K_3, WRITE8K_4, REQUEST_ERROR, LENGTH_ERROR, DATA_ERROR, DONE);
  type tb_phase_vector_t is array  (natural range<>) of tb_phase_t;
  signal tb_phase : tb_phase_vector_t(0 to HWT_COUNT-1);

	-- A fast memif write function, capable of writing 1 word per clock cycle 
	procedure memif_fifo_push_fast (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		signal data : in std_logic_vector(31 downto 0);
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

	-- Complements memif_fifo_push_fast function. Has to be called at end of
	-- transfer
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

    -- for reading a word of data in hwt process
    signal data_write : std_logic_vector(31 downto 0) := X"AAAAAAAA";
    signal data_read : std_logic_vector(31 downto 0) := X"AAAAAAAA";
    
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
        C_FIFO32_DEPTH => 10000
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
        C_FIFO32_DEPTH => 10000
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


    hwt_process : process(rst, clk, H2F_MEMIF_IN)
      is
      --! @brief First of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned      
      variable seed1 : positive := 1; --i+1;
      --! @brief Second of two global variables needed for random number functions,
      --!        e.g. get_rand_unsigned
      variable seed2 : positive := 2; --i+i+1;


      --! @brief This function generates a random unsigned number
      --! @details This is an impure function, because it uses the global
      --!          variables seed1 and seed2, although this variables are not
      --!          specified in its interface.
      --! @param[in] min_value This gives the lower limit of the random number 
      --! @param[in] max_value This gives the upper limit of the random number
      --! @param[in] bitwidth The unsigend type is based on standard_logic_vector,
      --!            so we need to know what width in bits the result shall have.
      --! @return A random unsigned number of type unsigned with a width of bitwidth.
      impure function get_rand_unsigned(constant min_value : natural;
                                        constant max_value : natural;
                                        constant bitwidth  : positive)
        return unsigned is
        variable rand_int : integer := 0;
        -- Variable that holds the result of the uniform function
        variable rand     : real;
      begin
        uniform(seed1, seed2, rand);
        rand_int := integer(TRUNC(rand*real(max_value+1-min_value)))+min_value;
        return to_unsigned(rand_int, bitwidth);
      end function;

      type state_t is (SET_PAUSE, PAUSE, WRITE_HEADER, WRITE_DATA, READ_DATA, REPORT_END_STATE, END_STATE);
      variable state : state_t;

      type MODE is (READ, WRITE);
      type MODE_VECTOR is array (natural range<>) of MODE;
      type LENGTH_VECTOR is array (natural range<>) of natural range 0 to 2**16-1;
      type ADDRESS_VECTOR is array (natural range<>) of std_logic_vector(31 downto 0);
      
      constant MAX_PACKETS  : natural                          := 11;
     
      variable PAUSE_LIST   : LENGTH_VECTOR(1 to MAX_PACKETS*2)  := (
        2000, 20, 2000, 20, 2000, 20, 2000, 20,  -- TUO  pauses
        2000, 20, 2000,
        20, 2000, 20, 2000, 0, 2000, 20, 2000,  -- ST pauses
        20, 2000, 20);
      
      variable MODE_LIST    : MODE_VECTOR(1 to MAX_PACKETS*2)    := (
         READ, WRITE, READ, WRITE,READ, WRITE,READ, WRITE, -- TUO, all good
         WRITE,READ, WRITE,                     -- TUO, intentional discrepancy to ST
         --READ, WRITE, READ, WRITE, READ, WRITE,READ, WRITE, -- ST, equal to TUO
         READ, WRITE, READ, WRITE, WRITE, WRITE,READ, WRITE, -- ST, equal to TUO
         READ, READ, WRITE);                    -- ST,  intentional discrepancy to ST
         
      variable LENGTH_LIST  : LENGTH_VECTOR(1 to MAX_PACKETS*2)  := (
        4, 4, 9000, 9000,9000, 9000,9000, 9000, -- TUO lengths
        128, 128, 128,
        4, 4, 9000, 9000,9000, 9000,9000, 9000, -- ST  lengths
        128, 124, 128);
      
      variable ADDRESS_LIST : ADDRESS_VECTOR(1 to MAX_PACKETS*2) := (
        X"DEADDEAD", X"DEADDEAD", X"AFFEAFFE", X"AFFEAFFE",X"AFFEAFFE", X"AFFEAFFE",X"AFFEAFFE", X"AFFEAFFE", -- TUO addresses
        X"BEEFBEEF",X"BEEFBEEF", X"BEEFBEEF",
        X"DEADDEAD", X"DEADDEAD", X"AFFEAFFE", X"AFFEAFFE",X"AFFEAFFE", X"AFFEAFFE",X"AFFEAFFE", X"AFFEAFFE", -- ST  addresses
        X"BEEFBEEF", X"BEEFBEEF", X"BEEFBEEF");

      variable packet_nr     : natural := 0;
      variable pause_counter : natural := 0;
      variable length_counter: natural := 0;
      variable done          : boolean := false;
      
    begin
      if rst = '1' then
        state := SET_PAUSE;
        -- init interface 
        memif_reset(H2F_MEMIF_OUT(i));
        done  := false;
        --data  <= std_logic_vector(get_rand_unsigned(0, 2**16-1, 32));
        data_read <= (others => '0');
        data_write <= (others => '0');
      elsif rising_edge(clk) then
        case state is
          when SET_PAUSE =>
          	memif_fifo_end_fast (
				H2F_MEMIF_IN(i),
				H2F_MEMIF_OUT(i)
				);					
            packet_nr := packet_nr + 1;
            tb_phase(i) <= tb_phase_t'val(packet_nr-1);
            if packet_nr > MAX_PACKETS then
              state := REPORT_END_STATE;
            else
              pause_counter := PAUSE_LIST((MAX_PACKETS*i)+packet_nr);
              state         := PAUSE;
              report "HWT " & i'image(i) & " Packet " & packet_nr'image(packet_nr) & " pausing " & pause_counter'image(pause_counter) & " cycles" severity note;
            end if;
            
          when PAUSE =>
            pause_counter    := pause_counter - 1;
            if pause_counter <= 0 then
              state := WRITE_HEADER;
              report "HWT " & i'image(i) & " Packet " & packet_nr'image(packet_nr) & " START packet with " & integer'image(LENGTH_LIST((MAX_PACKETS*i)+packet_nr)) & " bytes" severity note;
            end if;
            
          when WRITE_HEADER =>
            case MODE_LIST((MAX_PACKETS*i)+packet_nr) is
              when READ =>
                memif_read_request(
                  H2F_MEMIF_IN(i),
                  H2F_MEMIF_OUT(i),
                  ADDRESS_LIST((MAX_PACKETS*i)+packet_nr),  -- address
                  std_logic_vector(to_unsigned(LENGTH_LIST((MAX_PACKETS*i)+packet_nr), 24)),  -- length
                  done
                  );
                if done then
                  length_counter := LENGTH_LIST((MAX_PACKETS*i)+packet_nr);
                  state := READ_DATA;
                end if;
              when WRITE =>
                memif_write_request(
                  H2F_MEMIF_IN(i),
                  H2F_MEMIF_OUT(i),
                  ADDRESS_LIST((MAX_PACKETS*i)+packet_nr),  -- address
                  std_logic_vector(to_unsigned(LENGTH_LIST((MAX_PACKETS*i)+packet_nr), 24)),  -- length
                  done
                  );
                if done then
                  length_counter := LENGTH_LIST((MAX_PACKETS*i)+packet_nr);
                  state := WRITE_DATA;
                end if;
            end case;

          when WRITE_DATA =>
            --data <= std_logic_vector(get_rand_unsigned(0, 2**16-1, 32));
            
            

            
            
            memif_fifo_push_fast (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data_write,                     -- data
              done
              );
            if done then
	          data_write <= std_logic_vector(unsigned(data_write)+1);
	          
	        --
            -- Manual Error Injection. Adapt to your packet definitions!!!
            --
            --if i = 0 and length_counter = 8 and packet_nr = 7 then
            --if i = 0 and length_counter = 4 and packet_nr = 1 then
            if i = 0 and length_counter = 8 and packet_nr = 4 then
              data_write <= X"DEADBEEF";
              report "Inserting DATA error!" severity note;
            end if;
	          
              length_counter := length_counter -4;
            end if;
            if length_counter = 0 then
              state := SET_PAUSE;
              report "HWT " & i'image(i) & " Packet " & packet_nr'image(packet_nr) & " STOP" severity note;
            end if;
            
          when READ_DATA =>
            memif_fifo_pull (
              H2F_MEMIF_IN(i),
              H2F_MEMIF_OUT(i),
              data_read,                     -- data
              done
              );
            if done then
              length_counter := length_counter -4;
            end if;
            if length_counter = 0 then
              state := SET_PAUSE;
              report "HWT " & i'image(i) & " Packet " & packet_nr'image(packet_nr) & " STOP" severity note;
            end if;
            
          when REPORT_END_STATE =>
            report "HWT " & i'image(i) & " Packet generation done!" severity note;
            state := END_STATE;
            
          when END_STATE =>
            null;
        end case;
      end if;
    end process;

  end generate;

silence: for i in HWT_COUNT to ARB_PORT_COUNT-1 generate
begin
    F2A_FIFO32_S_Fill(16*(i+1)-1 downto 16*i) <= (others => '0');
end generate;

  proc_control_process: process(rst, clk) is
  begin
	
	if rst = '1' then
	    ERROR_ACK <= '0';
	elsif clk'event and clk = '1' then 
        -- Set Shadowing configuration
        --RUNTIME_OPTIONS(  3 downto  0 ) <= "1110"; -- Set shadow buffer size and debug mux
        --RUNTIME_OPTIONS(  7 downto  4 ) <= "1000"; -- Set first  thread to TUO and first sh unit
        --RUNTIME_OPTIONS( 11 downto  8 ) <= "0000"; -- Set second thread to ST  and first sh unit
        --RUNTIME_OPTIONS( 59 downto 12 ) <= (others => '1');-- All others operate normal
    
        RUNTIME_OPTIONS <= (others => '1');-- Shadowing off
        -- Error signals from arbiter
        if ERROR_REQ = '1' then
            ERROR_ACK <= '1';
        else
            ERROR_ACK <= '0';
        end if;

	end if;
  end process;
  
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

mem_ctrl_generate: if True generate
    type MEM_FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
    signal mem_state : MEM_FSM_STATE_T;    
    type mode_t is (READ, WRITE);
    signal transfer_mode    : mode_t := READ;
    signal transfer_size    : natural range 0 to 2**24;
    signal transfer_address : std_logic_vector(31 downto 0);
begin
  mem_ctrl : process(clk, rst, a2m_memif_in) is
  begin
    if rst = '1' then
      mem_state                <= IDLE;
      transfer_mode        <= READ;
      a2m_memif_out.s_rd   <= '0';
      a2m_memif_out.m_wr   <= '0';
      a2m_memif_out.m_data <= X"00000000";
    elsif rising_edge(clk) then
      case mem_state is
        
        when IDLE =>
          a2m_memif_out.s_rd <= '0';
          a2m_memif_out.m_wr <= '0';
          if to_integer(unsigned(a2m_memif_in.s_fill)) > 1 then
            mem_state              <= MODE_LENGTH;
            report "    MEM Packet Start" severity note;
            a2m_memif_out.s_rd <= '1';
          end if;
          
          
        when MODE_LENGTH =>
          mem_state <= ADDRESS;
          case a2m_memif_in.s_data(31) is
            when '0'    => transfer_mode <= READ;
            when others => transfer_mode <= WRITE;
          end case;
          transfer_size <= to_integer(unsigned(a2m_memif_in.s_data(23 downto 0)));
          report "    MEM Packet Mode " & std_logic'image(a2m_memif_in.s_data(31)) & 
                 " size: " & integer'image(to_integer(unsigned(a2m_memif_in.s_data(23 downto 0)))) & " bytes," severity note;
          
        when ADDRESS =>
          transfer_address <= a2m_memif_in.s_data;
          report "    MEM address: " & integer'image(to_integer(unsigned(a2m_memif_in.s_data))) severity note;
          case transfer_mode is
            when READ =>
              mem_state              <= DATA_READ;
              a2m_memif_out.s_rd <= '0';
              a2m_memif_out.m_wr <= '1';
              a2m_memif_out.m_data <= a2m_memif_in.s_data;
            when WRITE =>
              mem_state <= DATA_WRITE;
              a2m_memif_out.s_rd <= '0';
              --transfer_size <= transfer_size - 4;
            when others => null;
          end case;
          
        when DATA_WRITE =>
          if (a2m_memif_in.s_fill = X"0001" and transfer_size /= 4) or
             (a2m_memif_in.s_fill = X"0000") 
          then
            a2m_memif_out.s_rd <= '0';
          else
	        a2m_memif_out.s_rd <= '1';
            transfer_size <= transfer_size - 4;
            if transfer_size = 4 then
              mem_state <= IDLE;
              report "    MEM Packet Stop" severity note;
            end if;
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
            transfer_size      <= transfer_size - 4;
            if transfer_size = 4 then
              mem_state                <= IDLE;
              a2m_memif_out.m_wr   <= '0';
              a2m_memif_out.m_data <= X"00000000";
              report "    MEM Packet Stop" severity note;
            end if;
          end if;
          
        when others =>
          mem_state <= IDLE;
      end case;
    end if;
  end process;

end generate;


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

