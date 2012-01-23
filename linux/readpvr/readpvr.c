#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct field
{
	const char * name;
	int reg;
	int msb;
	int lsb;
};

struct field fields[] = {
	{"CFG"     , 0, 0, 0},
	{"BS"      , 0, 1, 1},
	{"DIV"     , 0, 2, 2},
	{"MUL"     , 0, 3, 3},
	{"FPU"     , 0, 4, 4},
	{"EXC"     , 0, 5, 5},
	{"ICU"     , 0, 6, 6},
	{"DCU"     , 0, 7, 7},
	{"MMU"     , 0, 8, 8},
	{"BTC"     , 0, 9, 9},
	{"ENDI"    , 0,10,10},
	{"FT"      , 0,11,11},
	{"MBV"     , 0,16,23},
	{"USR1"    , 0,24,31},
	{"USR2"    , 1, 0,31},
	{"DAXI"    , 2, 0, 0},
	{"DLMB"    , 2, 1, 1},
	{"IAXI"    , 2, 2, 2},
	{"ILMB"    , 2, 3, 3},
	{"IRQEDGE" , 2, 4, 4},
	{"IRQPOS"  , 2, 5, 5},
	{"DPLB"    , 2, 6, 6},
	{"IPLB"    , 2, 7, 7},
	{"INTERCON", 2, 8, 8},
	{"STREAM"  , 2, 9, 9},
	{"FSL"     , 2,12,12},
	{"FSLEXC"  , 2,13,13},
	{"MSR"     , 2,14,14},
	{"PCMP"    , 2,15,15},
	{"AREA"    , 2,16,16},
	{"BS"      , 2,17,17},
	{"DIV"     , 2,18,18},
	{"MUL"     , 2,19,19},
	{"FPU"     , 2,20,20},
	{"MUL64"   , 2,21,21},
	{"FPU2"    , 2,22,22},
	{"IPLBEXC" , 2,23,23},
	{"DPLBEXC" , 2,24,24},
	{"OP0EXC"  , 2,25,25},
	{"UNEXC"   , 2,26,26},
	{"OPEXC"   , 2,27,27},
	{"AXIIEXC" , 2,28,28},
	{"AXIDEXC" , 2,29,29},
	{"DIVEXC"  , 2,30,30},
	{"FPUEXC"  , 2,31,31},
	{"DEBUG"   , 3, 0, 0},
	{"PCBRK"   , 3, 3, 6},
	{"RDADDR"  , 3,10,12},
	{"WRADDR"  , 3,16,18},
	{"NUMFSL"  , 3,20,24},
	{"BTC_SIZE", 3,29,31},
	{"ICU"     , 4, 0, 0},
	{"ICTS"    , 4, 1, 5},
	{"ICW"     , 4, 7, 7},
	{"ICLL"    , 4, 8,10},
	{"ICBS"    , 4,11,15},
	{"IAU"     , 4,16,16},
	{"ICI"     , 4,18,18},
	{"ICV"     , 4,19,21},
	{"ICS"     , 4,22,23},
	{"IFTL"    , 4,24,24},
	{"ICDW"    , 4,25,25},
	{"DCU"     , 5, 0, 0},
	{"DCTS"    , 5, 1, 5},
	{"DCW"     , 5, 7, 7},
	{"DCLL"    , 5, 8,10},
	{"DCBS"    , 5,11,15},
	{"DAU"     , 5,16,16},
	{"DWB"     , 5,17,17},
	{"DCI"     , 5,18,18},
	{"DCV"     , 5,19,21},
	{"DFTL"    , 5,24,24},
	{"DCDW"    , 5,25,25},
	{"ICBA"    , 6, 0,31},
	{"ICHA"    , 7, 0,31},
	{"DCBA"    , 8, 0,31},
	{"DCHA"    , 9, 0,31},
	{"ARCH"    ,10, 0, 7},
	{"MMU"     ,11, 0, 1},
	{"ITLB"    ,11, 2, 4},
	{"DTLB"    ,11, 5, 7},
	{"TLBACC"  ,11, 8, 9},
	{"ZONES"   ,11,10,14},
	{"RSTMSR"  ,11,17,31},
	{NULL,0,0,0}
};

void exit_usage(const char *progname)
{
	fprintf(stderr,"Usage: %s [name of field|-h|-l]\n",progname);
	fprintf(stderr,"Prints contents processor version registers.\n");
	fprintf(stderr,"Optionally the name of a bit or bit field encoded in a PVR may be supplied\n");
	fprintf(stderr,"-h | --help  : print usage information\n");
	fprintf(stderr,"-l | --list  : print list of bit names\n");
	exit(1);
}

