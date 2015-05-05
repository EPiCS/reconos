library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

entity packetDecoder is
	port (
		clk 			: in  std_logic;
		reset 			: in  std_logic;
		
		-- Signals from the switch
		switch_data_rdy		: in  std_logic;
		switch_data		: in  std_logic_vector(dataWidth downto 0);
		thread_read_rdy	 	: out std_logic;
		noc_rx_sof 		: out std_logic;
		noc_rx_eof 		: out std_logic; -- Indicates the end of the packet
		noc_rx_data		: out std_logic_vector(dataWidth-1 downto 0); -- The current data byte
		noc_rx_src_rdy		: out std_logic; -- '1' if the data are valid, '0' else
		noc_rx_direction	: out std_logic; -- '1' for egress, '0' for ingress
		noc_rx_priority		: out std_logic_vector(priorityWidth-1 downto 0); -- The priority of the packet
		noc_rx_latencyCritical 	: out std_logic; -- '1' if this packet is latency critical
		noc_rx_srcIdp		: out std_logic_vector(idpWidth-1 downto 0); -- The source IDP
		noc_rx_dstIdp		: out std_logic_vector(idpWidth-1 downto 0); -- The destination IDP
		noc_rx_dst_rdy 		: in std_logic -- Read enable for the functional block
);
end entity packetDecoder;

architecture rtl of packetDecoder is
	
	type state_t is ( STATE_DECODE_HEADER_1,
					STATE_DECODE_HEADER_2,
					STATE_DECODE_SRC_IDP,
					STATE_DECODE_DST_IDP,
					STATE_START_PACKET_TRANSFER,
					STATE_PACKET_TRANSFER );
	
	signal state_n, state_p				: state_t;
	signal direction_n, direction_p 		: std_logic;
	signal priority_n, priority_p 			: std_logic_vector(priorityWidth-1 downto 0);
	signal latencyCritical_n, latencyCritical_p	: std_logic;
	signal srcIdp_n, srcIdp_p			: std_logic_vector(idpWidth-1 downto 0);
	signal dstIdp_n, dstIdp_p			: std_logic_vector(idpWidth-1 downto 0);
	signal idpByteCounter_n, idpByteCounter_p	: idpByteCounter;
	
	signal thread_read_rdy_local	: std_logic;
	
begin

	-- output
	noc_rx_srcIdp 		<= srcIdp_p;
	noc_rx_dstIdp 		<= dstIdp_p;
	noc_rx_latencyCritical 	<= latencyCritical_p;
	noc_rx_priority 	<= priority_p;
	noc_rx_data		<= switch_data(dataWidth-1 downto 0);
	noc_rx_sof 		<= '1' when state_p = STATE_START_PACKET_TRANSFER else '0';
	noc_rx_eof 		<= switch_data(dataWidth);
	thread_read_rdy_local	<= noc_rx_dst_rdy when state_p = STATE_START_PACKET_TRANSFER or state_p = STATE_PACKET_TRANSFER else '1';
	--noc_rx_src_rdy 		<= thread_read_rdy_local when state_p = STATE_START_PACKET_TRANSFER or state_p = STATE_PACKET_TRANSFER else '0';
	noc_rx_src_rdy 		<= switch_data_rdy when state_p = STATE_START_PACKET_TRANSFER or state_p = STATE_PACKET_TRANSFER else '0';
	
	thread_read_rdy 	<= thread_read_rdy_local;
	noc_rx_direction 	<= direction_p;
	
	-- priority
	priority_n 		<= switch_data(dataWidth-1 downto dataWidth-priorityWidth) when state_p = STATE_DECODE_HEADER_1
				  else priority_p;
	
	--direction
	direction_n 		<= switch_data(directionBit) when state_p = STATE_DECODE_HEADER_2
				   else direction_p;

	-- latency critical
	latencyCritical_n 	<= switch_data(latencyCriticalBit) when state_p = STATE_DECODE_HEADER_2
						 else latencyCritical_p;

	-- srcIdp
	nomem_srcIdp : process(state_p, srcIdp_p, switch_data, idpByteCounter_p)
	begin
		srcIdp_n <= srcIdp_p;
		if state_p = STATE_DECODE_SRC_IDP then
			srcIdp_n((to_integer(idpByteCounter_p)*dataWidth) + (dataWidth-1) downto to_integer(idpByteCounter_p)*dataWidth) <= switch_data(dataWidth-1 downto 0);
		end if;
	end process nomem_srcIdp;
	
	nomem_dstIdp : process(state_p, dstIdp_p, switch_data, idpByteCounter_p)
	begin
		dstIdp_n <= dstIdp_p;
		if state_p = STATE_DECODE_DST_IDP then
			dstIdp_n((to_integer(idpByteCounter_p)*dataWidth) + (dataWidth-1) downto to_integer(idpByteCounter_p)*dataWidth) <= switch_data(dataWidth-1 downto 0);
		end if;
	end process nomem_dstIdp;
	
	nomem_idpByteCounter : process(state_p, idpByteCounter_p, switch_data_rdy)
	begin
		idpByteCounter_n <= idpByteCounterMax;
		if state_p = STATE_DECODE_SRC_IDP or state_p = STATE_DECODE_DST_IDP then
			if switch_data_rdy = '1' and idpByteCounter_p /= 0 then
				idpByteCounter_n <= idpByteCounter_p - 1;
			end if;
		end if;
	end process nomem_idpByteCounter;

	nomem_nextState : process(state_p, switch_data_rdy, idpByteCounter_p, noc_rx_dst_rdy, switch_data(dataWidth))
	begin
		-- Default: keep current state
		state_n <= state_p;
		
		if switch_data_rdy = '1' then
			case state_p is
				when STATE_DECODE_HEADER_1 =>
					state_n <= STATE_DECODE_HEADER_2;
					
				when STATE_DECODE_HEADER_2 =>
						state_n <= STATE_DECODE_SRC_IDP;
				
				when STATE_DECODE_SRC_IDP =>
					if idpByteCounter_p = 0 then
						state_n <= STATE_DECODE_DST_IDP;
					end if;
				
				when STATE_DECODE_DST_IDP =>
					if idpByteCounter_p = 0 then
						state_n <= STATE_START_PACKET_TRANSFER;
					end if;
					
				when STATE_START_PACKET_TRANSFER =>
					if noc_rx_dst_rdy = '1' then
						state_n <= STATE_PACKET_TRANSFER;
					end if;
					
				when STATE_PACKET_TRANSFER =>
					if switch_data(dataWidth) = '1' then
						state_n <= STATE_DECODE_HEADER_1;
					end if;
			end case;
		end if;
		
	end process nomem_nextState;

	mem_stateTransition : process(clk, reset)
	begin
		if reset = '1' then
			state_p 	<= STATE_DECODE_HEADER_1;
			direction_p 	<= '0';
			priority_p 	<= (others => '0');
			idpByteCounter_p <= idpByteCounterMax;
			srcIdp_p 	<= (others => '0');
			dstIdp_p 	<= (others => '0');
			latencyCritical_p <= '0';
		elsif rising_edge(clk) then
			state_p 	<= state_n;
			direction_p 	<= direction_n;
			priority_p 	<= priority_n;
			idpByteCounter_p <= idpByteCounter_n;
			srcIdp_p 	<= srcIdp_n;
			dstIdp_p 	<= dstIdp_n;
			latencyCritical_p <= latencyCritical_n;
		end if;
	end process mem_stateTransition;

end architecture rtl;
