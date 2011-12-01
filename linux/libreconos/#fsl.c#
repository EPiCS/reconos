#include "fsl.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define MAX_FSL_DEVICES 16
#define FSL_PATH_LEN 256

#define FSL_DEBUG(...) fprintf(stderr,__VA_ARGS__);

static int fsl_fd[MAX_FSL_DEVICES] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};

static void fsl_open(int n)
{
	char s[FSL_PATH_LEN];
	vsnprintf(s, FSL_PATH_LEN, "/dev/fsl%d", &n);
	
	s[FSL_PATH_LEN-1] = '\0';
	
	fsl_fd[n] = open(s,O_RDWR);
	if(fsl_fd[n] < 0){
		perror("open");
		exit(1);
	}
}
/*
static void fsl_closeall()
{
	int i;
	for(i = 0; i < MAX_FSL_DEVICES; i++){
		if(fsl_fd[i] != -1) close(fsl_fd[i]);
	}
}
*/
void fsl_write(int n, uint32 value)
{	
	assert(n >= 0);
	assert(n < MAX_FSL_DEVICES);
	
	if(fsl_fd[n] == -1) fsl_open(n);
	
	write(fsl_fd[n],&value,4);
	FSL_DEBUG("wrote 0x%08X to fsl%d...\n",value,n);
}

uint32 fsl_read(int n)
{
	uint32 value;
	
	assert(n >= 0);
	assert(n < MAX_FSL_DEVICES);	
	
	if(fsl_fd[n] == -1) fsl_open(n);
	
	read(fsl_fd[n],&value,4);
	FSL_DEBUG("read 0x%08X from fsl%d...\n",value,n);
	
	return value;
}


