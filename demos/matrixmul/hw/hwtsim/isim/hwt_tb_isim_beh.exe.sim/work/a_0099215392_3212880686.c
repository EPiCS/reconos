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
static const char *ng0 = "/home/aloesch/hwts/matrixmul/hwt_matrixmul_v2_00_a/hdl/vhdl/matrixmultiplier.vhd";
extern char *IEEE_P_3499444699;
extern char *IEEE_P_3620187407;

char *ieee_p_3499444699_sub_2213602152_3536714472(char *, char *, int , int );
char *ieee_p_3499444699_sub_2237018233_3536714472(char *, char *, char *, char *, int );
char *ieee_p_3499444699_sub_3138463120_3536714472(char *, char *, char *, char *, char *, char *);
char *ieee_p_3620187407_sub_767668596_3965413181(char *, char *, char *, char *, char *, char *);


static void work_a_0099215392_3212880686_p_0(char *t0)
{
    char t12[16];
    char t20[16];
    char t21[16];
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned char t10;
    unsigned char t11;
    int t13;
    unsigned int t14;
    char *t15;
    int t16;
    int t17;
    int t18;
    char *t19;
    char *t22;
    unsigned int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    static char *nl0[] = {&&LAB11, &&LAB12, &&LAB13, &&LAB14, &&LAB15, &&LAB16, &&LAB17};

LAB0:    xsi_set_current_line(83, ng0);
    t1 = (t0 + 684U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 568U);
    t4 = xsi_signal_has_event(t1);
    if (t4 == 1)
        goto LAB7;

LAB8:    t3 = (unsigned char)0;

LAB9:    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 3068);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(84, ng0);
    t1 = (t0 + 3112);
    t5 = (t1 + 32U);
    t6 = *((char **)t5);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    *((unsigned char *)t8) = (unsigned char)2;
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(86, ng0);
    t1 = xsi_get_transient_memory(5U);
    memset(t1, 0, 5U);
    t2 = t1;
    memset(t2, (unsigned char)2, 5U);
    t5 = (t0 + 3148);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 5U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(87, ng0);
    t1 = xsi_get_transient_memory(10U);
    memset(t1, 0, 10U);
    t2 = t1;
    memset(t2, (unsigned char)2, 10U);
    t5 = (t0 + 3184);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 10U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(88, ng0);
    t1 = xsi_get_transient_memory(5U);
    memset(t1, 0, 5U);
    t2 = t1;
    memset(t2, (unsigned char)2, 5U);
    t5 = (t0 + 3220);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 5U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(89, ng0);
    t1 = xsi_get_transient_memory(32U);
    memset(t1, 0, 32U);
    t2 = t1;
    memset(t2, (unsigned char)2, 32U);
    t5 = (t0 + 3256);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 32U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(90, ng0);
    t1 = (t0 + 3292);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)2;
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(92, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)0;
    xsi_driver_first_trans_fast(t1);
    goto LAB3;

