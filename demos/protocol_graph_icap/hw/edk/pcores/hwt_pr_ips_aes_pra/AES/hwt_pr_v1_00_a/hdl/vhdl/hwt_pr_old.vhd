library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_b;
use reconos_v3_00_b.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

library yyang_v1_00_a;
use yyang_v1_00_a.yyangPkg.all;

entity hwt_pr is

	port (
		-- OSIF FSL
	--	OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
	--	OSFSL_Rst       : in  std_logic;
	--	OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
	--	OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic;                 -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic;                 -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic;                 -- Full Bit, indicating output FSL bus is full
		
		-- FIFO Interface
		FIFO32_S_Data   : in std_logic_vector(31 downto 0);
		FIFO32_M_Data   : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill   : in std_logic_vector(15 downto 0);
		FIFO32_M_Rem    : in std_logic_vector(15 downto 0);
		FIFO32_S_Rd     : out std_logic;
		FIFO32_M_Wr     : out std_logic;
		
		-- HWT reset
		rst             : in std_logic;
		clk		: in std_logic;

		switch_data_rdy	: in  std_logic;
		switch_data		   : in  std_logic_vector(dataWidth downto 0);
		thread_read_rdy	: out std_logic;
		switch_read_rdy	: in  std_logic;
		thread_data		   : out std_logic_vector(dataWidth downto 0);
		thread_data_rdy : out std_logic	

	);

end hwt_pr;

architecture implementation of hwt_pr is
  
  component aesCoreDe is
    port(
    --from topfsm:
    clk:                    in std_logic;
    rst:                    in std_logic;
    startTransmitKey:       in std_logic;
    key256In:               in CIPHERKEY256_ARRAY;
    modeIn:                 in std_logic_vector(1 downto 0);
globalLocalAddrIn:		in std_logic_vector(5 downto 0);
keyInjected:		out std_logic;
    
    --from pktDecoder:    
    noc_rx_sof:             in std_logic;
    noc_rx_eof:             in std_logic;
    noc_rx_data:            in std_logic_vector(7 downto 0);
    noc_rx_src_rdy:         in std_logic;
    noc_rx_direction:       in std_logic;
    noc_rx_priority:        in std_logic_vector(1 downto 0);
    noc_rx_latencyCritical: in std_logic;
    noc_rx_srcIdp:          in std_logic_vector(31 downto 0);
    noc_rx_dstIdp:          in std_logic_vector(31 downto 0);    
    noc_rx_dst_rdy:         out std_logic;
    
    --towards pktEncoder:
    noc_tx_sof:             out std_logic;                        -- Indicates the start of a new packet
		noc_tx_eof:             out std_logic;                        -- Indicates the end of the packet
		noc_tx_data:            out std_logic_vector(7 downto 0);     -- The current data byte
		noc_tx_src_rdy:         out std_logic;                        -- '1' if the data are valid, '0' else
		noc_tx_globalAddress:   out std_logic_vector(3 downto 0);     -- The global hardware address of the destination
		noc_tx_localAddress:    out std_logic_vector(1 downto 0);     -- The local hardware address of the destination
		noc_tx_direction:       out std_logic;                        -- '1' for egress, '0' for ingress
		noc_tx_priority:        out std_logic_vector(1 downto 0);     -- The priority of the packet
		noc_tx_latencyCritical: out std_logic;                        -- '1' if this packet is latency critical
		noc_tx_srcIdp:          out std_logic_vector(31 downto 0);    -- The source IDP
		noc_tx_dstIdp:          out std_logic_vector(31 downto 0);    -- The destination IDP
		noc_tx_dst_rdy:         in std_logic                          -- Read enable for the applied data
    );
  end component;
  
	constant MBOX_RECV         : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000000";
	constant MBOX_SEND         : std_logic_vector(C_FSL_WIDTH-1 downto 0) := x"00000001";
signal ignore:	std_logic_vector(C_FSL_WIDTH-1 downto 0);
	signal data                : std_logic_vector(31 downto 0);
	signal i_osif              : i_osif_t;
	signal o_osif              : o_osif_t;
	signal i_memif             : i_memif_t;
	signal o_memif             : o_memif_t;
	signal i_ram               : i_ram_t;
	signal o_ram               : o_ram_t;

  signal startTransmitKey         :std_logic;
  signal key2Core                 :CIPHERKEY256_ARRAY;
  signal mode2Core                :std_logic_vector(1 downto 0);  
