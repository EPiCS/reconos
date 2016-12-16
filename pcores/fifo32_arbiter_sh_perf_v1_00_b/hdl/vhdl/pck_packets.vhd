
library IEEE;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;  --! for UNIFORM, TRUNC: pseudo-random number generation

library work;
use work.pck_string.all;

package pck_packets is

    type mode_t is (NONE,   -- generates an empty packet with maximum pause time. Effectivly stops sending packets.
                    READ,   -- generates a read  request with predefined values
                    WRITE,  -- generates a write request with predefined values
                    RANDOM  -- generates a random packet
    );
    --type MODE_VECTOR is array (natural range<>) of mode_t;
   -- type LENGTH_VECTOR is array (natural range<>) of natural range 0 to 2**16-1;
    --type ADDRESS_VECTOR is array (natural range<>) of std_logic_vector(31 downto 0);

    type packet_t is record
        pause: natural;
        mode: mode_t;
        length: natural;
        address: std_logic_vector(31 downto 0);
    end record;
         
    constant MAX_PACKETS: natural:=1023;
    type packet_vector is array (natural range<>) of packet_t;
    type packet_matrix is array (natural range<>) of packet_vector(0 to MAX_PACKETS);
    type data_vector is array (natural range<>) of std_logic_vector(31 downto 0);
    type packet_ptr  is access data_vector;
             
    constant predefined_packets  : packet_matrix := (
    -- caller 0
    ( 
--       0 => ( 2000, READ,  4,    X"00000001"),
--       1 => ( 20,   WRITE, 4,    X"00000002"),
--       2 => ( 2000, READ,  9000, X"00000003"),
--       3 => ( 20,   WRITE, 9000, X"00000004"),
--       4 => ( 2000, READ,  9000, X"00000005"),
--       5 => ( 20,   WRITE, 9000, X"00000006"),
--       6 => ( 2000, READ,  9000, X"00000007"),
--       7 => ( 20,   WRITE, 9000, X"00000008"),
--       8 => ( 2000, WRITE, 128,  X"00000009"),
--       9 => ( 20,   READ,  128,  X"0000000A"),
--      10 => ( 2000, WRITE, 128,  X"0000000B"),
     0 to 1023 => (0,RANDOM,0,X"00000001"),
     others =>  (0,NONE,0,X"00000000"))
    -- caller 1
    ,( 
--        0 => ( 20,   READ,  4,    X"00000001"),
--        1 => ( 2000, WRITE, 4,    X"00000002"),
--        2 => ( 20,   READ,  9000, X"00000003"),
--        3 => ( 2000, WRITE, 9000, X"00000004"),
--        4 => ( 0,    READ,  9000, X"00000005"),
--        5 => ( 2000, WRITE, 9000, X"00000006"),
--        6 => ( 20,   READ,  9000, X"00000007"),
--        7 => ( 2000, WRITE, 9000, X"00000008"),
--        8 => ( 20,   WRITE,  128,  X"00000009"),
--        9 => ( 2000, READ,  128,  X"0000000A"),
--       10 => ( 20,   WRITE, 128,  X"0000000B"),
      0 to 1023 => (0,RANDOM,0,X"00000000"),
      others => (0,NONE,0,X"00000000"))
     );
    
    constant PACKET_MODE_READ  : unsigned( 7 downto 0 ) := X"00";
    constant PACKET_MODE_WRITE : unsigned( 7 downto 0 ) := X"80";
    constant PACKET_MODE_NONE  : unsigned( 7 downto 0 ) := X"FF"; -- SIMULATION ONLY CONSTANT
    
    function to_slv( number: natural; bitwidth:natural) return std_logic_vector;
    
    impure function packet_generate    ( caller_id: natural; packet_nr: natural; error:natural:=0 ) return packet_ptr;
    function packet_get_pause          ( p: data_vector ) return integer;
    function packet_get_mode           ( p: data_vector ) return unsigned;
    function packet_get_length         ( p: data_vector ) return integer;
    function packet_get_request_length ( p:data_vector ) return integer;
    function packet_get_address        ( p: data_vector ) return unsigned;
    function packet_get_data           ( p: data_vector; idx:natural ) return std_logic_vector;
    function packet_get_description    ( p: data_vector ) return string;

end package;


