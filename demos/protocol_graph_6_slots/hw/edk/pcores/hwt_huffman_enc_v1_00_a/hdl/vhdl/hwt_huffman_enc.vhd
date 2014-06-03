library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

library ana_v1_00_a;
use ana_v1_00_a.anaPkg.all;

library hwt_huffman_enc_v1_00_a;
use hwt_huffman_enc_v1_00_a.Huffman_Pkg.all;

entity hwt_huffman_enc is
	port(
		-- OSIF FSL
		OSFSL_Clk       : in  std_logic; -- Synchronous clock
		OSFSL_Rst       : in  std_logic;
		OSFSL_S_Clk     : out std_logic; -- Slave asynchronous clock
		OSFSL_S_Read    : out std_logic; -- Read signal, requiring next available input to be read
		OSFSL_S_Data    : in  std_logic_vector(0 to 31); -- Input data
		OSFSL_S_Control : in  std_logic; -- Control Bit, indicating the input data are control word
		OSFSL_S_Exists  : in  std_logic; -- Data Exist Bit, indicating data exist in the input FSL bus
		OSFSL_M_Clk     : out std_logic; -- Master asynchronous clock
		OSFSL_M_Write   : out std_logic; -- Write signal, enabling writing to output FSL bus
		OSFSL_M_Data    : out std_logic_vector(0 to 31); -- Output data
		OSFSL_M_Control : out std_logic; -- Control Bit, indicating the output data are contol word
		OSFSL_M_Full    : in  std_logic; -- Full Bit, indicating output FSL bus is full

		-- FIFO Interface
		--	FIFO32_S_Clk : out std_logic;
		--	FIFO32_M_Clk : out std_logic;
		FIFO32_S_Data   : in  std_logic_vector(31 downto 0);
		FIFO32_M_Data   : out std_logic_vector(31 downto 0);
		FIFO32_S_Fill   : in  std_logic_vector(15 downto 0);
		FIFO32_M_Rem    : in  std_logic_vector(15 downto 0);
		FIFO32_S_Rd     : out std_logic;
		FIFO32_M_Wr     : out std_logic;

		-- HWT reset
		rst             : in  std_logic;

		switch_data_rdy : in  std_logic;
		switch_data     : in  std_logic_vector(dataWidth downto 0);
		thread_read_rdy : out std_logic;
		switch_read_rdy : in  std_logic;
		thread_data     : out std_logic_vector(dataWidth downto 0);
		thread_data_rdy : out std_logic
	);

end hwt_huffman_enc;

architecture implementation of hwt_huffman_enc is
	constant HW_TO_SW_GATEWAY_ADDR_GLOBAL : std_logic_vector(globalAddrWidth - 1 downto 0) := "0000";
	constant HW_TO_SW_GATEWAY_ADDR_LOCAL  : std_logic_vector(localAddrWidth - 1 downto 0)  := "00";

	constant HUFF_DEC_ADDR_GLOBAL : std_logic_vector(globalAddrWidth - 1 downto 0) := "0001";
	constant HUFF_DEC_ADDR_LOCAL  : std_logic_vector(localAddrWidth - 1 downto 0)  := "01";

	constant MY_SRC_IDP : std_logic_vector(idpWidth - 1 downto 0) := x"aabbccdd";
	constant MY_DST_IDP : std_logic_vector(idpWidth - 1 downto 0) := x"eeff5566";

	signal decoder_startOfPacket   : std_logic;
	signal decoder_endOfPacket     : std_logic;
	signal decoder_data            : std_logic_vector(dataWidth - 1 downto 0);
	signal decoder_dataValid       : std_logic;
	signal decoder_direction       : std_logic;
	signal decoder_priority        : std_logic_vector(priorityWidth - 1 downto 0);
	signal decoder_latencyCritical : std_logic;
	signal decoder_srcIdp          : std_logic_vector(idpWidth - 1 downto 0);
	signal decoder_dstIdp          : std_logic_vector(idpWidth - 1 downto 0);
	signal decoder_readEnable      : std_logic;

	signal enc_data : std_logic_vector(9 downto 0);

	signal encoder_startOfPacket   : std_logic;
	signal encoder_endOfPacket     : std_logic;
	signal encoder_data            : std_logic_vector(dataWidth - 1 downto 0);
	signal encoder_dataValid       : std_logic;
	signal encoder_direction       : std_logic;
	signal encoder_priority        : std_logic_vector(priorityWidth - 1 downto 0);
	signal encoder_latencyCritical : std_logic;
	signal encoder_srcIdp          : std_logic_vector(idpWidth - 1 downto 0);
	signal encoder_dstIdp          : std_logic_vector(idpWidth - 1 downto 0);
	signal encoder_readEnable      : std_logic;
	signal encoder_notreadEnable   : std_logic;
	signal encoder_globalAddress   : std_logic_vector(globalAddrWidth - 1 downto 0);
	signal encoder_localAddress    : std_logic_vector(localAddrWidth - 1 downto 0);
	signal osif_clk                : std_logic;

	signal pktDecoder_sof              : std_logic;
	signal pktDecoder_eof              : std_logic;
	signal pktDecoder_data             : std_logic_vector(7 downto 0);
	signal pktDecoder_src_rdy          : std_logic;
	signal pktDecoder_dst_rdy          : std_logic;
	signal pktDecoder_direction        : std_logic;
	signal pktDecoder_priority         : std_logic_vector(1 downto 0);
	signal pktDecoder_latency_critical : std_logic;
	signal pktDecoder_srcIdp           : std_logic_vector(31 downto 0);
	signal pktDecoder_dstIdp           : std_logic_vector(31 downto 0);
	signal pktDecoder_global_addr      : std_logic_vector(3 downto 0);
	signal pktDecoder_local_addr       : std_logic_vector(1 downto 0);

	signal pktEncoder_sof              : std_logic;
	signal pktEncoder_eof              : std_logic;
	signal pktEncoder_data             : std_logic_vector(7 downto 0);
	signal pktEncoder_src_rdy          : std_logic;
	signal pktEncoder_global_addr      : std_logic_vector(3 downto 0);
	signal pktEncoder_local_addr       : std_logic_vector(1 downto 0);
	signal pktEncoder_direction        : std_logic;
	signal pktEncoder_priority         : std_logic_vector(1 downto 0);
	signal pktEncoder_latency_critical : std_logic;
	signal pktEncoder_srcIdp           : std_logic_vector(31 downto 0);
	signal pktEncoder_dstIdp           : std_logic_vector(31 downto 0);
	signal pktEncoder_dst_rdy          : std_logic;

