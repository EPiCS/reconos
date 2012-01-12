library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tlb is
	generic (
		C_TLB_LOGSIZE : integer := 5;
		C_TAG_SIZE    : integer := 20;
		C_DATA_SIZE   : integer := 20
	);
	port (
		clk        : in  std_logic;
		rst        : in  std_logic;
		tag        : in  std_logic_vector(C_TAG_SIZE-1 downto 0);
		di         : in  std_logic_vector(C_DATA_SIZE-1 downto 0);
		do         : out std_logic_vector(C_DATA_SIZE-1 downto 0);
		we         : in  std_logic;
		match      : out std_logic
	);
end tlb;

architecture Behavioral of tlb is

	function or_vec(v : std_logic_vector) return std_logic is
		variable result : std_logic;
	begin
		result := '0';
		for i in v'high downto v'low loop
			result := result or v(i);
		end loop;
		return result;
	end;

	constant C_TLB_SIZE : integer := 2**C_TLB_LOGSIZE;
	
	type TAG_T is array (0 to C_TLB_SIZE-1) of std_logic_vector(C_TAG_SIZE-1 downto 0);
	type DATA_T is array (0 to C_TLB_SIZE-1) of std_logic_vector(C_DATA_SIZE-1 downto 0);

	function or_data(d : DATA_T; m : std_logic_vector(C_TLB_SIZE-1 downto 0)) return std_logic_vector is
		variable result : std_logic_vector(C_DATA_SIZE-1 downto 0);
		variable tmp : std_logic_Vector(C_DATA_SIZE-1 downto 0);
	begin
		result := (others => '0');
		for i in 0 to C_TLB_SIZE-1 loop
			tmp := (others => m(i));
			result := result or (tmp and d(i));
		end loop;
		return result;
	end;
	
	signal tag_mem  : TAG_T;
	signal data_mem : DATA_T;
	signal valid : std_logic_vector(C_TLB_SIZE-1 downto 0);
	signal single_match : std_logic_vector(C_TLB_SIZE-1 downto 0);
	signal multi_match  : std_logic_Vector(C_TLB_SIZE-1 downto 0);
	signal wptr : integer range 0 to C_TLB_SIZE;
begin

	write_proc : process(clk,rst,we) is
	begin
		if rst = '1' then
			valid <= (others => '0');
		elsif rising_edge(clk) then
			if we = '1' then
				tag_mem(wptr)   <= tag;
				data_mem(wptr)  <= di;
				valid(wptr) <= '1';
				if wptr = C_TLB_SIZE-1 then
					wptr <= 0;
				else
					wptr <= wptr + 1;
				end if;
			end if;
		end if;
	end process;
	
	
	-- asynchronous read logic
	
	mm_gen : for i in 0 to C_TLB_SIZE-1 generate
		multi_match(i) <= valid(i) when tag_mem(i) = tag else '0';
	end generate;
	single_match <= multi_match; -- TODO: actually implement this
	do <= or_data(data_mem,single_match);
	match <= or_vec(multi_match);
	

end Behavioral;

