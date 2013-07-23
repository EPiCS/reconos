library ieee;
use ieee.std_logic_1164.all;

entity hwt_add_tb is
	
end entity hwt_add_tb;

architecture RTL of hwt_add_tb is
	
	signal rx_ll_sof  : std_logic;
	signal rx_ll_eof  : std_logic;
	signal rx_ll_data  : std_logic_vector(7 downto 0);
	signal rx_ll_src_rdy  : std_logic;
	signal rx_ll_dst_rdy  : std_logic;
	signal tx_ll_sof  : std_logic;
	signal tx_ll_eof  : std_logic;
	signal tx_ll_data  : std_logic_vector(7 downto 0);
	signal tx_ll_src_rdy  : std_logic;
	signal tx_ll_dst_rdy  : std_logic;
	
	signal packet_len : integer range 0 to 1500;
	signal cur_len : integer range 0 to 1500;
	signal cur_len_next : integer range 0 to 1500;
	type packet_state_t is ( P_STATE_SEND, P_STATE_INIT );
	signal packet_state : packet_state_t;
	signal packet_state_next : packet_state_t;
	signal clk : std_logic;
	signal rst : std_logic;
	
	component hwt_add is
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
	end component;
	
begin

	packet_len  <= 64;
	rx_ll_dst_rdy  <= '1';
	
	packets : process(packet_state, packet_len, cur_len) is
	begin
	tx_ll_sof  <= '0';
	tx_ll_eof  <= '0';
	tx_ll_src_rdy  <= '1';
	tx_ll_data  <= "01100001";
	cur_len_next  <= cur_len;
	packet_state_next  <= packet_state;
	case packet_state is
	when P_STATE_INIT  => 
		tx_ll_sof  <= '1';
		if tx_ll_dst_rdy = '1' then	
			packet_state_next  <= P_STATE_SEND;
			cur_len_next  <= 1;
		end if;
	when P_STATE_SEND  => 
		if cur_len = packet_len then
			tx_ll_eof  <= '1';
			packet_state_next  <= P_STATE_INIT;
		end if;
		if tx_ll_dst_rdy = '1' then
			cur_len_next  <= cur_len + 1;
		end if;
	end case;
	end process;


	rst  <= '1', '0' after 1 ms;
	clk_process :process
	begin
		clk <= '0';
		wait for 5 us;
		clk <= '1';
		wait for 5 us;
	end process;

	memzing: process(clk, rst) is
	begin
	    if rst = '1' then
			cur_len  <= 0;
			packet_state  <= P_STATE_INIT;
		
	    elsif rising_edge(clk) then
	    	cur_len  <= cur_len_next;
	    	packet_state  <= packet_state_next;
	    end if;
	end process;

	hwt_add_inst : hwt_add 
	port map(
		rst         => rst,
		clk			 => clk,
		rx_ll_sof  	 => tx_ll_sof,
		rx_ll_eof  	 => tx_ll_eof,
		rx_ll_data   => tx_ll_data,
		rx_ll_src_rdy   => tx_ll_src_rdy,
		rx_ll_dst_rdy   => tx_ll_dst_rdy,
		tx_ll_sof   => rx_ll_sof,
		tx_ll_eof   => rx_ll_eof,
		tx_ll_data  => rx_ll_data,
		tx_ll_src_rdy   => rx_ll_src_rdy,
		tx_ll_dst_rdy   => rx_ll_dst_rdy
	);

end architecture RTL;
