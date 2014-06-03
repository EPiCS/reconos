-- Wrapper for a gigabit Ethernet interface on a xilinx virtex 6
--!
--! \file led.vhd
--!
--! Demo thread for blinking leds
--!
--! \author     Ariane Keller
--! \date       29.07.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
	
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library unisim;
use unisim.vcomponents.all;


entity eth is

  port (
        -- Ethernet Signals
  	TXP             : out std_logic;
        TXN             : out std_logic;
	RXP             : in  std_logic;
	RXN             : in  std_logic;

	-- SGMII-transceiver reference clock buffer input
	MGTCLK_P        : in  std_logic;
	MGTCLK_N        : in  std_logic;

	-- Asynchronous reset
	PRE_PHY_RESET   : in  std_logic;
	PHY_RESET       : out std_logic;

        -- Standard Signals
	clk             : in  std_logic;
	reset           : in  std_logic;
        
        --Network on Chip signals
        -- To Ethernet block (_i = active low)
        tx_ll_data        : in std_logic_vector(7 downto 0);
        tx_ll_sof_n       : in std_logic;
        tx_ll_eof_n       : in std_logic;
        tx_ll_src_rdy_n   : in std_logic;
        tx_ll_dst_rdy_n   : out std_logic;

	-- From Ethernet block
        rx_ll_data        : out std_logic_vector(7 downto 0);
        rx_ll_sof_n       : out std_logic;
        rx_ll_eof_n       : out std_logic;
        rx_ll_src_rdy_n   : out std_logic;
        rx_ll_dst_rdy_n   : in std_logic

    	
    );
end eth;

architecture Behavioral of  eth is

-----------------start component declaration------------------------------  
    -- Component declaration for the LocalLink-level EMAC wrapper
    component v6_emac_v1_4_locallink is
    port(
        -- 125MHz clock output from transceiver
        CLK125_OUT               : out std_logic;
        -- 125MHz clock input from BUFG
        CLK125                   : in  std_logic;

        -- LocalLink receiver interface
        RX_LL_CLOCK              : in  std_logic;
        RX_LL_RESET              : in  std_logic;
        RX_LL_DATA               : out std_logic_vector(7 downto 0);
        RX_LL_SOF_N              : out std_logic;
        RX_LL_EOF_N              : out std_logic;
        RX_LL_SRC_RDY_N          : out std_logic;
        RX_LL_DST_RDY_N          : in  std_logic;
        RX_LL_FIFO_STATUS        : out std_logic_vector(3 downto 0);

        -- LocalLink transmitter interface
        TX_LL_CLOCK              : in  std_logic;
        TX_LL_RESET              : in  std_logic;
        TX_LL_DATA               : in  std_logic_vector(7 downto 0);
        TX_LL_SOF_N              : in  std_logic;
        TX_LL_EOF_N              : in  std_logic;
        TX_LL_SRC_RDY_N          : in  std_logic;
        TX_LL_DST_RDY_N          : out std_logic;

        -- Client receiver interface
        EMACCLIENTRXDVLD         : out std_logic;
        EMACCLIENTRXFRAMEDROP    : out std_logic;
        EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
        EMACCLIENTRXSTATSVLD     : out std_logic;
        EMACCLIENTRXSTATSBYTEVLD : out std_logic;

        -- Client Transmitter Interface
        CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
        EMACCLIENTTXSTATS        : out std_logic;
        EMACCLIENTTXSTATSVLD     : out std_logic;
        EMACCLIENTTXSTATSBYTEVLD : out std_logic;

        -- MAC control interface
        CLIENTEMACPAUSEREQ       : in  std_logic;
        CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

        -- EMAC-transceiver link status
        EMACCLIENTSYNCACQSTATUS  : out std_logic;
        EMACANINTERRUPT          : out std_logic;

        -- SGMII interface
        TXP                      : out std_logic;
        TXN                      : out std_logic;
        RXP                      : in  std_logic;
        RXN                      : in  std_logic;
        PHYAD                    : in  std_logic_vector(4 downto 0);
        RESETDONE                : out std_logic;

        -- SGMII transceiver clock buffer input
        CLK_DS                   : in  std_logic;

        -- Asynchronous reset
        RESET                    : in  std_logic
    );
    end component;

   

-----------------end component declaration------------------------------  

