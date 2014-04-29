--
-- adpcm.vhd
-- adpcm encoder/decoder
-- 
-- Author:		Alexander Sprenger	<alsp@mail.upb.de>
-- History:		03.01.2013	Alexander Sprenger created

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity adpcm is

  generic (
    G_AWIDTH : integer := 11;           -- in bits
    G_DWIDTH : integer := 32            -- in bits
    );

  port (
    clk   : in std_logic;
    reset : in std_logic;
	 
	 coder_decoder: in std_logic;	--1=>coder / 0=>decoder 
	 count : in unsigned(0 to G_AWIDTH);

    -- local ram interface
    o_RAMAddr : out unsigned(0 to G_AWIDTH-1);
    o_RAMData : out unsigned(0 to G_DWIDTH-1);
    i_RAMData : in  unsigned(0 to G_DWIDTH-1);
    o_RAMWE   : out std_logic;
	 
	 -- ADPCM state
	 i_state_valprev : in signed(15 downto 0) := (others => '0');
	 i_state_index	  : in unsigned(7 downto 0) := (others => '0');
	 
	 o_state_valprev : out signed(15 downto 0) := (others => '0');
	 o_state_index	  : out unsigned(7 downto 0) := (others => '0');
	 
    start     : in  std_logic;
    done      : out std_logic
    );
end adpcm;

architecture Behavioral of adpcm is

	type state_t is (	STATE_IDLE,
							STATE_INIT,
							STATE_GET_DATA,
							STATE_WAIT_1,
							STATE_GET_DATA_2,
							STATE_RUNNING_1, 
--							STATE_RUNNING_2,
--							STATE_RUNNING_3,
--							STATE_RUNNING_4,
--							STATE_RUNNING_5,
--							STATE_RUNNING_6,
							STATE_WRITE_DATA, 
							STATE_INC_ADDR, 
							STATE_SAVE_ADPCM_STATE,
							STATE_WAIT_2,
							STATE_DONE
	);

	type adpcm_mode_t is (	ENCODER,
							DECODER
	);
	
	type ADPCM_STEP_VARIATION_TABLE_T is array (0 to 15) of integer range -1 to 8;
	type ADPCM_STEP_SIZE_TABLE_T is array (0 to 88) of natural range 7 to 32767;
  
  signal state : state_t := STATE_IDLE;
  signal adpcm_mode : adpcm_mode_t := ENCODER;
  
  signal ptr 		: unsigned(0 to G_AWIDTH);
  signal ptr_max 	: unsigned(0 to G_AWIDTH);

