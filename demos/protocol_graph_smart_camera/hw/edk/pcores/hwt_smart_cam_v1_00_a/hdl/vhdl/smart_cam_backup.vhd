-----------------------------------------------------------------------------
---**************************************************************************
---***STORE and forward FRAME to Ethernet                                 ***
---***Author:     Yujiao                                                  ***
---***Date:       08.2013                                                 ***
---**************************************************************************
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;



entity smart_cam is
 generic
  (
    YUV_DATA_DWIDTH                   : integer              := 16;
    RGB_DATA_DWIDTH                   : integer              := 24;
    FRAME_WIDTH                       : integer              := 1920;
    FRAME_HEIGHT                      : integer              := 1080

  );
 port
  (
    clk                       : in  std_logic;
    rst                       : in  std_logic; 
    video_in_vblank           : in  std_logic;
    video_in_hblank           : in  std_logic;
    video_in_de               : in  std_logic;
    video_in_data             : in  std_logic_vector(RGB_DATA_DWIDTH-1 downto 0);
    comm_out_sof_n            : out  std_logic;         ----active low 
    comm_out_eof_n            : out  std_logic;         ----active low 
    comm_out_data             : out  std_logic_vector(7 downto 0);
    comm_out_src_rdy_n        : out  std_logic;         ----active low  
    comm_out_dst_rdy_n        : in  std_logic;          ----active low
    comm_in_sof_n             : in  std_logic;          ----active low
    comm_in_eof_n             : in  std_logic;          ----active low
    comm_in_data              : in  std_logic_vector(7 downto 0);
    comm_in_src_rdy_n         : in  std_logic;          ----active low
    comm_in_dst_rdy_n         : out  std_logic;          ----active low
	 switch_camera_1           : in  std_logic;
	 switch_camera_2           : in  std_logic;
	 switch_camera_3           : in  std_logic;
	 switch_camera_4           : in  std_logic;
	 button_up                 : in  std_logic;
	 button_down               : in  std_logic;
	 button_size               : in  std_logic;
	 button_left               : in  std_logic;
	 button_right              : in  std_logic
  );

end entity smart_cam;


------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------
architecture IMP of smart_cam is

	  component chipscope_icon
	  port (
		 control0 : inout std_logic_vector(35 downto 0));
	  end component;
	  
	  component chipscope_ila
	  port (
		 control : inout std_logic_vector(35 downto 0);
		 clk   : in std_logic;
		 trig0 : in std_logic_vector(15 downto 0);
		 trig1 : in std_logic_vector(15 downto 0);
		 trig2 : in std_logic_vector(23 downto 0);
		 trig3 : in std_logic_vector(23 downto 0);
		 trig4 : in std_logic_vector(31 downto 0);
		 trig5 : in std_logic_vector(15 downto 0);
		 trig6 : in std_logic_vector(23 downto 0);
		 trig7 : in std_logic_vector(7 downto 0);
		 trig8 : in std_logic_vector(47 downto 0));
	  end component;
	
	
	---------------------------------------------------
	----signals for Block RAM
  	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := 21000;  --6000;     --5184 for every 20 rows and columns 
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := 15;   --13;
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;
	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	--shared variable
	signal local_ram                   : LOCAL_MEMORY_T;
	--shared variable local_ram          : LOCAL_MEMORY_T;
	signal RAMAddr                     : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0) := (others => '0'); 
	signal in_RAMData                  : std_logic_vector(31 downto 0);
	signal in_RAMWE                    : std_logic;   --write when high value 
	signal out_RAMData                 : std_logic_vector(31 downto 0);
   signal active_line                 : std_logic := '0';  ---each 20 lines active one line   ---active when high 
	signal pixel_counter               : integer := 0;      ---count pixel for capture compressed frame
   signal line_counter                : integer := 0;      ---count line for capture compressed frame
	signal counter                     : integer := 0;      ---count the pixels that we need to store in compressed frame
   signal pixel_per_line_counter      : integer := 0;      ---count the pixels that we need to store in compressed frame
	
	signal RAMAddr_100                 : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0) := (others => '0'); 
	signal in_RAMData_100              : std_logic_vector(31 downto 0);
	signal in_RAMWE_100                : std_logic;   --write when high value 
	signal out_RAMData_100             : std_logic_vector(31 downto 0);
 
