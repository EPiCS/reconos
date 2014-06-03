library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pktGenCore is
	port (
	  clk                :in std_logic;
	  rst                :in std_logic;	  
	  pktLength          :in std_logic_vector(31 downto 0);
	  pktNumber          :in std_logic_vector(31 downto 0);
	  startGen           :in std_logic;	  
	  pktEncoder_dst_rdy :in std_logic;
	  pktLenCounter      :out std_logic_vector(31 downto 0);
	  pktNumCounter      :out std_logic_vector(31 downto 0);
	  allPktsSent        :out std_logic;	  
	  pktVector          :out std_logic_vector(10 downto 0)
	);	
end pktGenCore;

architecture implementation of pktGenCore is
  constant pktHead            :std_logic_vector(10 downto 0) :="10000000011";
  constant pktMid             :std_logic_vector(10 downto 0) :="00000000101";
  constant pktEnd             :std_logic_vector(10 downto 0) :="01000001001";
  constant pktNotReady        :std_logic_vector(10 downto 0) :="00111111110";   
  type stateType is(
    waitGen,
    sendHead,
    sendMid,
    sendEnd,
    finish
  );
  signal state_p:          stateType;
  signal state_n:          stateType;  
  signal pktVector_p:      std_logic_vector(10 downto 0); 
  signal pktVector_n:      std_logic_vector(10 downto 0);
  signal pktNum_p:         std_logic_vector(31 downto 0);
  signal pktLen_p:         std_logic_vector(31 downto 0);
  signal pktNumCounter_p:  std_logic_vector(31 downto 0);
  signal pktLenCounter_p:  std_logic_vector(31 downto 0);
  signal pktNum_n:         std_logic_vector(31 downto 0);
  signal pktLen_n:         std_logic_vector(31 downto 0);
  signal pktNumCounter_n:  std_logic_vector(31 downto 0);
  signal pktLenCounter_n:  std_logic_vector(31 downto 0);
  signal allPktsSent_p:    std_logic;
  signal allPktsSent_n:    std_logic;
begin  
  
  pktVector       <=pktVector_p;
  allPktsSent     <=allPktsSent_p;
  pktLenCounter   <=pktLenCounter_p;
  pktNumCounter   <=pktNumCounter_p;
   
  process(clk,rst)
    begin
      if rst='1'then
        state_p               <=waitGen;
        pktNum_p              <=X"00000064"; --100  pkts
        pktLen_p              <=X"000003E8"; --1000 Bytes/Pkt
        pktNumCounter_p       <=(others=>'0');
        pktLenCounter_p       <=(others=>'0');
        pktVector_p           <=pktNotReady;
        allPktsSent_p         <='0';
      elsif rising_edge(clk)then
        state_p               <=state_n;
        pktNum_p              <=pktNum_n;
        pktLen_p              <=pktLen_n;
        pktNumCounter_p       <=pktNumCounter_n;
        pktLenCounter_p       <=pktLenCounter_n;
        pktVector_p           <=pktVector_n;
        allPktsSent_p         <=allPktsSent_n;
      end if;
  end process;
     
  process(state_p, startGen, pktLength, pktNumber, pktEncoder_dst_rdy, pktNum_p, pktLen_p, pktNumCounter_p, pktLenCounter_p, pktVector_p, allPktsSent_p)
    begin
      state_n                 <=state_p;
      pktNum_n                <=pktNum_p;
      pktLen_n                <=pktLen_p;
      pktNumCounter_n         <=pktNumCounter_p;
      pktLenCounter_n         <=pktLenCounter_p;
      pktVector_n             <=pktVector_p;
      allPktsSent_n           <=allPktsSent_p;      
      case state_p is
        
      when waitGen=>
        if startGen='1'then
          state_n             <=sendHead;
          pktNum_n            <=pktNumber;
          pktLen_n            <=pktLength;
          pktNumCounter_n     <=(others=>'0');
          pktLenCounter_n     <=(others=>'0');
          pktVector_n         <=pktHead;
          allPktsSent_n       <='0';
        else
          state_n             <=state_p;
        end if;
        
      when sendHead=>
        if pktEncoder_dst_rdy='1'then
          state_n             <=sendMid;
          pktLenCounter_n     <=pktLenCounter_p+1;
          pktVector_n         <=pktMid;
        else
          state_n             <=state_p;
        end if;
        
      when sendMid=>
        if pktEncoder_dst_rdy='1'then
          pktLenCounter_n     <=pktLenCounter_p+1;
          if pktLenCounter_p=pktLen_p-1 then
            pktVector_n       <=pktEnd;
            state_n           <=sendEnd;
          else
            pktVector_n       <=pktMid;
          end if;
        else
          state_n             <=state_p;
        end if;
        
      when sendEnd=>
        if pktEncoder_dst_rdy='1'then
          if pktNumCounter_p=pktNum_p-1 then
            pktVector_n         <=pktNotReady;
            pktNumCounter_n     <=pktNumCounter_p+1;
            state_n             <=finish;
          else
            pktVector_n         <=pktHead;
            pktNumCounter_n     <=pktNumCounter_p+1;
            pktLenCounter_n     <=(others=>'0');
            state_n             <=sendHead;
          end if;
        else
          state_n               <=state_p;
        end if;
        
      when others=>
        pktVector_n           <=pktNotReady;
        allPktsSent_n         <='1';
        state_n               <=state_p;
      end case; 
end process;       

end architecture;