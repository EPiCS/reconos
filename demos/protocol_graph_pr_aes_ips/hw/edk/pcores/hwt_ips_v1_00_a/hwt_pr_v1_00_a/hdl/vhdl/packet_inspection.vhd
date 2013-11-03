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



-- This entity ...
-- TODO


entity packet_inspection is
	generic (
		PACKET_MAX_LENGTH         	:	integer	:= 1500;	-- Maximum length of a packet. Needed to compute the # results that have to be stored. 
		PACKET_MIN_LENGTH         	:	integer	:= 64;  	-- Minimum length of a packet.
		HEADER_MAX_LENGTH         	:	integer	:= 42   	-- Maximum length of header data (in bytes).
		-- CLOG2_HEADER_MAX_LENGTH	:	integer	:= 10   	-- Maximum bit width of header length. 10 Bits = Max. 1024 Bytes header length
	);
	port (
		rst	:	in	std_logic;
		clk	:	in	std_logic;
		-- This entity receives data packets...
		rx_sof                   	:	in 	std_logic;
		rx_eof                   	:	in 	std_logic;
		rx_data                  	:	in 	std_logic_vector(7 downto 0);
		rx_data_valid            	:	in 	std_logic;	-- source ready
		rx_packetinspection_ready	:	out	std_logic;	-- destination ready
		-- ... and returns results (note: no data packets).
		tx_result    	:	out	std_logic; -- from the outside this interface looks like a FIFO
		tx_fifo_empty	:	out	std_logic;
		tx_fifo_read 	:	in 	std_logic;
		-- the Header length can be configured from the outside.
		rx_header_length   	:	in	integer	range 0 to HEADER_MAX_LENGTH+2	:= 1
		-- rx_header_length	:	in	unsigned (CLOG2_HEADER_MAX_LENGTH-1 downto 0)
	);
end packet_inspection;