LAB5:    xsi_set_current_line(94, ng0);
    t2 = (t0 + 3292);
    t6 = (t2 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    *((unsigned char *)t9) = (unsigned char)2;
    xsi_driver_first_trans_fast_port(t2);
    xsi_set_current_line(95, ng0);
    t1 = xsi_get_transient_memory(32U);
    memset(t1, 0, 32U);
    t2 = t1;
    memset(t2, (unsigned char)2, 32U);
    t5 = (t0 + 3256);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 32U);
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(97, ng0);
    t1 = (t0 + 1604U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (char *)((nl0) + t3);
    goto **((char **)t1);

LAB7:    t2 = (t0 + 592U);
    t5 = *((char **)t2);
    t10 = *((unsigned char *)t5);
    t11 = (t10 == (unsigned char)3);
    t3 = t11;
    goto LAB9;

LAB10:    goto LAB3;

LAB11:    xsi_set_current_line(99, ng0);
    t5 = (t0 + 3112);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    *((unsigned char *)t9) = (unsigned char)2;
    xsi_driver_first_trans_fast_port(t5);
    xsi_set_current_line(100, ng0);
    t1 = (t0 + 776U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB18;

LAB20:
LAB19:    goto LAB10;

LAB12:    xsi_set_current_line(107, ng0);
    t1 = (t0 + 2344U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t1 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t12, t13, 5);
    t5 = (t12 + 12U);
    t14 = *((unsigned int *)t5);
    t14 = (t14 * 1U);
    t3 = (5U != t14);
    if (t3 == 1)
        goto LAB21;

LAB22:    t6 = (t0 + 3148);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 32U);
    t15 = *((char **)t9);
    memcpy(t15, t1, 5U);
    xsi_driver_first_trans_fast_port(t6);
    xsi_set_current_line(108, ng0);
    t1 = (t0 + 2344U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t16 = (t13 * 32);
    t1 = (t0 + 2276U);
    t5 = *((char **)t1);
    t17 = *((int *)t5);
    t18 = (t16 + t17);
    t1 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t12, t18, 10);
    t6 = (t12 + 12U);
    t14 = *((unsigned int *)t6);
    t14 = (t14 * 1U);
    t3 = (10U != t14);
    if (t3 == 1)
        goto LAB23;

LAB24:    t7 = (t0 + 3184);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    t15 = (t9 + 32U);
    t19 = *((char **)t15);
    memcpy(t19, t1, 10U);
    xsi_driver_first_trans_fast_port(t7);
    xsi_set_current_line(109, ng0);
    t1 = (t0 + 2344U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t16 = (t13 + 1);
    t1 = (t0 + 2344U);
    t5 = *((char **)t1);
    t1 = (t5 + 0);
    *((int *)t1) = t16;
    xsi_set_current_line(110, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)2;
    xsi_driver_first_trans_fast(t1);
    goto LAB10;

LAB13:    xsi_set_current_line(112, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)3;
    xsi_driver_first_trans_fast(t1);
    goto LAB10;

LAB14:    xsi_set_current_line(114, ng0);
    t1 = (t0 + 1696U);
    t2 = *((char **)t1);
    t1 = (t0 + 6816U);
    t5 = (t0 + 1052U);
    t6 = *((char **)t5);
    t5 = (t0 + 6736U);
    t7 = (t0 + 1236U);
    t8 = *((char **)t7);
    t7 = (t0 + 6768U);
    t9 = ieee_p_3499444699_sub_3138463120_3536714472(IEEE_P_3499444699, t21, t6, t5, t8, t7);
    t15 = ieee_p_3499444699_sub_2237018233_3536714472(IEEE_P_3499444699, t20, t9, t21, 32);
    t19 = ieee_p_3620187407_sub_767668596_3965413181(IEEE_P_3620187407, t12, t2, t1, t15, t20);
    t22 = (t12 + 12U);
    t14 = *((unsigned int *)t22);
    t23 = (1U * t14);
    t3 = (32U != t23);
    if (t3 == 1)
        goto LAB25;

LAB26:    t24 = (t0 + 3364);
    t25 = (t24 + 32U);
    t26 = *((char **)t25);
    t27 = (t26 + 32U);
    t28 = *((char **)t27);
    memcpy(t28, t19, 32U);
    xsi_driver_first_trans_fast(t24);
    xsi_set_current_line(115, ng0);
    t1 = (t0 + 2344U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t3 = (t13 == 32);
    if (t3 != 0)
        goto LAB27;

LAB29:    xsi_set_current_line(119, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)1;
    xsi_driver_first_trans_fast(t1);

LAB28:    goto LAB10;

LAB15:    xsi_set_current_line(122, ng0);
    t1 = (t0 + 2276U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t1 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t12, t13, 5);
    t5 = (t12 + 12U);
    t14 = *((unsigned int *)t5);
    t14 = (t14 * 1U);
    t3 = (5U != t14);
    if (t3 == 1)
        goto LAB30;

LAB31:    t6 = (t0 + 3220);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 32U);
    t15 = *((char **)t9);
    memcpy(t15, t1, 5U);
    xsi_driver_first_trans_fast_port(t6);
    xsi_set_current_line(123, ng0);
    t1 = (t0 + 3292);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)3;
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(124, ng0);
    t1 = (t0 + 1696U);
    t2 = *((char **)t1);
    t1 = (t0 + 3256);
    t5 = (t1 + 32U);
    t6 = *((char **)t5);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    memcpy(t8, t2, 32U);
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(125, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)5;
    xsi_driver_first_trans_fast(t1);
    goto LAB10;

LAB16:    xsi_set_current_line(127, ng0);
    t1 = (t0 + 3292);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)2;
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(128, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)6;
    xsi_driver_first_trans_fast(t1);
    goto LAB10;