void exit_list()
{
	int i = 0;
	printf("List of microblaze PVR bits and bit fields:\n");
	printf("    NAME REG MSB LSB\n");
	while(fields[i].name != NULL){
		printf("%8s  %2d  %2d  %2d\n",fields[i].name,fields[i].reg,fields[i].msb,fields[i].lsb); 
		i++;
	}
	exit(0);
}

int main(int argc, char **argv)
{
	int i,found = 0;
	unsigned int pvr0,pvr1,pvr2,pvr3,pvr4,pvr5,pvr6,pvr7,pvr8,pvr9,pvr10,pvr11,pvr12,pvr13,pvr14,pvr15;
	unsigned int pvr[16];
	
	if(argc > 2) exit_usage(argv[0]);

	asm volatile ("mfs %0,rPVR0" : "=d" (pvr0));
	asm volatile ("mfs %0,rPVR1" : "=d" (pvr1));
	asm volatile ("mfs %0,rPVR2" : "=d" (pvr2));
	asm volatile ("mfs %0,rPVR3" : "=d" (pvr3));
	asm volatile ("mfs %0,rPVR4" : "=d" (pvr4));
	asm volatile ("mfs %0,rPVR5" : "=d" (pvr5));
	asm volatile ("mfs %0,rPVR6" : "=d" (pvr6));
	asm volatile ("mfs %0,rPVR7" : "=d" (pvr7));
	asm volatile ("mfs %0,rPVR8" : "=d" (pvr8));
	asm volatile ("mfs %0,rPVR9" : "=d" (pvr9));
	asm volatile ("mfs %0,rPVR10" : "=d" (pvr10));
	asm volatile ("mfs %0,rPVR11" : "=d" (pvr11));
	asm volatile ("mfs %0,rPVR12" : "=d" (pvr12));
	asm volatile ("mfs %0,rPVR13" : "=d" (pvr13));
	asm volatile ("mfs %0,rPVR14" : "=d" (pvr14));
	asm volatile ("mfs %0,rPVR15" : "=d" (pvr15));

	pvr[ 0] = pvr0;
	pvr[ 1] = pvr1;
	pvr[ 2] = pvr2;
	pvr[ 3] = pvr3;
	pvr[ 4] = pvr4;
	pvr[ 5] = pvr5;
	pvr[ 6] = pvr6;
	pvr[ 7] = pvr7;
	pvr[ 8] = pvr8;
	pvr[ 9] = pvr9;
	pvr[10] = pvr10;
	pvr[11] = pvr11;
	pvr[12] = pvr12;
	pvr[13] = pvr13;
	pvr[14] = pvr14;
	pvr[15] = pvr15;

	if(argc == 2){
		unsigned int r;

		if(!strcmp(argv[1],"-h") || !strcmp(argv[1],"--help")) exit_usage(argv[0]); 
		if(!strcmp(argv[1],"-l") || !strcmp(argv[1],"--list")) exit_list();
		i = 0;
		while(fields[i].name != NULL){
			if(!strcmp(argv[1],fields[i].name)){
				found = 1;
				r = pvr[fields[i].reg];
				//printf("%08X\n",r);
				r = r << fields[i].msb;
				r = r >> fields[i].msb;
				//printf("%08X,%d\n",r,fields[i].msb);
				r = r >> (31 - fields[i].lsb);
				printf("%s: %d\n",fields[i].name,r);
			}
			i++;
		}
	} else { 
		printf("PVR0  = 0x%08X\n",pvr0);
		printf("PVR1  = 0x%08X\n",pvr1);
		printf("PVR2  = 0x%08X\n",pvr2);
		printf("PVR3  = 0x%08X\n",pvr3);
		printf("PVR4  = 0x%08X\n",pvr4);
		printf("PVR5  = 0x%08X\n",pvr5);
		printf("PVR6  = 0x%08X\n",pvr6);
		printf("PVR7  = 0x%08X\n",pvr7);
		printf("PVR8  = 0x%08X\n",pvr8);
		printf("PVR9  = 0x%08X\n",pvr9);
		printf("PVR10 = 0x%08X\n",pvr10);
		printf("PVR11 = 0x%08X\n",pvr11);
		printf("PVR12 = 0x%08X\n",pvr12);
		printf("PVR13 = 0x%08X\n",pvr13);
		printf("PVR14 = 0x%08X\n",pvr14);
		printf("PVR15 = 0x%08X\n",pvr15);
		return 0;
	}
	if(!found){
		fprintf(stderr,"Bit '%s' not found. Use '%s --list' to list all valid names.\n",argv[1],argv[0]);
		exit(1); 
	}
	return 0;
}
