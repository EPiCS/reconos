library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pktSinkCore is
	port (
	  clk                :in std_logic;
	  rst                :in std_logic;
	  startRcv           :in std_logic;
	  pktNumber          :in std_logic_vector(31 downto 0);
	  pktDecoder_sof     :in std_logic;
	  pktDecoder_eof     :in std_logic;
	  pktDecoder_data    :in std_logic_vector(7 downto 0);
	  pktDecoder_src_rdy :in std_logic;
	  pktDecoder_dst_rdy :out std_logic;
	  clkCounter         :out std_logic_vector(63 downto 0);
	  pktNumCounter      :out std_logic_vector(31 downto 0);
	  allPktsRcvd        :out std_logic
	);	
end pktSinkCore;

architecture implementation of pktSinkCore is

signal pktNum_p:           std_logic_vector(31 downto 0);
signal pktNum_n:           std_logic_vector(31 downto 0);
signal pktNumCounter_p:    std_logic_vector(31 downto 0);
signal pktNumCounter_n:    std_logic_vector(31 downto 0);
signal clkCounter_p:       std_logic_vector(63 downto 0);
signal clkCounter_n:       std_logic_vector(63 downto 0);
signal i_rdy_p:            std_logic;
signal i_rdy_n:            std_logic;
type stateType is(
  waitStart,
  rcvPkts,
  finish
);
signal state_p: stateType;
signal state_n: stateType;
begin  
  pktDecoder_dst_rdy<=i_rdy_p; 
  clkCounter        <=clkCounter_p;
  pktNumCounter  <=pktNumCounter_p;
  process(clk,rst)
    begin
      if rst='1'then
        pktNum_p          <=X"00000064";
        pktNumCounter_p   <=(others=>'0');
        clkCounter_p      <=(others=>'0');
        state_p           <=waitStart;
        i_rdy_p           <='1';             --'0'
      elsif rising_edge(clk)then
        pktNum_p          <=pktNum_n;
        pktNumCounter_p   <=pktNumCounter_n;
        clkCounter_p      <=clkCounter_n;
        state_p           <=state_n;
        i_rdy_p           <=i_rdy_n;
      end if;
  end process;
     
  process(state_p,startRcv,pktNumber,pktDecoder_sof,pktDecoder_eof,pktDecoder_src_rdy,pktNum_p,pktNumCounter_p,clkCounter_p,i_rdy_p )
    begin
      state_n               <=state_p;
      pktNum_n              <=pktNum_p;
      pktNumCounter_n       <=pktNumCounter_p;
      clkCounter_n          <=clkCounter_p;
      i_rdy_n               <=i_rdy_p;
      allPktsRcvd           <='0';
      case state_p is
        
      when waitStart=>
        if startRcv='1'then
          pktNum_n          <=pktNumber;
          i_rdy_n           <='1';
          state_n           <=rcvPkts;
        else
          state_n           <=state_p;
        end if;
        
      when rcvPkts=>
        clkCounter_n        <=clkCounter_p+1;
        if pktDecoder_src_rdy='1'then
          if pktNumCounter_p=pktNum_p then
            allPktsRcvd     <='1';
            state_n         <=finish;
          else
            case pktDecoder_eof is
            when '1'=>
              pktNumCounter_n<=pktNumCounter_p+1;
            when others=>
              state_n           <=state_p;
            end case;
          end if;
        else
          state_n           <=state_p;
        end if;
        
      when finish=>
        allPktsRcvd<='1';
        i_rdy_n     <='1';
        state_n     <=state_p;
      end case;
      
end process;       

end architecture;
