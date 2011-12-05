--Doxygen
--! @file fifo32_arbiter.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        can connect multipe hardware threads with fifo32 interfaces to a 
--!        single xps_mem module.

library ieee; --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all; --! For logic
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32_arbiter is
	generic (
		FIFO32_PORTS : integer := 16; --! 1, 2, 4, 8 or 16 allowed
        ARBITRATION_ALGO: integer := 0 --! 0= Round Robin, others not available atm.
	);
	port (
        -- Multiple FIFO32 Inputs
		IN_FIFO32_S_Clk : in std_logic_vector(FIFO32_PORTS-1 downto 0);
        IN_FIFO32_S_Data : out std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_S_Fill : out std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_S_Rd : in std_logic_vector(FIFO32_PORTS-1 downto 0);

		IN_FIFO32_M_Clk : in std_logic_vector(FIFO32_PORTS-1 downto 0);		
		IN_FIFO32_M_Data : in std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_M_Rem : out std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_M_Wr : in std_logic_vector(FIFO32_PORTS-1 downto 0);

        -- Single FIFO32 Output
		OUT_FIFO32_S_Clk : in std_logic;
        OUT_FIFO32_S_Data : out std_logic_vector(31 downto 0);
		OUT_FIFO32_S_Fill :out std_logic_vector(15 downto 0);
		OUT_FIFO32_S_Rd : in std_logic;

		OUT_FIFO32_M_Clk : in std_logic;		
		OUT_FIFO32_M_Data : in std_logic_vector(31 downto 0);
		OUT_FIFO32_M_Rem : out std_logic_vector(15 downto 0);
		OUT_FIFO32_M_Wr : in std_logic;

        -- Misc
        Rst : in std_logic;
        clk : in std_logic  -- separate clock for control logic
	);
end entity;

--! Notes to implementor:
--! This Multiplexer may only switch to another input stream, when a complete
--! packet was transmitted. As we don't have any signals telling us the end or
--! start of a packet, we have to track the protocol to decide when to switch.
architecture behavioural of fifo32_arbiter is

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

    component fifo32
	    generic (
		    FIFO32_DEPTH : integer := 16
	    );
	    port (
		    Rst : in std_logic;
		    FIFO32_S_Clk : in std_logic;
		    FIFO32_M_Clk : in std_logic;
		    FIFO32_S_Data : out std_logic_vector(31 downto 0);
		    FIFO32_M_Data : in std_logic_vector(31 downto 0);
		    FIFO32_S_Fill : out std_logic_vector(15 downto 0);
		    FIFO32_M_Rem : out std_logic_vector(15 downto 0);
		    FIFO32_S_Rd : in std_logic;
		    FIFO32_M_Wr : in std_logic
	    );
    end component;

    component rr_arbiter
      generic(
        request_width : positive := 6  --! How many request inputs do you want?
        );
      port (
        clk      : in  std_logic;           --! Clock signal
        reset    : in  std_logic;           --! Reset signal
        requests : in  std_logic_vector (request_width-1 downto 0);  --! Input lines from the requestors.
        sel      : out std_logic_vector (clog2(request_width)-1 downto 0));  --! Who of the requesters will be served?
    end component;

    component mux
      generic (
        element_width : positive := 32;  --! Width in bits of the input and output ports
        element_count  : positive := 16   --! Demux how many ports?
        );
      port (
        input : in  std_logic_vector(element_width*element_count-1 downto 0);  --! An array of input vectors
        sel         : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! The select signals to choose the input to be forwarded
        output      : out std_logic_vector(element_width-1 downto 0)  --! The output of the multiplexer
        );
    end component;

    component demux
      generic (
        element_width : positive := 32;  --! The width in bits of the input and output ports
        element_count : positive := 16       --! Demux to how many ports?
        );

      port (
        sel    : in  std_logic_vector(clog2(element_count)-1 downto 0);  --! Select signal: which output register shall be updated?
        input  : in  std_logic_vector(element_width-1 downto 0);  --! Data input
        output : out std_logic_vector(element_width*element_count-1 downto 0)  --! Data output
        );
    end component;

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

    --! Select signal from arbiter to the fsm.
    signal sel2mux : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);

    --! Select signal from fsm to the (de-)multiplexers.
    signal sel2fsm : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);
    
    --! 
    signal requests : std_logic_vector(FIFO32_PORTS-1 downto 0);

    --! FIFOs to multiplexers
    signal INT_FIFO32_S_Clk  : std_logic_vector(FIFO32_PORTS-1 downto 0);
    signal INT_FIFO32_S_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    signal INT_FIFO32_S_Fill : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    signal INT_FIFO32_S_Rd   : std_logic_vector(FIFO32_PORTS-1 downto 0);

    signal INT_FIFO32_M_Clk  : std_logic_vector(FIFO32_PORTS-1 downto 0);
    signal INT_FIFO32_M_Data : std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
    signal INT_FIFO32_M_Rem  : std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
    signal INT_FIFO32_M_Wr   : std_logic_vector(FIFO32_PORTS-1 downto 0);

    --! Tap slave data output to memory controller
    signal INT_OUT_FIFO32_S_Data : std_logic_vector(31 downto 0);

