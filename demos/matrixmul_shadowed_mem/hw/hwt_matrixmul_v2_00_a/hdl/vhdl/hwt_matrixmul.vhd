------------------------------------------------------------------------------
-- hwt_matrixmul - entity/architecture pair
------------------------------------------------------------------------------
-- Filename:		hwt_matrixmul
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

entity hwt_matrixmul is
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
		
		-- HWT reset and clock
		clk           : in std_logic;
		rst           : in std_logic
	);
end hwt_matrixmul;

------------------------------------------------------------------------------
-- Architecture Section
------------------------------------------------------------------------------

architecture implementation of hwt_matrixmul is
	type STATE_TYPE is (
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
	
	-- const for matrix B
	constant C_LOCAL_RAM_SIZE_MATRIX_B					: integer	:= C_LINE_LEN_MATRIX*C_LINE_LEN_MATRIX;
	constant C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B			: integer	:= clog2(C_LOCAL_RAM_SIZE_MATRIX_B);
	constant C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_B		: integer	:= 4*C_LOCAL_RAM_SIZE_MATRIX_B;
	type LOCAL_MEMORY_TYPE_MATRIX_B		is array(0 to C_LOCAL_RAM_SIZE_MATRIX_B   - 1) of std_logic_vector(31 downto 0);
	
	-- communication with microblaze core
	constant C_MBOX_RECV	: std_logic_vector(C_FSL_WIDTH-1 downto 0)	:= x"00000000";
	constant C_MBOX_SEND	: std_logic_vector(C_FSL_WIDTH-1 downto 0)	:= x"00000001";
	signal ignore			: std_logic_vector(C_FSL_WIDTH-1 downto 0);
	
	-- maddr is an acronym for "matrix address" (address that points to a matrix)
	constant C_MADDRS		: integer	:= 3;
	type MADDR_BOX_TYPE is array(0 to C_MADDRS-1) of std_logic_vector(31 downto 0);
	-- container for adresses pointing to the first element of matrixes A, B and C
	signal maddrs			: MADDR_BOX_TYPE;
	-- points to pointers to the matrixes
	signal addr2maddrs	: std_logic_vector(31 downto 0);
	
	-- temporary signals
	signal temp_addr_A	: std_logic_vector(31 downto 0);
	signal temp_addr_C	: std_logic_vector(31 downto 0);
	
	-- fsm state
	signal state		: STATE_TYPE;
	
	-- additional data for memif interfaces
	signal len_data_MATRIX_A_C	: std_logic_vector(23 downto 0);
	signal len_data_MATRIX_B	: std_logic_vector(23 downto 0);
	
	-- osif, memif and different local BRAM interfaces
	signal i_osif			: i_osif_t;
	signal o_osif			: o_osif_t;
	signal i_memif			: i_memif_t;
	signal o_memif			: o_memif_t;
	
	signal i_ram_A			: i_ram_t;
	signal o_ram_A			: o_ram_t;
	
	signal i_ram_B			: i_ram_t;
	signal o_ram_B			: o_ram_t;
	
	signal i_ram_C			: i_ram_t;
	signal o_ram_C			: o_ram_t;
	
	signal o_RAM_A_Addr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
	signal o_RAM_A_Addr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAM_A_Data_reconos   : std_logic_vector(0 to 31);
	signal o_RAM_A_WE_reconos     : std_logic;
	signal i_RAM_A_Data_reconos   : std_logic_vector(0 to 31);
	
	signal o_RAM_B_Addr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B   - 1);
	signal o_RAM_B_Addr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAM_B_Data_reconos   : std_logic_vector(0 to 31);
	signal o_RAM_B_WE_reconos     : std_logic;
	signal i_RAM_B_Data_reconos   : std_logic_vector(0 to 31);
	
	signal o_RAM_C_Addr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
	signal o_RAM_C_Addr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAM_C_Data_reconos   : std_logic_vector(0 to 31);
	signal o_RAM_C_WE_reconos     : std_logic;
	signal i_RAM_C_Data_reconos   : std_logic_vector(0 to 31);
	
	signal o_RAM_A_Addr_mul	: std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
	signal i_RAM_A_Data_mul	: std_logic_vector(0 to 31);
	
	signal o_RAM_B_Addr_mul	: std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B   - 1);
	signal i_RAM_B_Data_mul	: std_logic_vector(0 to 31);
	
	signal o_RAM_C_Addr_mul	: std_logic_vector(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1);
	signal o_RAM_C_Data_mul	: std_logic_vector(0 to 31);
	signal o_RAM_C_WE_mul	: std_logic;
	
	shared variable local_ram_a		: LOCAL_MEMORY_TYPE_MATRIX_A_C;
	shared variable local_ram_b		: LOCAL_MEMORY_TYPE_MATRIX_B;
	shared variable local_ram_c		: LOCAL_MEMORY_TYPE_MATRIX_A_C;
	
	signal multiplier_start	: std_logic;
	signal multiplier_done	: std_logic;
	
