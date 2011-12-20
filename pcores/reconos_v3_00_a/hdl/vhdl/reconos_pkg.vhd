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

	constant OSIF_CMD_SEM_POST : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000AA";
	constant OSIF_CMD_SEM_WAIT : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000AB";
	constant OSIF_CMD_MBOX_PUT : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000F1";
	constant OSIF_CMD_MBOX_GET : std_logic_vector(0 to C_FSL_WIDTH-1) := X"000000F0";
	constant MEMIF_CMD_READ    : std_logic_vector(7 downto 0) := X"00";
	constant MEMIF_CMD_WRITE   : std_logic_vector(7 downto 0) := X"80";
	
	-- generic FSL interface procedures and functions
	
	type fsl_t is record
		clk            : std_logic;
		rst            : std_logic;
		fsl2hwt_data    : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		fsl2hwt_exists  : std_logic;
		fsl2hwt_full    : std_logic;
		hwt2fsl_data    : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		hwt2fsl_reading : std_logic;
		hwt2fsl_writing : std_logic;
		hwt2fsl_ctrl    : std_logic;
		step           : integer range 0 to 15;
	end record;
	
	type sfifo_t is record
		data : std_logic_vector(31 downto 0);
		fill : std_logic_vector(15 downto 0);
		rd : std_logic;
	end record;
	
	type mfifo_t is record
		data : std_logic_vector(31 downto 0);
		remainder : std_logic_vector(15 downto 0);
		wr : std_logic;
	end record;
	
	type memif_t is record
		clk : std_logic;
		master : mfifo_t;
		slave : sfifo_t;
		step : integer range 0 to 15;
	end record;
	
	-- set up FSL interface. must be called in architecture body.
	procedure fsl_setup (
		signal fsl           : inout fsl_t;
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
		signal fsl      : inout fsl_t;
		data              : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		prev_step         : integer;
		next_step         : integer
	);
	
	-- check whether last push was successfull. if not, go back to previous step
	procedure fsl_push_finish (
		signal fsl      : inout fsl_t;
		next_step         : integer
	);

	-- pull word from fifo. set continue to True when next step pulls next word
	procedure fsl_pull (
		signal fsl      : inout fsl_t;
		signal result     : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		next_step         : integer;
		continue          : boolean
	);
	
	procedure fsl_read_word (
		signal fsl    : inout fsl_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);
	
	procedure fsl_write_word (
		signal fsl    : inout fsl_t;
		signal data   : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);

	-- reset FLS interface
	procedure fsl_reset(signal fsl : out fsl_t);
		
	
	-- OS interface functions and procedures
	
	-- see fsl_setup()
	procedure osif_setup (
		signal osif           : inout fsl_t;
		signal clk            : in std_logic;
		signal rst            : in std_logic;
		signal os2hwt_data    : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal os2hwt_exists  : in std_logic;
		signal os2hwt_full    : in std_logic;
		signal hwt2os_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2os_reading : out std_logic;
		signal hwt2os_writing : out std_logic;
		signal hwt2os_ctrl    : out std_logic
	);
	
	-- generic function call with 1 argument
	procedure osif_call_1(
		signal osif   : inout fsl_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);

	-- generic function call with 2 arguments
	procedure osif_call_2(
		signal osif   : inout fsl_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg1          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	);


	-- post semaphore
	procedure osif_sem_post (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	);
	
	-- wait for semaphore
	procedure osif_sem_wait (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	);
	
	-- put word into mbox
	procedure osif_mbox_put (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		word          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	);
	
	-- read word from mbox
	procedure osif_mbox_get (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	);
	
	-- see fsl_reset()
	procedure osif_reset(signal osif : out fsl_t);

	-- Memory interface procedures and functions
	-- Memory access procedures use the packet based protocol implemented by the xps_mem core
	
	-- see fsl_setup()

	procedure memif_setup (
		signal memif : inout memif_t;
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
	
	procedure memif_reset(signal memif : out memif_t);
	
	procedure memif_write (
		signal   memif : inout memif_t;
		addr  : in std_logic_vector(31 downto 0);
		data  : in std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read_debug (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	);
	
	procedure memif_read_request (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	);

	procedure memif_write_request (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	);

	procedure memif_fifo_pull (
		signal memif : inout memif_t;
		signal data : out std_logic_vector(31 downto 0);
		variable done : out boolean
	);

	procedure memif_fifo_push (
		signal memif : inout memif_t;
		signal data : in std_logic_vector(31 downto 0);
		variable done : out boolean
	);


end reconos_pkg;

package body reconos_pkg is
	
	procedure fsl_setup (
		signal fsl : inout fsl_t;
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
		fsl.clk <= clk;
		fsl.rst <= rst;
		fsl.fsl2hwt_data <= fsl2hwt_data;
		fsl.fsl2hwt_exists <= fsl2hwt_exists;
		fsl.fsl2hwt_full <= fsl2hwt_full;
		hwt2fsl_data <= fsl.hwt2fsl_data;
		hwt2fsl_reading <= fsl.hwt2fsl_reading;
		hwt2fsl_writing <= fsl.hwt2fsl_writing and not fsl2hwt_full; -- this is important: writing must change asynchronously!
		hwt2fsl_ctrl <= fsl.hwt2fsl_ctrl;
		fsl.hwt2fsl_ctrl <= '0';
             end procedure;
	
	procedure fsl_push (
		signal fsl   : inout fsl_t;
		data           : std_logic_vector(C_FSL_WIDTH-1 downto 0);
		prev_step      : integer;
		next_step      : integer
	) is begin
		fsl.hwt2fsl_data <= data;
		if fsl.fsl2hwt_full = '0' then
			fsl.hwt2fsl_writing <= '1';
			fsl.step <= next_step;
		else
			fsl.step <= prev_step;
		end if;
             end procedure;
	
	procedure fsl_push_finish (
		signal fsl   : inout fsl_t;
		next_step      : integer
	) is begin
		if fsl.fsl2hwt_full = '1' then
			fsl.hwt2fsl_writing <= '1';
		else
			fsl.step <= next_step;
		end if;
        end procedure;
	
	procedure fsl_pull (
		signal fsl   : inout fsl_t;
		signal result  : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		next_step      : integer;
		continue       : boolean
	) is begin
		if fsl.fsl2hwt_exists = '1' then
			fsl.hwt2fsl_reading <= '1';
		end if;
		if fsl.fsl2hwt_exists = '1' and fsl.hwt2fsl_reading = '1' then
			result <= fsl.fsl2hwt_data;
			fsl.step <= next_step;
			if not continue then
				fsl.hwt2fsl_reading <= '0';
			end if;
		end if;
        end procedure;
	
	procedure fsl_reset(signal fsl : out fsl_t) is
	begin
		fsl.step  <= 0;
		fsl.hwt2fsl_reading <= '0';
		fsl.hwt2fsl_writing <= '0';
		fsl.hwt2fsl_data <= (others => '0');
	end procedure;
	
	procedure fsl_default (signal fsl : out fsl_t) is
	begin
		fsl.hwt2fsl_reading <= '0';
		fsl.hwt2fsl_writing <= '0';
	end procedure;

	procedure fsl_read_word (
		signal fsl    : inout fsl_t;
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(fsl);
		case fsl.step is
			when 0 =>
				fsl_pull(fsl,result,1,False);
			when others =>
				done := True;
				fsl.step <= 0;
		end case;
        end procedure;
	
	procedure fsl_write_word (
		signal fsl    : inout fsl_t;
		signal data   : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(fsl);
		case fsl.step is
			when 0 =>
				fsl_push(fsl,data,0,1);
			when 1 =>
				fsl_push_finish(fsl,2);
			when others =>
				done := True;
				fsl.step <= 0;
		end case;
	end;



	procedure osif_setup (
		signal osif : inout fsl_t;
		signal clk  : in std_logic;
		signal rst  : in std_logic;
		signal os2hwt_data     : in std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal os2hwt_exists   : in std_logic;
		signal os2hwt_full     : in std_logic;
		signal hwt2os_data    : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal hwt2os_reading : out std_logic;
		signal hwt2os_writing : out std_logic;
		signal hwt2os_ctrl    : out std_logic
	) is begin
		fsl_setup(osif,clk,rst,os2hwt_data,os2hwt_exists,os2hwt_full,hwt2os_data,hwt2os_reading,hwt2os_writing,hwt2os_ctrl);
	end;

	procedure osif_reset(signal osif : out fsl_t) is
	begin
		fsl_reset(osif);
	end procedure;
	
	
	procedure osif_call_1 (
		signal osif   : inout fsl_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(osif);
		case osif.step is
			when 0 =>
				fsl_push(osif,call_id,0,1);
			when 1 =>
				fsl_push(osif,arg0,0,2);
			when 2 =>
				fsl_push_finish(osif,3);
			when 3=>
				fsl_pull(osif,result,4,False);
			when others =>
				done := True;
				osif.step <= 0;
		end case;
        end procedure;

	procedure osif_call_2 (
		signal osif   : inout fsl_t;
		call_id       : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg0          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		arg1          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		done := False;
		fsl_default(osif);
		case osif.step is
			when 0 =>
				fsl_push(osif,call_id,0,1);
			when 1 =>
				fsl_push(osif,arg0,0,2);
			when 2 =>
				fsl_push(osif,arg1,1,3);
			when 3 =>
				fsl_push_finish(osif,4);
			when 4 =>
				fsl_pull(osif,result,5,False);
			when others =>
				done := True;
				osif.step <= 0;
		end case;
        end procedure;

	procedure osif_sem_post (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(osif,OSIF_CMD_SEM_POST,handle,result,done);
        end procedure;

	procedure osif_sem_wait (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0);
		variable done : out boolean
	) is begin
		osif_call_1(osif,OSIF_CMD_SEM_WAIT,handle,result,done);
        end procedure;
	
	procedure osif_mbox_put (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		word          : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	) is begin
		osif_call_2(osif,OSIF_CMD_MBOX_PUT,handle,word,result,done);

        end procedure;
	
	procedure osif_mbox_get (
		signal osif   : inout fsl_t;
		handle        : in  std_logic_vector(C_FSL_WIDTH-1 downto 0);
		signal result : out std_logic_vector(C_FSL_WIDTH-1 downto 0); --
		variable done : out boolean
	) is begin
		osif_call_1(osif,OSIF_CMD_MBOX_GET,handle,result,done);
	end;
	
	procedure memif_setup (
		signal memif : inout memif_t;
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
		memif.clk <= clk;
		
		s_clk <= clk;
		memif.slave.data <= s_data;
		memif.slave.fill <= s_fill;
		s_rd <= memif.slave.rd;
		
		m_clk <= clk;
		m_data <= memif.master.data;
		memif.master.remainder <= m_remainder;
		m_wr <= memif.master.wr;
	end;
	
	procedure memif_reset( signal memif : out memif_t) is
	begin
		memif.step <= 0;
		memif.slave.rd <= '0';
		memif.master.wr <= '0';
	end;
	
	procedure memif_write (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		data  : in std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 2 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= MEMIF_CMD_WRITE & x"000004";
				memif.step <= 2;
			when 2 =>
				memif.master.wr <= '1';
				memif.master.data <= addr;
				memif.step <= 3;
			when 3 =>
				memif.master.wr <= '1';
				memif.master.data <= data;
				memif.step <= 4;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;
	
	procedure memif_read (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 1 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= MEMIF_CMD_READ & x"000004";
				memif.step <= 2;
			when 2 =>
				memif.master.wr <= '1';
				memif.master.data <= addr;
				memif.step <= 3;
			when 3 =>
				if memif.slave.fill > 0 then
					memif.step <= 4;
				end if;
			when 4 =>
				memif.slave.rd <= '1';
				data <= memif.slave.data;
				memif.step <= 5;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;
	
	procedure memif_read_debug (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		signal data  : out std_logic_vector(31 downto 0);
		variable done  : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 1 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= MEMIF_CMD_READ & x"000010";
				memif.step <= 2;
			when 2 =>
				memif.master.wr <= '1';
				memif.master.data <= addr;
				memif.step <= 3;
			when 3 =>
				if memif.slave.fill > 0 then
					memif.step <= 4;
				end if;
			when 4 =>
				memif.slave.rd <= '1';
				data <= memif.slave.data;
				memif.step <= 5;
			when 5 =>
				memif.slave.rd <= '1';
				memif.step <= 6;
			when 6 =>
				memif.slave.rd <= '1';
				memif.step <= 7;
			when 7 =>
				memif.slave.rd <= '1';
				memif.step <= 8;
				
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;
	
	procedure memif_read_request (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 1 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= MEMIF_CMD_READ & len;
				memif.step <= 2;
			when 2 =>
				memif.master.wr <= '1';
				memif.master.data <= addr;
				memif.step <= 3;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;

	procedure memif_write_request (
		signal   memif : inout memif_t;
		addr  : in  std_logic_vector(31 downto 0);
		len   : in std_logic_vector(23 downto 0);
		variable done  : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 1 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= MEMIF_CMD_WRITE & len;
				memif.step <= 2;
			when 2 =>
				memif.master.wr <= '1';
				memif.master.data <= addr;
				memif.step <= 3;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;


	procedure memif_fifo_pull (
		signal memif : inout memif_t;
		signal data : out std_logic_vector(31 downto 0);
		variable done : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.slave.fill > 0 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.slave.rd <= '1';
				data <= memif.slave.data;
				memif.step <= 2;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;


	procedure memif_fifo_push (
		signal memif : inout memif_t;
		signal data : in std_logic_vector(31 downto 0);
		variable done : out boolean
	) is begin
		memif.master.wr <= '0';
		memif.slave.rd <= '0';
		done := False;
		case memif.step is
			when 0 =>
				if memif.master.remainder > 0 then
					memif.step <= 1;
				end if;
			when 1 =>
				memif.master.wr <= '1';
				memif.master.data <= data;
				memif.step <= 2;
			when others =>
				memif.step <= 0;
				done := True;
		end case;
	end;
	
end reconos_pkg;

