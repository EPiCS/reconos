#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

/* from Linux */
#ifndef array_size
# define array_size(x)		(sizeof(x) / sizeof((x)[0]) + __must_be_array(x))
#endif

#ifndef __must_be_array
# define __must_be_array(x)		\
	build_bug_on_zero(__builtin_types_compatible_p(typeof(x), typeof(&x[0])))
#endif

#ifndef build_bug_on_zero
# define build_bug_on_zero(e)	(sizeof(char[1 - 2 * !!(e)]) - 1)
#endif

struct field {
	const char *name;
	int reg;
	int msb;
	int lsb;
};

static struct field fields[] = {
	{"CFG", 0, 0, 0},
	{"BS", 0, 1, 1},
	{"DIV",	0, 2, 2},
	{"MUL", 0, 3, 3},
	{"FPU", 0, 4, 4},
	{"EXC", 0, 5, 5},
	{"ICU", 0, 6, 6},
	{"DCU", 0, 7, 7},
	{"MMU", 0, 8, 8},
	{"BTC", 0, 9, 9},
	{"ENDI", 0, 10, 10},
	{"FT", 0, 11, 11},
	{"MBV", 0, 16, 23},
	{"USR1", 0, 24, 31},
	{"USR2", 1, 0, 31},
	{"DAXI", 2, 0, 0},
	{"DLMB", 2, 1, 1},
	{"IAXI", 2, 2, 2},
	{"ILMB", 2, 3, 3},
	{"IRQEDGE", 2, 4, 4},
	{"IRQPOS", 2, 5, 5},
	{"DPLB", 2, 6, 6},
	{"IPLB", 2, 7, 7},
	{"INTERCON", 2, 8, 8},
	{"STREAM", 2, 9, 9},
	{"FSL", 2, 12, 12},
	{"FSLEXC", 2, 13, 13},
	{"MSR", 2, 14, 14},
	{"PCMP", 2, 15, 15},
	{"AREA", 2, 16, 16},
	{"BS", 2, 17, 17},
	{"DIV", 2, 18, 18},
	{"MUL", 2, 19, 19},
	{"FPU", 2, 20, 20},
	{"MUL64", 2, 21, 21},
	{"FPU2", 2, 22, 22},
	{"IPLBEXC", 2, 23, 23},
	{"DPLBEXC", 2, 24, 24},
	{"OP0EXC", 2, 25, 25},
	{"UNEXC", 2, 26, 26},
	{"OPEXC", 2, 27, 27},
	{"AXIIEXC", 2, 28, 28},
	{"AXIDEXC", 2, 29, 29},
	{"DIVEXC", 2, 30, 30},
	{"FPUEXC", 2, 31, 31},
	{"DEBUG", 3, 0, 0},
	{"PCBRK", 3, 3, 6},
	{"RDADDR", 3, 10, 12},
	{"WRADDR", 3, 16, 18},
	{"NUMFSL", 3, 20, 24},
	{"BTC_SIZE", 3, 29,31},
	{"ICU", 4, 0, 0},
	{"ICTS", 4, 1, 5},
	{"ICW", 4, 7, 7},
	{"ICLL", 4, 8, 10},
	{"ICBS", 4, 11, 15},
	{"IAU", 4, 16, 16},
	{"ICI", 4, 18, 18},
	{"ICV", 4, 19, 21},
	{"ICS", 4, 22, 23},
	{"IFTL", 4, 24, 24},
	{"ICDW", 4, 25, 25},
	{"DCU", 5, 0, 0},
	{"DCTS", 5, 1, 5},
	{"DCW", 5, 7, 7},
	{"DCLL", 5, 8, 10},
	{"DCBS", 5, 11, 15},
	{"DAU", 5, 16, 16},
	{"DWB", 5, 17, 17},
	{"DCI", 5, 18, 18},
	{"DCV", 5, 19, 21},
	{"DFTL", 5, 24, 24},
	{"DCDW", 5, 25, 25},
	{"ICBA", 6, 0, 31},
	{"ICHA", 7, 0, 31},
	{"DCBA", 8, 0, 31},
	{"DCHA", 9, 0, 31},
	{"ARCH", 10, 0, 7},
	{"MMU", 11, 0, 1},
	{"ITLB", 11, 2, 4},
	{"DTLB", 11, 5, 7},
	{"TLBACC", 11, 8, 9},
	{"ZONES", 11, 10, 14},
	{"RSTMSR", 11, 17, 31},
};

static const char *short_options = "vhVl";

