-----------------------------------------------------------------------------
---**************************************************************************
---***GET FRAMES FROM FMC MODULE AND SEND THEM OVER THE NETWORK-ON-CHIP   ***
---***Author:     Markus Happe                                            ***
---***Date:       08.2013                                                 ***
---**************************************************************************
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

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
	 video_in_clk              : in  std_logic;	 
    video_in_vblank           : in  std_logic;
    video_in_hblank           : in  std_logic;
    video_in_de               : in  std_logic;
    video_in_data             : in  std_logic_vector(RGB_DATA_DWIDTH-1 downto 0);
    tx_ll_sof_n               : out std_logic;         ----active low 
    tx_ll_eof_n               : out std_logic;         ----active low 
    tx_ll_data             	: out std_logic_vector(7 downto 0);
    tx_ll_src_rdy_n        	: out std_logic;         ----active low  
    tx_ll_dst_rdy_n          	: in  std_logic;          ----active low
    rx_ll_sof_n             	: in  std_logic;          ----active low
    rx_ll_eof_n             	: in  std_logic;          ----active low
    rx_ll_data              	: in  std_logic_vector(7 downto 0);
    rx_ll_src_rdy_n         	: in  std_logic;          ----active low
    rx_ll_dst_rdy_n         	: out std_logic;          ----active low
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

	constant C_SCALE_DIVISOR          : integer := 4; --10;--4; -- 6; --4; --10; --20; --40;
	constant C_PIXEL_PER_LINE         : integer := FRAME_WIDTH/C_SCALE_DIVISOR;

	-- IMPORTANT: define size of local RAM here!!!! 
	constant C_LOCAL_RAM_SIZE          : integer := (FRAME_WIDTH/C_SCALE_DIVISOR)*(FRAME_HEIGHT/C_SCALE_DIVISOR);
	constant C_LOCAL_RAM_ADDRESS_WIDTH : integer := clog2(C_LOCAL_RAM_SIZE);
	constant C_LOCAL_RAM_SIZE_IN_BYTES : integer := 4*C_LOCAL_RAM_SIZE;

	type LOCAL_MEMORY_T is array (0 to C_LOCAL_RAM_SIZE-1) of std_logic_vector(31 downto 0);
	signal o_RAMAddr_com : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	signal o_RAMData_com : std_logic_vector(31 downto 0);
	signal o_RAMWE_com   : std_logic;
	signal i_RAMData_com : std_logic_vector(31 downto 0);

	signal o_RAMAddr_video   : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	signal o_RAMAddr_video_next : std_logic_vector(C_LOCAL_RAM_ADDRESS_WIDTH-1 downto 0);
	signal o_RAMData_video   : std_logic_vector(31 downto 0);
	signal o_RAMWE_video     : std_logic;
	signal i_RAMData_video   : std_logic_vector(31 downto 0);

	shared variable local_ram : LOCAL_MEMORY_T;
	
	signal size_x : std_logic_vector(31 downto 0);
	signal size_y : std_logic_vector(31 downto 0);
	signal size_frame : std_logic_vector(31 downto 0);
	signal divisor : std_logic_vector(31 downto 0);
	
	signal video_in_hblank_last : std_logic := '0';
	signal video_in_vblank_last : std_logic := '0';
	signal video_in_de_last : std_logic := '0';
	
	signal get_frame_en   : std_logic := '0';
	signal get_frame_done : std_logic := '0';
	
	signal send_frame_en   : std_logic := '0';
	signal send_frame_done : std_logic := '0';
	
	signal send_line_en   : std_logic := '0';
	signal send_line_done : std_logic := '0';
	
	signal frame_cnt : std_logic_vector(31 downto 0);
	
	signal line_cnt : std_logic_vector(31 downto 0);
	signal line_cnt_next : std_logic_vector(31 downto 0);
	signal parameter_size : std_logic_vector(31 downto 0);
	
	signal line_a   : std_logic_vector(23 downto 0);
	signal line_b   : std_logic_vector(23 downto 0);
	signal line_sel : std_logic;
	signal debug_r : std_logic_vector(7 downto 0);
	signal debug_g : std_logic_vector(7 downto 0);
	signal debug_b : std_logic_vector(7 downto 0);

	signal line_tx_ll_sof_n      : std_logic;     
	signal line_tx_ll_eof_n      : std_logic;    
	signal line_tx_ll_data       : std_logic_vector(7 downto 0);
	signal line_tx_ll_src_rdy_n  : std_logic; 
	
	signal camera_id : std_logic_vector(7 downto 0); 
	signal debug_step_line : std_logic_vector(4 downto 0);
	signal debug_pxl_cnt : std_logic_vector(31 downto 0);