package body pck_packets is

    shared variable global_seed1    : positive := 1;
    shared variable global_seed2    : positive := 2;


    -- This is merely an abbreviation.
    function to_slv( number: natural; bitwidth:natural) return std_logic_vector
    is
    begin
        return std_logic_vector(to_unsigned(number, bitwidth));
    end function;
    
    
    -- For deterministic randomness, this function accepts seeds
    impure function get_rand_with_seeds( constant seed1     : positive;
                              constant seed2     : positive;
                              constant min_value : natural;
                              constant max_value : natural)
      return natural is
      variable s1 : positive := 1;
      variable s2 : positive := 1;
      variable rand_int : natural := 0;
      variable rand     : real;
    begin
      s1 := seed1;
      s2 := seed2;
      uniform(s1, s2, rand);
      rand_int := integer(TRUNC(rand*real(max_value+1-min_value)))+min_value;
      return rand_int;
    end function;


    --! @brief This function generates a random natural number
    --! @param[in] min_value This gives the lower limit of the random number 
    --! @param[in] max_value This gives the upper limit of the random number
    --! @return A random natural number.
    impure function get_rand(constant min_value : natural;
                              constant max_value : natural)
      return natural is
      variable rand_int : natural := 0;
      variable rand     : real;
    begin
      uniform(global_seed1, global_seed2, rand);
      rand_int := integer(TRUNC(rand*real(max_value+1-min_value)))+min_value;
      return rand_int;
    end function;

    
    impure function packet_generate_predefined(caller_id: natural range 0 to 15; 
                                        packet_nr: natural range 0 to 2**28-1; 
                                        error:natural:=0) 
                                        return packet_ptr
    is
       alias    pp is predefined_packets;
       variable p  : packet_ptr;
       variable p_high_index : integer:=0;
    begin
        -- Look up packet length and create access type data.
        p_high_index := 2;
        if pp(caller_id)(packet_nr).mode = WRITE then
            p_high_index := p_high_index + pp(caller_id)(packet_nr).length/4;
        end if;
        p := new data_vector(0 to p_high_index);

        
        -- Fill packet array with pause time and header.
        p(0) := to_slv(pp(caller_id)(packet_nr).pause, 32);
        if pp(caller_id)(packet_nr).mode = WRITE then
            p(1)(31 downto 24) := X"80";
            -- Data field is filled with a unique packet id.
            for i in 3 to p'length-1 loop
                --p(i)(31 downto 28) := to_slv(caller_id, 4);
                p(i)(31 downto 28) := X"0";
                p(i)(27 downto  0) := to_slv(packet_nr, 28);
            end loop;
        else
            p(1)(31 downto 24) := X"00";
        end if;
        p(1)(23 downto 0) := to_slv(pp(caller_id)(packet_nr).length, 24);
        p(2)              := pp(caller_id)(packet_nr).address;

        return p;
    end function;
    
    impure function packet_generate_random(caller_id: natural range 0 to 15; 
                                        packet_nr: natural range 0 to 2**28-1; 
                                        error:natural:=0) 
                                        return packet_ptr
    is
        variable pause        : natural;
        variable length       : natural;
        variable mode         : mode_t;
        variable address      : natural;
        variable p            : packet_ptr;
        variable p_high_index : integer:=0;
    begin
        -- Generate random parameters
        pause  := get_rand_with_seeds(caller_id+1, packet_nr+1,0,1000);
        length := get_rand_with_seeds(caller_id+1, packet_nr+1,1, 2048);
        if get_rand_with_seeds(caller_id+1, packet_nr+1,0,9) < 5 then
            mode := READ;
        else 
            mode := WRITE;
        end if;
        address := get_rand_with_seeds(caller_id+1, packet_nr+1,0, natural'HIGH);
        
        -- Look up packet length and create access type data.
        p_high_index := 2;
        if mode = WRITE then
            p_high_index := p_high_index + length;
        end if;
        p := new data_vector(0 to p_high_index);
        
        -- Fill packet array with pause time and header.
        p(0) := to_slv(pause, 32);
        if mode = WRITE then
            p(1)(31 downto 24) := X"80";
            -- Data field is filled with a unique packet id.
            for i in 3 to p'LENGTH-1 loop
                --p(i)(31 downto 28) := to_slv(caller_id, 4);
                p(i)(31 downto 28) := X"0";
                p(i)(27 downto  0) := to_slv(packet_nr, 28);
            end loop;
        else
            p(1)(31 downto 24) := X"00";
        end if;
        p(1)(23 downto 0) := to_slv(length*4, 24);
        p(2)              := to_slv(address,32);


        return p;
    end function;
    
    impure function packet_generate_none return packet_ptr
    is
        alias    pp is predefined_packets;
       variable p  :packet_ptr;
    begin
        -- Look up packet length and create access type data.
        p := new data_vector(0 to 2);
        
        -- Fill packet array with pause time and header.
        p(0) := to_slv(natural'HIGH, 32);
        p(1) := X"00000000"; -- READ with length of 0
        p(2) := X"00000000"; -- Address of 0x0
        -- no data field because packet is read

        return p;
    end function;
    
    impure function packet_generate(caller_id: natural; 
                                        packet_nr: natural; 
                                        error:natural:=0) 
                                        return packet_ptr
    is
         alias    pp is predefined_packets;
    begin
        if caller_id < pp'LENGTH and packet_nr < pp(0)'length then 
            if pp(caller_id)(packet_nr).mode = RANDOM then
                return packet_generate_random(caller_id, packet_nr, error);
            elsif pp(caller_id)(packet_nr).mode = NONE then
                return packet_generate_none;
            else
               return packet_generate_predefined(caller_id, packet_nr, error);
            end if;
        else
            return packet_generate_none;
        end if;
        
    end function;

    function packet_get_pause      ( p:data_vector ) return integer
    is
    begin
		 assert p'length >= 3 severity failure; -- 3 is minimum valid packet
		 return to_integer(unsigned(p(0)));
    end function;

    function packet_get_mode        ( p:data_vector ) return unsigned
    is
        variable u : unsigned(7 downto 0);
    begin
		assert p'length >= 3 severity failure; -- 3 is minimum valid packet
		if to_integer(unsigned(p(0))) < natural'HIGH then
		     u := unsigned(p(1)(31 downto 24));
			 return u;
		else
			 return PACKET_MODE_NONE;
		end if;
    end function;
    
    -- Returns the length of the actual packet data to send in words. For a read this is 
    -- always 2 header words and for a write 2 header words + the amount of data
    -- to be written. See packet_get_request_length to get to know
    -- the amount of data to read or write. 
    function packet_get_length      ( p:data_vector ) return integer
    is
    begin
        assert p'length >= 3 severity failure; -- 3 is minimum valid packet
        --report "PACKET_GET_LENGTH returns " & to_string(p'length-1);
        --report "PACKET_GET_LENGTH p data  " & to_string(p(0)) &" " & to_string(p(1))&" " &to_string(p(2))&" " &to_string(p(3))&" " & to_string(p(4));
        return (p'length-1);
    end function;
    
    -- Returns the protocol field that indicates the amount of data in words
    -- to read or write.
    function packet_get_request_length      ( p:data_vector ) return integer
    is
    begin
        assert p'length >= 3 severity failure; -- 3 is minimum valid packet
        return to_integer(unsigned(p(1)(23 downto 0)))/4;
    end function;
    
    function packet_get_address     ( p:data_vector ) return unsigned
    is
    begin
	     assert p'length >= 3 severity failure; -- 3 is minimum valid packet
        return unsigned(p(2));
    end function;

    function packet_get_data        ( p:data_vector; idx:natural ) return std_logic_vector
    is
    begin
        assert p'length >= 3    report "PACKET_GET_DATA: malformed packet" severity failure; -- 3 is minimum valid packet
        assert idx < p'length-1 report "PACKET_GET_DATA: Index " & idx'image(idx) & " exceeds packet length!" severity failure;	
        return p(idx+1);
    end function;

    function packet_get_description ( p:data_vector ) return string
    is
    begin
        return "Packet: pause " & to_string(packet_get_pause(p)) & 
                " mode " & to_hstring(packet_get_mode(p)) &
                " length " & to_string(packet_get_request_length(p)*4) &
                " address " & to_hstring(packet_get_address(p)) &
                " data idx 0,1 " & to_hstring(packet_get_data(p,0)) &
                " " & to_hstring(packet_get_data(p,1));
    end function;
end package body;