static struct option long_options[] = {
        {"value", no_argument, 0, 'V'},
        {"list", no_argument, 0, 'l'},
        {"version", no_argument, 0, 'v'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
};

static unsigned int pvr[16];

static inline void die(void)
{
	exit(0);
}

static void read_pvr_regs(void)
{
	memset(pvr, 0, sizeof(pvr));

	asm volatile ("mfs %0,rPVR0" : "=d" (pvr[0]));
	asm volatile ("mfs %0,rPVR1" : "=d" (pvr[1]));
	asm volatile ("mfs %0,rPVR2" : "=d" (pvr[2]));
	asm volatile ("mfs %0,rPVR3" : "=d" (pvr[3]));
	asm volatile ("mfs %0,rPVR4" : "=d" (pvr[4]));
	asm volatile ("mfs %0,rPVR5" : "=d" (pvr[5]));
	asm volatile ("mfs %0,rPVR6" : "=d" (pvr[6]));
	asm volatile ("mfs %0,rPVR7" : "=d" (pvr[7]));
	asm volatile ("mfs %0,rPVR8" : "=d" (pvr[8]));
	asm volatile ("mfs %0,rPVR9" : "=d" (pvr[9]));
	asm volatile ("mfs %0,rPVR10" : "=d" (pvr[10]));
	asm volatile ("mfs %0,rPVR11" : "=d" (pvr[11]));
	asm volatile ("mfs %0,rPVR12" : "=d" (pvr[12]));
	asm volatile ("mfs %0,rPVR13" : "=d" (pvr[13]));
	asm volatile ("mfs %0,rPVR14" : "=d" (pvr[14]));
	asm volatile ("mfs %0,rPVR15" : "=d" (pvr[15]));
}

static void show_pvr_regs(void)
{
	int i;
	for (i = 0; i < array_size(pvr); ++i)
		printf("PVR%d  = 0x%08X\n", i, pvr[i]);
}

static void show_pvr_reg(char *name, int val)
{
	int i, found = 0;
	unsigned int r;

	for (i = 0; i < array_size(fields); ++i) {
		if (!strcmp(name, fields[i].name)) {
			found = 1;
			r = pvr[fields[i].reg];
			r = r << fields[i].msb;
			r = r >> fields[i].msb;
			r = r >> (31 - fields[i].lsb);
			if (val)
				printf("%d\n", r);
			else
				printf("%s: %d\n", fields[i].name, r);
		}
	}

	if (!found)
		printf("Register name not found! Try --list!\n");
}

static void show_pvr_list(void)
{
	int i;

	printf("List of microblaze PVR bits and bit fields:\n");
	printf("    NAME REG MSB LSB\n");

	for (i = 0; i < array_size(fields); ++i)
		printf("%8s  %2d  %2d  %2d\n",
		       fields[i].name, fields[i].reg,
		       fields[i].msb, fields[i].lsb);
}

static void help(void)
{
	printf("Usage: readpvr [name of field|-h|-l|-V]\n\n");
	printf("Prints contents processor of version registers.\n");
	printf("Optionally the name of a bit or bit field encoded in a PVR may be supplied\n\n");
	printf("Options:\n");
	printf("  -l|--list      Print list of possible bit names\n");
	printf("  -V|--value     Only print value of a specified field, not its name\n");
	printf("  -h|--help      Print usage information\n\n");
	printf("Examples:\n");
	printf("  readpvr NUMFSL\n");
	printf("  readpvr -V NUMFSL\n");
	printf("  readpvr -l\n\n");
	printf("This is free software: you are free to change and redistribute it.\n");
	printf("There is NO WARRANTY, to the extent permitted by law.\n");
	printf("Copyright (C) 2012 Andreas Agne <agne@upb.de>,\n");
	printf("Copyright (C) 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>\n");
	die();
}

int main(int argc, char **argv)
{
	int c, opt_index, only_value = 0, good = 0;

	while (argc >= 2 && (c = getopt_long(argc, argv, short_options,
		long_options, &opt_index)) != EOF) {
		switch (c) {
		case 'h':
			help();
			break;
		case 'v':
			help();
			break;
		case 'V':
			only_value = 1;
			good++;
			break;
		case 'l':
			show_pvr_list();
			die();
		case '?':
			break;
		default:
			abort();
		}
	}

	read_pvr_regs();

	if (good < argc)
		show_pvr_reg(argv[argc - 1], only_value);
	else
		show_pvr_regs();
	return 0;
}
