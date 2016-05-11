----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:45:56 02/25/2015 
-- Design Name: 
-- Module Name:    ringbus_tap - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ringbus_pck.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- Ringbus Tap implementation infos:
-- We use a multiplexer based implementation here. It seems to be the most area and time efficient one.
-- Measurements with bus width of 32:
-- MUX, integer coded: 96 slices, 1.4 ns combinational delay 
-- MUX, onehot coded : 110 slices, >2 ns combinational delay 
-- Tristate, int. coded: 101 slices, >2ns combinational delay 
-- Tristate, one-hot coded: 105 slices, >2ns combinational delay 

-- Signal orientation
--
--    a b
--    | |
--    v ^
--   +---+
--f<-|   |<-c
--   |TAP|
--e->|   |->d
--   +---+
--     |
--     v
--   ctrl
--    
    
entity ringbus_tap is
    generic (
        G_ADDRESS: unsigned(RB_ADDR_WIDTH-1 downto 0) := to_unsigned(7, RB_ADDR_WIDTH);
        G_TAP_CNT : integer := 8
    );
    port (
    -- FIFO32 Interface to a FIFO
        FIFO32_S_Data : in  std_logic_vector(31 downto 0);
        FIFO32_S_Fill : in  std_logic_vector(15 downto 0);
        FIFO32_S_Rd   : out std_logic;
        
        FIFO32_M_Data : out std_logic_vector(31 downto 0);
        FIFO32_M_Rem  : in  std_logic_vector(15 downto 0);
        FIFO32_M_Wr   : out std_logic;
        
        -- Ring Interface
        c_in, cc_in : in  ring_t ;
        c_out, cc_out : out ring_t := RING_IDLE;
        
        -- Control Interface
        ctrl_out : out ctrl_master_t;
        ctrl_in  : in  ctrl_slave_t;
        
        -- Misc
        clk: in std_logic;
        rst: in std_logic;
        
        -- Debug signals to ILA
        ila_signals : out std_logic_vector(130 downto 0)
    );
end ringbus_tap;

architecture Behavioral of ringbus_tap is
    constant C_PACKET_CMD_READ  : unsigned(7 downto 0) := X"00"; 
    constant C_PACKET_CMD_WRITE : unsigned(7 downto 0) := X"80";
    
type state_t is (IDLE,
FIFO32_ARBITE, FIFO32_SEND, FIFO32_SEND_UPDATE_COUNTERS,
FIFO32_WAIT_READ_DATA, FIFO32_READ_DATA, FIFO32_DEARBITE_MASTER,FIFO32_DEARBITE_SLAVE);
type mode_t is (MASTER, SLAVE);
    
    signal state : state_t;
    signal mode  : mode_t;
    signal default_dst: unsigned(RB_ADDR_WIDTH-1 downto 0):= (others => '0');
    signal burst_size : unsigned(RB_TRANS_SIZE_WIDTH-1 downto 0);
     
    signal packet_write_size: unsigned(21 downto 0);
    signal packet_read_size: unsigned(21 downto 0);
    
    signal packet_cmd : unsigned(7 downto 0);
    signal return_address: unsigned(RB_ADDR_WIDTH-1 downto 0); 

    signal FIFO32_M_Data_debug : std_logic_vector(31 downto 0);
    signal FIFO32_M_Wr_debug   : std_logic;
    signal FIFO32_S_Rd_debug   : std_logic;
    
    signal bus_error : std_logic;
    
function minimum (trans_size: unsigned(RB_TRANS_SIZE_WIDTH-1 downto 0);
fifo32_fill:unsigned(15 downto 0))
return unsigned is
-- declarations
begin
    if to_integer(trans_size) < to_integer(fifo32_fill) then
        return trans_size;
    else
        return fifo32_fill(RB_TRANS_SIZE_WIDTH-1 downto 0);
    end if;
end minimum;

begin

    FIFO32_M_Data <= FIFO32_M_Data_debug;
    FIFO32_M_Wr   <= FIFO32_M_Wr_debug;
    FIFO32_S_Rd   <= FIFO32_S_Rd_debug;
    
