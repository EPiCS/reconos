--Doxygen
--! @file shadow_perf.vhd
--! @brief This file contains the entity and architecture of memory request 
--! 		comparator, which buffers memory requests in an internal FIFO.
--!			On any deviation of the two incoming requests, an error messages is
--!			send out to proc_control

library ieee;              --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

--library fifo32_v1_00_b;
--use fifo32_v1_00_b.fifo32;

entity sh_unit_comp is
	generic (
		C_SLV_DWIDTH     : integer := 32;
		FIFO_DEPTH       : integer := 8192 -- should be big enough to hold biggest request of a HWT. 
											-- Around 32000 synthesis tools have a hard time implementing it.
	);
	port (
		-- Multiple FIFO32 Inputs
		IN_FIFO32_S_Data_A : in  std_logic_vector(31 downto 0);
		IN_FIFO32_S_Fill_A : in  std_logic_vector(15 downto 0);
		IN_FIFO32_S_Rd_A   : out std_logic;

		IN_FIFO32_M_Data_A : out std_logic_vector(31 downto 0);
		IN_FIFO32_M_Rem_A  : in  std_logic_vector(15 downto 0);
		IN_FIFO32_M_Wr_A   : out std_logic;

		IN_FIFO32_S_Data_B : in  std_logic_vector(31 downto 0);
		IN_FIFO32_S_Fill_B : in  std_logic_vector(15 downto 0);
		IN_FIFO32_S_Rd_B   : out std_logic;

		IN_FIFO32_M_Data_B : out std_logic_vector(31 downto 0);
		IN_FIFO32_M_Rem_B  : in  std_logic_vector(15 downto 0);
		IN_FIFO32_M_Wr_B   : out std_logic;

		-- Single FIFO32 Output
		OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
		OUT_FIFO32_S_Fill : out std_logic_vector(15 downto 0);
		OUT_FIFO32_S_Rd   : in  std_logic;

		OUT_FIFO32_M_Data : in  std_logic_vector(31 downto 0);
		OUT_FIFO32_M_Rem  : out std_logic_vector(15 downto 0);
		OUT_FIFO32_M_Wr   : in  std_logic;
		
    	-- Run-time options
    	RUNTIME_OPTIONS : in std_logic_vector( 2 downto 0 );

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
end entity;

--! Notes to implementor:
--! This Multiplexer may only switch to another input stream, when a complete
--! packet was transmitted. As we don't have any signals telling us the end or
--! start of a packet, we have to track the protocol to decide when to switch.
architecture behavioural of sh_unit_comp is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
	component fifo32 is
		generic (
			C_FIFO32_DEPTH  : integer := 2048;
			C_ENABLE_ILA    : integer := 0
		);
		port (
			Rst : in std_logic;
			FIFO32_S_Clk : in std_logic;
			FIFO32_M_Clk : in std_logic;
			FIFO32_S_Data : out std_logic_vector(31 downto 0);
			FIFO32_M_Data : in std_logic_vector(31 downto 0);
			FIFO32_S_Fill : out std_logic_vector(15 downto 0);
			FIFO32_M_Rem : out std_logic_vector(15 downto 0);
			FIFO32_S_Rd : in std_logic;
			FIFO32_M_Wr : in std_logic
		);
	end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
	constant INTERNAL_PORT_COUNT: integer := 2;

	constant ERROR_TYP_NONE    : std_logic_vector(7 downto 0) := X"00";
	constant ERROR_TYP_HEADER1 : std_logic_vector(7 downto 0) := X"01";
	constant ERROR_TYP_HEADER2 : std_logic_vector(7 downto 0) := X"02";
	constant ERROR_TYP_DATA    : std_logic_vector(7 downto 0) := X"03";

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------
	--! Registers for storing error information
	signal error_typ_reg : std_logic_vector(7 downto 0);
	signal error_adr_reg : std_logic_vector(31 downto 0);

	-- These state definition belongs to process fsm_p. Because ISE Simulator
	-- can't access process local variables, the state signal is defined here.
	type FSM_STATE_T is (
		-- Synchronization
		WAIT_THREADS,
		UPDATE_RUNTIME_OPTIONS,
		-- Packet handling
		READ_MODE_LENGTH, READ_ADDRESS, READ_MODE_LENGTH_SH, READ_ADDRESS_SH, WRITE_MODE_LENGTH, WAIT_SH_BUFFER, COMPARE_REQ,
		WRITE_ADDRESS, DATA_READ, DATA_WRITE,
		-- Error Handling:
		DELETE_REQUEST_TUO, DELETE_REQUEST_ST,  COMPLETE_WRITE,
		REPORT_ERROR, WAIT_ERROR_ACK);
	signal state_tuo : FSM_STATE_T;
	signal state_st : FSM_STATE_T;

	--! For storing the first packet word
	type reg_vector_t is array (natural range<>) of std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal mode_length_reg : reg_vector_t(0 to 2); -- 0 is TUO, 1 is ST, 2 is from sh_buffer
	signal address_reg     : reg_vector_t(0 to 2);

	--! Internal signal vectors to unify all FIFO32 ports
	signal IN_FIFO32_S_Data : std_logic_vector((32*INTERNAL_PORT_COUNT)-1 downto 0);
	signal IN_FIFO32_S_Fill : std_logic_vector((16*INTERNAL_PORT_COUNT)-1 downto 0);
	signal IN_FIFO32_S_Rd   : std_logic_vector(INTERNAL_PORT_COUNT-1 downto 0);

	signal IN_FIFO32_M_Data : std_logic_vector((32*INTERNAL_PORT_COUNT)-1 downto 0);
	signal IN_FIFO32_M_Rem  : std_logic_vector((16*INTERNAL_PORT_COUNT)-1 downto 0);
	signal IN_FIFO32_M_Wr   : std_logic_vector(INTERNAL_PORT_COUNT-1 downto 0);

	--! Translates FIFO fill levels into a single bit request per port.
	signal requests : std_logic_vector(INTERNAL_PORT_COUNT-1 downto 0);

	--! Tap slave data output to memory controller
	signal INT_OUT_FIFO32_S_Data : std_logic_vector(31 downto 0);
	signal INT_OUT_FIFO32_S_Fill : std_logic_vector(15 downto 0);
	signal INT_OUT_FIFO32_M_Rem  : std_logic_vector(15 downto 0);

  	-- run-time options registers
  	signal sh_buffer_size_exp_reg: std_logic_vector(2 downto 0);

	-- Signals for internal data buffers
	-- SHadow buffer
	signal sh_read_data : std_logic_vector(31 downto 0);
	signal sh_write_data : std_logic_vector(31 downto 0);
	signal sh_fill : std_logic_vector(15 downto 0);
	signal sh_rem : std_logic_vector(15 downto 0);
	signal sh_read : std_logic;
	signal sh_write : std_logic;

--------------------------------------------------------------------------------
-- Aliases
--------------------------------------------------------------------------------

  alias sh_buffer_size_exp : std_logic_vector(2 downto 0) is RUNTIME_OPTIONS(2 downto 0);
--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

	function minimum (a : unsigned; b : unsigned)
		return unsigned is
	begin
		if a > b then return b;
		else return a;
		end if;
	end function;

	-- Returns the minimum of two stripes of a std_logic_vector.
	-- Optionally an offset is added to that minimum.
	function my_minimum(  v: std_logic_vector;
			stripe_length: integer;
			stripe_a: integer;
			stripe_b: integer;
			offset  : integer := 0)
		return std_logic_vector is
	begin
		return std_logic_vector(minimum(
				unsigned(v((stripe_length * (1 + stripe_a))-1 downto 16 * stripe_a)),
				unsigned(v((stripe_length * (1 + stripe_b))-1 downto 16 * stripe_b)))
			+ offset);
	end function;

begin  -- of architecture -------------------------------------------------------

	-- connect separate entity ports to internal signal vectors
	A : if INTERNAL_PORT_COUNT > 0 generate
		IN_FIFO32_S_Data((32 * (1 + 0))-1 downto 32 * 0) <= IN_FIFO32_S_Data_A;
		IN_FIFO32_S_Fill((16 * (1 + 0))-1 downto 16 * 0) <= IN_FIFO32_S_Fill_A;
		IN_FIFO32_S_Rd_A                                 <= IN_FIFO32_S_Rd(0);

		IN_FIFO32_M_Data_A                              <= IN_FIFO32_M_Data((32 * (1 + 0))-1 downto 32 * 0);
		IN_FIFO32_M_Rem((16 * (1 + 0))-1 downto 16 * 0) <= IN_FIFO32_M_Rem_A;
		IN_FIFO32_M_Wr_A                                <= IN_FIFO32_M_Wr(0);
	end generate;

	B : if INTERNAL_PORT_COUNT > 1 generate
		IN_FIFO32_S_Data((32 * (1 + 1))-1 downto 32 * 1) <= IN_FIFO32_S_Data_B;
		IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1) <= IN_FIFO32_S_Fill_B;
		IN_FIFO32_S_Rd_B                                 <= IN_FIFO32_S_Rd(1);

		IN_FIFO32_M_Data_B                              <= IN_FIFO32_M_Data((32 * (1 + 1))-1 downto 32 * 1);
		IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1) <= IN_FIFO32_M_Rem_B;
		IN_FIFO32_M_Wr_B                                <= IN_FIFO32_M_Wr(1);
	end generate;

	OUT_FIFO32_S_Fill <= INT_OUT_FIFO32_S_Fill;
	OUT_FIFO32_M_Rem  <= INT_OUT_FIFO32_M_Rem;
	-- Slave part of fifo link

	OUT_FIFO32_S_Data <= INT_OUT_FIFO32_S_Data;
	OUT_FIFO32_S_Fill <= INT_OUT_FIFO32_S_Fill;
	OUT_FIFO32_M_Rem  <= INT_OUT_FIFO32_M_Rem;