LAB17:    xsi_set_current_line(130, ng0);
    t1 = (t0 + 2276U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t16 = (t13 + 1);
    t1 = (t0 + 2276U);
    t5 = *((char **)t1);
    t1 = (t5 + 0);
    *((int *)t1) = t16;
    xsi_set_current_line(132, ng0);
    t1 = (t0 + 2276U);
    t2 = *((char **)t1);
    t13 = *((int *)t2);
    t3 = (t13 == 32);
    if (t3 != 0)
        goto LAB32;

LAB34:    xsi_set_current_line(137, ng0);
    t1 = xsi_get_transient_memory(32U);
    memset(t1, 0, 32U);
    t2 = t1;
    memset(t2, (unsigned char)2, 32U);
    t5 = (t0 + 3364);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 32U);
    xsi_driver_first_trans_fast(t5);
    xsi_set_current_line(138, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)1;
    xsi_driver_first_trans_fast(t1);

LAB33:    goto LAB10;

LAB18:    xsi_set_current_line(101, ng0);
    t1 = (t0 + 2276U);
    t5 = *((char **)t1);
    t1 = (t5 + 0);
    *((int *)t1) = 0;
    xsi_set_current_line(102, ng0);
    t1 = (t0 + 2344U);
    t2 = *((char **)t1);
    t1 = (t2 + 0);
    *((int *)t1) = 0;
    xsi_set_current_line(103, ng0);
    t1 = xsi_get_transient_memory(32U);
    memset(t1, 0, 32U);
    t2 = t1;
    memset(t2, (unsigned char)2, 32U);
    t5 = (t0 + 3364);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    memcpy(t9, t1, 32U);
    xsi_driver_first_trans_fast(t5);
    xsi_set_current_line(104, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)1;
    xsi_driver_first_trans_fast(t1);
    goto LAB19;

LAB21:    xsi_size_not_matching(5U, t14, 0);
    goto LAB22;

LAB23:    xsi_size_not_matching(10U, t14, 0);
    goto LAB24;

LAB25:    xsi_size_not_matching(32U, t23, 0);
    goto LAB26;

LAB27:    xsi_set_current_line(116, ng0);
    t1 = (t0 + 2344U);
    t5 = *((char **)t1);
    t1 = (t5 + 0);
    *((int *)t1) = 0;
    xsi_set_current_line(117, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)4;
    xsi_driver_first_trans_fast(t1);
    goto LAB28;

LAB30:    xsi_size_not_matching(5U, t14, 0);
    goto LAB31;

LAB32:    xsi_set_current_line(133, ng0);
    t1 = (t0 + 2276U);
    t5 = *((char **)t1);
    t1 = (t5 + 0);
    *((int *)t1) = 0;
    xsi_set_current_line(134, ng0);
    t1 = (t0 + 3112);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)3;
    xsi_driver_first_trans_fast_port(t1);
    xsi_set_current_line(135, ng0);
    t1 = (t0 + 3328);
    t2 = (t1 + 32U);
    t5 = *((char **)t2);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = (unsigned char)0;
    xsi_driver_first_trans_fast(t1);
    goto LAB33;

}


extern void work_a_0099215392_3212880686_init()
{
	static char *pe[] = {(void *)work_a_0099215392_3212880686_p_0};
	xsi_register_didat("work_a_0099215392_3212880686", "isim/hwt_tb_isim_beh.exe.sim/work/a_0099215392_3212880686.didat");
	xsi_register_executes(pe);
}
