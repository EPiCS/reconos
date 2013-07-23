library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity readStage is
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
end readStage;
  
  
architecture rtl of readStage is
  
  signal dataMatrix_p:          DATA_ARRAY;
  signal dataMatrix_n:          DATA_ARRAY;
  signal counter_p:             integer range 0 to 16;
  signal counter_n:             integer range 0 to 16;
  signal pktLen_p:              std_logic_vector(15 downto 0);
  signal pktLen_n:              std_logic_vector(15 downto 0);
  signal eof_p:                 std_logic;
  signal eof_n:                 std_logic;
  signal sof_p:                 std_logic;
  signal sof_n:                 std_logic;
  signal send_rdy_p:            std_logic;
  signal send_rdy_n:            std_logic;
  signal read_rdy_p:            std_logic;
  signal read_rdy_n:            std_logic;
  
  signal noc_rx_direction_p:       std_logic;
  signal noc_rx_priority_p:        std_logic_vector(1 downto 0);
  signal noc_rx_latencyCritical_p: std_logic;
  signal noc_rx_srcIdp_p:          std_logic_vector(31 downto 0);
  signal noc_rx_dstIdp_p:          std_logic_vector(31 downto 0);
  
  signal noc_rx_direction_n:       std_logic;
  signal noc_rx_priority_n:        std_logic_vector(1 downto 0);
  signal noc_rx_latencyCritical_n: std_logic;
  signal noc_rx_srcIdp_n:          std_logic_vector(31 downto 0);
  signal noc_rx_dstIdp_n:          std_logic_vector(31 downto 0);   
  type stateType is(
    waitStart,
    waitPkt,
    loadData,
    sendData0,
    sendData1
  );
  signal state_p:         stateType;
  signal state_n:         stateType;
  signal tmp : std_logic;
  