--------------------------------------------------------------------------------
-- Instantiation
--------------------------------------------------------------------------------

	sh_buffer: fifo32
	generic map(
		C_FIFO32_DEPTH => FIFO_DEPTH,
		C_ENABLE_ILA   => 0
	)
	port map(
		Rst => rst,
		FIFO32_S_Clk  => clk,
		FIFO32_M_Clk  => clk,
		FIFO32_S_Data => sh_read_data,
		FIFO32_M_Data => sh_write_data,
		FIFO32_S_Fill => sh_fill,
		FIFO32_M_Rem  => sh_rem,
		FIFO32_S_Rd   => sh_read,
		FIFO32_M_Wr   => sh_write
	);

	-- Analyzes all fill levels of input FIFOS and sets the request vector accordingly.
	request_p : process (clk, rst, in_fifo32_s_fill) is
	begin
		for i in 0 to INTERNAL_PORT_COUNT-1 loop
			if to_integer(unsigned(IN_FIFO32_S_Fill((16*(i+1))-1 downto 16*i))) > 1 then
				requests(i) <= '1';
			else
				requests(i) <= '0';
			end if;
		end loop;
	end process;

	-- This process controls non-registered state machine outputs.
	-- If we don't register all outputs, the state machine reacts faster to
	-- changing inputs and state machine design is easier.
	fsm_outputs_st_p: process (state_st,state_tuo, IN_FIFO32_M_Rem, mode_length_reg, address_reg,
			OUT_FIFO32_M_Data, OUT_FIFO32_M_Wr, OUT_FIFO32_S_Rd,
			IN_FIFO32_S_Data, IN_FIFO32_S_Fill,in_fifo32_s_rd,requests,
			sh_read, sh_read_data, sh_rem, sh_fill,sh_write,in_fifo32_m_wr,
			sh_buffer_size_exp_reg,
			-- debug:
			int_out_fifo32_s_data, INT_OUT_FIFO32_S_Fill,INT_OUT_FIFO32_M_Rem)
		is

	begin
		-- for ILA debug
		case state_st is
			when WAIT_THREADS       => ila_signals(3 downto 0) <= "0000"; --0
			when UPDATE_RUNTIME_OPTIONS =>ila_signals(3 downto 0) <= "0001"; --1
			when READ_MODE_LENGTH   => ila_signals(3 downto 0) <= "0010"; --2
			when READ_ADDRESS       => ila_signals(3 downto 0) <= "0011"; --3
			when WRITE_MODE_LENGTH  => ila_signals(3 downto 0) <= "0100"; --4			
			when WRITE_ADDRESS      => ila_signals(3 downto 0) <= "0101"; --5
			when COMPARE_REQ        => ila_signals(3 downto 0) <= "0110"; --6
			when DATA_READ          => ila_signals(3 downto 0) <= "0111"; --7
			when DATA_WRITE         => ila_signals(3 downto 0) <= "1000"; --8
			when DELETE_REQUEST_TUO => ila_signals(3 downto 0) <= "1001"; --9
			when DELETE_REQUEST_ST  => ila_signals(3 downto 0) <= "1010"; --A
			when COMPLETE_WRITE     => ila_signals(3 downto 0) <= "1011"; --B
			when REPORT_ERROR       => ila_signals(3 downto 0) <= "1100"; --C
			when WAIT_ERROR_ACK     => ila_signals(3 downto 0) <= "1101"; --D
			when WAIT_SH_BUFFER     => ila_signals(3 downto 0) <= "1110"; --E
			when others      			=> ila_signals(3 downto 0) <= "1111"; --F;
		end case;
		
		case state_tuo is
			when WAIT_THREADS       => ila_signals(99 downto 96) <= "0000"; --0
			when UPDATE_RUNTIME_OPTIONS =>ila_signals(99 downto 96) <= "0001"; --1
			when READ_MODE_LENGTH   => ila_signals(99 downto 96) <= "0010"; --2
			when READ_ADDRESS       => ila_signals(99 downto 96) <= "0011"; --3
			when READ_MODE_LENGTH_SH=> ila_signals(99 downto 96) <= "1111"; --F - NOT UNIQUE
			when READ_ADDRESS_SH    => ila_signals(99 downto 96) <= "1111"; --F - NOT UNIQUE
			when WRITE_MODE_LENGTH  => ila_signals(99 downto 96) <= "0100"; --4			
			when WRITE_ADDRESS      => ila_signals(99 downto 96) <= "0101"; --5
			when COMPARE_REQ        => ila_signals(99 downto 96) <= "0110"; --6
			when DATA_READ          => ila_signals(99 downto 96) <= "0111"; --7
			when DATA_WRITE         => ila_signals(99 downto 96) <= "1000"; --8
			when DELETE_REQUEST_TUO => ila_signals(99 downto 96) <= "1001"; --9
			when DELETE_REQUEST_ST  => ila_signals(99 downto 96) <= "1010"; --A
			when COMPLETE_WRITE     => ila_signals(99 downto 96) <= "1011"; --B
			when REPORT_ERROR       => ila_signals(99 downto 96) <= "1100"; --C
			when WAIT_ERROR_ACK     => ila_signals(99 downto 96) <= "1101"; --D
			when WAIT_SH_BUFFER     => ila_signals(99 downto 96) <= "1110"; --E
			when others      => null;
		end case;
		
		-- shadow buffer 
		ila_signals (19 downto 4) <= sh_fill; -- shadow buffer fill
		ila_signals (35 downto 20) <= sh_rem; -- shadow buffer remaining
		ila_signals (36) <= sh_read; -- shadow buffer read indicator
		ila_signals (37) <= sh_write; -- shadow buffer write indicator

		-- ST side connection to ST
		ila_signals(53 downto 38) <= IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1);
		ila_signals(54) 		   <= IN_FIFO32_S_Rd(1);
		
		ila_signals(70 downto 55)<= IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1);
		ila_signals(71)           <= IN_FIFO32_M_Wr(1);

		-- 95 downto 72 used in process fsm_states_st_p
		-- 123 downto 100 used in process fsm_states_tuo_p
		ila_signals(130 downto 124) <= (others => '0');
		
		-- defaults
		IN_FIFO32_S_Rd(1)        <= '0';
		IN_FIFO32_M_Wr(1)        <= '0';
		IN_FIFO32_M_Data(63 downto 32)      <= (others => '0');
				
		sh_read  <= '0';
		
		case state_st is
			------------------
			-- Synchronization
			------------------
			when WAIT_THREADS => -- does nothing
			when UPDATE_RUNTIME_OPTIONS => -- does nothing
			
			------------------
			-- Packet handling
			------------------
			when READ_MODE_LENGTH =>
				IN_FIFO32_S_Rd(1) <= '1';				

			when READ_ADDRESS =>
				IN_FIFO32_S_Rd(1) <= '1';

			when READ_MODE_LENGTH_SH =>
				sh_read           <= '1';
			when READ_ADDRESS_SH =>		
				sh_read           <= '1';
				
			when COMPARE_REQ => -- does nothing
								
			when WAIT_SH_BUFFER => -- does nothing

			when DATA_READ =>

				-- forward sh_buffer data tp ST
				IN_FIFO32_M_Data((32 * (1 + 1))-1 downto 32 * 1) <= sh_read_data;
				if ( unsigned(IN_FIFO32_M_Rem(31 downto 16)) >= 1 and 
						  unsigned(sh_fill) >= 1 )
				then
					-- read from the shadow buffer
					sh_read <= '1';
					IN_FIFO32_M_Wr(1)                       <= '1';
				end if;				

			when DATA_WRITE =>
				-- fill the shadow buffer
				-- TODO: suppress more than one write to it
				if (  unsigned(IN_FIFO32_S_Fill(31 downto 16)) >= 1 and 
					  unsigned(sh_fill) >= 1 
				    ) 
				then					
					IN_FIFO32_S_Rd(1) <= '1';
					sh_read <= '1';
				end if;

			-----------------
			-- Error handling
			-----------------
			when DELETE_REQUEST_TUO =>
				-- When we arrive here, a part of the header is defect. 
				-- This state deletes the current request from the sh_buffer.
				if (unsigned(sh_fill) >= 1) then
					sh_read <= '1';
				end if;

			when DELETE_REQUEST_ST =>
				case mode_length_reg(1)(31) is
					when '0' =>
						-- thread reads
						if unsigned(IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1)) >= 1 then
							IN_FIFO32_M_Wr(1) <= '1';
						end if; 

					when '1' =>
						-- thread writes
						if unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) >= 1 then
							IN_FIFO32_S_Rd(1) <= '1';
						end if;

					when others =>
						report "Request mode undefined!" severity ERROR;
				end case;

			when COMPLETE_WRITE =>
				if ( (unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) > 0 and mode_length_reg(1)(31) = '1') and 
					(unsigned(sh_fill) > 0) )
				then
					sh_read               <= '1';
					IN_FIFO32_S_Rd(1)     <= '1';
				end if;
				
			when REPORT_ERROR =>

			when WAIT_ERROR_ACK =>
				
			when others => 
		end case;
	end process;


	fsm_outputs_tuo_p: process (state_tuo, IN_FIFO32_M_Rem, mode_length_reg, address_reg,
			OUT_FIFO32_M_Data, OUT_FIFO32_M_Wr, OUT_FIFO32_S_Rd, sh_buffer_size_exp_reg,
			IN_FIFO32_S_Data, IN_FIFO32_S_Fill)
	is
	begin

		-- defaults
		IN_FIFO32_S_Rd(0)        <= '0';
		IN_FIFO32_M_Wr(0)        <= '0';
		IN_FIFO32_M_Data(31 downto 0)      <= (others => '0');
		INT_OUT_FIFO32_M_Rem  <= (others => '0');
		INT_OUT_FIFO32_S_Data <= (others => '0');
		INT_OUT_FIFO32_S_Fill <= (others => '0');
		
		sh_write <= '0'; 
		sh_write_data <= (sh_write_data'range => '0');
		case state_tuo is
			------------------
			-- Synchronization
			------------------
			when WAIT_THREADS => -- does nothing
			when UPDATE_RUNTIME_OPTIONS => -- does nothing
			------------------
			-- Packet handling
			------------------
			when READ_MODE_LENGTH =>
				IN_FIFO32_S_Rd(0) <= '1';

			when READ_ADDRESS =>
				IN_FIFO32_S_Rd(0) <= '1';

			when WAIT_SH_BUFFER=> -- does nothing

			when WRITE_MODE_LENGTH =>
				-- fill the shadow buffer with request
				-- if error detection is on, but always on a read request
				if (mode_length_reg(0)(31) = '0') then
					sh_write_data <=     mode_length_reg(0);
					sh_write      <=  OUT_FIFO32_S_Rd;
				end if;

				-- fill_level handling: +2 for unwritten mode_length and address word
				INT_OUT_FIFO32_S_Fill <= STD_LOGIC_VECTOR(unsigned(IN_FIFO32_S_Fill(15 downto 0)) +2 );
				INT_OUT_FIFO32_S_Data <= mode_length_reg(0);


			when WRITE_ADDRESS =>
				-- fill the shadow buffer with request
				-- if error detection is on, but always on a read request
				if (mode_length_reg(0)(31) = '0') then
					sh_write_data <=     address_reg(0);
					sh_write      <=  OUT_FIFO32_S_Rd;
				end if;

				-- fill_level handling: +1 for unwritten address word
				INT_OUT_FIFO32_S_Fill <= STD_LOGIC_VECTOR(unsigned(IN_FIFO32_S_Fill(15 downto 0)) +1 );
				INT_OUT_FIFO32_S_Data <= address_reg(0);

			when DATA_READ =>
				-- fill the shadow buffer
				sh_write_data <= OUT_FIFO32_M_Data;
				sh_write <= OUT_FIFO32_M_Wr;

				-- synchronize mem port with thread ports
				IN_FIFO32_M_Data((32 * (1 + 0))-1 downto 32 * 0) <= OUT_FIFO32_M_Data;
				IN_FIFO32_M_Wr(0)                       <= OUT_FIFO32_M_Wr;

				-- fill_level handling
				INT_OUT_FIFO32_M_Rem <= IN_FIFO32_M_Rem(15 downto 0);

			when DATA_WRITE =>
				-- fill the shadow buffer
				-- TODO: suppress more than one write to it
				sh_write_data <=     IN_FIFO32_S_Data(31 downto 0);
				sh_write      <=  OUT_FIFO32_S_Rd;

				IN_FIFO32_S_Rd(0)     <= OUT_FIFO32_S_Rd;
				INT_OUT_FIFO32_S_DATA <= IN_FIFO32_S_Data(31 downto 0);
				INT_OUT_FIFO32_S_Fill <= IN_FIFO32_S_Fill(15 downto 0);

		--
		-- Tuo does no error handling
		--
			when others => 
		end case;
	end process;

	-- State machine for request selection, packet tracking and shadowing
	fsm_states_st_p : process (clk, rst) is
		type TRANSFER_MODE_T is (READ, WRITE);
		variable transfer_mode : TRANSFER_MODE_T;
		variable transfer_size : natural range 0 to 2**24;

	begin
		if rst = '1' then
			state_st           <= WAIT_THREADS;
			mode_length_reg(1 to 2) <= (others=>(others => '0'));
			address_reg(1 to 2)     <= (others=>(others => '0'));
			transfer_mode   := READ;
			transfer_size   := 0;

			ERROR_REQ <= '0';
			ERROR_TYP <= (others => '0');
			ERROR_ADR <= (others => '0');
			
			error_typ_reg<= (others => '1');
			error_adr_reg<= (others => '1');
			
		elsif clk'event and clk = '1' then

			-- default is to hold all outputs.
			state_st         <= state_st;
			transfer_mode := transfer_mode;
			transfer_size := transfer_size;

			-----------------------------------------------------------------------
			-- INFO: We expect TUO to be connected to port 0 and ST to be connected
			-- to port 1. No other ports are served.
			-----------------------------------------------------------------------
			ila_signals(95 downto 72) <= std_logic_vector(to_unsigned(transfer_size, 24));
			case state_st is
				------------------
				-- Synchronization
				------------------
				when WAIT_THREADS =>
					-- TODO: fill_level handling!
					-- when ST and sh_buffer are ready we start processing the request
					if (requests(1) = '1') -- and	( unsigned(sh_fill) >= 2 ) 
					then
						state_st                     <= UPDATE_RUNTIME_OPTIONS;
					end if;

				when UPDATE_RUNTIME_OPTIONS => -- does nothing
					state_st <= READ_MODE_LENGTH;
				------------------
				-- Packet handling
				------------------
				when READ_MODE_LENGTH =>
					-- TODO: fill_level handling!
					-- Read in first word of header from tuo thread
					-- and first word of header from sh_buffer.
					mode_length_reg(1) <= IN_FIFO32_S_Data(63 downto 32);
					state_st              <= READ_ADDRESS;

					-- Take information from sh_buffer and thus, indirectly from TUO
					--case sh_read_data(31) is
					case IN_FIFO32_S_Data(63) is
						when '0'    => transfer_mode := READ;
						when others => transfer_mode := WRITE;
					end case;
					-- lower 24 bits of first word are defined to be the length
					-- of the transfer.
					transfer_size := to_integer(unsigned(IN_FIFO32_S_Data(55 downto 32)));

				when READ_ADDRESS =>
					-- TODO: fill_level handling!
					address_reg(1) <= IN_FIFO32_S_Data(63 downto 32);
					if (transfer_mode = READ)
					then
						state_st          <= WAIT_SH_BUFFER;
					else 
						state_st          <= DATA_WRITE;
					end if;
					
					
				when WAIT_SH_BUFFER =>
					if ( unsigned(sh_fill) >= unsigned(mode_length_reg(1)(15 downto 2)) )  then 
						state_st <= READ_MODE_LENGTH_SH; 
					end if;
					
				when READ_MODE_LENGTH_SH =>
					mode_length_reg(2) <= sh_read_data;
					state_st <= READ_ADDRESS_SH;
			
				when READ_ADDRESS_SH =>		
					address_reg(2) <= sh_read_data;
					state_st          <= COMPARE_REQ;

				when COMPARE_REQ =>
					-- TODO: fill_level handling!
					-- Compare both headers. If same, continue normally, if not, go to
					-- error handling.
					if( (mode_length_reg(2) = mode_length_reg(1))AND
						(address_reg(2)     = address_reg(1))  )
					then
						case transfer_mode is
							when READ =>
								state_st <= DATA_READ;
							when WRITE =>
								state_st <= DATA_WRITE;
						end case;

					--
					-- ERROR HANDLING
					--
					elsif mode_length_reg(2) /= mode_length_reg(1) then
						state_st         <= DELETE_REQUEST_TUO;
						error_typ_reg <= ERROR_TYP_HEADER1;
						-- Command or length is wrong, give address of sh_buffer/TUO to help identifying request
						error_adr_reg <= address_reg(2);
					elsif address_reg(2) /= address_reg(1)then
						state_st         <= DELETE_REQUEST_TUO;
						error_typ_reg <= ERROR_TYP_HEADER2;
						-- Address is wrong. Give address of sh_buffer/TUO anyway to help identifying request
						error_adr_reg <= address_reg(2);
					end if;


				when DATA_READ =>
					-- TODO: What about forever stalling thread?
					-- Read from FIFO and forward it to ST.
					-- Write to ST if his FIFO allows to.
					-- NO ERROR DETECTION HERE because we just cache the read results for the ST
					if ( unsigned(IN_FIFO32_M_Rem(31 downto 16)) >= 1 and 
						  unsigned(sh_fill) >= 1 )
					then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size := transfer_size-4;
					end if;
					if transfer_size = 0 then
						state_st <= WAIT_THREADS;
					end if;


				when DATA_WRITE =>
					-- TODO: What about forever stalling thread?
					-- Read data from sh_buffer and ST and compare them.
					-- On error jump to error handling.
					if ( unsigned(IN_FIFO32_S_Fill(31 downto 16)) >= 1 and 
						 unsigned(sh_fill) >= 1 ) 
					then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size := transfer_size-4;
						if transfer_size = 0 then
							state_st <= WAIT_THREADS;
						end if;
						
						--
						-- ERROR HANDLING
						--
						if ( sh_read_data /= IN_FIFO32_S_Data(63 downto 32) )
						then
							error_typ_reg <= ERROR_TYP_DATA;
							error_adr_reg <= std_logic_vector(unsigned(mode_length_reg(0)(23 downto 0)) - transfer_size+ unsigned(address_reg(0))-4);
							if transfer_size = 0 then
								state_st <= REPORT_ERROR;
							else
								state_st <= COMPLETE_WRITE;
							end if;
							
						end if;
					end if;

				-----------------
				-- Error handling
				-----------------
				when DELETE_REQUEST_TUO =>
					-- TODO: What about forever stalling thread?
					-- Handle threads seperately: they might have different request types and
					-- lengths, so we have to delete the request individually
					-- This deletes the request from the sh_buffer

					if (unsigned(sh_fill) >= 1)
					then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size              := transfer_size-4;
					end if;

					if transfer_size = 0 then
						state_st <= DELETE_REQUEST_ST;
						transfer_size := to_integer(unsigned(mode_length_reg(1)(23 downto 0)));
					end if;

				when DELETE_REQUEST_ST =>
					-- this deletes the request directly from the shadow thread
					if (unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) >= 1 and mode_length_reg(1)(31) = '1') or
						(unsigned(IN_FIFO32_M_Rem((16 * (1 + 1))-1 downto 16 * 1)) >= 1 and mode_length_reg(1)(31) = '0')
					then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size              := transfer_size-4;
					end if;

					if transfer_size = 0 then
						state_st <= REPORT_ERROR;
					end if;

				when COMPLETE_WRITE =>
					-- TODO: What data do we write on error? TUO Data? ST Data? All
					-- zeros? Special Marker?
					-- TODO: What about forever stalling thread?
					
					-- When we arrive here, headers have been the same (length, address, type).
					-- We just read out data from sh_buffer and ST to discard the request and then 
					-- report the error.
					if ( (unsigned(IN_FIFO32_S_Fill((16 * (1 + 1))-1 downto 16 * 1)) > 0 
							and mode_length_reg(1)(31) = '1') and 
							(unsigned(sh_fill) > 0) )
					then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size := transfer_size-4;
					end if;
					if transfer_size = 0 then
						state_st <= REPORT_ERROR;
					end if;

				when REPORT_ERROR =>
					ERROR_REQ <= '1';
					ERROR_TYP <= error_typ_reg;
					ERROR_ADR <= error_adr_reg;
					state_st <= WAIT_ERROR_ACK;

				when WAIT_ERROR_ACK =>
					if ERROR_ACK = '1' then
						state_st <= WAIT_THREADS;

						-- reset error interface
						ERROR_REQ <= '0';
						ERROR_TYP <= ERROR_TYP_NONE;
						ERROR_ADR <= (others => '0');
					end if;

				when others =>
					state_st <= WAIT_THREADS;
			end case;
		end if;
	end process;


	fsm_states_tuo_p : process (clk, rst) is
		type TRANSFER_MODE_T is (READ, WRITE);
		variable transfer_mode : TRANSFER_MODE_T;
		variable transfer_size : natural range 0 to 2**24;

	begin
		if rst = '1' then
			state_tuo       <= WAIT_THREADS;
			mode_length_reg(0 to 0) <= (others=>(others => '0'));
			address_reg(0 to 0)     <= (others=>(others => '0'));
			transfer_mode   := READ;
			transfer_size   := 0;

			sh_buffer_size_exp_reg <= "111"; -- default is biggest buffer size allowed
			
		elsif clk'event and clk = '1' then

			-- default is to hold all outputs.
			state_tuo         <= state_tuo;
			transfer_mode := transfer_mode;
			transfer_size := transfer_size;

			ila_signals(123 downto 100) <= std_logic_vector(to_unsigned(transfer_size, 24));
			-----------------------------------------------------------------------
			-- INFO: We expect TUO to be connected to port 0 and ST to be connected
			-- to port 1. No other ports are served.
			-----------------------------------------------------------------------
			case state_tuo is
				------------------
				-- Synchronization
				------------------
				when WAIT_THREADS =>
					-- TODO: fill_level handling!
					-- when TUO is ready we start its processing its request
					if requests(0) = '1' then
						state_tuo                      <= UPDATE_RUNTIME_OPTIONS;
					end if;

				when UPDATE_RUNTIME_OPTIONS =>
					sh_buffer_size_exp_reg <= sh_buffer_size_exp;		    
		    		state_tuo <= READ_MODE_LENGTH;
		    		
				------------------
				-- Packet handling
				------------------
				when READ_MODE_LENGTH =>
					-- TODO: fill_level handling!
					-- Read in first word of header from tuo thread
					mode_length_reg(0)            <= IN_FIFO32_S_Data(31 downto 0);
					state_tuo                      <= READ_ADDRESS;

					-- Take information from TUO
					case IN_FIFO32_S_DATA(31) is
						when '0'    => transfer_mode := READ;
						when others => transfer_mode := WRITE;
					end case;
					-- lower 24 bits of first word are defined to be the length
					-- of the transfer.
					transfer_size := to_integer(unsigned(IN_FIFO32_S_DATA(23 downto 0)));


				when READ_ADDRESS =>
					-- TODO: fill_level handling!
					-- Only forward packet if the sh_buffer has enough empty space to
					-- for the current packet.
					address_reg(0) <= IN_FIFO32_S_Data(31 downto 0);
					-- Only wait when we actually want to write something into the shadow buffer
					-- When is that? When error detection is on and when we have a write re
					if (transfer_mode = READ) then
						state_tuo          <= WAIT_SH_BUFFER;
					else 
						state_tuo          <= WRITE_MODE_LENGTH;
					end if;
					
				when WAIT_SH_BUFFER =>
					-- TODO: Don't wait until sh_buffer has enough space for a whole packet: maybe sh_buffer is too small for a complete packet.
					-- we wait until the full packet will fit into the sh_buffer to ease buffer handling.
                  -- First argument of minimum function is remaining (empty) words in shadow buffer.
                  -- Right argument is complex: sh_buffer_size_exp is an exponent that gives the limit of to be used bytes of the buffer.
                  -- The meaning of the exponent is: 
                  -- 0-> 1KBytes of shadow buffer used
                  -- 1-> 2KBytes of shadow buffer used
                  -- 2-> 4KBytes of shadow buffer used
                  -- ...
                  -- 7-> 128KBytes of shadow buffer used
                  -- As sh_rem is given in words and the exponent is given in bytes, we need to convert it properly
					if ( minimum( unsigned(sh_rem), to_unsigned( (2**to_integer(unsigned(sh_buffer_size_exp_reg)))*(1024/4), 16) )  
						> unsigned(mode_length_reg(0)(15 downto 2)) ) 
					then
						state_tuo <= WRITE_MODE_LENGTH;
					end if;
					
				when WRITE_MODE_LENGTH =>
					if OUT_FIFO32_S_Rd = '1' then
						state_tuo                 <= WRITE_ADDRESS;
					end if;

				when WRITE_ADDRESS =>
					if OUT_FIFO32_S_Rd = '1' then
						case transfer_mode is
							when READ =>
								state_tuo <= DATA_READ;
							when WRITE =>
								state_tuo <= DATA_WRITE;
						end case;
					end if;


				when DATA_READ =>
					if OUT_FIFO32_M_Wr = '1' then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size := transfer_size-4;
					end if;
					if transfer_size = 0 then
						state_tuo <= WAIT_THREADS;
					end if;

				when DATA_WRITE =>
					-- TODO: What data do we write on error? TUO Data? ST Data? All
					-- zeros? Special Marker?
					-- TODO: What about forever stalling thread?
					if OUT_FIFO32_S_Rd = '1' then
						assert transfer_size >0 report "Transfer size becomes less than zero!" severity error;
						transfer_size := transfer_size-4;
					end if;
					if transfer_size = 0 then
						state_tuo <= WAIT_THREADS;
					end if;

				when others =>
					state_tuo <= WAIT_THREADS;
			end case;
		end if;
	end process;
end architecture;
