--
-- \file reconos_pkg.vhd
--
-- ReconOS package
--
-- Contains type definitions and functions for hardware OS services in VHDL
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       27.06.2006
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--
-- Major changes
-- 27.06.2006  Enno Luebbers        File created
-- 30.06.2006  Enno Luebbers        added shared memory data types
-- 17.07.2006  Enno Luebbers        merged osif and shm interfaces
-- 18.07.2006  Enno Luebbers        implemented shared memory reads
-- 03.08.2006  Enno Luebbers        Added commands for shared memory
--                                  initialization (PLB busmaster)
-- 04.07.2007  Enno Luebbers        Added support for multi-cycle
--                                  commands, tidied code (command_decoder)
-- 10.07.2007  Enno Luebbers        Added support for auxiliary thread "data"
-- 11.07.2007  Enno Luebbers        Added support for mutexes
-- xx.07.2007  Enno Luebbers        Added support for condition variables
-- xx.09.2007  Enno Luebbers        added support for mailboxes
-- 04.10.2007  Enno Luebbers        added support for local mailboxes
-- 09.02.2008  Enno Luebbers        implemented thread_exit() call
-- 19.04.2008  Enno Luebbers        added handshaking between command_decoder
--                                  and HW thread
-- 04.08.2008  Andreas Agne         implemented mq send and receive functions
-- 22.08.2010  Andreas Agne         added MMU related command codes
--*************************************************************************/

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package reconos_pkg is
	
	constant C_FSL_WIDTH      : natural := 32;
	
	-- common constants
	constant C_RECONOS_FAILURE : std_logic_vector(0 to C_FSL_WIDTH-1) := X"00000000";
	constant C_RECONOS_SUCCESS : std_logic_vector(0 to C_FSL_WIDTH-1) := X"00000001";
	
	---------------------------------------------------
	-- task2os commands
	---------------------------------------------------
	
	constant OSIF_CMD_SEM_POST : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000B0";
	constant OSIF_CMD_SEM_WAIT : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000B1";
	
	constant OSIF_CMD_MUTEX_LOCK    : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000C0";
	constant OSIF_CMD_MUTEX_UNLOCK  : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000C1";
	constant OSIF_CMD_MUTEX_TRYLOCK : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000C2";
	
	constant OSIF_CMD_COND_WAIT      : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000D0";
	constant OSIF_CMD_COND_SIGNAL    : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000D1";
	constant OSIF_CMD_COND_BROADCAST : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000D2";
	
	constant OSIF_CMD_MBOX_PUT : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000F1";
	constant OSIF_CMD_MBOX_GET : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000F0";

	constant OSIF_CMD_THREAD_GET_INIT_DATA : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000A0";
	constant OSIF_CMD_THREAD_EXIT          : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000A2";	
	
	constant MEMIF_CMD_READ    : std_logic_vector(7 downto 0) := X"00";
	constant MEMIF_CMD_WRITE   : std_logic_vector(7 downto 0) := X"80";
	
	-- generic OSIF (and FSL) interface procedures and functions
	
	type i_osif_t is record
		clk             : std_logic;
		rst             : std_logic;
		fsl2hwt_data   : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		fsl2hwt_exists : std_logic;
		fsl2hwt_full   : std_logic;
		hwt2fsl_reading : std_logic;
		step            : integer range 0 to 15;
	end record;

	type o_osif_t is record
		hwt2fsl_data    : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		hwt2fsl_reading : std_logic;
		hwt2fsl_writing : std_logic;
		step           : integer range 0 to 15;
	end record;

	alias i_fsl_t is i_osif_t;
	alias o_fsl_t is o_osif_t;	
	
	
	type i_memif_t is record
		clk : std_logic;
		s_data : std_logic_vector(31 downto 0);
		s_fill : std_logic_vector(15 downto 0);
		m_remainder : std_logic_vector(15 downto 0);
		step : integer range 0 to 15;
	end record;
	
	type o_memif_t is record
		s_rd : std_logic;
		m_data : std_logic_vector(31 downto 0);
		m_wr : std_logic;
		step : integer range 0 to 15;
	end record;
	
	-- set up OSIF interface. must be called in architecture body.
	procedure osif_setup (
		signal i_osif          : out  i_osif_t;
		signal o_osif          : in o_osif_t;
		signal clk             : in std_logic;
		signal rst             : in std_logic;
		signal fsl2hwt_data    : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal fsl2hwt_exists  : in std_logic;
		signal fsl2hwt_full    : in std_logic;
		signal hwt2fsl_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2fsl_reading : out std_logic;
		signal hwt2fsl_writing : out std_logic;
		signal hwt2fsl_ctrl    : out std_logic
	);
	
	procedure fsl_setup (
		signal i_fsl           : out  i_fsl_t;
		signal o_fsl           : in o_fsl_t;
		signal clk             : in std_logic;
		signal rst             : in std_logic;
		signal fsl2hwt_data    : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal fsl2hwt_exists  : in std_logic;
		signal fsl2hwt_full    : in std_logic;
		signal hwt2fsl_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2fsl_reading : out std_logic;
		signal hwt2fsl_writing : out std_logic;
		signal hwt2fsl_ctrl    : out std_logic
	);
	
	-- push next word into FSL fifo and check whether last push was successfull
	-- if not, go back and repeat last state. For the first word: prev_step == current step
	procedure fsl_push (
		signal i_fsl      : in  i_fsl_t;
		signal o_fsl      : out o_fsl_t;
		data              : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		prev_step         : integer;
		next_step         : integer
	);
	
	-- check whether last push was successfull. if not, go back to previous step
	procedure fsl_push_finish (
		signal i_fsl      : in  i_fsl_t;
		signal o_fsl      : out o_fsl_t;
		next_step         : integer
	);

	-- pull word from fifo. set continue to True when next step pulls next word
	procedure fsl_pull (
		signal i_fsl      : in  i_fsl_t;
		signal o_fsl      : out o_fsl_t;
		signal result     : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		next_step         : integer;
		continue          : boolean
	);
	
	procedure fsl_read_word (
		signal i_fsl  : in  i_fsl_t;
		signal o_fsl  : out o_fsl_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	procedure fsl_write_word (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		signal data   : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);

	-- reset FLS interface
	procedure fsl_reset(signal o_fsl : out o_fsl_t);
		
	
	-- OS interface functions and procedures
	
	-- generic function call with 1 argument
	procedure osif_call_1(
		signal i_osif     : in  i_osif_t;
		signal o_osif     : out o_osif_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);

	-- generic function call with 2 arguments
	procedure osif_call_2(
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg1          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);


	-- post semaphore
	procedure osif_sem_post (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- wait for semaphore
	procedure osif_sem_wait (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- mutex lock
	procedure osif_mutex_lock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- mutex unlock
	procedure osif_mutex_unlock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);	
	
	-- mutex trylock
	procedure osif_mutex_trylock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- condition variable wait
	procedure osif_cond_wait (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		cond_handle   : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		mutex_handle  : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- condition variable signal
	procedure osif_cond_signal (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);	
	
	-- condition variable broadcast
	procedure osif_cond_broadcast (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- put word into mbox
	procedure osif_mbox_put (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		word          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- read word from mbox
	procedure osif_mbox_get (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- get_init_data
	procedure osif_get_init_data (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	-- thread_exit
	procedure osif_thread_exit (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t
	);
	
	-- see fsl_reset()
	procedure osif_reset(
		signal o_osif : out o_osif_t
	);

	-- Memory interface procedures and functions
	-- Memory access procedures use the packet based protocol implemented by the xps_mem core
	
	-- see fsl_setup()

	procedure memif_setup (
		signal i_memif : out i_memif_t;
		signal o_memif : in  o_memif_t;
		signal clk   : in std_logic;
		signal s_clk : out std_logic;
		signal s_data : in std_logic_vector(31 downto 0);
		signal s_fill : in std_logic_vector(15 downto 0);
		signal s_rd : out std_logic;
		signal m_clk : out std_logic;
		signal m_data : out std_logic_vector(31 downto 0);
		signal m_remainder : in std_logic_vector(15 downto 0);
		signal m_wr : out std_logic
	);
	
	procedure memif_reset(signal o_memif : out o_memif_t);
	
	procedure memif_write (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in std_logic_vector(31 downto 0);
		data  : in std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read_debug (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read_request (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	);

	procedure memif_write_request (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	);

	procedure memif_fifo_pull (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		signal data : out std_logic_vector(31 downto 0);
		variable done : out boolean
	);

	procedure memif_fifo_push (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		signal data : in std_logic_vector(31 downto 0);
		variable done : out boolean
	);


end reconos_pkg;

package body reconos_pkg is
	
	procedure osif_setup (
		signal i_osif : out  i_osif_t;
		signal o_osif : in   o_osif_t;
		signal clk  : in std_logic;
		signal rst  : in std_logic;
		signal fsl2hwt_data     : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal fsl2hwt_exists   : in std_logic;
		signal fsl2hwt_full     : in std_logic;
		signal hwt2fsl_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2fsl_reading : out std_logic;
		signal hwt2fsl_writing : out std_logic;
		signal hwt2fsl_ctrl    : out std_logic
		
	) is begin
		i_osif.step <= o_osif.step;
		i_osif.clk <= clk;
		i_osif.rst <= rst;
		i_osif.fsl2hwt_data <= fsl2hwt_data;
		i_osif.fsl2hwt_exists <= fsl2hwt_exists;
		i_osif.fsl2hwt_full <= fsl2hwt_full;
		i_osif.hwt2fsl_reading <= o_osif.hwt2fsl_reading;
		hwt2fsl_data <= o_osif.hwt2fsl_data;
		hwt2fsl_reading <= o_osif.hwt2fsl_reading;
		hwt2fsl_writing <= o_osif.hwt2fsl_writing and not fsl2hwt_full; -- this is important: writing must change asynchronously!
		hwt2fsl_ctrl    <= '0';
	end procedure;
	
	procedure fsl_setup (
		signal i_fsl : out  i_fsl_t;
		signal o_fsl : in   o_fsl_t;
		signal clk  : in std_logic;
		signal rst  : in std_logic;
		signal fsl2hwt_data     : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal fsl2hwt_exists   : in std_logic;
		signal fsl2hwt_full     : in std_logic;
		signal hwt2fsl_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2fsl_reading : out std_logic;
		signal hwt2fsl_writing : out std_logic;
		signal hwt2fsl_ctrl    : out std_logic
		
	) is begin
		osif_setup(i_fsl, o_fsl, clk, rst, fsl2hwt_data, fsl2hwt_exists, fsl2hwt_full, hwt2fsl_data, hwt2fsl_reading, hwt2fsl_writing, hwt2fsl_ctrl);
	end procedure;
	
	procedure fsl_push (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		data           : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		prev_step      : integer;
		next_step      : integer
	) is begin
		o_fsl.hwt2fsl_data <= data;
		if i_fsl.fsl2hwt_full = '0' then
			o_fsl.hwt2fsl_writing <= '1';
			o_fsl.step <= next_step;
		else
			o_fsl.step <= prev_step;
		end if;
             end procedure;
	
	procedure fsl_push_finish (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		next_step      : integer
	) is begin
		if i_fsl.fsl2hwt_full = '1' then
			o_fsl.hwt2fsl_writing <= '1';
		else
			o_fsl.step <= next_step;
		end if;
        end procedure;
	
	procedure fsl_pull (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		signal result  : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		next_step      : integer;
		continue       : boolean
	) is
	begin
		if i_fsl.fsl2hwt_exists = '1' then
			o_fsl.hwt2fsl_reading <= '1';
		end if;
		if i_fsl.fsl2hwt_exists = '1' and i_fsl.hwt2fsl_reading = '1' then
			result <= i_fsl.fsl2hwt_data;
			o_fsl.step <= next_step;
			if not continue then
				o_fsl.hwt2fsl_reading <= '0';
			end if;
		end if;
        end procedure;
	
	procedure fsl_reset(
		signal o_fsl   : out o_fsl_t
	) is begin
		o_fsl.step  <= 0;
		o_fsl.hwt2fsl_reading <= '0';
		o_fsl.hwt2fsl_writing <= '0';
		o_fsl.hwt2fsl_data <= (others => '0');
	end procedure;
	
	procedure fsl_default (
		signal o_fsl   : out o_fsl_t
	) is begin
		o_fsl.hwt2fsl_reading <= '0';
		o_fsl.hwt2fsl_writing <= '0';
	end procedure;

	procedure fsl_read_word (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(o_fsl);
		case i_fsl.step is
			when 0 =>
				fsl_pull(i_fsl,o_fsl,result,1,False);
			when others =>
				done := True;
				o_fsl.step <= 0;
		end case;
        end procedure;
	
	procedure fsl_write_word (
		signal i_fsl   : in  i_fsl_t;
		signal o_fsl   : out o_fsl_t;
		signal data   : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(o_fsl);
		case i_fsl.step is
			when 0 =>
				fsl_push(i_fsl,o_fsl,data,0,1);
			when 1 =>
				fsl_push_finish(i_fsl,o_fsl,2);
			when others =>
				done := True;
				o_fsl.step <= 0;
		end case;
	end;


	procedure osif_reset(
		signal o_osif : out o_osif_t
		
	) is begin
		fsl_reset(o_osif);
	end procedure;
	
	
	procedure osif_call_0 (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(o_osif);
		case i_osif.step is
			when 0 =>
				fsl_push(i_osif,o_osif,call_id,0,1);
			when 1 =>
				fsl_push_finish(i_osif,o_osif,2);
			when 2=>
				fsl_pull(i_osif,o_osif,result,3,False);
			when others =>
				done := True;
				o_osif.step <= 0;
		end case;
	end procedure;
	
	
	procedure osif_call_1 (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(o_osif);
		case i_osif.step is
			when 0 =>
				fsl_push(i_osif,o_osif,call_id,0,1);
			when 1 =>
				fsl_push(i_osif,o_osif,arg0,0,2);
			when 2 =>
				fsl_push_finish(i_osif,o_osif,3);
			when 3=>
				fsl_pull(i_osif,o_osif,result,4,False);
			when others =>
				done := True;
				o_osif.step <= 0;
		end case;
	end procedure;

	procedure osif_call_2 (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg1          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(o_osif);
		case i_osif.step is
			when 0 =>
				fsl_push(i_osif, o_osif,call_id,0,1);
			when 1 =>
				fsl_push(i_osif, o_osif,arg0,0,2);
			when 2 =>
				fsl_push(i_osif, o_osif,arg1,1,3);
			when 3 =>
				fsl_push_finish(i_osif, o_osif,4);
			when 4 =>
				fsl_pull(i_osif, o_osif,result,5,False);
			when others =>
				done := True;
				o_osif.step <= 0;
		end case;
	end procedure;

	procedure osif_sem_post (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_SEM_POST,handle,result,done);
	end procedure;

	procedure osif_sem_wait (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_SEM_WAIT,handle,result,done);
	end procedure;
		  
	-- mutex lock
	procedure osif_mutex_lock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_MUTEX_LOCK,handle,result,done);
	end procedure;
	
	-- mutex unlock
	procedure osif_mutex_unlock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_MUTEX_UNLOCK,handle,result,done);
	end procedure;
	
	-- mutex trylock
	procedure osif_mutex_trylock (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_MUTEX_TRYLOCK,handle,result,done);
	end procedure;
	
	-- condition variable wait
	procedure osif_cond_wait (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		cond_handle   : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		mutex_handle  : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_2(i_osif, o_osif,OSIF_CMD_COND_WAIT,cond_handle, mutex_handle,result,done);
	end procedure;
	
	-- condition variable signal
	procedure osif_cond_signal (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_COND_SIGNAL,handle,result,done);
	end procedure;
	
	-- condition variable broadcast
	procedure osif_cond_broadcast (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_COND_BROADCAST,handle,result,done);
	end procedure;
		  
	
	procedure osif_mbox_put (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		word          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	) is begin
		osif_call_2(i_osif, o_osif,OSIF_CMD_MBOX_PUT,handle,word,result,done);
	end procedure;
	
	procedure osif_mbox_get (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	) is begin
		osif_call_1(i_osif, o_osif,OSIF_CMD_MBOX_GET,handle,result,done);
	end procedure;
	
	-- get_init_data
	procedure osif_get_init_data (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_0(i_osif, o_osif,OSIF_CMD_THREAD_GET_INIT_DATA,result,done);
	end procedure;
		
	-- thread_exit
	procedure osif_thread_exit (
		signal i_osif : in  i_osif_t;
		signal o_osif : out o_osif_t
	)is begin
		fsl_default(o_osif);
		case i_osif.step is
			when 0 =>
				fsl_push(i_osif,o_osif,OSIF_CMD_THREAD_EXIT,0,1);
			when 1 =>
				fsl_push_finish(i_osif,o_osif,2);
			when others =>
				o_osif.step <= 2;
		end case;
	end procedure;
	
	procedure memif_setup (
		signal i_memif : out i_memif_t;
		signal o_memif : in  o_memif_t;
		signal clk   : in std_logic;
		signal s_clk : out std_logic;
		signal s_data : in std_logic_vector(31 downto 0);
		signal s_fill : in std_logic_vector(15 downto 0);
		signal s_rd : out std_logic;
		signal m_clk : out std_logic;
		signal m_data : out std_logic_vector(31 downto 0);
		signal m_remainder : in std_logic_vector(15 downto 0);
		signal m_wr : out std_logic
	) is begin
		i_memif.clk <= clk;
		
		s_clk <= clk;
		i_memif.s_data <= s_data;
		i_memif.s_fill <= s_fill;
		s_rd <= o_memif.s_rd;
		
		m_clk <= clk;
		m_data <= o_memif.m_data;
		i_memif.m_remainder <= m_remainder;
		m_wr <= o_memif.m_wr;
		
		i_memif.step <= o_memif.step;
	end procedure;
	
	procedure memif_reset( signal o_memif : out o_memif_t) is
	begin
		o_memif.step <= 0;
		o_memif.s_rd <= '0';
		o_memif.m_wr <= '0';
	end procedure;
	
	procedure memif_write (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		data  : in std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 2 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= MEMIF_CMD_WRITE & x"000004";
				o_memif.step <= 2;
			when 2 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= addr;
				o_memif.step <= 3;
			when 3 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= data;
				o_memif.step <= 4;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;
	
	procedure memif_read (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 1 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= MEMIF_CMD_READ & x"000004";
				o_memif.step <= 2;
			when 2 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= addr;
				o_memif.step <= 3;
			when 3 =>
				if i_memif.s_fill > 0 then
					o_memif.step <= 4;
				end if;
			when 4 =>
				o_memif.s_rd <= '1';
				data <= i_memif.s_data;
				o_memif.step <= 5;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;
	
	procedure memif_read_debug (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 1 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= MEMIF_CMD_READ & x"000010";
				o_memif.step <= 2;
			when 2 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= addr;
				o_memif.step <= 3;
			when 3 =>
				if i_memif.s_fill > 0 then
					o_memif.step <= 4;
				end if;
			when 4 =>
				o_memif.s_rd <= '1';
				data <= i_memif.s_data;
				o_memif.step <= 5;
			when 5 =>
				o_memif.s_rd <= '1';
				o_memif.step <= 6;
			when 6 =>
				o_memif.s_rd <= '1';
				o_memif.step <= 7;
			when 7 =>
				o_memif.s_rd <= '1';
				o_memif.step <= 8;
				
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;
	
	procedure memif_read_request (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 1 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= MEMIF_CMD_READ & len;
				o_memif.step <= 2;
			when 2 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= addr;
				o_memif.step <= 3;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;

	procedure memif_write_request (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 1 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= MEMIF_CMD_WRITE & len;
				o_memif.step <= 2;
			when 2 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= addr;
				o_memif.step <= 3;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;


	procedure memif_fifo_pull (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		signal data : out std_logic_vector(31 downto 0);
		variable done : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.s_fill > 0 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.s_rd <= '1';
				data <= i_memif.s_data;
				o_memif.step <= 2;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;


	procedure memif_fifo_push (
		signal i_memif : in  i_memif_t;
		signal o_memif : out o_memif_t;
		signal data : in std_logic_vector(31 downto 0);
		variable done : out boolean
	) is begin
		o_memif.m_wr <= '0';
		o_memif.s_rd <= '0';
		done := False;
		case i_memif.step is
			when 0 =>
				if i_memif.m_remainder > 0 then
					o_memif.step <= 1;
				end if;
			when 1 =>
				o_memif.m_wr <= '1';
				o_memif.m_data <= data;
				o_memif.step <= 2;
			when others =>
				o_memif.step <= 0;
				done := True;
		end case;
	end procedure;
	
end reconos_pkg;

