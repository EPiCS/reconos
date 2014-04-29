/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0xfbc00daa */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
extern char *STD_STANDARD;
static const char *ng1 = "Function log2 ended without a return statement";



int fsl_v20_v2_11_e_a_3271584164_0090727531_sub_2604412845_1724905902(char *t1, int t2)
{
    char t3[72];
    char t4[8];
    char t8[8];
    int t0;
    char *t5;
    char *t6;
    char *t7;
    char *t9;
    char *t10;
    char *t11;
    unsigned char t12;
    int t13;
    int t14;
    int t15;
    int t16;

LAB0:    t5 = (t3 + 4U);
    t6 = ((STD_STANDARD) + 240);
    t7 = (t5 + 52U);
    *((char **)t7) = t6;
    t9 = (t5 + 36U);
    *((char **)t9) = t8;
    *((int *)t8) = 0;
    t10 = (t5 + 48U);
    *((unsigned int *)t10) = 4U;
    t11 = (t4 + 4U);
    *((int *)t11) = t2;
    t12 = (t2 == 0);
    if (t12 != 0)
        goto LAB2;

LAB4:
LAB6:    t6 = (t5 + 36U);
    t7 = *((char **)t6);
    t13 = *((int *)t7);
    t14 = xsi_vhdl_pow(2, t13);
    t12 = (t14 < t2);
    if (t12 != 0)
        goto LAB7;

LAB9:    t6 = (t5 + 36U);
    t7 = *((char **)t6);
    t13 = *((int *)t7);
    t0 = t13;

LAB1:    return t0;
LAB2:    t0 = 0;
    goto LAB1;

LAB3:    xsi_error(ng1);
    t0 = 0;
    goto LAB1;

LAB5:    goto LAB3;

LAB7:    t6 = (t5 + 36U);
    t9 = *((char **)t6);
    t15 = *((int *)t9);
    t16 = (t15 + 1);
    t6 = (t5 + 36U);
    t10 = *((char **)t6);
    t6 = (t10 + 0);
    *((int *)t6) = t16;
    goto LAB6;

LAB8:;
LAB10:    goto LAB3;

}


extern void fsl_v20_v2_11_e_a_3271584164_0090727531_init()
{
	static char *se[] = {(void *)fsl_v20_v2_11_e_a_3271584164_0090727531_sub_2604412845_1724905902};
	xsi_register_didat("fsl_v20_v2_11_e_a_3271584164_0090727531", "isim/hwt_tb_isim_beh.exe.sim/fsl_v20_v2_11_e/a_3271584164_0090727531.didat");
	xsi_register_subprogram_executes(se);
}
