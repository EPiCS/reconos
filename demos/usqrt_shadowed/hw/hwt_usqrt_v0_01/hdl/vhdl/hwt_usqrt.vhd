--
-- hwt_usqrt.vhd
-- Hardwarethread for Basicmath Benchmark, using usqrt_module usqrt.vhd
--
-- Author:		Alexander Sprenger   <alsp@mail.upb.de>
-- History:		18.01.2012	Alexander Sprenger	created

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_usqrt is
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

end entity;

architecture implementation of hwt_usqrt is
	type STATE_TYPE is (
					STATE_GET_DATA,
					STATE_WAIT_1,
					STATE_GET_INPADDR,
					STATE_INCR_ADDR_1,
					STATE_WAIT_2,
					STATE_GET_OUTPADDR,
					STATE_INCR_ADDR_2,
					STATE_WAIT_3,
					STATE_GET_COUNT,
					STATE_COPY_DATA_TO_RAM,
					STATE_CALCULATE,
					STATE_WRITE,
					STATE_ACK_1,
					STATE_ACK_2,
					STATE_ACK_3,
					STATE_THREAD_EXIT
	);

	component usqrt is
		generic (
			G_AWIDTH : integer := 14;           -- in bits
			G_DWIDTH : integer := 32            -- in bits
		);

		port (
			clk   : in std_logic;
			reset : in std_logic;
			count : in std_logic_vector(0 to G_AWIDTH);

			-- local ram interface
			 o_RAMAddr : out std_logic_vector(0 to G_AWIDTH-1);
			 o_RAMData : out std_logic_vector(0 to G_DWIDTH-1);
			 i_RAMData : in  std_logic_vector(0 to G_DWIDTH-1);
			 o_RAMWE   : out std_logic;
			 start     : in  std_logic;
			 done      : inout std_logic
		);
  	end component;
	
	-- IMPORTANT: define number of Bytes in rq_recieve!!!! 
	constant RQ_RECV_LEN_BYTES	  : integer := 12;
	constant RQ_SEND_LEN_BYTES	  : integer := 4;
	
	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 16384;
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	
	constant RQ_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant RQ_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	signal data     : std_logic_vector(31 downto 0);
	signal len_recieve      : std_logic_vector(31 downto 0);
	signal len_send      : std_logic_vector(31 downto 0);
	signal message_width : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;
	signal i_ram    : i_ram_t;
	signal o_ram    : o_ram_t;

	signal o_RAMAddr_usqrt : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMData_usqrt : std_logic_vector(0 to 31);
	signal o_RAMWE_usqrt   : std_logic;
	signal i_RAMData_usqrt : std_logic_vector(0 to 31);

	signal o_RAMAddr_reconos   : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1);
	signal o_RAMAddr_reconos_2 : std_logic_vector(0 to 31);
	signal o_RAMData_reconos   : std_logic_vector(0 to 31);
	signal o_RAMWE_reconos     : std_logic;
	signal i_RAMData_reconos   : std_logic_vector(0 to 31);
	
	constant o_RAMAddr_max : std_logic_vector(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) := (others=>'1');

	shared variable local_ram : LOCAL_MEMORY_T;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal ignore_natural : natural range 0 to 32;

	signal usqrt_start : std_logic := '0';
	signal usqrt_done  : std_logic := '0';
	
	signal cnt : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH downto 0);
	
	signal inp_addr : std_logic_vector(31 downto 0);
	signal outp_addr: std_logic_vector(31 downto 0);
	signal count_hwt: std_logic_vector(31 downto 0);
	
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
			if (o_RAMWE_usqrt = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_usqrt))) := o_RAMData_usqrt;
			else
				i_RAMData_usqrt <= local_ram(conv_integer(unsigned(o_RAMAddr_usqrt)));
			end if;
		end if;
	end process;
	

	-- instantiate square root module
	usqrt_calc : usqrt
		generic map (
			G_AWIDTH  => C_LOCAL_RAM_ADDRESS_WIDTH,
			G_DWIDTH  => 32
		)
		port map (
			clk       => OSFSL_Clk,
			reset     => rst,
			count		 => cnt,
			o_RAMAddr => o_RAMAddr_usqrt,
			o_RAMData => o_RAMData_usqrt,
			i_RAMData => i_RAMData_usqrt,
			o_RAMWE   => o_RAMWE_usqrt,
			start     => usqrt_start,
			done      => usqrt_done
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
	
	ram_setup(
		i_ram,
		o_ram,
		o_RAMAddr_reconos_2,		
		o_RAMData_reconos,
		i_RAMData_reconos,
		o_RAMWE_reconos
	);
	
	o_RAMAddr_reconos(0 to C_LOCAL_RAM_ADDRESS_WIDTH-1) <= o_RAMAddr_reconos_2((32-C_LOCAL_RAM_ADDRESS_WIDTH) to 31);
		
	-- os and memory synchronisation state machine
	reconos_fsm: process (OSFSL_Clk,rst,o_osif,o_memif,o_ram) is
		variable done  : boolean;
		variable ptr	: std_logic_vector(0 to 31);
		
	begin		
		--RESET
		if rst = '1' then
			ptr := (others => '0');
			osif_reset(o_osif);
			memif_reset(o_memif);
			ram_reset(o_ram);
			state <= STATE_GET_DATA;
			done  := False;
			data <= (others => '0');
			len_recieve <= conv_std_logic_vector(RQ_RECV_LEN_BYTES,32);
			len_send <= conv_std_logic_vector(RQ_SEND_LEN_BYTES,32);
			usqrt_start <= '0';
			--o_RAMWE_reconos <= '0';
			inp_addr <= (others => '0');
			outp_addr <= (others => '0');
			count_hwt <= (others => '0');
			cnt <= (others => '0');
			
		elsif rising_edge(OSFSL_Clk) then
		
		cnt <= count_hwt(C_LOCAL_RAM_ADDRESS_WIDTH downto 0);
		
			case state is
				-- get Data via rq
				when STATE_GET_DATA =>
					osif_rq_receive(i_osif,o_osif,i_ram,o_ram,RQ_RECV,len_recieve,X"00000000",message_width,done);
					if done then
						if (message_width = 0) then
							--state <= STATE_THREAD_EXIT;
						else
							o_ram.addr <= (others => '0');
							state <= STATE_WAIT_1;
						end if;
					end if;
				
				when STATE_WAIT_1 =>
					state <= STATE_GET_INPADDR;
				
				-- get first value in reconos_queue -> input_addr
				when STATE_GET_INPADDR =>
					inp_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_1;
				
				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_1 =>
					if(inp_addr = X"FFFFFFFF") then
						state <= STATE_THREAD_EXIT;
					else
					   o_ram.addr <= X"00000001";
					   state <= STATE_WAIT_2;
					end if;
					
				when STATE_WAIT_2 =>
					state <= STATE_GET_OUTPADDR;

				-- get second value in reconos_queue -> output_addr
				when STATE_GET_OUTPADDR =>
					outp_addr <= i_ram.data;
					state <= STATE_INCR_ADDR_2;

				-- increment RAM_ADDR 
				when STATE_INCR_ADDR_2 =>
					o_ram.addr <= X"00000002";
					state <= STATE_WAIT_3;
					
				when STATE_WAIT_3 =>
					state <= STATE_GET_COUNT;

				-- get third value in reconos_queue -> number of values to calculate (count)
				when STATE_GET_COUNT =>
					count_hwt <= i_ram.data;
					state <= STATE_COPY_DATA_TO_RAM;
				
				-- copy "count" words from the given input addr of the memory to the local RAM
				when STATE_COPY_DATA_TO_RAM =>
					memif_read(i_ram, o_ram, i_memif, o_memif, inp_addr, (others => '0'), count_hwt(21 downto 0) & "00", done); 
					if done then
						usqrt_start <= '1';
						state <= STATE_CALCULATE;
					end if;
	
				-- calculate the square root of the given values in local RAM
				when STATE_CALCULATE =>
					usqrt_start <= '0';
					if usqrt_done = '1' then
						state  <= STATE_WRITE;
					end if;
					
				-- copy data from local RAM to the given output_addr in main memory
				when STATE_WRITE =>
					memif_write(i_ram,o_ram,i_memif,o_memif,X"00000000",outp_addr,count_hwt(21 downto 0) & "00",done);
					--osif_mbox_put(i_osif, o_osif, MBOX_SEND, i_RAMData_reconos, ignore, done);
					if done then
						state <= STATE_ACK_1;
						--state <= STATE_GET_DATA;
					end if;
				
				-- set the local RAM pointer to 0
				when STATE_ACK_1 =>
					o_ram.addr <= (others => '0');
					state <= STATE_ACK_2;
				
				-- write the output_addr to the local RAM
				when STATE_ACK_2 =>
					o_ram.we   <= '1';
					--o_ram.data <= outp_addr;
					o_ram.data <= count_hwt;
					state <= STATE_ACK_3;
				
				-- send rq with the output_addr as value, to signal that the calculating is finished
				when STATE_ACK_3 =>
					osif_rq_send(i_osif, o_osif, i_ram, o_ram, RQ_SEND, len_send, X"00000000", ignore, done);
					if done then 
						state <= STATE_GET_DATA; 
					end if;

				-- thread exit
				when STATE_THREAD_EXIT =>
					osif_thread_exit(i_osif,o_osif);

			end case;
		end if;
	end process;	
end architecture;
