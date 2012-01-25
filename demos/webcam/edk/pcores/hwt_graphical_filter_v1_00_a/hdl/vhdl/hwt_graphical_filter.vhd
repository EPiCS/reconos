library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_graphical_filter is
	port (
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Clk : out std_logic;
		FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data : in std_logic_vector(31 downto 0);
		FIFO32_M_Data : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd : out std_logic;
		FIFO32_M_Wr : out std_logic;
		
		-- HWT reset
		rst           : in std_logic
	);

end hwt_graphical_filter;

architecture implementation of hwt_graphical_filter is
	type STATE_TYPE is (STATE_GET_INIT_DATA,STATE_READ_PARAMETER,STATE_READ_PARAMETER_2,
		STATE_GET_ADDR,STATE_CONTROL,STATE_LOAD_LINE,STATE_MIRROR_LINE,STATE_MIRROR_LINE_2,
		STATE_MIRROR_LINE_3,STATE_MIRROR_LINE_4,STATE_MIRROR_LINE_5,
		STATE_STORE_LINE,STATE_ACK,STATE_THREAD_EXIT);
	
	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 512;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);	
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal addr  : std_logic_vector(31 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_uf : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_uf : std_logic_vector(0 to 31);
	signal o_RAMWE_uf   : std_logic;
	signal i_RAMData_uf : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	
	signal information_struct_addr : std_logic_vector(31 downto 0);
	signal size_x : std_logic_vector(31 downto 0);
	signal size_y : std_logic_vector(31 downto 0);
	signal y : std_logic_vector(31 downto 0);
	signal x : std_logic_vector(31 downto 0);
	signal ptr : std_logic_vector(31 downto 0);
	signal ram_src : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal ram_dst : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal data : std_logic_vector(31 downto 0);

begin

	-- local dual-port RAM
	local_ram_ctrl_1 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then
			if (o_RAMWE_reconos = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_reconos))) := o_RAMData_reconos;
			else
				i_RAMData_reconos <= local_ram(conv_integer(unsigned(o_RAMAddr_reconos)));
			end if;
		end if;
	end process;
			
	local_ram_ctrl_2 : process (OSFSL_Clk) is
	begin
		if (rising_edge(OSFSL_Clk)) then		
			if (o_RAMWE_uf = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_uf))) := o_RAMData_uf;
			else
				i_RAMData_uf <= local_ram(conv_integer(unsigned(o_RAMAddr_uf)));
			end if;
		end if;
	end process;

	o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);

	ram_setup(
		i_ram,
		o_ram,
		o_RAMAddr_reconos_2,		
		o_RAMData_reconos,
		i_RAMData_reconos,
		o_RAMWE_reconos
	);

	fsl_setup(
		i_osif,
		o_osif,
		OSFSL_Clk,
		OSFSL_Rst,
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
		OSFSL_Clk,
		FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
		FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);

	
	-- os and memory synchronisation state machine
	reconos_fsm: process (i_osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= STATE_GET_INIT_DATA;
			done := False;
			addr <= (others => '0');
		elsif rising_edge(i_osif.clk) then
			o_RAMWE_uf <= '0';
			case state is
				
				-- read init data
				when STATE_GET_INIT_DATA =>
					osif_get_init_data(i_osif,o_osif,information_struct_addr,done);
					if done then state <= STATE_READ_PARAMETER; end if;
				
				-- read frame width
				when STATE_READ_PARAMETER =>
					memif_read_word(i_memif,o_memif,information_struct_addr,size_x,done);
					if done then state <= STATE_READ_PARAMETER_2; end if;
					
				--read frame height
				when STATE_READ_PARAMETER_2 =>
					memif_read_word(i_memif,o_memif,information_struct_addr+4,size_y,done);
					if done then state <= STATE_GET_ADDR; end if;

				-- get address via mbox: the data will be copied from this address to the local ram in the next states
				when STATE_GET_ADDR =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr, done);
					if done then
						if (addr = X"FFFFFFFF") then
							state <= STATE_THREAD_EXIT;
						else
							ptr <= addr;
							state <= STATE_ACK;
							--state <= STATE_CONTROL;
							y <= (others=>'0');
						end if;
					end if;
				
--				-- control the processing of lines
--				when STATE_CONTROL =>
--					if (y < size_y) then
--						y <= y + 1;
--						state <= STATE_LOAD_LINE;
--					else
--						state <= STATE_ACK;
--					end if;
--				
--				-- load line from main memory
--				when STATE_LOAD_LINE =>
--					memif_read(i_ram,o_ram,i_memif,o_memif,ptr,X"00000000",size_x(21 downto 0)&"00",done);
--					if done then 
--						x <= (others=>'0');
--						ram_src <= (others=>'0');
--						ram_dst <= "100000000" + size_x;
--						state <= STATE_MIRROR_LINE; 
--					end if;
--				
--				-- start to mirror the pixel line
--				when STATE_MIRROR_LINE =>	
--					ram_dst <= ram_dst - 1;
--					o_RAMAddr_uf <= ram_src;
--					state <= STATE_MIRROR_LINE_2;
--				
--				-- count the pixels in the line. load the pixel data
--				when STATE_MIRROR_LINE_2 =>
--					o_RAMAddr_uf <= ram_src;
--					if (x<size_x) then
--						x <= x + 1;
--						state <= STATE_MIRROR_LINE_3;
--					else 
--						state <= STATE_STORE_LINE;
--					end if;
--				
--				-- wait 1 clock cycle (BRAM delay)
--				when STATE_MIRROR_LINE_3 =>	
--					state <= STATE_MIRROR_LINE_4;
--				
--				-- store pixel in the second half of the local RAM
--				when STATE_MIRROR_LINE_4 =>	
--					o_RAMData_uf <= i_RAMData_uf;
--					o_RAMAddr_uf <= ram_dst;
--					o_RAMWE_uf   <= '1';
--					state <= STATE_MIRROR_LINE_5;
--				
--				-- set new src and dst addresses
--				when STATE_MIRROR_LINE_5 =>
--					ram_dst <= ram_dst - 1;
--					ram_src <= ram_src + 1;
--					state <= STATE_MIRROR_LINE_2;
--				
--				-- store pixel line to main memory
--				when STATE_STORE_LINE =>
--					memif_write(i_ram,o_ram,i_memif,o_memif,X"00000100",ptr,size_x(21 downto 0)&"00",done);
--					if done then 
--						ptr <= ptr + (size_x(29 downto 0)&"00");
--						state <= STATE_CONTROL; 
--					end if;
				
				-- send mbox that signals that filtering is done
				when STATE_ACK =>
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, addr, ignore, done);
					if done then state <= STATE_GET_ADDR; end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);
					
				when others =>
					state <= STATE_GET_ADDR;
			
			end case;
		end if;
	end process;
	
end architecture;
