library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--library yyang_v1_00_a;
use work.yyangPkg.all;

entity control is
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
    
    --to keyBak & sendStage:
    keyInject:            out std_logic;
    
    --to readStage:
    permitEnc:            out std_logic;
    readStageIdle:        in std_logic;
    
    --to encryptionStage:
    stageAIdle:           in std_logic;
    stageBIdle:           in std_logic;
    stageCIdle:           in std_logic;
    stageDIdle:           in std_logic;
    
    --to sendStage:
    sendStageIdle:        in std_logic;
    globalLocalAddr:      out std_logic_vector(5 downto 0)
  );
end control;

architecture rtl of control is
  
  --signal cipherKey:       CIPHERKEY256_ARRAY;
  signal cipherKey_p:     CIPHERKEY256_ARRAY;
  signal cipherKey_n:     CIPHERKEY256_ARRAY;
  signal mode_p:          std_logic_vector(1 downto 0);
  signal mode_n:          std_logic_vector(1 downto 0);
  signal startExp_p:      std_logic;
  signal startExp_n:      std_logic;
  signal startEnc_p:      std_logic;
  signal startEnc_n:      std_logic;
  signal     globalLocalAddr_p:    std_logic_vector(5 downto 0);
  signal     globalLocalAddr_n:    std_logic_vector(5 downto 0);  
  constant ZEROKEY:       CIPHERKEY256_ARRAY:=(others=>X"00000000");
  type stateType is(
    waitKey,
    loadKey,
    expanKey,
    waitKeyValid,
    startEnc,
    encPkt
  );
  signal state_p:         stateType;
  signal state_n:         stateType;
  signal keyInject_p:     std_logic;
  signal keyInject_n:     std_logic;
  
  begin
    
    keyOut          <=cipherKey_p;
    mode            <=mode_p;
    permitEnc       <=startEnc_p;
    startExp        <=startExp_p;
    globalLocalAddr <=globalLocalAddr_p;
    keyInject       <=keyInject_p;
    
    process(rst, clk)
      begin
        if rst='1'then
          state_p           <=waitKey;
          mode_p            <=mode256;
          startExp_p        <='0';
          startEnc_p        <='0';
          cipherKey_p       <=ZEROKEY;
          keyInject_p       <='0';
          globalLocalAddr_p <="000100";
        elsif rising_edge(clk)then
          state_p           <=state_n;
          mode_p            <=mode_n;
          startExp_p        <=startExp_n;
          startEnc_p        <=startEnc_n;
          cipherKey_p       <=cipherKey_n;
          keyInject_p       <=keyInject_n;
          globalLocalAddr_p <=globalLocalAddr_n;
        end if;
      end process;
      
      
      
      process(
      state_p, 
      mode_p, 
      startExp_p, 
      startEnc_p, 
      cipherKey_p,
      globalLocalAddrIn,
      globalLocalAddr_p, 
      startTransmitKey,
      key256In,
      modeIn,
      readStageIdle,
      stageAIdle,
      stageBIdle,
      stageCIdle,
      sendStageIdle,
      keyValid
      )
        begin
          
          state_n           <=state_p;
          mode_n            <=mode_p;
          startExp_n        <=startExp_p;
          startEnc_n        <=startEnc_p;
          cipherKey_n       <=cipherKey_p;
          keyInject_n       <='0';
          globalLocalAddr_n <=globalLocalAddr_p;
          
          case state_p is
          when waitKey=>
            if startTransmitKey='1' then
              state_n       <=loadKey;
              mode_n        <=modeIn;
              cipherKey_n   <=key256In;
              globalLocalAddr_n<=globalLocalAddrIn;
              startExp_n    <='0';
              startEnc_n    <='0';              
            else
              state_n       <=state_p;
            end if;
          when loadKey=>
            state_n        <=expanKey;
            startExp_n     <='1';
          when expanKey=>
            state_n      <=waitKeyValid;
            startExp_n   <='0';
          when waitKeyValid=>
            if keyValid='1'then
              state_n      <=startEnc;
            else
              state_n      <=state_p;
            end if;
          when startEnc=>
            if readStageIdle='1' and stageAIdle='1' and stageBIdle='1' and stageCIdle='1' and stageDIdle ='1' and sendStageIdle='1' then
              state_n       <=encPkt;
              startEnc_n    <='1';
              keyInject_n   <='1';
            else
              state_n       <=state_p;
              startEnc_n    <='0';
            end if;
          when encPkt=>
            startExp_n     <='0';
            startEnc_n     <='1';
            if startTransmitKey='1' then
              state_n       <=loadKey;
              mode_n        <=modeIn;
              cipherKey_n   <=key256In;
              globalLocalAddr_n<=globalLocalAddrIn;
              startExp_n    <='0';
              startEnc_n    <='0';              
            else
              state_n       <=state_p;
            end if;
          end case;
        end process;
                      

 end rtl;    
      
          