begin
	-- set RAM address
	o_RAMAddr <= ptr(0 to G_AWIDTH-1);  

	-- adpcm_coder state machine
	adpcm_coder_proc	: process(clk, reset)
		variable indexTable 		: ADPCM_STEP_VARIATION_TABLE_T := (	-1, -1, -1, -1, 2, 4, 6, 8, 
																						-1, -1, -1, -1, 2, 4, 6, 8);
		variable stepsizeTable	: ADPCM_STEP_SIZE_TABLE_T := (7,		8,		9,		10,	11,	12,	13,	14,	16,	17,
																				19,	21,	23,	25,	28,	31,	34,	37,	41,	45,
																				50,	55,	60,	66,	73,	80,	88,	97,	107,	118,
																				130,	143,	157,	173,	190,	209,	230,	253,	279,	307,
																				337,	371, 	408, 	449, 	494, 	544, 	598, 	658, 	724, 	796,
																				876, 	963, 	1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
																				2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
																				5894, 6484, 7132, 7845, 8630, 9493, 10442,11487,12635,13899,
																				15289,16818,18500,20350,22385,24623,27086,29794,32767);
		variable sign 		: signed(31 downto 0) := (others => '0'); 
		variable delta 	: signed(31 downto 0) 	:= (others => '0'); 
		variable diff 		: signed(31 downto 0)	:= (others => '0'); 
		variable step 		: signed(31 downto 0) := (others => '0'); 
		variable valpred	: signed(31 downto 0)	:= (others => '0'); 
		variable vpdiff	: signed(31 downto 0) 	:= (others => '0'); 
		variable index		: signed(31 downto 0) := (others => '0');
		variable outputbuffer	: unsigned((G_DWIDTH)-1 downto 0) := (others => '0'); 
		variable bufferstep		: natural range 0 to 8;
		variable in_ptr	: unsigned(0 to G_AWIDTH) := (others => '0');
		variable out_ptr	: unsigned(0 to G_AWIDTH) := (others => '0');
		variable value	: signed(15 downto 0);
		variable output_bufferstep : std_logic := '0';
		
		variable last_run : std_logic := '0';
																			
		begin	
		 --RESET
		 if reset = '1' then
			ptr       		<= (others => '0');
			in_ptr			:= (others => '0');
			out_ptr			:= (others => '0');
			o_RAMData 		<= (others => '0');
			o_RAMWE   		<= '0';
			done				<= '0';
			sign				:= (others => '0');
			delta				:= (others => '0');
			step				:= (others => '0');
			valpred			:= (others => '0');
			vpdiff			:= (others => '0');
			index				:= (others => '0');
			outputbuffer	:= (others => '0');
			bufferstep		:= 0;		
			ptr_max 			<= (others => '0');
			state 			<= STATE_IDLE;
			adpcm_mode		<= ENCODER;
			o_state_valprev 	<= (others => '0');
			last_run 		:= '0';
			output_bufferstep := '0';
		 
		 elsif rising_edge(clk) then
			o_RAMWE   <= '0';
			done		 <= '0';
			
			case adpcm_mode is
				-- control whether used as encode or decode 
				when ENCODER =>
					case state is
					  when STATE_IDLE =>
							-- start calculating on 'start' signal
							if start = '1' then
								if(coder_decoder = '1') then
									-- encoder
									adpcm_mode <= ENCODER;
								else
									--decoder
									adpcm_mode <= DECODER;
								end if;					
								state   <= STATE_INIT;
							end if;
					
					--INIT
					  when STATE_INIT =>
							in_ptr := (others => '0');
							valpred  := to_signed(to_integer(i_state_valprev),32);
							index 	:= to_signed(to_integer(i_state_index),32);
							step		:= to_signed(stepSizeTable(to_integer(index)),32);
							bufferstep := 0;
							
							if count(G_AWIDTH) = '0' then		--if ((count mod 2) = 0) then
								ptr_max <= (count/2)-1;
								out_ptr := (count/2);	--write output behind the input
							else
								ptr_max <= (count/2);
								out_ptr := (count/2)+1;	--write output behind the input
							end if;							
							state   <= STATE_GET_DATA;

						 -- get value
					  when STATE_GET_DATA =>
							-- get 16-bit word
							ptr <= in_ptr;
							state <= STATE_WAIT_1;
							
					  when STATE_WAIT_1 =>
							state <= STATE_GET_DATA_2;
							
					  when STATE_GET_DATA_2 =>
							if in_ptr(G_AWIDTH) = '1' then 
								value := to_signed(to_integer(i_RAMData((G_DWIDTH/2) to G_DWIDTH-1)),16);
							elsif in_ptr(G_AWIDTH) = '0' then
								value := to_signed(to_integer(i_RAMData(0 to (G_DWIDTH/2)-1)),16);
							end if;
							
							state <= STATE_RUNNING_1;       
					
					-- convert value
					  when STATE_RUNNING_1 =>	
							diff := to_signed(to_integer(value) - to_integer(valpred),32);
							
							if (diff < 0) then
								sign := X"00000008";
								diff := -diff;
							else
								sign := (others => '0');
							end if;
							
							delta := (others => '0');
							vpdiff := X"0000" & "000" & signed(step(15 downto 3));
--							state <= STATE_RUNNING_2;
--					  
--					  when STATE_RUNNING_2 =>
							if diff >= to_integer(step) then
								delta := to_signed(4,32);
								diff := diff - to_integer(step);
								vpdiff := vpdiff + to_integer(step);
							end if;
							step := X"0000" & '0' & step((G_DWIDTH/2)-1 downto 1);
--							state <= STATE_RUNNING_3;
--					  
--					  when STATE_RUNNING_3 =>
							if diff >= to_integer(step) then
								delta := delta or to_signed(2,32);
								diff := diff - to_integer(step);
								vpdiff := vpdiff + to_integer(step);
							end if;					
							step := X"0000" & '0' & step((G_DWIDTH/2)-1 downto 1);
--							state <= STATE_RUNNING_4;
--							
--					  when STATE_RUNNING_4 =>
							if diff >= to_integer(step) then
								delta := delta or to_signed(1,32);
								vpdiff := vpdiff + to_integer(step);
							end if;
--							state <= STATE_RUNNING_5;
--					  
--					  when STATE_RUNNING_5 =>
							if sign = to_signed(8,32) then
								--valpred := valpred - vpdiff;
								if ( to_integer(valpred) - to_integer(vpdiff) ) > 32767 then--to_signed(32767,16) then
									valpred := to_signed(32767,32);
								elsif ( to_integer(valpred) - to_integer(vpdiff) ) < -32768 then --to_signed(-32768,16) then
									valpred := to_signed(-32768,32);
								else
									valpred := valpred - vpdiff;
								end if;
							else
								--valpred := valpred + vpdiff;
								if ( to_integer(valpred) + to_integer(vpdiff) ) > 32767 then--to_signed(32767,16) then
									valpred := to_signed(32767,32);
								elsif ( to_integer(valpred) + to_integer(vpdiff) ) < -32768 then --to_signed(-32768,16) then
									valpred := to_signed(-32768,32);
								else
									valpred := valpred + vpdiff;
								end if;
							end if;
