library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.hwt_aes_yyang_pkg.all;

entity atb_aes is
end entity;

architecture rtl of atb_aes is
  
  component aesCore is
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
  end component;
  
  signal clk:               std_logic;
  signal rst:               std_logic;
  signal startTransmitKey:  std_logic;
  signal globalLocalAddrIn: std_logic_vector(5 downto 0);
  signal key256In:          CIPHERKEY256_ARRAY;
  signal modeIn:            std_logic_vector(1 downto 0);
  signal keyInjected:       std_logic;
  
  --from pktDecoder:    
  signal noc_rx_sof:               std_logic;
  signal noc_rx_eof:               std_logic;
  signal noc_rx_data:              std_logic_vector(7 downto 0);
  signal noc_rx_src_rdy:           std_logic;
  signal noc_rx_direction:         std_logic;
  signal noc_rx_priority:          std_logic_vector(1 downto 0);
  signal noc_rx_latencyCritical:   std_logic;
  signal noc_rx_srcIdp:            std_logic_vector(31 downto 0);
  signal noc_rx_dstIdp:            std_logic_vector(31 downto 0);    
  signal noc_rx_dst_rdy:           std_logic;
  
  --towards pktEncoder:
  signal noc_tx_sof:               std_logic;                        -- Indicates the start of a new packet
	signal noc_tx_eof:               std_logic;                        -- Indicates the end of the packet
	signal noc_tx_data:              std_logic_vector(7 downto 0);     -- The current data byte
	signal noc_tx_src_rdy:           std_logic;                        -- '1' if the data are valid, '0' else
	signal noc_tx_globalAddress:     std_logic_vector(3 downto 0);     -- The global hardware address of the destination
	signal noc_tx_localAddress:      std_logic_vector(1 downto 0);     -- The local hardware address of the destination
	signal noc_tx_direction:         std_logic;                        -- '1' for egress, '0' for ingress
	signal noc_tx_priority:          std_logic_vector(1 downto 0);     -- The priority of the packet
	signal noc_tx_latencyCritical:   std_logic;                        -- '1' if this packet is latency critical
	signal noc_tx_srcIdp:            std_logic_vector(31 downto 0);    -- The source IDP
	signal noc_tx_dstIdp:            std_logic_vector(31 downto 0);    -- The destination IDP
	signal noc_tx_dst_rdy:           std_logic;                          -- Read enable for the applied data
	
  constant PKTNULL:          std_logic_vector(69 downto 0):="11"&X"F"&X"FFFFFFFF"&X"FFFFFFFF";
  constant PKTSOF:           std_logic_vector(69 downto 0):="10"&X"0"&X"55555555"&X"33333333";
  constant PKTMID:           std_logic_vector(69 downto 0):="00"&X"B"&X"55555555"&X"33333333";
  constant PKTEOF:           std_logic_vector(69 downto 0):="01"&X"F"&X"55555555"&X"33333333";
  
  signal pktDecoder_data:         std_logic_vector(7 downto 0);
  signal pktDecoder_info:         std_logic_vector(69 downto 0);
  signal pktDecoder_rdy:          std_logic;
  signal counter: integer range 0 to 80;
  constant clk_p: time:= 10 ns;

  begin
    
    noc_rx_sof              <=pktDecoder_info(69);
    noc_rx_eof              <=pktDecoder_info(68);
    noc_rx_data             <=pktDecoder_data;
    noc_rx_src_rdy          <=pktDecoder_rdy;
    noc_rx_direction        <=pktDecoder_info(67);
    noc_rx_priority         <=pktDecoder_info(66 downto 65);
    noc_rx_latencyCritical  <=pktDecoder_info(64);
    noc_rx_srcIdp           <=pktDecoder_info(63 downto 32);
    noc_rx_dstIdp           <=pktDecoder_info(31 downto 0); 
    
    ac:   aesCore port map(
      
    clk                     =>clk,
    rst                     =>rst,
    startTransmitKey        =>startTransmitKey,
    key256In                =>key256In,
    modeIn                  =>modeIn,
    globalLocalAddrIn       =>globalLocalAddrIn,
    keyInjected             =>keyInjected,  
    --from pktDecoder:    
    noc_rx_sof              =>noc_rx_sof,
    noc_rx_eof              =>noc_rx_eof,
    noc_rx_data             =>noc_rx_data,
    noc_rx_src_rdy          =>noc_rx_src_rdy,
    noc_rx_direction        =>noc_rx_direction,
    noc_rx_priority         =>noc_rx_priority,
    noc_rx_latencyCritical  =>noc_rx_latencyCritical,
    noc_rx_srcIdp           =>noc_rx_srcIdp,
    noc_rx_dstIdp           =>noc_rx_dstIdp,   
    noc_rx_dst_rdy          =>noc_rx_dst_rdy,
    
    --towards pktEncoder:
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
    
  
  noc_tx_dst_rdy<='1';

--process begin
--  globalLocalAddrIn<="000100";
--  wait for 100 ns;
--  globalLocalAddrIn<=globalLocalAddrIn+1;
--  wait for 100 ns;
--end process;

process(clk,rst)
  begin
    if rst='1'then
      globalLocalAddrIn<="000100";
    elsif rising_edge(clk)then
      globalLocalAddrIn<=globalLocalAddrIn+1;
    end if;
  end process;

  key_gen: process begin
    startTransmitKey<='0';
--    key256In(0)        <=X"00000000";
--    key256In(1)        <=X"00000001";
--    key256In(2)        <=X"00000000";
--    key256In(3)        <=X"00000003";
    key256In(0)        <=X"03020100";
    key256In(1)        <=X"07060504";
    key256In(2)        <=X"0b0a0908";
    key256In(3)        <=X"0f0e0d0c";    
    key256In(4)        <=X"13121110";
    key256In(5)        <=X"17161514";
    key256In(6)        <=X"1b1a1918";
    key256In(7)        <=X"1f1e1d1c";
	--change modeIn form mode 256 to 128, or 192. 
	--e.g. modeIn <= mode192;
    modeIn          <=mode256;
    wait for 200 ns;
    startTransmitKey<='1';
    wait for 20 ns;
    startTransmitKey<='0';
    wait for 4500 ns;
    startTransmitKey<='1';
    modeIn          <=mode256;
    wait for 20 ns;
    startTransmitKey<='0';
    wait;
  end process;
  
  produce_data: process (rst,clk)
  begin
    if rst='1' then
      pktDecoder_data<=X"00";
      counter<=0;
    elsif rising_edge(clk)then
      case noc_rx_dst_rdy is
      when '1'=>
        if pktDecoder_data=X"FF" then
          pktDecoder_data<=X"00";
          counter<=counter+1;
          if counter=2 then counter<=2; end if;
        else
          pktDecoder_data<=pktDecoder_data+X"11";
        end if;
      when others=>
        pktDecoder_data<=pktDecoder_data;
      end case;
    end if;
  end process;
  
  sofeofmid:  process (clk,rst)
  begin
    if rst='1' then
      pktDecoder_info<=PKTSOF;
        pktDecoder_rdy<='1';
    elsif rising_edge(clk)then
      if counter=0 and pktDecoder_data=X"00" then
          pktDecoder_rdy<='1';
        pktDecoder_info<=PKTSOF;
      elsif counter=2 and pktDecoder_data=X"EE" then
          pktDecoder_rdy<='1';
        pktDecoder_info<=PKTEOF;
      elsif counter=2 and pktDecoder_data=X"FF" then
          pktDecoder_rdy<='0';
        pktDecoder_info<=PKTEOF;
      else
        pktDecoder_info<=PKTMID;
      end if;
    end if;
  end process;
      
   
  clk_gen: process begin
     clk<='1';
     wait for clk_p/2;
     clk<='0';
     wait for clk_p/2;
  end process;

  rst_gen: process begin
     rst<='1';
     wait for 10*clk_p;
     rst<='0';
     wait;
  end process;
  
  
 end rtl; 

