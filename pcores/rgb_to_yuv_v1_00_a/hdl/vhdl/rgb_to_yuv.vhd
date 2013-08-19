-----------------------------------------------------------------------------
---**************************************************************************
---***conversion from RGB color space to YUV color space                  ***
---***Author:     Yujiao                                                  ***
---***Date:       05.2013                                                 ***
---**************************************************************************
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity rgb_to_yuv is
   generic
  (
    YUV_DATA_DWIDTH                   : integer              := 16;
    RGB_DATA_DWIDTH                   : integer              := 24
    --TEMP_DATA_DWIDTH                  : integer              := 48;
  );
  port
  (
    clk                       : in  std_logic;
    rst                       : in  std_logic;
    --switch_uv                 : in  std_logic;
    rgb_data_in               : in  std_logic_vector(RGB_DATA_DWIDTH-1 downto 0);    
    yuv_data_out              : out  std_logic_vector(YUV_DATA_DWIDTH-1 downto 0);
    rgb2yuv_in_vblank         : in  std_logic;
    rgb2yuv_in_hblank         : in  std_logic;
    rgb2yuv_in_de             : in  std_logic;
    rgb2yuv_out_vblank        : out  std_logic;
    rgb2yuv_out_hblank        : out  std_logic;
    rgb2yuv_out_de            : out  std_logic
	 
  );

  attribute SIGIS             : string;
  attribute SIGIS of clk      : signal is "CLK";
  attribute SIGIS of rst      : signal is "RST";

end entity rgb_to_yuv;


------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------
architecture IMP of rgb_to_yuv is

  constant C_DELAY : integer := 4; --yujiao: 2 clock cycle delay
  
  ------------------------------------------
  -- signal declarations
  -- signal declarations
  ------------------------------------------
 
  signal last_signal                       : std_logic_vector(RGB_DATA_DWIDTH-1 downto 0) := (others => '0');   ---input temp 
  signal current_signal                    : std_logic_vector(RGB_DATA_DWIDTH-1 downto 0) := (others => '0');   ---input temp 
  signal last_pixel                        : std_logic_vector(YUV_DATA_DWIDTH-1 downto 0) := (others => '0');   ---output temp 
  signal current_pixel                     : std_logic_vector(YUV_DATA_DWIDTH-1 downto 0) := (others => '0');   ---output temp 
  signal data_temp_en                    : std_logic := '1';
  signal data_temp_en_delay              : std_logic := '1';
  signal data_out_en                     : std_logic := '1';
  signal data_in_en                      : std_logic := '1';
  signal data_temp 			              : std_logic_vector(47 downto 0) := (others => '0');
  signal dummy_out : std_logic_vector(YUV_DATA_DWIDTH-1 downto 0);  

  signal vblank_delay : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');
  signal hblank_delay : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');
  signal de_delay     : std_logic_vector(C_DELAY-1 downto 0) := (others => '0');


