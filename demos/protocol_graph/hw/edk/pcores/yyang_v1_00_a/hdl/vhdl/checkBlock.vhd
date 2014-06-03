library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity checkBlock is
  port(
    clk                   :in std_logic;
    rst                   :in std_logic;
    en                    :in std_logic;
    upstream_rdy          :in std_logic;
    dwstream_rdy          :in std_logic;
    dataIn                :in DATA_ARRAY;
    --sof+eof+pktLen+otherInfo=1+1+16+68
    infoIn                :in std_logic_vector(85 downto 0);
    infoOut               :out std_logic_vector(85 downto 0);
    read_rdy              :out std_logic;
    send_rdy              :out std_logic;
    dataOut               :out DATA_ARRAY
  );
end checkBlock;

--eof is on bit 84 of infoIn/out(85 downto 0);
--A: older block. B: newer block
architecture rtl of checkBlock is
  
  signal dataMidA_n:         DATA_ARRAY;
  signal infoMidA_n:         std_logic_vector(85 downto 0);
  signal dataMidB_n:         DATA_ARRAY;
  signal infoMidB_n:         std_logic_vector(85 downto 0);
  signal valiA_n:           std_logic;
  signal valiB_n:           std_logic;
  signal read_rdy_n:        std_logic;
  signal send_rdy_n:        std_logic;
  
  signal dataMidA_p:         DATA_ARRAY;
  signal infoMidA_p:         std_logic_vector(85 downto 0);
  signal dataMidB_p:         DATA_ARRAY;
  signal infoMidB_p:         std_logic_vector(85 downto 0);
  signal valiA_p:           std_logic;
  signal valiB_p:           std_logic;
  signal read_rdy_p:        std_logic;
  signal send_rdy_p:        std_logic;
  
  TYPE stateType is(
    wait1stBlock,
    wait2ndBlock,
    waitSendA,
    waitFinalSendA
  );
  
  signal state_p:           stateType;
  signal state_n:           stateType;
  
begin
  
  infoOut         <=infoMidA_p;
  read_rdy        <=read_rdy_p;
  send_rdy        <=send_rdy_p;
  dataOut         <=dataMidA_p;
  
  process(clk,rst)
    begin
      if rst='1'then
        dataMidA_p       <=ZEROMATRIX;
        infoMidA_p       <=(others=>'0');
        dataMidB_p       <=ZEROMATRIX;
        infoMidB_p       <=(others=>'0');
        valiA_p         <='0';
        valiB_p         <='0';
        read_rdy_p      <='0';
        send_rdy_p      <='0';
        state_p         <=wait1stBlock;
      elsif rising_edge(clk)then
        dataMidA_p       <=dataMidA_n;
        infoMidA_p       <=infoMidA_n;
        dataMidB_p       <=dataMidB_n;
        infoMidB_p       <=infoMidB_n;
        valiA_p         <=valiA_n;
        valiB_p         <=valiB_n;
        read_rdy_p      <=read_rdy_n;
        send_rdy_p      <=send_rdy_n;
        state_p         <=state_n;
      end if;
    end process;
    
    process(
      upstream_rdy,
      dwstream_rdy,
      dataIn,
      infoIn,
      dataMidA_p,
      infoMidA_p,
      dataMidB_p,
      infoMidB_p,
      valiA_p,
      valiB_p,
      read_rdy_p,
      send_rdy_p,
      state_p
      )
      begin
        dataMidA_n            <=dataMidA_p;
        infoMidA_n            <=infoMidA_p;
        dataMidB_n            <=dataMidB_p;
        infoMidB_n            <=infoMidB_p;
        valiA_n               <=valiA_p;
        valiB_n               <=valiB_p;
        read_rdy_n            <=read_rdy_p;
        send_rdy_n            <=send_rdy_p;
        state_n               <=state_p;
        
        case state_p is
        when wait1stBlock=>
          if upstream_rdy='0' then
            dataMidA_n          <=ZEROMATRIX;
            infoMidA_n          <=(others=>'0');
            dataMidB_n          <=ZEROMATRIX;
            infoMidB_n          <=(others=>'0');
            valiA_n             <='0';
            valiB_n             <='0';
            read_rdy_n          <='1';
            send_rdy_n          <='0';
            state_n             <=state_p;
          else
            dataMidA_n          <=ZEROMATRIX;
            infoMidA_n          <=(others=>'0');
            dataMidB_n          <=dataIn;
            infoMidB_n          <=infoIn;
            valiA_n             <='0';
            valiB_n             <='1';
            read_rdy_n          <='1';
            send_rdy_n          <='0';
            state_n             <=wait2ndBlock;
          end if;          
        when wait2ndBlock=>
          if upstream_rdy='1' then
            dataMidA_n          <=dataMidB_p;
            infoMidA_n          <=infoMidB_p;
            dataMidB_n          <=dataIn;
            infoMidB_n          <=infoIn;
            valiA_n             <='1';
            valiB_n             <='1';
            --now A and B are filled with data, check infoIn(84)=eof=1?0:
            if infoIn(84)='0' then
              state_n           <=waitSendA;
              send_rdy_n        <='1';
            else
              --eof of packet!!, preInject!
              infoMidA_n(84)    <='1';
              infoMidA_n(83 downto 68)<=dataIn(0)&dataIn(1);
              send_rdy_n        <='1';
              state_n           <=waitFinalSendA;
            end if;
          else
            --must wait for both 2 blocks in to decide!
            state_n             <=state_p;
          end if;
        when waitFinalSendA=>
          if dwstream_rdy='1'then --A sent, B discard, back to the same situation as after reset
            dataMidA_n          <=ZEROMATRIX;
            infoMidA_n          <=(others=>'0');
            dataMidB_n          <=ZEROMATRIX;
            infoMidB_n          <=(others=>'0');
            valiA_n             <='0';
            valiB_n             <='0';
            read_rdy_n          <='1';
            send_rdy_n          <='0';
            state_n             <=wait1stBlock;
          else
            state_n             <=state_p;
          end if;
        when waitSendA=> --normal, A B were valid, B not end, A will be sent
          if dwstream_rdy='1'then
            --A sent
            dataMidA_n          <=dataMidB_p;
            infoMidA_n          <=infoMidB_p;
            send_rdy_n          <='0'; --though A sent, and was filled with B, still wait for new packet to decide.
            read_rdy_n          <='1'; --A now is filled with B, wait for a new block to decide
            state_n             <=wait2ndBlock;
          else
            state_n             <=state_p;
          end if;
             
        end case;
                          
      end process;
  
end rtl;