--							state <= STATE_RUNNING_6;
--					  
--					  when STATE_RUNNING_6 => 												
							delta := delta or (signed(sign));

							if ( to_integer(index) + indexTable(to_integer(delta)) ) < 0 then
								index := to_signed(0,32);
							elsif ( to_integer(index) + indexTable(to_integer(delta)) ) > 88 then
								index := to_signed(88,32);
							else
								index := index + indexTable(to_integer(delta));
							end if;
							
							step := to_signed(stepSizeTable(to_integer(index)),32);
							
							-- buffer output til a whole word can be written
							if bufferstep = 0 then
								outputbuffer := unsigned(delta(3 downto 0) & X"0000000"); 
							elsif bufferstep = 1 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-4) & unsigned(delta(3 downto 0) & X"000000");
							elsif bufferstep = 2 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-8) & unsigned(delta(3 downto 0) & X"00000");
							elsif bufferstep = 3 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-12) & unsigned(delta(3 downto 0) & X"0000");
							elsif bufferstep = 4 then 
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-16) & unsigned(delta(3 downto 0) & X"000");
							elsif bufferstep = 5 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-20) & unsigned(delta(3 downto 0) & X"00");
							elsif bufferstep = 6 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-24) & unsigned(delta(3 downto 0) & X"0");
							elsif bufferstep = 7 then
								outputbuffer := outputbuffer(G_DWIDTH-1 downto G_DWIDTH-28) & unsigned(delta(3 downto 0));
							end if;
							bufferstep := bufferstep + 1;				
							
							ptr <= out_ptr(1 to G_AWIDTH) & '0';
							state <= STATE_WRITE_DATA;
						 
						 -- write value
					  when STATE_WRITE_DATA =>
							if ( in_ptr(0 to G_AWIDTH-1) >= ptr_max(1 to G_AWIDTH) ) and (in_ptr(G_AWIDTH) = '1')then
								state <= STATE_SAVE_ADPCM_STATE;
							elsif bufferstep = 8 then	
								bufferstep := 0;
								o_RAMData <= unsigned(outputbuffer);				 
								o_RAMWE   <= '1';
								
								--next State
								state <= STATE_INC_ADDR;
							else
								in_ptr := in_ptr + 1;
								state <= STATE_GET_DATA;
							end if;
						 
					  when STATE_INC_ADDR =>
							in_ptr	  := in_ptr + 1;
							out_ptr   := out_ptr + 1;
							state <= STATE_GET_DATA;
						 
						-- save current adpcm_State
					  when STATE_SAVE_ADPCM_STATE =>
							o_RAMData <= unsigned(outputbuffer);				 
							o_RAMWE   <= '1';
														
							o_state_valprev <= to_signed(to_integer(valpred),16);
							o_state_index <= to_unsigned(to_integer(index),8);
							state <= STATE_WAIT_2;
						
						when STATE_WAIT_2 =>	
							state <= STATE_DONE;
						
						when STATE_DONE =>
							done <= '1';
							state <= STATE_IDLE;
						
						when others =>
							state <= STATE_IDLE;
					end case;

