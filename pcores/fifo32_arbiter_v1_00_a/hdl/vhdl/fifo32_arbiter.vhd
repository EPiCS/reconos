--Doxygen
--! @file fifo32_arbiter.vhd
--! @brief This file contains the entity and architecture of an arbiter that
--!        can connect multipe hardware threads with fifo32 interfaces to a 
--!        single xps_mem module.

library ieee; --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all; --! For logic
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; --! For unsigned and signed types and conversion from/to std_logic_vector

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

entity fifo32_arbiter is
	generic (
		FIFO32_PORTS : integer := 7; --! 1, 2, 4, 8 or 16 allowed
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
		OUT_FIFO32_S_Clk : out std_logic;
        OUT_FIFO32_S_Data : in std_logic_vector(31 downto 0);
		OUT_FIFO32_S_Fill : in std_logic_vector(15 downto 0);
		OUT_FIFO32_S_Rd : out std_logic;

		OUT_FIFO32_M_Clk : out std_logic;		
		OUT_FIFO32_M_Data : out std_logic_vector(31 downto 0);
		OUT_FIFO32_M_Rem : in std_logic_vector(15 downto 0);
		OUT_FIFO32_M_Wr : out std_logic;

        -- Misc
        Rst : in std_logic
	);
end entity;

--! Notes to implementor:
--! This Multiplexer may only switch to another input stream, when a complete
--! packet was transmitted. As we don't have any signals telling us the end or
--! start of a packet, we have to track the protocol to decide when to switch.
architecture behavioural of fifo32_arbiter is

component rr_arbiter
  generic(
    request_width : positive := 6  --! How many request inputs do you want?
    );
  port (
    clk      : in  std_logic;           --! Clock signal
    reset    : in  std_logic;           --! Reset signal
    requests : in  std_logic_vector (request_width-1 downto 0);  --! Input lines from the requestors.
    sel      : out std_logic_vector (clog2(request_width+1)-1 downto 0));  --! Who of the requesters will be served?
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

    --! Select signal from arbiter to the (de-)multiplexers.
    signal sel : std_logic_vector(clog2(FIFO32_PORTS+1)-1 downto 0);

    --! 
    signal requests : std_logic_vector(FIFO32_PORTS-1 downto 0);

begin -- of architecture -------------------------------------------------------


        
    -- Master part of fifo link

    mux_M_DATA: mux
    generic map (
       element_width => 32,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => IN_FIFO32_M_Data,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output  => OUT_FIFO32_M_DATA
    );   

    demux_M_REM: demux
    generic map (
       element_width => 16,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => OUT_FIFO32_M_Rem,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output  => IN_FIFO32_M_Rem
    );   

    mux_M_Wr: mux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => IN_FIFO32_M_Wr,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output(0)  => OUT_FIFO32_M_Wr
    );   

    mux_M_Clk: mux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => IN_FIFO32_M_Clk,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output(0)  => OUT_FIFO32_M_Clk
    );   

    -- Slave part of fifo link

    demux_S_Data: demux
    generic map (
       element_width => 32,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => OUT_FIFO32_S_Data,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output  => IN_FIFO32_S_Data
    );   

    demux_S_Fill: demux
    generic map (
       element_width => 16,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => OUT_FIFO32_S_Fill,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output  => IN_FIFO32_S_Fill
    );   

    mux_S_Rd: mux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => IN_FIFO32_S_Rd,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output(0)  => OUT_FIFO32_S_Rd
    );   

    mux_S_Clk: mux
    generic map (
       element_width => 1,
       element_count => FIFO32_PORTS
    )
    port map (
        input   => IN_FIFO32_S_Clk,
        sel     => sel(clog2(FIFO32_PORTS+1)-2 downto 0),
        output(0)  => OUT_FIFO32_S_Clk
    );   


    -- Arbiter controls sel signal
    rr_arbiter_i :rr_arbiter
      generic map(
        request_width => FIFO32_PORTS
      )
      port map(
       clk      => IN_FIFO32_M_Clk(0),
       reset    => Rst,
       requests => requests,
       sel      => sel
      );

    request_p: process (IN_FIFO32_M_Clk(0))
    is

    begin
        if Rst = '1' then
            requests <= (others => '0');
        elsif IN_FIFO32_M_Clk(0)'event and IN_FIFO32_M_Clk(0) = '1' then
            requests <= requests + 1 ;
        end if;

    end process;

end architecture;