-- attribute S : string;
-- attribute S of local_ram           : signal is "yes";
--	attribute S of RAMAddr             : signal is "yes";
--	attribute S of in_RAMData          : signal is "yes";
--	attribute S of in_RAMWE            : signal is "yes";
--	attribute S of out_RAMData         : signal is "yes";
   
	
	---------------------------------------------------
	----signals     
	constant ORIGINAL_FRAME_SIZE          : integer := FRAME_WIDTH * FRAME_HEIGHT;     
	constant SCALE_DIVISOR                : integer := 10; --5; --40;  --20;
	constant FRAME_SIZE                   : integer := ORIGINAL_FRAME_SIZE/(SCALE_DIVISOR*SCALE_DIVISOR); ---in pixels 
	constant COMPRESSED_FRAME_WIDE        : integer := FRAME_WIDTH/SCALE_DIVISOR; ---in pixels
	constant PACKAGE_NUM                  : integer := 108; --6; --6;  --12;   ---one frame split into 12 packages( one package in pixel)
	constant PACKAGE_SIZE                 : integer := FRAME_SIZE/PACKAGE_NUM ;   ---in pixels 
   constant HEADER_SIZE                  : integer := 33;        --in pixels
	--constant SOF_DELAY                    : integer := 3;          --3 clock cycle delay
	constant EOF_DELAY                    : integer := 2;          --5 clock cycle delay
	
	
	signal write_addr                     : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0)  := (others => '0');
	signal write_addr_next                : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0)  := (others => '0');
   signal read_addr                      : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0) ;
   signal write_en_n                     : std_logic := '0';     --enable with low value 
   signal read_en_n                      : std_logic := '1';     --enable with low value 
  
   signal store_finish                   : std_logic := '0';     --enable with high value
   signal transmit_finish                : std_logic := '0';     --enable with high value
	signal pixel_forward_finish           : std_logic := '0';     --enable with high value   
	signal pixel_read_finish              : std_logic := '0';     --enable with high value 
	signal pixel_read_finish_delay        : std_logic := '0';     --enable with high value 
	signal pixel_read_finish_delay_1      : std_logic := '0';     --enable with high value 
	signal pixel_read_finish_delay_2      : std_logic := '0';     --enable with high value 
	signal sof_packet_finish              : std_logic := '0';     --enable with high value
	signal handover_packet_finish         : std_logic := '0';     --enable with high value
	
	
	
	signal read_delay_counter               : integer := 0;
	signal total_pixel_counter              : integer := 0;
   signal package_pixel_counter            : integer := 0;
	signal package_counter                  : integer := 0;
   signal pixel_factor_counter             : integer := 0;
	signal header_pixel_counter             : integer := 0;
	signal total_frame_counter              : integer := 0;
	signal std_total_frame_counter          : std_logic_vector(31 downto 0);
   
	--signal comm_out_sof_n_in             : std_logic := '1';     
	signal comm_out_eof_n_in             : std_logic := '1';     
	signal active_comm_out_sof_n         : std_logic := '0';     --enable with high value
	signal active_comm_out_eof_n         : std_logic := '0';     --enable with high value
	signal active_comm_out_sof_n_delay   : std_logic := '0';     --enable with high value
	signal active_comm_out_eof_n_delay   : std_logic := '0';     --enable with high value	
	
	--signal comm_out_sof_n_delay          : std_logic_vector(SOF_DELAY-1 downto 0) := (others => '0');
   signal comm_out_eof_n_delay          : std_logic_vector(EOF_DELAY-1 downto 0) := (others => '0');
	signal video_in_vblank_last             : std_logic := '0';
	signal video_in_hblank_last             : std_logic := '0';
	signal video_in_de_last                 : std_logic := '0';
	signal set_camera_number              : std_logic_vector(7 downto 0);
	signal loc_x                          : std_logic_vector(7 downto 0);
	signal loc_y                          : std_logic_vector(7 downto 0);
	
	
	
	
	---------------------------------------------------
	----signals for send packets
	--type dest_mac is array (0 to 5) of std_logic_vector(7 downto 0);
	signal dest_mac_0                             : std_logic_vector(7 downto 0) := (others => '0');
	signal dest_mac_1                             : std_logic_vector(7 downto 0) := (others => '0');
	signal dest_mac_2                             : std_logic_vector(7 downto 0) := (others => '0');
	signal dest_mac_3                             : std_logic_vector(7 downto 0) := (others => '0');
	signal dest_mac_4                             : std_logic_vector(7 downto 0) := (others => '0');
	signal dest_mac_5                             : std_logic_vector(7 downto 0) := (others => '0');
	signal src_mac_0                              : std_logic_vector(7 downto 0) := (others => '0');
	signal src_mac_1                              : std_logic_vector(7 downto 0) := (others => '0');	
	signal src_mac_2                              : std_logic_vector(7 downto 0) := (others => '0');
	signal src_mac_3                              : std_logic_vector(7 downto 0) := (others => '0');
	signal src_mac_4                              : std_logic_vector(7 downto 0) := (others => '0');
	signal src_mac_5                              : std_logic_vector(7 downto 0) := (others => '0');
	

	signal protocol_0                           : std_logic_vector(7 downto 0);
	signal protocol_1                           : std_logic_vector(7 downto 0);
	signal comm_in_sof_n_delay                 : std_logic;
	signal comm_in_sof_n_delay1                : std_logic;
	signal comm_in_eof_n_delay                 : std_logic;
	signal comm_in_eof_n_delay1                : std_logic;
	signal rx_ready                             : std_logic;
	signal rx_finish                            : std_logic;
	signal data_in_counter                      : integer;
	signal loc1_x                               : std_logic_vector(7 downto 0);
	signal loc1_y                               : std_logic_vector(7 downto 0);
	signal loc2_x                               : std_logic_vector(7 downto 0);
	signal loc2_y                               : std_logic_vector(7 downto 0);
	signal dst_id                               : std_logic_vector(7 downto 0); 
	signal rx_active_frame                      : std_logic;
	signal command_type                         : std_logic_vector(7 downto 0);
	signal src_id                               : std_logic_vector(7 downto 0);
	signal rx_command_size                      : std_logic_vector(7 downto 0);
	signal button_left_delay                    : std_logic;
	signal button_right_delay                   : std_logic;
	signal button_up_delay                      : std_logic;
	signal button_down_delay                    : std_logic;
	signal button_size_delay                    : std_logic;
	signal ho_2_cam                             : std_logic_vector(7 downto 0);
	signal handover_finish                      : std_logic;
	signal active_handover                      : std_logic;
	
	
	
	------test signal for chipscope
	signal trig0   : std_logic_vector(15 downto 0);
   signal trig1   : std_logic_vector(15 downto 0);
	signal trig2   : std_logic_vector(23 downto 0);
   signal trig3   : std_logic_vector(23 downto 0);
	signal trig4   : std_logic_vector(31 downto 0);
   signal trig5   : std_logic_vector(15 downto 0);
	signal trig6   : std_logic_vector(23 downto 0);
	signal trig7   : std_logic_vector(7 downto 0);
   signal trig8   : std_logic_vector(47 downto 0);
	signal control : std_logic_vector(35 downto 0);
	
	signal dummy_std_counter_1    : std_logic_vector(7 downto 0);
	signal dummy_std_counter_2    : std_logic_vector(7 downto 0);
	signal dummy_std_counter_3    : std_logic_vector(7 downto 0);
	signal dummy_comm_in_dst_rdy_n      : std_logic;
	
	---------------------------------------------------
	----state machine
	type state is ( initial_state, write_state, read_state , transmit_state , generate_sof_state, generate_handover_state, read_wait_state);
	signal present_state                  : state;
   
   type rx_state is ( rx_wait_state , receive_state);
	signal rx_present_state               : rx_state;


