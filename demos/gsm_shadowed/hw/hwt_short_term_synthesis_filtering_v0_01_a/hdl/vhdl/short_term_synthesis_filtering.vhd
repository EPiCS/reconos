--
-- short_term_synthesis_filtering.vhd
-- 
-- Author:		Alexander Sprenger   <alsp@mail.upb.de>
-- History:		08.02.2013	Alexander Sprenger	created
--				25.02.2013	Alexander Sprenger	bugs fixed

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity short_term_synthesis_filtering is

  generic (
    G_AWIDTH : integer := 11;           -- Addresswidth in bits
    G_DWIDTH : integer := 32            -- Datawidth in bits
    );

  port (
    clk   : in std_logic;
    reset : in std_logic;
	 
	 count : in signed(0 to G_DWIDTH-1); --k in short_term_synthesis_filtering function

    -- local ram interface
    o_RAMAddr : out unsigned(0 to G_AWIDTH-1);
    o_RAMData : out unsigned(0 to G_DWIDTH-1);
    i_RAMData : in  unsigned(0 to G_DWIDTH-1);
    o_RAMWE   : out std_logic;
	 
    start     : in  std_logic;
    done      : out std_logic
    );
end short_term_synthesis_filtering;

architecture Behavioral of short_term_synthesis_filtering is

	type state_t is (	STATE_IDLE,
							STATE_WAIT_1,
							STATE_SET_SRI,
							STATE_WAIT_2,
							STATE_GET_RRP,
							STATE_WAIT_3,
							STATE_GET_V,
							STATE_WAIT_4,
							STATE_GET_CURRENT_V_VALUES,
							STATE_CALCULATING,
							STATE_WAIT_5,
							STATE_WRITE_STATE,
							STATE_WAIT_6,
							STATE_SET_SR_ADDR,
							STATE_WAIT_7,
							STATE_SAVE_SR_STATUS,
							STATE_WRITE_SR_1,
							STATE_WRITE_SR_2,
							STATE_WRITE_SR_3,
							STATE_SET_ADDR_V0,
							STATE_WAIT_99,
							STATE_READ_V0,
							STATE_WRITE_SR_4,
							STATE_SET_WT_ADDR,
							STATE_WAIT_8,
							STATE_DONE
	);  
	signal state : state_t := STATE_IDLE;
  
	signal ptr 		: unsigned(0 to G_AWIDTH-1);
	
	--start_adresses in lokal RAM
	constant C_S_START 	: unsigned(0 to G_AWIDTH-1) := (others => '0');
	constant C_RRP_START : unsigned(0 to G_AWIDTH) := to_unsigned(162,G_AWIDTH) & '0';
	constant C_WT_START	: unsigned(0 to G_AWIDTH) := to_unsigned(166,G_AWIDTH) & '0';
	constant C_V_START	: unsigned(0 to G_AWIDTH) := to_unsigned(156,G_AWIDTH) & '0';