--ila_proc: process(state, FIFO32_S_Fill, FIFO32_M_Rem, FIFO32_M_Data_debug, FIFO32_M_Wr_debug, FIFO32_S_Data, FIFO32_S_Rd_debug, c_in, cc_in) is
--    begin
--         case(state) is
--             when IDLE                        => ila_signals(3 downto 0) <= X"0";
--             when FIFO32_ARBITE               => ila_signals(3 downto 0) <= X"1";
--             when FIFO32_SEND                 => ila_signals(3 downto 0) <= X"2";
--             when FIFO32_SEND_UPDATE_COUNTERS => ila_signals(3 downto 0) <= X"3";
--             when FIFO32_WAIT_READ_DATA       => ila_signals(3 downto 0) <= X"4";
--             when FIFO32_READ_DATA            => ila_signals(3 downto 0) <= X"5";
--             when FIFO32_DEARBITE_MASTER      => ila_signals(3 downto 0) <= X"6";
--             when FIFO32_DEARBITE_SLAVE       => ila_signals(3 downto 0) <= X"7";
--         end case;
        
        ila_signals(3 downto 0)   <= X"0" when state = IDLE else
                                     X"1" when state = FIFO32_ARBITE else 
                                     X"2" when state = FIFO32_SEND   else
                                     X"3" when state = FIFO32_SEND_UPDATE_COUNTERS else
                                     X"4" when state = FIFO32_WAIT_READ_DATA else
                                     X"5" when state = FIFO32_READ_DATA else
                                     X"6" when state = FIFO32_DEARBITE_MASTER else
                                     X"7" when state = FIFO32_DEARBITE_SLAVE else
                                     X"8";
                                     
        --ila_signals(7 downto  4)  <= FIFO32_S_Fill(3 downto 0);
        --ila_signals(11 downto 8)  <= FIFO32_M_Rem (3 downto 0);
        ila_signals(11 downto  4)  <= FIFO32_S_Fill(7 downto 0);
        
        
        ila_signals(43 downto 12) <= FIFO32_M_Data_debug;
        ila_signals(44)           <= FIFO32_M_Wr_debug;
        ila_signals(76 downto 45) <= FIFO32_S_Data;
        ila_signals(77)           <= FIFO32_S_Rd_debug;
        
        --ila_signals(85 downto 78) <= std_logic_vector(c_in.data(31 downto 24)); -- only upper 8 bit of data
        ila_signals(85 downto 78) <= FIFO32_M_Rem (7 downto 0);
        
        ila_signals(90 downto 86) <= std_logic_vector(c_in.dst);
        ila_signals(95 downto 91) <= std_logic_vector(c_in.src);
        
        ila_signals(103 downto 96)  <= std_logic_vector(cc_in.data(31 downto 24)); -- only upper 8 bit of data
        ila_signals(108 downto 104) <= std_logic_vector(cc_in.dst);
        ila_signals(113 downto 109) <= std_logic_vector(cc_in.src);
        ila_signals(121 downto 114) <= std_logic_vector(packet_read_size(7 downto 0));
        ila_signals(129 downto 122) <= std_logic_vector(packet_write_size(7 downto 0));
        ila_signals(130)            <= bus_error;
--end process;

