-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  library proc_common_v3_00_a;
  use proc_common_v3_00_a.proc_common_pkg.all;
  use proc_common_v3_00_a.ipif_pkg.all;
  
  library plb2hwif_v1_00_a;
  use plb2hwif_v1_00_a.hwif_pck.all;
  use plb2hwif_v1_00_a.hwif_address_decoder;
  
  ENTITY tb_hwif_address_decoder IS
  END;

  ARCHITECTURE behavior OF tb_hwif_address_decoder IS
    constant C_ADDR_RANGE_ARRAY : SLV32_ARRAY_TYPE := (X"00000000", X"000000FF",X"00000100", X"000001FF",X"00000200", X"000002FF",X"00000300", X"000003FF");
    constant C_SLV_DWIDTH: integer := 32; 
    signal rst: std_logic;
    signal clk: std_logic;
    
    type slv32_array is array (integer range<>) of std_logic_vector(31 downto 0);
    signal regfile_a: slv32_array(0 to 255);
    signal regfile_b: slv32_array(0 to 255);
    signal regfile_c: slv32_array(0 to 255);
    signal regfile_d: slv32_array(0 to 255);
    
    signal tb_HWIF2DEC_Addr  : std_logic_vector(0 to 31);
    signal tb_HWIF2DEC_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_HWIF2DEC_RdCE  : std_logic;
    signal tb_HWIF2DEC_WrCE  : std_logic;
    signal tb_DEC2HWIF_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_DEC2HWIF_RdAck : std_logic;
    signal tb_DEC2HWIF_WrAck : std_logic;        

    signal tb_DEC2SUB: master2slave_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
    signal tb_SUB2DEC: slave2master_array_t(0 to (C_ADDR_RANGE_ARRAY'length/2)-1);
      
  BEGIN

  ad: entity work.hwif_address_decoder
 generic map (
    C_ADDR_RANGE_ARRAY => C_ADDR_RANGE_ARRAY,
    C_SLV_DWIDTH       => 32
    )
  port map(
    -- HWIF interface
    HWIF2DEC_Addr  => tb_HWIF2DEC_Addr,
    HWIF2DEC_Data  => tb_HWIF2DEC_Data,
    HWIF2DEC_RdCE  => tb_HWIF2DEC_RdCE,
    HWIF2DEC_WrCE  => tb_HWIF2DEC_WrCE,
    DEC2HWIF_Data  => tb_DEC2HWIF_Data,
    DEC2HWIF_RdAck => tb_DEC2HWIF_RdAck,
    DEC2HWIF_WrAck => tb_DEC2HWIF_WrAck,
    
    -- sub-module interfaces
    DEC2SUB => tb_DEC2SUB,
    SUB2DEC => tb_SUB2DEC 
    );
  
   reset: process
   begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
   end process;

   clock: process
   begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
    
   end process;

   sub_a: process(clk, tb_DEC2SUB(0).address,tb_DEC2SUB(0).Data_in,tb_DEC2SUB(0).Read_CE,tb_DEC2SUB(0).Write_CE)
   is
   begin
      if rst = '1' then
        regfile_a <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC(0).Write_Ack <= '0';
        tb_SUB2DEC(0).Read_Ack <= '0';
        -- RO Registers
        if (tb_DEC2SUB(0).Read_CE or tb_DEC2SUB(0).Write_CE) = '1' then
          if tb_DEC2SUB(0).Write_CE = '1' then
           regfile_a(to_integer(unsigned(tb_DEC2SUB(0).address(24 to 31)))) <= tb_DEC2SUB(0).Data_in;
           tb_SUB2DEC(0).Write_Ack <= '1';
          end if;
          if tb_DEC2SUB(0).Read_CE = '1' then
            tb_SUB2DEC(0).Read_Ack <= '1';
          end if;
          tb_SUB2DEC(0).Data_out <= regfile_a(to_integer(unsigned(tb_DEC2SUB(0).address(24 to 31))));
        end if;
      end if;
   end process;
   
   sub_b: process(clk, tb_DEC2SUB(1).address,tb_DEC2SUB(1).Data_in,tb_DEC2SUB(1).Read_CE,tb_DEC2SUB(1).Write_CE)
   is
   begin
      if rst = '1' then
        regfile_b <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC(1).Write_Ack <= '0';
        tb_SUB2DEC(1).Read_Ack <= '0';
        -- RO Registers
        if (tb_DEC2SUB(1).Read_CE or tb_DEC2SUB(1).Write_CE) = '1' then
          if tb_DEC2SUB(1).Write_CE = '1' then
           regfile_b(to_integer(unsigned(tb_DEC2SUB(1).address(24 to 31)))) <= tb_DEC2SUB(1).Data_in;
           tb_SUB2DEC(1).Write_Ack <= '1';
          end if;
          if tb_DEC2SUB(1).Read_CE = '1' then
            tb_SUB2DEC(1).Read_Ack <= '1';
          end if;
          tb_SUB2DEC(1).Data_out <= regfile_b(to_integer(unsigned(tb_DEC2SUB(1).address(24 to 31))));
        end if;
      end if;
   end process;
  
  sub_c: process(clk, tb_DEC2SUB(2).address,tb_DEC2SUB(2).Data_in,tb_DEC2SUB(2).Read_CE,tb_DEC2SUB(2).Write_CE)
   is
   begin
      if rst = '1' then
        regfile_c <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC(2).Write_Ack <= '0';
        tb_SUB2DEC(2).Read_Ack <= '0';
        -- RO Registers
        if (tb_DEC2SUB(2).Read_CE or tb_DEC2SUB(2).Write_CE) = '1' then
          if tb_DEC2SUB(2).Write_CE = '1' then
           regfile_c(to_integer(unsigned(tb_DEC2SUB(2).address(24 to 31)))) <= tb_DEC2SUB(2).Data_in;
           tb_SUB2DEC(2).Write_Ack <= '1';
          end if;
          if tb_DEC2SUB(2).Read_CE = '1' then
            tb_SUB2DEC(2).Read_Ack <= '1';
          end if;
          tb_SUB2DEC(2).Data_out <= regfile_c(to_integer(unsigned(tb_DEC2SUB(2).address(24 to 31))));
        end if;
      end if;
   end process;
  
  sub_d: process(clk, tb_DEC2SUB(3).address,tb_DEC2SUB(3).Data_in,tb_DEC2SUB(3).Read_CE,tb_DEC2SUB(3).Write_CE)
   is
   begin
      if rst = '1' then
        regfile_d <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC(3).Write_Ack <= '0';
        tb_SUB2DEC(3).Read_Ack <= '0';
        -- RO Registers
        if (tb_DEC2SUB(3).Read_CE or tb_DEC2SUB(3).Write_CE) = '1' then
          if tb_DEC2SUB(3).Write_CE = '1' then
           regfile_d(to_integer(unsigned(tb_DEC2SUB(3).address(24 to 31)))) <= tb_DEC2SUB(3).Data_in;
           tb_SUB2DEC(3).Write_Ack <= '1';
          end if;
          if tb_DEC2SUB(3).Read_CE = '1' then
            tb_SUB2DEC(3).Read_Ack <= '1';
          end if;
          tb_SUB2DEC(3).Data_out <= regfile_d(to_integer(unsigned(tb_DEC2SUB(3).address(24 to 31))));
        end if;
      end if;
   end process;
  
   hwif : PROCESS
   BEGIN
     tb_HWIF2DEC_Addr <= X"00000000";
     tb_HWIF2DEC_Data <= X"00000000";
     tb_HWIF2DEC_RdCE <= '0';
     tb_HWIF2DEC_WrCE <= '0';
     wait for 30 ns; -- reset and adaption to rising clock
    -- Write data
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000000" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"AAAAAA" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_RdCE <= '0';
     tb_HWIF2DEC_WrCE <= '1';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000001" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"BBBBBB" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_RdCE <= '0';
     tb_HWIF2DEC_WrCE <= '1';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000002" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"CCCCCC" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_RdCE <= '0';
     tb_HWIF2DEC_WrCE <= '1';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000003" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"DDDDDD" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_RdCE <= '0';
     tb_HWIF2DEC_WrCE <= '1';
     wait for 20 ns;
     end loop;
     
     -- read data
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000000" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"00000000";
     tb_HWIF2DEC_RdCE <= '1';
     tb_HWIF2DEC_WrCE <= '0';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000001" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"00000000";
     tb_HWIF2DEC_RdCE <= '1';
     tb_HWIF2DEC_WrCE <= '0';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000002" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"00000000";
     tb_HWIF2DEC_RdCE <= '1';
     tb_HWIF2DEC_WrCE <= '0';
     wait for 20 ns;
     end loop;
     
     for i in 0 to 16 loop
     tb_HWIF2DEC_Addr <= X"000003" & std_logic_vector(to_unsigned(i, 8));
     tb_HWIF2DEC_Data <= X"00000000";
     tb_HWIF2DEC_RdCE <= '1';
     tb_HWIF2DEC_WrCE <= '0';
     wait for 20 ns;
     end loop;
     
     wait; -- will wait forever
   END PROCESS;


  END;
