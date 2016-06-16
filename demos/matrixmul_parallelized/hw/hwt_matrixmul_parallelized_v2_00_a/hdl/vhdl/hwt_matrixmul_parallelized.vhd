------------------------------------------------------------------------------
-- hwt_matrixmul_parallelized - entity/architecture pair
------------------------------------------------------------------------------
-- Filename:		hwt_matrixmul_parallelized
-- Version:			2.00.a
-- Description:	ReconOS matrix multiplier hardware thread (VHDL).
-- Date:				Wed June 7 16:32:00 2013
-- VHDL Standard:	VHDL'93
-- Author:			Achim Loesch
------------------------------------------------------------------------------
-- Feel free to modify this file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

------------------------------------------------------------------------------
-- Entity Section
------------------------------------------------------------------------------

entity hwt_matrixmul_parallelized is
	generic (
		C_ENGINE_CNT: integer := 4
	);
	port (
		-- OSIF FSL
		
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
    -- Debug
    debug : out std_logic_vector(127 downto 0);
    
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);
end hwt_matrixmul_parallelized;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture implementation of hwt_matrixmul_parallelized is
	type STATE_TYPE is (
		STATE_GET_MCOUNT,
		STATE_GET_ADDR2MADDRS,
		STATE_READ_MADDRS,
		STATE_READ_MATRIX_B,
		STATE_READ_MATRIX_ROW_FROM_A,
		STATE_MULTIPLY_MATRIX_ROW,
		STATE_WRITE_MATRIX_ROW_TO_C,
		STATE_ACK,
		STATE_THREAD_EXIT
	);
	
	component matrixmultiplier is
		generic(
			G_LINE_LEN_MATRIX					: integer	:= 128;
			G_RAM_DATA_WIDTH					: integer	:= 32;
			
			G_RAM_SIZE_MATRIX_A_C			: integer	:= 128;
			G_RAM_ADDR_WIDTH_MATRIX_A_C	: integer	:= 7;
			
			G_RAM_SIZE_MATRIX_B				: integer	:= 16384;
			G_RAM_ADDR_WIDTH_MATRIX_B		: integer	:= 14
		);
		port(
			clk	: in std_logic;
			reset	: in std_logic;
			start	: in std_logic;
			done	: out std_logic;
			
			o_RAM_A_Addr	: out std_logic_vector(0 to G_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
			i_RAM_A_Data	: in std_logic_vector(0 to G_RAM_DATA_WIDTH - 1);
			
			o_RAM_B_Addr	: out std_logic_vector(0 to G_RAM_ADDR_WIDTH_MATRIX_B - 1);
			i_RAM_B_Data	: in std_logic_vector(0 to G_RAM_DATA_WIDTH - 1);
			
			o_RAM_C_Addr	: out std_logic_vector(0 to G_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
			o_RAM_C_Data	: out std_logic_vector(0 to G_RAM_DATA_WIDTH - 1);
			o_RAM_C_WE		: out std_logic
		);
	end component;
	
	constant C_LINE_LEN_MATRIX								: integer	:= 128;
	-- Use the following line for testing purposes.
	--constant C_LINE_LEN_MATRIX								: integer	:= 32;
	
	-- const for matrixes A and C
	constant C_LOCAL_RAM_SIZE_MATRIX_A_C				: integer	:= C_LINE_LEN_MATRIX;
	constant C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C		: integer	:= clog2(C_LOCAL_RAM_SIZE_MATRIX_A_C);
	constant C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_A_C	: integer	:= 4*C_LOCAL_RAM_SIZE_MATRIX_A_C;
	type LOCAL_MEMORY_TYPE_MATRIX_A_C	is array(0 to C_LOCAL_RAM_SIZE_MATRIX_A_C - 1) of std_logic_vector(31 downto 0);
	type LOCAL_MEMORY_TYPE_MATRIX_A_C_VECTOR	is array(0 to C_ENGINE_CNT - 1) of LOCAL_MEMORY_TYPE_MATRIX_A_C;
	
	-- const for matrix B
	constant C_LOCAL_RAM_SIZE_MATRIX_B					: integer	:= C_LINE_LEN_MATRIX*C_LINE_LEN_MATRIX;
	constant C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B			: integer	:= clog2(C_LOCAL_RAM_SIZE_MATRIX_B);
	constant C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_B		: integer	:= 4*C_LOCAL_RAM_SIZE_MATRIX_B;
	type LOCAL_MEMORY_TYPE_MATRIX_B		is array(0 to C_LOCAL_RAM_SIZE_MATRIX_B   - 1) of std_logic_vector(31 downto 0);
	type LOCAL_MEMORY_TYPE_MATRIX_B_VECTOR		is array(0 to C_ENGINE_CNT - 1) of LOCAL_MEMORY_TYPE_MATRIX_B;
	
	-- communication with microblaze core
	constant C_MBOX_RECV	: std_logic_vector(C_FSL_WIDTH-1 downto 0)	:= x"00000000";
	constant C_MBOX_SEND	: std_logic_vector(C_FSL_WIDTH-1 downto 0)	:= x"00000001";
	signal ignore			: std_logic_vector(C_FSL_WIDTH-1 downto 0);
	
	-- maddr is an acronym for "matrix address" (address that points to a matrix)
	constant C_MADDRS		: integer	:= 3;
	type MADDR_BOX_TYPE is array(0 to C_MADDRS-1) of std_logic_vector(31 downto 0);
	type MADDR_BOX_TYPE_VECTOR is array(0 to C_ENGINE_CNT-1) of MADDR_BOX_TYPE;
	-- container for adresses pointing to the first element of matrixes A, B and C
	signal maddrs			: MADDR_BOX_TYPE_VECTOR;
	-- points to pointers to the matrixes
	type ADDR_TYPE_VECTOR is array(0 to C_ENGINE_CNT-1) of std_logic_vector(31 downto 0);
	signal addr2maddrs	: ADDR_TYPE_VECTOR;
	
	-- stores the number of matrices to sort 
	signal mcount : std_logic_vector(31 downto 0);
	
	-- temporary signals
	signal temp_addr_A	: ADDR_TYPE_VECTOR;
	signal temp_addr_C	: ADDR_TYPE_VECTOR;
	
	-- fsm state
	signal state		: STATE_TYPE;
	
	-- additional data for memif interfaces
	type LEN_TYPE_VECTOR is array (0 to C_ENGINE_CNT-1) of std_logic_vector(23 downto 0);
	signal len_data_MATRIX_A_C	: LEN_TYPE_VECTOR;
	signal len_data_MATRIX_B	: LEN_TYPE_VECTOR;
	
	-- osif, memif and different local BRAM interfaces
	signal i_osif			: i_osif_t;
	signal o_osif			: o_osif_t;
	signal i_memif			: i_memif_t;
	signal o_memif			: o_memif_t;
	
	type i_ram_t_vector is array (0 to C_ENGINE_CNT-1) of i_ram_t;
	type o_ram_t_vector is array (0 to C_ENGINE_CNT-1) of o_ram_t;
	
	signal i_ram_A			: i_ram_t_vector;
	signal o_ram_A			: o_ram_t_vector;
	
	signal i_ram_B			: i_ram_t_vector;
	signal o_ram_B			: o_ram_t_vector;
	
	signal i_ram_C			: i_ram_t_vector;
	signal o_ram_C			: o_ram_t_vector;
	
	-- Internal RAMs for data storage
	type RAM_A_C_ADDR_TYPE_VECTOR is array (0 to C_ENGINE_CNT-1) of std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
	type RAM_B_ADDR_TYPE_VECTOR   is array (0 to C_ENGINE_CNT-1) of std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B - 1);
	type RAM_ADDR2_TYPE_VECTOR    is array (0 to C_ENGINE_CNT-1) of std_logic_vector(0 to 31);
	type RAM_DATA_TYPE_VECTOR     is array (0 to C_ENGINE_CNT-1) of std_logic_vector(0 to 31);
	type RAM_WE_TYPE_VECTOR       is array (0 to C_ENGINE_CNT-1) of std_logic;
	
	signal o_RAM_A_Addr_reconos   : RAM_A_C_ADDR_TYPE_VECTOR;
	signal o_RAM_A_Addr_reconos_2 : RAM_ADDR2_TYPE_VECTOR;
	signal o_RAM_A_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	signal o_RAM_A_WE_reconos     : RAM_WE_TYPE_VECTOR;
	signal i_RAM_A_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	
	signal o_RAM_B_Addr_reconos   : RAM_B_ADDR_TYPE_VECTOR;
	signal o_RAM_B_Addr_reconos_2 : RAM_ADDR2_TYPE_VECTOR;
	signal o_RAM_B_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	signal o_RAM_B_WE_reconos     : RAM_WE_TYPE_VECTOR;
	signal i_RAM_B_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	
	signal o_RAM_C_Addr_reconos   : RAM_A_C_ADDR_TYPE_VECTOR;
	signal o_RAM_C_Addr_reconos_2 : RAM_ADDR2_TYPE_VECTOR;
	signal o_RAM_C_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	signal o_RAM_C_WE_reconos     : RAM_WE_TYPE_VECTOR;
	signal i_RAM_C_Data_reconos   : RAM_DATA_TYPE_VECTOR;
	
	signal o_RAM_A_Addr_mul	: RAM_A_C_ADDR_TYPE_VECTOR;
	signal i_RAM_A_Data_mul	: RAM_DATA_TYPE_VECTOR;
	
	signal o_RAM_B_Addr_mul	: RAM_B_ADDR_TYPE_VECTOR;
	signal i_RAM_B_Data_mul	: RAM_DATA_TYPE_VECTOR;
	
	signal o_RAM_C_Addr_mul	: RAM_A_C_ADDR_TYPE_VECTOR;
	signal o_RAM_C_Data_mul	: RAM_DATA_TYPE_VECTOR;
	signal o_RAM_C_WE_mul	: RAM_WE_TYPE_VECTOR;
	
	shared variable local_ram_a		: LOCAL_MEMORY_TYPE_MATRIX_A_C_VECTOR;
	shared variable local_ram_b		: LOCAL_MEMORY_TYPE_MATRIX_B_VECTOR;
	shared variable local_ram_c		: LOCAL_MEMORY_TYPE_MATRIX_A_C_VECTOR;
	
	type MULTIPLIER_CTRL_VECTOR is array (0 to C_ENGINE_CNT-1) of std_logic;
	signal multiplier_start	: MULTIPLIER_CTRL_VECTOR;
	signal multiplier_done	: MULTIPLIER_CTRL_VECTOR;
	
begin
	
	my_little_rams: for i in 0 to C_ENGINE_CNT-1 generate
		-- local BRAM read and write access
		local_ram_ctrl_1 : process (clk) is
		begin
			if (clk'event and clk = '1') then
				if (o_RAM_A_WE_reconos(i) = '1') then
					local_ram_A(i)(conv_integer(unsigned(o_RAM_A_Addr_reconos(i)))) := o_RAM_A_Data_reconos(i);
				end if;
				if (o_RAM_B_WE_reconos(i) = '1') then
					local_ram_B(i)(conv_integer(unsigned(o_RAM_B_Addr_reconos(i)))) := o_RAM_B_Data_reconos(i);
				end if;
				if (o_RAM_C_WE_reconos(i) = '0') then
					i_RAM_C_Data_reconos(i) <= local_ram_C(i)(conv_integer(unsigned(o_RAM_C_Addr_reconos(i))));
				end if;
			end if;
		end process;
		
		local_ram_ctrl_2 : process (clk) is
		begin
			if (rising_edge(clk)) then		
				if (o_RAM_C_WE_mul(i) = '1') then
					local_ram_C(i)(conv_integer(unsigned(o_RAM_C_Addr_mul(i)))) := o_RAM_C_Data_mul(i);
				else
					i_RAM_A_Data_mul(i) <= local_ram_A(i)(conv_integer(unsigned(o_RAM_A_Addr_mul(i))));
					i_RAM_B_Data_mul(i) <= local_ram_B(i)(conv_integer(unsigned(o_RAM_B_Addr_mul(i))));
				end if;
			end if;
		end process;
		
		-- the matrix multiplication module
		matrixmultiplier_i : matrixmultiplier
			generic map(
				G_LINE_LEN_MATRIX					=> C_LINE_LEN_MATRIX,
				G_RAM_DATA_WIDTH					=> 32,
				
				G_RAM_SIZE_MATRIX_A_C			=> C_LOCAL_RAM_SIZE_MATRIX_A_C,
				G_RAM_ADDR_WIDTH_MATRIX_A_C	=> C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C,
				
				G_RAM_SIZE_MATRIX_B				=> C_LOCAL_RAM_SIZE_MATRIX_B,
				G_RAM_ADDR_WIDTH_MATRIX_B		=> C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B
			)
			port map(
				clk	=> clk,
				reset	=> rst,
				start	=> multiplier_start(i),
				done	=> multiplier_done(i),
				
				o_RAM_A_Addr	=> o_RAM_A_Addr_mul(i),
				i_RAM_A_Data	=> i_RAM_A_Data_mul(i),
				
				o_RAM_B_Addr	=> o_RAM_B_Addr_mul(i),
				i_RAM_B_Data	=> i_RAM_B_Data_mul(i),
				
				o_RAM_C_Addr	=> o_RAM_C_Addr_mul(i),
				o_RAM_C_Data	=> o_RAM_C_Data_mul(i),
				o_RAM_C_WE		=> o_RAM_C_WE_mul(i)
		);

		-- setup interfaces (FIFOs, FSL,...)
		ram_setup(
			i_ram_A(i),
			o_ram_A(i),
			o_RAM_A_Addr_reconos_2(i),
			o_RAM_A_Data_reconos(i),
			i_RAM_A_Data_reconos(i),
			o_RAM_A_WE_reconos(i)
		);
		
		ram_setup(
			i_ram_B(i),
			o_ram_B(i),
			o_RAM_B_Addr_reconos_2(i),
			o_RAM_B_Data_reconos(i),
			i_RAM_B_Data_reconos(i),
			o_RAM_B_WE_reconos(i)
		);
		
		ram_setup(
			i_ram_C(i),
			o_ram_C(i),
			o_RAM_C_Addr_reconos_2(i),
			o_RAM_C_Data_reconos(i),
			i_RAM_C_Data_reconos(i),
			o_RAM_C_WE_reconos(i)
		);
		
		o_RAM_A_Addr_reconos(i)(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1) <= o_RAM_A_Addr_reconos_2(i)((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C) to 31);
		o_RAM_B_Addr_reconos(i)(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B   - 1) <= o_RAM_B_Addr_reconos_2(i)((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B  ) to 31);
		o_RAM_C_Addr_reconos(i)(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1) <= o_RAM_C_Addr_reconos_2(i)((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C) to 31);
	end generate;
	
	fsl_setup(
		i_osif,
		o_osif,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
	
	
	memif_setup(
		i_memif,
		o_memif,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
			
  debug(3 downto 0) <= X"0" when state = STATE_GET_MCOUNT else
                   X"1" when state = STATE_GET_ADDR2MADDRS else
		               X"2" when state = STATE_READ_MADDRS else
		               X"3" when state = STATE_READ_MATRIX_B else
		               X"4" when state = STATE_READ_MATRIX_ROW_FROM_A else
		               X"5" when state = STATE_MULTIPLY_MATRIX_ROW else
		               X"6" when state = STATE_WRITE_MATRIX_ROW_TO_C else
		               X"7" when state = STATE_ACK else
		               X"8" when state = STATE_THREAD_EXIT else
                   X"F";
                   
  -- this code expects C_ENGINE_CNT to be at most 5.
  multipliers: for i in 0 to C_ENGINE_CNT-1 generate 
    debug( 4+i) <= multiplier_start(0+i);
    debug(10+i) <= multiplier_done(0+i);
  end generate;
  Nulls: for i in C_ENGINE_CNT to 5 generate 
    debug( 4+i) <= '0';
    debug(10+i) <= '0';
  end generate;
  
  -- In process reconos_fsm:
  --debug(47 downto 16)<= conv_std_logic_vector(calculated_rows, 32);
  --debug(79 downto 48)<= conv_std_logic_vector(mcurrent, 32);
  --if done then debug(80 ) <= '1';
  --    else debug(80 ) <= '0';
  
  debug(96 downto 81) <= FIFO32_S_Fill;-- : in std_logic_vector(15 downto 0);
	debug(112 downto 97) <= FIFO32_M_Rem;-- : in std_logic_vector(15 downto 0);
	debug(113) <= o_memif.s_rd;-- : out std_logic;
	debug(114) <= o_memif.m_wr;-- : out std_logic;
  
  
  debug(127 downto 115) <= (others => '0');
  
  
	reconos_fsm	: process(clk, rst, o_osif, o_memif, o_ram_a, o_ram_b, o_ram_c) is
		type integer_vector is array (0 to C_ENGINE_CNT-1) of integer;
		variable done					: boolean;
		variable addr_pos				: integer_vector;
		variable calculated_rows	: integer;
		variable mcurrent			:integer;
	begin
		if (rst = '1') then
			osif_reset(o_osif);
			memif_reset(o_memif);
			
			for i in 0 to C_ENGINE_CNT-1 loop
				ram_reset(o_ram_A(i));
				ram_reset(o_ram_B(i));
				ram_reset(o_ram_C(i));
				
				len_data_MATRIX_A_C(i)	<= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_A_C, 24);
				len_data_MATRIX_B(i)	<= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_B  , 24);
				-- important to know:
				-- maddrs(0) = C, maddrs(1) = B, maddrs(2) = A
				addr2maddrs(i)			<= (others => '0');
				addr_pos(i)				:= C_MADDRS - 1;
				for j in 0 to (C_MADDRS - 1) loop
					maddrs(i)(j)		<= (others => '0');
				end loop;
				
				temp_addr_A(i)			<= (others => '0');
				temp_addr_C(i)			<= (others => '0');
			end loop;
			
			multiplier_start	<= (others =>'0');
			done					:= false;
			
			calculated_rows	:= 0;
			mcount <= (others =>'0');
			mcurrent := 0;
			state					<= STATE_GET_MCOUNT;
			
		elsif (clk'event and clk = '1') then
        
      debug(47 downto 16)<= conv_std_logic_vector(calculated_rows, 32);
      debug(79 downto 48)<= conv_std_logic_vector(mcurrent, 32);
      if done then debug(80 ) <= '1';
      else debug(80 ) <= '0';
      end if;
    
			case state is
				-- get number of matrices we shall sort in parallel
				when STATE_GET_MCOUNT =>
					osif_mbox_get(i_osif, o_osif, C_MBOX_RECV, mcount, done);
					if done then
						mcurrent := conv_integer( unsigned(mcount) ) -1;
						state <= STATE_GET_ADDR2MADDRS;
					end if;
				-- Get address pointing to the addresses pointing to the 3 matrixes via FSL.
				when STATE_GET_ADDR2MADDRS =>
					osif_mbox_get(i_osif, o_osif, C_MBOX_RECV, addr2maddrs(mcurrent), done);
					if (done) then
						if (addr2maddrs(mcurrent) = x"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else							
							addr2maddrs(mcurrent) <= addr2maddrs(mcurrent)(31 downto 2) & "00";
							addr_pos(mcurrent) := C_MADDRS - 1;
							
							mcurrent := mcurrent -1 ;
							if mcurrent = -1 then
								mcurrent := conv_integer(unsigned(mcount))-1;
								state <= STATE_READ_MADDRS;
							end if;
						end if;
					end if;
				
				-- Read addresses pointing to input matrixes A, B and output matrix C from main memory.
				when STATE_READ_MADDRS =>
					memif_read_word(i_memif, o_memif, addr2maddrs(mcurrent), maddrs(mcurrent)(addr_pos(mcurrent)), done);
					if done then
						if (addr_pos(mcurrent) = 0) then
							addr_pos(mcurrent) := C_MADDRS - 1;
							mcurrent := mcurrent -1;
							if mcurrent = -1 then
								mcurrent := conv_integer(unsigned(mcount))-1;
								state <= STATE_READ_MATRIX_B;
							end if;
						else
							addr_pos(mcurrent) := addr_pos(mcurrent) - 1;
							addr2maddrs(mcurrent) <= conv_std_logic_vector(unsigned(addr2maddrs(mcurrent)) + 4, 32);
						end if;
					end if;
				
				-- Read matrix B from main memory.
				when STATE_READ_MATRIX_B =>
					memif_read(i_ram_B(mcurrent), o_ram_B(mcurrent), i_memif, o_memif, maddrs(mcurrent)(1), X"00000000", len_data_MATRIX_B(mcurrent), done);
					if done then
						temp_addr_A(mcurrent) <= maddrs(mcurrent)(2);
						temp_addr_C(mcurrent) <= maddrs(mcurrent)(0);
						mcurrent := mcurrent -1;
						if mcurrent = -1 then
							mcurrent := conv_integer(unsigned(mcount))-1;
							state <= STATE_READ_MATRIX_ROW_FROM_A;
						end if;
					end if;
				
				-- Read a row of matrix A.
				when STATE_READ_MATRIX_ROW_FROM_A =>
					memif_read(i_ram_a(mcurrent), o_ram_A(mcurrent), i_memif, o_memif, temp_addr_A(mcurrent), X"00000000", len_data_MATRIX_A_C(mcurrent), done);
					multiplier_start <= (others => '0');
          if done then
						multiplier_start(mcurrent) <= '1'; -- activates start signal for one clock cycle
						mcurrent := mcurrent -1;
						if mcurrent = -1 then 
							mcurrent := conv_integer(unsigned(mcount))-1;
							state <= STATE_MULTIPLY_MATRIX_ROW;
						end if;
					end if;
				
				-- Multiply row of matrix A with matrix B.
				when STATE_MULTIPLY_MATRIX_ROW =>
					multiplier_start <= (others => '0');
          
          -- The following code assumes that the multiplier_done signal is '1' for only one clock cycle
          -- and that no two elements of the vector are at the same time '1'.
          -- This is achieved in the STATE_READ_MATRIX_ROW_FROM_A state by activating one matrix multiplication
          -- one after the other ... 
          if multiplier_done /= (others => '0') then 
             mcurrent := mcurrent -1;
          end if ;
          if ( mcurrent = -1 ) then
						calculated_rows := calculated_rows + 1;
            mcurrent := conv_integer(unsigned(mcount))-1;
						state <= STATE_WRITE_MATRIX_ROW_TO_C;
					end if;
				
				-- Write multiplication result (row of matrix C) to main memory.
				when STATE_WRITE_MATRIX_ROW_TO_C =>
					memif_write(i_ram_C(mcurrent), o_ram_C(mcurrent), i_memif, o_memif, X"00000000", temp_addr_C(mcurrent), len_data_MATRIX_A_C(mcurrent), done);
					if (done) then						
						if (calculated_rows < C_LINE_LEN_MATRIX) then
							-- Calculate new temporary addresses
							-- => to fetch next matrix row of matrix A
							-- => to store calculated values to next matrix row of matrix C
							temp_addr_A(mcurrent) <= conv_std_logic_vector(unsigned(temp_addr_A(mcurrent)) + C_LINE_LEN_MATRIX*4, 32);
							temp_addr_C(mcurrent) <= conv_std_logic_vector(unsigned(temp_addr_C(mcurrent)) + C_LINE_LEN_MATRIX*4, 32);
							mcurrent := mcurrent -1 ;
							if mcurrent = -1 then
								mcurrent := conv_integer(unsigned(mcount))-1;
								state <= STATE_READ_MATRIX_ROW_FROM_A;
							end if;
						else
              mcurrent := mcurrent -1 ;
							if mcurrent = -1 then
								mcurrent := conv_integer(unsigned(mcount))-1;
								state <= STATE_ACK;
							end if;
						end if;
					end if;
				
				-- We finished calculating matrix multiplication A * B = C.
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, C_MBOX_SEND, maddrs(mcurrent)(addr_pos(mcurrent)), ignore, done);
					if (done) then
						calculated_rows	:= 0;
						addr_pos(mcurrent)				:= C_MADDRS - 1;
						temp_addr_A			<= (others =>(others => '0'));
						temp_addr_C			<= (others =>(others => '0'));
						mcurrent := mcurrent -1 ;
						if mcurrent = -1 then
							state					<= STATE_GET_MCOUNT;
						end if;
					end if;
				
				-- Terminate hardware thread.
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif, o_osif);
			end case;
		end if;
	end process;
	
end architecture implementation;