begin
  
  
  rgb2yuv_out_vblank <= vblank_delay(0);  --rgb2yuv_in_vblank;
  rgb2yuv_out_hblank <= hblank_delay(0);  --rgb2yuv_in_hblank;
  rgb2yuv_out_de     <= de_delay(0);      --rgb2yuv_in_de;
  
	
  delay_control_signals : process(clk) is
  begin
	  if (rising_edge(clk)) then	
		   vblank_delay(C_DELAY-1 downto 0) <= rgb2yuv_in_vblank & vblank_delay(C_DELAY-1 downto 1);
			hblank_delay(C_DELAY-1 downto 0) <= rgb2yuv_in_hblank & hblank_delay(C_DELAY-1 downto 1);
			de_delay(C_DELAY-1 downto 0)     <= rgb2yuv_in_de     &     de_delay(C_DELAY-1 downto 1);
	   end if;
  end process;


  ---yuv_data_out(YUV_DATA_DWIDTH-1 downto 0) <= rgb_data_in(RGB_DATA_DWIDTH-1 downto 8);
  -- implement 
  rgb2yuv : process( rst, clk ) is
  variable last_r                            : std_logic_vector(8 downto 0) := (others => '0');
  variable last_g                            : std_logic_vector(8 downto 0) := (others => '0');
  variable last_b                            : std_logic_vector(8 downto 0) := (others => '0');
  variable current_r                         : std_logic_vector(8 downto 0) := (others => '0');
  variable current_g                         : std_logic_vector(8 downto 0) := (others => '0');
  variable current_b                         : std_logic_vector(8 downto 0) := (others => '0'); 
  variable high_y                            : std_logic_vector(8 downto 0) := (others => '0');
  variable high_u                            : std_logic_vector(8 downto 0) := (others => '0');
  variable high_v                            : std_logic_vector(8 downto 0) := (others => '0');
  variable low_y                             : std_logic_vector(8 downto 0) := (others => '0');
  variable low_u                             : std_logic_vector(8 downto 0) := (others => '0');
  variable low_v                             : std_logic_vector(8 downto 0) := (others => '0');  

  begin
	---input data 
	---input data 
	---input data
	if rising_edge (clk) then
		if (data_in_en = '0') then
			last_signal (RGB_DATA_DWIDTH-1 downto 0) <= rgb_data_in (RGB_DATA_DWIDTH-1 downto 0);
		else
			current_signal (RGB_DATA_DWIDTH-1 downto 0) <= rgb_data_in (RGB_DATA_DWIDTH-1 downto 0);
		end if;
	end if; 
	
	--extract two pixels  
	--extract two pixels 
	if  rising_edge(clk) then	
		if data_in_en = '0' then 
		data_temp (47 downto 0) <= last_signal (RGB_DATA_DWIDTH-1 downto 0) & current_signal (RGB_DATA_DWIDTH-1 downto 0);
		end if;
	end if;
	
	--drag out two pixels 
	--data_temp (TEMP_DATA_DWIDTH-1 downto 0) <= last_signal (RGB_DATA_DWIDTH-1 downto 0) & current_signal (RGB_DATA_DWIDTH-1 downto 0);
   ---recover the new input two pixels 
	last_r (8 downto 0) := '0' & data_temp (47 downto 40);
	last_g (8 downto 0) := '0' & data_temp (39 downto 32);
	last_b (8 downto 0) := '0' & data_temp (31 downto 24);
	current_r (8 downto 0) := '0' & data_temp (23 downto 16);
	current_g (8 downto 0) := '0' & data_temp (15 downto 8);
	current_b (8 downto 0) := '0' & data_temp (7 downto 0);
	
	-----recover the new R G B
	-----recover the new R G B
	--Y'UV422 can also be expressed in YUY2 FourCC format code. That means 2 pixels will be defined in each macropixel (four bytes) treated in the image. Yuv422 yuy2.svg. 
	high_y (8 downto 0) := ("00" & last_r (8 downto 2)) + ("00000" & last_r (8 downto 5)) + ("000000" & last_r (8 downto 6)) + ('0' & last_g (8 downto 1)) + ("0000" & last_g (8 downto 4)) + ("000000" & last_g (8 downto 6)) + ("0000000" & last_g (8 downto 7)) + ("0000" & last_b (8 downto 4)) + ("00000" & last_b (8 downto 5)) + ("000000" & last_b (8 downto 6));
		if high_y (8) = '1' then
			high_y (7 downto 0) := "11111111";
		end if;	
	high_u (8 downto 0) := 128 + ('0' & last_b (8 downto 1)) - ("000" & last_r (8 downto 3)) - ("00000" & last_r (8 downto 5)) - ("0000000" & last_r (8 downto 7)) - ("00" & last_g (8 downto 2)) - ("0000" & last_g (8 downto 4)) - ("000000" & last_g (8 downto 6));
		if high_u (8) = '1' then
			high_u (7 downto 0) := "11111111";
		end if;	
	high_v (8 downto 0) := 128 + ('0' & last_r (7 downto 1)) - ("00"& last_g (8 downto 2)) - ("000"& last_g (8 downto 3)) - ("00000" & last_g (8 downto 5)) - ("0000000" & last_g (8 downto 7)) - ("0000" & last_b (8 downto 4)) - ("000000" & last_b(8 downto 6));
		if high_v (8) = '1' then
			high_v (7 downto 0) := "11111111";
		end if;	
	low_y (8 downto 0) := ("00" & current_r (8 downto 2)) + ("00000" & current_r (8 downto 5)) + ("000000" & current_r (8 downto 6)) + ('0' & current_g (8 downto 1)) + ("0000" & current_g (8 downto 4)) + ("000000" & current_g (8 downto 6)) + ("0000000" & current_g (8 downto 7)) + ("0000" & current_b (8 downto 4)) + ("00000" & current_b (8 downto 5)) + ("000000" & current_b (8 downto 6));
		if low_y (8) = '1' then
			low_y (7 downto 0) := "11111111";
		end if;	
	---low_u (7 downto 0) := ('0' & current_by (7 downto 1)) + ("0000" & current_by (7 downto 4)) + 128;
	---low_v (7 downto 0) := ('0' & current_ry (7 downto 1)) + ("000" & current_ry (7 downto 3)) + ("0000" & current_ry (7 downto 4)) + ("00000" & current_ry(7 downto 5)) + 128;
	
	---restore the two output pixels 
	---restore the two output pixels 	
	--if switch_uv = '0' then
		last_pixel (YUV_DATA_DWIDTH-1 downto 0) <= high_y (7 downto 0) & high_u (7 downto 0);
		current_pixel (YUV_DATA_DWIDTH-1 downto 0) <= low_y (7 downto 0) & high_v (7 downto 0);
	--else
		--last_pixel (YUV_DATA_DWIDTH-1 downto 0) <= high_y (7 downto 0) & high_v (7 downto 0);
		--current_pixel (YUV_DATA_DWIDTH-1 downto 0) <= low_y (7 downto 0) & high_u (7 downto 0);
	--end if;
	
	---output data 
	---output data
	if rst='1' then
		yuv_data_out  <= (others => '0');
		dummy_out     <= (others => '0');
		current_pixel <= (others => '0');
		last_pixel    <= (others => '0');
		data_temp_en         <= '1';
		data_out_en          <= '1';
		data_in_en          <= '0';
	 
	elsif rising_edge(clk) then	
	   data_temp_en <= not data_temp_en;
		data_temp_en_delay <= data_temp_en;
		--data_out_en <= not data_out_en;	
	 	data_in_en <= not data_in_en;	
		data_out_en <= data_temp_en;
	end if;
	
	
	if rising_edge(clk) then
		if (data_in_en = '1') then
			yuv_data_out(YUV_DATA_DWIDTH-1 downto 0) <= last_pixel(YUV_DATA_DWIDTH-1 downto 0);
			dummy_out(YUV_DATA_DWIDTH-1 downto 0) <= last_pixel(YUV_DATA_DWIDTH-1 downto 0);
		else
			yuv_data_out(YUV_DATA_DWIDTH-1 downto 0) <= current_pixel(YUV_DATA_DWIDTH-1 downto 0);
			dummy_out(YUV_DATA_DWIDTH-1 downto 0) <= current_pixel(YUV_DATA_DWIDTH-1 downto 0);
		end if;
	end if;	
  end process rgb2yuv;

end IMP;