signal globalLocalAddrIn	:std_logic_vector(5 downto 0);               
signal keyInjected		:std_logic;
	signal pktDecoder_sof	          : std_logic;
	signal pktDecoder_eof	          : std_logic;
	signal pktDecoder_data	         : std_logic_vector(7 downto 0);
	signal pktDecoder_src_rdy	      : std_logic;
	signal pktDecoder_dst_rdy	      : std_logic;
	signal pktDecoder_direction           : std_logic;
	signal pktDecoder_priority            : std_logic_vector(1 downto 0);
	signal pktDecoder_latency_critical    : std_logic;
	signal pktDecoder_srcIdp              : std_logic_vector(31 downto 0);
	signal pktDecoder_dstIdp              : std_logic_vector(31 downto 0);
	signal pktDecoder_global_addr         : std_logic_vector(3 downto 0);
	signal pktDecoder_local_addr          : std_logic_vector(1 downto 0);
	
	signal pktEncoder_sof	          : std_logic;
	signal pktEncoder_eof	          : std_logic;
	signal pktEncoder_data	         : std_logic_vector(7 downto 0);
	signal pktEncoder_src_rdy	      : std_logic;
  signal pktEncoder_global_addr         : std_logic_vector(3 downto 0);
	signal pktEncoder_local_addr          : std_logic_vector(1 downto 0);
	signal pktEncoder_direction           : std_logic;
	signal pktEncoder_priority            : std_logic_vector(1 downto 0);
	signal pktEncoder_latency_critical    : std_logic;
	signal pktEncoder_srcIdp              : std_logic_vector(31 downto 0);
	signal pktEncoder_dstIdp              : std_logic_vector(31 downto 0);
	signal pktEncoder_dst_rdy	      : std_logic;	


  type stateType is(
    waitKey,
getMode,
    loadKey0,
    loadKey1,
    loadKey2,
    loadKey3,
    loadKey4,
    loadKey5,
    loadKey6,
    loadKey7,
    loadKey8,
waitInject,
    encrypt,
sendAck,
    threadExit
  );
  signal counter: integer range 0 to 8;
  signal state:   stateType;  
  signal rst_new : std_logic;
  signal configuring : std_logic;

	component icon
	port (
		control0 : inout std_logic_vector(35 downto 0)
	);
	end component;

	component ila
	port (
		control : inout std_logic_vector(35 downto 0);
		clk   : in std_logic;
		trig0 : in std_logic_vector( 3 downto 0);
		trig1 : in std_logic_vector( 7 downto 0);
		trig2 : in std_logic_vector( 3 downto 0);
		trig3 : in std_logic_vector( 7 downto 0);
		trig4 : in std_logic_vector( 7 downto 0);
		trig5 : in std_logic_vector( 7 downto 0);
		trig6 : in std_logic_vector( 3 downto 0);
		trig7 : in std_logic_vector(31 downto 0);
		trig8 : in std_logic_vector(15 downto 0);
		trig9 : in std_logic_vector(15 downto 0);
		trig10: in std_logic_vector(15 downto 0)
	);
	end component;
	
	signal trig0 : std_logic_vector( 3 downto 0);
	signal trig1 : std_logic_vector( 7 downto 0);
	signal trig2 : std_logic_vector( 3 downto 0);
	signal trig3 : std_logic_vector( 7 downto 0);
	signal trig4 : std_logic_vector( 7 downto 0);
	signal trig5 : std_logic_vector( 7 downto 0);
	signal trig6 : std_logic_vector( 3 downto 0);
	signal trig7 : std_logic_vector(31 downto 0);
	signal trig8 : std_logic_vector(15 downto 0);
	signal trig9 : std_logic_vector(15 downto 0);
	signal trig10: std_logic_vector(15 downto 0);
	signal control : std_logic_vector(35 downto 0);

	signal reconos_step : std_logic_vector( 3 downto 0);
	signal pktDecoder_dst_rdy_reconos : std_logic;
	signal pktDecoder_dst_rdy_combined : std_logic;

