library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity hwt_memaccess is
	generic (
		C_ENABLE_ILA : integer := 0
	);
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

end hwt_memaccess;

architecture implementation of hwt_memaccess is
	type STATE_TYPE is (STATE_GET_ADDR_A,STATE_GET_ADDR_B,STATE_GET_SIZE,STATE_GET_BURST_LEN,STATE_GET_REPEAT,STATE_COPY_0,
                            STATE_COPY_1,STATE_ACK,STATE_READ_REQ,STATE_WRITE_REQ);

	type LOCAL_MEMORY_T is array (0 to 1023) of std_logic_vector(31 downto 0);
	
	constant MBOX_RECV  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND  : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";

	component hwt_icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
	end component;

	component hwt_ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(223 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	end component;

	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal CSDATA    : STD_LOGIC_VECTOR(223 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(15 DOWNTO 0);
       
	signal addr_a   : std_logic_vector(31 downto 0);
	signal addr_b   : std_logic_vector(31 downto 0);
	signal data     : std_logic_vector(31 downto 0);
	signal size     : std_logic_vector(31 downto 0);
	signal counter  : std_logic_vector(31 downto 0);
	signal blen     : std_logic_vector(31 downto 0);
	signal repeat     : std_logic_vector(31 downto 0);
			
	signal state    : STATE_TYPE;
	signal i_osif   : i_osif_t;
	signal o_osif   : o_osif_t;
	signal i_memif  : i_memif_t;
	signal o_memif  : o_memif_t;

	signal ignore   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
begin

--------------------- CHIPSCOPE -------------------------
       
	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

	icon_i : hwt_icon
	port map (
		CONTROL0 => CONTROL
	);

	ila_i : hwt_ila
	port map (
		CONTROL => CONTROL,
		CLK => OSFSL_Clk,
		DATA => CSDATA,
		TRIG0 => TRIG
	);

	end generate;

	CSDATA(0) <= '1' when state = STATE_GET_ADDR_A else '0';
	CSDATA(1) <= '1' when state = STATE_GET_ADDR_B else '0';
	CSDATA(2) <= '1' when state = STATE_GET_SIZE else '0';
	CSDATA(3) <= '1' when state = STATE_GET_BURST_LEN else '0';
	CSDATA(4) <= '1' when state = STATE_GET_REPEAT else '0';
	CSDATA(5) <= '1' when state = STATE_COPY_0 else '0';
	CSDATA(6) <= '1' when state = STATE_COPY_1 else '0';
	CSDATA(7) <= '1' when state = STATE_ACK else '0';
	CSDATA(8) <= '1' when state = STATE_READ_REQ else '0';
	CSDATA(9) <= '1' when state = STATE_WRITE_REQ else '0';

	CSDATA(63 downto 32) <= data;
	CSDATA(95 downto 64) <= size;
	CSDATA(127 downto 96) <= counter;
	CSDATA(159 downto 128) <= blen;
	CSDATA(191 downto 160) <= repeat;
	CSDATA(207 downto 192) <= FIFO32_S_Fill;
	CSDATA(223 downto 208) <= FIFO32_M_Rem;
	TRIG <= "000000" & CSDATA(9 downto 0);
       
----------------------------------------------------------

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
	process (i_osif.clk) is
		variable done : boolean;
	begin
		if rst = '1' then
			osif_reset(o_osif);
			memif_reset(o_memif);
			state <= STATE_GET_ADDR_A;
			done := False;
			addr_a <= (others => '0');
			addr_b <= (others => '0');
			counter <= (others => '0');
			blen <= (others => '0');
			size <= (others => '0');
			repeat <= (others => '0');
			data <= x"AFFE7654";
		elsif rising_edge(i_osif.clk) then
			case state is
				when STATE_GET_ADDR_A =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr_a, done);
					if done then state <= STATE_GET_ADDR_B; end if;

				when STATE_GET_ADDR_B =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, addr_b, done);
					if done then state <= STATE_GET_SIZE; end if;
				
				when STATE_GET_SIZE =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, size, done);
					if done then
						size <= size(31 downto 2) & "00";
						state <= STATE_GET_BURST_LEN;
					end if;

				when STATE_GET_BURST_LEN =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, blen, done);
					if done then
						blen <= blen(31 downto 2) & "00";
						state <= STATE_GET_REPEAT;
					end if;

				when STATE_GET_REPEAT =>
					osif_mbox_get(i_osif, o_osif, MBOX_RECV, repeat, done);
					if done then state <= STATE_READ_REQ; end if;

				when STATE_READ_REQ =>
					memif_read_request(i_memif, o_memif, addr_a, blen(23 downto 0), done);
					if done then state <= STATE_WRITE_REQ; end if;

				when STATE_WRITE_REQ =>
					memif_write_request(i_memif, o_memif, addr_b, blen(23 downto 0), done);
					if done then
						state <= STATE_COPY_0;
						counter <= (others => '0');
					end if;

				when STATE_COPY_0 =>
					memif_fifo_pull(i_memif, o_memif, data,done);
					if done then
						state <= STATE_COPY_1;
						data <= data + 1;
						counter <= counter + 4;
					end if;

				when STATE_COPY_1 =>
					memif_fifo_push(i_memif, o_memif, data,done);
					if done then 
						state <= STATE_COPY_0;
						if counter = blen then
							state <= STATE_READ_REQ;
							if repeat = 0 then
								state <= STATE_ACK;
							else
								addr_a <= addr_b;
								addr_b <= addr_a;
								repeat <= repeat - 1;
								if blen < size then
									blen <= blen + 4;
								else
									blen <= x"00000004";
								end if;
							end if;
						end if;
					end if;


				when STATE_ACK => -- this informs the sw that we are done writing
					osif_mbox_put(i_osif, o_osif, MBOX_SEND, addr_a, ignore, done);
					if done then state <= STATE_GET_ADDR_A; end if;
			
			end case;
		end if;
	end process;
	
end architecture;
