library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v3_00_a;
--use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32 is
	generic (	-- Note: These default values were chosen to ensure backwards compatibility with the older version of the fifo32 entity (before June 2013). 
	         	-- Do not change them unless you know what this implies for code which relies on the older version.
	         	C_FIFO32_WORD_WIDTH         	:	integer	:= 32;  	-- width of data words
	         	C_FIFO32_DEPTH              	:	integer	:= 16;  	-- depth (# elements) of the FIFO
	         	CLOG2_FIFO32_DEPTH          	:	integer	:= 4;   	-- ceil(log2(depth)), i.e. #bits needed to represent the fill and remainer
	         	C_FIFO32_CONTROLSIGNAL_WIDTH	:	integer	:= 16;  	-- width of "Fill" and "Rem" control signals. Must be > CLOG2...DEPTH
	         	C_FIFO32_SAFE_READ_WRITE    	:	boolean	:= false	-- if enabled, the FIFO automatically prevents reading from it, if it is empty resp. writing if it is full. 
	);
	port (
		Rst         	:	in	std_logic;
		-- ..._M_...	=	input of the FIFO.
		-- ..._S_...	=	output of the FIFO.
		-- Clock and data signals. Different Clocks are possible for input and output. 
		FIFO32_S_Clk 	:	in 	std_logic;
		FIFO32_M_Clk 	:	in 	std_logic;
		FIFO32_S_Data	:	out	std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);
		FIFO32_M_Data	:	in 	std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);
		-- # data elements in the FIFO. 0 means the FIFO is empty, i.e. the FIFO32_M_Empty signal will be set to '1'. 
		-- Alike for the remaining free space / FIFO32_S_Full signal. 
		FIFO32_S_Fill 	:	out	std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);
		FIFO32_M_Rem  	:	out	std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 downto 0);
		FIFO32_S_Full 	:	out	std_logic;
		FIFO32_M_Empty	:	out	std_logic;
		-- read enable resp. write enable signal
		FIFO32_S_Rd	:	in	std_logic;
		FIFO32_M_Wr	:	in	std_logic
	);
end entity;

architecture implementation of fifo32 is
	type  	MEM_T     	is array (0 to C_FIFO32_DEPTH-1) of std_logic_vector(C_FIFO32_WORD_WIDTH-1 downto 0);
	signal	mem       	: MEM_T;
	signal	wrptr     	: std_logic_vector(CLOG2_FIFO32_DEPTH-1 downto 0);
	signal	rdptr     	: std_logic_vector(CLOG2_FIFO32_DEPTH-1 downto 0);
	signal	remainder 	: std_logic_vector(CLOG2_FIFO32_DEPTH-1 downto 0);
	signal	fill      	: std_logic_vector(CLOG2_FIFO32_DEPTH-1 downto 0);
	signal	full      	: std_logic;
	signal	empty     	: std_logic;
	signal	pad       	: std_logic_vector(C_FIFO32_CONTROLSIGNAL_WIDTH-1 - CLOG2_FIFO32_DEPTH downto 0);
	signal	safe_read 	: std_logic; 
	signal	safe_write	: std_logic; 

begin
	pad <= (others => '0');

	FIFO32_S_Fill <= pad & fill; 
	FIFO32_M_Rem  <= pad & remainder; 
	FIFO32_S_Data <= mem(CONV_INTEGER(rdptr));
	
	fill          	<= wrptr - rdptr	when wrptr >= rdptr               	else (C_FIFO32_DEPTH + wrptr) - rdptr;
	remainder     	<=              	                                  	(C_FIFO32_DEPTH - 1) - fill;
	full          	<= '1'          	when remainder = (fill'range=>'0')	else '0';
	empty         	<= '1'          	when fill = (fill'range=>'0')     	else '0';
	FIFO32_S_Full 	<= full;
	FIFO32_M_Empty	<= empty;

	-- If enabled, the FIFO prevents an overflow when writing data into the full fifo (analogue for the empty FIFO).
	-- you can enable or disable this feature by setting the "C_FIFO32_SAFE_READ_WRITE" gereric.
	safe_read_write : process(FIFO32_S_Rd, FIFO32_M_Wr, empty, full)
	begin
		if C_FIFO32_SAFE_READ_WRITE = true then
			safe_read 	<= FIFO32_S_Rd and (not empty);
			safe_write	<= FIFO32_M_Wr and (not full);
		else
			safe_read 	<= FIFO32_S_Rd;
			safe_write	<= FIFO32_M_Wr;
		end if;
	end process;

	write_to_fifo : process(FIFO32_M_Clk, Rst)
	begin
		if Rst = '1' then
			wrptr <= (others => '0');
		elsif rising_edge(FIFO32_M_Clk) then
			if safe_write = '1' then
				mem(CONV_INTEGER(wrptr)) <= FIFO32_M_Data;
				if wrptr = C_FIFO32_DEPTH-1 then
					wrptr <= (others => '0');
				else
					wrptr <= wrptr + 1;
				end if;
			end if;
		end if;
	end process;

	read_from_fifo : process(FIFO32_S_Clk, Rst)
	begin
		if Rst = '1' then
			rdptr <= (others => '0');
		elsif rising_edge(FIFO32_S_Clk) then
			if safe_read = '1' then
				if rdptr = C_FIFO32_DEPTH-1 then
					rdptr <= (others => '0');
				else
					rdptr <= rdptr + 1;
				end if;
			end if;
		end if;
	end process;

end architecture;
