-----------------------------------------------------------------------------
---**************************************************************************
---***conversion from YUV color space to RGB color space                  ***
---***Author:     Yujiao                                                  ***
---***Date:       05.2013                                                 ***
---**************************************************************************
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;


entity yuv_to_rgb is
 generic
  (
    -- ---------------------
    YUV_DATA_DWIDTH                   : integer              := 16;
    RGB_DATA_DWIDTH                   : integer              := 24
    --FRAME_WIDTH                       : integer              := 1920;
    --FRAME__HEIGHT                     : integer              := 1080
  );
 port
  (
    clk                       : in  std_logic;
    rst                       : in  std_logic;
	 switch_r                  : in  std_logic;
	 switch_g                  : in  std_logic;
	 switch_b                  : in  std_logic;
	 switch_uv                 : in  std_logic;
    yuv_data_in               : in  std_logic_vector(YUV_DATA_DWIDTH-1 downto 0);
    rgb_data_out              : out  std_logic_vector(RGB_DATA_DWIDTH-1 downto 0);
    yuv2rgb_in_vblank         : in  std_logic;
	 yuv2rgb_in_hblank         : in  std_logic;
	 yuv2rgb_in_de             : in  std_logic;
	 yuv2rgb_out_vblank        : out  std_logic;
	 yuv2rgb_out_hblank        : out  std_logic;
	 yuv2rgb_out_de            : out  std_logic
    
  );

  attribute SIGIS             : string;
  attribute SIGIS of clk      : signal is "CLK";
  attribute SIGIS of rst      : signal is "RST";

end entity yuv_to_rgb;


------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------
architecture IMP of yuv_to_rgb is


--  component chipscope_icon
--  port (
--    control0 : inout std_logic_vector(35 downto 0));
--  end component;
--  
--  component chipscope_ila
--  port (
--    control : inout std_logic_vector(35 downto 0);
--    clk   : in std_logic;
--    trig0 : in std_logic_vector(15 downto 0);
--    trig1 : in std_logic_vector(15 downto 0);
--    trig2 : in std_logic_vector(23 downto 0);
--    trig3 : in std_logic_vector(23 downto 0);
--    trig4 : in std_logic_vector(31 downto 0);
--    trig5 : in std_logic_vector(15 downto 0);
--    trig6 : in std_logic_vector(23 downto 0);
--    trig7 : in std_logic_vector(7 downto 0);
--    trig8 : in std_logic_vector(47 downto 0));
--  end component;

  
  constant C_DELAY : integer := 4; --yujiao: 2 clock cycle delay


  ------------------------------------------
  -- signal declarations
  -- signal declarations
  ------------------------------------------
  signal last_signal                     : std_logic_vector(YUV_DATA_DWIDTH-1 downto 0) := (others => '0');   ---input temp 
  signal current_signal                  : std_logic_vector(YUV_DATA_DWIDTH-1 downto 0) := (others => '0');   ---input temp 
  signal last_pixel                      : std_logic_vector(RGB_DATA_DWIDTH-1 downto 0) := (others => '0');   ---output temp 
  signal current_pixel                   : std_logic_vector(RGB_DATA_DWIDTH-1 downto 0) := (others => '0');   ---output temp 
  signal data_in_en                      : std_logic := '1';
  signal data_temp 			              : std_logic_vector(31 downto 0) := (others => '0');
  signal high_r_out                      : std_logic_vector(8 downto 0) := (others => '0');
  signal high_g_out                      : std_logic_vector(8 downto 0) := (others => '0');
  signal high_b_out                      : std_logic_vector(8 downto 0) := (others => '0');
  signal low_r_out                       : std_logic_vector(8 downto 0) := (others => '0');
  signal low_g_out                       : std_logic_vector(8 downto 0) := (others => '0');
  signal low_b_out                       : std_logic_vector(8 downto 0) := (others => '0');
  
  signal vblank_delay : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');
  signal hblank_delay : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');
  signal de_delay     : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');
  
  signal dummy_out : std_logic_vector(RGB_DATA_DWIDTH-1 downto 0); 
  signal trig7 : std_logic_vector(7 downto 0);
  signal trig8 : std_logic_vector(47 downto 0);
  signal dummy_g : std_logic := '0';

  signal control : std_logic_vector(35 downto 0);
 

