/*
 * sh_error_to_json_test.c
 *
 *  Created on: 12.04.2016
 *      Author: meise
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "thread_shadowing_error_handler.h"


int main(int argc, char **argv) {

	const char * test_error_description = "This is a test.";

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_OSIF_PARAM_ILLEGAL,
		.exit_code = SH_OSIF_PARAM_ILLEGAL_EXIT_CODE,
		.hwt = -1,
		.osif_func_nr = 12,
		.osif_is_type = 2,
		.osif_should_type = 2,
		.osif_max_resource_handle = 1,
		.osif_resource_handle = 0,
	});

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_FUNC_NAME_MISMATCH,
		.exit_code = SH_FUNC_ERROR_EXIT_CODE,
		.hwt = -1,
		.func_name_a = "mbox_put",
		.func_name_b = "mbox_get",
		.func_param_a = 1234,
		.func_param_b = 0,
	});

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_MEM_REQ_MISMATCH,
		.exit_code = SH_MEM_ERROR_EXIT_CODE,
		.hwt = -1,
		.mem_request_a = 1,
		.mem_request_a = 0,
		.mem_address_a = 1234,
		.mem_address_b = 1234,
		.mem_offset_a = 16,
		.mem_offset_b = 17,
		.mem_data_a = 5555,
		.mem_data_b = 6666,
	});

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_WATCHDOG_TIMEOUT,
		.exit_code = SH_WATCHDOG_EXIT_CODE,
		.hwt = -1,
		.watchdog_timeout= 100,
	});

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_SIGNAL,
		.exit_code = SH_SIGNAL_EXIT_CODE_BASE,
		.hwt = -1,
		.signal_thread_name = "proc_control",
		.signal_signr = 14,
		.signal_code_address= 1234,
		.signal_mem_address= 5678,
	});

	sh_error_to_json((sh_err_t){
		.sh = NULL,
		.error_code = SH_FILE_OPEN_ERROR,
		.exit_code = SH_FILE_OPEN_EXIT_CODE,
		.hwt = -1,
		.file_path="/dev/pgd",
		.file_flags=-1,
		.file_is_read=127,
		.file_should_read=128,
		.file_is_write=0,
		.file_should_write=0

	});

	sh_error_to_json((sh_err_t){
			.sh = NULL,
			.error_code = SH_GENERIC_ERROR,
			.exit_code = SH_GENERIC_EXIT_CODE,
			.hwt = -1,
			.generic_error_description = test_error_description
		});

	exit(EXIT_SUCCESS);
}
