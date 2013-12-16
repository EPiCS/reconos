library ieee;
-- library fifo32_v1_00_a;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 -- use fifo32_v1_00_a.all;

--library proc_common_v3_00_a;
--use proc_common_v3_00_a.proc_common_pkg.all;

--library reconos_v3_00_a;
--use reconos_v3_00_a.reconos_pkg.all;

--library ana_v1_00_a;
--use ana_v1_00_a.anaPkg.all;



-- This entity checks input data for characters represented in UTF-8 non-shortest form.
-- http://www.unicode.org/versions/corrigendum1.html
-- it returns exactly one result per packet (i.e. one clock cycle where result_valid is set).


entity ca_utf8_nonshortest_form is
	port (
		-- This entity receives data packets...
		rst          	:	in 	std_logic;
		clk          	:	in 	std_logic;
		rx_sof       	:	in 	std_logic;
		rx_eof       	:	in 	std_logic;
		rx_data      	:	in 	std_logic_vector(7 downto 0);
		rx_data_valid	:	in 	std_logic;
		rx_ca_ready  	:	out	std_logic;
		-- ... and returns one result per packet. 
		tx_result      	:	out	std_logic;
		tx_result_valid	:	out	std_logic
	);

end ca_utf8_nonshortest_form;

--------------------------------------------------------------

architecture implementation of ca_utf8_nonshortest_form is

	-- some constants
	constant	RESET       	:	std_logic	:= '1'; -- define if rst is active low or active high
	constant	GOOD_FORWARD	:	std_logic	:= '1'; -- used constants instead of a "type" to simplify feeding it into a FIFO of std_logic_vector's.s
	constant	EVIL_DROP   	:	std_logic	:= '0';


	--			 ######   ####   ######    ##    ##     ###     ## 
	--			##    ##   ##   ##    ##   ###   ##    ## ##    ##
	--			##         ##   ##         ####  ##   ##   ##   ## 
	--			 ######    ##   ##   ####  ## ## ##  ##     ##  ## 
	--			      ##   ##   ##    ##   ##  ####  #########  ## 
	--			##    ##   ##   ##    ##   ##   ###  ##     ##  ## 
	--			 ######   ####   ######    ##    ##  ##     ##  ######## 
	-- signal declarations

	type  	detector_state	is(	
	      	              	   	unknown_idle, -- Note that we don't need an explicit id le state since it has the same meaning as the not yet known state.
	      	              	   	good,
	      	              	   	evil,
	      	              	   	evil_wait, -- evil bit was already sent, 
	      	              	   	examine_2nd_byte_3, -- for 3-byte chars.
	      	              	   	examine_2nd_byte_4); -- for 4-byte chars.
	signal	state         	:  	detector_state; -- we only have one FSM in this entity, so this name is unambigous.
	signal	next_state    	:  	detector_state;

	-- Define what to do when EOF arrives while analysing a multibyte character.
	constant	SAFE_STATE	:	detector_state	:= evil; -- Default is evil.


	-- This entity is the innermost, it has no components.


--				########   ########   ######    ####  ##    ## 
--				##     ##  ##        ##    ##    ##   ###   ## 
--				##     ##  ##        ##          ##   ####  ## 
--				########   ######    ##   ####   ##   ## ## ## 
--				##     ##  ##        ##    ##    ##   ##  #### 
--				##     ##  ##        ##    ##    ##   ##   ### 
--				########   ########   ######    ####  ##    ## 
begin
	-- This content analyser has not delay, it is always ready :-).
	rx_ca_ready	<=	'0' when (rst = RESET)	else '1'; 


	-- there are no components, so no instantiations either.


	-- processes

