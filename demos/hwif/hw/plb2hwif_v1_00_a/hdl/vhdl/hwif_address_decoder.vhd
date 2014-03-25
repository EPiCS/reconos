----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:35:33 02/25/2014 
-- Design Name: 
-- Module Name:    hwif_address_decoder - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library work;
use work.hwif_pck.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwif_address_decoder is
 generic(
    C_ADDR_RANGE_ARRAY : SLV32_ARRAY_TYPE := (X"00000000", X"00000FF",X"00000100", X"00001FF",X"00000200", X"00002FF",X"00000300", X"00003FF");
    C_SLV_DWIDTH   : integer := 32
    );
  port (
    -- HWIF interface
    HWIF2DEC_Addr  : in  std_logic_vector(0 to 31);
    HWIF2DEC_Data  : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    HWIF2DEC_RdCE  : in  std_logic;
    HWIF2DEC_WrCE  : in  std_logic;
    DEC2HWIF_Data  : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2HWIF_RdAck : out std_logic;
    DEC2HWIF_WrAck : out std_logic;
    
    -- sub-module interfaces
    DEC2SUB_A_Addr  : out  std_logic_vector(0 to 31);
    DEC2SUB_A_Data  : out  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2SUB_A_RdCE  : out  std_logic;
    DEC2SUB_A_WrCE  : out  std_logic;
    SUB2DEC_A_Data  : in   std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    SUB2DEC_A_RdAck : in   std_logic;
    SUB2DEC_A_WrAck : in   std_logic;
    
    DEC2SUB_B_Addr  : out  std_logic_vector(0 to 31);
    DEC2SUB_B_Data  : out  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2SUB_B_RdCE  : out  std_logic;
    DEC2SUB_B_WrCE  : out  std_logic;
    SUB2DEC_B_Data  : in   std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    SUB2DEC_B_RdAck : in   std_logic;
    SUB2DEC_B_WrAck : in   std_logic;
    
    DEC2SUB_C_Addr  : out  std_logic_vector(0 to 31);
    DEC2SUB_C_Data  : out  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2SUB_C_RdCE  : out  std_logic;
    DEC2SUB_C_WrCE  : out  std_logic;
    SUB2DEC_C_Data  : in   std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    SUB2DEC_C_RdAck : in   std_logic;
    SUB2DEC_C_WrAck : in   std_logic;

    DEC2SUB_D_Addr  : out  std_logic_vector(0 to 31);
    DEC2SUB_D_Data  : out  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    DEC2SUB_D_RdCE  : out  std_logic;
    DEC2SUB_D_WrCE  : out  std_logic;
    SUB2DEC_D_Data  : in   std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    SUB2DEC_D_RdAck : in   std_logic;
    SUB2DEC_D_WrAck : in   std_logic
    );
end hwif_address_decoder;

architecture Behavioral of hwif_address_decoder is

  signal mux_in: std_logic_vector(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);

  signal HWIF2DEC  : master2slave_t;
  signal DEC2SUB   : master2slave_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);

  signal SUB2DEC  : slave2master_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
  signal DEC2HWIF : slave2master_t;
      
begin

HWIF2DEC.address  <= HWIF2DEC_Addr;
HWIF2DEC.data_in  <= HWIF2DEC_Data;
HWIF2DEC.read_ce  <= HWIF2DEC_RdCE;
HWIF2DEC.write_ce <= HWIF2DEC_WrCE;
DEC2HWIF_Data  <= DEC2HWIF.data_out;
DEC2HWIF_RdAck <= DEC2HWIF.read_ack;
DEC2HWIF_WrAck <= DEC2HWIF.write_ack;

A: if (C_ADDR_RANGE_ARRAY'length/2) > 0 generate
DEC2SUB_A_Addr <= DEC2SUB(0).address;
DEC2SUB_A_Data <= DEC2SUB(0).data_in;
DEC2SUB_A_RdCE <= DEC2SUB(0).read_ce;
DEC2SUB_A_WrCE <= DEC2SUB(0).write_ce;
SUB2DEC(0).data_out <= SUB2DEC_A_Data;
SUB2DEC(0).read_ack <= SUB2DEC_A_RdAck;
SUB2DEC(0).write_ack <= SUB2DEC_A_WrAck;
end generate;

B: if (C_ADDR_RANGE_ARRAY'length/2) > 1 generate
DEC2SUB_B_Addr <= DEC2SUB(1).address;
DEC2SUB_B_Data <= DEC2SUB(1).data_in;
DEC2SUB_B_RdCE <= DEC2SUB(1).read_ce;
DEC2SUB_B_WrCE <= DEC2SUB(1).write_ce;
SUB2DEC(1).data_out <= SUB2DEC_B_Data;
SUB2DEC(1).read_ack <= SUB2DEC_B_RdAck;
SUB2DEC(1).write_ack <= SUB2DEC_B_WrAck;
end generate;

C: if (C_ADDR_RANGE_ARRAY'length/2) > 2 generate
DEC2SUB_C_Addr <= DEC2SUB(2).address;
DEC2SUB_C_Data <= DEC2SUB(2).data_in;
DEC2SUB_C_RdCE <= DEC2SUB(2).read_ce;
DEC2SUB_C_WrCE <= DEC2SUB(2).write_ce;
SUB2DEC(2).data_out <= SUB2DEC_C_Data;
SUB2DEC(2).read_ack <= SUB2DEC_C_RdAck;
SUB2DEC(2).write_ack <= SUB2DEC_C_WrAck;
end generate;

D: if (C_ADDR_RANGE_ARRAY'length/2) > 3 generate
DEC2SUB_D_Addr <= DEC2SUB(3).address;
DEC2SUB_D_Data <= DEC2SUB(3).data_in;
DEC2SUB_D_RdCE <= DEC2SUB(3).read_ce;
DEC2SUB_D_WrCE <= DEC2SUB(3).write_ce;
SUB2DEC(3).data_out <= SUB2DEC_D_Data;
SUB2DEC(3).read_ack <= SUB2DEC_D_RdAck;
SUB2DEC(3).write_ack <= SUB2DEC_D_WrAck;
end generate;

-- analyze address according to address map
-- mux_in is one-hot coded
mux_control: process (HWIF2DEC_Addr)
begin
  mux_in <= (others => '0');
  for i in 0 to (C_ADDR_RANGE_ARRAY'length/2)-1 loop
    if HWIF2DEC_Addr >= C_ADDR_RANGE_ARRAY(2*i) and HWIF2DEC_Addr <= C_ADDR_RANGE_ARRAY(2*i+1) then 
      mux_in(i) <= '1';
    end if;
  end loop;
end process;

-- route request to specified port
mux: process(mux_in,hwif2dec,sub2dec)
begin
  DEC2HWIF <= S2M_ALL_ZEROS;
  for i in 0 to (C_ADDR_RANGE_ARRAY'length/2)-1 loop
    DEC2SUB(i)  <= M2S_ALL_ZEROS;
    if mux_in(i) = '1' then
      DEC2SUB(i)<= HWIF2DEC;
      DEC2SUB(i).address <= std_logic_vector(unsigned(HWIF2DEC.address) - unsigned(C_ADDR_RANGE_ARRAY(2*i)));
      DEC2HWIF  <= SUB2DEC(i);
    end if;
  end loop;
end process;
end Behavioral;