begin
	
	-- local BRAM read and write access
	local_ram_ctrl_1 : process (clk) is
	begin
		if (clk'event and clk = '1') then
			if (o_RAM_A_WE_reconos = '1') then
				local_ram_A(conv_integer(unsigned(o_RAM_A_Addr_reconos))) := o_RAM_A_Data_reconos;
			end if;
			if (o_RAM_B_WE_reconos = '1') then
				local_ram_B(conv_integer(unsigned(o_RAM_B_Addr_reconos))) := o_RAM_B_Data_reconos;
			end if;
			if (o_RAM_C_WE_reconos = '0') then
				i_RAM_C_Data_reconos <= local_ram_C(conv_integer(unsigned(o_RAM_C_Addr_reconos)));
			end if;
		end if;
	end process;
	
	local_ram_ctrl_2 : process (clk) is
	begin
		if (rising_edge(clk)) then		
			if (o_RAM_C_WE_mul = '1') then
				local_ram_C(conv_integer(unsigned(o_RAM_C_Addr_mul))) := o_RAM_C_Data_mul;
			else
				i_RAM_A_Data_mul <= local_ram_A(conv_integer(unsigned(o_RAM_A_Addr_mul)));
				i_RAM_B_Data_mul <= local_ram_B(conv_integer(unsigned(o_RAM_B_Addr_mul)));
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
			start	=> multiplier_start,
			done	=> multiplier_done,
			
			o_RAM_A_Addr	=> o_RAM_A_Addr_mul,
			i_RAM_A_Data	=> i_RAM_A_Data_mul,
			
			o_RAM_B_Addr	=> o_RAM_B_Addr_mul,
			i_RAM_B_Data	=> i_RAM_B_Data_mul,
			
			o_RAM_C_Addr	=> o_RAM_C_Addr_mul,
			o_RAM_C_Data	=> o_RAM_C_Data_mul,
			o_RAM_C_WE		=> o_RAM_C_WE_mul
	);
	
	-- setup interfaces (FIFOs, FSL,...)
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
	
	ram_setup(
		i_ram_A,
		o_ram_A,
		o_RAM_A_Addr_reconos_2,
		o_RAM_A_Data_reconos,
		i_RAM_A_Data_reconos,
		o_RAM_A_WE_reconos
	);
	
	ram_setup(
		i_ram_B,
		o_ram_B,
		o_RAM_B_Addr_reconos_2,
		o_RAM_B_Data_reconos,
		i_RAM_B_Data_reconos,
		o_RAM_B_WE_reconos
	);
	
	ram_setup(
		i_ram_C,
		o_ram_C,
		o_RAM_C_Addr_reconos_2,
		o_RAM_C_Data_reconos,
		i_RAM_C_Data_reconos,
		o_RAM_C_WE_reconos
	);
	
	o_RAM_A_Addr_reconos(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1) <= o_RAM_A_Addr_reconos_2((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C) to 31);
	o_RAM_B_Addr_reconos(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B   - 1) <= o_RAM_B_Addr_reconos_2((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_B  ) to 31);
	o_RAM_C_Addr_reconos(0 to C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C - 1) <= o_RAM_C_Addr_reconos_2((32-C_LOCAL_RAM_ADDR_WIDTH_MATRIX_A_C) to 31);
	
	reconos_fsm	: process(clk, rst, o_osif, o_memif, o_ram_a, o_ram_b, o_ram_c) is
		variable done					: boolean;
		variable addr_pos				: integer;
		variable calculated_rows	: integer;
	begin
		if (rst = '1') then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram_A);
			ram_reset(o_ram_B);
			ram_reset(o_ram_C);
			
			multiplier_start	<= '0';
			done					:= false;
			
			calculated_rows	:= 0;
			
			len_data_MATRIX_A_C	<= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_A_C, 24);
			len_data_MATRIX_B		<= conv_std_logic_vector(C_LOCAL_RAM_SIZE_IN_BYTES_MATRIX_B  , 24);
			-- important to know:
			-- maddrs(0) = C, maddrs(1) = B, maddrs(2) = A
			addr2maddrs			<= (others => '0');
			addr_pos				:= C_MADDRS - 1;
			for i in 0 to (C_MADDRS - 1) loop
				maddrs(i)		<= (others => '0');
			end loop;
			
			temp_addr_A			<= (others => '0');
			temp_addr_C			<= (others => '0');
			
			state					<= STATE_GET_ADDR2MADDRS;
			
		elsif (clk'event and clk = '1') then
			case state is
				-- Get address pointing to the addresses pointing to the 3 matrixes via FSL.
				when STATE_GET_ADDR2MADDRS =>
					osif_mbox_get(i_osif, o_osif, C_MBOX_RECV, addr2maddrs, done);
					if (done) then
						if (addr2maddrs = x"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							addr2maddrs <= addr2maddrs(31 downto 2) & "00";
							addr_pos := C_MADDRS - 1;
							state <= STATE_READ_MADDRS;
						end if;
					end if;
				
				-- Read addresses pointing to input matrixes A, B and output matrix C from main memory.
				when STATE_READ_MADDRS =>
					memif_read_word(i_memif, o_memif, addr2maddrs, maddrs(addr_pos), done);
					if done then
						if (addr_pos = 0) then
							state <= STATE_READ_MATRIX_B;
						else
							addr_pos := addr_pos - 1;
							addr2maddrs <= conv_std_logic_vector(unsigned(addr2maddrs) + 4, 32);
						end if;
					end if;
				
				-- Read matrix B from main memory.
				when STATE_READ_MATRIX_B =>
					memif_read(i_ram_B, o_ram_B, i_memif, o_memif, maddrs(1), X"00000000", len_data_MATRIX_B, done);
					if done then
						temp_addr_A <= maddrs(2);
						temp_addr_C <= maddrs(0);
						state <= STATE_READ_MATRIX_ROW_FROM_A;
					end if;
				
				-- Read a row of matrix A.
				when STATE_READ_MATRIX_ROW_FROM_A =>
					memif_read(i_ram_A, o_ram_A, i_memif, o_memif, temp_addr_A, X"00000000", len_data_MATRIX_A_C, done);
					if done then
						multiplier_start <= '1';
						state <= STATE_MULTIPLY_MATRIX_ROW;
					end if;
				
				-- Multiply row of matrix A with matrix B.
				when STATE_MULTIPLY_MATRIX_ROW =>
					multiplier_start <= '0';
					if (multiplier_done = '1') then
						calculated_rows := calculated_rows + 1;
						state <= STATE_WRITE_MATRIX_ROW_TO_C;
					end if;
				
				-- Write multiplication result (row of matrix C) to main memory.
				when STATE_WRITE_MATRIX_ROW_TO_C =>
					memif_write(i_ram_C, o_ram_C, i_memif, o_memif, X"00000000", temp_addr_C, len_data_MATRIX_A_C, done);
					if (done) then
						if (calculated_rows < C_LINE_LEN_MATRIX) then
							-- Calculate new temporary addresses
							-- => to fetch next matrix row of matrix A
							-- => to store calculated values to next matrix row of matrix C
							temp_addr_A <= conv_std_logic_vector(unsigned(temp_addr_A) + C_LINE_LEN_MATRIX*4, 32);
							temp_addr_C <= conv_std_logic_vector(unsigned(temp_addr_C) + C_LINE_LEN_MATRIX*4, 32);
							state <= STATE_READ_MATRIX_ROW_FROM_A;
						else
							state <= STATE_ACK;
						end if;
					end if;
				
				-- We finished calculating matrix multiplication A * B = C.
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, C_MBOX_SEND, maddrs(addr_pos), ignore, done);
					if (done) then
						calculated_rows	:= 0;
						addr_pos				:= C_MADDRS - 1;
						temp_addr_A			<= (others => '0');
						temp_addr_C			<= (others => '0');
						state					<= STATE_GET_ADDR2MADDRS;
					end if;
				
				-- Terminate hardware thread.
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif, o_osif);
			end case;
		end if;
	end process;
	
end architecture implementation;