begin

	-- local dual-port RAM
	local_ram_ctrl_1 : process (video_in_clk) is
	begin
		if (rising_edge(video_in_clk)) then
			if (o_RAMWE_video = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_video))) := o_RAMData_video;
			else
				i_RAMData_video <= local_ram(conv_integer(unsigned(o_RAMAddr_video)));
			end if;
		end if;
	end process;
			
	local_ram_ctrl_2 : process (clk) is
	begin
		if (rising_edge(clk)) then		
			if (o_RAMWE_com = '1') then
				local_ram(conv_integer(unsigned(o_RAMAddr_com))) := o_RAMData_com;
			else
				i_RAMData_com <= local_ram(conv_integer(unsigned(o_RAMAddr_com)));
			end if;
		end if;
	end process;
	
	store_control_signal_changes : process (video_in_clk) is
	begin
		if (rising_edge(video_in_clk)) then
			video_in_hblank_last <= video_in_hblank;
			video_in_vblank_last <= video_in_vblank;
			video_in_de_last     <= video_in_de;
		end if;
	end process;
	
	-- main process: (1) grab frame, (2) send frame, goto (1)
	control_proc: process(clk,rst) is
		variable step : natural range 0 to 1;
	begin
		if (rst='1') then
			divisor    <= X"00000004";--X"0000000A";
			size_x     <= X"000001E0";--X"000000C0";
			size_y     <= X"0000010E";--X"0000006C";
			size_frame <= X"0001FA40";--X"00005100";		
			get_frame_en  <= '0';
			send_frame_en <= '0';
			frame_cnt <= (others=>'0');
			step := 0;
		elsif (rising_edge(clk)) then
			get_frame_en  <= '0';
			send_frame_en <= '0';
			case step is 
				when 0 => -- grab frame
					get_frame_en <= '1';
					if (get_frame_done = '1') then
						get_frame_en  <= '0';
						frame_cnt <= frame_cnt + 1;
						step := step + 1;
					end if;
				when 1 => --send frame
					send_frame_en <= '1';
					if (send_frame_done = '1') then
						send_frame_en <= '0';				
						step := step - 1;
					end if;				
			end case;
		end if;
	end process; 
	
	-- process: send frame by sending one line after the other 
	send_frame: process(clk,rst,send_frame_en) is
		variable step : natural range 0 to 2;
	begin
		if (rst='1' or send_frame_en='0') then 
			send_frame_done <= '0';
			send_line_en    <= '0';
			line_cnt <= (others=>'0');
			step     := 0;
		elsif (rising_edge(clk)) then
			send_line_en <= '0';
			case step is 
				when 0 => -- get first line
					send_line_en <= '1';
					if (send_line_done = '1') then
						line_cnt <= line_cnt + 1;
						step := step + 1;
					end if;

				when 1 => -- get next line or stop?
					if (size_y <= line_cnt) then
						step := step + 1;
					else
						step := step - 1;
					end if;
				
				when 2 => -- all lines have been sent
					send_frame_done <= '1';				
			end case;
		end if;
	end process;
	
	
	tx_ll_sof_n <= line_tx_ll_sof_n;
	tx_ll_eof_n <= line_tx_ll_eof_n;
	tx_ll_src_rdy_n <= line_tx_ll_src_rdy_n;
	tx_ll_data      <= line_tx_ll_data;
	
	-- process that sends current line to tx_ll 
	send_line : process(clk,rst,send_line_en,send_frame_en) is
		variable step       : natural range 0 to 19;
		variable pixel_cnt  : natural range 0 to FRAME_HEIGHT;
		variable header_cnt : natural range 0 to 11;  
	begin
		if (rst = '1' or send_line_en = '0') then
			o_RAMWE_com     <= '0';
			if (rst ='1' or send_frame_en = '0') then
				o_RAMAddr_com   <= (others=>'0');
			end if;
			line_sel        <= '0';
			line_a          <= (others=>'0');
			line_b          <= (others=>'0');
			o_RAMData_com   <= (others=>'0');
			line_tx_ll_sof_n     <= '1';
			line_tx_ll_eof_n     <= '1';
			line_tx_ll_data      <= (others=>'1');
			line_tx_ll_src_rdy_n <= '1';
			send_line_done  <= '0';
			line_cnt_next   <= (others=>'0');
			pixel_cnt := 0;
			debug_step_line <= (others=>'0');
			debug_pxl_cnt <= (others=>'0');
			step := 0;
		elsif (rising_edge(clk)) then
			line_tx_ll_data  <= (others => '1');
			line_tx_ll_sof_n <= '1';
			line_tx_ll_eof_n <= '1';
			line_tx_ll_src_rdy_n <= '0';
			case step is
				when 0 => -- start of ETH header
					line_tx_ll_data    <= X"FF";
					line_tx_ll_sof_n <= '0';
					if tx_ll_dst_rdy_n = '0' then
						header_cnt := 2;
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;	
				when 1 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data    <= X"FF";
						if (10 <= header_cnt) then
							debug_step_line <= debug_step_line + 1;
							step := step + 1;
						else
							header_cnt := header_cnt + 1;
						end if;
					end if;		
				when 2 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= camera_id;
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 3 => 
					if tx_ll_dst_rdy_n = '0' then
						parameter_size <= size_x;
						line_tx_ll_data <= X"AC";
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 4 =>  -- end of ETH header
					if tx_ll_dst_rdy_n = '0' then
						parameter_size <= parameter_size + size_x;
						line_tx_ll_data <= X"DC";
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 5 => -- start of smart cam header
					if tx_ll_dst_rdy_n = '0' then
						parameter_size <= parameter_size + size_x;
						line_tx_ll_data <= X"F0"; -- destination: GUI at workstation
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 6 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= camera_id;
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 7 => 
					if tx_ll_dst_rdy_n = '0' then
						parameter_size <= parameter_size + 6; -- parameter size = 3*size_x + 6 -- used to be 5
						line_tx_ll_data <= X"01"; -- command: send compressed video frame
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 8 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= parameter_size(15 downto 8); -- parameter size: 6 + size_x*3 (1/2)
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 9 => 
					if tx_ll_dst_rdy_n = '0' then
						line_cnt_next <= line_cnt + 1;
						line_tx_ll_data <= parameter_size(7 downto 0); -- parameter size: 6 + size_x*3 (2/2)
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 10 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= line_cnt_next(15 downto 8); -- line number (1/2)
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 11 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= line_cnt_next(7 downto 0); -- line number (2/2)
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 12 =>
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= frame_cnt(31 downto 24); -- frame no.
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 13 =>
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= frame_cnt(23 downto 16);
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 14 => 
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= frame_cnt(15 downto 8);
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 15 => -- end of smart cam header
					if tx_ll_dst_rdy_n = '0' then
						line_tx_ll_data <= frame_cnt(7 downto 0);
						line_sel <= '0';
						line_a(23 downto 0) <= i_RAMData_com(23 downto 0);
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 16 => -- start of sending pixel data: first byte
					if tx_ll_dst_rdy_n = '0' then
						pixel_cnt := pixel_cnt + 1;
						debug_pxl_cnt <= debug_pxl_cnt + 1;
						o_RAMAddr_com <= o_RAMAddr_com + 1; -- get next pixel
						if (line_sel='0') then
							line_tx_ll_data <= line_a(23 downto 16);
						else
							line_tx_ll_data <= line_b(23 downto 16);
						end if;
						--line_tx_ll_data <= i_RAMData_com(23 downto 16);
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 17 => -- second byte
					if tx_ll_dst_rdy_n = '0' then
						if (line_sel='0') then
							line_tx_ll_data <= line_a(15 downto 8);
						else
							line_tx_ll_data <= line_b(15 downto 8);
						end if;
						--line_tx_ll_data <= i_RAMData_com(15 downto 8);
						debug_step_line <= debug_step_line + 1;
						step := step + 1;
					end if;
				when 18 => -- third byte
					if tx_ll_dst_rdy_n = '0' then
						if (line_sel='0') then
							line_b(23 downto 0) <= i_RAMData_com(23 downto 0); 
							line_tx_ll_data <= line_a(7 downto 0);
						else
							line_a(23 downto 0) <= i_RAMData_com(23 downto 0); 
							line_tx_ll_data <= line_b(7 downto 0);
						end if;
						line_sel <= not line_sel;
						--line_tx_ll_data <= i_RAMData_com(7 downto 0);
						if (size_x <= pixel_cnt) then
							line_tx_ll_eof_n <= '0';
							debug_step_line <= debug_step_line + 1;
							step := step + 1;
						else
							debug_step_line <= debug_step_line - 2;
							step := step - 2;
						end if;
					end if;						
				when 19 => -- finished sending frame
					send_line_done <= '1';
			end case;
		end if;
	end process;
	
