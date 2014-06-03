library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;


entity add is
--	generic (
--		destination	: std_logic_vector(5 downto 0);
--		sender		: std_logic
--	);
	port (
	rst         : in std_logic;
		clk			: in std_logic;
		rx_ll_sof  	: in std_logic;
		rx_ll_eof  	: in std_logic;
		rx_ll_data  : in std_logic_vector(7 downto 0);
		rx_ll_src_rdy  : in std_logic;
		rx_ll_dst_rdy  : out std_logic;
		tx_ll_sof  : out std_logic;
		tx_ll_eof  : out std_logic;
		tx_ll_data : out std_logic_vector(7 downto 0);
		tx_ll_src_rdy  : out std_logic;
		tx_ll_dst_rdy  : in std_logic
	);

end add;

architecture implementation of add is
	constant C_NR_OF_ELEMENTS : unsigned := 24;
	constant C_MAX_CODE_LEN : unsigned := 10;
	
	type value_array is array (0 to C_NR_OF_ELEMENTS - 1) of unsigned integer range 0 to 255; 
	signal value     : value_array;
	type code_array is array (0 to C_NR_OF_ELEMENTS - 1) of std_logic_vector (0 to C_MAX_CODE_LEN - 1); 
	signal code     : code_array;
	type len_array is array (0 to C_NR_OF_ELEMENTS - 1) of unsigned integer range 0 to C_MAX_CODE_LEN;
	signal len     : len_array;
	signal plain 		: std_logic_vector(0 to 8 * 1500); --max packet size
	signal plain_next	: std_logic_vector(0 to 8 * 1500);
	signal encoded		: std_logic_vector(0 to 8 * 1500); --if it gets longer, we simply truncate it.
	signal encoded_next : std_logic_vector(0 to 8 * 1500);
	
	-- PUT YOUR OWN COMPONENTS HERE

    -- END OF YOUR OWN COMPONENTS
	

    -- ADD YOUR CONSTANTS, TYPES AND SIGNALS BELOW

	signal tx_ll_sof	: std_logic;
	signal tx_ll_eof	: std_logic;
	signal tx_ll_data	: std_logic_vector(7 downto 0);
	signal tx_ll_src_rdy	: std_logic;
	signal tx_ll_dst_rdy	: std_logic;

	signal rx_ll_sof	: std_logic;
	signal rx_ll_eof	: std_logic;
	signal rx_ll_data	: std_logic_vector(7 downto 0);
	signal rx_ll_src_rdy	: std_logic;
	signal rx_ll_dst_rdy	: std_logic;

	
	type receiving_state_t is ( R_STATE_WAIT, R_STATE_RCV, R_STATE_ENC, R_STATE_TRANSMIT );
	
	signal receiving_state_next : receiving_state_t;
	signal receiving_state : receiving_state_t;
	signal index_next : integer range 0 to 1508;
	signal index : integer range 0 to 1508;
	signal enc_index : integer range 0 to 1508;
	signal enc_index_next : integer range 0 to 1508;
	signal total_len : integer range 0 to 1500;
	signal total_len_next : integer range 0 to 1500;
	

