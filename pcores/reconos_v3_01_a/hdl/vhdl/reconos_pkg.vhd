--                                                        ____  _____
--                            ________  _________  ____  / __ \/ ___/
--                           / ___/ _ \/ ___/ __ \/ __ \/ / / /\__ \
--                          / /  /  __/ /__/ /_/ / / / / /_/ /___/ /
--                         /_/   \___/\___/\____/_/ /_/\____//____/
-- 
-- ======================================================================
--
--   title:        VHDL Package - ReconOS
--
--   project:      ReconOS
--   author:       Enno Lübbers, University of Paderborn
--                 Andreas Agne, University of Paderborn
--                 Christoph Rüthing, University of Paderborn
--   description:  The entire ReconOS package with type definitions and
--                 hardware OS services in VHDL
--
-- ======================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

package reconos_pkg is

	constant C_FIFO_WIDTH          : integer := 32;
	constant C_OSIF_WIDTH          : integer := C_FIFO_WIDTH;
	constant C_MEMIF_WIDTH         : integer := C_FIFO_WIDTH;
	-- any request will be split up in multiple requests of size C_CHUNK_SIZE (in words)
	constant C_CHUNK_SIZE          : integer := 64;
	constant C_CHUNK_SIZE_BYTES    : integer := C_CHUNK_SIZE * 4;
	constant C_MEMIF_LENGTH_WIDTH  : integer := 24;
	constant C_MEMIF_CMD_WIDTH     : integer := C_MEMIF_WIDTH - C_MEMIF_LENGTH_WIDTH;

	-- common constants
	constant C_RECONOS_FAILURE  : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"00000000";
	constant C_RECONOS_SUCCESS  : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"00000001";

	-- commands
	constant OSIF_CMD_THREAD_GET_INIT_DATA  : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A0";
	constant OSIF_CMD_THREAD_DELAY          : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A1"; -- ToDo
	constant OSIF_CMD_THREAD_EXIT           : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A2";
	constant OSIF_CMD_THREAD_YIELD          : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A3"; -- ToDo
	constant OSIF_CMD_THREAD_RESUME         : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A4"; -- ToDo
	constant OSIF_CMD_THREAD_LOAD_STATE     : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A5"; -- ToDo
	constant OSIF_CMD_THREAD_STORE_STATE    : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000A6"; -- ToDo

	constant OSIF_CMD_SEM_POST              : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000B0";
	constant OSIF_CMD_SEM_WAIT              : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000B1";

	constant OSIF_CMD_MUTEX_LOCK            : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000C0";
	constant OSIF_CMD_MUTEX_UNLOCK          : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000C1";
	constant OSIF_CMD_MUTEX_TRYLOCK         : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000C2"; -- Not tested, yet

	constant OSIF_CMD_COND_WAIT             : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000D0"; -- Not tested, yet
	constant OSIF_CMD_COND_SIGNAL           : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000D1"; -- Not tested, yet
	constant OSIF_CMD_COND_BROADCAST        : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000D2"; -- Not tested, yet

	constant OSIF_CMD_RQ_RECEIVE            : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000E0"; -- ToDo
	constant OSIF_CMD_RQ_SEND               : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000E1"; -- ToDo

	constant OSIF_CMD_MBOX_GET              : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000F0";
	constant OSIF_CMD_MBOX_PUT              : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000F1";
	constant OSIF_CMD_MBOX_TRYGET           : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000F2"; -- ToDo
	constant OSIF_CMD_MBOX_TRYPUT           : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"000000F3"; -- ToDo

	constant OSIF_CMD_YIELD_MASK            : std_logic_vector(C_OSIF_WIDTH - 1 downto 0) := X"80000000";


	constant MEMIF_CMD_READ                 : std_logic_vector(C_MEMIF_CMD_WIDTH - 1 downto 0) := X"00";
	constant MEMIF_CMD_WRITE                : std_logic_vector(C_MEMIF_CMD_WIDTH - 1 downto 0) := X"F0";

	-- type definitions for easier handling of signals
	type i_fifo_t is record
		s_data  : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		s_fill  : std_logic_vector(15 downto 0);
		s_empty : std_logic;
		m_rem   : std_logic_vector(15 downto 0);
		m_full  : std_logic;
		s_re    : std_logic;
		m_we    : std_logic;
		step    : integer range 0 to 15;
		void    : std_logic;
	end record;

	type o_fifo_t is record
		s_re    : std_logic;
		m_data  : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		m_we    : std_logic;
		step    : integer range 0 to 15;
		void    : std_logic;
	end record;

	alias i_osif_t is i_fifo_t;
	alias o_osif_t is o_fifo_t;
	
	alias i_memif_t is i_fifo_t;
	alias o_memif_t is o_fifo_t;
	
	type i_ram_t is record
		addr         : std_logic_vector(31 downto 0);
		data         : std_logic_vector(31 downto 0);
		count        : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		remote_addr  : std_logic_vector(31 downto 0);
		remainder    : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		step         : integer range 0 to 15;
	end record;
	
	type o_ram_t is record
		addr         : std_logic_vector(31 downto 0);
		data         : std_logic_vector(31 downto 0);
		we           : std_logic;
		count        : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		remote_addr  : std_logic_vector(31 downto 0);
		remainder    : std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		step         : integer range 0 to 15;
	end record;


	-- setup functions

	-- ONLY FOR INTERNAL USE
	-- Assigns signals to the FIFO record. This function must be called
	-- asynchronously in the main entity including the OS-FSM.
	--
	--   i_fifo  - i_fifo_t record
	--   o_fifo  - o_fifo_t record
	--   s_data  - data signal of slave FIFO
	--   s_fill  - fill signal of slave FIFO
	--   s_empty - empty signal of slave FIFO
	--   m_rem   - remaining signal of master FIFO
	--   m_full  - full signal of master FIFO
	--   s_re    - read signal of slave FIFO
	--   m_data  - data signal of master FIFO
	--   m_we    - write signal of master FIFO
	--
	procedure fifo_setup (
		signal i_fifo   : out i_fifo_t;
		signal o_fifo   : in  o_fifo_t;
		signal s_data   : in  std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		signal s_fill   : in  std_logic_vector(15 downto 0);
		signal s_empty  : in  std_logic;
		signal m_rem    : in  std_logic_vector(15 downto 0);
		signal m_full   : in  std_logic;
		signal s_re     : out std_logic;
		signal m_data   : out std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		signal m_we     : out std_logic
	);
	
	-- ONLY FOR INTERNAL USE
	-- Resets the FIFO signals to a default state.
	--
	--   o_fifo - o_fifo_t
	--
	procedure fifo_reset (
		signal o_fifo  : out o_fifo_t
	);


	-- Assigns signals to the OSIF record. This function must be called
	-- asynchronously in the main entity including the OS-FSM.
	--
	--   i_osif      - i_osif_t record
	--   o_osif      - o_osif_t_record
	--   sw2hw_data  - data signal of OSIF      - OSIF_FIFO_Sw2Hw_Data
	--   sw2hw_fill  - fill signal of OSIF      - OSIF_FIFO_Sw2Hw_Fill
	--   sw2hw_empty - empty signal of OSIF     - OSIF_FIFO_Sw2Hw_Empty
	--   hw2sw_rem   - remaining signal of OSIF - OSIF_FIFO_Hw2Sw_Rem
	--   hw2sw_full  - full signal of OSIF      - OSIF_FIFO_Hw2Sw_Full
	--   sw2hw_re    - read signal of OSIF      - OSIF_FIFO_Sw2Hw_RE
	--   hw2sw_data  - data signal of OSIF      - OSIF_FIFO_Hw2Sw_Data
	--   hw2sw_we    - write signal of OSIF     - OSIF_FIFO_Hw2Sw_WE
	--
	procedure osif_setup (
		signal i_osif       : out i_osif_t;
		signal o_osif       : in  o_osif_t;
		signal sw2hw_data   : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal sw2hw_fill   : in  std_logic_vector(15 downto 0);
		signal sw2hw_empty  : in  std_logic;
		signal hw2sw_rem    : in  std_logic_vector(15 downto 0);
		signal hw2sw_full   : in  std_logic;
		signal sw2hw_re     : out std_logic;
		signal hw2sw_data   : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal hw2sw_we     : out std_logic
	);
	
	-- Resets the OSIF signals to a default state. This function should be called
	-- on reset of the OS-FSM.
	--
	--   o_osif - o_osif_t record
	--
	procedure osif_reset (
		signal o_osif  : out o_osif_t
	);


	-- Assigns signals to the MEMIF record. This function must be called
	-- asynchronously in the main entity including the OS-FSM.
	--
	--   i_memif       - i_memif_t record
	--   o_memif       - o_memif_t record
	--   mem2hwt_data  - data signal of MEMIF      - MEMIF_FIFO_Mem2Hwt_Data
	--   mem2hwt_fill  - fill signal of MEMIF      - MEMIF_FIFO_Mem2Hwt_Fill
	--   mem2hwt_empty - empty signal of MEMIF     - MEMIF_FIFO_Mem2Hwt_Empty
	--   hwt2mem_rem   - remaining signal of MEMIF - MEMIF_FIFO_Hwt2Mem_Rem
	--   hwt2mem_full  - full signal of MEMIF      - MEMIF_FIFO_Hwt2Mem_Full
	--   mem2hwt_re    - read signal of MEMIF      - MEMIF_FIFO_Mem2Hwt_RE
	--   hwt2mem_data  - data signal of MEMIF      - MEMIF_FIFO_Hwt2Mem_Data
	--   hwt2mem_we    - write signal of MEMIF     - MEMIF_FIFO_Hwt2Mem_WE
	--
	procedure memif_setup (
		signal i_memif        : out i_memif_t;
		signal o_memif        : in  o_memif_t;
		signal mem2hwt_data   : in  std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal mem2hwt_fill   : in  std_logic_vector(15 downto 0);
		signal mem2hwt_empty  : in  std_logic;
		signal hwt2mem_rem    : in  std_logic_vector(15 downto 0);
		signal hwt2mem_full   : in  std_logic;
		signal mem2hwt_re     : out std_logic;
		signal hwt2mem_data   : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal hwt2mem_we     : out std_logic
	);
	
	-- Resets the MEMIF signals to a default state. This function should be called
	-- on reset of the OS-FSM.
	--
	--   o_memif - o_memif_t record
	--
	procedure memif_reset (
		signal o_memif  : out o_memif_t
	);
	
	
	-- Assigns signals to the MEMIF record. This function must be called
	-- asynchronously in the main entity including the OS-FSM.
	--
	--   i_ram  - i_ram_t record
	--   o_ram  - o_ram_t record
	--   addr   - address signal of the local ram
	--   we     - write enable signal of the local ram
	--   o_data - output data signal of the local ram
	--   i_data - input data signal of the local ram
	--
	procedure ram_setup (
		signal i_ram   : out i_ram_t;
		signal o_ram   : in  o_ram_t;
		signal addr    : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal we      : out std_logic;
		signal o_data  : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal i_data  : in  std_logic_vector(C_MEMIF_WIDTH - 1 downto 0)
	);
	
	-- Resets the RAM signals to a default state. This function should be called
	-- on reset of the OS-FSM.
	--
	--   o_ram - o_ram_t record
	--
	procedure ram_reset (
		signal o_ram  : out o_ram_t
	);
	
	
	-- fifo access functions

	-- ONLY FOR INTERNAL USE
	--
	-- Resets FIFO signals to a default state (sets read and write flag to '0')
	--
	--   o_fifo - o_fifo_t record
	--
	procedure fifo_default (
		signal o_fifo  : out o_fifo_t
	);

	-- ONLY FOR INTERNAL USE
	--
	-- Reads a single word out of the FIFO and sets o_fifo.step to next_step.
	-- Be aware, that you must set continue if you want to read multiple words
	-- after another.
	--
	--   i_fifo    - i_fifo_t record
	--   o_fifo    - o_fifo_t record
	--   result    - the word read from the FIFO
	--   next_step - the new value of o_fifo.step after the word was read
	--   continue  - boolean value, indicating if the next clock cycle another
	--               read will be performed
	--
	procedure fifo_pull_word (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal result  : out std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		next_step      : integer;
		continue       : boolean
	);
	
	-- ONLY FOR INTERNAL USE
	--
	-- Writes a single word into the FIFO and sets o_fifo.step to next_step.
	--
	--   i_fifo    - i_fifo_t record
	--   o_fifo    - o_fifo_t record
	--   data      - the word that should be written into the FIFO
	--   next_step - the new value of o_fifo.step after the word was written
	--
	procedure fifo_push_word (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		data           : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		next_step      : integer
	);
	
	-- ONLY FOR INTERNAL USE
	--
	-- Reads multiple words from the FIFO into a local ram and sets o_fifo.step to
	-- next_step. This function reads from i_ram.addr and increases this address
	-- appropriately.
	--
	--   i_fifo - i_fifo_t record
	--   o_fifo - o_fifo_t record
	--   i_ram  - i_ram record
	--   o_ram  - o_ram record
	--   count  - number of words to read
	--   next_step - the new value of o_fifo.step after the word was written
	--
	procedure fifo_pull (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		count          : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		next_step      : integer
	);
	
	-- ONLY FOR INTERNAL USE
	--
	-- Writes multiple words from a local ram into the FIFO and sets o_fifo.step to
	-- next_step. This function reads from i_ram.addr and increases this address
	-- appropriately.
	--
	--   i_fifo - i_fifo_t record
	--   o_fifo - o_fifo_t record
	--   i_ram  - i_ram record
	--   o_ram  - o_ram record
	--   count  - number of words to read
	--   next_step - the new value of o_fifo.step after the word was written
	--
	procedure fifo_push (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		count          : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		next_step      : integer
	);
	
	
	-- functions to access osif directly

	-- Reads a single word from the OSIF.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   result - word read from the OSIF
	--   done   - indicates when read finished
	--
	procedure osif_read (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Writes a single word into the OSIF
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   data   - word to write int the OSIF
	--   done   - indicates when write finished
	-- 
	procedure osif_write (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		data           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);


	-- generic osif functions

	-- ONLY FOR INTERNAL USE
	--
	-- Issues a system call with no arguments and a single result.
	--
	--   i_osif  - i_osif_t record
	--   o_osif  - o_osif_t record
	--   call_id - id of the system call
	--   result  - result of the system call
	--   done    - indicates when system call finished
	--
	procedure osif_call_0 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);

	-- ONLY FOR INTERNAL USE
	--
	-- Issues a system call with one argument and a single result.
	--
	--   i_osif  - i_osif_t record
	--   o_osif  - o_osif_t record
	--   call_id - id of the system call
	--   arg0    - argument of the system call
	--   result  - result of the system call
	--   done    - indicates when system call finished
	--
	procedure osif_call_1 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);

	-- ONLY FOR INTERNAL USE
	--
	-- Issues a system call with one arguments and to results.
	--
	--   i_osif  - i_osif_t record
	--   o_osif  - o_osif_t record
	--   call_id - id of the system call
	--   arg0    - argument of the system call
	--   result1 - first result of the system call
	--   result2 - second result of the system call
	--   done    - indicates when system call finished
	--
	procedure osif_call_1_2 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result1 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result2 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);

	-- ONLY FOR INTERNAL USE
	--
	-- Issues a system call with two arguments and a single result.
	--
	--   i_osif  - i_osif_t record
	--   o_osif  - o_osif_t record
	--   call_id - id of the system call
	--   arg0    - first argument of the system call
	--   arg1    - second argument of the system call
	--   result  - result of the system call
	--   done    - indicates when system call finished
	--
	procedure osif_call_2 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg1           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);


	-- osif functions

	-- Yields the hardware thread slots. This causes the scheduler to be called
	-- and might result in an preemtion of the hardware thread. This method alone
	-- does not issue any call but only sets the yield bit for a regular system call.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--
	procedure osif_set_yield (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t
	);

	-- Posts the semaphore specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_sem_post (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);

	-- Waits for the semaphore specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_sem_wait (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Locks the mutex specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_mutex_lock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Unlocks the mutex specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_mutex_unlock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Tries to lock the mutex specified by handle and returns if successful or not.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_mutex_trylock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Waits for the condition variable specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_cond_wait (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		cond_handle    : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		mutex_handle   : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Signals a single thread waiting on the condition variable specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_cond_signal (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Signals all threads waiting on the condition variable specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_cond_broadcast (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Puts a single word into the mbox specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   word   - word to write into the mbox
	--   result - result of the osif call
	--   done   - indicates when call finished
	--
	procedure osif_mbox_put (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		word           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Reads a single word from the mbox specified by handle.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   result - word read from the mbox
	--   done   - indicates when call finished
	--
	procedure osif_mbox_get (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Tries to put a single word into the mbox specified by handle but does not
	-- blocks until the mbox gets populated.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   handle - index representing the resource in the resource array
	--   word   - word to write into the mbox
	--   result - indicates if word was written into the mbox
	--   done   - indicates when call finished
	--
	procedure osif_mbox_tryput (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		word           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Tries to read a single word from the mbox specified by handle but does not
	-- blocks until the mbox gets free.
	--
	--   i_osif  - i_osif_t record
	--   o_osif  - o_osif_t record
	--   handle  - index representing the resource in the resource array
	--   result1 - word read from the mbox
	--   result2 - indicates if a word was read from the mbox
	--   done    - indicates when call finished
	--
	procedure osif_mbox_tryget (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result1 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result2 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- NOT IMPLEMENTED YET
	procedure osif_rq_receive (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		size           : in  std_logic_vector(31 downto 0);
		addr           : in  std_logic_vector(31 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- NOT IMPLEMENTED YET
	procedure osif_rq_send (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		size           : in  std_logic_vector(31 downto 0);
		addr           : in  std_logic_vector(31 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Gets the pointer to the initialization data of the hardware thread
	-- specified by reconos_hwt_setinitdata.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--   result - the pointer to the initialization data
	--   done   - indicated when call finished
	--
	procedure osif_get_init_data (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	);
	
	-- Terminates the current hardware thread and the delegate in software.
	--
	--   i_osif - i_osif_t record
	--   o_osif - o_osif_t record
	--
	procedure osif_thread_exit (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t
	);


	-- memif functions

	-- Flushes the MEMIF-FIFOs to guarantee that no more words are
	-- waiting to be written into the memory. Be aware, that this function only
	-- checks the words in the MEMIF-FIFOs but does not guarantee that even the last
	-- word was written into the memory.
	--
	--   i_memif - i_memif_t record
	--   o_memif - o_memif_t record
	--   done    - indicates that the call finished
	--
	procedure memif_flush (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		variable done  : out boolean
	);

	-- Writes a single word into the main memory.
	--
	--   i_memif - i_memif_t record
	--   o_memif - o_memif_t record
	--   addr    - address of the main memory to write
	--   data    - word to write into the main memory
	--   done    - indicates that the call finished
	--
	procedure memif_write_word (
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		addr            : in  std_logic_vector(31 downto 0);
		data            : in  std_logic_vector(31 downto 0);
		variable done   : out boolean
	);
	
	-- Reads a single word from the main memory.
	--
	--   i_memif - i_memif_t record
	--   o_memif - o_memif_t record
	--   addr    - address of the main memory to read from
	--   data    - word read from the main memory
	--   done    - indicates that the call finished
	--
	procedure memif_read_word (
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		addr            : in  std_logic_vector(31 downto 0);
		signal data     : out std_logic_vector(31 downto 0);
		variable done   : out boolean
	);

	-- Writes several words from the local ram into the main memory.
	--
	--   i_ram    - i_ram_t record
	--   o_ram    - o_ram_t record
	--   i_memif  - i_memif_t record
	--   o_memif  - o_memif_t record
	--   src_addr - start address to read from the local ram
	--   dst_addr - start address to write into the main memory
	--   len      - number of writes to transmit
	--   done     - indicates that the call finished
	--
	procedure memif_write (
		signal i_ram    : in  i_ram_t;
		signal o_ram    : out o_ram_t;
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		src_addr        : in  std_logic_vector(31 downto 0);
		dst_addr        : in  std_logic_vector(31 downto 0);
		len             : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable done   : out boolean
	);
	
	-- Writes several words from the local ram into the main memory.
	--
	--   i_ram    - i_ram_t record
	--   o_ram    - o_ram_t record
	--   i_memif  - i_memif_t record
	--   o_memif  - o_memif_t record
	--   src_addr - start address to read from the main memory
	--   dst_addr - start address to write into the local ram
	--   len      - number of writes to transmit
	--   done     - indicates that the call finished
	--
	procedure memif_read (
		signal i_ram    : in  i_ram_t;
		signal o_ram    : out o_ram_t;
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		src_addr        : in  std_logic_vector(31 downto 0);
		dst_addr        : in  std_logic_vector(31 downto 0);
		len             : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable done   : out boolean
	);
	
end package reconos_pkg;

package body reconos_pkg is

	procedure fifo_setup (
		signal i_fifo   : out i_fifo_t;
		signal o_fifo   : in  o_fifo_t;
		signal s_data   : in  std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		signal s_fill   : in  std_logic_vector(15 downto 0);
		signal s_empty  : in  std_logic;
		signal m_rem    : in  std_logic_vector(15 downto 0);
		signal m_full   : in  std_logic;
		signal s_re     : out std_logic;
		signal m_data   : out std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		signal m_we     : out std_logic
	) is begin
		i_fifo.step <= o_fifo.step;
		
		i_fifo.s_data  <= s_data;
		i_fifo.s_fill  <= s_fill;
		i_fifo.s_empty <= s_empty;
		i_fifo.m_rem   <= m_rem;
		i_fifo.m_full  <= m_full;
		
		s_re    <= o_fifo.s_re;
		m_data  <= o_fifo.m_data;
		m_we    <= o_fifo.m_we;
		
		i_fifo.s_re <= o_fifo.s_re;
		i_fifo.m_we <= o_fifo.m_we;

		i_fifo.void <= o_fifo.void;
	end procedure fifo_setup;
	
	procedure fifo_reset (
		signal o_fifo  : out o_fifo_t
	) is begin
		o_fifo.step <= 0;
		o_fifo.m_we <= '0';
		o_fifo.s_re <= '0';
		o_fifo.m_data <= (others => '0');
		o_fifo.void <= '0';
	end procedure fifo_reset;


	procedure osif_setup (
		signal i_osif       : out i_osif_t;
		signal o_osif       : in  o_osif_t;
		signal sw2hw_data   : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal sw2hw_fill   : in  std_logic_vector(15 downto 0);
		signal sw2hw_empty  : in  std_logic;
		signal hw2sw_rem    : in  std_logic_vector(15 downto 0);
		signal hw2sw_full   : in  std_logic;
		signal sw2hw_re     : out std_logic;
		signal hw2sw_data   : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal hw2sw_we     : out std_logic
	) is begin
		fifo_setup(i_osif, o_osif, sw2hw_data, sw2hw_fill, sw2hw_empty,
		           hw2sw_rem, hw2sw_full, sw2hw_re, hw2sw_data, hw2sw_we);
	end procedure osif_setup;

	procedure osif_reset (
		signal o_osif  : out o_osif_t
	) is begin
		fifo_reset(o_osif);
	end procedure osif_reset;


	procedure memif_setup (
		signal i_memif        : out i_memif_t;
		signal o_memif        : in  o_memif_t;
		signal mem2hwt_data   : in  std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal mem2hwt_fill   : in  std_logic_vector(15 downto 0);
		signal mem2hwt_empty  : in  std_logic;
		signal hwt2mem_rem    : in  std_logic_vector(15 downto 0);
		signal hwt2mem_full   : in  std_logic;
		signal mem2hwt_re     : out std_logic;
		signal hwt2mem_data   : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal hwt2mem_we     : out std_logic
	) is begin
		fifo_setup(i_memif, o_memif, mem2hwt_data, mem2hwt_fill, mem2hwt_empty,
		           hwt2mem_rem, hwt2mem_full, mem2hwt_re, hwt2mem_data, hwt2mem_we);
	end procedure memif_setup;
	
	procedure memif_reset (
		signal o_memif  : out o_memif_t
	) is begin
		fifo_reset(o_memif);
	end procedure memif_reset;


	procedure ram_setup (
		signal i_ram   : out i_ram_t;
		signal o_ram   : in  o_ram_t;
		signal addr    : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal we      : out std_logic;
		signal o_data  : out std_logic_vector(C_MEMIF_WIDTH - 1 downto 0);
		signal i_data  : in  std_logic_vector(C_MEMIF_WIDTH - 1 downto 0)
	) is begin
		i_ram.data <= i_data;

		addr   <= o_ram.addr;
		we     <= o_ram.we;
		o_data <= o_ram.data;

		i_ram.addr  <= o_ram.addr;
		i_ram.count <= o_ram.count;
		i_ram.step  <= o_ram.step;
		i_ram.remote_addr <= o_ram.remote_addr;
		i_ram.remainder <= o_ram.remainder;
	end procedure ram_setup;
	
	procedure ram_reset (
		signal o_ram  : out o_ram_t
	) is begin
		o_ram.we    <= '0';
		o_ram.addr  <= (others => '0');
		o_ram.data  <= (others => '0');
		o_ram.count <= (others => '0');
		o_ram.step  <= 0;

		o_ram.remote_addr <= (others => '0');
		o_ram.remainder   <= (others => '0');
	end procedure ram_reset;


	-- fifo access functions
	procedure fifo_default (
		signal o_fifo  : out o_fifo_t
	) is begin
		o_fifo.s_re <= '0';
		o_fifo.m_we <= '0';
	end procedure fifo_default;

	procedure fifo_pull_word (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal result  : out std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		next_step      : integer;
		continue       : boolean
	) is begin
		-- set re, if FIFO is empty this is no problem
		--if i_fifo.s_empty = '0' then
		o_fifo.s_re <= '1';
		--end if;
		
		-- read data one clock cycle after setting the re
		-- and only if FIFO not empty
		if i_fifo.s_empty = '0' and i_fifo.s_re = '1' then
			result <= i_fifo.s_data;
			o_fifo.step <= next_step;
			
			-- stop reading if continue is false (last read)
			if not continue then
				o_fifo.s_re <= '0';
			end if;
		end if;
	end procedure fifo_pull_word;

	procedure fifo_push_word (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		data           : std_logic_vector(C_FIFO_WIDTH - 1 downto 0);
		next_step      : integer
	) is begin
		o_fifo.m_data <= data;

		if     i_fifo.m_full = '0'
		   and (i_fifo.m_we = '0' or or_reduce(i_fifo.m_rem) = '1') then
			-- write data into FIFO if
			--       FIFO is not full
			--   and no previous write or more than one word free
			o_fifo.m_we <= '1';
			o_fifo.step <= next_step;
		end if;
	end procedure fifo_push_word;

	procedure fifo_pull (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		count          : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		next_step      : integer
	) is begin
		case i_ram.step is
			when 0 =>
				-- because of the FIFO implementation used
				-- we can keep the RE high and check the empty flag
				o_fifo.s_re <= '1';
				-- set address one word before actual address
				--o_ram.addr <= i_ram.addr - 1;
				o_ram.step <= 1;

				o_ram.count <= (others => '0');
			when 1 =>
				o_fifo.s_re <= '1';

				if i_fifo.s_empty = '0' then
					o_ram.we <= '1';
					o_ram.data <= i_fifo.s_data;
					
					if or_reduce(i_ram.count) = '0' then
						o_ram.addr <= i_ram.addr;
					else
						o_ram.addr <= i_ram.addr + 1;
					end if;

					o_ram.count <= i_ram.count + 1;

					if i_ram.count = count - 1 then
						o_ram.step <= 2;
					end if;
				end if;
			when others =>
				o_ram.we <= '0';
				o_ram.step <= 0;
				o_fifo.s_re <= '0';
				o_fifo.step <= next_step;
		end case;
	end procedure fifo_pull;
	
	procedure fifo_push (
		signal i_fifo  : in  i_fifo_t;
		signal o_fifo  : out o_fifo_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		count          : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 3 downto 0);
		next_step      : integer
	) is begin
		case i_ram.step is
			when 0 =>
				-- waiting for FIFO to become empty enough
				-- this is not so nice, but should be now major drawback
				-- since the FIFOs are empty most of the time
				if i_fifo.m_full = '0' and i_fifo.m_rem >= count - 1 then
					o_ram.count <= (others => '0');
					o_ram.addr <= i_ram.addr + 1;

					o_ram.step <= 1;
				end if;
			when 1 =>
				o_fifo.m_we <= '1';
				o_fifo.m_data <= i_ram.data;

				o_ram.addr <= i_ram.addr + 1;
				o_ram.count <= i_ram.count + 1;

				if i_ram.count = count - 1 then
					o_ram.step <= 2;
				end if;
			when others =>
				o_ram.addr <= i_ram.addr - 2;
				o_ram.step <= 0;
				o_fifo.m_we <= '0';
				o_fifo.step <= next_step;
		end case;
	end procedure fifo_push;


	procedure osif_read (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);
		
		case i_osif.step is
			when 0 =>
				fifo_pull_word(i_osif, o_osif, result, 1, False);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_read;
	
	procedure osif_write (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		data           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				fifo_push_word(i_osif, o_osif, data, 1);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_write;


	procedure osif_call_0 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				-- wait for yield bit
				o_osif.step <= 1;
			when 1 =>
				-- push call_id into FIFO
				if i_osif.void = '1' then
					fifo_push_word(i_osif, o_osif, call_id or OSIF_CMD_YIELD_MASK, 2);
				else
					fifo_push_word(i_osif, o_osif, call_id, 2);
				end if;
			when 2 =>
				fifo_pull_word(i_osif, o_osif, result, 3, False);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_call_0;

	procedure osif_call_1 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				-- wait for yield bit
				o_osif.step <= 1;
			when 1 =>
				-- push call_id into FIFO
				if i_osif.void = '1' then
					fifo_push_word(i_osif, o_osif, call_id or OSIF_CMD_YIELD_MASK, 2);
				else
					fifo_push_word(i_osif, o_osif, call_id, 2);
				end if;
			when 2 =>
				-- push arg0 into FIFO
				fifo_push_word(i_osif, o_osif, arg0, 3);
			when 3 =>
				fifo_pull_word(i_osif, o_osif, result, 4, False);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_call_1;

	procedure osif_call_1_2 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result1 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result2 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				-- wait for yield bit
				o_osif.step <= 1;
			when 1 =>
				-- push call_id into FIFO
				if i_osif.void = '1' then
					fifo_push_word(i_osif, o_osif, call_id or OSIF_CMD_YIELD_MASK, 2);
				else
					fifo_push_word(i_osif, o_osif, call_id, 2);
				end if;
			when 2 =>
				-- push arg0 into FIFO
				fifo_push_word(i_osif, o_osif, arg0, 3);
			when 3 =>
				fifo_pull_word(i_osif, o_osif, result1, 4, True);
			when 4 =>
				fifo_pull_word(i_osif, o_osif, result2, 5, False);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_call_1_2;

	procedure osif_call_2 (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		call_id        : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg0           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		arg1           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				-- wait for yield bit
				o_osif.step <= 1;
			when 1 =>
				-- push call_id into FIFO
				if i_osif.void = '1' then
					fifo_push_word(i_osif, o_osif, call_id or OSIF_CMD_YIELD_MASK, 2);
				else
					fifo_push_word(i_osif, o_osif, call_id, 2);
				end if;
			when 2 =>
				-- push arg0 into FIFO
				fifo_push_word(i_osif, o_osif, arg0, 3);
			when 3 =>
				-- push arg1 into FIFO
				fifo_push_word(i_osif, o_osif, arg1, 4);
			when 4 =>
				fifo_pull_word(i_osif, o_osif, result, 5, False);
			when others =>
				done := True;
				o_osif.void <= '0';
				o_osif.step <= 0;
		end case;
	end procedure osif_call_2;


	-- osif functions
	procedure osif_set_yield (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t
	) is begin
		o_osif.void <= '1';
	end procedure osif_set_yield;

	procedure osif_sem_post (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_SEM_POST, handle, result, done);
	end procedure osif_sem_post;

	procedure osif_sem_wait (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_SEM_WAIT, handle, result, done);
	end procedure osif_sem_wait;
	
	procedure osif_mutex_lock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_MUTEX_LOCK, handle, result, done);
	end procedure osif_mutex_lock;
	
	procedure osif_mutex_unlock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_MUTEX_UNLOCK, handle, result, done);
	end procedure osif_mutex_unlock;
	
	procedure osif_mutex_trylock (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_MUTEX_TRYLOCK, handle, result, done);
	end procedure osif_mutex_trylock;
	
	procedure osif_cond_wait (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		cond_handle    : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		mutex_handle   : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_2(i_osif, o_osif, OSIF_CMD_COND_WAIT, cond_handle, mutex_handle, result, done);
	end procedure osif_cond_wait;
	
	procedure osif_cond_signal (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_COND_SIGNAL, handle, result, done);
	end procedure osif_cond_signal;
	
	procedure osif_cond_broadcast (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_COND_BROADCAST, handle, result, done);
	end procedure osif_cond_broadcast;
	
	procedure osif_mbox_put (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		word           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_2(i_osif, o_osif, OSIF_CMD_MBOX_PUT, handle, word, result, done);
	end procedure osif_mbox_put;
	
	procedure osif_mbox_get (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1(i_osif, o_osif, OSIF_CMD_MBOX_GET, handle, result, done);
	end procedure osif_mbox_get;

	procedure osif_mbox_tryput (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		word           : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_2(i_osif, o_osif, OSIF_CMD_MBOX_TRYPUT, handle, word, result, done);
	end procedure osif_mbox_tryput;
	
	procedure osif_mbox_tryget (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result1 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		signal result2 : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_1_2(i_osif, o_osif, OSIF_CMD_MBOX_TRYGET, handle, result1, result2, done);
	end procedure osif_mbox_tryget;
	
	procedure osif_rq_receive (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		size           : in  std_logic_vector(31 downto 0);
		addr           : in  std_logic_vector(31 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- not implemented yet
	end procedure osif_rq_receive;
	
	procedure osif_rq_send (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal i_ram   : in  i_ram_t;
		signal o_ram   : out o_ram_t;
		handle         : in  std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		size           : in  std_logic_vector(31 downto 0);
		addr           : in  std_logic_vector(31 downto 0);
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		-- not implemented yet
	end procedure osif_rq_send;
	
	procedure osif_get_init_data (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t;
		signal result  : out std_logic_vector(C_OSIF_WIDTH - 1 downto 0);
		variable done  : out boolean
	) is begin
		osif_call_0(i_osif, o_osif, OSIF_CMD_THREAD_GET_INIT_DATA, result, done);
	end procedure osif_get_init_data;
	
	procedure osif_thread_exit (
		signal i_osif  : in  i_osif_t;
		signal o_osif  : out o_osif_t
	) is begin
		fifo_default(o_osif);

		case i_osif.step is
			when 0 =>
				-- push THREAD_EXIT
				fifo_push_word(i_osif, o_osif, OSIF_CMD_THREAD_EXIT, 1);
			when others =>
				-- never return from this loop
				o_osif.step <= 2;
		end case;
	end procedure osif_thread_exit;


	--memif functions
	procedure memif_flush (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		variable done  : out boolean
	) is begin
		done := False;
		if i_memif.m_rem = X"007F" and i_memif.m_full = '0' then
			done := True;
		end if;
	end procedure memif_flush;

	procedure memif_write_word (
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		addr            : in  std_logic_vector(31 downto 0);
		data            : in  std_logic_vector(31 downto 0);
		variable done   : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_memif);

		case i_memif.step is
			when 0 =>
				fifo_push_word(i_memif, o_memif, MEMIF_CMD_WRITE & X"000004", 1);
			when 1 =>
				fifo_push_word(i_memif, o_memif, addr(31 downto 2) & "00", 2);
			when 2 =>
				fifo_push_word(i_memif, o_memif, data, 3);
			when others =>
				done := True;
				o_memif.step <= 0;
		end case;
	end procedure memif_write_word;
	
	procedure memif_read_word (
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		addr             : in  std_logic_vector(31 downto 0);
		signal data     : out  std_logic_vector(31 downto 0);
		variable done   : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_memif);

		case i_memif.step is
			when 0 =>
				fifo_push_word(i_memif, o_memif, MEMIF_CMD_READ & X"000004", 1);
			when 1 =>
				fifo_push_word(i_memif, o_memif, addr(31 downto 2) & "00", 2);
			when 2 =>
				fifo_pull_word(i_memif, o_memif, data, 3, False);
			when others =>
				done := True;
				o_memif.step <= 0;
		end case;
	end procedure memif_read_word;

	procedure memif_write (
		signal i_ram    : in  i_ram_t;
		signal o_ram    : out o_ram_t;
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		src_addr        : in  std_logic_vector(31 downto 0);
		dst_addr        : in  std_logic_vector(31 downto 0);
		len             : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable done   : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_memif);

		case i_memif.step is
			when 0 =>
				o_ram.addr <= src_addr;
				o_ram.remainder <= len(C_MEMIF_LENGTH_WIDTH - 1 downto 2);
				o_ram.remote_addr <= dst_addr(31 downto 2) & "00";

				o_memif.step <= 1;

			when 1 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					fifo_push_word(i_memif, o_memif, MEMIF_CMD_WRITE & CONV_STD_LOGIC_VECTOR(C_CHUNK_SIZE_BYTES, C_MEMIF_LENGTH_WIDTH), 2);
				else
					fifo_push_word(i_memif, o_memif, MEMIF_CMD_WRITE & i_ram.remainder & "00", 2);
				end if;

			when 2 =>
				fifo_push_word(i_memif, o_memif, i_ram.remote_addr, 3);

			when 3 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					fifo_push(i_memif, o_memif, i_ram, o_ram, CONV_STD_LOGIC_VECTOR(C_CHUNK_SIZE, C_MEMIF_LENGTH_WIDTH - 2), 4);
				else
					fifo_push(i_memif, o_memif, i_ram, o_ram, i_ram.remainder, 4);
				end if;

			when 4 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					-- o_ram.addr is incremented by fifo_push
					o_ram.remainder <= i_ram.remainder - C_CHUNK_SIZE;
					o_ram.remote_addr <= i_ram.remote_addr + C_CHUNK_SIZE_BYTES;
					o_ram.addr <= i_ram.addr + 1;
					o_memif.step <= 1;
				else
					o_memif.step <= 5;
				end if;

			when others =>
				done := True;
				o_memif.step <= 0;
		end case;
	end procedure memif_write;

	procedure memif_read (
		signal i_ram    : in  i_ram_t;
		signal o_ram    : out o_ram_t;
		signal i_memif  : in  i_memif_t;
		signal o_memif  : out o_memif_t;
		src_addr        : in  std_logic_vector(31 downto 0);
		dst_addr        : in  std_logic_vector(31 downto 0);
		len             : in  std_logic_vector(C_MEMIF_LENGTH_WIDTH - 1 downto 0);
		variable done   : out boolean
	) is begin
		-- set done to false, so the user does not have to care about it
		done := False;
		fifo_default(o_memif);

		case i_memif.step is
			when 0 =>
				o_ram.addr <= dst_addr;
				o_ram.remainder <= len(C_MEMIF_LENGTH_WIDTH - 1 downto 2);
				o_ram.remote_addr <= src_addr(31 downto 2) & "00";

				o_memif.step <= 1;

			when 1 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					fifo_push_word(i_memif, o_memif, MEMIF_CMD_READ & CONV_STD_LOGIC_VECTOR(C_CHUNK_SIZE_BYTES, C_MEMIF_LENGTH_WIDTH), 2);
				else
					fifo_push_word(i_memif, o_memif, MEMIF_CMD_READ & i_ram.remainder & "00", 2);
				end if;

			when 2 =>
				fifo_push_word(i_memif, o_memif, i_ram.remote_addr, 3);

			when 3 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					fifo_pull(i_memif, o_memif, i_ram, o_ram, CONV_STD_LOGIC_VECTOR(C_CHUNK_SIZE, C_MEMIF_LENGTH_WIDTH - 2), 4);
				else
					fifo_pull(i_memif, o_memif, i_ram, o_ram, i_ram.remainder, 4);
				end if;

			when 4 =>
				if i_ram.remainder > C_CHUNK_SIZE then
					-- o_ram.addr is incremented by fifo_push
					o_ram.remainder <= i_ram.remainder - C_CHUNK_SIZE;
					o_ram.remote_addr <= i_ram.remote_addr + C_CHUNK_SIZE_BYTES;
					o_ram.addr <= i_ram.addr + 1;
					o_memif.step <= 1;
				else
					o_memif.step <= 5;
				end if;

			when others =>
				done := True;
				o_memif.step <= 0;
		end case;
	end procedure memif_read;
	
end package body reconos_pkg;