--	-- process that sends current line to tx_ll 
--	send_line : process(clk,rst,send_line_en,send_frame_en) is
--		variable step       : natural range 0 to 19;
--		variable pixel_cnt  : natural range 0 to FRAME_HEIGHT;
--		variable header_cnt : natural range 0 to 11;  
--	begin
--		if (rst = '1' or send_line_en = '0') then
--			o_RAMWE_com     <= '0';
--			if (rst ='1' or send_frame_en = '0') then
--				o_RAMAddr_com   <= (others=>'0');
--			end if;
--			line_sel        <= '0';
--			line_a          <= (others=>'0');
--			line_b          <= (others=>'0');
--			o_RAMData_com   <= (others=>'0');
--			tx_ll_sof_n     <= '1';
--			tx_ll_eof_n     <= '1';
--			tx_ll_data      <= (others=>'1');
--			tx_ll_src_rdy_n <= '1';
--			rx_ll_dst_rdy_n <= '0';
--			send_line_done  <= '0';
--			line_cnt_next   <= (others=>'0');
--			pixel_cnt := 0;
--			step := 0;
--		elsif (rising_edge(clk)) then
--			tx_ll_data  <= (others => '1');
--			tx_ll_sof_n <= '1';
--			tx_ll_eof_n <= '1';
--			tx_ll_src_rdy_n <= '0';
--			case step is
--				when 0 => -- start of ETH header
--					tx_ll_data    <= X"FF";
--					tx_ll_sof_n <= '0';
--					if tx_ll_dst_rdy_n = '0' then
--						header_cnt := 2;
--						step := step + 1;
--					end if;
--					
--				when 1 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data    <= X"FF";
--						if (10 <= header_cnt) then
--							step := step + 1;
--						else
--							header_cnt := header_cnt + 1;
--						end if;
--					end if;
--					
--				when 2 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= "0000" & switch_camera_4 & switch_camera_3 & switch_camera_2 & switch_camera_1;
--						step := step + 1;
--					end if;
--					
--				when 3 => 
--					if tx_ll_dst_rdy_n = '0' then
--						parameter_size <= size_x;
--						tx_ll_data <= X"AC";
--						step := step + 1;
--					end if;
--					
--				when 4 =>  -- end of ETH header
--					if tx_ll_dst_rdy_n = '0' then
--						parameter_size <= parameter_size + size_x;
--						tx_ll_data <= X"DC";
--						step := step + 1;
--					end if;
--
--				when 5 => -- start of smart cam header
--					if tx_ll_dst_rdy_n = '0' then
--						parameter_size <= parameter_size + size_x;
--						tx_ll_data <= X"F0"; -- destination: GUI at workstation
--						step := step + 1;
--					end if;
--
--				when 6 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= "0000" & switch_camera_4 & switch_camera_3 & switch_camera_2 & switch_camera_1;
--						step := step + 1;
--					end if;
--
--				when 7 => 
--					if tx_ll_dst_rdy_n = '0' then
--						parameter_size <= parameter_size + 6; -- parameter size = 3*size_x + 6 -- used to be 5
--						tx_ll_data <= X"01"; -- command: send compressed video frame
--						step := step + 1;
--					end if;
--
--				when 8 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= parameter_size(15 downto 8); -- parameter size: 6 + size_x*3 (1/2)
--						step := step + 1;
--					end if;
--					
--				when 9 => 
--					if tx_ll_dst_rdy_n = '0' then
--						line_cnt_next <= line_cnt + 1;
--						tx_ll_data <= parameter_size(7 downto 0); -- parameter size: 6 + size_x*3 (2/2)
--						step := step + 1;
--					end if;
--
--				when 10 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= line_cnt_next(15 downto 8); -- line number (1/2)
--						step := step + 1;
--					end if;
--					
--				when 11 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= line_cnt_next(7 downto 0); -- line number (2/2)
--						step := step + 1;
--					end if;
--
--				when 12 =>
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= frame_cnt(31 downto 24); -- frame no.
--						step := step + 1;
--					end if;
--
--				when 13 =>
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= frame_cnt(23 downto 16);
--						step := step + 1;
--					end if;
--
--				when 14 => 
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= frame_cnt(15 downto 8);
--						step := step + 1;
--					end if;
--
--				when 15 => -- end of smart cam header
--					if tx_ll_dst_rdy_n = '0' then
--						tx_ll_data <= frame_cnt(7 downto 0);
--						line_sel <= '0';
--						line_a(23 downto 0) <= i_RAMData_com(23 downto 0);
--						step := step + 1;
--					end if;
--
--				when 16 => -- start of sending pixel data: first byte
--					if tx_ll_dst_rdy_n = '0' then
--						pixel_cnt := pixel_cnt + 1;
--						o_RAMAddr_com <= o_RAMAddr_com + 1; -- get next pixel
--						if (line_sel='0') then
--							tx_ll_data <= line_a(23 downto 16);
--						else
--							tx_ll_data <= line_b(23 downto 16);
--						end if;
--						--tx_ll_data <= i_RAMData_com(23 downto 16);
--						step := step + 1;
--					end if;
--
--				when 17 => -- second byte
--					if tx_ll_dst_rdy_n = '0' then
--						if (line_sel='0') then
--							tx_ll_data <= line_a(15 downto 8);
--						else
--							tx_ll_data <= line_b(15 downto 8);
--						end if;
--						--tx_ll_data <= i_RAMData_com(15 downto 8);
--						step := step + 1;
--					end if;
--
--				when 18 => -- third byte
--					if tx_ll_dst_rdy_n = '0' then
--						if (line_sel='0') then
--							line_b(23 downto 0) <= i_RAMData_com(23 downto 0); 
--							tx_ll_data <= line_a(7 downto 0);
--						else
--							line_a(23 downto 0) <= i_RAMData_com(23 downto 0); 
--							tx_ll_data <= line_b(7 downto 0);
--						end if;
--						line_sel <= not line_sel;
--						--tx_ll_data <= i_RAMData_com(7 downto 0);
--						if (size_x <= pixel_cnt) then
--							tx_ll_eof_n <= '0';
--							step := step + 1;
--						else
--							step := step - 2;
--						end if;
--					end if;						
--				
--				when 19 => -- finished sending frame
--					send_line_done <= '1';
--			end case;
--		end if;
--	end process;
	
	-- process that strores next frame to local memory
	get_next_frame : process(video_in_clk,rst,get_frame_en) is
		variable step    : natural range 0 to 2;
		variable counter : natural range 0 to 2097151;
		variable line_counter   : natural range 0 to 2047;
		variable pixel_counter  : natural range 0 to 2047;
		variable pixel_per_line_counter  : natural range 0 to 2047;
		variable active_line : std_logic;
	begin
		if (rst = '1' or get_frame_en = '0') then
			get_frame_done   <= '0';
			o_RAMWE_video    <= '0';
			o_RAMAddr_video  <= (others=>'0');
			o_RAMData_video  <= (others=>'0');
			o_RAMAddr_video_next <= (others=>'0');
			debug_r <= X"01";
			debug_g <= X"11";
			debug_b <= X"21";
			pixel_per_line_counter := 0;
			line_counter  := 0;
			pixel_counter := 0;
			active_line   := '0';
			counter := 0;
			step    := 0;
		elsif rising_edge(video_in_clk) then
			o_RAMWE_video  <= '0';
			case step is
			
					when 0 => -- wait for start of next frame
						if (video_in_vblank_last='1' and video_in_vblank='0') then
							o_RAMAddr_video  <= (others=>'0');
							o_RAMAddr_video_next <= (others=>'0');
							line_counter := 0;
							counter      := 0;
							step := step + 1;
						end if;				
					
					when 1 => -- store pixels
						-- frame already stored? 
						if (size_frame <= counter) then
							step := step + 1;
						-- start of line
						elsif ( video_in_de_last='0' and video_in_de='1' and video_in_hblank='0' and video_in_vblank_last='0' and video_in_vblank='0' ) then -- and video_in_de_last='0' and video_in_de='1') then
							-- store first pixel of each 'C_SCALE_DIVISOR'th line
							--if (line_counter = 0 or line_counter = C_SCALE_DIVISOR) then
							if (line_counter = 0 or divisor <= line_counter) then
								pixel_per_line_counter := 1;
								active_line   := '1';
								pixel_counter := 1;
								line_counter := 1;
								-- store first pixel of active line
								o_RAMAddr_video <= o_RAMAddr_video_next;		
								if (switch_camera_1 = '0' and switch_camera_2 = '0' and switch_camera_3 = '0' and switch_camera_4 = '0') then
									debug_r <= X"02";
									debug_g <= X"12";
									debug_b <= X"22";
									o_RAMData_video <= X"00" & X"01" & X"11" & X"21"; --video_in_data;
								else
									o_RAMData_video <= X"00" & video_in_data;
								end if;
								o_RAMWE_video   <= '1';
								o_RAMAddr_video_next <= o_RAMAddr_video_next + 1;
								counter := counter + 1;
							else 
								active_line := '0';
								line_counter := line_counter + 1;
							end if;
						-- pixel of active line
						elsif (active_line = '1' and video_in_hblank_last='0'  and video_in_de_last='1' and video_in_de='1' and video_in_hblank='0' and video_in_vblank_last='0' and video_in_vblank='0') then
							-- each 'C_SCALE_DIVISOR'th pixel of line
							--if (pixel_counter = C_SCALE_DIVISOR or pixel_counter = 0) then
							if (divisor <= pixel_counter or pixel_counter = 0) then
								pixel_counter := 1;--0;
								--if (pixel_per_line_counter<C_PIXEL_PER_LINE) then
								if (pixel_per_line_counter<size_x) then
									pixel_per_line_counter := pixel_per_line_counter + 1;
									-- store 'C_SCALE_DIVISOR'th pixel
									o_RAMAddr_video <= o_RAMAddr_video_next;
									if (switch_camera_1 = '0' and switch_camera_2 = '0' and switch_camera_3 = '0' and switch_camera_4 = '0') then
										debug_r <= debug_r + 1;
										debug_g <= debug_g + 1;
										debug_b <= debug_b + 1;
										o_RAMData_video <= X"00" & debug_r & debug_g & debug_b; --video_in_data;
									else
										o_RAMData_video <= X"00" & video_in_data;
									end if;
									o_RAMWE_video   <= '1';
									o_RAMAddr_video_next <= o_RAMAddr_video_next + 1;
									counter := counter + 1;
								end if;
							else
								pixel_counter := pixel_counter + 1;
							end if;
						end if;
		
					when 2 => -- frame completely stored to local RAM	
						get_frame_done <= '1';		
			end case;
		end if;
	end process;
	


end IMP;
