------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           2.00.a
-- Description:       User logic.
-- Date:              Mon Nov 10 11:53:26 2014 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    C_DEBUG_WIDTH : integer;
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 4
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
    debug			   : out std_logic_vector(C_DEBUG_WIDTH-1 downto 0);
    gpio_led			   : out std_logic_vector(0 to 7);		
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;


architecture IMP of user_logic is
------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------
--USER signal declarations added here, as needed for user logic
COMPONENT sem_v3_6
  PORT (
    status_heartbeat : 		OUT STD_LOGIC;
    status_initialization : 	OUT STD_LOGIC;
    status_observation : 	OUT STD_LOGIC;
    status_correction : 	OUT STD_LOGIC;
    status_classification : 	OUT STD_LOGIC;
    status_injection : 		OUT STD_LOGIC;
    status_essential : 		OUT STD_LOGIC;
    status_uncorrectable : 	OUT STD_LOGIC;
    monitor_txdata : 		OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    monitor_txwrite : 		OUT STD_LOGIC;
    monitor_txfull : 		IN STD_LOGIC;
    monitor_rxdata : 		IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    monitor_rxread : 		OUT STD_LOGIC;
    monitor_rxempty : 		IN STD_LOGIC;
    inject_strobe : 		IN STD_LOGIC;
    inject_address : 		IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    icap_busy : 		IN STD_LOGIC;
    icap_o : 			IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    icap_csb : 			OUT STD_LOGIC;
    icap_rdwrb : 		OUT STD_LOGIC;
    icap_i : 			OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    icap_clk : 			IN STD_LOGIC;
    icap_request : 		OUT STD_LOGIC;
    icap_grant : 		IN STD_LOGIC;
    fecc_crcerr : 		IN STD_LOGIC;
    fecc_eccerr : 		IN STD_LOGIC;
    fecc_eccerrsingle : 	IN STD_LOGIC;
    fecc_syndromevalid : 	IN STD_LOGIC;
    fecc_syndrome : 		IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    fecc_far : 			IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    fecc_synbit : 		IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    fecc_synword : 		IN STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END COMPONENT;
component sem_v3_6_sem_mon
  port (
    icap_clk                    : in    std_logic;
    monitor_tx                  : out   std_logic;
    monitor_rx                  : in    std_logic;
    monitor_txdata              : in    std_logic_vector(7 downto 0);
    monitor_txwrite             : in    std_logic;
    monitor_txfull              : out   std_logic;
    monitor_rxdata              : out   std_logic_vector(7 downto 0);
    monitor_rxread              : in    std_logic;
    monitor_rxempty             : out   std_logic
    );
 end component;



  --USER signal declarations added here, as needed for user logic
  type cmd_type is  (NOP,IDLE,INJECTION,STATUS,RESET,OBSERVATION);  --type of Commands.
  signal cmd_exe: cmd_type := NOP;  

  type execution_state is (WAITING,CMD_DECODE,NOP_EXE,IDLE_EXE,INJECTION_EXE,
				STATUS_EXE,RESET_EXE,OBSERVATION_EXE,OBS_ACK_WAIT,SEM_EXE,IDLE_ACK_WAIT,INJ_ACK_WAIT);  --CMD EXECUTION STATES.
  signal main_current_state,main_next_state,main_prev_state : execution_state := WAITING ;  --current and next state declaration.

  signal cmd_exetest: cmd_type := NOP;  
  signal sem_status_flags : bit_vector (0 to 3);

  constant FIFO_DATA_WIDTH : positive := 8;


  signal status_heartbeat : 		STD_LOGIC;
  signal status_initialization :  	STD_LOGIC; 
  signal status_observation :     	STD_LOGIC;
  signal status_correction :      	STD_LOGIC;
  signal status_classification :  	STD_LOGIC;
  signal status_injection :  		STD_LOGIC;
  signal status_essential :  		STD_LOGIC;
  signal status_uncorrectable :  		STD_LOGIC;
  signal monitor_txdata : 		STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal monitor_txwrite :  		STD_LOGIC;
  signal monitor_txfull :  		STD_LOGIC;
  signal monitor_rxdata :  		STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal monitor_rxread :  		STD_LOGIC;
  signal monitor_rxempty :  		STD_LOGIC;
  signal inject_strobe : 			STD_LOGIC;
  signal inject_address :  		STD_LOGIC_VECTOR(35 DOWNTO 0);
  signal icap_busy :  			STD_LOGIC;
  signal icap_o :  			STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal icap_csb :  			STD_LOGIC;
  signal icap_rdwrb :  			STD_LOGIC;
  signal icap_i :  			STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal icap_clk :  			STD_LOGIC;
  signal icap_request :  			STD_LOGIC;
  signal icap_grant : 			STD_LOGIC;
  signal fecc_crcerr :  			STD_LOGIC;
  signal fecc_eccerr :  			STD_LOGIC;
  signal fecc_eccerrsingle :  		STD_LOGIC;
  signal fecc_syndromevalid :  		STD_LOGIC;
  signal fecc_syndrome : 			STD_LOGIC_VECTOR(12 DOWNTO 0);
  signal fecc_far :  			STD_LOGIC_VECTOR(23 DOWNTO 0);
  signal fecc_synbit :  			STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal fecc_synword : 			STD_LOGIC_VECTOR(6 DOWNTO 0);
  signal USB_1_TX:  		STD_LOGIC;
  signal USB_1_RX :  		STD_LOGIC;

-- Counter and related signlas
  signal count_1 :			unsigned(7 downto 0) := x"00";
  signal ctr1_ld_val :			unsigned(7 downto 0) := x"00";
  signal capture_count_1 :		unsigned(7 downto 0) := x"FF";
  signal count_test :		        unsigned(7 downto 0) := x"FF";
  signal capture_en, capture_clr : 	std_logic;
  signal tick_cntr1 : 			std_logic ;
  signal cntr1_en : 			std_logic ;
  signal cntr1_rst : 			std_logic ;
  signal load_cntr1 : 			std_logic ;

  signal count_hb :			unsigned(7 downto 0) := x"FF";
  signal cntr_hb_en : 			std_logic ;
  signal cntr_hb_rst : 			std_logic ;

  
  signal sem_cmd_status: std_logic_vector(3 downto 0) ;

  signal inj_addr_36:  std_logic_vector(63 downto 0);
  signal sem_init_cnt: unsigned(7 downto 0) := x"00";
  signal rxdata_fifo:  std_logic_vector(0 to FIFO_DATA_WIDTH - 1);
  signal rxen_fifo :   STD_LOGIC;
  signal empty_fifo :  STD_LOGIC;
  signal full_fifo :   STD_LOGIC;
  signal dump_fifo :   STD_LOGIC;


  signal WrCE0_rcv :   std_logic ;
  signal slv0_chng:   std_logic ;
  signal slv0_prev :   std_logic_vector(0 to 4);

  signal wait_state:   std_logic ;
  signal obsexe_state:   std_logic ;
  signal idleexe_state:   std_logic ;
  signal injexe_state:   std_logic ;


  signal sem_init_chk 	: STD_LOGIC;
  signal sem_obs_chk 	: STD_LOGIC;
  signal sem_inj_chk 	: STD_LOGIC;
  signal sem_hb_chk   	: STD_LOGIC;
  signal my_status_reg  : std_logic_vector(0 to C_SLV_DWIDTH-1) := (others => '0');
  signal saved_status_reg  : std_logic_vector(0 to C_SLV_DWIDTH-1) := (others => '0');


  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg1                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg2                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg3                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 3);
  signal slv_reg_read_sel               : std_logic_vector(0 to 3);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin

  --USER logic implementation added here