begin
	
	generate_table : for i in 0 to C_NR_OF_ELEMENTS -1 generate
		value(i) <= i+97;
		end generate;
	
	assign_codes : process(i_osif.clk) is
	begin
	if rising_edge(i_osif.clk) then
	code  <= (others => (others => '0'));
	code(0)(0 to 3)		<= "0011"; --a
	len(0)				<= 4;
	code(1)(0 to 5)		<= "011011"; --b
	len(1)				<= 6;
	code(2)(0 to 4)		<= "11111"; --c
	len(2)				<= 5;	
	code(3)(0 to 4)		<= "00100"; --d
	len(3)				<= 5;	
	code(4)(0 to 2)		<= "101"; --e
	len(4)				<= 3;	
	code(5)(0 to 5)		<= "000010"; --f
	len(5)				<= 6;	
	code(6)(0 to 5)		<= "011001"; --g
	len(6)				<= 6;	
	code(7)(0 to 3)		<= "1110"; --h
	len(7)				<= 4;	
	code(8)(0 to 3)		<= "0101"; --i
	len(8)				<= 4;	
	code(9)(0 to 8)		<= "011010101"; --j
	len(9)				<= 9;	
	code(10)(0 to 9)	<= "0110101001"; --k
	len(10)				<= 10;	
	code(11)(0 to 4)	<= "00101"; --l
	len(11)				<= 5;	
	code(12)(0 to 5)	<= "000001"; --m
	len(12)				<= 6;	
	code(13)(0 to 3)	<= "0111"; --n
	len(13)				<= 4;	
	code(14)(0 to 3)	<= "0100"; --o
	len(14)				<= 4;	
	code(15)(0 to 5)	<= "011000"; --p
	len(15)				<= 6;	
	code(16)(0 to 9)	<= "0110101000"; --q
	len(16)				<= 10;	
	code(17)(0 to 3)	<= "1101"; --r
	len(17)				<= 4;	
	code(18)(0 to 3)	<= "1100"; --s
	len(18)				<= 4;	
	code(19)(0 to 3)	<= "0001"; --t
	len(19)				<= 4;	
	code(20)(0 to 4)	<= "11110"; --u
	len(20)				<= 5;	
	code(21)(0 to 6)	<= "0110100"; --v
	len(21)				<= 7;	
	code(22)(0 to 5)	<= "000000"; --w
	len(22)				<= 6;	
	code(23)(0 to 8)	<= "011010111"; --x
	len(23)				<= 9;	
	code(24)(0 to 5)	<= "000011"; --y
	len(24)				<= 6;	
	code(25)(0 to 7)	<= "01101011"; --z
	len(25)				<= 8;
	code(26)(0 to 2)	<= "100";
	len(26)				<= 3;
	end if;
	end process;
	
	
   
	
	receiving: process(receiving_state, rx_ll_sof, rx_ll_eof, rx_ll_src_rdy, rx_ll_data, plain, 
						index, enc_index, encoded, total_len) is
	begin
	plain_next <= plain;
	encoded_next  <= encoded;
	receiving_state_next  <= receiving_state;
	index_next  <= index;
	enc_index_next  <= enc_index;
	total_len_next  <= total_len;
	tx_ll_sof  <= '0';
	tx_ll_eof  <= '0';
	tx_ll_data  <= (others  => '0');
	tx_ll_src_rdy  <= '0';
	rx_ll_dst_rdy  <= '0';
	case receiving_state is
		when R_STATE_WAIT =>
			encoded_next  <= (others => '0');
			enc_index_next  <= 0;
			rx_ll_dst_rdy <= '1';
			if rx_ll_src_rdy = '1' and rx_ll_sof = '1' then
				plain_next(0 to 7)  <= rx_ll_data;
				index_next  <= 8;
				receiving_state_next  <= R_STATE_RCV;
			end if;
		when R_STATE_RCV =>
			rx_ll_dst_rdy  <= '1';
			if rx_ll_src_rdy = '1' then
				plain_next(index to index + 7) <= rx_ll_data;
				index_next  <= index + 8;
				if rx_ll_eof = '1' then
					receiving_state_next  <= R_STATE_ENC;
					rx_ll_dst_rdy  <=  '0';
					total_len_next  <= index + 8;
				end if;
			end if;
		when R_STATE_ENC  => 
			rx_ll_dst_rdy  <= '0';
			encoded_next(enc_index to len(to_integer(plain(index to index + 7)) - 97) - 1)  <= code(to_integer(plain(index to index + 7)) - 97);
			enc_index_next  <=  enc_index + len(to_integer(plain(index to index + 7)) - 97) - 1;
			index_next  <= index + 8;
			if enc_index_next > 1500 or index > total_len then
				receiving_state_next  <= R_STATE_TRANSMIT;
				index_next  <= 0;
			end if;			
		when R_STATE_TRANSMIT  => 
			rx_ll_dst_rdy  <= '0';
			tx_ll_src_rdy  <= '1';
			if index = 0 then
				tx_ll_sof  <= '1';
			end if;
			tx_ll_data  <= encoded(index to index + 7);
			if tx_ll_dst_rdy = '1' then
				index_next  <= index + 8;
				if index + 8 >= enc_index then
					receiving_state_next  <= R_STATE_WAIT;
					tx_ll_eof  <= '1';
				end if;
			end if;
			
	end case;
	end process;
	
	

	--creates flipflops
	memzing: process(clk, rst) is
	begin
	    if rst = '1' then
			plain <= (others  => '0');
			encoded  <= (others  => '0');
			receiving_state  <= R_STATE_WAIT;
			index  <= 0;
			enc_index  <= 0;
			total_len  <= 0;
		
	    elsif rising_edge(i_osif.clk) then
			plain <= plain_next;
			encoded  <= encoded_next;
			receiving_state  <= receiving_state_next;
			index  <= index_next;
			enc_index  <= enc_index_next;
			total_len  <= total_len_next;
	    end if;
	end process;

end architecture;
