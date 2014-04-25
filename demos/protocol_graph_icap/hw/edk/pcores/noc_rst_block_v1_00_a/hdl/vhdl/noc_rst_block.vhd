library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity noc_rst_block is
	port (	
		-- HWT reset
		rst : in std_logic;
		--clk : in std_logic;

		switch_data_rdy_in	: in  std_logic;
		switch_data_in		: in  std_logic_vector(8 downto 0);
		switch_read_rdy_in	: in  std_logic;
		thread_read_rdy_in 	: in  std_logic;
		thread_data_in		: in  std_logic_vector(8 downto 0);
		thread_data_rdy_in 	: in  std_logic;

		switch_data_rdy_out	: out std_logic;
		switch_data_out		: out std_logic_vector(8 downto 0);
		switch_read_rdy_out	: out std_logic;
		thread_read_rdy_out 	: out std_logic;
		thread_data_out		: out std_logic_vector(8 downto 0);
		thread_data_rdy_out 	: out std_logic
	);

end noc_rst_block;

architecture implementation of noc_rst_block is
begin	
	switch_data_rdy_out <= switch_data_rdy_in when rst='0' else '0';
	switch_data_out     <= switch_data_in     when rst='0' else "000000000";
	switch_read_rdy_out <= switch_read_rdy_in when rst='0' else '0';
	
	thread_data_rdy_out <= thread_data_rdy_in when rst='0' else '0';
	thread_data_out     <= thread_data_in     when rst='0' else "000000000";
	thread_read_rdy_out <= thread_read_rdy_in when rst='0' else '0';
end architecture;
