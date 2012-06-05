/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdio.h>
#include <pthread.h>

#include "props.h"
#include "xutils.h"

static void *property_fetcher(void *null)
{

	pthread_exit(NULL);
}

void start_property_fetcher(void)
{
	printd("Start property collector!\n");
}

void stop_property_fetcher(void)
{
	printd("Stop property collector!\n");
}