-----------------signal declaration ------------------------------------
        -- setting up the Ethernet interface
	-- Global asynchronous reset
        signal reset_i              : std_logic;
        -- Synchronous reset registers in the LocalLink clock domain
        signal ll_pre_reset_i       : std_logic_vector(5 downto 0);
        signal ll_reset_i           : std_logic;

        attribute async_reg         : string;
        attribute async_reg of ll_pre_reset_i : signal is "true";

        -- Reset signal from the transceiver
        signal resetdone_i          : std_logic;
        signal resetdone_r          : std_logic;
    
        attribute async_reg of resetdone_r : signal is "true";

        -- LocalLink interface clocking signal (required for reset synchronisation)
        signal ll_clk_i             : std_logic;
 
        -- Transceiver output clock (REFCLKOUT at 125MHz)
        signal clk125_o             : std_logic;

        -- 125MHz clock input to wrappers
        signal clk125               : std_logic;

        attribute keep              : boolean;
        attribute keep of clk125    : signal is true;

        -- Input 125MHz differential clock for transceiver
        signal clk_ds               : std_logic;


        -- State machines
	type os_state_t is (STATE_INIT, STATE_WAIT, STATE_NOTIFY);
	signal os_sync_state 	    : os_state_t;

	type testing_state_t is (T_STATE_INIT, T_STATE_RCV);
	signal testing_state 	    : testing_state_t;
	signal testing_state_next   : testing_state_t;

	signal rx_packet_count 	    : natural range 0 to 1023;
	signal rx_packet_count_next : natural range 0 to 1023;

        signal rx_ll_src_rdy_int_n  : std_logic;
        signal rx_ll_sof_int_n      : std_logic;
    
  
--end signal declaration