begin -- of architecture -------------------------------------------------------
    
    OUT_FIFO32_S_Data <= INT_OUT_FIFO32_S_Data;
    

    -- FIFOS
    fifos: for i in 0 to FIFO32_PORTS-1 generate
        master_fifo32_i : fifo32
        	generic map(
		            FIFO32_DEPTH => 16
            )
	        port map (
		        Rst => Rst,
		        FIFO32_S_Clk => INT_FIFO32_S_Clk(i),
		        FIFO32_M_Clk => IN_FIFO32_M_Clk(i),
		        FIFO32_S_Data => INT_FIFO32_S_Data((32*(i+1))-1 downto 32*i),
		        FIFO32_M_Data => IN_FIFO32_M_Data((32*(i+1))-1 downto 32*i),
		        FIFO32_S_Fill => INT_FIFO32_S_Fill((16*(i+1))-1 downto 16*i),
		        FIFO32_M_Rem => IN_FIFO32_M_Rem((16*(i+1))-1 downto 16*i),
		        FIFO32_S_Rd => INT_FIFO32_S_Rd(i),
		        FIFO32_M_Wr => IN_FIFO32_M_Wr(i)
	        );

        slave_fifo32_i : fifo32
        	generic map(
		            FIFO32_DEPTH => 16
            )
	        port map (
		        Rst => Rst,
		        FIFO32_S_Clk => IN_FIFO32_S_Clk(i),
		        FIFO32_M_Clk => INT_FIFO32_M_Clk(i),
		        FIFO32_S_Data => IN_FIFO32_S_Data((32*(i+1))-1 downto 32*i),
		        FIFO32_M_Data => INT_FIFO32_M_Data((32*(i+1))-1 downto 32*i),
		        FIFO32_S_Fill => IN_FIFO32_S_Fill((16*(i+1))-1 downto 16*i),
		        FIFO32_M_Rem => INT_FIFO32_M_Rem((16*(i+1))-1 downto 16*i),
		        FIFO32_S_Rd => IN_FIFO32_S_Rd(i),
		        FIFO32_M_Wr => INT_FIFO32_M_Wr(i)
	        );
    end generate;
    

        
    -- Slave part of fifo link

    mux_S_DATA: mux
    generic map (
       element_width => 32,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => INT_FIFO32_S_Data,
        sel     => sel2mux,
        output  => INT_OUT_FIFO32_S_DATA
    );   

    mux_S_FILL: mux
    generic map (
       element_width => 16,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => INT_FIFO32_S_FILL,
        sel     => sel2mux,
        output  => OUT_FIFO32_S_Fill
    );   

    demux_S_Rd: demux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input(0)   => OUT_FIFO32_S_Rd,
        sel     => sel2mux,
        output  => INT_FIFO32_S_Rd
    );   

    demux_S_Clk: demux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input(0)   => OUT_FIFO32_S_Clk,
        sel     => sel2mux,
        output  => INT_FIFO32_S_Clk
    );   

    -- Master part of fifo link

    demux_M_Data: demux
    generic map (
       element_width => 32,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => OUT_FIFO32_M_Data,
        sel     => sel2mux,
        output  => INT_FIFO32_M_Data
    );   

    mux_M_Rem: mux
    generic map (
       element_width => 16,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => INT_FIFO32_M_Rem,
        sel     => sel2mux,
        output  => OUT_FIFO32_M_Rem
    );   

    demux_M_Wr: demux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input(0)   => OUT_FIFO32_M_Wr,
        sel     => sel2mux,
        output  => INT_FIFO32_M_Wr
    );   

    demux_M_Clk: demux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input(0)   => OUT_FIFO32_M_Clk,
        sel     => sel2mux,
        output  => INT_FIFO32_M_Clk
    );   


    -- Arbiter controls sel signal
    rr_arbiter_i :rr_arbiter
      generic map(
        request_width => FIFO32_PORTS
      )
      port map(
       clk      => clk,
       reset    => Rst,
       requests => requests,
       sel      => sel2fsm
      );

    request_p: process (clk,rst,int_fifo32_s_fill)
    is

    begin
        --if Rst = '1' then
        --    requests <= (others => '0');
        --else --if clk'event and clk = '1' then
            for i in 0 to FIFO32_PORTS-1 loop
                if to_integer(unsigned(INT_FIFO32_S_Fill((16*(i+1))-1 downto 16*i))) > 1 then
                    requests(i) <= '1';
                else
                    requests(i) <= '0';
                end if;
            end loop;
        --end if;

    end process;

    fsm_p : process (clk,rst, sel2fsm)
    is  
        type FSM_STATE_T is (IDLE, MODE_LENGTH, ADDRESS, DATA_READ, DATA_WRITE);
        variable state : FSM_STATE_T;

        variable selection : std_logic_vector(clog2(FIFO32_PORTS)-1 downto 0);

        type TRANSFER_MODE_T is (READ, WRITE);
        variable transfer_mode : TRANSFER_MODE_T;
        variable transfer_size : natural range 0 to 2**30;

    begin
        if rst='1' then
            state := IDLE;
            selection := (others => '0');
            transfer_mode := READ;
        elsif clk'event and clk = '1' then
            -- default is to hold all outputs.
            state := state;
            selection := selection;
            sel2mux <= sel2mux;
            transfer_mode := transfer_mode;
            transfer_size := transfer_size;
            case state is
                when IDLE =>
                    state := MODE_LENGTH;
                    selection := sel2fsm;
                    sel2mux <= (others => '0');
                    case INT_OUT_FIFO32_S_DATA(31) is
                        when '0' => transfer_mode := READ;
                        when others => transfer_mode := WRITE;
                        
                    end case;
                    transfer_size := to_integer(unsigned(INT_OUT_FIFO32_S_DATA(31 downto 0)));
                when MODE_LENGTH =>
                    state := ADDRESS;
                    sel2mux <= selection;
                when ADDRESS =>
                    case transfer_mode is
                        when READ => state := DATA_READ;
                        when WRITE => state := DATA_WRITE;
                    end case;
                    sel2mux <= selection;
                when DATA_READ =>
                    if transfer_size = 0 then
                        state := IDLE;
                    end if;
                    if OUT_FIFO32_M_Wr = '1' then
                        transfer_size := transfer_size-1;
                    end if;

                    sel2mux <= selection;
                when DATA_WRITE =>
                    if transfer_size = 0 then
                        state := IDLE;
                    end if;
                    if OUT_FIFO32_S_Rd = '1' then
                        transfer_size := transfer_size-1;
                    end if;
                    sel2mux <= selection;
                when others =>
                    state := IDLE;
                    selection := selection;
                    sel2mux <= sel2mux;
            end case;
        end if;
    end process;

end architecture;