architecture implementation of packet_inspection is

	-- some constants
	constant   	RESET            	:	std_logic	:= '1';	-- define if rst is active low or active high
	constant   	GOOD_FORWARD     	:	std_logic	:= '1';	-- used constants instead of a "type" to simplify feeding it into a FIFO of std_logic_vector's.
	constant   	EVIL_DROP        	:	std_logic	:= '0';	
	constant   	RESULT_WIDTH     	:	integer  	:= 1;  	-- in bits (good / evil).
	-- constant	HEADER_MAX_LENGTH	:	integer  	:= 42; 	-- Moved to Generic


	--			 ######  ####  ######   ##    ##    ###    ## 
	--			##    ##  ##  ##    ##  ###   ##   ## ##   ##
	--			##        ##  ##        ####  ##  ##   ##  ## 
	--			 ######   ##  ##   #### ## ## ## ##     ## ## 
	--			      ##  ##  ##    ##  ##  #### ######### ## 
	--			##    ##  ##  ##    ##  ##   ### ##     ## ## 
	--			 ######  ####  ######   ##    ## ##     ## ######## 
	-- signal declarations

	-- used to skip a certain amount of header bytes
	signal   	header_length        	:  	integer	range 0 to HEADER_MAX_LENGTH+2; 
	signal   	skipheader_count     	:  	integer	range 0 to HEADER_MAX_LENGTH+2; 
	signal   	skipheader_next_count	:  	integer	range 0 to HEADER_MAX_LENGTH+2; 
	-- signal	header_length        	:  	unsigned (CLOG2_HEADER_MAX_LENGTH-1 downto 0);
	-- signal	skipheader_count     	:  	unsigned (CLOG2_HEADER_MAX_LENGTH-1 downto 0);
	-- signal	skipheader_next_count	:  	unsigned (CLOG2_HEADER_MAX_LENGTH-1 downto 0);
	-- type  	skipheader_type      	is(	idle, 
	--       	                     	   	next_header_byte, 
	--       	                     	   	next_data_byte); 
	type     	skipheader_type      	is(	header_bytes, 
	         	                     	   	data_bytes); 
	signal   	skipheader_state     	:  	skipheader_type;	
	signal   	skipheader_next_state	:  	skipheader_type; 

	-- "data_valid" signal for the content analyser blocks. Will be set to 1 when the header is over (and the data are valid).
	signal	check_me  	:	std_logic; 
	signal	fifo_read 	:	std_logic; -- one fifo_read for all FIFOs is enough.
	signal	fifo_empty	:	std_logic; -- intermediate signal for tx_fifo_empty

	-- TODO to be automatised one day: one signal for each content analyser (ca_ready_1, ca ca_ready_2 ca_ready_3 etc.)
	signal	ca_ready_1     	:	std_logic; -- n'th content analyser block ready
	signal	result_1       	:	std_logic; -- result output of the n'tn content analyser block, input of the n'th FIFO
	signal	result_valid_1 	:	std_logic; -- valid bit of result_n
	signal	queued_result_1	:	std_logic; -- queued version of result_1, output of the FIFO
	signal	fifo_full_1    	:	std_logic; -- read, write, full and empty signal for the n'th FIFO
	signal	fifo_empty_1   	:	std_logic; 
	signal	fifo_write_1   	:	std_logic; 
	-- create std_logic_vector's for the fifos.
	signal	fifo_in_1 	:	std_logic_vector(RESULT_WIDTH-1 downto 0);
	signal	fifo_out_1	:	std_logic_vector(RESULT_WIDTH-1 downto 0);


	-- include components

	-- include one "analyser" component for each content analysis.
	-- TODO somehow automatise this process s.t. it includes all files in the content_analysers directory.
	component ca_utf8_nonshortest_form is
		port (
			rst            	:	in 	std_logic;
			clk            	:	in 	std_logic;
			rx_sof         	:	in 	std_logic;
			rx_eof         	:	in 	std_logic;
			rx_data        	:	in 	std_logic_vector(7 downto 0);
			rx_data_valid  	:	in 	std_logic;
			rx_ca_ready    	:	out	std_logic;
			tx_result      	:	out	std_logic;
			tx_result_valid	:	out	std_logic
		);
	end component;

	-- include FIFO component for the results
	component fifo32 is
	generic (
		C_FIFO32_WORD_WIDTH         	:	integer	:= RESULT_WIDTH;
		C_FIFO32_CONTROLSIGNAL_WIDTH	:	integer	:= 8; -- TODO
		-- TODO change this to relative values
		C_FIFO32_DEPTH          	:	integer := 24; -- 1500/64 (worst case # packets in packet FIFO). 
		CLOG2_FIFO32_DEPTH      	:	integer := 4; -- ceil(log2(depth))
		C_FIFO32_SAFE_READ_WRITE	:	boolean	:= true
	);
		port (
			Rst           	:	in	std_logic;
			-- ..._M_...  	=	input of the FIFO.
			-- ..._S_...  	=	output of the FIFO.
			FIFO32_S_Clk  	:	in 	std_logic;                                                	-- clock and data signals
			FIFO32_M_Clk  	:	in 	std_logic;                                                	
			FIFO32_S_Data 	:	out	std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);         	
			FIFO32_M_Data 	:	in 	std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);         	
			FIFO32_S_Fill 	:	out	std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);	-- # elements in the FIFO. 0 means FIFO is empty.
			FIFO32_M_Rem  	:	out	std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);	-- remaining free space. 0 means FIFO is full.
			FIFO32_S_Full 	:	out	std_logic;                                                	-- FIFO full signal
			FIFO32_M_Empty	:	out	std_logic;                                                	-- FIFO empty signal
			FIFO32_S_Rd   	:	in 	std_logic;                                                	-- output data ready
			FIFO32_M_Wr   	:	in 	std_logic   
		);
	end component;


