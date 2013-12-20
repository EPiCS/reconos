--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        IP-Core - OSIF FIFO - FIFO implementation
--
--   project:      ReconOS
--   author:       Christoph Rüthing, University of Paderborn
--   description:  The burst converter splits burst transfers into smaller
--                 requests which do not go over a page border. This is
--                 needed because the MMU does not deal with this problem.
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity reconos_memif_burst_converter is
	generic (
		C_CTRL_FIFO_WIDTH    : integer := 32;
		
		C_MEMIF_LENGTH_WIDTH : integer := 24;
		
		-- page size in bytes
		C_PAGE_SIZE          : integer := 4096;
		-- maximal possible burst size supported
		-- by the memory-bus in bytes
		-- this MUST be smaller or equal than the page size
		C_MAX_BURST_SIZE     : integer := 1024
	);
	port (
		-- Input FIFO ports from the transaction control
		CTRL_FIFO_In_Data    : in  std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
		CTRL_FIFO_In_Fill    : in  std_logic_vector(15 downto 0);
		CTRL_FIFO_In_Empty   : in  std_logic;
		CTRL_FIFO_In_RE      : out std_logic;
		
		-- Output FIFO ports to the MMU
		CTRL_FIFO_Out_Data    : out std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
		CTRL_FIFO_Out_Fill    : out std_logic_vector(15 downto 0);
		CTRL_FIFO_Out_Empty   : out std_logic;
		CTRL_FIFO_Out_RE      : in  std_logic;
 
		-- Burst converter ports
		BCONV_Clk : in std_logic;
		BCONV_Rst : in std_logic
	);
	
	attribute SIGIS   : string;

	attribute SIGIS of BCONV_Clk   : signal is "Clk";
	attribute SIGIS of BCONV_Rst   : signal is "Rst";

end entity reconos_memif_burst_converter;

architecture implementation of reconos_memif_burst_converter is

	constant C_PAGE_OFFSET_WIDTH  : integer := clog2(C_PAGE_SIZE);

	signal ctrl_in_re      : std_logic;

	signal ctrl_out_data    : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
	signal ctrl_out_fill    : std_logic_vector(15 downto 0);
	signal ctrl_out_empty   : std_logic;

	-- Burst converter signals
	type STATE_TYPE is (WAIT_REQUEST, READ_CMD, READ_ADDR, CALC_CHUNK, WRITE_CMD, WRITE_ADDR);
	signal state : STATE_TYPE;
	
	-- these signals contain the received request data unchanged
	signal ctrl_cmd      : std_logic_vector(C_CTRL_FIFO_WIDTH - C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	signal ctrl_length   : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	signal ctrl_addr     : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);

	signal clk : std_logic;
	signal rst : std_logic;
	
	-- calculates remaining bytes to page border
	function calc_bytes_rem_page (
		start_addr : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0)
	) return std_logic_vector is
		variable page_offset    : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	begin
		page_offset := (others => '0');
		page_offset(C_PAGE_OFFSET_WIDTH - 1 downto 0) := start_addr(C_PAGE_OFFSET_WIDTH - 1 downto 0);
		
		return C_PAGE_SIZE - page_offset;
	end function calc_bytes_rem_page;
	
	-- calculates the size of the chunk from start_addr to max_end_addr
	function calc_chunk_length (
		start_addr     : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
		bytes_rem      : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		bytes_rem_page : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0)
	) return std_logic_vector is
		variable length_byte    : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	begin
		length_byte := bytes_rem_page;

		if bytes_rem < length_byte then
			length_byte := bytes_rem;
		end if;

		if C_MAX_BURST_SIZE < length_byte then
			length_byte := CONV_STD_LOGIC_VECTOR(C_MAX_BURST_SIZE, C_MEMIF_LENGTH_WIDTH);
		end if;

		return length_byte;
	end function calc_chunk_length;

