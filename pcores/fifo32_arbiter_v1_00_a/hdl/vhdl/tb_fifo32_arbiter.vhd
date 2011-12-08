library ieee; --! Use the standard ieee libraries for logic
use ieee.std_logic_1164.all; --! For logic
use ieee.numeric_std.all; --! For unsigned and signed types and conversion from/to std_logic_vector
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library reconos_v3_00_a;
use reconos_v3_00_a.reconos_pkg.all;

entity tb_fifo32_arbiter is
end entity;

architecture testbench of tb_fifo32_arbiter is
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

component fifo32_arbiter
	generic (
		FIFO32_PORTS : integer := 16; --! 1, 2, 4, 8 or 16 allowed
        ARBITRATION_ALGO: integer := 0 --! 0= Round Robin, others not available atm.
	);
	port (
        -- Multiple FIFO32 Inputs
		IN_FIFO32_S_Clk : out std_logic_vector(FIFO32_PORTS-1 downto 0);
        IN_FIFO32_S_Data : in std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_S_Fill : in std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_S_Rd : out std_logic_vector(FIFO32_PORTS-1 downto 0);

		IN_FIFO32_M_Clk : out std_logic_vector(FIFO32_PORTS-1 downto 0);		
		IN_FIFO32_M_Data : out std_logic_vector((32*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_M_Rem : in std_logic_vector((16*FIFO32_PORTS)-1 downto 0);
		IN_FIFO32_M_Wr : out std_logic_vector(FIFO32_PORTS-1 downto 0);

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
end component;

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
    constant half_cycle : time := 5 ns;
    constant full_cycle : time := 2 * half_cycle;

    constant HWT_COUNT : integer range 1 to 16 := 16;

--------------------------------------------------------------------------------
-- Signals
--------------------------------------------------------------------------------

    -- FIFO32 interface between hardware and fifos.
	signal H2F_FIFO32_S_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
    signal H2F_FIFO32_S_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
	signal H2F_FIFO32_S_Fill : std_logic_vector((16*HWT_COUNT)-1 downto 0);
	signal H2F_FIFO32_S_Rd   : std_logic_vector(HWT_COUNT-1 downto 0);

	signal H2F_FIFO32_M_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);		
	signal H2F_FIFO32_M_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
	signal H2F_FIFO32_M_Rem  : std_logic_vector((16*HWT_COUNT)-1 downto 0);
	signal H2F_FIFO32_M_Wr   : std_logic_vector(HWT_COUNT-1 downto 0);

    -- FIFO32 interface between fifos and arbiter
    signal F2A_FIFO32_S_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);
    signal F2A_FIFO32_S_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
	signal F2A_FIFO32_S_Fill : std_logic_vector((16*HWT_COUNT)-1 downto 0);
	signal F2A_FIFO32_S_Rd   : std_logic_vector(HWT_COUNT-1 downto 0);

	signal F2A_FIFO32_M_Clk  : std_logic_vector(HWT_COUNT-1 downto 0);		
	signal F2A_FIFO32_M_Data : std_logic_vector((32*HWT_COUNT)-1 downto 0);
	signal F2A_FIFO32_M_Rem  : std_logic_vector((16*HWT_COUNT)-1 downto 0);
	signal F2A_FIFO32_M_Wr   : std_logic_vector(HWT_COUNT-1 downto 0);

    -- FIFO32 interface between arbiter and memory controller.
	signal A2M_FIFO32_S_Clk  : std_logic;
    signal A2M_FIFO32_S_Data : std_logic_vector(31 downto 0);
	signal A2M_FIFO32_S_Fill : std_logic_vector(15 downto 0);
	signal A2M_FIFO32_S_Rd   : std_logic;

	signal A2M_FIFO32_M_Clk  : std_logic;		
	signal A2M_FIFO32_M_Data : std_logic_vector(31 downto 0);
	signal A2M_FIFO32_M_Rem  : std_logic_vector(15 downto 0);
	signal A2M_FIFO32_M_Wr   : std_logic;

    -- memif interface signals
    type memif_array_t is array(natural range <>) of memif_t ;    
    signal H2F_MEMIF : memif_array_t(0 to HWT_COUNT-1);

    signal A2M_MEMIF : memif_t;
    -- Misc
    signal Rst : std_logic;
    signal clk : std_logic;



begin -- of architecture -------------------------------------------------------

fifos:for i in 0 to HWT_COUNT-1 generate
    --signal H2F_MEMIF : memif_t;
begin

     memif_setup (
		H2F_MEMIF(i),
		clk,
		H2F_FIFO32_S_Clk(i),
		H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
        H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
		H2F_FIFO32_S_Rd(i),
		H2F_FIFO32_M_Clk(i),
		H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
        H2F_FIFO32_M_Rem (16*(i+1)-1 downto 16*i),
		H2F_FIFO32_M_Wr(i)
    );

    master_fifo32_i : fifo32
	    generic map(
		    FIFO32_DEPTH =>16
	    )
	    port map(
		    Rst => rst,
		    FIFO32_S_Clk  => F2A_FIFO32_S_Clk(i),
		    FIFO32_M_Clk  => H2F_FIFO32_M_Clk(i),
		    FIFO32_S_Data => F2A_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
		    FIFO32_M_Data => H2F_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
		    FIFO32_S_Fill => F2A_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
		    FIFO32_M_Rem  => H2F_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
		    FIFO32_S_Rd   => F2A_FIFO32_S_Rd(i),
		    FIFO32_M_Wr   => H2F_FIFO32_M_Wr(i)
	    );
    slave_fifo32_i : fifo32
	    generic map(
		    FIFO32_DEPTH =>16
	    )
	    port map(
		    Rst => rst,
		    FIFO32_S_Clk  => H2F_FIFO32_S_Clk(i),
		    FIFO32_M_Clk  => F2A_FIFO32_M_Clk(i),
		    FIFO32_S_Data => H2F_FIFO32_S_Data(32*(i+1)-1 downto 32*i),
		    FIFO32_M_Data => F2A_FIFO32_M_Data(32*(i+1)-1 downto 32*i),
		    FIFO32_S_Fill => H2F_FIFO32_S_Fill(16*(i+1)-1 downto 16*i),
		    FIFO32_M_Rem  => F2A_FIFO32_M_Rem(16*(i+1)-1 downto 16*i),
		    FIFO32_S_Rd   => H2F_FIFO32_S_Rd(i),
		    FIFO32_M_Wr   => F2A_FIFO32_M_Wr(i)
	    );


    hwt_process: process is
        --! @brief First of two global variables needed for random number functions,
        --!        e.g. get_rand_unsigned      
        variable seed1 : positive;
        --! @brief Second of two global variables needed for random number functions,
        --!        e.g. get_rand_unsigned
        variable seed2 : positive;


        --! @brief This function generates a random unsigned number
        --! @details This is an impure function, because it uses the global
        --!          variables seed1 and seed2, although this variables are not
        --!          specified in its interface.
        --! @param[in] min_value This gives the lower limit of the random number 
        --! @param[in] max_value This gives the upper limit of the random number
        --! @param[in] bitwidth The unsigend type is based on standard_logic_vector,
        --!            so we need to know what width in bits the result shall have.
        --! @return A random unsigned number of type unsigned with a width of bitwidth.
        impure function get_rand_unsigned(constant min_value : natural;
                                          constant max_value : natural;
                                          constant bitwidth  : positive)
          return unsigned is
          variable rand_int : integer := 0;
          -- Variable that holds the result of the uniform function
          variable rand     : real;
        begin
          uniform(seed1, seed2, rand);
          rand_int := integer(TRUNC(rand*real(max_value+1-min_value)))+min_value;
          return to_unsigned(rand_int, bitwidth);
        end function;

        variable done : boolean;
    begin
        -- init interface 
        memif_reset(H2F_MEMIF(i));
        -- Wait some time before sending data
        wait for 10 * full_cycle;
        -- Write mode + length
        memif_write (
		    H2F_MEMIF(i),
		    X"55555555", -- address
            X"AAAAAAAA", -- data
		    done
	    );
        wait;

    end process;

end generate;

fifo32_arbiter_i: fifo32_arbiter
	generic map(
		FIFO32_PORTS => 16,
        ARBITRATION_ALGO => 0
	)
	port map(
        -- Multiple FIFO32 Inputs
		IN_FIFO32_S_Clk  => F2A_FIFO32_S_Clk,
        IN_FIFO32_S_Data => F2A_FIFO32_S_Data,
		IN_FIFO32_S_Fill => F2A_FIFO32_S_Fill,
		IN_FIFO32_S_Rd   => F2A_FIFO32_S_Rd,

		IN_FIFO32_M_Clk  => F2A_FIFO32_M_Clk,
		IN_FIFO32_M_Data => F2A_FIFO32_M_Data,
		IN_FIFO32_M_Rem  => F2A_FIFO32_M_Rem,
		IN_FIFO32_M_Wr   => F2A_FIFO32_M_Wr,

        -- Single FIFO32 Output
		OUT_FIFO32_S_Clk  => A2M_FIFO32_S_Clk,
        OUT_FIFO32_S_Data => A2M_FIFO32_S_Data, 
		OUT_FIFO32_S_Fill => A2M_FIFO32_S_Fill,
		OUT_FIFO32_S_Rd   => A2M_FIFO32_S_Rd,

		OUT_FIFO32_M_Clk  => A2M_FIFO32_M_Clk,
		OUT_FIFO32_M_Data => A2M_FIFO32_M_Data,
		OUT_FIFO32_M_Rem  => A2M_FIFO32_M_Rem,
		OUT_FIFO32_M_Wr   => A2M_FIFO32_M_wr,

        -- Misc
        Rst  => rst,
        clk  => clk
	);

memif_setup (
	A2M_MEMIF,
	clk,
	A2M_FIFO32_S_Clk,
	A2M_FIFO32_S_Data,
    A2M_FIFO32_S_Fill,
	A2M_FIFO32_S_Rd,
	A2M_FIFO32_M_Clk,
	A2M_FIFO32_M_Data,
    A2M_FIFO32_M_Rem,
	A2M_FIFO32_M_Wr
);

mem_ctrl: process is
begin
    memif_reset(A2M_MEMIF);
    wait;
end process;

reset: process is
begin
    rst <= '1';
    wait for 5 * full_cycle;
    rst <= '0';
    wait;
end process;

-- All clocks are the same.
clock: process is
begin
   clk <= '1';
    for i in 0 to HWT_COUNT-1 loop
        --H2F_FIFO32_M_Clk(i) <= '1';
        --H2F_FIFO32_S_Clk(i) <= '1';
        --F2A_FIFO32_M_Clk(i) <= '1';
        --F2A_FIFO32_S_Clk(i) <= '1';
        --A2M_FIFO32_M_Clk    <= '1';
        --A2M_FIFO32_S_Clk    <= '1';
    end loop;
    wait for half_cycle;
    clk <= '0';
    for i in 0 to HWT_COUNT-1 loop
        --H2F_FIFO32_M_Clk(i) <= '0';
        --H2F_FIFO32_S_Clk(i) <= '0';
        --F2A_FIFO32_M_Clk(i) <= '0';
        --F2A_FIFO32_S_Clk(i) <= '0';
        --A2M_FIFO32_M_Clk    <= '0';
        --A2M_FIFO32_S_Clk    <= '0';
    end loop;
    wait for half_cycle;
end process;


end architecture;

