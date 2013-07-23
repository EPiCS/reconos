library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library ana_va_00_a;
--use ana_v1_00_a.anaPkg.all;
use work.hwt_aes_yyang_pkg.all;

entity sendStageDe is
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
end sendStageDe;

architecture rtl of sendStageDe is
    
    signal matrix_p:        DATA_ARRAY;
    signal matrix_n:        DATA_ARRAY;
    signal sofIn:           std_logic;
    signal eofIn:           std_logic;
    type stateType is(
      waitMatrix,
      sendFinalByte,
      sendLastBlock,
      sendData0
    );
    signal dwstream_rdy:    std_logic;
    signal state_p:         stateType;
    signal state_n:         stateType;
    signal counter_p:       integer range 0 to 16;
    signal counter_n:       integer range 0 to 16;
    signal data_p:          std_logic_vector(7 downto 0);
    signal data_n:          std_logic_vector(7 downto 0);
    signal info_p:          std_logic_vector(85 downto 0);
    signal info_n:          std_logic_vector(85 downto 0);
    
    signal sd_rdy_p:          std_logic;
    signal rd_rdy_p:          std_logic;
    signal sd_rdy_n:          std_logic;
    signal rd_rdy_n:          std_logic;
    
    signal eof_p:             std_logic;
    signal eof_n:             std_logic;

begin

    read_rdy                <=rd_rdy_p;
    --addrE                  <="0000";
    --from stageC:
    sofIn                  <=infoIn(85);
    eofIn                  <=infoIn(84);
    
    --towards packetEncoder:
    noc_tx_sof             <=info_p(85);
		noc_tx_eof             <=eof_p;
		noc_tx_data            <=data_p;
		noc_tx_src_rdy         <=sd_rdy_p;
--		noc_tx_globalAddress   <=globalLocalAddr(5 downto 2);
--		noc_tx_localAddress    <=globalLocalAddr(1 downto 0);
		noc_tx_direction       <=info_p(67);
		noc_tx_priority        <=info_p(66 downto 65);
		noc_tx_latencyCritical <=info_p(64);
		noc_tx_srcIdp          <=info_p(63 downto 32);
		noc_tx_dstIdp          <=info_p(31 downto 0);

		 
    dwstream_rdy           <=noc_tx_dst_rdy;

process(clk,rst)
  begin
    if rst='1'then
		  noc_tx_globalAddress   <="0001";
		  noc_tx_localAddress    <="00";
		elsif rising_edge(clk)then
		  if keyInject='1'then
			  noc_tx_globalAddress   <=globalLocalAddr(5 downto 2);
		    noc_tx_localAddress    <=globalLocalAddr(1 downto 0);
		  end if;
		 end if;
end process;      
       
  process(clk,rst)
    begin
    if rst='1' then
      sendStageIdle<='1';
    elsif rising_edge(clk)then
      case state_p is
      when waitMatrix=>
        sendStageIdle<='1';
      when others=>
        sendStageIdle<='0';
      end case;
    end if;
  end process;
  
    
  process(state_p, counter_p, eof_p, matrix_p, matrixIn, infoIn, upstream_rdy, dwstream_rdy, info_p, data_p, sd_rdy_p, rd_rdy_p, eofIn)
          
    variable finalBlockLen: integer range 0 to 16;
    
    begin
      
      state_n               <=state_p;
      counter_n             <=counter_p;
      eof_n                 <='0';
      matrix_n              <=matrix_p;
      info_n                <=info_p;
      data_n                <=data_p;
      sd_rdy_n              <=sd_rdy_p;
      rd_rdy_n              <=rd_rdy_p;     
      case state_p is      
      when waitMatrix=>
        sd_rdy_n        <='0';
        rd_rdy_n        <='1';
        if upstream_rdy='1' then
          counter_n         <=0;
          info_n            <=infoIn;
          matrix_n          <=matrixIn;
          eof_n             <='0';
          sd_rdy_n          <='1';
          rd_rdy_n          <='0';
          case eofIn is
          when '1'=>
            finalBlockLen   :=CONV_INTEGER(info_p(71 downto 68)); 
            data_n          <=matrixIn(0);
            counter_n       <=1;
            if finalBlockLen=1 then  --final block=0=>16=>elsif=>sendLastBlock=>accept case counter_p=15 exit then.
              eof_n         <='1';
              state_n       <=sendFinalByte;
            else
              state_n       <=sendLastBlock;
            end if;
          when others=>
            state_n         <=sendData0;
            data_n          <=matrixIn(0);
            counter_n       <=1;
          end case;
        else
          state_n           <=state_p;
        end if;
        
      when sendFinalByte=>
        if dwstream_rdy='1'then
          rd_rdy_n          <='1';
          sd_rdy_n          <='0';
          state_n           <=waitMatrix;
          counter_n         <=0;
        else
          rd_rdy_n          <='0';
          sd_rdy_n          <='1';
          eof_n             <='1';
        end if;
        
      when sendLastBlock=>
        rd_rdy_n        <='0';
        sd_rdy_n        <='1';
        finalBlockLen   :=CONV_INTEGER(info_p(71 downto 68)); 
        if dwstream_rdy='1'then
          if counter_p=15 then  --counter_p=1: matrix0 being sent
          --matrix(14) being sent , set eof=1 for matrix(15)
            eof_n       <='1';
            data_n      <=matrix_p(counter_p);
            state_n     <=sendFinalByte;
          elsif counter_p=finalBlockLen-1 then --e.g. fbl=5, 5 bytes in the last block, send m(0~4), counter_p=5-1=4 means m(3)begin sent, prepare eof for m(4)
            eof_n       <='1';
            data_n      <=matrix_p(counter_p);
            state_n     <=sendFinalByte;
          else
            eof_n       <='0';
            data_n      <=matrix_p(counter_p);
            counter_n   <=counter_p+1;
          end if;                     
        else
          state_n           <=state_p;
        end if;
        
        
      when sendData0=>
        sd_rdy_n        <='1';
        rd_rdy_n        <='0';
        if dwstream_rdy='1'then
          case counter_p is
          when 16=>
            if upstream_rdy='1'then
              case infoIn(84)is
              when '1'=>
                sd_rdy_n        <='0';
                rd_rdy_n        <='1';
                state_n         <=waitMatrix;
              when others=>
                state_n         <=sendData0;
                data_n          <=matrixIn(0);
                rd_rdy_n        <='1';
                counter_n       <=1;
              end case;
            else
              sd_rdy_n        <='0';
              rd_rdy_n        <='1';
              state_n         <=waitMatrix;
            end if;
          when others=>
            data_n          <=matrix_p(counter_p);
            counter_n       <=counter_p+1;
          end case;
        else
          state_n           <=state_p;
        end if;
      end case;
      
  end process;
        

  process(rst,clk)
    begin
      if rst='1' then
        matrix_p            <=ZEROMATRIX;
        eof_p               <='0';
        state_p             <=waitMatrix;
        counter_p           <=0;
        data_p              <=X"FF";
        info_p              <=(others=>'0');
        sd_rdy_p            <='0';
        rd_rdy_p            <='0';
      elsif rising_edge(clk)then
        matrix_p            <=matrix_n;
        eof_p               <=eof_n;
        state_p             <=state_n;
        counter_p           <=counter_n;
        data_p              <=data_n;
        info_p              <=info_n;
        sd_rdy_p            <=sd_rdy_n;
        rd_rdy_p            <=rd_rdy_n;
      end if;
  end process;

end rtl;




