-- Send and receive logic
-- Handles protocol needed for successful sending to the ring bus
-- RECEIVE logic
-- Monitors both rings for our own address. If address matches, it writes the data into 
-- the receive FIFO and removes the data from the bus by forwarding an IDLE symbol.
-- If data on both rings arrives simultaneously, both messages are removed from the bus, but 
-- only that one from the counter-clockwise ring is written into the receive FIFO.
-- The arbiter should avoid multiple concurrent transmission to a single address.
send_regs_proc: process(clk, rst, c_in, cc_in) is
        variable temp_ring : ring_t;
    begin
        if rst='1' then
            state <= IDLE;
            mode <= MASTER;
            
            c_out <= RING_IDLE;
            cc_out<= RING_IDLE;
            
            default_dst <= (others => '0');
            return_address <= (others => '1');
            packet_cmd <= C_PACKET_CMD_READ;
            packet_read_size <= to_unsigned(0, packet_read_size'length);
            packet_write_size <= to_unsigned(0, packet_write_size'length);
            burst_size <= to_unsigned(0, burst_size'length);
            ctrl_out.dst <= RING_ADDRESS_IDLE;
            ctrl_out.req <= '0';
            
            bus_error <= '0';
        elsif clk'event and clk= '1' then
        
            c_out <= c_in;        -- default is to forward data unaltered
            cc_out <= cc_in;
            temp_ring := RING_IDLE;
            
            bus_error<='0';
            
            -- SEND state machine
            case state is
                when IDLE =>
                    --DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    
                    ctrl_out.dst <= RING_ADDRESS_IDLE;
                    ctrl_out.req <= '0';
                    
                    -- Receiving data from the ring has priority over FIFO32 interface
                    if    ctrl_in.incoming = '1' then
                        state <= FIFO32_WAIT_READ_DATA;
                        mode  <= SLAVE;
                    elsif unsigned(FIFO32_S_Fill) > 0 then
                        state <= FIFO32_ARBITE;
                        mode <= MASTER;
                        -- begin of FIFO32 packet
                        packet_cmd  <= unsigned(FIFO32_S_Data(31 downto 24));
                        if unsigned(FIFO32_S_Data(31 downto 24)) = C_PACKET_CMD_WRITE then
                            packet_write_size <= unsigned(FIFO32_S_Data(23 downto 2)) + 2; -- +2 for the header
                            packet_read_size  <= to_unsigned(0, packet_read_size'length);
                        else
                            packet_write_size <= to_unsigned(2, packet_read_size'length);
                            packet_read_size  <= unsigned(FIFO32_S_Data(23 downto 2));
                        end if;
                    end if;
                
                when FIFO32_ARBITE =>
                    --DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    
                    -- request transmission from arbiter
                    -- arbiter returns maximum transaction size
                    ctrl_out.dst <= default_dst;
                    ctrl_out.req <= '1';
                    if ctrl_in.max_trans > 0 then
                        state <= FIFO32_SEND_UPDATE_COUNTERS;
                    end if;
                
                when FIFO32_SEND_UPDATE_COUNTERS =>
                	--DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    
                    -- There can be up to G_TAP_CNT-1 word on flight in the bus. Additionally, 
                    -- max_trans is delayed by one clock cycle and potentially too high. Therefore
                    -- we always have to let at least G_TAPCOUNT words unused in the receiving buffer
                    if ( ctrl_in.max_trans > G_TAP_CNT ) and ( unsigned(FIFO32_S_Fill) > 0 ) then
                        burst_size <= minimum(ctrl_in.max_trans-G_TAP_CNT, unsigned(FIFO32_S_Fill));
                        state <= FIFO32_SEND;
                    end if;
                
                when FIFO32_SEND =>  -- expects we burst_size > 0
                    --DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    if (ctrl_in.direction = '1' and c_in  = RING_IDLE) or
                    (ctrl_in.direction = '0' and cc_in = RING_IDLE)
                    then
                        temp_ring.data:= unsigned(FIFO32_S_Data);
                        if mode = MASTER then
                            temp_ring.dst := default_dst;
                        elsif mode = SLAVE then
                            temp_ring.dst := return_address;
                        end if;
                        temp_ring.src := G_ADDRESS;
                        temp_ring.ctrl:= RB_CTRL_CMD_DATA;
                        if ctrl_in.direction = '1' then
                            c_out<= temp_ring;
                        else
                            cc_out <= temp_ring;
                        end if;
                        
                        burst_size <= burst_size -1;
                        packet_write_size<= packet_write_size-1;
                        
                        if burst_size = 1 then
                            state <= FIFO32_SEND_UPDATE_COUNTERS;
                        end if;
                        if packet_write_size = 1 then
                            if mode = MASTER then
                                if packet_cmd = C_PACKET_CMD_READ then
                                    state <= FIFO32_READ_DATA;
                                else
                                    state <= FIFO32_DEARBITE_MASTER;
                                end if;
                            elsif mode = SLAVE then
                                state <= FIFO32_DEARBITE_SLAVE;
                            end if;
                        end if;
                    end if;
                
                when FIFO32_DEARBITE_MASTER =>
                    --DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    
                    ctrl_out.dst <= default_dst; -- keep address valid for arbiter!
                    ctrl_out.req <= '0';
                    if ctrl_in.max_trans = 0 then
                        state <= IDLE;
                    end if;
                
                when FIFO32_DEARBITE_SLAVE =>
                    --DEBUG
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                        bus_error<='1';
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                        bus_error<='1';
                    end if;
                    --DEBUG
                    
                    ctrl_out.req <= '0'; -- show arbiter we are done with receiving
                    if ctrl_in.incoming = '0' then
                        state <= IDLE;
                    end if;
                
                when FIFO32_WAIT_READ_DATA =>
                    --State is only entered when slave
                    --wait for first word , read it and extract important information
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                    end if;
                    ctrl_out.req <= '1'; -- show arbiter we are ready
                    if temp_ring.dst = G_ADDRESS then
                        packet_cmd <= temp_ring.data(31 downto 24);
                        if temp_ring.data(31 downto 24) = C_PACKET_CMD_WRITE then
                            packet_read_size  <= temp_ring.data(23 downto 2) + 1; -- +2 for the header, but we just read the first, so +1
                            packet_write_size <= to_unsigned(0, packet_write_size'length);
                        else
                            packet_read_size  <= to_unsigned(1, packet_read_size'length); -- we just read first word, wait for second
                            packet_write_size <= temp_ring.data(23 downto 2);
                        end if;
                        return_address <= temp_ring.src;
                        burst_size <= ctrl_in.max_trans;
                        state <= FIFO32_READ_DATA;
                    end if;
                
                when FIFO32_READ_DATA =>
                    --Receive remaining words of packet
                    if c_in.dst = G_ADDRESS then
                        c_out  <= RING_IDLE;    -- take data from bus
                        temp_ring := c_in;
                    end if;
                    if cc_in.dst = G_ADDRESS then
                        cc_out <= RING_IDLE;    -- take data from bus
                        temp_ring := cc_in;
                    end if;
                    
                    if temp_ring.dst = G_ADDRESS then
                        packet_read_size <= packet_read_size -1 ;
                        if packet_read_size = 1  and mode = MASTER then
                            state <= FIFO32_DEARBITE_MASTER;
                        elsif packet_read_size = 1  and mode = SLAVE then
                            if packet_cmd = C_PACKET_CMD_READ then
                                state <= FIFO32_SEND_UPDATE_COUNTERS;
                            elsif packet_cmd = C_PACKET_CMD_WRITE then
                                state <= FIFO32_DEARBITE_SLAVE;
                            end if;
                        end if;
                    end if;
            
            end case;
        end if;
end process;

send_outs_proc: process(clk, rst, state, ctrl_in, c_in, cc_in, fifo32_m_rem, fifo32_s_fill) is
    begin
        if rst='1' then
            FIFO32_S_Rd_debug <= '0';
            
            FIFO32_M_Wr_debug <= '0';
            FIFO32_M_Data_debug <= (others => '0');
            ctrl_out.free_words<= (others => '0');
        else
            FIFO32_S_Rd_debug <= '0';
            FIFO32_M_Wr_debug <= '0';
            FIFO32_M_Data_debug <= (others => '0');
            -- Default: report free words in receive fifo
            if unsigned(FIFO32_M_Rem) >= 31 then
                ctrl_out.free_words <= (others => '1');
            else
                ctrl_out.free_words <= unsigned(FIFO32_M_Rem(RB_TRANS_SIZE_WIDTH-1 downto 0));
            end if;
            
            case state is
                when IDLE =>
                
                when FIFO32_ARBITE =>
                --ctrl_out.free_words <= (others => '0');
                when FIFO32_SEND =>
                --ctrl_out.free_words <= (others => '0');
                if (ctrl_in.direction = '1' and c_in  = RING_IDLE) or
                (ctrl_in.direction = '0' and cc_in = RING_IDLE)
                then
                    FIFO32_S_Rd_debug <= '1';
                end if;
                when FIFO32_SEND_UPDATE_COUNTERS =>
                --ctrl_out.free_words <= (others => '0');
                
                when FIFO32_WAIT_READ_DATA =>
                if c_in.dst = G_ADDRESS then
                    FIFO32_M_Data_debug <= std_logic_vector(c_in.data);
                    FIFO32_M_Wr_debug <= '1';
                end if;
                if cc_in.dst = G_ADDRESS then
                    FIFO32_M_Data_debug <= std_logic_vector(cc_in.data);
                    FIFO32_M_Wr_debug <= '1';
                end if;
                
                when FIFO32_DEARBITE_MASTER =>
                --ctrl_out.free_words <= (others => '0');
                
                when FIFO32_DEARBITE_SLAVE =>
                --ctrl_out.free_words <= (others => '0');
                
                when FIFO32_READ_DATA =>
                if c_in.dst = G_ADDRESS then
                    FIFO32_M_Data_debug <= std_logic_vector(c_in.data);
                    FIFO32_M_Wr_debug <= '1';
                end if;
                if cc_in.dst = G_ADDRESS then
                    FIFO32_M_Data_debug <= std_logic_vector(cc_in.data);
                    FIFO32_M_Wr_debug <= '1';
                end if;
            
            end case;
        end if;
end process;

end architecture;