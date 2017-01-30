/*
 * thread_shadowing_error_handler.c
 *
 *  Created on: 05.04.2016
 *      Author: meise
 */


#include "thread_shadowing_error_handler.h"
#include "thread_status.h"

//#define DEBUG 1
#define OUTPUT stderr

#ifdef DEBUG
#define TS_DEBUG(message) fprintf(OUTPUT, "TS: " message)
#define TS_DEBUG1(message, arg1) fprintf(OUTPUT, "TS: " message, (arg1))
#define TS_DEBUG2(message, arg1, arg2) fprintf(OUTPUT, "TS: " message, (arg1), (arg2))
#else
#define TS_DEBUG(message)
#define TS_DEBUG1(message, arg1)
#define TS_DEBUG2(message, arg1, arg2)
#endif


void sh_mem_error_handler(uint8_t hwt, uint32_t err_type, uint32_t err_addr){
	shadowedthread_t * sh;
	sh_err_t error;

	fprintf(OUTPUT,"SH_MEM_ERR: HWT: %d,  Type: %s, Address: 0x%x\n", hwt,
		  err_type == MEM_ERROR_TYP_NONE ? "NONE" : (
		  err_type == MEM_ERROR_TYP_HEADER1 ? "HEADER1" : (
		  err_type == MEM_ERROR_TYP_HEADER2 ? "HEADER2" :(
		  err_type == MEM_ERROR_TYP_DATA ? "DATA": "UNKNOWN"))),
		  err_addr);

	// @TODO:update statistics about errors, so we know if they are permanent or transient

	/*
	 * Build error struct.
	 */
	is_shadowed_in_parent(pthread_self(), &sh);


	error.sh = sh;
	error.hwt = -1;
	error.error_code = err_type == MEM_ERROR_TYP_NONE ? SH_ERR_UNKNOWN : (
						err_type == MEM_ERROR_TYP_HEADER1 ? SH_MEM_REQ_MISMATCH : (
						err_type == MEM_ERROR_TYP_HEADER2 ? SH_MEM_ADR_MISMATCH :(
						err_type == MEM_ERROR_TYP_DATA ? SH_MEM_DATA_MISMATCH: SH_ERR_UNKNOWN)));
	error.exit_code = SH_MEM_ERROR_EXIT_CODE;

	/*
	 * @todo: MEMIF error reporting has to be extended to provide a lot more information
	 */
	error.mem_request_a = -1;
	error.mem_request_b = -1;
	error.mem_address_a = err_addr;
	error.mem_address_b = -1;
	error.mem_data_a = -1;
	error.mem_data_b = -1;
	error.mem_offset_a= -1;
	error.mem_offset_b= -1;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_func_error_handler(uint32_t err_type, func_call_t * a, func_call_t * b){
	pthread_t tid = pthread_self();
	timing_t diff = func_call_timediff_us(a,b);
	shadowedthread_t * sh;
	sh_err_t error;

	fprintf(OUTPUT, "\n#################################################\n");
	fprintf(OUTPUT, "# ERROR: Thread ID %lu,  %s\n",tid, func_call_strerror(err_type));
	fprintf(OUTPUT, "# a: "); func_call_dump(a);
	fprintf(OUTPUT, "# b: "); func_call_dump(b);
	fprintf(OUTPUT, "# Detected after: %ld us\n", timer2us(&diff));
	fprintf(OUTPUT, "#################################################\n");

	/*
	 * Build error struct.
	 */

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = err_type == FC_ERR_FUNCTION_MATCH ? SH_FUNC_NAME_MISMATCH :(
						err_type == FC_ERR_PARAMS_MATCH ? SH_FUNC_PARAM_MISMATCH : SH_ERR_UNKNOWN);
	error.exit_code = SH_FUNC_ERROR_EXIT_CODE;

	error.func_name_a = NULL;
	error.func_name_b = NULL;
	error.func_param_a = NULL;
	error.func_param_b = NULL;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		shadow_dump_all();
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_watchdog_error_handler(uint32_t timeout){
	shadowedthread_t * sh;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = SH_WATCHDOG_TIMEOUT;
	error.exit_code = SH_WATCHDOG_EXIT_CODE;

	error.watchdog_timeout = timeout;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_osif_function_error_handler(int32_t hwt_slot, uint32_t function ){

	shadowedthread_t * sh;
	sh_err_t error;
	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = hwt_slot;
	error.error_code = SH_OSIF_NR_ILLEGAL;
	error.exit_code = SH_OSIF_NR_ILLEGAL_EXIT_CODE;

	error.osif_func_nr = function;
	error.osif_resource_handle = -1;
	error.osif_max_resource_handle = -1;
	error.osif_is_type = -1;
	error.osif_should_type = -1;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_osif_param_error_handler(int32_t hwt_slot, uint32_t resource_handle, uint32_t max_resource_handle, uint32_t is_type, uint32_t should_type){

	shadowedthread_t * sh;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = hwt_slot;
	error.error_code = SH_OSIF_PARAM_ILLEGAL;
	error.exit_code = SH_OSIF_PARAM_ILLEGAL_EXIT_CODE;

	error.osif_func_nr = -1;
	error.osif_resource_handle = resource_handle;
	error.osif_max_resource_handle = max_resource_handle;
	error.osif_is_type = is_type;
	error.osif_should_type = should_type;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_signal_error_handler(const char* thread_name, int signr, void* code_address, void* mem_address){
	shadowedthread_t * sh;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = SH_SIGNAL;
	error.exit_code = SH_SIGNAL_EXIT_CODE_BASE+signr;

	error.signal_thread_name = thread_name;
	error.signal_signr = signr;
	error.signal_code_address = code_address;
	error.signal_mem_address = mem_address;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_file_open_error_handler(const char * file, int flags){
	shadowedthread_t * sh;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = SH_FILE_OPEN_ERROR;
	error.exit_code = SH_FILE_OPEN_EXIT_CODE;

	error.file_path = file;
	error.file_flags = flags;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


void sh_file_readwrite_error_handler(const char * file,int32_t is_read, int32_t should_read, int32_t is_write, int32_t should_write ){
	shadowedthread_t * sh;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = SH_FILE_READWRITE_ERROR;
	error.exit_code = SH_FILE_READWRITE_EXIT_CODE;

	error.file_path = file;
	error.file_flags = -1;
	error.file_is_read = is_read;
	error.file_should_read = should_read;
	error.file_is_write = is_write;
	error.file_should_write = should_write;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}

void sh_proc_control_error_handler(uint8_t cmd){
	shadowedthread_t * sh;
	sh_err_t error;

	fprintf(OUTPUT,"SH_PROC_CONTROL_ERR: Unknown command 0x%x\n", cmd);

	is_shadowed_in_parent(pthread_self(), &sh);

	// @TODO:update statistics about errors, so we know if they are permanent or transient
	/*
	 * Build error struct.
	 */

	error.sh = NULL;
	error.hwt = -1;
	error.error_code = SH_PROC_CONTROL_CMD;
	error.exit_code = SH_PROC_CONTROL_EXIT_CODE;

	/*
	 * @todo: MEMIF error reporting has to be extended to provide a lot more information
	 */
	error.cmd = cmd;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}

}

void sh_generic_error_handler(const char* error_description, ...){
	shadowedthread_t * sh;
	char *text_buffer;
	va_list vl;
	sh_err_t error;

	is_shadowed_in_parent(pthread_self(), &sh);

	text_buffer = malloc(200); // 200 bytes for error message maximum
	if (text_buffer == NULL){
		exit(SH_MALLOC_EXIT_CODE);
	}

	va_start(vl, error_description);
	vsnprintf(text_buffer,200, error_description, vl);
	va_end(vl);

	error.sh = sh;
	error.hwt = -1;
	error.error_code = SH_GENERIC_ERROR;
	error.exit_code = SH_GENERIC_EXIT_CODE;

	error.generic_error_description = text_buffer;

	/*
	 *  Notify application if an error handler was specified, else abort program.
	 */
	if( (sh != NULL) && (sh->error_callback != NULL) ){
		sh->error_callback(error);
	} else {
		thread_status_print_all();
		sh_error_to_json(error);
		exit(error.exit_code);
	}
}


/*
 * Converts the sh_err_t structure to a JSON string, which is easy to parse by scripts.
 * Output goes to stderr.
 */
void sh_error_to_json(sh_err_t error){

#define OUT(ITEM, FORMAT) fprintf(stderr, ", \""#ITEM"\":"#FORMAT, error.ITEM)
#define OUTF(ITEM, FORMAT) fprintf(stderr, "\""#ITEM"\":"#FORMAT, error.ITEM)

	/*
	 * Open JSON object and make sure it shows up on its own line of output.
	 */
	fprintf(stderr, "\n{");
	OUTF(error_code,%u);
	OUT(exit_code,%u);
	OUT(hwt,%u);
	OUT(sh,%lu);

	switch(error.error_code){
	case SH_OSIF_NR_ILLEGAL:
	case SH_OSIF_PARAM_ILLEGAL:
		OUT(osif_func_nr,%u);
		OUT(osif_resource_handle,%u);
		OUT(osif_max_resource_handle,%u);
		OUT(osif_is_type,%u);
		OUT(osif_should_type,%u);
		break;

	case SH_FUNC_NAME_MISMATCH:
	case SH_FUNC_PARAM_MISMATCH:
		OUT(func_name_a,"%s");
		OUT(func_name_b,"%s");
		OUT(func_param_a,%lu);
		OUT(func_param_b,%lu);
		break;

	case SH_MEM_REQ_MISMATCH:
	case SH_MEM_ADR_MISMATCH:
	case SH_MEM_DATA_MISMATCH:
		OUT(mem_request_a,%u);
		OUT(mem_request_b,%u);
		OUT(mem_address_a,%u);
		OUT(mem_address_b,%u);
		OUT(mem_offset_a,%u);
		OUT(mem_offset_b,%u);
		OUT(mem_data_a,%u);
		OUT(mem_data_b,%u);
		break;

	case SH_WATCHDOG_TIMEOUT:
		OUT(watchdog_timeout,%u);
		break;

	case SH_SIGNAL:
		OUT(signal_thread_name, "%s");
		OUT(signal_signr, %d);
		OUT(signal_code_address,%lu);
		OUT(signal_mem_address, %lu);
		break;

	case SH_FILE_OPEN_ERROR:
	case SH_FILE_READWRITE_ERROR:
		OUT(file_path,"%s");
		OUT(file_flags,%d);
		OUT(file_is_read,%d);
		OUT(file_should_read,%d);
		OUT(file_is_write,%d);
		OUT(file_should_write,%d);
		break;

	case SH_GENERIC_ERROR:
		OUT(generic_error_description,"%s");
		break;

	case SH_ERR_UNKNOWN:
		break;
	}
	fprintf(stderr, "}\n");
}

#if 0

/*
 * Example user level error handling function
 */

void sh_user_error_handler(sh_err_t err){

}

#endif

