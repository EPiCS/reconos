library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library yyang_v1_00_a;
use yyang_v1_00_a.yyangPkg.all;

entity aesCore is
  port(
    --from topfsm:
    clk:                    in std_logic;
    rst:                    in std_logic;
    startTransmitKey:       in std_logic;
    key256In:               in CIPHERKEY256_ARRAY;
    modeIn:                 in std_logic_vector(1 downto 0);
    globalLocalAddrIn:      in std_logic_vector(5 downto 0);
    keyInjected:            out std_logic;
        
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
end aesCore;



architecture rtl of aesCore is
  
signal keyC2K:          CIPHERKEY256_ARRAY;
signal roundKeys:       KEY256_ARRAY;
signal readStageIdle:   std_logic;
signal sendStageIdle:   std_logic;
signal keyInject:       std_logic;
signal en:              std_logic;
signal mode:            std_logic_vector(1 downto 0);
signal startExp:        std_logic;
signal permitEnc:       std_logic;

signal rdy_R2A:         std_logic;
signal rdy_A2R:         std_logic;
signal data_R2A:        DATA_ARRAY;
signal info_R2A:        std_logic_vector(85 downto 0);
signal stageA:          std_logic_vector(1 downto 0);

signal rdy_A2B:         std_logic;
signal rdy_B2A:         std_logic;
signal data_A2B:        DATA_ARRAY;
signal info_A2B:        std_logic_vector(85 downto 0);
signal stageB:          std_logic_vector(1 downto 0);

signal rdy_B2C:         std_logic;
signal rdy_C2B:         std_logic;
signal data_B2C:        DATA_ARRAY;
signal info_B2C:        std_logic_vector(85 downto 0);  
signal stageC:          std_logic_vector(1 downto 0);

signal rdy_C2D:         std_logic;
signal rdy_D2C:         std_logic;
signal data_C2D:        DATA_ARRAY;
signal info_C2D:        std_logic_vector(85 downto 0);  
signal stageD:          std_logic_vector(1 downto 0);

signal rdy_D2S:         std_logic;
signal rdy_S2D:         std_logic;
signal info_D2S:        std_logic_vector(85 downto 0);
signal data_D2S:        DATA_ARRAY;

signal startExpansion:  std_logic;
signal keyWord:         std_logic_vector(31 downto 0);
signal addrA:           std_logic_vector(3 downto 0);
signal addrB:           std_logic_vector(3 downto 0);
signal addrC:           std_logic_vector(3 downto 0);
signal addrD:           std_logic_vector(3 downto 0);
signal keyA:            DATA_ARRAY;
signal keyB:            DATA_ARRAY;
signal keyC:            DATA_ARRAY;
signal keyD:            DATA_ARRAY;
signal keyValid:        std_logic;
signal globalLocalAddr: std_logic_vector(5 downto 0);

component control is
  port(
    clk:                  in std_logic;
    rst:                  in std_logic;
    
    --to topfsm:
    startTransmitKey:     in std_logic;
    key256In:             in CIPHERKEY256_ARRAY;
    modeIn:               in std_logic_vector(1 downto 0);
    globalLocalAddrIn:    in std_logic_vector(5 downto 0);
    
    --to keyExpansion:
    keyValid:             in std_logic;
    startExp:             out std_logic;
    keyOut:               out CIPHERKEY256_ARRAY;
    mode:                 out std_logic_vector(1 downto 0);
    
    --to keyBak & SENDSTAGE:
    keyInject:            out std_logic;
    
    --to readStage:
    permitEnc:            out std_logic;
    readStageIdle:        in std_logic;
    
    --to encryptionStage:
    stageAIdle:           in std_logic;
    stageBIdle:           in std_logic;
    stageCIdle:           in std_logic;
    
    --to sendStage:
    sendStageIdle:        in std_logic;
    globalLocalAddr:      out std_logic_vector(5 downto 0)
  );
end component;

component keyExpansion
  port(
    clk                     :in std_logic;
    rst                     :in std_logic;
    en                      :in std_logic;
    mode                    :in std_logic_vector(1 downto 0);
    startExpansion          :in std_logic;
    key256In                :in CIPHERKEY256_ARRAY;
    roundKeys               :out KEY256_ARRAY;
    keyValid                :out std_logic
  );
end component;

component keyBak is
  port(
    rst                     :in std_logic;
    clk                     :in std_logic;
    keyIn                   :in KEY256_ARRAY;
    keyInject               :in std_logic;
    
    addrA                   :in std_logic_vector(3 downto 0);
    addrB                   :in std_logic_vector(3 downto 0);
    addrC                   :in std_logic_vector(3 downto 0);
    addrD                   :in std_logic_vector(3 downto 0);
    keyA                    :out DATA_ARRAY;
    keyB                    :out DATA_ARRAY;
    keyC                    :out DATA_ARRAY;
    keyD                    :out DATA_ARRAY
  );
end component;

component readStage is
  port(
    clk:                    in std_logic;
    rst:                    in std_logic;
    
    --to control:
    start:                  in std_logic;
    readStageIdle:          out std_logic;
   
    --towards pktDecoder: 1+1+8+2+2+1+64+1=80, 8=data, 1=me rdy, 1=pktdecode rdy.
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

    --to stageA:
    dwstream_rdy:           in std_logic; 
    send_rdy:               out std_logic;    
    matrixOut:              out DATA_ARRAY;
    Info:                   out std_logic_vector(85 downto 0)
  );
end component;

component sendStage is
  port(   
    clk:                    in std_logic;
    rst:                    in std_logic;
    
    --to control:
    keyInject:              in std_logic;
    globalLocalAddr:        in std_logic_vector(5 downto 0);
    sendStageIdle:          out std_logic;
    
    --to keyBak (for test only):
    --addrE:                  out std_logic_vector(3 downto 0);
    
    --from stageC:
    matrixIn:               in DATA_ARRAY;    --connect to keyD for test!
    infoIn:                 in std_logic_vector(85 downto 0);
    upstream_rdy:           in std_logic;
    read_rdy:               out std_logic;
    
    --towards packetEncoder:    1+1+8+1+4+2+1+2+1+64+1=86, 85 out, 1= switch rdy, 1= me rdy, 8=data, 76 other. 85!=infoIn!!
    noc_tx_sof:             out std_logic; -- Indicates the start of a new packet
		noc_tx_eof:             out std_logic; -- Indicates the end of the packet
		noc_tx_data:            out std_logic_vector(7 downto 0); -- The current data byte
		noc_tx_src_rdy:         out std_logic; -- '1' if the data are valid, '0' else
		noc_tx_globalAddress:   out std_logic_vector(3 downto 0); -- The global hardware address of the destination
		noc_tx_localAddress:    out std_logic_vector(1 downto 0); -- The local hardware address of the destination
		noc_tx_direction:       out std_logic; -- '1' for egress, '0' for ingress
		noc_tx_priority:        out std_logic_vector(1 downto 0); -- The priority of the packet
		noc_tx_latencyCritical: out std_logic; -- '1' if this packet is latency critical
		noc_tx_srcIdp:          out std_logic_vector(31 downto 0); -- The source IDP
		noc_tx_dstIdp:          out std_logic_vector(31 downto 0); -- The destination IDP
		noc_tx_dst_rdy:         in std_logic -- Read enable for the applied data
  );
end component;

component encryptBlock is
  port(
    clk                   :in std_logic;
    rst                   :in std_logic;
    en                    :in std_logic;
    upstream_rdy          :in std_logic;
    dwstream_rdy          :in std_logic;
    stage                 :in std_logic_vector(1 downto 0);
    mode                  :in std_logic_vector(1 downto 0);
    dataIn                :in DATA_ARRAY;
    keyIn                 :in DATA_ARRAY;
    --sof+eof+pktLen+otherInfo=1+1+16+68
    InfoIn                :in std_logic_vector(85 downto 0);
    InfoOut               :out std_logic_vector(85 downto 0);
    read_rdy              :out std_logic;
    send_rdy              :out std_logic;
    dataOut               :out DATA_ARRAY;
    addrOut               :out std_logic_vector(3 downto 0)
  );
end component;


begin
  
  en<='1';
  keyInjected<=keyInject;
  
  cnt:    control port map(
    clk                   =>clk,
    rst                   =>rst,
    startTransmitKey      =>startTransmitKey,
    key256In              =>key256In,
    modeIn                =>modeIn,  
    keyValid              =>keyValid,
    startExp              =>startExp,
    permitEnc             =>permitEnc,
    keyOut                =>keyC2K,
    globalLocalAddrIn     =>globalLocalAddrIn,
    globalLocalAddr       =>globalLocalAddr,
    mode                  =>mode,

    
    --to keyBak:
    keyInject             =>keyInject,
    
    --to readStage:
    readStageIdle         =>readStageIdle,
    
    --to encryptionStage:
    stageAIdle            =>rdy_A2R,
    stageBIdle            =>rdy_B2A,
    stageCIdle            =>rdy_C2B,
    
    --to sendStage:
    sendStageIdle         =>sendStageIdle
  );
  
  ke:     keyExpansion port map(
    clk                   =>clk,
    rst                   =>rst,
    en                    =>en,
    mode                  =>mode,
    startExpansion        =>startExp,
    key256In              =>keyC2K,
    roundKeys             =>roundKeys,
    keyValid              =>keyValid
  );
  
  kb:     keyBak port map(
    rst                   =>rst,
    clk                   =>clk,
    keyIn                 =>roundKeys,
    keyInject             =>keyInject,
    
    addrA                 =>addrA,
    addrB                 =>addrB,
    addrC                 =>addrC,
    addrD                 =>addrD,
    keyA                  =>keyA,
    keyB                  =>keyB,
    keyC                  =>keyC,
    keyD                  =>keyD
  );
  
  rd:     readStage port map(
    clk                   =>clk,
    rst                   =>rst,

    start                 =>permitEnc,
    readStageIdle         =>readStageIdle,
    
    noc_rx_sof            =>noc_rx_sof,
    noc_rx_eof            =>noc_rx_eof,
    noc_rx_data           =>noc_rx_data,
    noc_rx_src_rdy        =>noc_rx_src_rdy,
    noc_rx_direction      =>noc_rx_direction,
    noc_rx_priority       =>noc_rx_priority,
    noc_rx_latencyCritical=>noc_rx_latencyCritical,
    noc_rx_srcIdp         =>noc_rx_srcIdp,
    noc_rx_dstIdp         =>noc_rx_dstIdp,    
    noc_rx_dst_rdy        =>noc_rx_dst_rdy,

    dwstream_rdy          =>rdy_A2R, 
    send_rdy              =>rdy_R2A,   
    matrixOut             =>data_R2A,
    Info                  =>info_R2A
  );
  
  ea: encryptBlock port map(
    clk             =>clk,
    rst             =>rst,
    en              =>en,
    upstream_rdy    =>rdy_R2A, 
    dwstream_rdy    =>rdy_B2A,      
    stage           =>"00",      
    mode            =>mode,     
    dataIn          =>data_R2A,     
    keyIn           =>keyA,
    InfoIn          =>info_R2A,
    InfoOut         =>info_A2B,     
    read_rdy        =>rdy_A2R,
    send_rdy        =>rdy_A2B,      
    dataOut         =>data_A2B,      
    addrOut         =>addrA      
  );
  
  eb: encryptBlock port map(
    clk             =>clk,
    rst             =>rst,
    en              =>en,
    upstream_rdy    =>rdy_A2B, 
    dwstream_rdy    =>rdy_C2B,      
    stage           =>"01",      
    mode            =>mode,     
    dataIn          =>data_A2B,     
    keyIn           =>keyB,
    InfoIn          =>info_A2B,
    InfoOut         =>info_B2C,     
    read_rdy        =>rdy_B2A,
    send_rdy        =>rdy_B2C,      
    dataOut         =>data_B2C,      
    addrOut         =>addrB      
  );
  
  ec: encryptBlock port map(
    clk             =>clk,
    rst             =>rst,
    en              =>en,
    upstream_rdy    =>rdy_B2C, 
    dwstream_rdy    =>rdy_D2C,      
    stage           =>"10",      
    mode            =>mode,     
    dataIn          =>data_B2C,     
    keyIn           =>keyC,
    InfoIn          =>info_B2C,
    InfoOut         =>info_C2D,     
    read_rdy        =>rdy_C2B,
    send_rdy        =>rdy_C2D,      
    dataOut         =>data_C2D,      
    addrOut         =>addrC      
  );
  
  ed: encryptBlock port map(
    clk             =>clk,
    rst             =>rst,
    en              =>en,
    upstream_rdy    =>rdy_C2D, 
    dwstream_rdy    =>rdy_S2D,      
    stage           =>"11",      
    mode            =>mode,     
    dataIn          =>data_C2D,     
    keyIn           =>keyD,
    InfoIn          =>info_C2D,
    InfoOut         =>info_D2S,     
    read_rdy        =>rdy_D2C,
    send_rdy        =>rdy_D2S,      
    dataOut         =>data_D2S,      
    addrOut         =>addrD      
  );
  sd: sendStage port map(
       
    clk             =>clk,
    rst             =>rst,
    
    --from control:
    globalLocalAddr =>globalLocalAddr,
    sendStageIdle   =>sendStageIdle,
    keyInject       =>keyInject,
    
    --towards stageC:
    matrixIn        =>data_D2S,
    infoIn          =>info_D2S,
    upstream_rdy    =>rdy_D2S,
    read_rdy        =>rdy_S2D,
    
    --towards packetEncoder:    
    noc_tx_sof              =>noc_tx_sof,
		noc_tx_eof              =>noc_tx_eof,
		noc_tx_data             =>noc_tx_data,
		noc_tx_src_rdy          =>noc_tx_src_rdy,
		noc_tx_globalAddress    =>noc_tx_globalAddress,
		noc_tx_localAddress     =>noc_tx_localAddress,
		noc_tx_direction        =>noc_tx_direction,
		noc_tx_priority         =>noc_tx_priority,
		noc_tx_latencyCritical  =>noc_tx_latencyCritical,
		noc_tx_srcIdp           =>noc_tx_srcIdp,
		noc_tx_dstIdp           =>noc_tx_dstIdp,
		noc_tx_dst_rdy          =>noc_tx_dst_rdy
  );
  
end rtl;
