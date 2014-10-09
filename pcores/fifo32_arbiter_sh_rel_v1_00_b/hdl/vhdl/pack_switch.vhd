----------------------------------------------------------------------------------
-- Company: Universität Paderborn, AG Datentechnik 
-- Engineer: Sebastian Meisner (meise@upb.de)
-- 
-- Create Date:    18:45:04 03/16/2007 
-- Design Name: 
-- Module Name:    pack_switch
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  This package gathers constants, functions and definitions
--               for the Network-On-Chip Design.
--
-- Dependencies: 
--
-- Revision:
-- Revision 0.03 - Sebastian Meisner, 23.07.2009:
--                      - (re)moved unused constants: CHIP_ADDR*, PORT_COUNT,
--                        MAX_FRAME_SIZE
-- Revision 0.02 - Fixes this header, contained old information
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--
--
-- Constants defined in pack_switch.vhd.
-- 
----------------------------------------------------------------------------------

-- Doxygen:

--! \mainpage TediNoCa Switch Documentation
--! \section intro Introduction
--! Welcome to the TediNoCa Switch documentation pages. This page will give
--! you a brief introduction into the NoC and Switch architecture needed to
--! understand the rest of this documentation

--! @file pack_switch.vhd
--! @brief Contains constants, types, procedures and functions used throughout the NoC.
--! @details This file should be included into every design file for synthesis and simulation.


library ieee;              --! Use the standard IEEE libraries for logic
use ieee.std_logic_1164.all;            --! For logic
use ieee.numeric_std.all;  --! For unsigned and signed types and conversion from/to std_logic_vector.

