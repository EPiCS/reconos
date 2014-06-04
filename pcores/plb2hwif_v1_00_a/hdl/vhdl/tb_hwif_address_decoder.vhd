-- TestBench Template 

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

  library work;
  use work.hwif_address_decoder;
  use work.hwif_pck.all;

  ENTITY tb_hwif_address_decoder IS
  END;

  ARCHITECTURE behavior OF tb_hwif_address_decoder IS 
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
    
    signal tb_DEC2SUB_A_Addr  : std_logic_vector(0 to 31);
    signal tb_DEC2SUB_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_DEC2SUB_A_RdCE  : std_logic;
    signal tb_DEC2SUB_A_WrCE  : std_logic;
    signal tb_SUB2DEC_A_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_SUB2DEC_A_RdAck : std_logic;
    signal tb_SUB2DEC_A_WrAck : std_logic;
    
    signal tb_DEC2SUB_B_Addr  : std_logic_vector(0 to 31);
    signal tb_DEC2SUB_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_DEC2SUB_B_RdCE  : std_logic;
    signal tb_DEC2SUB_B_WrCE  : std_logic;
    signal tb_SUB2DEC_B_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_SUB2DEC_B_RdAck : std_logic;
    signal tb_SUB2DEC_B_WrAck : std_logic;

    signal tb_DEC2SUB_C_Addr  : std_logic_vector(0 to 31);
    signal tb_DEC2SUB_C_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_DEC2SUB_C_RdCE  : std_logic;
    signal tb_DEC2SUB_C_WrCE  : std_logic;
    signal tb_SUB2DEC_C_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_SUB2DEC_C_RdAck : std_logic;
    signal tb_SUB2DEC_C_WrAck : std_logic;
    
    signal tb_DEC2SUB_D_Addr  : std_logic_vector(0 to 31);
    signal tb_DEC2SUB_D_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_DEC2SUB_D_RdCE  : std_logic;
    signal tb_DEC2SUB_D_WrCE  : std_logic;
    signal tb_SUB2DEC_D_Data  : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    signal tb_SUB2DEC_D_RdAck : std_logic;
    signal tb_SUB2DEC_D_WrAck : std_logic;
  BEGIN

  ad: entity work.hwif_address_decoder
 generic map (
    C_ADDR_RANGE_ARRAY => (X"00000000", X"000000FF",X"00000100", X"000001FF",X"00000200", X"000002FF",X"00000300", X"000003FF"),
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
    DEC2SUB_A_Addr  => tb_DEC2SUB_A_Addr,
    DEC2SUB_A_Data  => tb_DEC2SUB_A_Data,
    DEC2SUB_A_RdCE  => tb_DEC2SUB_A_RdCE,
    DEC2SUB_A_WrCE  => tb_DEC2SUB_A_WrCE,
    SUB2DEC_A_Data  => tb_SUB2DEC_A_Data,
    SUB2DEC_A_RdAck => tb_SUB2DEC_A_RdAck,
    SUB2DEC_A_WrAck => tb_SUB2DEC_A_WrAck,
    
    DEC2SUB_B_Addr  => tb_DEC2SUB_B_Addr,
    DEC2SUB_B_Data  => tb_DEC2SUB_B_Data,
    DEC2SUB_B_RdCE  => tb_DEC2SUB_B_RdCE,
    DEC2SUB_B_WrCE  => tb_DEC2SUB_B_WrCE,
    SUB2DEC_B_Data  => tb_SUB2DEC_B_Data,
    SUB2DEC_B_RdAck => tb_SUB2DEC_B_RdAck,
    SUB2DEC_B_WrAck => tb_SUB2DEC_B_WrAck,
    
    DEC2SUB_C_Addr  => tb_DEC2SUB_C_Addr,
    DEC2SUB_C_Data  => tb_DEC2SUB_C_Data,
    DEC2SUB_C_RdCE  => tb_DEC2SUB_C_RdCE,
    DEC2SUB_C_WrCE  => tb_DEC2SUB_C_WrCE,
    SUB2DEC_C_Data  => tb_SUB2DEC_C_Data,
    SUB2DEC_C_RdAck => tb_SUB2DEC_C_RdAck,
    SUB2DEC_C_WrAck => tb_SUB2DEC_C_WrAck,
    
    DEC2SUB_D_Addr  => tb_DEC2SUB_D_Addr,
    DEC2SUB_D_Data  => tb_DEC2SUB_D_Data,
    DEC2SUB_D_RdCE  => tb_DEC2SUB_D_RdCE,
    DEC2SUB_D_WrCE  => tb_DEC2SUB_D_WrCE,
    SUB2DEC_D_Data  => tb_SUB2DEC_D_Data,
    SUB2DEC_D_RdAck => tb_SUB2DEC_D_RdAck,
    SUB2DEC_D_WrAck => tb_SUB2DEC_D_WrAck    
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

   sub_a: process(clk, tb_DEC2SUB_A_Addr,tb_DEC2SUB_A_Data,tb_DEC2SUB_A_RdCE,tb_DEC2SUB_A_WrCE)
   is
   begin
      if rst = '1' then
        regfile_a <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC_A_WrAck <= '0';
        tb_SUB2DEC_A_RdAck <= '0';
        -- RO Registers
        if (tb_DEC2SUB_A_RdCE or tb_DEC2SUB_A_WrCE) = '1' then
          if tb_DEC2SUB_A_WrCE = '1' then
           regfile_a(to_integer(unsigned(tb_DEC2SUB_A_Addr(24 to 31)))) <= tb_DEC2SUB_A_Data;
           tb_SUB2DEC_A_WrAck <= '1';
          end if;
          if tb_DEC2SUB_A_RdCE = '1' then
            tb_SUB2DEC_A_RdAck <= '1';
          end if;
          tb_SUB2DEC_A_Data <= regfile_a(to_integer(unsigned(tb_DEC2SUB_A_Addr(24 to 31))));
        end if;
      end if;
   end process;
   
   sub_b: process(clk, tb_DEC2SUB_b_Addr,tb_DEC2SUB_b_Data,tb_DEC2SUB_b_RdCE,tb_DEC2SUB_b_WrCE)
   is
   begin
      if rst = '1' then
        regfile_b <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC_b_WrAck <= '0';
        tb_SUB2DEC_b_RdAck <= '0';
        -- RO Registers
        if (tb_DEC2SUB_b_RdCE or tb_DEC2SUB_b_WrCE) = '1' then
          if tb_DEC2SUB_b_WrCE = '1' then
           regfile_b(to_integer(unsigned(tb_DEC2SUB_b_Addr(24 to 31)))) <= tb_DEC2SUB_b_Data;
           tb_SUB2DEC_b_WrAck <= '1';
          end if;
          if tb_DEC2SUB_b_RdCE = '1' then
            tb_SUB2DEC_b_RdAck <= '1';
          end if;
          tb_SUB2DEC_b_Data <= regfile_b(to_integer(unsigned(tb_DEC2SUB_b_Addr(24 to 31))));
        end if;
      end if;
   end process;
  
  sub_c: process(clk, tb_DEC2SUB_c_Addr,tb_DEC2SUB_c_Data,tb_DEC2SUB_c_RdCE,tb_DEC2SUB_c_WrCE)
   is
   begin
      if rst = '1' then
        regfile_c <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC_c_WrAck <= '0';
        tb_SUB2DEC_c_RdAck <= '0';
        -- RO Registers
        if (tb_DEC2SUB_c_RdCE or tb_DEC2SUB_c_WrCE) = '1' then
          if tb_DEC2SUB_c_WrCE = '1' then
           regfile_c(to_integer(unsigned(tb_DEC2SUB_c_Addr(24 to 31)))) <= tb_DEC2SUB_c_Data;
           tb_SUB2DEC_c_WrAck <= '1';
          end if;
          if tb_DEC2SUB_c_RdCE = '1' then
            tb_SUB2DEC_c_RdAck <= '1';
          end if;
          tb_SUB2DEC_c_Data <= regfile_c(to_integer(unsigned(tb_DEC2SUB_c_Addr(24 to 31))));
        end if;
      end if;
   end process;
  
  sub_d: process(clk, tb_DEC2SUB_d_Addr,tb_DEC2SUB_d_Data,tb_DEC2SUB_d_RdCE,tb_DEC2SUB_d_WrCE)
   is
   begin
      if rst = '1' then
        regfile_d <= (others => (others => '0'));
      elsif clk'event and clk = '1' then
        tb_SUB2DEC_d_WrAck <= '0';
        tb_SUB2DEC_d_RdAck <= '0';
        -- RO Registers
        if (tb_DEC2SUB_d_RdCE or tb_DEC2SUB_d_WrCE) = '1' then
          if tb_DEC2SUB_d_WrCE = '1' then
           regfile_d(to_integer(unsigned(tb_DEC2SUB_d_Addr(24 to 31)))) <= tb_DEC2SUB_d_Data;
           tb_SUB2DEC_d_WrAck <= '1';
          end if;
          if tb_DEC2SUB_d_RdCE = '1' then
            tb_SUB2DEC_d_RdAck <= '1';
          end if;
          tb_SUB2DEC_d_Data <= regfile_d(to_integer(unsigned(tb_DEC2SUB_d_Addr(24 to 31))));
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