begin

	tmp <= noc_rx_sof;
  
  matrixOut         <=dataMatrix_p;
  noc_rx_dst_rdy    <=read_rdy_p;
  send_rdy          <=send_rdy_p;
  info              <=sof_p&eof_p&pktLen_p&noc_rx_direction_p&noc_rx_priority_p&noc_rx_latencyCritical_p&noc_rx_srcIdp_p&noc_rx_dstIdp_p;
  
  process(clk,rst)
    begin
      if(rst='1')then
        readStageIdle<='1';
      elsif rising_edge(clk)then
        case state_p is
        when waitStart=>
          readStageIdle<='1';
        when waitPkt=>
          readStageIdle<='1';
        when others=>
          readStageIdle<='0';
        end case;
      end if;
  end process;
  
  process(clk,rst)
    begin
      if(rst='1')then
        eof_p<='0';
        sof_p<='0';
        noc_rx_direction_p<='0';
        noc_rx_priority_p<="00";
        noc_rx_latencyCritical_p<='0';
        noc_rx_srcIdp_p<=(others=>'0');
        noc_rx_dstIdp_p<=(others=>'0');
      elsif rising_edge(clk)then
        eof_p<=eof_n;
        sof_p<=sof_n;
        noc_rx_direction_p<=noc_rx_direction_n;
        noc_rx_priority_p<=noc_rx_priority_n;
        noc_rx_latencyCritical_p<=noc_rx_latencyCritical_n;
        noc_rx_srcIdp_p<=noc_rx_srcIdp_n;
        noc_rx_dstIdp_p<=noc_rx_dstIdp_n;
      end if;
  end process;
  
  process(state_p, noc_rx_src_rdy,
  noc_rx_direction, noc_rx_priority, noc_rx_latencyCritical, noc_rx_srcIdp, noc_rx_dstIdp,
  noc_rx_direction_p, noc_rx_priority_p, noc_rx_latencyCritical_p, noc_rx_srcIdp_p, noc_rx_dstIdp_p
  )
  begin
    noc_rx_direction_n<=noc_rx_direction_p;
    noc_rx_priority_n<=noc_rx_priority_p;
    noc_rx_latencyCritical_n<=noc_rx_latencyCritical_p;
    noc_rx_srcIdp_n<=noc_rx_srcIdp_p;
    noc_rx_dstIdp_n<=noc_rx_dstIdp_p;
    case state_p is
    when waitPkt=>
      if noc_rx_src_rdy='1'then
        noc_rx_direction_n<=noc_rx_direction;
        noc_rx_priority_n<=noc_rx_priority;
        noc_rx_latencyCritical_n<=noc_rx_latencyCritical;
        noc_rx_srcIdp_n<=noc_rx_srcIdp;
        noc_rx_dstIdp_n<=noc_rx_dstIdp;
      end if;
    when others=>
      noc_rx_direction_n<=noc_rx_direction_p;
      noc_rx_priority_n<=noc_rx_priority_p;
      noc_rx_latencyCritical_n<=noc_rx_latencyCritical_p;
      noc_rx_srcIdp_n<=noc_rx_srcIdp_p;
      noc_rx_dstIdp_n<=noc_rx_dstIdp_p;
    end case;
  end process;
  
  process(state_p, noc_rx_eof, noc_rx_sof, dwstream_rdy,sof_p,eof_p)
    begin
      eof_n<=eof_p;
      sof_n<=sof_p;
      case state_p is
      when waitStart=>
        eof_n<='0';
        sof_n<='1';
      when waitPkt=>
        eof_n<=noc_rx_eof;
        sof_n<=noc_rx_sof;
      when loadData=>
        sof_n<=sof_p;
        eof_n<=noc_rx_eof;
      when sendData0=>
        --after the 1st 16B, next batch would not be sof=1.
        if(dwstream_rdy='1')then
          sof_n<='0';
        else
          sof_n<=sof_p;
        end if;
      when sendData1=>
        --after taken the last batch of data, next must be the start of pkt
        if(dwstream_rdy='1')then
          sof_n<='1';
        else
          sof_n<=sof_p;
        end if;
      end case;
    end process;
    
  process(clk,rst)
    begin
      if(rst='1')then
        state_p         <=waitStart;
        dataMatrix_p    <=ZEROMATRIX;
        counter_p       <=0;
        pktLen_p        <=(others=>'0');
        send_rdy_p      <='0';
        read_rdy_p      <='0';
      elsif rising_edge(clk)then
        state_p         <=state_n;
        dataMatrix_p    <=dataMatrix_n;
        counter_p       <=counter_n;
        pktLen_p        <=pktLen_n;
        send_rdy_p      <=send_rdy_n;
        read_rdy_p      <=read_rdy_n;
      end if;
  end process;


  process(start, state_p, counter_p, pktLen_p, noc_rx_data, noc_rx_sof, noc_rx_eof, noc_rx_src_rdy, dwstream_rdy, dataMatrix_p, send_rdy_p, read_rdy_p)
    begin
      state_n               <=state_p;
      counter_n             <=counter_p;
      pktLen_n              <=pktLen_p;
      dataMatrix_n          <=dataMatrix_p;
      send_rdy_n            <=send_rdy_p;
      read_rdy_n            <=read_rdy_p;
      
      case state_p is
      when waitStart=>
        send_rdy_n                <='0';
        read_rdy_n                <='0';
        if start='1' then
          state_n                 <=waitPkt;
          counter_n               <=0;
          pktLen_n                <=(others=>'0');
          dataMatrix_n            <=ZEROMATRIX;
          read_rdy_n              <='1';
        else
          state_n                 <=state_p;
        end if;
        
      when waitPkt=>
	      dataMatrix_n              <=ZEROMATRIX;
	      send_rdy_n                <='0';
	      read_rdy_n                <='1';
	      
        if noc_rx_src_rdy='1' then
          case noc_rx_sof is
          when '1'=>
            if noc_rx_eof='0'then
              state_n             <=loadData;
              dataMatrix_n(0)     <=noc_rx_data;
              for i in 1 to 15 loop
                dataMatrix_n(i)   <=X"00";
              end loop;
              counter_n           <=1;
              pktLen_n            <=X"0001";
            else
              state_n             <=sendData1;
              send_rdy_n          <='1';
              read_rdy_n          <='0';
              dataMatrix_n(0)     <=noc_rx_data;
              for i in 1 to 15 loop
                dataMatrix_n(i)   <=X"00";
              end loop;
              counter_n           <=0;
              pktLen_n            <=X"0001";
            end if;
          when others=>
            if noc_rx_eof='1' then
              state_n             <=sendData1;
              send_rdy_n          <='1';
              read_rdy_n          <='0';
              dataMatrix_n(0)     <=noc_rx_data;
              for i in 1 to 15 loop
                dataMatrix_n(i)   <=X"00";
              end loop;
              counter_n           <=0;
              pktLen_n            <=X"0001";
            else
              --sof=0 && eof=0 :in the middle of a pkt
              state_n             <=loadData;
              dataMatrix_n(0)     <=noc_rx_data;
              counter_n           <=1;
              pktLen_n            <=pktLen_p+1;
            end if;
          end case;
        else
          state_n                 <=state_p;
        end if;
        
      when loadData=>
        send_rdy_n                <='0';
	      read_rdy_n                <='1';
	      
        case noc_rx_src_rdy is
        when '1'=>
          if noc_rx_eof='1'then
              dataMatrix_n(counter_p) <=noc_rx_data;
              counter_n               <=0;
              pktLen_n                <=pktLen_p+1;
              state_n                 <=sendData1;
              send_rdy_n              <='1';
              read_rdy_n              <='0';
          else
            case counter_p is
            when 15=>
              dataMatrix_n(15)        <=noc_rx_data;
              counter_n               <=0;
              pktLen_n                <=pktLen_p+1;
              state_n                 <=sendData0;
              send_rdy_n              <='1';
              read_rdy_n              <='0';
              if dwstream_rdy='1'then
                state_n               <=waitPkt;
                send_rdy_n            <='1';
                read_rdy_n            <='1';
              else
                state_n               <=sendData0;
                send_rdy_n            <='1';
                read_rdy_n            <='0';
              end if;
            when others=>
              dataMatrix_n(counter_p) <=noc_rx_data;
              counter_n               <=counter_p+1;
              pktLen_n                <=pktLen_p+1;
              state_n                 <=state_p;
            end case;            
          end if;
        when others=>
          state_n                     <=state_p;
        end case;
        
      when sendData0=>
        if dwstream_rdy='1' then
          state_n                     <=waitPkt;
			    send_rdy_n                  <='0';
	        read_rdy_n                  <='1';
        else
          state_n                     <=state_p;
          send_rdy_n                  <='1';
	        read_rdy_n                  <='0';
        end if;
        
      when sendData1=>
        if dwstream_rdy='1' then
          state_n                     <=waitStart;
			    send_rdy_n                  <='0';
	        read_rdy_n                  <='0';
        else
          state_n                     <=state_p;
          send_rdy_n                  <='1';
	        read_rdy_n                  <='0';
        end if;
      end case;

  end process;
    
  end rtl;
            
    


            
          

       
                
    
