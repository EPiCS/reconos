/*
 * thread_shadowing_error_handler.h
 *
 *  Created on: 05.04.2016
 *      Author: meise
 */

#ifndef THREAD_SHADOWING_ERROR_HANDLER_H_
#define THREAD_SHADOWING_ERROR_HANDLER_H_

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>

#include "thread_shadowing.h"
#include "func_call.h"

/*
 * Definitions for different types of memory errors.
 */
#define MEM_ERROR_TYP_NONE    0
#define MEM_ERROR_TYP_HEADER1 1
#define MEM_ERROR_TYP_HEADER2 2
#define MEM_ERROR_TYP_DATA    3

/*
 * Error code definitions
 */
#define SH_NO_ERROR				0x0000 //     0

#define SH_OSIF_NR_ILLEGAL		0x0101 //   257
#define SH_OSIF_PARAM_ILLEGAL	0x0102 //   258

#define SH_FUNC_NAME_MISMATCH	0x0211 //   529
#define SH_FUNC_PARAM_MISMATCH	0x0212 //   530

#define SH_MEM_REQ_MISMATCH		0x0301 //   769
#define SH_MEM_ADR_MISMATCH		0x0302 //   770
#define SH_MEM_DATA_MISMATCH	0x0303 //   771

#define SH_WATCHDOG_TIMEOUT		0x0401 //  1025

#define SH_SIGNAL				0x0501 //  1281

#define SH_FILE_OPEN_ERROR		0x0601 //  1537
#define SH_FILE_READWRITE_ERROR	0x0602 //  1538

#define SH_GENERIC_ERROR		0x0701 //  1793

#define SH_PROC_CONTROL_CMD		0x0801 //  2049

#define SH_ERR_UNKNOWN			0xFFFF // 65535

/*
 * Exit code definitions
 * Codes 0 to 15 reserved to application
 */

#define SH_FUNC_ERROR_EXIT_CODE 		16
#define SH_WATCHDOG_EXIT_CODE 			17
#define SH_OSIF_NR_ILLEGAL_EXIT_CODE 	18
#define SH_OSIF_PARAM_ILLEGAL_EXIT_CODE 19
#define SH_FILE_OPEN_EXIT_CODE 			20
#define SH_FILE_READWRITE_EXIT_CODE 	21
#define SH_GENERIC_EXIT_CODE 			22
#define SH_MALLOC_EXIT_CODE 			23
#define SH_PROC_CONTROL_EXIT_CODE		24
#define SH_SIGNAL_EXIT_CODE_BASE 		192
#define SH_MEM_ERROR_EXIT_CODE			32+192

typedef struct sh_err {
	uint16_t error_code;	// What exactly has gone wrong?
	uint8_t exit_code;		// Suggested exit code of application.
	uint8_t hwt;			// For some types of error we know which hardware thread was faulty.
	shadowedthread_t * sh;

	union {
		struct {
			uint32_t osif_func_nr; 		// Number transported over OSIF to identify function to call.
			uint32_t osif_resource_handle;	// Parameter transported over OSIF as a parameter for a function.
			uint32_t osif_max_resource_handle;
			uint32_t osif_is_type;
			uint32_t osif_should_type;
		};

		struct {
			char * func_name_a;
			char * func_name_b;

			void * func_param_a;
			void * func_param_b;
		};

		struct {
			uint32_t mem_request_a;
			uint32_t mem_request_b;

			uint32_t mem_address_a;
			uint32_t mem_address_b;

			uint32_t mem_offset_a;
			uint32_t mem_offset_b;

			uint32_t mem_data_a;
			uint32_t mem_data_b;
		};

		struct {
			uint32_t watchdog_timeout;
		};

		struct {
			const char* 	signal_thread_name;
			int		signal_signr;
			void * 	signal_code_address;
			void * 	signal_mem_address;
		};

		struct {
			const char* file_path;
			int file_flags;
			int32_t file_is_read;
			int32_t file_should_read;
			int32_t file_is_write;
			int32_t file_should_write;
		};

		struct {
			uint8_t cmd;
		};

		struct {
			const char * generic_error_description;
		};
	};
} sh_err_t;

void sh_mem_error_handler(uint8_t hwt, uint32_t err_type, uint32_t err_addr);
void sh_func_error_handler(uint32_t err_type, func_call_t * a, func_call_t * b);
void sh_watchdog_error_handler(uint32_t timeout);
void sh_osif_function_error_handler(int32_t hwt_slot, uint32_t function );
void sh_osif_param_error_handler(int32_t hwt_slot, uint32_t resource_handle, uint32_t max_resource_handle, uint32_t is_type, uint32_t should_type);
void sh_signal_error_handler(const char* thread_name, int signr, void* code_address, void* mem_address);
void sh_file_open_error_handler(const char * file, int flags);
void sh_file_readwrite_error_handler(const char * file,int32_t is_read, int32_t should_read, int32_t is_write, int32_t should_write );
void sh_proc_control_error_handler(uint8_t cmd);
void sh_generic_error_handler(const char* error_description, ...);

void sh_error_to_json(sh_err_t error);

#endif /* THREAD_SHADOWING_ERROR_HANDLER_H_ */