---------------------------------------------------------------------------
  -- Instantiate the SEM Core.
---------------------------------------------------------------------------
sem_core : sem_v3_6
  PORT MAP (
    status_heartbeat => status_heartbeat,
    status_initialization => status_initialization,
    status_observation => status_observation,
    status_correction => status_correction,
    status_classification => status_classification,
    status_injection => status_injection,
    status_essential => status_essential,
    status_uncorrectable => status_uncorrectable,
    monitor_txdata => monitor_txdata,
    monitor_txwrite => monitor_txwrite,
    monitor_txfull => monitor_txfull,
    monitor_rxdata => monitor_rxdata,
    monitor_rxread => monitor_rxread,
    monitor_rxempty => monitor_rxempty,
    inject_strobe =>  inject_strobe,
    inject_address => inject_address,
    icap_busy => 	icap_busy,
    icap_o => 		icap_o,
    icap_csb => 	icap_csb,
    icap_rdwrb => 	icap_rdwrb,
    icap_i => 		icap_i,
    icap_clk => 	Bus2IP_Clk,
    icap_request => 	icap_request,
    icap_grant => 	icap_grant,
    fecc_crcerr => 	fecc_crcerr,
    fecc_eccerr => 	fecc_eccerr,
    fecc_eccerrsingle => fecc_eccerrsingle,
    fecc_syndromevalid => fecc_syndromevalid,
    fecc_syndrome => 	fecc_syndrome,
    fecc_far => 	fecc_far,
    fecc_synbit => 	fecc_synbit,
    fecc_synword => 	fecc_synword
  );
  ---------------------------------------------------------------------------
  -- Instantiate the SEM_MONITOR
  --------------------------------------------------------------------------- 
  example_mon : sem_v3_6_sem_mon
  port map (
    icap_clk 		=> Bus2IP_Clk,
    monitor_tx 		=> USB_1_TX,
    monitor_rx 		=> USB_1_RX,
    monitor_txdata 	=> monitor_txdata,
    monitor_txwrite 	=> monitor_txwrite,
    monitor_txfull 	=> monitor_txfull,
    monitor_rxdata 	=> monitor_rxdata,
    monitor_rxread 	=> monitor_rxread,
    monitor_rxempty 	=> monitor_rxempty
    );
  ---------------------------------------------------------------------------
  -- Instantiate the FRAME_ECC primitive.
  ---------------------------------------------------------------------------

  example_frame_ecc : FRAME_ECC_VIRTEX6
  generic map (
    FRAME_RBT_IN_FILENAME => "NONE",
    FARSRC => "EFAR"
    )
  port map (
    CRCERROR => 	fecc_crcerr,
    ECCERROR => 	fecc_eccerr,
    ECCERRORSINGLE => 	fecc_eccerrsingle,
    FAR => 		fecc_far,
    SYNBIT => 		fecc_synbit,
    SYNDROME => 	fecc_syndrome,
    SYNDROMEVALID => 	fecc_syndromevalid,
    SYNWORD => 		fecc_synword
    );
  ---------------------------------------------------------------------------
  -- Instantiate the ICAP primitive.
  ---------------------------------------------------------------------------

  example_icap : ICAP_VIRTEX6
  generic map (
    SIM_CFG_FILE_NAME => "NONE",
    DEVICE_ID => X"04250093",
    ICAP_WIDTH => "X32"
    )
  port map (
    BUSY => 	icap_busy,
    O => 	icap_o,
    CLK => 	Bus2IP_Clk,
    CSB => 	icap_csb,
    I => 	icap_i,
    RDWRB => 	icap_rdwrb
    );


	
  ---------------------------------------------------------------------------
  -- DEBUG SIGNALS 
  ---------------------------------------------------------------------------
  debug(0)    <= status_heartbeat;
  debug(1)    <= status_initialization;
  debug(2)    <= status_observation;
  debug(3)    <= status_injection ;

  debug(4)    <= Bus2IP_Clk;
  debug(5)    <= Bus2IP_RESET;

  debug(6)    <= Bus2IP_Data(0);
  debug(7)    <= Bus2IP_Data(1);
  debug(8)    <= Bus2IP_Data(2);
  debug(9)    <= Bus2IP_Data(3);
  debug(10)   <= Bus2IP_Data(4);
  debug(11)   <= Bus2IP_Data(5);
  debug(12)   <= Bus2IP_Data(6);
  debug(13)   <= Bus2IP_Data(7);
  debug(14)   <= Bus2IP_Data(8);

  debug(15)   <= Bus2IP_BE(0);
  debug(16)   <= Bus2IP_BE(1);
  debug(17)   <= Bus2IP_BE(2);
  debug(18)   <= Bus2IP_BE(3);

  debug(19)   <= Bus2IP_WrCE(0);
  debug(20)   <= Bus2IP_WrCE(1);
  debug(21)   <= Bus2IP_WrCE(2);
  debug(22)   <= Bus2IP_WrCE(3);

  debug(23)   <= Bus2IP_RdCE(0);
  debug(24)   <= Bus2IP_RdCE(1);
  debug(25)   <= Bus2IP_RdCE(2);
  debug(26)   <= Bus2IP_RdCE(3);

  debug(27)   <= inject_strobe;

  debug(28)   <= inject_address(32);
  debug(29)   <= inject_address(33);
  debug(30)   <= inject_address(34);
  debug(31)   <= inject_address(35);

  debug(32)   <= slv_reg0(0);
  debug(33)   <= slv_reg0(1);
  debug(34)   <= slv_reg0(2);
  debug(35)   <= slv_reg0(3);
  debug(36)   <= slv_reg0(4);

  debug(37)   <= slv0_chng;
  debug(38)   <= wait_state;

  debug(39)   <= slv_reg1(0);
  debug(40)   <= slv_reg1(1);
  debug(41)   <= slv_reg1(2);
  debug(42)   <= slv_reg1(3);
  debug(43)   <= slv_reg1(4);
  debug(44)   <= slv_reg1(5);
  debug(45)   <= slv_reg1(6);
  debug(46)   <= slv_reg1(7);
  debug(47)   <= slv_reg1(8);

  debug(48)   <= obsexe_state;
  debug(49)   <= idleexe_state;
  debug(50)   <= injexe_state;

  debug(51)   <= count_1(0);
  debug(52)   <= count_1(1);
  debug(53)   <= count_1(2);
  debug(54)   <= count_1(3);
  debug(55)   <= count_1(4);
  debug(56)   <= count_1(5);
  debug(57)   <= count_1(6);
  debug(58)   <= count_1(7);
  
  debug(59)   <= cntr1_en;
  debug(60)   <= cntr1_rst;


  debug(99 downto 61) <= (others => '0');



  gpio_led(0) <= status_heartbeat;
  gpio_led(1) <= status_initialization;
  gpio_led(2) <= status_observation;
  gpio_led(3) <= status_injection;
  gpio_led(4) <= slv_reg0(0);
  gpio_led(5) <= slv_reg0(1);
  gpio_led(6) <= slv_reg0(4);
  gpio_led(7) <= '1';


 inj_addr_36 <= slv_reg3 & slv_reg2;
  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 3);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 3);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        slv_reg0 <= (others => '0');
        --slv_reg1 <= (others => '0');
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg0(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg1(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg2(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg3(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, slv_reg0, slv_reg1, slv_reg2, slv_reg3 ) is
  begin

    case slv_reg_read_sel is
      when "1000" => slv_ip2bus_data <= slv_reg0;
      when "0100" => slv_ip2bus_data <= slv_reg1;
      when "0010" => slv_ip2bus_data <= slv_reg2;
      when "0001" => slv_ip2bus_data <= slv_reg3;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';



------------------------------------
--SEM INITIALIZATION STATUS Capture Process
------------------------------------
SEM_INIT_STATUS_PROC: process(Bus2IP_Clk,Bus2IP_Reset,status_initialization) 	 
   begin
       if(Bus2IP_Reset = '1') then
            sem_init_cnt <= x"00";
       elsif (Bus2IP_Clk'event and Bus2IP_Clk = '1' ) then     
	 if status_initialization = '1' then     
            if (sem_init_cnt = x"FF") then	
	    	sem_init_cnt <= x"00";
	    else 
		sem_init_cnt <= sem_init_cnt + 1;                        --Increment 
       	    end if;
	 else sem_init_cnt <= sem_init_cnt;
	 end if;
       end if;
end process SEM_INIT_STATUS_PROC; 

------------------------------------
--SEM CMD Register DECODE Process.--------
------------------------------------
process (Bus2IP_Clk,Bus2IP_WrCE(0),slv_reg0)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
	icap_grant <= '1';
        slv0_prev <= slv_reg0(0 to 4);
    end if;
end process;
slv0_chng <= or_reduce(slv0_prev xor slv_reg0(0 to 4));


SEM_CMD_DEC_PROC: process(Bus2IP_Clk,Bus2IP_WrCE(0),slv_reg0) 	 
  begin
	--sem_cmd_status <= "0000";
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if slv0_chng = '1' then
      	  WrCE0_rcv <= '1';
      	  case slv_reg0(0 to 4) is
       	 	when "00000" => cmd_exe  <= NOP;
        	when "10000" => cmd_exe  <= IDLE;
        	when "01000" => cmd_exe  <= INJECTION;
        	when "00100" => cmd_exe  <= STATUS;
        	when "00010" => cmd_exe  <= RESET;
        	when "00001" => cmd_exe  <= OBSERVATION;
        	when others  => cmd_exe  <= NOP;
      	  end case; 
      else WrCE0_rcv <= '0';
      end if;
    else WrCE0_rcv <= WrCE0_rcv;
    end if;
end process SEM_CMD_DEC_PROC; 


------------------------------------
--Main State CMD EXE process.--------
------------------------------------
MAIN_STATE_CMD_EXE_PROC: process (Bus2IP_Reset,main_current_state,slv0_chng,count_1,count_hb)
begin
  if(Bus2IP_Reset = '1') then
	main_next_state <= WAITING;  
	my_status_reg   <= (others => '0');
	inject_address <= x"000000000";
    	inject_strobe  <= '0';
	load_cntr1 <= '0';
	ctr1_ld_val <= x"00";
	cntr1_en <= '0';
	cntr1_rst <= '1';
	wait_state <= '0';
	obsexe_state <= '0';
	idleexe_state <= '0';
	injexe_state <= '0';
  else
  case main_current_state is
    when WAITING => 

	wait_state <= '0';
	obsexe_state <= '0';
	idleexe_state <= '0';
	injexe_state <= '0';
 	load_cntr1 <= '0';
	ctr1_ld_val <= x"00";
	cntr1_en <= '0';
	cntr1_rst <= '1';
	my_status_reg(0) <= '1';           -- CORE IS READY
	my_status_reg(1) <= '0';           -- CORE IS NOT BUSY 
	my_status_reg(4) <= saved_status_reg(4);         -- Keep IDLE ACK flag 
	my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag
	inject_address <= x"000000000";
    	inject_strobe  <= '0';
	if slv0_chng = '1' then   
           main_next_state <= CMD_DECODE;  
        else  
           main_next_state <= WAITING;  
        end if;  

    when CMD_DECODE => 
	--my_status_reg <= my_status_reg;
	my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag 
	my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag
	my_status_reg(0) <= '0';           -- CORE IS NOT READY
	my_status_reg(1) <= '1';           -- CORE IS BUSY 
	inject_address <= x"000000000";
    	inject_strobe  <= '0';
	wait_state <= '0';
	obsexe_state <= '0';
	idleexe_state <= '0';
	injexe_state <= '0';
	case cmd_exe is
       	  when NOP =>   load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= NOP_EXE;  
          when IDLE =>  load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= IDLE_EXE;  
          when INJECTION  => load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= INJECTION_EXE;  
          when STATUS =>load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= STATUS_EXE;  			
          when RESET => load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= RESET_EXE;  			
          when OBSERVATION => load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= OBSERVATION_EXE;  			
          when others  => load_cntr1 <= '0';
			ctr1_ld_val <= x"00";
			cntr1_en <= '0';
			cntr1_rst <= '1';
			main_next_state <= NOP_EXE;  
			
      	end case; 
    when NOP_EXE =>
		load_cntr1 <= '0';
		ctr1_ld_val <= x"00";  
		cntr1_en <= '0';
		wait_state <= '0';
		wait_state <= '0';
		obsexe_state <= '0';
		idleexe_state <= '0';
		injexe_state <= '0';
		my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag 
		my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag
		my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag 
		my_status_reg(0) <= '0';           -- CORE IS NOT READY
		my_status_reg(1) <= '1';           -- CORE IS BUSY 
	        --my_status_reg <= my_status_reg;
		inject_address <= x"000000000";
    		inject_strobe  <= '0';
		main_next_state <= SEM_EXE;  
    
    when INJECTION_EXE => 
	    wait_state <= '0';
	    injexe_state <= '1';
	    obsexe_state <= '0';
	    idleexe_state <= '0';	
	    cntr1_rst <= '0';	
	    load_cntr1 <= '0';
	    cntr1_en <= '1';
	    --my_status_reg <= my_status_reg;
	    my_status_reg(5) <= '0';         -- return INJ ACK flag to zero 
	    my_status_reg(1) <= '1';           -- CORE IS BUSY 
	    my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag
	    my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag
	    my_status_reg(0) <= '0';           -- CORE IS NOT READY


	    if ( count_1 = x"00" or count_1 = x"01" ) then
		inject_address   <= inj_addr_36(35 downto 0);
		inject_strobe    <= '0';
		cntr1_en <= '1';
		main_next_state <= INJECTION_EXE;  
    	    elsif ( count_1 >= x"04" and count_1 < x"08") then
		inject_address   <= inj_addr_36(35 downto 0);	
		inject_strobe <= '1';
		cntr1_en <= '1';
		main_next_state <= INJECTION_EXE;  
	    elsif (  count_1 >= x"08" and count_1 < x"0B") then
		inject_address   <= inj_addr_36(35 downto 0);	
		inject_strobe <= '0';
		cntr1_en <= '1';
		main_next_state <= INJECTION_EXE;  
	    elsif ( count_1 >= x"0B") then	
		inject_address <= x"000000000";
		--main_next_state <= IDLE_EXE;  
		inject_strobe <= '0';
		cntr1_en <= '0';
		main_next_state <= INJ_ACK_WAIT; 
	    else 	
		inject_strobe <= inject_strobe;
		inject_address   <= inj_addr_36(35 downto 0);	
		main_next_state <= INJECTION_EXE;  
	 	cntr1_en <= '1';
	    end if;
    when STATUS_EXE =>		
	    cntr1_rst <= '0';
	    load_cntr1 <= '0';
	    cntr1_en <= '1';
	    --my_status_reg <= my_status_reg;
	    wait_state <= '0';
	    injexe_state <= '0';
	    obsexe_state <= '0';
	    idleexe_state <= '0';
	    my_status_reg(1) <= '1';           -- CORE IS BUSY 
	    my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	    my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag  
	    my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag 
	    my_status_reg(0) <= '0';           -- CORE IS NOT READY
	
	    if ( count_1 = x"00" or count_1 = x"01" ) then
		inject_address   <= x"E00000000";
		inject_strobe    <= '0';
		cntr1_en <= '1';
		main_next_state <= STATUS_EXE;  
    	    elsif ( count_1 >= x"04" and count_1 < x"08") then
		inject_address   <= x"E00000000";	
		inject_strobe <= '1';
		cntr1_en <= '1';
		main_next_state <= STATUS_EXE;  
	    elsif (  count_1 >= x"08" and count_1 < x"0B") then
		inject_address   <= x"E00000000";	
		inject_strobe <= '0';
		cntr1_en <= '1';
		main_next_state <= STATUS_EXE;  
	    elsif ( count_1 >= x"0B") then	
		inject_address <= x"000000000";
		inject_strobe <= '0';
		cntr1_en <= '0';
		main_next_state <= SEM_EXE; 
	    else 	

		inject_strobe <= inject_strobe;
		inject_address   <= x"E00000000";
		main_next_state <= STATUS_EXE;  
	 	cntr1_en <= '1';
	    end if;	
    when RESET_EXE =>		
	    cntr1_rst <= '0';
	    load_cntr1 <= '0';
	    cntr1_en <= '1';
	    --my_status_reg <= my_status_reg;
   	    wait_state <= '0';
	    injexe_state <= '0';
	    obsexe_state <= '0';
	    idleexe_state <= '0';
	    my_status_reg(1) <= '1';           -- CORE IS BUSY 
 	    my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	    my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag 
	    my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag
	    my_status_reg(0) <= '0';           -- CORE IS NOT READY


	    if ( count_1 = x"00" or count_1 = x"01" ) then
		inject_address   <= x"B00000000";
		inject_strobe    <= '0';
		main_next_state <= RESET_EXE;  
		cntr1_en <= '1';
    	    elsif ( count_1 >= x"04" and count_1 < x"08") then
		inject_address   <= x"B00000000";	
		inject_strobe <= '1';
		main_next_state <= RESET_EXE;  
		cntr1_en <= '1';
	    elsif (  count_1 >= x"08" and count_1 < x"0B") then
		inject_address   <= x"B00000000";	
		inject_strobe <= '0';
		main_next_state <= RESET_EXE;  
		cntr1_en <= '1';
	    elsif ( count_1 >= x"0B") then	
		inject_address <= x"000000000";
		inject_strobe <= '0';
		cntr1_en <= '0';
		main_next_state <= SEM_EXE; 
	    else 	
		inject_strobe <= inject_strobe;
		inject_address   <= x"B00000000";
		main_next_state <= RESET_EXE;  
	 	cntr1_en <= '1';
	    end if;		
    when OBSERVATION_EXE =>
	    wait_state <= '0';
	    obsexe_state <= '1';
	    injexe_state <= '0';
	    idleexe_state <= '0';

	    cntr1_rst <= '0';	
	    load_cntr1 <= '0';
	    cntr1_en <= '1';
	    --my_status_reg <= my_status_reg;
 	    my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	    my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag  
	    my_status_reg(6) <= '0';         -- return OBS ACK flag to zero 
	    my_status_reg(1) <= '1';           -- CORE IS BUSY 
	    my_status_reg(0) <= '0';           -- CORE IS NOT READY

	    if ( count_1 = x"00" or count_1 = x"01" ) then
		inject_address   <= x"A00000000";
		inject_strobe    <= '0';
		cntr1_en <= '1';
		main_next_state <= OBSERVATION_EXE;  
    	    elsif ( count_1 >= x"04" and count_1 < x"08") then
		inject_address   <= x"A00000000";	
		inject_strobe <= '1';
		cntr1_en <= '1';
		main_next_state <= OBSERVATION_EXE;  
	    elsif (  count_1 >= x"08" and count_1 < x"0B") then
		inject_address   <= x"A00000000";	
		inject_strobe <= '0';
		cntr1_en <= '1';
		main_next_state <= OBSERVATION_EXE;  
	    elsif ( count_1 >= x"0B") then	
		inject_address <= x"000000000";
		inject_strobe <= '0';
		cntr1_en <= '0';
		main_next_state <= OBS_ACK_WAIT; 
	    else 	
		inject_strobe <= inject_strobe;
		inject_address   <= x"A00000000";
		main_next_state <= OBSERVATION_EXE;  
	 	cntr1_en <= '1';
	    end if; 
     when IDLE_EXE => 
	    cntr1_rst <= '0';
	    load_cntr1 <= '0';
	    idleexe_state <= '1';
	    obsexe_state <= '0';
	    injexe_state <= '0';
	    cntr1_en <= '1';
	    --my_status_reg <= my_status_reg;
	    my_status_reg(4) <= '0';         -- return Idle ACK flag to zero 
	    my_status_reg(1) <= '1';           -- CORE IS BUSY 
	    my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	    my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag  
	    my_status_reg(0) <= '0';           -- CORE IS NOT READY
	    wait_state <= '0';
	    if ( count_1 = x"00" or count_1 = x"01" ) then
		inject_address   <= x"E00000000";
		inject_strobe    <= '0';
		cntr1_en <= '1';
		main_next_state <= IDLE_EXE;  
    	    elsif ( count_1 >= x"04" and count_1 < x"08") then
		inject_address   <= x"E00000000";	
		inject_strobe <= '1';
		cntr1_en <= '1';
		main_next_state <= IDLE_EXE;  
	    elsif (  count_1 >= x"08" and count_1 < x"0B") then
		inject_address   <= x"E00000000";	
		inject_strobe <= '0';
		cntr1_en <= '1';
		main_next_state <= IDLE_EXE;  
	    elsif ( count_1 >= x"0B") then	
		inject_address <= x"000000000";
		inject_strobe <= '0';
		cntr1_en <= '0';
		main_next_state <= IDLE_ACK_WAIT; 
	    else 
		inject_strobe <= inject_strobe;
		inject_address   <= x"E00000000";	
		main_next_state <= IDLE_EXE;  
	 	cntr1_en <= '1';
	    end if;
    when OBS_ACK_WAIT =>
		obsexe_state <= '1';
	        idleexe_state <= '0';
	        injexe_state <= '0';
		wait_state <= '1';
		inject_address <= x"000000000";
    		inject_strobe  <= '0';	
	        my_status_reg(1) <= '1';           -- CORE IS BUSY 
	        my_status_reg(0) <= '0';           -- CORE IS NOT READY
 	        my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	        my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag

		--my_status_reg(6) <= my_status_reg(6);
		if(status_observation = '1') then        -- OBSERVATION SUCCESS
			my_status_reg(6) <= '1';         -- OBS ACK flag to one 
	                main_next_state <= SEM_EXE; 
		elsif (status_observation = '0') then
			main_next_state <= OBS_ACK_WAIT; 
			my_status_reg(6) <= '0';         -- OBS ACK flag to zero 
		else 
			main_next_state <= OBS_ACK_WAIT; 
			--main_next_state <= SEM_EXE; 
		end if; 
	 
   when IDLE_ACK_WAIT =>
		idleexe_state <= '1';
		obsexe_state <= '0';
	        injexe_state <= '0';
		wait_state <= '1';
		inject_address <= x"000000000";
    		inject_strobe  <= '0';
	        my_status_reg(1) <= '1';           -- CORE IS BUSY
 	        my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag  
	        my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag  
	        my_status_reg(0) <= '0';           -- CORE IS NOT READY 
		--my_status_reg <= my_status_reg;
			--cntr_hb_en <= '1';	-- only for testbech,,,,,MUST REMOVE FOR RTL,,,,,,,	
		if(status_observation = '1') then	 -- IDLE SUCCESS
	                main_next_state <= IDLE_ACK_WAIT; 
			my_status_reg(4) <= '0';         -- IDLE ACK flag to one 
		--elsif(count_hb = x"0A") then   --- remove for RTL
		--	cntr_hb_rst <= '1';
		--	cntr_hb_en <= '0';
		--	my_status_reg(4) <= '1';         -- IDLE ACK flag to one 
		--	main_next_state <= SEM_EXE;
		--	wait_state <= '0'; 
		elsif (status_observation = '0') then
			my_status_reg(4) <= '1';         -- IDLE ACK flag to one 
			main_next_state <= SEM_EXE;
		else  
			main_next_state <= IDLE_ACK_WAIT;

		end if; 
   when INJ_ACK_WAIT =>	
		injexe_state <= '1';
		wait_state <= '1';
		inject_address <= x"000000000";
    		inject_strobe  <= '0';	
		--my_status_reg <= my_status_reg;
	        my_status_reg(1) <= '1';           -- CORE IS BUSY 
	        my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag   
	        my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag
	        my_status_reg(0) <= '0';           -- CORE IS NOT READY 
		if(status_injection = '1') then          -- INJECTION SUCCESS
			my_status_reg(5) <= '1';         -- INJ ACK flag to one 	
	                main_next_state <= SEM_EXE; 
		elsif (status_injection = '0') then
			main_next_state <= INJ_ACK_WAIT; 
			my_status_reg(5) <= '0';         -- INJ ACK flag to one 	
		else 
			main_next_state <= INJ_ACK_WAIT; 

		end if; 			
    when SEM_EXE =>
	obsexe_state <= '0';
	idleexe_state <= '0';
	injexe_state <= '0';
	cntr1_rst <= '0';
	cntr1_en <= '0';	 	 
	wait_state <= '0';	
	my_status_reg <= saved_status_reg;
	my_status_reg(0) <= '1';           -- CORE IS READY
	my_status_reg(1) <= '0';           -- CORE IS NOT BUSY
        my_status_reg(5) <= saved_status_reg(5);         -- Keep INJ ACK flag 
	my_status_reg(4) <= saved_status_reg(4);          -- Keep IDLE ACK flag 
	my_status_reg(6) <= saved_status_reg(6);         -- Keep OBS ACK flag
	inject_address <= x"000000000";
    	inject_strobe  <= '0';	
	main_next_state <= WAITING;  		
  end case;
  end if;
end process MAIN_STATE_CMD_EXE_PROC;	
------------------------------------
--ASYNCH STATE OUTPUTS SAVINGS process.--------
------------------------------------
ASYNCH_OUT_SAVE_PROC: process (Bus2IP_Clk, Bus2IP_Reset)
begin
    if (Bus2IP_Reset ='1') then  
      saved_status_reg <= (others => '0'); 
    elsif (Bus2IP_Clk'Event and Bus2IP_Clk='1' ) then 
      saved_status_reg <= my_status_reg ;
    else saved_status_reg <= saved_status_reg ;
    end if;  
end process ASYNCH_OUT_SAVE_PROC;
		
------------------------------------
--Main State Transition process.--------
------------------------------------
MAIN_STATE_TRANS_PROC: process (Bus2IP_Clk, Bus2IP_Reset)
begin
if (Bus2IP_Reset ='1') then  
      main_current_state <= WAITING;
      slv_reg1 <= (others => '0'); 
    elsif (Bus2IP_Clk'Event and Bus2IP_Clk='1' ) then 
      main_current_state <= main_next_state;  
      slv_reg1 <= my_status_reg ;
    end if;  
end process MAIN_STATE_TRANS_PROC;

------------------------------------
--Counter process.--------
------------------------------------

COUNTER_1_PROC: process(Bus2IP_Clk,Bus2IP_Reset,load_cntr1,cntr1_rst,cntr1_en) 	 
   begin
       if(Bus2IP_Reset = '1') then
            count_1 <= x"00";
       elsif (Bus2IP_Clk'event and Bus2IP_Clk = '1' ) then          
            if (load_cntr1 = '1') then	
		count_1 <= ctr1_ld_val;
	    elsif (cntr1_en = '1') then
		count_1 <= count_1 + 1;                        --Increment 
	    elsif (cntr1_rst = '1') then
		count_1 <= x"00";    
       	    end if;
	else count_1 <= count_1;
	end if;
end process COUNTER_1_PROC; 

COUNTER_HB_PROC: process(Bus2IP_Clk,Bus2IP_Reset,cntr_hb_rst,cntr_hb_en) 	 
   begin
       	    
       if(Bus2IP_Reset = '1') then
            count_hb <= x"00";
       elsif (Bus2IP_Clk'event and Bus2IP_Clk = '1' ) then          
	    if (cntr_hb_en = '1') then
		count_hb <= count_hb + 1;                        --Increment 
	    elsif (cntr_hb_rst = '1') then
		count_hb <= x"00";    
       	    end if;
	else count_hb <= count_hb;
	end if;
end process COUNTER_HB_PROC; 

end IMP;
