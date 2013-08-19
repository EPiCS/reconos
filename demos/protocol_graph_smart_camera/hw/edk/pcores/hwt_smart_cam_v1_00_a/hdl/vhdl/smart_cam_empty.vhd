library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;


entity smart_cam is
--	generic (
--		destination	: std_logic_vector(5 downto 0);
--		sender		: std_logic
--	);
	port (
		--enter your ports here: 

		-- 

		rst         	: in  std_logic;
		clk		: in  std_logic;
		rx_ll_sof  	: in  std_logic;
		rx_ll_eof  	: in  std_logic;
		rx_ll_data  	: in  std_logic_vector(7 downto 0);
		rx_ll_src_rdy 	: in  std_logic;
		rx_ll_dst_rdy 	: out std_logic;
		tx_ll_sof  	: out std_logic;
		tx_ll_eof  	: out std_logic;
		tx_ll_data 	: out std_logic_vector(7 downto 0);
		tx_ll_src_rdy 	: out std_logic;
		tx_ll_dst_rdy 	: in  std_logic
	);

end smart_cam;

architecture implementation of packet_generator is

	

begin
	
	

end architecture;
