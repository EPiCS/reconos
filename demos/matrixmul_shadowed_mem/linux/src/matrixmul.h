/*
 * matrixmul.h
 *
 *  Created on: May 23, 2014
 *      Author: meise
 */

#ifndef MATRIXMUL_H_
#define MATRIXMUL_H_

#include <signal.h>
#include <sys/ucontext.h>
#include <sys/types.h>
#include <sys/stat.h>

void *matrixmul_thread(void *data);
int limit(int var, int lower, int upper);
void sigsegv_handler(int sig, siginfo_t *siginfo, void * context);
void install_sighandlers();
void handle_commandline(int argc, char** argv);

#endif /* MATRIXMUL_H_ */