begin
	-- set RAM address
	o_RAMAddr <= ptr;  

	-- short_term_synthesis_filtering_coder state machine
	short_term_synthesis_filtering_coder_proc	: process(clk, reset)
		variable k : signed (31 downto 0) := (others => '0');
		
		variable i : signed (31 downto 0) := (others => '0');
		
		variable sri	: signed(15 downto 0) := (others => '0');
		variable tmp1	: signed(15 downto 0) := (others => '0');
		variable tmp2	: signed(15 downto 0) := (others => '0');
		
		variable ltmp	: signed(31 downto 0) := (others => '0');
		
		variable s_ptr		: unsigned(0 to G_AWIDTH-1) := C_S_START;
		variable v_ptr		: unsigned(0 to G_AWIDTH) := C_V_START;
		variable rrp_ptr	: unsigned(0 to G_AWIDTH) := C_RRP_START;
		variable wt_ptr	: unsigned(0 to G_AWIDTH) := C_WT_START;
		variable sr_ptr	: unsigned(0 to G_AWIDTH) := (others => '0');
		
		variable mul_result	: signed(31 downto 0) := (others => '0');
		variable v_input		: signed(15 downto 0) := (others => '0'); 		
		variable v_output		: signed(15 downto 0) := (others => '0'); 
		
		variable outputbuffer : unsigned(G_DWIDTH-1 downto 0) := (others => '0');
		variable outputbuffer_2 : unsigned(G_DWIDTH-1 downto 0) := (others => '0');
		variable outputbuffer_v : unsigned(G_DWIDTH-1 downto 0) := (others => '0');
		
		variable sr_start	: unsigned(0 to G_AWIDTH) := (others => '0');
																				
		begin	
			--RESET
			if reset = '1' then
				ptr			<= (others => '0');
				o_RAMData	<= (others => '0');
				o_RAMWE		<= '0';
				done			<= '0';
				state			<= STATE_IDLE;

				k		:= (others => '0');
				i		:= (others => '0');
				sri	:= (others => '0');
				tmp1	:= (others => '0');
				tmp2	:= (others => '0');
				ltmp	:= (others => '0');
				
				s_ptr		:= C_S_START;
				v_ptr		:= C_V_START;
				v_ptr		:= v_ptr + 7;
				rrp_ptr	:= C_RRP_START;
				rrp_ptr := rrp_ptr + 7;
				wt_ptr	:= C_WT_START;
				sr_ptr 	:= sr_start;
				
				mul_result	:= (others => '0');
				v_input 		:= (others => '0');
				v_output 	:= (others => '0');
				
				outputbuffer := (others => '0');
				outputbuffer_2 := (others => '0');
				outputbuffer_v := (others => '0');
				
				sr_start := (others => '0');
							
			elsif rising_edge(clk) then
				o_RAMWE   <= '0';
				done		 <= '0';
				
				case state is 	
					-- wait for start signal
					when STATE_IDLE =>
						ptr <= C_V_START(0 to G_AWIDTH-1);
						if start = '1' then
							k := count;
							i := to_signed(8,32);
							ptr <= wt_ptr(0 to G_AWIDTH-1);
							if(count(G_DWIDTH-1) = '1') then
								sr_start := C_WT_START + to_integer(count) + 1; --calculate where the array sr starts
							else
							   sr_start := C_WT_START + to_integer(count); --calculate where the array sr starts 
							end if;
							sr_ptr := sr_start;
							
							state <= STATE_WAIT_1;
						end if;

					when STATE_WAIT_1 =>
						state <= STATE_SET_SRI;	--wait for local ram to change value on i_ramdata
					
					-- get the value for sri
					when STATE_SET_SRI =>
						if (k=0) then
							state <= STATE_DONE; --if k==0 then done
						else						
							k := k - 1;
							--sri=*wt++
							if wt_ptr(G_AWIDTH) = '0' then
								sri := signed(i_RAMData(0 to 15));
							elsif wt_ptr(G_AWIDTH) = '1' then
								sri := signed(i_RAMData(16 to 31)); 
							end if;
							wt_ptr := wt_ptr + 1;

							ptr <= rrp_ptr(0 to G_AWIDTH-1);
							state <= STATE_WAIT_2;
						end if;
						
					when STATE_WAIT_2 =>
						state <= STATE_GET_RRP;
						
					-- get rrp value
					when STATE_GET_RRP =>
						if (i=0) then
							state <= STATE_SET_SR_ADDR;
						else
							i := i - 1;
							--tmp1=rrp[i]
							if rrp_ptr(G_AWIDTH) = '0' then
								tmp1 := signed(i_RAMData(0 to 15));
							elsif rrp_ptr(G_AWIDTH) = '1' then
								tmp1 := signed(i_RAMData(16 to 31));
							end if;
							rrp_ptr := rrp_ptr - 1;
							
							ptr <= v_ptr(0 to G_AWIDTH-1);
							state <= STATE_WAIT_3;
						end if;
					
					when STATE_WAIT_3 =>
						state <= STATE_GET_V;
						
					-- get value of v[i]
					when STATE_GET_V =>
						--tmp2=v[i]
						if v_ptr(G_AWIDTH) = '0' then
							tmp2 := signed(i_RAMData(0 to 15));
							v_input := signed(i_RAMData(0 to 15));
						elsif v_ptr(G_AWIDTH) = '1' then
							tmp2 := signed(i_RAMData(16 to 31));
							v_input := signed(i_RAMData(16 to 31));
						end if;
						v_ptr := v_ptr + 1;
						ptr <= v_ptr(0 to G_AWIDTH-1);
						state <= STATE_WAIT_4;
						
					when STATE_WAIT_4 =>
						state <= STATE_GET_CURRENT_V_VALUES;
					
					--buffer output
					when STATE_GET_CURRENT_V_VALUES =>
						outputbuffer_v := i_RAMData;						
						state <= STATE_CALCULATING;
					
					--calculate values
					when STATE_CALCULATING =>
						--tmp2 = gsm_mult_r(rrp[i],v[i])
						if(tmp1 = to_signed(-32768,16) and tmp2 = to_signed(-32768,16)) then
							tmp2 := to_signed(32767,16);
						else
							mul_result := ( tmp1 * tmp2 ) + 16384; 
							tmp2 := mul_result(30 downto 15);
						end if;
						
						--sri = GSM_SUB(sri, tmp2)
						ltmp := to_signed( (to_integer(sri) - to_integer(tmp2)) ,32);
						if (ltmp >= to_signed(32767,32)) then
							sri := to_signed(32767,16);
						elsif (ltmp <= to_signed(-32768,32)) then
							sri := to_signed(-32768,16);
						else
							sri := ltmp(15 downto 0);
						end if;
						
						--tmp1 = gsm_mult_r(rrp[i] , sri)
						if(tmp1 = to_signed(-32768,16) and sri = to_signed(-32768,16)) then
							tmp1 := to_signed(32767,16);
						else
							mul_result := (tmp1 * sri) + 16384; 
							tmp1 := mul_result(30 downto 15);
						end if;
						
						--v[i+1] = GSM_ADD( v[i], tmp1)
						ltmp := to_signed( (to_integer(v_input) + to_integer(tmp1)), 32);
						if ( ((ltmp) - (-32768)) > (32767 - (-32768)) ) then
							if (ltmp > to_signed(0,32)) then
								v_output := to_signed(32757,16);
							else
								v_output := to_signed(-32768,16);
							end if;
						else
							v_output := to_signed( to_integer(ltmp) ,16);
						end if;
						
						--build outputbuffer_v
						if (v_ptr(G_AWIDTH) = '1') then
							outputbuffer_v(15 downto 0) := unsigned(v_output);
						elsif (v_ptr(G_AWIDTH) = '0') then
							outputbuffer_v(31 downto 16) := unsigned(v_output);
						end if;
						
						ptr <= v_ptr(0 to G_AWIDTH-1);
						o_RAMdata <= outputbuffer_v;
						state <= STATE_WAIT_5;
						
					when STATE_WAIT_5 =>
						state <= STATE_WRITE_STATE;
						
					-- save new value in v[i+1]
					when STATE_WRITE_STATE =>
						-- save v[i+1]
						o_RAMWE <= '1';
						state <= STATE_WAIT_6;
						
					when STATE_WAIT_6 =>						
						v_ptr := v_ptr - 2;
						ptr <= rrp_ptr(0 to G_AWIDTH-1);
						state <= STATE_WAIT_2;
					
					when STATE_SET_SR_ADDR =>
						ptr <= sr_ptr(0 to G_AWIDTH-1);
						state <= STATE_WAIT_7;
					
					when STATE_WAIT_7 =>
						state <= STATE_SAVE_SR_STATUS;
					
					--save current SR_STATUS
					when STATE_SAVE_SR_STATUS =>
						outputbuffer := i_RAMData; 
						state <= STATE_WRITE_SR_1;
					
					-- manipulate sr_status
					when STATE_WRITE_SR_1 =>
						if sr_ptr(G_AWIDTH) = '0' then
							outputbuffer(31 downto 16) := unsigned(sri);
						elsif sr_ptr(G_AWIDTH) = '1' then
							outputbuffer(15 downto 0) := unsigned(sri);
						end if;
						
						ptr <= sr_ptr(0 to G_AWIDTH-1);
						state <= STATE_WRITE_SR_2;
						
					-- *sr++ = v[0]
					when STATE_WRITE_SR_2 =>
						o_RAMdata <= outputbuffer;
						o_RAMWE <= '1';
						sr_ptr := sr_ptr + 1;
						state <= STATE_SET_ADDR_V0;
					
					when STATE_SET_ADDR_V0 =>
						ptr <= C_V_START(0 to G_AWIDTH-1);
						state <= STATE_WAIT_99;
						
					when STATE_WAIT_99 =>
						state <= STATE_READ_V0;
						
					when STATE_READ_V0 =>
						outputbuffer_2 := i_RAMdata;
						state <= STATE_WRITE_SR_3;
						
					--v[0] = sri
					when STATE_WRITE_SR_3 =>
						outputbuffer_2(31 downto 16) := unsigned(sri);
						state <= STATE_WRITE_SR_4;
						
					-- write v[0] = sri
					when STATE_WRITE_SR_4 =>
						o_RAMdata <= outputbuffer_2;
						o_RAMWE <= '1';
						
						--internal_reset
						v_ptr		:= C_V_START;
						v_ptr		:= v_ptr + 7;
						rrp_ptr	:= C_RRP_START;
						rrp_ptr	:= rrp_ptr + 7;
						i := to_signed(8,32);
						
						state <= STATE_SET_WT_ADDR;
						
					when STATE_SET_WT_ADDR =>
						--set ptr for next loop
						ptr <= wt_ptr(0 to G_AWIDTH-1);
						state <= STATE_WAIT_8;
						
					when STATE_WAIT_8 =>
						state <= STATE_SET_SRI;
						
					--Done
					when STATE_DONE =>
						done <= '1';
						wt_ptr := C_WT_START;
						state <= STATE_IDLE;
				end case;
			end if;
	end process;
end Behavioral;