begin

	icon_i : icon
	port map (
		control0 => control
	);
	
	ila_i : ila
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
		trig8 => trig8,
		trig9 => trig9,
		trig10 => trig10
	);

	trig0(3) <= pktDecoder_sof;
	trig0(2) <= pktDecoder_eof;
	trig0(1) <= pktDecoder_src_rdy;
	trig0(0) <= pktDecoder_dst_rdy;
	
	trig1 <= pktDecoder_data;
	
	trig2(3) <= pktEncoder_sof;
	trig2(2) <= pktEncoder_eof;
	trig2(1) <= pktEncoder_src_rdy;
	trig2(0) <= pktEncoder_dst_rdy;

	trig3 <= pktEncoder_data;
	trig4 <= rst & startTransmitKey & keyInjected & mode2Core & "000";  --  8 bits
	trig5 <= globalLocalAddrIn & "00";  --  8 bits
	trig6 <= reconos_step;  --  4 bits
	trig7 <= key2Core(0);  -- 32 bits
	trig8 <= (others=>'0');  -- 16 bits
	trig9 <= (others=>'0');  -- 16 bits
	trig10 <= (others=>'0'); -- 16 bits
	
  aesCore_inst : aesCoreDe
  port map(
    --from topfsm:
		clk 	                 => clk,
		rst 	                 => rst,
    startTransmitKey      => startTransmitKey,
    key256In              => key2Core,
    modeIn                => mode2Core,
globalLocalAddrIn	=>globalLocalAddrIn,
keyInjected		=>keyInjected,
   
    --from pktDecoder:    
		noc_rx_sof		          => pktDecoder_sof,		         -- Indicates the start of a new packet
		noc_rx_eof		          => pktDecoder_eof,		         -- Indicates the end of the packet
		noc_rx_data		         => pktDecoder_data,		        -- The current data byte
		noc_rx_src_rdy		      => pktDecoder_src_rdy, 	     -- '1' if the data are valid, '0' else
		noc_rx_direction	     => pktDecoder_direction, 		        -- '1' for egress, '0' for ingress
		noc_rx_priority		     => pktDecoder_priority,		          -- The priority of the packet
		noc_rx_latencyCritical=> pktDecoder_latency_critical,		  -- '1' if this packet is latency critical
		noc_rx_srcIdp		       => pktDecoder_srcIdp,		            -- The source IDP
		noc_rx_dstIdp		       => pktDecoder_dstIdp,		            -- The destination IDP
		noc_rx_dst_rdy		      => pktDecoder_dst_rdy,	       -- Read enable for the functional block
    
    --towards pktEncoder:
		noc_tx_sof  			       => pktEncoder_sof, 		
		noc_tx_eof  			       => pktEncoder_eof,
		noc_tx_data	 		       => pktEncoder_data,		
		noc_tx_src_rdy 	 		   => pktEncoder_src_rdy,		
		noc_tx_globalAddress  => pktEncoder_global_addr,         --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress  	=> pktEncoder_local_addr,          --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	  => pktEncoder_direction,		
		noc_tx_priority 	 	   => pktEncoder_priority,		
		noc_tx_latencyCritical=> pktEncoder_latency_critical,	
		noc_tx_srcIdp 			     => pktEncoder_srcIdp,	
		noc_tx_dstIdp 			     => pktEncoder_dstIdp,
		noc_tx_dst_rdy	 		    => pktEncoder_dst_rdy
  );
  
	pktDecoder_dst_rdy_combined <= pktDecoder_dst_rdy & pktDecoder_dst_rdy_reconos;
  
	decoder_inst : packetDecoder
	port map (
		clk 	                 => clk,
		reset 	               => rst,

		-- Signals from the switch
		switch_data_rdy		     => switch_data_rdy,
		switch_data		         => switch_data,
		thread_read_rdy		     => thread_read_rdy,

		-- Decoded values of the packet
		noc_rx_sof		          => pktDecoder_sof,		         -- Indicates the start of a new packet
		noc_rx_eof		          => pktDecoder_eof,		         -- Indicates the end of the packet
		noc_rx_data		         => pktDecoder_data,		        -- The current data byte
		noc_rx_src_rdy		      => pktDecoder_src_rdy, 	     -- '1' if the data are valid, '0' else
		noc_rx_direction	     => pktDecoder_direction, 		        -- '1' for egress, '0' for ingress
		noc_rx_priority		     => pktDecoder_priority,		          -- The priority of the packet
		noc_rx_latencyCritical=> pktDecoder_latency_critical,		  -- '1' if this packet is latency critical
		noc_rx_srcIdp		       => pktDecoder_srcIdp,		            -- The source IDP
		noc_rx_dstIdp		       => pktDecoder_dstIdp,		            -- The destination IDP
		noc_rx_dst_rdy		      => pktDecoder_dst_rdy	       -- Read enable for the functional block
	);
	
	pktDecoder_dst_rdy_combined 
	
	encoder_inst : packetEncoder
	port map(
		clk 				              => clk,					
		reset 				            => rst, --rst_new,
				
		-- Signals to the switch
		switch_read_rdy  		   => switch_read_rdy, 		
		thread_data  			      => thread_data,		
		thread_data_rdy 		    => thread_data_rdy,
		
		-- Encoded values of the packet
		noc_tx_sof  			       => pktEncoder_sof, 		
		noc_tx_eof  			       => pktEncoder_eof,
		noc_tx_data	 		       => pktEncoder_data,		
		noc_tx_src_rdy 	 		   => pktEncoder_src_rdy,		
		noc_tx_globalAddress  => pktEncoder_global_addr,         --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
		noc_tx_localAddress  	=> pktEncoder_local_addr,          --"01",-- (others  => '0'), --2 bits		
		noc_tx_direction 	 	  => pktEncoder_direction,		
		noc_tx_priority 	 	   => pktEncoder_priority,		
		noc_tx_latencyCritical=> pktEncoder_latency_critical,	
		noc_tx_srcIdp 			     => pktEncoder_srcIdp,	
		noc_tx_dstIdp 			     => pktEncoder_dstIdp,
		noc_tx_dst_rdy	 		    => pktEncoder_dst_rdy
	);

	fsl_setup(
		i_osif,
		o_osif,
	--	OSFSL_Clk,
	--	OSFSL_Rst,
		OSFSL_S_Data,
		OSFSL_S_Exists,
		OSFSL_M_Full,
		OSFSL_M_Data,
		OSFSL_S_Read,
		OSFSL_M_Write,
		OSFSL_M_Control
	);
		
	memif_setup(
		i_memif,
		o_memif,
	--	OSFSL_Clk,
	--	FIFO32_S_Clk,
		FIFO32_S_Data,
		FIFO32_S_Fill,
		FIFO32_S_Rd,
	--	FIFO32_M_Clk,
		FIFO32_M_Data,
		FIFO32_M_Rem,
		FIFO32_M_Wr
	);
	
	--rst_new <= rst or configuring;
	
  reconos_fsm: process(clk, rst, o_osif, o_memif, o_ram)is
  variable done:    boolean;
  begin
    if rst='1'then
      osif_reset(o_osif);
      memif_reset(o_memif);
      state             <=waitKey;
      startTransmitKey  <='0';
      key2Core          <=(others=>X"FFFFFFFF");
      mode2Core         <=mode256;
      globalLocalAddrIn	<="000100"; --to eth
      counter           <=0;
      configuring       <='1'; 
		pktDecoder_dst_rdy_reconos <= '0';
      reconos_step <= "0000";
    elsif rising_edge(clk)then
      case state is
      pktDecoder_dst_rdy_reconos <= '0'; 
      when waitKey=>
        reconos_step <= "0001";
        configuring       <='1'; 
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
            state       <=threadExit;
          elsif data=X"00000001"then
		state	<=getMode;
          end if;
        end if;
   
	when getMode=>
        reconos_step <= "0010";
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
            state       <=threadExit;
          else
                mode2Core<=data(1 downto 0);
                globalLocalAddrIn<=data(7 downto 2);
                state<=loadKey0;
                counter<=0;
          end if;
        end if;
     
      when loadKey0=>
        reconos_step <= "0011";
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(0)<=data;
	      state<=loadKey1;
	end if;
      when loadKey1=>
        reconos_step <= "0100";
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(1)<=data;
	      state<=loadKey2;
	end if;
  when loadKey2=>
        reconos_step <= "0101";
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(2)<=data;
	      state<=loadKey3;
	end if;
  when loadKey3=>
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(3)<=data;
	      state<=loadKey4;
	end if;
  when loadKey4=>
        reconos_step <= "0110";
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(4)<=data;
	      state<=loadKey5;
	end if;
  when loadKey5=>
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(5)<=data;
	      state<=loadKey6;
	end if;
  when loadKey6=>
        reconos_step <= "0111";
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
              key2Core(6)<=data;
	      state<=loadKey7;
	end if;
  	when loadKey7=>
        reconos_step <= "1000";
	configuring       <='0';
 	osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
				  configuring       <='0';
              key2Core(7)<=data;
              state           <=loadKey8;

	end if;
 	when loadKey8=>
        reconos_step <= "1001";
				  configuring       <='0';
              state           <=waitInject;
              startTransmitKey<='1';

--          case counter is
  --        when 8=>
    --        state           <=waitInject;
      --      startTransmitKey<='1';
      --    when others=>
      --      osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
       --     if done then
       --       key2Core(counter)<=data;
       --       counter          <=counter+1;
       --     end if;
       --   end case;

	when waitInject=>
      reconos_step <= "1010";
		configuring <='0';
		startTransmitKey<='0';
		if keyInjected='1'then
			state<=sendAck;
		end if;

	when sendAck=>
       reconos_step <= "1011";
       configuring <='0';
	    osif_mbox_put(i_osif,o_osif, MBOX_SEND, X"00000002", ignore, done);
	    if done then state<=encrypt; end if;
               
      when encrypt=>
        reconos_step <= "1100";
		  configuring <='0';
		  pktDecoder_dst_rdy_reconos <= '1';
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
				pktDecoder_dst_rdy_reconos <= '0';
            state <=threadExit;
          elsif data=X"00000001"then
				pktDecoder_dst_rdy_reconos <= '0';
            state<=getMode;
            counter<=0;
          end if;
        end if;
        
      when others=>
        reconos_step <= "1111";
		  configuring <='1';
        osif_thread_exit(i_osif, o_osif);
      end case;
      
    end if;
  end process;

end architecture;