begin
        --Setup Ethernet block
	reset_i <= PRE_PHY_RESET;
	PHY_RESET <= not reset_i;

 	-- Generate the clock input to the transceiver
        -- (clk_ds can be shared between multiple EMAC instances, including
        --  multiple instantiations of the EMAC wrappers)
	clkingen : IBUFDS_GTXE1 port map (
            I     => MGTCLK_P,
            IB    => MGTCLK_N,
            CEB   => '0',
            O     => clk_ds,
            ODIV2 => open
        );

	-- The 125MHz clock from the transceiver is routed through a BUFG and
        -- input to the MAC wrappers
        -- (clk125 can be shared between multiple EMAC instances, including
        --  multiple instantiations of the EMAC wrappers)
        bufg_clk125 : BUFG port map (
            I => clk125_o,
            O => clk125
        );

        -- Clock the LocalLink interface with the globally-buffered 125MHz
        -- clock from the transceiver
        ll_clk_i <= clk125;

        --Synchronize resetdone_i from the GT in the transmitter clock domain
        gen_resetdone_r : process(ll_clk_i, reset_i)
        begin
            if (reset_i = '1') then
                resetdone_r <= '0';
            elsif ll_clk_i'event and ll_clk_i = '1' then
                resetdone_r <= resetdone_i;
            end if;
        end process gen_resetdone_r;

        -- Create synchronous reset in the transmitter clock domain
        gen_ll_reset : process (ll_clk_i, reset_i)
        begin
            if reset_i = '1' then
                ll_pre_reset_i <= (others => '1');
                ll_reset_i     <= '1';
            elsif ll_clk_i'event and ll_clk_i = '1' then
                if resetdone_r = '1' then
                    ll_pre_reset_i(0)          <= '0';
                    ll_pre_reset_i(5 downto 1) <= ll_pre_reset_i(4 downto 0);
                    ll_reset_i                 <= ll_pre_reset_i(5);
                end if;
            end if;
        end process gen_ll_reset;

        --Instantiate Ethernet 
        v6_emac_v1_4_locallink_inst : v6_emac_v1_4_locallink 
        port map (
            -- 125MHz clock output from transceiver
            CLK125_OUT               => clk125_o,
            -- 125MHz clock input from BUFG
            CLK125                   => clk125,

            -- LocalLink receiver interface
            RX_LL_CLOCK              => clk, --shouldn't this be clk125?
            RX_LL_RESET              => ll_reset_i,
            RX_LL_DATA               => rx_ll_data,
            RX_LL_SOF_N              => rx_ll_sof_int_n,-- rx_ll_sof_n_i,
            RX_LL_EOF_N              => rx_ll_eof_n,
            RX_LL_SRC_RDY_N          => rx_ll_src_rdy_int_n, --rx_ll_src_rdy_n_i,
            RX_LL_DST_RDY_N          => rx_ll_dst_rdy_n,
            RX_LL_FIFO_STATUS        => open,

            -- Client receiver signals
            EMACCLIENTRXDVLD         => open, 
            EMACCLIENTRXFRAMEDROP    => open,
            EMACCLIENTRXSTATS        => open,
            EMACCLIENTRXSTATSVLD     => open,
            EMACCLIENTRXSTATSBYTEVLD => open,

            -- LocalLink transmitter interface
            TX_LL_CLOCK              => clk, --shouldn't this be clk125?
            TX_LL_RESET              => ll_reset_i,
            TX_LL_DATA               => tx_ll_data,
            TX_LL_SOF_N              => tx_ll_sof_n,
            TX_LL_EOF_N              => tx_ll_eof_n,
            TX_LL_SRC_RDY_N          => tx_ll_src_rdy_n,
            TX_LL_DST_RDY_N          => tx_ll_dst_rdy_n,

            -- Client transmitter signals
            CLIENTEMACTXIFGDELAY     => (others => '0'),
            EMACCLIENTTXSTATS        => open,
            EMACCLIENTTXSTATSVLD     => open,
            EMACCLIENTTXSTATSBYTEVLD => open,

            -- MAC control interface
            CLIENTEMACPAUSEREQ       => '0',
            CLIENTEMACPAUSEVAL       => (others => '0'),

            -- EMAC-transceiver link status
            EMACCLIENTSYNCACQSTATUS  => open,
            EMACANINTERRUPT          => open,

            -- SGMII interface
            TXP                      => TXP,
            TXN                      => TXN,
            RXP                      => RXP,
            RXN                      => RXN,
            PHYAD                    => (others => '0'),
            RESETDONE                => resetdone_i,

            -- SGMII transceiver reference clock buffer input
            CLK_DS                   => clk_ds,

            -- Asynchronous reset
            RESET                    => reset_i
        );

        rx_ll_src_rdy_n <= rx_ll_src_rdy_int_n;
        rx_ll_sof_n     <= rx_ll_sof_int_n;

   
        --count all packets that are received
	test_counting : process(rx_ll_sof_int_n, rx_ll_src_rdy_int_n, rx_packet_count, testing_state)
	begin
	    rx_packet_count_next <= rx_packet_count;
    	    testing_state_next <= testing_state;
	    case testing_state is
        	when T_STATE_INIT =>
		    rx_packet_count_next <= 0;
		    testing_state_next <= T_STATE_RCV;
		when T_STATE_RCV =>
		    if rx_ll_src_rdy_int_n = '0' and rx_ll_sof_int_n = '0' then
			rx_packet_count_next <= rx_packet_count + 1;
		    end if;
		when others =>
		    testing_state_next <= T_STATE_INIT;
	    end case;
	end process;


	--creates flipflops
	memzing: process(clk, reset)
	begin
	    if reset = '1' then
	        rx_packet_count <= 0;
	        testing_state <= T_STATE_INIT;
	    elsif rising_edge(clk) then
	        rx_packet_count <= rx_packet_count_next;
	        testing_state <= testing_state_next;
	    end if;
	end process;


--        -- OS synchronization state machine
--        state_proc : process(clk, reset)
--	variable done 			: boolean;
--        variable success 		: boolean;
--        begin
--            if reset = '1' then
--    	    reconos_reset_with_signature(o_osif, i_osif, X"ABCDEF00");
--    	    os_sync_state      <= STATE_INIT;
--    	    done        := false;
--  	    success     := false;
--            elsif rising_edge(clk) then
--    	        reconos_begin(o_osif, i_osif);
--                if reconos_ready(i_osif) then
--                    case os_sync_state is
--
--		    when STATE_INIT =>
--		        os_sync_state <= STATE_WAIT;
--
--                    when STATE_WAIT =>
--	                count := count + 1;
--           		if count > 100000000 then
--			    count := 0;
--			    os_sync_state <= STATE_NOTIFY;
--			end if;
--
--                    when STATE_NOTIFY =>
--        		reconos_mbox_put(done, success,o_osif, i_osif, C_MBOX_HANDLE_HW_SW, padding & std_logic_vector(rx_packet_len));
--			if done then
--			    os_sync_state <= STATE_WAIT;  	
--            		end if;

--		    when others =>
--			os_sync_state <= STATE_INIT;
--        	    end case;
--                end if;
--            end if;
--        end process;
end Behavioral;