--				########   ########   ######    ####  ##    ## 
--				##     ##  ##        ##    ##    ##   ###   ## 
--				##     ##  ##        ##          ##   ####  ## 
--				########   ######    ##   ####   ##   ## ## ## 
--				##     ##  ##        ##    ##    ##   ##  #### 
--				##     ##  ##        ##    ##    ##   ##   ### 
--				########   ########   ######    ####  ##    ## 
begin

	-- The FIFOs only contain valid results. So when the result is valid, write it to the FIFO.
	fifo_write_1	<=	result_valid_1;
	-- WARNING: This line of code assumes that each CA block only set this bit to '1' for one clock cycle. 
	-- If this assumption no longer holds, one needs to adapt it s.t. only one result bit per packet is written to the FIFO!


	-- You might not want to check the header of a packet for attacks.
	-- The following signal can be set to the number of bytes an the begin of a packet which shall be skipped.
	-- currently, the header length is assumed to be constant.
	--header_length	<=	1; -- in bytes
	header_length  	<=	rx_header_length; -- in bytes


	-- the result is std_logic, but the FIFO expects a std_logic_vector.
	fifo_in_1(0)   	<=	result_1;
	queued_result_1	<=	fifo_out_1(0); 

	-- only read FIFOs when they are not empty.
	-- Probably this code is redundant since the FIFOs cannot "underflow" (C_FIFO32_SAFE_READ_WRITE is set to true). 
	-- TODO Think about this and remove if redundant.
	fifo_read    	<=	tx_fifo_read	and not fifo_empty; 
	tx_fifo_empty	<=	fifo_empty; 



	-- component instantiations

	-- instantiate all content analysis components. TODO To be automatised...
	ca_utf8_nonshortest_form_inst : ca_utf8_nonshortest_form
	port map(
		-- The same signal for all content analysers.
		rst          	=>	rst,
		clk          	=>	clk,
		rx_sof       	=>	rx_sof,
		rx_eof       	=>	rx_eof,
		rx_data      	=>	rx_data,
		rx_data_valid	=>	check_me,
		-- Signals specific for each content analyser.
		-- TODO automatise here...
		rx_ca_ready    	=>	ca_ready_1,
		tx_result      	=>	result_1,
		tx_result_valid	=>	result_valid_1
	);



	-- instantiate a FIFO for each result.  TODO To be automatised...
	result_fifo_1 : fifo32
	--generic map(
	  	-- already defined above, we need the same generics for all FIFOs.
	--	)
	port map(
		Rst         	=> rst, 
		FIFO32_S_Clk	=> clk,
		FIFO32_M_Clk	=> clk,
		-- TODO automatise all ..._1's.
		FIFO32_S_Data  	=> fifo_out_1, 
		FIFO32_M_Data  	=> fifo_in_1, 
		--FIFO32_S_Fill	=> ,	-- unused, we need full and empty only.
		--FIFO32_M_Rem 	=> ,	-- unused, we need full and empty only.
		FIFO32_S_Full  	=> fifo_full_1, 
		FIFO32_M_Empty 	=> fifo_empty_1, 
		FIFO32_S_Rd    	=> fifo_read, 
		FIFO32_M_Wr    	=> fifo_write_1
	);



	-- processes

	-- do not check the header bytes.
	--
	-- header_bytes:	(initial state)
	--              	The current byte is a header byte.
	--              	Set check_me to '0'.
	-- data_bytes:  	The current byte is a data byte.
	--              	Set check_me to '1'.

	skipheader_memless : process(	skipheader_state, 
	                             	rx_sof, 
	                             	rx_eof, 
	                             	rx_data_valid, 
	                             	skipheader_count,
	                             	header_length)
	begin
		-- default: do nothing.
		skipheader_next_state	<=	skipheader_state;
		skipheader_next_count	<=	skipheader_count; 
		check_me             	<=	'0';

		if (rx_data_valid = '1') then
			case skipheader_state is

				when header_bytes =>
					-- wait for SOF (on first byte only):
					if (rx_sof = '1' or skipheader_count > 1) then
						skipheader_next_count	<=	skipheader_count + 1;
						if (skipheader_count >= header_length) then 
							skipheader_next_state	<=	data_bytes; 
						else
							skipheader_next_state	<=	header_bytes; 
						end if; 
					-- else: 
						-- do nothing and continue waiting for SOF.
					end if; 

				when data_bytes =>
					check_me	<=	'1';
					-- wait for EOF.
					if (rx_eof = '1') then
						-- special case: if header length is 0, we won't need to skip anything.
						if (header_length = 0) then
							skipheader_next_state	<=	data_bytes;
						else
							skipheader_next_state	<=	header_bytes;
							skipheader_next_count	<=	1; -- init counter
							-- TODO max. hier i
						end if; 
					end if; 

				-- when idle =>
				--	--skipheader_next_count	<=	header_length; -- start counter
				--	if rx_sof='1' then





				--		-- done: Implement special handling for header length 0 and 1.         	--
				--		---- oder einfach nochmals neu überlegen... Ich denke 2 states reichen.	--



				--		skipheader_next_state	<=	next_header_byte;
				--		-- start counter at byte 2.
				--		-- one byte, because we will miss the first data byte. It arrives at the same time when SOF arrives.
				--		-- the second byte because we start counting at 1, not on 0.
				--		skipheader_next_count	<=	2;
				--		-- the 
				--		--old: skipheader_count-1; -- iteration
				--	end if ;
				--	check_me	<=	'0';
			
				-- when next_header_byte =>
				--	skipheader_next_count	<=	skipheader_count+1; -- iteration
				--	check_me             	<=	'0';
				--	if (skipheader_count >= header_length) then -- stop criterion
				--		skipheader_next_state	<=	next_data_byte;
				--	elsif (rx_eof='1') then
				--		skipheader_next_state	<=	idle; 
				--	end if ;

				-- when next_data_byte =>
				--	if (rx_eof='1') then
				--		skipheader_next_state	<=	idle; 
				--	end if;
				--	skipheader_next_count	<=	skipheader_count; -- don't continue counting to prevent overflow.
				--	check_me             	<=	'1';
			
			end case ;
		else -- i.e. (rx_data_valid = '0')
			skipheader_next_state	<= skipheader_state; 
		end if;
	end process ; -- skipheader_memless


	skipheader_memzing : process( clk, rst )
	begin
	    if rst = RESET then
			skipheader_count  	<= 1; -- init counter
			--skipheader_state	<= idle;
			skipheader_state  	<= header_bytes; 
	    elsif rising_edge(clk) then
			skipheader_count	<= skipheader_next_count;
			skipheader_state	<= skipheader_next_state;
	    end if;
	end process ; -- skipheader_memzing




	-- aggregate all "Ready" signals. Note: if any of the fifos is full, we are not ready.
	-- TODO automatise all ..._n's.
	aggregate_ready_signals : process(	--ca_ready_n,	fifo_full_n,
	                                  	ca_ready_1,  	fifo_full_1)
	begin
		rx_packetinspection_ready	<=   	ca_ready_1	and	not fifo_full_1;
		                         	--and	ca_ready_n	and	not fifo_full_n usw.
	end process;


	-- aggregate all FIFO outputs, i.e. fifo empty and good/evil signals
	-- TODO automatise all ..._n's.
	aggregate_fifo_outputs : process(	--fifo_empty_n,	queued_result_n,
	                                 	fifo_empty_1,  	queued_result_1)
	begin
		-- if any of the FIFOs is empty, set empty signal to 1.
		fifo_empty	<=   	fifo_empty_1;
		          	-- or	fifo_empty_n usw.
		if (EVIL_DROP = '1') then
			-- if any result is set to '1', the result is evil. --> OR.
			tx_result	<=  	result_1; 
			         	--or	result_n usw.
		else -- i.e. EVIL_DROP = '0'
			-- if any result is set to '0', the result is evil. --> AND.
			tx_result	<=   	result_1; 
			         	--and	result_n usw.
		end if; 
	end process;



	-- TODO all the h2s logging stuff (i.e. wiring the resp. signals to.


end architecture;
