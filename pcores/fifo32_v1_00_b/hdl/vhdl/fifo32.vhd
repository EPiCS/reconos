library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32 is
	generic (
		C_FIFO32_DEPTH  : integer := 2048;
		C_ENABLE_ILA    : integer := 0
	);
	port (
		Rst : in std_logic;
		FIFO32_S_Clk : in std_logic;
		FIFO32_M_Clk : in std_logic;
		FIFO32_S_Data : out std_logic_vector(31 downto 0);
		FIFO32_M_Data : in std_logic_vector(31 downto 0);
		FIFO32_S_Fill : out std_logic_vector(15 downto 0);
		FIFO32_M_Rem : out std_logic_vector(15 downto 0);
		FIFO32_S_Rd : in std_logic;
		FIFO32_M_Wr : in std_logic
	);
end entity;

architecture implementation of fifo32 is

	component fifo32b_icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
	end component;

	component fifo32b_ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	end component;

	signal CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal DATA    : STD_LOGIC_VECTOR(255 DOWNTO 0);
	signal TRIG    : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	function incptr(v : std_logic_vector) return std_logic_vector is
		variable result : std_logic_vector (v'length-1 downto 0);
	begin
		if v = C_FIFO32_DEPTH-1 then
			result := (others => '0');
		else
			result :=  v + 1;
		end if;
		return result;
	end;

	type MEM_T is array (0 to C_FIFO32_DEPTH-1) of std_logic_vector(31 downto 0);
	signal mem : MEM_T;
	
	signal wrptr : std_logic_vector(clog2(C_FIFO32_DEPTH)-1 downto 0);
	signal rdptr : std_logic_vector(clog2(C_FIFO32_DEPTH)-1 downto 0);
	signal remainder : std_logic_vector(clog2(C_FIFO32_DEPTH)-1  downto 0);
	signal fill      : std_logic_vector(clog2(C_FIFO32_DEPTH)-1  downto 0);
	signal pad       : std_logic_vector(15 - clog2(C_FIFO32_DEPTH) downto 0);
	signal clk       : std_logic;
	
	signal FIFO32_S_Data_out : std_logic_vector(31 downto 0);
	signal FIFO32_S_Fill_out : std_logic_vector(15 downto 0);
	signal FIFO32_M_Rem_out  : std_logic_vector(15 downto 0);
begin

--------------------- CHIPSCOPE -------------------------
	
	GENERATE_ILA : if C_ENABLE_ILA = 1 generate

	icon_i : fifo32b_icon
	port map (
		CONTROL0 => CONTROL
	);
	
	ila_i : fifo32b_ila
	port map (
		CONTROL => CONTROL,
		CLK => clk,
		DATA => DATA,
		TRIG0 => TRIG
	);

	end generate;
	
	DATA(0) <= Rst;
	DATA(1) <= FIFO32_S_Rd;
	DATA(2) <= FIFO32_M_wr;

	DATA(31 downto 12) <= (others => '0');
	DATA(47 downto 32) <= FIFO32_S_Fill_out;
	DATA(63 downto 48) <= FIFO32_M_Rem_out;
	DATA(95 downto 64) <= FIFO32_S_Data_out;
	DATA(127 downto 96) <= FIFO32_M_Data;
	DATA(143 downto 128) <= pad & rdptr;
	DATA(159 downto 144) <= pad & wrptr;



	
	TRIG <= DATA(15 downto 0);

---------------------------------------------------------

	FIFO32_S_Data <= FIFO32_S_Data_out;
	FIFO32_S_Fill <= FIFO32_S_Fill_out;
	FIFO32_M_Rem  <= FIFO32_M_Rem_out;

	clk <= FIFO32_M_Clk;
	
	pad <= (others => '0');

	FIFO32_S_Fill_out <= pad & fill;
	FIFO32_M_Rem_out  <= pad & remainder;
	

        fillAndRemainder: process(rst,clk)
        begin
          if rst='1' then
            fill <= (others => '0');
	    remainder <= CONV_STD_LOGIC_VECTOR(C_FIFO32_DEPTH - 1,remainder'length);
          elsif rising_edge(clk) then
            -- FIFO empties when read
            if FIFO32_M_Wr = '0' and FIFO32_S_Rd = '1' then
	    	fill <= fill - 1;
                remainder <= remainder + 1;
            end if;

            -- FIFO fills when written
	    if FIFO32_M_Wr = '1' and FIFO32_S_Rd = '0' then
	      fill <= fill + 1;
	      remainder <= remainder - 1;
	    end if;

            -- In all other cases FIFO fill level remains the same.
          end if;
        end process;
        
	write2ram: process(clk, rst)
	begin
		if rst = '1' then
			wrptr <= (others => '0');
       		elsif rising_edge(clk) then
			if FIFO32_M_Wr = '1' then
				mem(CONV_INTEGER(wrptr)) <= FIFO32_M_Data;
				wrptr <= incptr(wrptr);
			end if;
		end if;
	end process;
	
	-- This works just fine in simulation:
	--
	-- do <= mem(CONV_INTEGER(rdptr_syn));
	--
	-- Together with the process above this specifies a write-first dual port ram.
	-- According to the xilinx xst documentation the ram will be implemented using
	-- block ram resources.
	--
	-- Unfortunately, while a block ram implementation is indeed infered during synthesis,
	-- it will not implement write-first access (which contradicts the plain vhdl specification).
	-- This is a subtle bug that can be hard to find and can cost you days of debugging.
	-- This workaround implements write-first access in a way that works with xst:

-- We implement a FIFO which means we need a Dual port memory: One port for
-- writing, another for reading. This way, writes and reads can happen to
-- different addresses. However, the Xilinx Documentation (ug363, p. 17f ) limits accesses from
-- both ports to the same address at the same time: 
        
--Both Ports Asynchronously clocked:
--When one port performs a write operation,
--the other port must not read- or write-
--access the exact same memory location be
--cause all address bits are identical. The
--simulation model will produce an error if this condition is violated. If this restriction
--is ignored, the output read data will be
--unknown (unpredictable). There is, however,
--no risk of physical damage to the device. If a read and write operation is performed,
--then the write will store valid data at the write location. 


--Both Ports Synchronously Clocked :        
--When one port performs a write operation,
--the write operation succeeds; the other
--port can reliably read data from the same lo
--cation if the write port is in READ_FIRST
--mode. DATA_OUT on both ports will then reflect the previously stored data.
--If the write port is in either WRITE_FIRST or in NO_CHANGE mode, then the
--DATA_OUT on the read port would become invalid (unreliable). The mode setting of
--the read-port does not affect this operation.

-- So clearly the Documentation forbids accesses to the same address at the
-- same time completely, or limits it to READ_FIRST mode.
-- Anyhow, is there a need for WRITE_FIRST behaviour?
-- When read and write address are the same, the fifo is empty. read points to
-- the first data word to read and write points to the next empty address. When
-- both addresses are the same, either the fifo is empty, thus the read address
-- being invalid, or the fifo is full, thus the write address being invalid. A
-- simultanious read and write in this situation is invalid anyway.
-- This seems like a minor performance optimization, which incurs alot complexity.

      	FIFO32_S_Data_out <= mem(CONV_INTEGER(rdptr));
        readFromRam: process(clk, rst)
	begin
		if rst = '1' then
			rdptr <= (others => '0');
       		elsif rising_edge(clk) then

			if FIFO32_S_Rd = '1' then
				rdptr <= incptr(rdptr);
			end if;
		end if;
	end process;

end architecture;

