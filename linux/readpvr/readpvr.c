#include <stdio.h>
#include <stdlib.h>

int main(void)
{
	unsigned int pvr0,pvr1,pvr2,pvr3,pvr4,pvr5,pvr6,pvr7,pvr8,pvr9,pvr10,pvr11,pvr12,pvr13,pvr14,pvr15;
	
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