-- TODO description of the states.
	-- The entity's purpose is to check for non-shortest form. This is done with the following state machine.
	--
	-- Description of the states:
	-- Note that we don't need an explicit idle state since it has the same meaning as the not yet known state.
	--
	-- unknown_idle      	(initial state)
	--                   	Nothing evil has been found so far. 
	--                   	Inspect the next byte.
	--                   	Then, jump to "evil", "examine_2nd_byte_n" resp. the initial state.
	--                   	If EOF arrives, jump to the "good"-State	
	-- examine_2nd_byte_n	(n \in {3, 4})
	--                   	In order to know the result, the second byte of a n-byte character has to be inspected.
	--                   	Inspect the next byte.
	--                   	Then, jump to "evil" resp. the initial state.
	-- good              	Nothing evil has been found so far and EOF has arrived.
	--                   	Send the result (good) to the output during exactly one clock cycle. 
	--                   	Then, continue with the next packet.
	-- evil              	Something evil has been found.
	--                   	Send the result (evil) to the output during exactly one clock cycle. 
	--                   	Then, jump to evil_wait in order to wait for EOF. 
	-- evil_wait         	The result (evil) is known and has already been sent.
	--                   	Just wait for EOF.
	--                   	Then, jump back to the initial state.
	-- SAFE_STATE        	(Not an actual state, but a variable)
	--                   	The byte currently inspected is part of a multibyte character,
	--                   	it could be an attack, but EOF arrives.
	--                   	Jump to the state defined in this variable.
	--                   	You may set this variable to "good" or "evil".


	memless : process(	state, 
	                  	rx_data,
	                  	rx_eof,
	                  	-- rx_sof, --not needed, this entity just has to check as long as the data are valid.
	                  	rx_data_valid)
	begin
		-- default: Do not change anything. 
		next_state     	<= state; 
		--next_state   	<= SAFE_STATE; 
		tx_result_valid	<= '0';
		--tx_result    	<= ; -- don't care as long as it is not valid.

		-- The two states "good" and "evil" forward the result of the content analysis to the next upper entity. 
		-- They have to be left after exactly one clock cycle because only one result bit per packet is allowed in the result FIFOs, 
		-- All other states perform the actual content analysis. 
		-- They shall only be processed when the data received is valid.

		-- forward result and leave state on next clock cycle:
		case state is
			when good =>
				-- give out good signal
				tx_result      	<=	GOOD_FORWARD;
				tx_result_valid	<=	'1';
				-- directly jump back to default state.
				-- EOF has already arrived i.e. we don't need any good_wait state.
				next_state	<=	unknown_idle; 

			when evil =>
				-- send evil signal. 
				tx_result      	<=	EVIL_DROP;
				tx_result_valid	<=	'1';
				
				if (rx_eof = '1') then
					next_state	<=	unknown_idle; 
				else
					-- wait if EOF has not arrived yet. 
					next_state	<=	evil_wait; 
				end if ;

				when others => 
					-- Do nothing. 
					-- All other states will be checked in the "if rx_data_valid" statement below. 
		end case; -- state

		-- the actual content analysis: 
		if (rx_data_valid='1') then 
			-- default:
			--next_state     	<=	SAFE_STATE; 
			--tx_result_valid	<=	'0';

			case state is

			-- search for multi-byte characters which could have been represented using a shorter form.
			-- 
			-- # bytes	max. #bits	binary representation
			-- 1      	 7 bit    	0xxx xxxx
			--        	          	
			-- 2      	11 bit    	110x xxxx   10xx xxxx
			--        	          	        ^ 7th x-bit
			-- 3      	16 bit    	1110 xxxx   10xx xxxx   10xx xxxx
			--        	          	               ^ 11th x-bit
			-- 4      	21 bit    	1111 0xxx   10xx xxxx   10xx xxxx   10xx xxxx
			--        	          	                 ^ 16th x-bit
			--
			-- If there are only 0's in the x-bite before the bit marked with ^, the character could have been represented using a shorter representation. 
			-- i.e. it is evil  }:-)
			-- If not, it is good O:-)
			-- 
			-- as one can see, only the first 2 bytes are necessary to decide wether the packet is evil or not.
			

				when unknown_idle =>

					-- TODO probably there would be a more elegant way to the the EOF handling than all these copypasta if statements...

					-- Bytes which contain 7-bit ASCII characters "0xxx xxxx" are valid O:-)
					-- Latter bytes of a multibyte character "10xx xxxx" can be ignored since the first bytes have already been checked.
					if (rx_data(7) = '0' or rx_data(7 downto 6) = "10") then
						if (rx_eof = '1') then
							next_state	<=	good; 
						else
							next_state	<=	unknown_idle; 
						end if ;
					end if ;

					-- Look for the first byte of a 2-byte character: "110x xxxx"
					if (rx_data(7 downto 5) = "110") then
						if (rx_data(4 downto 1) = "0000" )  then
							-- 7-bit character represented with 2 bytes instead of 1 }:-)
							next_state	<=	evil;
						else
							-- a regular 2-byte character O:-)
							if (rx_eof = '1') then
								next_state	<=	good; 
							else
								next_state	<=	unknown_idle; 
							end if ;
						end if ;
					end if ;

					-- Look for the first byte of a 3-byte character: "1110 xxxx"
					if (rx_data(7 downto 4) = "1110") then
						if (rx_data(3 downto 0) = "0000") then
							-- character can be up to 12 bits long, need to check the second byte.
							if (rx_eof = '1') then
								next_state	<=	SAFE_STATE; 
							else
								next_state	<=	examine_2nd_byte_3; 
							end if ;
						else -- i.e. rx_data(3 downto 0) contain at least one '1' Bit
							-- 13 bit or longer, i.e. this is a regular 3-byte character O:-)
							if (rx_eof = '1') then
								next_state	<=	good; 
							else
								next_state	<=	unknown_idle; 
							end if ;
						end if ;
								
					end if ;

					-- Look for the first byte of a 4-byte character: "1111 0xxx"
					if (rx_data(7 downto 3) = "11110") then
						if (rx_data(2 downto 0) = "000") then
							-- character can be up to 18 bit long, need to check the second byte.
							if (rx_eof = '1') then
								next_state	<=	SAFE_STATE; 
							else
								next_state	<=	examine_2nd_byte_4; 
							end if ;
						else -- i.e. rx_data(2 downto 0) contain at least one '1' Bit
							-- 19 bit or longer, i.e. this is a regular 4-byte character O:-)
							if (rx_eof = '1') then
								next_state	<=	good; 
							else
								next_state	<=	unknown_idle; 
							end if ;
						end if ;
					end if ;


					-- EOF handling.
					-- not known means "nothing evil found so far". 
					-- i.e. when EOF arrives: jump to "good"
					-- if (rx_eof = '1') then
					--         	next_state	<=	good; 
					-- end if ;	          	  			

					-- if (next_state = SAFE_STATE or next_state = unknown_idle) then
					--	if (rx_eof = '1') then
					  	
					--	end if ;
					--	-- default for EOF.
					--	next_state	<=	good; 
					-- else
					--	next_state	<= SAFE_STATE; 
					-- end if; 
								

				when examine_2nd_byte_3 =>
					-- It may happen that EOF arrives while inspecting a character. In this case, jump to a safe state.
					-- if (rx_eof='1')  then
					--	next_state	<=	SAFE_STATE;

					-- examine the 2nd byte of a 3-byte character
					if (rx_data(7 downto 5) = "100") then
						-- 11 bit character represented with 3 bytes instead of 2 }:-)
						next_state	<=	evil;
					else
						-- regular 3-byte character
						if (rx_eof = '1') then
							next_state	<=	good; 
						else
							next_state	<=	unknown_idle; 
						end if ;
					end if ;


				when examine_2nd_byte_4 =>
					-- It may happen that EOF arrives while inspecting a character. In this case, jump to a safe state.
					-- if (rx_eof='1')  then
					--	next_state	<=	SAFE_STATE;

					-- examine the 2nd byte of a 3-byte character
					if (rx_data(7 downto 4) = "1000") then
						-- 16 bit character represented with 4 bytes instead of 3 }:-)
						next_state	<=	evil;
					else
						-- regular 4-byte character
						if (rx_eof = '1') then
							next_state	<=	good; 
						else
							next_state	<=	unknown_idle; 
						end if ;
					end if ;


				when evil_wait =>
					-- just wait for EOF.

					if (rx_eof = '1') then
						next_state	<=	unknown_idle; 
					else
						next_state	<=	evil_wait; 
					end if ;

				when others => -- i.e. "good" and "evil" 
					-- Do nothing. 
					-- These states are already covered before the "if rx_data_valid" statement.
				
			end case; -- state
		end if ; -- rx_data_valid
	end process; -- memless

	memzing : process( clk, rst )
	begin
	    if rst = RESET then
			state	<=	unknown_idle;
	    elsif rising_edge(clk) then
			state	<=	next_state; 
	    end if;
	end process ; -- memzing



	-- TODO do we need logging within this entity?


end architecture;