begin

	--	downstreamReadClock <= OSFSL_Clk;
	--	upstreamWriteClock <= OSFSL_Clk;

	encoder_notreadEnable <= not encoder_readEnable;

	-- The following signals determine the next functional block!
	-- hw2sw is switch 0 stream 0

	
	decoder_inst : packetDecoder
		port map(
			clk                    => osif_clk,
			reset                  => rst,

			-- Signals from the switch
			switch_data_rdy        => switch_data_rdy,
			switch_data            => switch_data,
			thread_read_rdy        => thread_read_rdy,

			-- Decoded values of the packet
			noc_rx_sof             => pktDecoder_sof, -- Indicates the start of a new packet
			noc_rx_eof             => pktDecoder_eof, -- Indicates the end of the packet
			noc_rx_data            => pktDecoder_data, -- The current data byte
			noc_rx_src_rdy         => pktDecoder_src_rdy, -- '1' if the data are valid, '0' else
			noc_rx_direction       => pktDecoder_direction, -- '1' for egress, '0' for ingress
			noc_rx_priority        => pktDecoder_priority, -- The priority of the packet
			noc_rx_latencyCritical => pktDecoder_latency_critical, -- '1' if this packet is latency critical
			noc_rx_srcIdp          => pktDecoder_srcIdp, -- The source IDP
			noc_rx_dstIdp          => pktDecoder_dstIdp, -- The destination IDP
			noc_rx_dst_rdy         => pktDecoder_dst_rdy -- Read enable for the functional block
		);

	encoder_inst : packetEncoder
		port map(
			clk                    => osif_clk,
			reset                  => rst,

			-- Signals to the switch
			switch_read_rdy        => switch_read_rdy,
			thread_data            => thread_data,
			thread_data_rdy        => thread_data_rdy,

			-- Encoded values of the packet
			noc_tx_sof             => pktEncoder_sof,
			noc_tx_eof             => pktEncoder_eof,
			noc_tx_data            => pktEncoder_data,
			noc_tx_src_rdy         => pktEncoder_src_rdy,
			noc_tx_globalAddress   => "0000", --"0000",--(others => '0'), --6 bits--(0:send it to hw/sw)		
			noc_tx_localAddress    => "00", --"01",-- (others  => '0'), --2 bits		
			noc_tx_direction       => pktDecoder_direction, --pktEncoder_direction,		
			noc_tx_priority        => pktDecoder_priority, --pktEncoder_priority,		
			noc_tx_latencyCritical => pktDecoder_latency_critical,
			noc_tx_srcIdp          => pktDecoder_srcIdp, --pktEncoder_srcIdp,	
			noc_tx_dstIdp          => pktDecoder_dstIdp, --pktEncoder_dstIdp,
			noc_tx_dst_rdy         => pktEncoder_dst_rdy --pktEncoder_dst_rdy
		);

	huffman_encoder : huffman_enc
		port map(
			OSFSL_Clk       => OSFSL_Clk,
			OSFSL_Rst       => OSFSL_Rst,
			OSFSL_S_Clk     => OSFSL_S_Clk,
			OSFSL_S_Read    => OSFSL_S_Read,
			OSFSL_S_Data    => OSFSL_S_Data,
			OSFSL_S_Control => OSFSL_S_Control,
			OSFSL_S_Exists  => OSFSL_S_Exists,
			OSFSL_M_Clk     => OSFSL_M_Clk,
			OSFSL_M_Write   => OSFSL_M_Write,
			OSFSL_M_Data    => OSFSL_M_Data,
			OSFSL_M_Control => OSFSL_M_Control,
			OSFSL_M_Full    => OSFSL_M_Full,
			FIFO32_S_Data   => FIFO32_S_Data,
			FIFO32_M_Data   => FIFO32_M_Data,
			FIFO32_S_Fill   => FIFO32_S_Fill,
			FIFO32_M_Rem    => FIFO32_M_Rem,
			FIFO32_S_Rd     => FIFO32_S_Rd,
			FIFO32_M_Wr     => FIFO32_M_Wr,
			rst             => rst,
			osif_clk        => osif_clk,
			DataInxD        => pktDecoder_data,
			ValidInxS       => pktDecoder_src_rdy,
			SofInxS         => pktDecoder_sof,
			EofInxS         => pktDecoder_eof,
			ReadyOutxS      => pktDecoder_dst_rdy, -- read_enable
			FullInxS        => not pktEncoder_dst_rdy, -- FIFO full
			DataOutxD       => enc_data,
			ValidOutxS      => pktEncoder_src_rdy -- write_enable
		);

	pktEncoder_sof  <= enc_data(9);
	pktEncoder_eof  <= enc_data(8);
	pktEncoder_data <= enc_data(7 downto 0);

end architecture;