begin
   
	yuv2rgb_out_vblank <= vblank_delay(0);  --yuv2rgb_in_vblank;
   yuv2rgb_out_hblank <= hblank_delay(0);  --yuv2rgb_in_hblank;
   yuv2rgb_out_de     <= de_delay(0);      --yuv2rgb_in_de;
	
	delay_control_signals : process(clk) is
	begin
		if (rising_edge(clk)) then	
		   vblank_delay(C_DELAY-1 downto 0) <= yuv2rgb_in_vblank & vblank_delay(C_DELAY-1 downto 1);
			hblank_delay(C_DELAY-1 downto 0) <= yuv2rgb_in_hblank & hblank_delay(C_DELAY-1 downto 1);
			de_delay(C_DELAY-1 downto 0)     <= yuv2rgb_in_de     &     de_delay(C_DELAY-1 downto 1);
		end if;
	end process;

--	my_chipscope_icon : chipscope_icon
--		 port map (
--		 control0 => control);
-- 
--	 my_chipscope_ila : chipscope_ila
--	  port map (
--		 control => control,
--		 clk => clk,
--		 trig0 => last_signal,
--		 trig1 => current_signal,
--		 trig2 => last_pixel,
--		 trig3 => current_pixel,
--		 trig4 => data_temp,
--		 trig5 => yuv_data_in,
--		 trig6 => dummy_out,
--		 trig7 => trig7,
--		 trig8 => trig8);
-- 
--
--   trig8 <= (others => '0');
--	trig7 <= "000" & data_in_en & rst & dummy_g  & "00"; 

  -- implement 
  yuv2rgb : process( clk, rst, switch_r, switch_g, switch_b, data_in_en)  is
    ------------------------------------------
  -- variable declarations
  -- variable declarations
  variable high_y                            : std_logic_vector(8 downto 0) := (others => '0');
  variable high_y_for_g                      : std_logic_vector(8 downto 0) := (others => '0');
  variable u                                 : std_logic_vector(8 downto 0) := (others => '0');
  variable v                                 : std_logic_vector(8 downto 0) := (others => '0');
  variable low_y                             : std_logic_vector(8 downto 0) := (others => '0');
  variable low_y_for_g                       : std_logic_vector(8 downto 0) := (others => '0');
  --variable low_u                             : std_logic_vector(8 downto 0) := (others => '0');
  --variable low_v                             : std_logic_vector(8 downto 0) := (others => '0');  
  variable high_r                            : std_logic_vector(8 downto 0) := (others => '0');
  variable high_g                            : std_logic_vector(8 downto 0) := (others => '0');
  variable high_b                            : std_logic_vector(8 downto 0) := (others => '0');
  variable low_r                             : std_logic_vector(8 downto 0) := (others => '0');
  variable low_g                             : std_logic_vector(8 downto 0) := (others => '0');
  variable low_b                             : std_logic_vector(8 downto 0) := (others => '0');

  
  
 
 begin	

	------------------------------------------------------------
	---input data 
	---input data
	if rising_edge(clk) then
		if data_in_en = '0' then  
			last_signal (YUV_DATA_DWIDTH-1 downto 0) <= yuv_data_in (YUV_DATA_DWIDTH-1 downto 0);
		else
			current_signal (YUV_DATA_DWIDTH-1 downto 0) <= yuv_data_in (YUV_DATA_DWIDTH-1 downto 0);
		end if;
	end if;	

	--extract two pixels  
	--extract two pixels 
	if  rising_edge(clk) then	
		if data_in_en = '0' then 
		data_temp (31 downto 0) <= last_signal (YUV_DATA_DWIDTH-1 downto 0) & current_signal (YUV_DATA_DWIDTH-1 downto 0);
		end if;
	end if;

   ---recover the new input two pixels
   ---RGB data is between 0 and 255	
	high_y (8 downto 0) := '0' & data_temp(31 downto 24);
	high_y_for_g (8 downto 0) := '1' & data_temp(31 downto 24);
	if switch_uv = '0' then 
		u (8 downto 0) := '0' & data_temp(23 downto 16);
		v (8 downto 0) := '0' & data_temp(7 downto 0);
	else
		v (8 downto 0) := '0' & data_temp(23 downto 16);
		u (8 downto 0) := '0' & data_temp(7 downto 0);
	end if;
	low_y (8 downto 0)  := '0' & data_temp(15 downto 8);
	low_y_for_g (8 downto 0)  := '1' & data_temp(15 downto 8);
	
	-----recover the new R G B
	-----recover the new R G B
	high_r (8 downto 0) := high_y (8 downto 0) + v (8 downto 0) + ("00" & v (8 downto 2)) + ("000" & v (8 downto 3)) + ("000000" & v (8 downto 6))+ ("0000000" & v (8 downto 7)) - 178;
	--RGB VALUE BETWEEN 0 TO 255	--RGB VALUE BETWEEN 0 TO 255	
		if high_r (8) = '1' then
			high_r (7 downto 0) := "11111111";
		end if;		
	--high_g (8 downto 0) := high_y (8 downto 0) + 136 - ("00" & u (8 downto 2)) - ("0000" & u (8 downto 4)) - ("00000" & u (8 downto 5)) - ('0' & v (8 downto 1)) - ("000" & v (8 downto 3)) - ("0000" & v (8 downto 4)) - ("00000" & v (8 downto 5));
	high_g (8 downto 0) := high_y_for_g (8 downto 0)  - ("00" & u (8 downto 2)) - ("0000" & u (8 downto 4)) - ("00000" & u (8 downto 5)) - ('0' & v (8 downto 1)) - ("000" & v (8 downto 3)) - ("0000" & v (8 downto 4)) - ("00000" & v (8 downto 5)) -120;
		if high_g (8) = '1' then
			high_g (7 downto 0) := "11111111";
			--high_g (7 downto 0) := "00000000";
		end if;	
	high_b (8 downto 0) := high_y (8 downto 0) +  u (8 downto 0) + ('0' & u (8 downto 1)) + ("00" & u (8 downto 2)) + ("000000" & u (8 downto 6)) - 225;
		if high_b (8) = '1' then
			high_b (7 downto 0) := "11111111";
		end if;	
		
	dummy_g <= high_g (8);
	
	--Y'UV422 can also be expressed in YUY2 FourCC format code. That means 2 pixels will be defined in each macropixel (four bytes) treated in the image. Yuv422 yuy2.svg. 
	low_r (8 downto 0) := low_y (8 downto 0) + v (8 downto 0) + ("00" & v (8 downto 2)) + ("000" & v (8 downto 3)) + ("000000" & v (8 downto 6)) + ("0000000" & v (8 downto 7)) - 178;
		if low_r (8) = '1' then
			low_r (7 downto 0) := "11111111";
		end if;
	low_g (8 downto 0) := low_y_for_g (8 downto 0)- ("00" & u (8 downto 2)) - ("0000" & u (8 downto 4)) - ("00000" & u (8 downto 5)) - ('0' & v (8 downto 1)) - ("000" & v (8 downto 3)) - ("0000" & v (8 downto 4)) - ("00000" & v (8 downto 5)) -120;
		if low_g (8) = '1' then
			low_g (7 downto 0) := "11111111";
		end if;
	low_b (8 downto 0) := low_y (8 downto 0) + u (8 downto 0) + ('0' & u (8 downto 1)) + ("00" & u (8 downto 2)) + ("000000" & u (8 downto 6)) - 225;
		if low_b (8) = '1' then
			low_b (7 downto 0) := "11111111";
		end if;
	
	--------------------------
	-----control red by switch
	if switch_r = '1' then
		high_r_out <= high_r;
		low_r_out <= low_r;
	else
		high_r_out <= "000000000";
		low_r_out <= "000000000";	
	end if;
	--------------------------
	-----control green by switch
	if switch_g = '1' then
		high_g_out <= high_g;
		low_g_out <= low_g;
	else
		high_g_out <= "000000000";
		low_g_out <= "000000000";	
	end if;
	--------------------------
	-----control blue by switch
	if switch_b = '1' then
		high_b_out <= high_b;
		low_b_out <= low_b;
	else
		high_b_out <= "000000000";
		low_b_out <= "000000000";	
	end if;
	
   ---restore the two output pixels 
	---restore the two output pixels 	
	last_pixel (RGB_DATA_DWIDTH-1 downto 0) <= high_r_out (7 downto 0) & high_g_out (7 downto 0) & high_b_out (7 downto 0);
	current_pixel (RGB_DATA_DWIDTH-1 downto 0) <= low_r_out (7 downto 0) & low_g_out (7 downto 0) & low_b_out (7 downto 0);
	
	---output data 
	---output data
	if rst='1' then
		rgb_data_out  <= (others => '0');
		dummy_out     <= (others => '0');
		current_pixel <= (others => '0');
		last_pixel    <= (others => '0');
		data_in_en           <= '0';
	 
	elsif rising_edge(clk) then		
	 	data_in_en <= not data_in_en;	
	end if;
	
	
	if rising_edge(clk) then 
		if (data_in_en = '1') then
			rgb_data_out(RGB_DATA_DWIDTH-1 downto 0) <= last_pixel(RGB_DATA_DWIDTH-1 downto 0);
			dummy_out(RGB_DATA_DWIDTH-1 downto 0) <= last_pixel(RGB_DATA_DWIDTH-1 downto 0);
		else
			rgb_data_out(RGB_DATA_DWIDTH-1 downto 0) <= current_pixel(RGB_DATA_DWIDTH-1 downto 0);
			dummy_out(RGB_DATA_DWIDTH-1 downto 0) <= current_pixel(RGB_DATA_DWIDTH-1 downto 0);
		end if;
	end if;			
  end process yuv2rgb;
  
end IMP;