-------------------------------------------------------------------------------
--! All kinds of declarations for the NoC
-------------------------------------------------------------------------------
--! @brief Package containing important constants and type definitions for the
--!        tedinoca switch implementation.
package pack_switch is

  -------------------------------------------------------------------------------  
  -- Common Constants
  -------------------------------------------------------------------------------

  --! @brief Maximum number of words in a frame.
  --! @details The noc_gen_packet_l2 function and some data structures
  --!          needs to know this to reserve enough memory for saving a
  --!          whole frame.
  constant MAX_FRAME_SIZE : natural := 255;

  constant SW_MAX_HEIGHT : natural := 16;
  constant SW_MAX_WIDTH  : natural := 16;

  constant PORT_COUNT : positive := 5;  --! Number of external switch ports.

  --! @brief Switch Out Port FIFO Depth (2**8 = 256 Byte)
  --! @details Must be at least 2, because the SOP Control unit relies on a few
  --!          free words in the fifo, for implementing transfer pauses through
  --!          the register stage at the input of the SOP.
  constant SWITCH_OUT_FIFO_ADDR_WIDTH : positive := 8;

  --! @brief Bitwidth of select signals: How many destinations do we have inside a switch?
  --! @details North, East, South, West, Ressource Directions = 5
  --!          switch control                                 = 1
  --!          --------------------------------------------------
  --!          Sum                                            = 6
  constant SELECT_WIDTH : integer := 6;

  constant BUFFER_WIDTH     : integer := 8;  --! Buffer depth (2**8 = 256 Byte) used in NIPaket.vhd
                                             --! and buffer.vhd in the network interface model.
  constant ADDR_LARGE_WIDTH : integer := 9;  --! Buffer depth (2**9 = 512 Byte)  
  --constant RESET_TYPE       : std_logic := '1';  --! Used in the network interface

  -- MUX Constants

  -- Add aliases for your header fields 
  -- as you like

  --! @brief Size of the register file in the demux_reg module used in the switch in port.
  --! @details This value should be set to the length of the biggest frame
  --!          header in use plus 2. Plus 1 because Register 0 of the demux is always '0'
  --!          and updates to it are discarded and another plus 1 for being
  --!          able to read in the first data word, to prevent an unneccessary stop
  --!          of transmission.
  --! @note Update the REG_* constants if you change this one.
  constant REGISTER_COUNT : positive := 8;

  --! @name Constants for adressing the registers of the demux_reg in the switch in port.
  --! These constants have to be checked whenever the REGISTER_COUNT constant is changed.
  --! For correct functionality, this constants have to be consecutive, that
  --! means, no "holes" in the numbering are allowed.  
  --! @{
  constant REG_0, REG_DISCARD   : std_logic_vector(2 downto 0) := "000";
  constant REG_1, REG_FRAMETYPE : std_logic_vector(2 downto 0) := "001";
  constant REG_2, REG_DEST      : std_logic_vector(2 downto 0) := "010";
  constant REG_3, REG_SRC       : std_logic_vector(2 downto 0) := "011";
  constant REG_4, REG_DATATYPE  : std_logic_vector(2 downto 0) := "100";
  constant REG_5, REG_LEN       : std_logic_vector(2 downto 0) := "101";
  constant REG_6, REG_CHKSUM    : std_logic_vector(2 downto 0) := "110";
  constant REG_7, REG_DATA      : std_logic_vector(2 downto 0) := "111";
  --! @}

  -------------------------------------------------------------------------------
  -- Common Types
  -------------------------------------------------------------------------------
  --! @name Datatypes of fixed width for generic use. Unsigned Versions.
  --! @{
  subtype unibble is unsigned (3 downto 0);   --! Half of a Byte
  subtype ubyte is unsigned(7 downto 0);      --! A common Byte made of 8 bits
  subtype uhword is unsigned (15 downto 0);   --! Half-Word consists of 2 Bytes
  subtype uword is unsigned (31 downto 0);    --! Word
  subtype udword is unsigned (63 downto 0);   --! Double Word
  subtype uqword is unsigned (127 downto 0);  --! Quad Word
  --! @}

  --! @name Array versions of fixed width, signed datatypes.
  --! @{
  type unibble_array is array (natural range <>) of unibble;
  type ubyte_array is array (natural range <>) of ubyte;
  type uhword_array is array (natural range <>) of uhword;
  type uword_array is array (natural range <>) of uword;
  type udword_array is array (natural range <>) of udword;
  type uqword_array is array (natural range <>) of uqword;
  --! @}

  --! @name Datatypes of fixed width for generic use. Signed Versions.
  --! @{
  subtype snibble is signed (3 downto 0);   --! Half of a Byte
  subtype sbyte is signed(7 downto 0);      --! A common Byte made of 8 bits
  subtype shword is signed (15 downto 0);   --! A Half-Word consists of 2 Bytes
  subtype sword is signed (31 downto 0);    --! Word
  subtype sdword is signed (63 downto 0);   --! Double Word
  subtype sqword is signed (127 downto 0);  --! Quad Word
  --! @}

  --! @name Array versions of fixed width, signed datatypes.
  --! @{
  type snibble_array is array (natural range <>) of snibble;
  type sbyte_array is array (natural range <>) of sbyte;
  type shword_array is array (natural range <>) of shword;
  type sword_array is array (natural range <>) of sword;
  type sdword_array is array (natural range <>) of sdword;
  type sqword_array is array (natural range <>) of sqword;
  --! @}

  --! @brief Function to get the x'th unsigned nibble from a bigger unsigned data type.
  --! @param[in] data The unsigned vector.
  --! @param[in] index Index of the nibble  in the data vector.
  --! @return          The requested unsigned nibble
  function get_unibble (
    constant data  : unsigned;
    constant index : natural)
    return unibble;

  --! @brief Function to get the x'th unsigned byte from a bigger unsigned data type.
  --! @param[in] data The unsigned vector.
  --! @param[in] index Index of the byte in the data vector.
  --! @return          The requested unsigned byte.
  function get_ubyte (
    constant data  : unsigned;
    constant index : natural)
    return ubyte;

  --! @brief Conversion function from natural to ubyte type.
  --! @details Checks correct range: number has to be between 0 an 255, inclusive.
  --! @param[in] number A number in the range from 0 to 255 to convert to an
  --!                   unsigned byte.
  --! @return An unsigned byte of type ubyte.
  function to_ubyte (
    constant number : natural)
    return ubyte;

  -- @brief General type for storing frame or packets during simulations.
  -- @details As frame protocol fields need to be 8-bit aligned, every element
  --          in this array is an 8-bit word used to store a byte of frame or
  --          packet data. Unsigned type of elements is choosen to ease
  --          arithmetics on protocol fields.
  --          The packages pack_switch_interface_{int,ext} offer conversion
  --          functions to their own data_types.
  -- @note The function to_string() in pack_tb.vhd uses this type.
  --type data_array_type is array (natural range <>) of unsigned(7 downto 0);

  --> See now ubyte_array


  --! @brief Record defining a natural range.
  type nat_range is record
    min : natural;
    max : natural;
  end record;


  -----------------------------------------------------------------------------
  -- Routing Algorithm and associated types and functions
  -----------------------------------------------------------------------------

  --! @brief Type to denote the forwarding direction.
  --! @details The ordering is always: 0= North, 1= East, 2= South,
  --!          3= West, 4= Resource. See directions constants below.
  subtype sw_direction is natural range 0 to SELECT_WIDTH-1;

  --! @name Direction Numbers
  --! @brief The direction numbers are used to distinguish between the destinations
  --!        inside the switch and to walk through all direction in for
  --!        statements. Don't change the order in this list! Only add to the end!
  --!        Otherwise some "generate" statements or for loops could break!
  --! @{
  constant NORTH_NUM    : sw_direction := 0;
  constant EAST_NUM     : sw_direction := 1;
  constant SOUTH_NUM    : sw_direction := 2;
  constant WEST_NUM     : sw_direction := 3;
  constant RESOURCE_NUM : sw_direction := 4;
  constant CONTROL_NUM  : sw_direction := 5;
  --! @}

  --! @brief Type for simultaneously indicating multiple directions.
  --! @details Implemented as a bit field. Every index specifies a direction.
  --!          If there is a '1' this direction is active, if there is a '0',
  --!          the direction is inactive. See the direction numbers like NO_DIR
  --!          and NORTH_DIR for a mapping of indices to directions.
  subtype sw_mult_direction is std_logic_vector(SELECT_WIDTH-1 downto 0);

  --! @name Direction constant of switch_multiple_direction type
  --! @brief These constants are used with the noc_set_* and noc_get_* procedures
  --!        and functions to set the directions which shall be altered in
  --!        state or data.
  --! @details NO_DIR specifies that no direction is selected. ALL_DIR is meant
  --!          to be used for broadcasts, as every direction will be altered
  --!          simultaneously. The other constants address single directions.
  --!          For creating a multicast, you can combine any single direction
  --!          with the or operator. So calling
  --!          sw_set_send_state(signals, SELECTONLY, NORTH_DIR or SOUTH_DIR);
  --!          will set the signals to north and south to be in SELECTONLY state.
  --! @note Xilinx ISE9.2 does not support deferred constant initialization, so
  --!       we have to do it here.
  --! @note We formerly used a statement like:
  --!       @c std_logic_vector(to_unsigned(2**NORTH_NUM, sw_mult_direction'length));
  --!       to initialize the constant. Unfortunately ISE didn't recognize it
  --!       as a constant this way, because we used functions for the initialization.
  --! @warning Never rely on the value of the constants! These may change in
  --!          the future! You have been warned!
  --! @{
  constant NO_DIR       : sw_mult_direction := (others => '0');
  constant ALL_DIR      : sw_mult_direction := (others => '1');
  constant NORTH_DIR    : sw_mult_direction := "000001";
  constant EAST_DIR     : sw_mult_direction := "000010";
  constant SOUTH_DIR    : sw_mult_direction := "000100";
  constant WEST_DIR     : sw_mult_direction := "001000";
  constant RESOURCE_DIR : sw_mult_direction := "010000";
  constant CONTROL_DIR  : sw_mult_direction := "100000";
  --! @}

  --! @brief Conversion function from type sw_direction to type sw_mult_direction.
  --! @param[in] dir_num The direction number which should be converted into a
  --!                sw_mult_direction type;
  --! @return The converted direction number.
  function to_sw_mult_direction (
    constant dir_num : in sw_direction)
    return sw_mult_direction;

  --! @brief Conversion function from type sw_mult_direction to type sw_direction.
  --! @details If dir is NO_DIR, then NORTH_NUM will be returned. If a single
  --!          direction is activated in dir, then the direction Number will be returned.
  --!          If multiple directions are activated in dir, then the first one
  --!          counting from NORTH_NUM up will be returned.
  --! @param[in] dir Input direction(s).
  --! @return    The first activated direction found or NORTH_NUM.
  function to_sw_direction (
    constant dir   : in sw_mult_direction)
    return sw_direction;

  --! @brief Abstract type for representing a switch address.
  --! @details: The physical representation in an ubyte shall be as follows:
  --!           yyyyxxxx
  --!
  --!           8 Bit in total, the first 4 Bits from the left (7 downto 4) give
  --!           the y-coordinate or row, and the last 4 bits (3 downto 0) give
  --!           the x coordinate or column.
  type sw_address is record
    y : natural range 0 to SW_MAX_HEIGHT-1;
    x : natural range 0 to SW_MAX_WIDTH-1;
  end record;

  --! @brief Transforms a data byte into the abstract switch address
  --! @details See the sw_address type for an explanation of the physical
  --!          representation of the address type.
  --! @param[in] address An unsigned byte of data which holds a switch address.
  --! @return    The address as an abstract sw_address type.
  function to_sw_address(
    constant address : ubyte)
    return sw_address;

  --! @brief Transforms an abstract switch address into the physical representation.
  --! @details See the sw_address type for an explanation of the physical
  --!          implementation of the address type.
  --! @param[in] address The switch address in abstract form.
  --! @return The swicth address in physical ubyte representation.
  function to_ubyte (
    constant address : sw_address)
    return ubyte;

  --! @brief Routing function used in the switches.
  --! @details It implements a simple yx-Routing scheme. That means a frame is
  --!          first forwarded into the destination row (y-coordinate) and then into the
  --!          destination column (x-coordinate). If the destination address
  --!          matches the switch address, the frame will be forwarded to the resource, else
  --!          the y- and x-coordinates will be compared and the frame will
  --!          be forwarded to one of the 4 switch directions north, east, south or
  --!          west.
  --! @param[in] dest The destination address of a frame.
  --! @param[in] current_address The address of the processing element.
  --! return     The direction to which the frame shall be forwarded.
  function sw_get_next_hop (
    constant dest            : in sw_address;
    constant current_address : in sw_address)
    return sw_direction;

  -----------------------------------------------------------------------------
  -- Information about the Diagnosis Controller
  -----------------------------------------------------------------------------
  --! @brief Address of the diagnosis controller.
  --! @details Must be  globally known, so that every switch knows where to send
  --!          test requests.
  constant SW_DC_ADDRESS : sw_address := (0, 0);

  -----------------------------------------------------------------------------
  -- Common Functions
  -----------------------------------------------------------------------------

  --! @brief Calculates the even parity of a data word.
  --! @param[in] data One data word of the appropiate width, from which the parity shall be calculated.
  --! @return The parity bit.
  function sw_parity(
    constant data : std_logic_vector)
    return std_logic;

  --! @brief Calculates a xor checksum
  --! @param[in] data The first or next word of data to be checksummed
  --! @param[in] old_checksum The old checksum, generated by a former
  --!             invocation of this function, or (others =>'0') for the first time
  --! @return A Vector with the updated checksum
  function sw_checksum (
    constant data         : ubyte;
    constant old_checksum : ubyte)
    return ubyte;

  --! @brief Calculates a xor checksum
  --! @param[in] data An array of data words, over which the checksum shall be
  --!                 calculated.
  --! @return A vector with the checksum of the data array
  function sw_checksum (
    constant data : ubyte_array)
    return ubyte;

  --! @brief This logarithm function is only for constant calculation!
  --! @param[in] x Number of type positive to calculate the logarithm from
  --! @return Type Natural, the logarithm of x, rounded up to the next integer
  function log2 (
    x : positive)
    return natural;

  --! @brief Returns the hamming weight of a standard_logic_vector, that is the
  --!        number of set bits.
  --! @details Non '1' literals in the vector are silently ignored. So vector
  --!          "001Z1XH" results in 2 bits set.
  --! @param[in] vector A vector of arbitrary length
  --! @return The integer number of set bits in the vector.
  function hamming_weight (
    constant vector : std_logic_vector)
    return natural;
  
end package pack_switch;

-------------------------------------------------------------------------------
--! Implementation of the procedures and functions
-------------------------------------------------------------------------------
package body pack_switch is

  -----------------------------------------------------------------------------
  -- Routing Algorithm and associated types and functions
  -----------------------------------------------------------------------------
  function to_sw_address(
    constant address : ubyte)
    return sw_address
  is
    variable my_address : sw_address;
  begin
    my_address.y := to_integer(get_unibble(address, 1));
    my_address.x := to_integer(get_unibble(address, 0));
    return my_address;
  end function;

  function to_ubyte (
    constant address : sw_address)
    return ubyte
  is
    variable my_byte : ubyte;
  begin
    my_byte := to_unsigned(address.y, 4) & to_unsigned(address.x, 4);
    return my_byte;
  end function;

  function sw_get_next_hop (
    constant dest            : in sw_address;
    constant current_address : in sw_address)
    return sw_direction
  is
    variable direction : sw_direction;
  begin
    if dest = current_address then
      direction := RESOURCE_NUM;           -- Network Interface
    elsif dest.y = current_address.y then  -- same row address 
      if dest.x < current_address.x then
        direction := WEST_NUM;             -- West
      else
        direction := EAST_NUM;             -- East
      end if;
    else
      if dest.y < current_address.y then
        direction := SOUTH_NUM;            -- South
      else
        direction := NORTH_NUM;            -- North
      end if;
    end if;
    return direction;
  end function;

  -----------------------------------------------------------------------------
  -- Common Functions
  -----------------------------------------------------------------------------
  function to_sw_mult_direction (
    constant dir_num : sw_direction)
    return sw_mult_direction
  is
  begin
    return std_logic_vector(to_unsigned(2**dir_num, sw_mult_direction'length));
  end function;

  function to_sw_direction (
    constant dir   :    sw_mult_direction)
    return sw_direction
  is
    variable r_value : sw_direction;
  begin
    r_value := NORTH_NUM;
    for i in sw_mult_direction'range loop
      if dir(i) = '1' then
        r_value := i;
      end if;
    end loop;
    return r_value;
  end function;

  function get_slice (
    constant data   : unsigned;
    constant index  : natural;
    constant length : natural)
    return unsigned
  is
    variable ret_value : unsigned(length-1 downto 0);
  begin
    assert data'length mod length = 0
      report "data vector is not a multiple of 4! Refusing to get a nibble!"
      severity error;
    assert data'length >= length*(1+index)-1
      report "data vector to short. Can't access requested nibble."
      severity error;
    
    if data'ascending then
      ret_value := data(length*index to length*(1+index)-1);
    else
      ret_value := data(length*(1+index)-1 downto length*index);
    end if;

    return ret_value;
  end get_slice;
  
  function get_unibble (
    constant data  : unsigned;
    constant index : natural)
    return unibble
  is
  begin
    return unibble(get_slice(data, index, unibble'length));
  end function;

  function get_ubyte (
    constant data  : unsigned;
    constant index : natural)
    return ubyte
  is
  begin
    return ubyte(get_slice(data, index, ubyte'length));
  end function;

  function to_ubyte (
    constant number : natural)
    return ubyte
  is
  begin
    assert number < 256
      report "to_ubyte: Number bigger than 255, doesn't fit into ubyte"
      severity error;
    assert number >= 0
      report "to_ubyte: Number smaller than 0, doesn't fit into ubyte"
      severity error;

    return to_unsigned(number, ubyte'length);
  end function;


  --! @brief Calculates the even parity of a data word
  --! @param[in] data One data word of the appropiate width, from which the parity shall be calculated
  --! @return the parity bit
  --! @todo Remove this function. It is now included in
  --!       pack_switch_external_interface as sw_ext_parity.
  function sw_parity (
    constant data : std_logic_vector)
    return std_logic is
    variable one_count : natural := 0;
  begin
    one_count := 0;

    -- Count '1's inside the data word.
    for i in data'range loop
      if data(i) = '1' then
        one_count := one_count + 1;
      end if;
    end loop;

    -- Return even parity.
    if one_count mod 2 = 1 then
      return '1';
    else
      return '0';
    end if;
  end function;

--! @brief Calculates a xor checksum
--! @param[in] data The first or next word of data to be checksummed
--! @param[in] old_checksum The old checksum, generated by a former
--!             invocation of this function, or (others =>'0') for the first time
--! @return A Vector with the updated checksum
  function sw_checksum (
    constant data         : ubyte;
    constant old_checksum : ubyte)
    return ubyte is
  begin
    return ubyte(std_logic_vector(data) xor std_logic_vector(old_checksum));
  end function;

--! @brief Calculates a xor checksum
--! @param[in] data An array of data words, over which the checksum shall be
--!                 calculated.
--! @return A vector with the checksum of the data array
  function sw_checksum (
    constant data : ubyte_array
    )
    return ubyte
  is
    variable checksum : ubyte := (others => '0');
  begin
    for i in data'range loop
      checksum := sw_checksum(data(i), checksum);
    end loop;
    return checksum;
  end function;

  --! @brief This logarithm function is only for constant calculation!
  --! @details Do not synthesise it!
  --! Its return value holds the equation 2**log2(x) >= x
  --! That means for example, it gives you the number of bits you need
  --! to store the unsigned integer x.
  --!<pre>
  --! x      | log2(x)
  --!-------------
  --! 1      | 0
  --! 2      | 1
  --! 3,4    | 2
  --! 5 - 8  | 3
  --! 9 - 16 | 4
  --! ...
  --!</pre>
  --! @param[in] x Number of type positive to calculate the logarithm from
  --! @return Type Natural, the logarithm of x, rounded up to the next integer
  function log2 (
    x : positive)
    return natural is
    variable exp : natural;
  begin
    exp := 0;
    while 2**exp < x loop
      exp := exp+1;
    end loop;
    return exp;
  end function log2;

  --! @brief Returns the hamming weight of a given vector.
  --! @details The hamming weight is defined as the number of 1's in a bit
  --!          string. This functions counts only  strong ones, namely
  --!          literal 1's of the std_logic value space, and the weak
  --!          ones, namely 'H'.
  --! @param[in] vector An arbitralily long std_logic_vector.
  --! @return The number of 1's in the given vector.
  function hamming_weight (
    constant vector : std_logic_vector)
    return natural
  is
    variable count : natural := 0;
  begin
    for i in vector'range loop
      if vector(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    return count;
  end;
  
end package body pack_switch;
