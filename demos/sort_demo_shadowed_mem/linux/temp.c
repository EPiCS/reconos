/*
 * temp.c
 *
 *  Created on: Mar 19, 2015
 *      Author: meise
 */


	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "Creating %i hw-threads: ", hw_threads);
	fflush(stdout);
	#endif
	for (i = 0; i < hw_threads; i++)
	{
	  #ifndef _MIBENCHOUTPUT
	  fprintf(stderr, " %i",i);fflush(stdout);
	  #endif
	  reconos_hwt_setresources(&(hwt[i]),res,2);
	  reconos_hwt_create(&(hwt[i]),FIRST_SHORT_TERM_SLOT+i,NULL);
	}
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "\n");
	#endif

	// init software threads
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "Creating %i sw-threads: ",sw_threads);
	fflush(stdout);
	#endif
	for (i = 0; i < sw_threads; i++)
	{
	  #ifndef _MIBENCHOUTPUT
	  fprintf(stderr, " %i",i);fflush(stdout);
	  #endif
	  pthread_attr_init(&swt_attr[i]);
	  pthread_create(&swt[i], &swt_attr[i], short_term_synthesis_filtering_swt, (void*)res);
	}
	#ifndef _MIBENCHOUTPUT
	fprintf(stderr, "\n");
	#endif








	for (i=0; i<hw_threads; i++)
		{
		  pthread_join(hwt[i].delegate,NULL);
		}
		for (i=0; i<sw_threads; i++)
		{
		  pthread_join(swt[i],NULL);
		}