begin

	clk <= BCONV_Clk;
	rst <= BCONV_Rst;

	CTRL_FIFO_In_RE <= ctrl_in_re;

	CTRL_FIFO_Out_Data  <= ctrl_out_data;
	CTRL_FIFO_Out_Fill  <= ctrl_out_fill;
	CTRL_FIFO_Out_Empty <= ctrl_out_empty;


	burst_converter_proc : process(clk,rst) is
		variable bconv_cmd            : std_logic_vector(C_CTRL_FIFO_WIDTH - C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable bconv_length         : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable bconv_addr           : std_logic_vector(C_CTRL_FIFO_WIDTH - 1 downto 0);
		variable bconv_bytes_rem      : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable bconv_bytes_rem_page : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
	begin
		if rst = '1' then
			state <= WAIT_REQUEST;

			ctrl_cmd    <= (others => '0');
			ctrl_length <= (others => '0');
			ctrl_addr   <= (others => '0');

			ctrl_out_empty <= '1';
			ctrl_out_fill  <= (others => '0');
			ctrl_out_data  <= (others => '0');
			
			ctrl_in_re <= '0';
		elsif rising_edge(clk) then 
			case state is
				when WAIT_REQUEST =>
					-- set RE of FIFO, because of the FIFO specification this is totally fine
					ctrl_in_re <= '1';
					state <= READ_CMD;
				
				when READ_CMD =>
					if CTRL_FIFO_In_Empty = '0' then
						-- read cmd and length
						ctrl_cmd <= CTRL_FIFO_In_Data(C_CTRL_FIFO_WIDTH - 1 downto C_MEMIF_LENGTH_WIDTH);
						ctrl_length <= CTRL_FIFO_In_Data(C_MEMIF_LENGTH_WIDTH - 1 downto 0);

						bconv_cmd := CTRL_FIFO_In_Data(C_CTRL_FIFO_WIDTH - 1 downto C_MEMIF_LENGTH_WIDTH);
						bconv_bytes_rem := CTRL_FIFO_In_Data(C_MEMIF_LENGTH_WIDTH - 1 downto 2) & "00";
					
						state <= READ_ADDR;
					end if;
				
				when READ_ADDR =>
					if CTRL_FIFO_In_Empty = '0' then
						-- read address 
						ctrl_addr <= CTRL_FIFO_In_Data;
						ctrl_in_re <= '0';

						bconv_addr := CTRL_FIFO_In_Data;
						bconv_bytes_rem_page := calc_bytes_rem_page(bconv_addr);
					
						state <= CALC_CHUNK;
					end if;

				when CALC_CHUNK =>
						bconv_length := calc_chunk_length(bconv_addr, bconv_bytes_rem, bconv_bytes_rem_page);

						ctrl_out_empty <= '0';
						ctrl_out_data <= bconv_cmd & bconv_length;
						ctrl_out_fill <= X"0001";

						state <= WRITE_CMD;

				when WRITE_CMD =>
					if CTRL_FIFO_Out_RE = '1' then
						ctrl_out_data <= bconv_addr;
						ctrl_out_fill <= X"0000";

						state <= WRITE_ADDR;
					end if;

				when WRITE_ADDR =>
					if CTRL_FIFO_Out_RE = '1' then
						bconv_addr := bconv_addr + bconv_length;
						bconv_bytes_rem := bconv_bytes_rem - bconv_length;
						bconv_bytes_rem_page := calc_bytes_rem_page(bconv_addr);

						ctrl_out_empty <= '1';
						ctrl_out_fill  <= X"0000";
						ctrl_out_data  <= (others => '0');

						if or_reduce(bconv_bytes_rem) = '0' then
							-- last chunk was read and we have nothing more
							state <= WAIT_REQUEST;
						else
							state <= CALC_CHUNK;
						end if;
					end if;
			end case;
		end if;
	end process burst_converter_proc;
		
end architecture implementation;
