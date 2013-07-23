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

entity hwt_aes is

	port (
		-- OSIF FSL
		--OSFSL_Clk       : in  std_logic;                 -- Synchronous clock
		--OSFSL_Rst       : in  std_logic;
		--OSFSL_S_Clk     : out std_logic;                 -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic;                 -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic;                 -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic;                 -- Data Exist Bit, indicating data exist in the input FSL bus
		--OSFSL_M_Clk     : out std_logic;                 -- Master asynchronous clock
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

end hwt_aes;

architecture implementation of hwt_aes is
  
  component aesCore is
    port(
    --from topfsm:
    clk:                    in std_logic;
    rst:                    in std_logic;
    startTransmitKey:       in std_logic;
    key256In:               in CIPHERKEY256_ARRAY;
    modeIn:                 in std_logic_vector(1 downto 0);
    globalLocalAddrIn:	    in std_logic_vector(5 downto 0);
    keyInjected:	    out std_logic;
    
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
    	loadKey,
	waitInject,
    	encrypt,
	sendAck,
    	threadExit
  );
  signal counter: integer range 0 to 8;
  signal state:   stateType;  

begin
	
  aesCore_inst : aesCore
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
	
	encoder_inst : packetEncoder
	port map(
		clk 				              => clk,					
		reset 				            => rst,
				
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
		--OSFSL_Clk,
		--OSFSL_Rst,
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
      globalLocalAddrIn	<="000100";
      counter           <=0;
    elsif rising_edge(clk)then
      case state is
        
      when waitKey=>
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
            state       <=threadExit;
          elsif data=X"00000001"then
		state	<=getMode;
          end if;
        end if;
   
	when getMode=>
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
            state       <=threadExit;
          else
		mode2Core<=data(1 downto 0);
		globalLocalAddrIn<=data(7 downto 2);
		state<=loadKey;
		counter<=0;
          end if;
        end if;
     
      when loadKey=>
          case counter is
          when 8=>
            state           <=waitInject;
            startTransmitKey<='1';
          when others=>
            osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
            if done then
              key2Core(counter)<=data;
              counter          <=counter+1;
            end if;
          end case;

	when waitInject=>
		startTransmitKey<='0';
		if keyInjected='1'then
			state<=sendAck;
		end if;

	when sendAck=>
	osif_mbox_put(i_osif,o_osif, MBOX_SEND, X"00000002", ignore, done);
	if done then state<=encrypt; end if;
               
      when encrypt=>
        osif_mbox_get(i_osif, o_osif, MBOX_RECV, data, done);
        if done then
          if (data=X"FFFFFFFF")then
            state       <=threadExit;
          elsif data=X"00000001"then
		state<=getMode;
		counter<=0;
          end if;
        end if;
        
      when others=>
        osif_thread_exit(i_osif, o_osif);
      end case;
      
    end if;
  end process;

end architecture;
