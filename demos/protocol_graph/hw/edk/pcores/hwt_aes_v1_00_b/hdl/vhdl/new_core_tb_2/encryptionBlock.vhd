library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity encryptBlock is
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
    infoIn                :in std_logic_vector(85 downto 0);
    infoOut               :out std_logic_vector(85 downto 0);
    read_rdy              :out std_logic;
    send_rdy              :out std_logic;
    dataOut               :out DATA_ARRAY;
    addrOut               :out std_logic_vector(3 downto 0)
  );
end encryptBlock;



architecture rtl of encryptBlock is
  
  signal info_p           :std_logic_vector(85 downto 0);
  signal info_n           :std_logic_vector(85 downto 0);
  signal round_p          :std_logic_vector(3 downto 0);
  signal step_p           :std_logic_vector(1 downto 0);
  signal round_n          :std_logic_vector(3 downto 0);
  signal step_n           :std_logic_vector(1 downto 0);
  signal data_p           :DATA_ARRAY;
  signal data_n           :DATA_ARRAY;
  signal mode_p           :std_logic_vector(1 downto 0);
  signal mode_n           :std_logic_vector(1 downto 0);
  signal stage_p          :std_logic_vector(1 downto 0);
  signal stage_n          :std_logic_vector(1 downto 0);
  signal send_rdy_p       :std_logic;
  signal send_rdy_n       :std_logic;
  signal read_rdy_p       :std_logic;
  signal read_rdy_n       :std_logic;
  
  TYPE stateType is(
    waitData,
    encrData,
    sendData
  );
  signal state_p          :stateType;
  signal state_n          :stateType;
  signal sboxMatrixResult :DATA_ARRAY;
  signal addKeyResult     :DATA_ARRAY;
  signal mixColResult     :DATA_ARRAY;
  
  COMPONENT addkey is
  port(
    round_key_bytes:            in  DATA_ARRAY;
    round_txt_bytes:            in  DATA_ARRAY;        
    ciphered_bytes:             out DATA_ARRAY   
  );
  end COMPONENT;
  
  COMPONENT mixcol is
  port(
    rst:        in std_logic;
    en:         in std_logic;
    bi:         in  DATA_ARRAY;
    bo:         out DATA_ARRAY    
  );
  end COMPONENT;
  
  COMPONENT sboxMatrix is  
  port(   
    clk:                        in std_logic;
    rst:                        in std_logic;
    byte_array_in:              in DATA_ARRAY;        
    byte_array_out:             out DATA_ARRAY   
  );
  end COMPONENT;
  
  begin
    
    --InfoOut       <=InfoIn when state_p=waitData AND upstream_rdy='1' AND state_p=waitData;
    infoOut<=info_p;
	 
    sboxMatrix0:          sboxMatrix
    port map(
     clk                  =>clk,
     rst                  =>rst,
     byte_array_in        =>data_p,
     byte_array_out       =>sboxMatrixResult
    );
    mixCol0:              mixCol
    port map(
      rst                 =>rst,
      en                  =>en,
      bi                  =>data_p,
      bo                  =>mixColResult
    );
    addKey0:              addKey
    port map(
      round_key_bytes     =>keyIn,
      round_txt_bytes     =>data_p,
      ciphered_bytes      =>addkeyResult
    );
    
    process(clk,rst)
      begin
        if(rst='1')then                  
          state_p         <=waitData;
          read_rdy_p      <='0';
          send_rdy_p      <='0';
          round_p         <=X"0";
          step_p          <="00";
          for i in 0 to 15 loop
            data_p(i)     <=X"FF";
          end loop;
          mode_p          <=mode128;
          stage_p         <="00";
			    info_p				<=(others=>'0');
        elsif rising_edge(clk)then
          state_p         <=state_n;
          read_rdy_p      <=read_rdy_n;
          send_rdy_p      <=send_rdy_n;
          round_p         <=round_n;
          step_p          <=step_n;
          data_p          <=data_n;
          mode_p          <=mode_n;
          stage_p         <=stage_n;
			    info_p				      <=info_n;
        end if;
    end process;
    

    addrOut           <=round_p;
    
    dataOut           <=data_p;
    send_rdy          <=send_rdy_p;
    read_rdy          <=read_rdy_p;
    

    
  process(state_p, round_p, step_p, stage_p, data_p, mode_p, mode, stage, 
	 upstream_rdy, dwstream_rdy, dataIn, sboxMatrixResult, mixColResult, addKeyResult,
	 send_rdy_p, read_rdy_p, info_p, infoIn
	 )
    begin
      state_n         <= state_p;
      send_rdy_n      <= send_rdy_p;
      read_rdy_n      <= read_rdy_p;
      stage_n         <= stage_p;
      mode_n          <= mode_p;
      step_n          <= step_p;
      round_n         <= round_p;
      data_n          <= data_p;
		  info_n				<=info_p;
		
      case state_p is
        
        
      when waitData=>
          send_rdy_n      <= '0';
          if(upstream_rdy='1')then
			      info_n			<=infoIn;
            state_n         <= encrData;
            read_rdy_n      <= '0';
            mode_n          <=mode;
            data_n          <=dataIn;
            stage_n         <=stage;
            case stage is
            when "00"=>
              round_n       <=X"0";
              step_n        <="00";
            when "01"=>
              round_n       <=X"4";
              step_n        <="00";
            when "10"=>
              round_n       <=X"8";
              step_n        <="00";
            when others=>
              round_n       <=X"C";
              step_n        <="00";
            end case;
          else
            state_n         <=state_p;
            read_rdy_n      <= '1';
            step_n          <=step_p;
            mode_n          <=mode_p;
            data_n          <=data_p;
          end if;
          
          
      when encrData=>
        
          read_rdy_n    <='0';
          send_rdy_n    <='0';--9:17pm
          
          case stage_p is
            
          --STAGE A:  
          when "00"=>
              case step_p is
              when "00"=>
                if round_p=0 then
                  data_n      <=addKeyResult;
                  step_n      <="00";
                  round_n     <=X"1";
                else
                  data_n      <=sboxMatrixResult;
                  step_n      <="01";
                  round_n     <=round_p;
                end if;
              when "01"=>
                data_n      <=mixColResult;
                step_n      <="10";
                round_n     <=round_p;
              when others=>              
                data_n      <=addKeyResult;
                step_n      <="00";
                if round_p=X"3" then
                  state_n   <=sendData;
                  send_rdy_n<='1';
                  round_n   <=X"0";
                else
                  state_n   <=state_p;
                  round_n   <=round_p+1;
                end if;
              end case;
              
            --STAGE B:  
            when "01"=>
              case step_p is
              when "00"=>
                if round_p=0 then
                  data_n      <=addKeyResult;
                  step_n      <="00";
                  round_n     <=X"1";
                else
                  data_n      <=sboxMatrixResult;
                  step_n      <="01";
                  round_n     <=round_p;
                end if;
              when "01"=>
                data_n      <=mixColResult;
                step_n      <="10";
                round_n     <=round_p;
              when others=>              
                data_n      <=addKeyResult;
                step_n      <="00";
                if round_p=X"7" then
                  state_n   <=sendData;
                  send_rdy_n<='1';
                  round_n   <=X"4";
                else
                  state_n   <=state_p;
                  round_n   <=round_p+1;
                end if;
              end case;
              
            --STAGE C:  
            when "10"=>
              case mode_p is
                
              when mode128=>
                case step_p is
                when "00"=>
                  data_n      <=sboxMatrixResult;
                  step_n      <="01";
                  round_n     <=round_p;
                when "01"=>
                  if round_p/=X"A" then 
                    data_n      <=mixColResult;
                    step_n      <="10";
                    round_n     <=round_p;
                  else
                    data_n      <=addKeyResult;
                    step_n      <="00";
                    round_n     <=X"8";
                    state_n     <=sendData;
                    send_rdy_n  <='1';
                  end if;
                when others=>             
                  data_n      <=addKeyResult;
                  step_n      <="00";
                  round_n     <=round_p+1;
                end case;
                
              when others=>
                case step_p is
                when "00"=>
                  data_n      <=sboxMatrixResult;
                  step_n      <="01";
                  round_n     <=round_p;
                when "01"=>
                    data_n      <=mixColResult;
                    step_n      <="10";
                    round_n     <=round_p;
                when others=>             
                  data_n      <=addKeyResult;
                  step_n      <="00";
                  round_n     <=round_p+1;
                  if round_p =X"B" then
                    state_n   <=sendData;
                    send_rdy_n<='1';
                    round_n   <=X"8";
                  else
                    state_n   <=state_p;
                  end if;
                end case;
                
              end case;                               ---mode_p
            
            --STAGE D : 
            when others=>
              case mode_p is
                
              when mode128=>
                state_n       <=sendData;
                send_rdy_n    <='1';
                
              when mode192=>
                 case step_p is
                  when "00"=>
                    data_n      <=sboxMatrixResult;
                    step_n      <="01";
                  when "01"=>
                      data_n      <=addKeyResult;
                      step_n      <="00";
                      state_n     <=sendData;
                      send_rdy_n  <='1';
                  when others=>             
                    data_n      <=addKeyResult;
                    step_n      <="00";
                  end case;               
                
              when others=>
                case step_p is
                when "00"=>
                  data_n      <=sboxMatrixResult;
                  step_n      <="01";
                  round_n     <=round_p;
                when "01"=>
                  if round_p/=X"E" then 
                    data_n      <=mixColResult;
                    step_n      <="10";
                    round_n     <=round_p;
                  else
                    data_n      <=addKeyResult;
                    step_n      <="00";
                    round_n     <=X"C";
                    state_n     <=sendData;
                    send_rdy_n  <='1';
                  end if;
                when others=>             
                  data_n      <=addKeyResult;
                  step_n      <="00";
                  round_n     <=round_p+1;
                end case;
              end case;
            
            end case;                                 ---stage_p
            
            
          when sendData=>
            send_rdy_n  <='1';
            read_rdy_n  <='0';
            if dwstream_rdy='1' then
              read_rdy_n  <='1';
              send_rdy_n  <='0';
              state_n     <=waitData;
            else
              state_n     <=state_p;
            end if;
            
          end case;
                  
        end process;
        
      end rtl;
                
                  
                  
                
              
          
              
    