--DECODER-------------------------------------------------------------------					
				when DECODER =>
					case state is 
						when STATE_IDLE =>
							-- start calculating on 'start' signal
							if start = '1' then
								if(coder_decoder = '1') then
									-- encoder
									adpcm_mode <= ENCODER;
								else
									--decoder
									adpcm_mode <= DECODER;
								end if;					
								state   <= STATE_INIT;
							end if;
						
						-- INIT
						when STATE_INIT =>
							in_ptr := (others => '0');
							out_ptr := (count/8);
							ptr_max <= (count/8)-1;
							valpred  := to_signed(to_integer(i_state_valprev),32);
							index 	:= to_signed(to_integer(i_state_index),32);
							step		:= to_signed(stepSizeTable(to_integer(index)),32);
							bufferstep := 0;
							output_bufferstep := '0';
							state <= STATE_GET_DATA;
						
						--get value
						when STATE_GET_DATA =>
							-- get 4-bit from input
							ptr <= in_ptr(1 to G_AWIDTH) & '0';
							state <= STATE_WAIT_1;
						
						when STATE_WAIT_1 =>
							state <= STATE_GET_DATA_2;
							
						when STATE_GET_DATA_2 =>
							-- getting the correct sample
							case bufferstep is
								 when 0 => delta(3 downto 0) := signed(i_RAMData(0 to 3));
								 when 1 => delta(3 downto 0) := signed(i_RAMData(4 to 7));
								 when 2 => delta(3 downto 0) := signed(i_RAMData(8 to 11));
								 when 3 => delta(3 downto 0) := signed(i_RAMData(12 to 15));
								 when 4 => delta(3 downto 0) := signed(i_RAMData(16 to 19));
								 when 5 => delta(3 downto 0) := signed(i_RAMData(20 to 23));
								 when 6 => delta(3 downto 0) := signed(i_RAMData(24 to 27));
								 when 7 => delta(3 downto 0) := signed(i_RAMData(28 to 31));
								 when others => bufferstep := 0;
							end case;
							bufferstep := bufferstep + 1;
							if bufferstep = 8 then
								bufferstep := 0;
								in_ptr := in_ptr + 1;
							end if;
							
							if output_bufferstep = '0' then 
								outputbuffer := (others => '0');
							end if;
							
							state <= STATE_RUNNING_1;
						
						--convert value
						when STATE_RUNNING_1 =>
							if ( to_integer(index) + indexTable(to_integer(delta)) ) < 0 then
								index := to_signed(0,32);
							elsif ( to_integer(index) + indexTable(to_integer(delta)) ) > 88 then
								index := to_signed(88,32);
							else
								index := index + indexTable(to_integer(delta));
							end if;
							
							sign := (others => '0');
							sign(3) := delta(3);
							delta(3) := '0';
							
							vpdiff := "000" & step(31 downto 3);
							
							if delta(2) = '1' then --( ( delta and to_signed(4,32) ) /= 0) then
								vpdiff := vpdiff + step;
							end if;
							if delta(1) = '1' then --( ( delta and to_signed(2,32) ) /= 0) then
								vpdiff := vpdiff + ('0' & step(31 downto 1));
							end if;
							if delta(0) = '1' then --( ( delta and to_signed(1,32) ) /= 0) then
								vpdiff := vpdiff + ("00" & step(31 downto 2));
							end if;
							
							if sign /= 0 then
									--valpred := valpred - vpdiff;
								if ( to_integer(valpred) - to_integer(vpdiff) ) > 32767 then--to_signed(32767,16) then
									valpred := to_signed(32767,32);
								elsif ( to_integer(valpred) - to_integer(vpdiff) ) < -32768 then --to_signed(-32768,16) then
									valpred := to_signed(-32768,32);
								else
									valpred := valpred - vpdiff;
								end if;
							else
								--valpred := valpred + vpdiff;
								if ( to_integer(valpred) + to_integer(vpdiff) ) > 32767 then--to_signed(32767,16) then
									valpred := to_signed(32767,32);
								elsif ( to_integer(valpred) + to_integer(vpdiff) ) < -32768 then --to_signed(-32768,16) then
									valpred := to_signed(-32768,32);
								else
									valpred := valpred + vpdiff;
								end if;
							end if;
							
							step := to_signed(stepSizeTable(to_integer(index)),32);
							
							-- buffer outpur til a whole word can be written
							if output_bufferstep = '0' then 
								outputbuffer(31 downto 16) := unsigned(valpred(15 downto 0));
								output_bufferstep := '1';
							elsif output_bufferstep = '1' then
								outputbuffer(15 downto 0) := unsigned(valpred(15 downto 0));
								output_bufferstep := '0';
							end if;
							ptr <= out_ptr(1 to G_AWIDTH) & '0';
							state <= STATE_WRITE_DATA;
							
						--write data
						when STATE_WRITE_DATA =>
							if ( in_ptr > ptr_max ) then
								state <= STATE_SAVE_ADPCM_STATE;
							elsif output_bufferstep = '0' then
								o_RAMData <= unsigned(outputbuffer);				 
								o_RAMWE   <= '1';

								state <= STATE_INC_ADDR;
							else
								state <= STATE_GET_DATA;
							end if;
							
						when STATE_INC_ADDR =>
							out_ptr := out_ptr + 1;
							state <= STATE_GET_DATA;
							
						--save current adpcm_state
						when STATE_SAVE_ADPCM_STATE =>
							o_RAMData <= unsigned(outputbuffer);				 
							o_RAMWE   <= '1';
														
							o_state_valprev <= to_signed(to_integer(valpred),16);
							o_state_index <= to_unsigned(to_integer(index),8);
							state <= STATE_WAIT_2;
						
						when STATE_WAIT_2 =>	
							state <= STATE_DONE;
						
						when STATE_DONE =>
							done <= '1';
							state <= STATE_IDLE;
						
						when others =>
							state <= STATE_IDLE;
					end case;
			end case;
		end if;
	end process;
end Behavioral;
