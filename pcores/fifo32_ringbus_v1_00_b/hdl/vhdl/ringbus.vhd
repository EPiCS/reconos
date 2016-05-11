----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:44:09 02/25/2015 
-- Design Name: 
-- Module Name:    ringbus - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.ringbus_pck.all;

entity ringbus is
	generic ( 
		G_TAP_CNT : integer := 8;
		G_BUS_WIDTH: integer := 32;
		G_FILL_WIDTH: integer:= 16;
		G_REM_WIDTH: integer:= 16
	);
	port (
		FIFO32_S_Data : in std_logic_vector((G_TAP_CNT*G_BUS_WIDTH)-1 downto 0);
		FIFO32_S_Fill : in std_logic_vector((G_TAP_CNT*G_FILL_WIDTH)-1 downto 0);
		FIFO32_S_Rd  : out std_logic_vector((G_TAP_CNT)-1 downto 0);
		
		FIFO32_M_Data: out std_logic_vector((G_TAP_CNT*G_BUS_WIDTH)-1 downto 0);
		FIFO32_M_Rem  : in  std_logic_vector((G_TAP_CNT*G_REM_WIDTH)-1 downto 0);
		FIFO32_M_Wr  : out std_logic_vector((G_TAP_CNT)-1 downto 0);
		
		clk : in STD_LOGIC;
		rst: in STD_LOGIC;
		
		-- Debug signals to ILA
        ila_signals : out std_logic_vector(255 downto 0)
	);
end ringbus;

architecture Behavioral of ringbus is

	signal c_ring  : ring_vector_t(0 to G_TAP_CNT-1);
	signal cc_ring : ring_vector_t(0 to G_TAP_CNT-1);

	signal ctrl_masters : ctrl_master_vector_t(0 to G_TAP_CNT-1);
	signal ctrl_slaves  : ctrl_slave_vector_t(0 to G_TAP_CNT-1);
	
	-- Debug signals to ILA
  	type  ila_vector_t is array (natural range<>) of std_logic_vector(130 downto 0);
  	signal ila_signals_tap : ila_vector_t(0 to G_TAP_CNT-1);
  	signal ila_signals_control : std_logic_vector(130 downto 0);
	
begin

-- 	ila_signals(15 downto 0)   <= ila_signals_control(15 downto 0);
-- 	ila_signals(27 downto 16)  <= ila_signals_tap(0)(11 downto 0);
-- 	ila_signals(39 downto 28)  <= ila_signals_tap(1)(11 downto 0);
-- 	ila_signals(105 downto 40)  <= ila_signals_tap(0)(77 downto 12); -- FIFO Data and rd/wr signals
-- 	ila_signals(123 downto 106)  <= ila_signals_tap(0)(113 downto 96); -- cc ring signals
-- 	ila_signals(130 downto 124) <= (others =>'0');
	
	ila_signals(130 downto 0) <= ila_signals_tap(0);
	ila_signals(146 downto 131) <= ila_signals_control(15 downto 0);
	ila_signals(224 downto 147) <= ila_signals_tap(1)(77 downto 0);
	ila_signals(241 downto 225) <= ila_signals_tap(1)(130 downto 114);
	ila_signals(255 downto 242) <= (others =>'0');
	
	taps_generate: for i in 0 to G_TAP_CNT-1 generate
	begin

		taps_i : entity work.ringbus_tap 
		generic map ( 
			G_ADDRESS        => to_unsigned(i, RB_ADDR_WIDTH),
			G_TAP_CNT        => G_TAP_CNT)
		port    map (
    		FIFO32_S_Data    => FIFO32_S_Data( ((i+1)*G_BUS_WIDTH)-1 downto (i*G_BUS_WIDTH) ),
    		FIFO32_S_Fill    => FIFO32_S_Fill( ((i+1)*G_FILL_WIDTH)-1 downto (i*G_FILL_WIDTH) ),
    		FIFO32_S_Rd      => FIFO32_S_Rd( i ),
    		FIFO32_M_Data    => FIFO32_M_Data( ((i+1)*G_BUS_WIDTH)-1 downto (i*G_BUS_WIDTH) ),
    		FIFO32_M_Rem     => FIFO32_M_Rem( ((i+1)*G_REM_WIDTH)-1 downto (i*G_REM_WIDTH) ),
    		FIFO32_M_Wr      => FIFO32_M_Wr( i ),
    		c_in             => c_ring(i),   
    		cc_in            => cc_ring(i),  
    		c_out            => c_ring( (i+1) mod G_TAP_CNT ),  
    		cc_out           => cc_ring( (i-1) mod G_TAP_CNT ), 
        	ctrl_out 		 => ctrl_masters(i),
        	ctrl_in  		 => ctrl_slaves(i),
    		clk              => clk,    
    		rst              => rst,
    		ila_signals      => ila_signals_tap(i));

	end generate;

	control_i: entity work.ringbus_control
		generic map(
			G_TAP_CNT => G_TAP_CNT)
		port map(
			ctrl_in  => ctrl_masters,
			ctrl_out =>ctrl_slaves,
			clk => clk,
			rst => rst,
			ila_signals => ila_signals_control
		);

end Behavioral;