begin


	------------------------------------------------------
   -- read or write for 
   -- local single-port RAM
   ------------------------------------------------------
	read_write_data : process ( rst, present_state, write_addr, read_addr ) is
	begin
		if (present_state = write_state) then
			in_RAMWE <= '1';
			RAMAddr <= write_addr;			
		elsif (present_state = read_wait_state) then
			in_RAMWE <= '0';
			RAMAddr <= read_addr;
		end if;
	end process;
	
   ------------------------------------------------------
   -- local single-port RAM
   -- local single-port RAM
	------------------------------------------------------
	local_ram_proc : process( clk ) is
		begin
		-- local RAM input and output
		if (rising_edge(clk)) then	
			if (in_RAMWE = '1') then
				local_ram(conv_integer(unsigned(RAMAddr))) <= in_RAMData;
			else
				out_RAMData <= local_ram(conv_integer(unsigned(RAMAddr)));
			end if;
		end if;
		end process;


	

	 my_chipscope_icon : chipscope_icon
	 port map (
		 control0 => control);
 
	 my_chipscope_ila : chipscope_ila
	  port map (
		 control => control,
		 clk => clk,
		 trig0 => trig0,
		 trig1 => trig1,
		 trig2 => trig2,
		 trig3 => trig3,
		 trig4 => trig4,
		 trig5 => trig5,
		 trig6 => trig6,
		 trig7 => trig7,
		 trig8 => trig8);
		 
		 
 
   dummy_std_counter_1 <=  conv_std_logic_vector( line_counter, 8);
	dummy_std_counter_2 <=  conv_std_logic_vector( pixel_per_line_counter, 8);	
	dummy_std_counter_3 <=  conv_std_logic_vector( data_in_counter, 8);
	
	
   trig0 <= dummy_std_counter_1 & loc_y;
	trig1 <= dummy_std_counter_2 & loc_x;
	trig2 <= command_type & "000" & handover_finish & active_handover & rx_ready & rx_finish & 
	         rx_active_frame & comm_in_src_rdy_n & dummy_comm_in_dst_rdy_n & comm_in_sof_n & comm_in_sof_n_delay1 & 
	         comm_in_sof_n_delay & comm_in_eof_n & comm_in_eof_n_delay1 & comm_in_eof_n_delay;
	trig3 <= dummy_std_counter_3 & set_camera_number & dst_id;
	trig4 <= dest_mac_5 & dest_mac_0 & src_mac_5 & src_mac_0;
	trig5 <= protocol_1 & protocol_0;
	trig6 <= in_RAMData(7 downto 0) & rx_command_size & ho_2_cam;
	trig8 <= dst_id & src_id & loc2_y & loc2_x & loc1_y & loc1_x;
	
   set_camera_number <= "0000" & switch_camera_4 & switch_camera_3 & switch_camera_2 & switch_camera_1;  

	------------------------------------------------------
   --process for delaying control singals delay
   ------------------------------------------------------
	--comm_out_sof_n <= comm_out_sof_n_delay(0);  
   comm_out_eof_n <= comm_out_eof_n_delay(0);  
	

	delay_control_signals : process(clk) is
	begin
		if (rising_edge(clk)) then	
		   video_in_hblank_last <= video_in_hblank;
			video_in_vblank_last <= video_in_vblank;
			video_in_de_last     <= video_in_de;
			comm_in_sof_n_delay1 <= comm_in_sof_n;
			comm_in_sof_n_delay  <= comm_in_sof_n_delay1;
			comm_in_eof_n_delay1 <= comm_in_eof_n;
			comm_in_eof_n_delay  <= comm_in_eof_n_delay1;
			button_left_delay <= button_left;
			button_right_delay <= button_right;
			button_up_delay <= button_up;
			button_down_delay <= button_down;
			button_size_delay <= button_size;
		end if;
	end process;
	
	
	------------------------------------------------------
   --store and transfer frame state machine process 
   ------------------------------------------------------
	store_transfer_state: process ( clk, rst, present_state, write_en_n, store_finish, counter, line_counter, pixel_counter, 
									pixel_per_line_counter, video_in_vblank, video_in_hblank, video_in_de, video_in_vblank_last, video_in_hblank_last, 
									video_in_de_last, write_addr, read_en_n, pixel_read_finish_delay_2, total_pixel_counter, read_delay_counter, 
									pixel_read_finish, pixel_read_finish_delay, sof_packet_finish, comm_out_dst_rdy_n, pixel_factor_counter,
									header_pixel_counter,  active_comm_out_sof_n, active_comm_out_sof_n_delay, active_comm_out_eof_n, 
									active_comm_out_eof_n_delay, transmit_finish, pixel_forward_finish, package_pixel_counter, dst_id,
									active_handover) is 
									
	variable step                         : natural range 0 to 2;
	
	begin 
		if ( rst = '1' ) then             --enable with high value
			present_state <= initial_state;
			write_addr <= (others => '0');
			read_addr <= (others => '0');
			in_RAMData <= (others=>'0');
			total_frame_counter <= 0;
		elsif ( rising_edge(clk) ) then 
			if active_handover = '1' then
				handover_finish <= '0';
			end if;
			case present_state is 
				when initial_state =>
					if write_en_n = '0' then 
						------change to next state
						present_state <= write_state;  
					end if;
					------what u wannna do in this state
					--write_addr <= (others => '0');
					read_addr <= ( 0 => '1' , others => '0');
					in_RAMData <= (others=>'0');
					write_en_n <= '0';
					total_pixel_counter <= 0;
					package_pixel_counter <= 0;
					package_counter <= 1;
					transmit_finish <= '0';
					sof_packet_finish <= '0';
					handover_packet_finish <= '0';
					active_line <= '0';
					pixel_counter <= 0;
					line_counter <= 0;
					store_finish <= '0';
					step := 0;
					pixel_factor_counter <= 0;
					header_pixel_counter <= 0;
					
					
				when write_state =>
					if store_finish = '1' then 
						write_en_n <= '1';
						read_en_n <= '0'; 
						------change to next state
						present_state <= read_wait_state;
					else
						case step is
								when 0 => -- wait for start of next frame
									if (video_in_vblank_last='1' and video_in_vblank='0') then
										write_addr  <= (others=>'0');
										write_addr_next <= (others=>'0');
										line_counter <= 0;
										counter      <= 0;
										loc_x <= X"00";
										loc_y <= X"00";
										step := step + 1;
									end if;				
								
								when 1 => -- store pixels
									-- frame already stored? 
									if (FRAME_SIZE <= counter) then
										step := step + 1;
									-- start of line
									elsif ( video_in_de_last='0' and video_in_de='1' and video_in_hblank='0' and video_in_vblank_last='0' and video_in_vblank='0' ) then -- and video_in_de_last='0' and video_in_de='1') then
										-- store first pixel of each 'C_SCALE_DIVISOR'th line
										if (line_counter = 0 or line_counter = SCALE_DIVISOR) then
											pixel_per_line_counter <= 1;
											loc_x <= X"00";
											active_line   <= '1';
											pixel_counter <= 1;
											line_counter <= 1;
											loc_y <= loc_y + 1;
											-- store first pixel of active line
											write_addr <= write_addr_next;
											--in_RAMData <= X"00" & video_in_data;
											if command_type = X"02" or command_type = X"05" then 
												if (loc_y = loc1_y or loc_y = loc2_y) and  (loc1_x <= 0  and 0 <= loc2_x) then
													in_RAMData <= X"00FF0000";  -----draw red rectangle in hardware
												elsif (0 = loc1_x or 0 = loc2_x) and  ( loc1_y <= loc_y and loc_y <= loc2_y) then
													in_RAMData <= X"00FF0000";
												else 
													in_RAMData <= X"00" & video_in_data;
												end if;
											else
												in_RAMData <= X"00" & video_in_data;
											end if;
											----in_RAMWE   <= '1';
											write_addr_next <= write_addr_next + 1;
											counter <= counter + 1;
										else 
											active_line <= '0';
											loc_x <= X"00";
											line_counter <= line_counter + 1;
											--loc_y <= loc_y + 1;
										end if;
									-- pixel of active line
									elsif (active_line = '1' and video_in_hblank_last='0'  and video_in_de_last='1' and video_in_de='1' and video_in_hblank='0' and video_in_vblank_last='0' and video_in_vblank='0') then
										-- each 'C_SCALE_DIVISOR'th pixel of line
										if (pixel_counter = SCALE_DIVISOR or pixel_counter = 0) then
											pixel_counter <= 1;
											if (pixel_per_line_counter < COMPRESSED_FRAME_WIDE) then
												pixel_per_line_counter <= pixel_per_line_counter + 1;
												loc_x <= loc_x + 1;
												-- store 'C_SCALE_DIVISOR'th pixel
												write_addr <= write_addr_next;
												if command_type = X"02"  or command_type = X"05" then 
													if (loc_y = loc1_y or loc_y = loc2_y) and  (loc1_x <= loc_x+1  and loc_x+1 <= loc2_x) then
															in_RAMData <= X"00FF0000";  -----draw red rectangle in hardware
													elsif (loc_x+1 = loc1_x or loc_x+1 = loc2_x) and  ( loc1_y <= loc_y and loc_y <= loc2_y) then
															in_RAMData <= X"00FF0000";
													else 
															in_RAMData <= X"00" & video_in_data;
													end if;
												else
													in_RAMData <= X"00" & video_in_data;
												end if;
												----in_RAMWE   <= '1';
												write_addr_next <= write_addr_next + 1;
												counter <= counter + 1;
											end if;
										else
											pixel_counter <= pixel_counter + 1;
										end if;
									end if;
					
								when 2 =>      -- frame completely stored to local RAM	
									store_finish <= '1';		
						end case;
					end if;
					
				

				when read_wait_state =>
					if read_en_n = '0' then 
						pixel_forward_finish <= '0';
						------change to next state
						present_state <= read_state;  
					end if;
					store_finish <= '0';

				
				when read_state =>	
					if pixel_read_finish_delay_2 = '1' then
						------change to next state
						present_state <= transmit_state;
					elsif total_pixel_counter = 0 then 
						---if command_type = X"04" and handover_finish = '0' then 
							------change to next state
							present_state <= generate_sof_state;
						--else 
							--total_pixel_counter <= 1;
						--end if;
					end if;
						
					------what u wannna do in this state
					read_delay_counter <= read_delay_counter + 1;
						case read_delay_counter is 
							when 0 =>
								pixel_read_finish <= '1';
							when 1 =>
								pixel_read_finish_delay <= '1';
							when 2 =>
								pixel_read_finish_delay_1 <= '1';
							when 3 =>
								pixel_read_finish_delay_2 <= '1';
							when others =>
								pixel_read_finish <= '0';
								pixel_read_finish_delay <= '0';
								pixel_read_finish_delay_1 <= '0';
								pixel_read_finish_delay_2 <= '0';
								read_delay_counter <= 0;
						end case;
					
					if pixel_read_finish = '1' and pixel_read_finish_delay = '0' then
							read_addr <= read_addr + 1;
							total_pixel_counter <= total_pixel_counter + 1;
							package_pixel_counter <= package_pixel_counter + 1;
					end if;
			

			
				when generate_sof_state =>        --33 pixels(99 bytes) which value are X"0010ff" means start of picture
					if sof_packet_finish = '1' then
						pixel_forward_finish <= '0';
						pixel_factor_counter <= 0;
						sof_packet_finish <= '0';
						total_pixel_counter <= total_pixel_counter + 1;
						------change to next state
						present_state <= read_state;	
					elsif comm_out_dst_rdy_n = '0' then 
						------what u wannna do in this state
						comm_out_eof_n_delay(EOF_DELAY-1 downto 0) <= comm_out_eof_n_in & comm_out_eof_n_delay(EOF_DELAY-1 downto 1);
						active_comm_out_sof_n_delay <= active_comm_out_sof_n;
						active_comm_out_eof_n_delay <= active_comm_out_eof_n;
						pixel_factor_counter <= pixel_factor_counter + 1;
						case pixel_factor_counter is 
							when 0 =>
								comm_out_src_rdy_n <= '1';
							when 1 =>
								comm_out_src_rdy_n <= '0';
								comm_out_data <= X"00";
							when 2 =>
								comm_out_data <= X"10";
							when 3 =>
								comm_out_data <= X"ff";
							when others =>
								header_pixel_counter <= header_pixel_counter + 1;
								comm_out_src_rdy_n <= '1';
								pixel_factor_counter <= 0;
						end case;
						
						if header_pixel_counter = 1 then
							sof_packet_finish <= '0';
							active_comm_out_sof_n <= '1';
						elsif header_pixel_counter = ( HEADER_SIZE - 1 ) then   --- header_pixel_counter = HEADER_SIZE-1
							active_comm_out_eof_n <= '1';   --- header_pixel_counter = HEADER_SIZE
						elsif header_pixel_counter = HEADER_SIZE then   --- header_pixel_counter = HEADER_SIZE-1
							sof_packet_finish <= '1';
							header_pixel_counter <= 0;
						else
							active_comm_out_sof_n <= '0';
							active_comm_out_eof_n <= '0';					
						end if;
						
						if ( active_comm_out_sof_n = '1' and active_comm_out_sof_n_delay = '0' ) then
							comm_out_sof_n <= '0';	
							total_frame_counter <= total_frame_counter + 1 ;
						else
							comm_out_sof_n <= '1';	
						end if;
						
						if ( active_comm_out_eof_n = '1' and active_comm_out_eof_n_delay = '0' ) then
							comm_out_eof_n_in <= '0';	
						else
							comm_out_eof_n_in <= '1';	
						end if;
					end if;
				
				
				

				when transmit_state =>
					if transmit_finish = '1' then
						if command_type = X"04" and handover_finish = '0' then 
						------change to next state
							present_state <= generate_handover_state;	
						else 
							present_state <= initial_state;	
						end if;
					elsif pixel_forward_finish = '1' then 
						pixel_read_finish <= '0';
						------change to next state
						present_state <= read_wait_state;
					elsif comm_out_dst_rdy_n = '0' then 
						------what u wannna do in this state
						comm_out_eof_n_delay(EOF_DELAY-1 downto 0) <= comm_out_eof_n_in & comm_out_eof_n_delay(EOF_DELAY-1 downto 1);
						active_comm_out_sof_n_delay <= active_comm_out_sof_n;
						active_comm_out_eof_n_delay <= active_comm_out_eof_n;
						pixel_factor_counter <= pixel_factor_counter + 1;
						if  package_pixel_counter = 1 then
							case pixel_factor_counter is 
								when 0 =>
									comm_out_src_rdy_n <= '1';    
								--------------------------------------
								-------eth_header
								---dst mac addr
								when 1 =>
									comm_out_src_rdy_n <= '0';     ----start source ready
									comm_out_data <= X"ff";   -- start of dst mac addr 1
								when 2 =>
									comm_out_data <= X"ff";   --dst mac addr 2
								when 3 =>
									comm_out_data <= X"ff";   --dst mac addr 3
								when 4 =>
									comm_out_data <= X"ff";   --dst mac addr 4
								when 5 =>
									comm_out_data <= X"ff";   --dst mac addr 5
								when 6 =>
									comm_out_data <= X"ff";   -- end of dst mac addr 6
								--------------------
								---src mac addr
								when 7 =>
									comm_out_data <= X"ff";  -- start of src mac addr 1
								when 8 =>
									comm_out_data <= X"ff";
								when 9 =>
									comm_out_data <= X"ff";
								when 10 =>
									comm_out_data <= X"ff";
								when 11 =>
									comm_out_data <= X"ff";
								when 12 =>
									comm_out_data <= "0000" & switch_camera_4 & switch_camera_3 & switch_camera_2 & switch_camera_1;  -- end of src mac addr 1
								-----------------
								---protocol
							   when 13 =>
									comm_out_data <= X"ac";    ------protocol
								when 14 =>
									comm_out_data <= X"dc";     ------protocol
								---------------
								---command
								when 15 =>
									comm_out_data <= X"f0";   ----dst_id 
								when 16 =>
									comm_out_data <= set_camera_number;    ----src_id
								when 17 =>
									comm_out_data <= X"01";     ----command : line pixel data  
								when 18 =>
									comm_out_data <= conv_std_logic_vector ( (PACKAGE_SIZE*3+5 ), 8 );   ----size of command
								when 19 =>
									comm_out_data <= conv_std_logic_vector ( package_counter , 8 );    ----packet number
								when 20 =>
								   std_total_frame_counter <= conv_std_logic_vector ( total_frame_counter , 32 ); 
									comm_out_data <= std_total_frame_counter (31 downto 24);   ----total frame number
								when 21 =>
									comm_out_data <= std_total_frame_counter (23 downto 16);   ----total frame number
								when 22 =>
									comm_out_data <= std_total_frame_counter (15 downto 8);   ----total frame number
								when 23 =>
									comm_out_data <= std_total_frame_counter (7 downto 0);   ----total frame number
								
								when 24 =>
									comm_out_data <= out_RAMData (23 downto 16);   ---first byte of the first pixel of frame
								when 25 =>
									comm_out_data <= out_RAMData (15 downto 8);
								when 26 =>
									comm_out_data <= out_RAMData (7 downto 0);
								when others =>
									comm_out_src_rdy_n <= '1';
									pixel_forward_finish <= '1';
									pixel_factor_counter <= 0;
							end case;
						else
							case pixel_factor_counter is 
								when 0 =>
									comm_out_src_rdy_n <= '1';
								when 1 =>
									comm_out_src_rdy_n <= '0';
									comm_out_data <= out_RAMData (23 downto 16);
								when 2 =>
									comm_out_data <= out_RAMData (15 downto 8);
								when 3 =>
									comm_out_data <= out_RAMData (7 downto 0);
								when others =>
									comm_out_src_rdy_n <= '1';
									pixel_forward_finish <= '1';
									pixel_factor_counter <= 0;
									if ( read_addr < ( FRAME_SIZE + 1 ) ) then  ----FRAME_SIZE + 2
										transmit_finish <= '0';
									elsif ( read_addr = ( FRAME_SIZE + 1 ) ) then   ---FRAME_SIZE + 2
										transmit_finish <= '1';
									end if;
							end case;
						end if;
						
						if package_pixel_counter = 1 then
							active_comm_out_sof_n <= '1';
						elsif package_pixel_counter = PACKAGE_SIZE   then   --- package_pixel_counter = PACKAGE_SIZE
							active_comm_out_eof_n <= '1';   --- package_pixel_counter = PACKAGE_SIZE
							package_pixel_counter <= 0;
							package_counter <= package_counter + 1; 
						else
							active_comm_out_sof_n <= '0';
							active_comm_out_eof_n <= '0';					
						end if;
						
						if ( active_comm_out_sof_n = '1' and active_comm_out_sof_n_delay = '0' ) then
							comm_out_sof_n <= '0';	
						else
							comm_out_sof_n <= '1';	
						end if;
						
						if ( active_comm_out_eof_n = '1' and active_comm_out_eof_n_delay = '0' ) then
							comm_out_eof_n_in <= '0';		
						else
							comm_out_eof_n_in <= '1';	
						end if;
					
					end if;
					
					
				
				when generate_handover_state =>        --33 pixels(99 bytes) which value are X"ff1000" means start of picture
					if handover_packet_finish = '1' then
						handover_packet_finish <= '0';
						handover_finish <= '1';
						------change to next state
						present_state <= initial_state;	
					elsif comm_out_dst_rdy_n = '0' then 
						------what u wannna do in this state
						comm_out_eof_n_delay(EOF_DELAY-1 downto 0) <= comm_out_eof_n_in & comm_out_eof_n_delay(EOF_DELAY-1 downto 1);
						active_comm_out_sof_n_delay <= active_comm_out_sof_n;
						active_comm_out_eof_n_delay <= active_comm_out_eof_n;
						pixel_factor_counter <= pixel_factor_counter + 1;
						if  header_pixel_counter = 0 then
							case pixel_factor_counter is 
								when 0 =>
									comm_out_src_rdy_n <= '1';
								when 1 =>
										comm_out_src_rdy_n <= '0';     ----start source ready
										comm_out_data <= X"ff";   --dst mac addr 1
									when 2 =>
										comm_out_data <= X"ff";   --dst mac addr 2
									when 3 =>
										comm_out_data <= X"ff";   --dst mac addr 3
									when 4 =>
										comm_out_data <= X"ff";   --dst mac addr 4
									when 5 =>
										comm_out_data <= X"ff";   --dst mac addr 5
									when 6 =>
										comm_out_data <= X"ff";   -- end of dst mac addr 6
									--------------------
									---src mac addr
									when 7 =>
										comm_out_data <= X"ff";  -- start of src mac addr 1
									when 8 =>
										comm_out_data <= X"ff";
									when 9 =>
										comm_out_data <= X"ff";
									when 10 =>
										comm_out_data <= X"ff";
									when 11 =>
										comm_out_data <= X"ff";
									when 12 =>
										comm_out_data <= "0000" & switch_camera_4 & switch_camera_3 & switch_camera_2 & switch_camera_1;  -- end of src mac addr 1
									-----------------
									---protocol
									when 13 =>
										comm_out_data <= X"08";    ------protocol
									when 14 =>
										comm_out_data <= X"00";     ------protocol
									---------------
									---command
									when 15 =>
										comm_out_data <= ho_2_cam;     ----dst_id 
									when 16 =>
										comm_out_data <= set_camera_number;    ----src_id
									when 17 =>
										comm_out_data <= X"05";     ----command :   
									when 18 =>
										comm_out_data <= X"04";   ----size of command
									when 19 =>
										comm_out_data <= loc1_x;   
									when 20 =>
										comm_out_data <= loc1_y;   
									when 21 =>
										comm_out_data <= loc2_x;   
									when 22 =>
										comm_out_data <= loc2_y;   
								when others =>
									comm_out_src_rdy_n <= '1';
									pixel_forward_finish <= '1';
									pixel_factor_counter <= 0;
									header_pixel_counter <= header_pixel_counter + 1;
							end case;
						else 
							case pixel_factor_counter is 
								when 0 =>
									comm_out_src_rdy_n <= '1';
								when 1 =>
										comm_out_src_rdy_n <= '0';     ----start source ready
										comm_out_data <= X"03";   --
									when 2 =>
										comm_out_data <= X"03";   --
									when 3 =>
										comm_out_data <= X"03";   --
								when others =>
									comm_out_src_rdy_n <= '1';
									pixel_forward_finish <= '1';
									pixel_factor_counter <= 0;
									header_pixel_counter <= header_pixel_counter + 1;
							end case;
						end if;
						
						
						if header_pixel_counter = 1 then
							handover_packet_finish <= '0';
							active_comm_out_sof_n <= '1';
						elsif header_pixel_counter = 2 then   --- header_pixel_counter = HEADER_SIZE
							active_comm_out_eof_n <= '1';   --- header_pixel_counter = HEADER_SIZE
						elsif header_pixel_counter = 3 then   --- header_pixel_counter = HEADER_SIZE
							handover_packet_finish <= '1';
							header_pixel_counter <= 0;
						else
							active_comm_out_sof_n <= '0';
							active_comm_out_eof_n <= '0';					
						end if;
						
						if ( active_comm_out_sof_n = '1' and active_comm_out_sof_n_delay = '0' ) then
							comm_out_sof_n <= '0';	
						else
							comm_out_sof_n <= '1';	
						end if;
						
						if ( active_comm_out_eof_n = '1' and active_comm_out_eof_n_delay = '0' ) then
							comm_out_eof_n_in <= '0';		
						else
							comm_out_eof_n_in <= '1';	
						end if;
					end if;
				
				
				when others =>
					------change to next state
					present_state <= initial_state;
			end case;
		end if;
	end process;



	------------------------------------------------------
   --receive packets state machine process 
   ------------------------------------------------------
	receive_packets: process ( clk, rst, rx_ready, comm_in_sof_n, comm_in_sof_n_delay,  set_camera_number, 
	                 dst_id, rx_finish, rx_active_frame, comm_in_src_rdy_n, src_mac_0, src_mac_1, src_mac_5, 
						  protocol_0, protocol_1, src_id, dst_id, command_type ) is 
	
	begin 
		if ( rst = '1' ) then             --enable with high value
			rx_present_state <= rx_wait_state;
			rx_finish <= '0';
			data_in_counter <= 0;
			rx_ready <= '0';
			rx_active_frame <= '0';
		else
			if button_size = '0' and button_up = '0' and button_up_delay = '1' then   ---move up
				loc1_y <= loc1_y - 1;
				loc2_y <= loc2_y - 1;
			elsif button_size = '0' and button_down = '0' and button_down_delay = '1' then  ----move down
				loc1_y <= loc1_y + 1;
				loc2_y <= loc2_y + 1;
			elsif button_size = '0' and button_left = '0' and button_left_delay = '1' then ----move left
				loc1_x <= loc1_x - 1;
				loc2_x <= loc2_x - 1;
			elsif button_size = '0' and button_right = '0' and button_right_delay = '1' then ----move right
				loc1_x <= loc1_x + 1;
				loc2_x <= loc2_x + 1;
			elsif button_size = '1' and  button_up = '0' and button_up_delay = '1' then   -----vertical direction bigger
				loc1_y <= loc1_y - 1;
				loc2_y <= loc2_y + 1;
			elsif button_size = '1' and button_down = '0' and button_down_delay = '1' then  ----vertical direction smaller
				loc1_y <= loc1_y + 1;
				loc2_y <= loc2_y - 1;
			elsif button_size = '1' and button_left = '0' and button_left_delay = '1' then ----horizontal direction bigger
				loc1_x <= loc1_x - 1;
				loc2_x <= loc2_x + 1;
			elsif button_size = '1' and button_right = '0' and button_right_delay = '1' then ----horizontal direction smaller
				loc1_x <= loc1_x + 1;
				loc2_x <= loc2_x - 1;
			end if;
			if ( rising_edge(clk) ) then 
				case rx_present_state is 
					when rx_wait_state =>
						if rx_ready = '1' then 
							------change to next state
							rx_present_state <= receive_state;   
						end if;
						rx_ready <= '1';
						rx_finish <= '0';
						comm_in_dst_rdy_n <= '0';
						dummy_comm_in_dst_rdy_n <= '0';
						data_in_counter <= 0;
						rx_active_frame <= '0';

					
					when receive_state =>	
						if rx_finish = '1' then
							------change to next state
							rx_present_state <= rx_wait_state;
						else
							rx_ready <= '0';
							------what u wannna do in this state
							if comm_in_sof_n = '0' and comm_in_sof_n_delay = '1' then
								rx_active_frame <= '1';
							elsif comm_in_eof_n = '1' and comm_in_eof_n_delay1 = '0' then
								rx_active_frame <= '0';
							end if;
							
							if rx_active_frame = '0' then	
								dest_mac_0 <= comm_in_data;
							elsif rx_active_frame = '1' then
								if comm_in_src_rdy_n = '0' then 
									data_in_counter <= data_in_counter + 1;
									case data_in_counter is 
									when 0 =>
										dest_mac_1 <= comm_in_data;
									when 1 =>
										dest_mac_2 <= comm_in_data;
									when 2 =>
										dest_mac_3 <= comm_in_data;
									when 3 =>
										dest_mac_4 <= comm_in_data;
									when 4 =>
										dest_mac_5 <= comm_in_data;
										
										
									when 5 =>
										src_mac_0 <= comm_in_data;
									when 6 =>
										src_mac_1 <= comm_in_data;
									when 7 =>
										src_mac_2 <= comm_in_data;
									when 8 =>
										src_mac_3 <= comm_in_data;
									when 9 =>
										src_mac_4 <= comm_in_data;
									when 10 =>
										src_mac_5 <= comm_in_data;
										
									when 11 =>
										--if src_mac_0 = X"00" and src_mac_1 = X"1b" and src_mac_5 = X"52" then 
											protocol_0 <= comm_in_data;
										--else
											--rx_finish <= '1';
										--end if;
									when 12 =>
										--if src_mac_0 = X"00" and src_mac_1 = X"1b" and src_mac_5 = X"52" then 
											protocol_1 <= comm_in_data;
										--else
											--rx_finish <= '1';
										--end if;
										
									---------------------------	
									when 13 =>
										if  protocol_0 = X"08" and protocol_1 = X"00" then
											 dst_id <= comm_in_data;
										else
											rx_finish <= '1';
										end if;
									when 14 =>
										if  protocol_0 = X"08" and protocol_1 = X"00" then
											src_id <= comm_in_data;	
										else
											rx_finish <= '1';
										end if;
									when 15 =>
										--if src_id = X"f0"  and  dst_id = set_camera_number then
										if dst_id = set_camera_number then
											command_type <= comm_in_data;
										else
											rx_finish <= '1';
										end if;		
									when 16 =>
										--if src_id = X"f0"  and  dst_id = set_camera_number then
										if dst_id = set_camera_number then
											rx_command_size <= comm_in_data;
										else
											rx_finish <= '1';
										end if;	
									when 17 =>
										if command_type = X"02" or command_type = X"05" then
											loc1_x <= comm_in_data;
											active_handover <= '0';
										elsif command_type = X"04" then
											ho_2_cam <= comm_in_data;
											active_handover <= '1';
										else 
											active_handover <= '0';
										end if;
									when 18 =>
										if command_type = X"02"  or command_type = X"05" then
											loc1_y <= comm_in_data;
										elsif command_type = X"04" then
											active_handover <= '1';
										else
											rx_finish <= '1';
										end if;
									when 19 =>
										if command_type = X"02"  or command_type = X"05" then
											loc2_x <= comm_in_data;
										elsif command_type = X"04" then
											active_handover <= '1';	
										else
											rx_finish <= '1';
										end if;
									when 20 =>
										if command_type = X"02"  or command_type = X"05" then
											loc2_y <= comm_in_data;
										elsif command_type = X"04" then
											active_handover <= '0';	
										else
											rx_finish <= '1';
										end if;
										
									when others =>
										rx_finish <= '1';
										data_in_counter <= 0;
										
								end case;				
							end if;
						end if;
					end if;
						
					when others =>
						------change to next state
						rx_present_state <= rx_wait_state;
				end case;
			end if;
		end if;
	end process; 



end IMP;
