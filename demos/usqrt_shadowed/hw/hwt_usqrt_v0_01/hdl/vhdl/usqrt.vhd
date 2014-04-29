--
-- usqrt.vhd
-- usqrt module. Calculates a sqaure root.
--
-- Author:		Alexander Sprenger   <alsp@mail.upb.de>
-- History:		20.12.2012	Alexander Sprenger	created

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--use IEEE.NUMERIC_STD.all;

entity usqrt is
  generic (
    G_AWIDTH : integer := 11;           -- in bits
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
    done      : out std_logic
    );
end usqrt;

architecture Behavioral of usqrt is
  type state_t is (
		STATE_IDLE,
		STATE_GET_DATA, 
		STATE_RUNNING,
		STATE_WRITE_DATA,
		STATE_WAIT_2,
		STATE_INC_ADDR);

  signal state : state_t := STATE_IDLE;
  
  signal ptr : std_logic_vector(0 to G_AWIDTH-1);
  signal ptr_max : std_logic_vector(0 to G_AWIDTH) := (others => '0');

begin
  -- set RAM address
  o_RAMAddr <= ptr;

  -- usqrt state machine
 usqrt_proc	: process(clk, reset)
	variable accu 				: std_logic_vector(G_DWIDTH-1 downto 0);
	variable remainder		: std_logic_vector(G_DWIDTH-1 downto 0);
	variable trial_product	: std_logic_vector(G_DWIDTH-1 downto 0);
	variable value 			: std_logic_vector(G_DWIDTH-1 downto 0);
	variable bits 				: natural range 0 to G_DWIDTH;
  
	begin
	 if reset = '1' then
	   ptr       		<= (others => '0');
		o_RAMData 		<= (others => '0');
      o_RAMWE   		<= '0';
      done				<= '0';
		accu				:= (others => '0');
		remainder		:= (others => '0');
		trial_product	:= (others => '0');
		bits 				:= 0;
		ptr_max 			<= (others => '0');
    
	 elsif rising_edge(clk) then
		o_RAMWE   <= '0';
	 
      case state is

        when STATE_IDLE        =>
          done				<= '0';
			 accu				:= (others => '0');
			 remainder		:= (others => '0');
			 trial_product	:= (others => '0');
			 bits				:= 0;
			 ptr				<= (others => '0');
			 ptr_max 		<= count-1;
			 
          -- start calculating on 'start' signal
          if start = '1' then
            state   <= STATE_GET_DATA;
          end if;

          -- get value
        when STATE_GET_DATA =>
			 value := i_RAMData;
			 state <= STATE_RUNNING;          

          -- calculate sqrt
        when STATE_RUNNING =>			 
			 if bits < G_DWIDTH then
				remainder := remainder(29 downto 0) & value(31 downto 30);
				value := value(29 downto 0) & "00";
				accu := accu(30 downto 0) & "0";
				trial_product := accu(30 downto 0) & "1";
				if (remainder >= trial_product) then
					remainder := remainder - trial_product;
					accu := accu + 1;
				end if;
				bits := bits+1;
			 else
				o_RAMData <= accu;
				state <= STATE_WRITE_DATA;
			 end if;
			           
          -- write value
        when STATE_WRITE_DATA =>
          o_RAMWE   <= '1';
			 if ( unsigned('0' & ptr) >= unsigned(ptr_max) ) then
				done <= '1';
				state <= STATE_IDLE;
			 else
			   --internal reset
				accu				:= (others => '0');
				remainder		:= (others => '0');
				trial_product	:= (others => '0');
				bits				:= 0;
				
				--next State
				state <= STATE_INC_ADDR;
          end if;
			 
        when STATE_INC_ADDR =>
			 ptr   <= ptr + 1;
			 state <= STATE_WAIT_2;
			 
		  when STATE_WAIT_2 =>
			 state <= STATE_GET_DATA;
			 
		  when others =>
          state <= STATE_IDLE;

      end case;
		
    end if;
	 
  end process;

end Behavioral;
