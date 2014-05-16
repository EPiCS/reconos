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
static const char *ng0 = "/home/aloesch/hwts/matrixmul/hwtsim/memory.vhd";
extern char *IEEE_P_3620187407;
extern char *IEEE_P_2592010699;
extern char *IEEE_P_3499444699;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );
char *ieee_p_3499444699_sub_2213602152_3536714472(char *, char *, int , int );
int ieee_p_3620187407_sub_514432868_3965413181(char *, char *, char *);


static void work_a_3392787015_3212880686_p_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    int t4;
    int t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    xsi_set_current_line(24, ng0);

LAB3:    t1 = (t0 + 1144U);
    t2 = *((char **)t1);
    t1 = (t0 + 776U);
    t3 = *((char **)t1);
    t1 = (t0 + 3944U);
    t4 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t3, t1);
    t5 = (t4 - 0);
    t6 = (t5 * 1);
    xsi_vhdl_check_range_of_index(0, 4095, 1, t4);
    t7 = (32U * t6);
    t8 = (0 + t7);
    t9 = (t2 + t8);
    t10 = (t0 + 2228);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    memcpy(t14, t9, 32U);
    xsi_driver_first_trans_fast_port(t10);

LAB2:    t15 = (t0 + 2176);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_3392787015_3212880686_p_1(char *t0)
{
    char t16[16];
    char t27[16];
    char t29[16];
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    int t8;
    int t9;
    char *t10;
    int t11;
    int t12;
    char *t13;
    int t14;
    unsigned char t15;
    char *t17;
    int t18;
    int t19;
    char *t20;
    char *t21;
    int t22;
    int t23;
    char *t24;
    char *t25;
    char *t26;
    char *t28;
    char *t30;
    char *t31;
    int t32;
    unsigned int t33;
    unsigned int t34;
    unsigned char t35;
    char *t36;
    int t37;
    int t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    char *t42;
    char *t43;
    char *t44;
    char *t45;
    char *t46;

LAB0:    xsi_set_current_line(28, ng0);
    t1 = (t0 + 568U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 2184);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(29, ng0);
    t3 = (t0 + 684U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:    t1 = (t0 + 1052U);
    t3 = *((char **)t1);
    t2 = *((unsigned char *)t3);
    t5 = (t2 == (unsigned char)3);
    if (t5 != 0)
        goto LAB39;

LAB40:
LAB6:    goto LAB3;

LAB5:    xsi_set_current_line(30, ng0);
    t3 = (t0 + 1316U);
    t7 = *((char **)t3);
    t8 = *((int *)t7);
    t9 = (t8 - 1);
    t3 = (t0 + 135176);
    *((int *)t3) = 0;
    t10 = (t0 + 135180);
    *((int *)t10) = t9;
    t11 = 0;
    t12 = t9;

LAB8:    if (t11 <= t12)
        goto LAB9;

LAB11:    xsi_set_current_line(37, ng0);
    t1 = (t0 + 1316U);
    t3 = *((char **)t1);
    t8 = *((int *)t3);
    t9 = (2 * t8);
    t11 = (t9 - 1);
    t1 = (t0 + 1316U);
    t4 = *((char **)t1);
    t12 = *((int *)t4);
    t1 = (t0 + 135186);
    *((int *)t1) = t12;
    t7 = (t0 + 135190);
    *((int *)t7) = t11;
    t14 = t12;
    t18 = t11;

LAB18:    if (t14 <= t18)
        goto LAB19;

LAB21:    xsi_set_current_line(40, ng0);
    t1 = (t0 + 1316U);
    t3 = *((char **)t1);
    t8 = *((int *)t3);
    t9 = (3 * t8);
    t11 = (t9 - 1);
    t1 = (t0 + 1316U);
    t4 = *((char **)t1);
    t12 = *((int *)t4);
    t14 = (2 * t12);
    t1 = (t0 + 135202);
    *((int *)t1) = t14;
    t7 = (t0 + 135206);
    *((int *)t7) = t11;
    t18 = t14;
    t19 = t11;

LAB25:    if (t18 <= t19)
        goto LAB26;

LAB28:    xsi_set_current_line(43, ng0);
    t1 = (t0 + 1316U);
    t3 = *((char **)t1);
    t8 = *((int *)t3);
    t9 = (4 * t8);
    t11 = (t9 - 1);
    t1 = (t0 + 1316U);
    t4 = *((char **)t1);
    t12 = *((int *)t4);
    t14 = (3 * t12);
    t1 = (t0 + 135218);
    *((int *)t1) = t14;
    t7 = (t0 + 135222);
    *((int *)t7) = t11;
    t18 = t14;
    t19 = t11;

LAB32:    if (t18 <= t19)
        goto LAB33;

LAB35:    goto LAB6;

LAB9:    xsi_set_current_line(31, ng0);
    t13 = (t0 + 135176);
    t14 = *((int *)t13);
    t15 = (t14 < 3);
    if (t15 != 0)
        goto LAB12;

LAB14:    xsi_set_current_line(34, ng0);
    t1 = xsi_get_transient_memory(32U);
    memset(t1, 0, 32U);
    t3 = t1;
    memset(t3, (unsigned char)2, 32U);
    t4 = (t0 + 135176);
    t8 = *((int *)t4);
    t9 = (t8 - 0);
    t33 = (t9 * 1);
    t34 = (32U * t33);
    t39 = (0U + t34);
    t7 = (t0 + 2264);
    t10 = (t7 + 32U);
    t13 = *((char **)t10);
    t17 = (t13 + 32U);
    t20 = *((char **)t17);
    memcpy(t20, t1, 32U);
    xsi_driver_first_trans_delta(t7, t39, 32U, 0LL);

LAB13:
LAB10:    t1 = (t0 + 135176);
    t11 = *((int *)t1);
    t3 = (t0 + 135180);
    t12 = *((int *)t3);
    if (t11 == t12)
        goto LAB11;

LAB17:    t8 = (t11 + 1);
    t11 = t8;
    t4 = (t0 + 135176);
    *((int *)t4) = t11;
    goto LAB8;

LAB12:    xsi_set_current_line(32, ng0);
    t17 = (t0 + 135176);
    t18 = *((int *)t17);
    t19 = (t18 + 1);
    t20 = (t0 + 1316U);
    t21 = *((char **)t20);
    t22 = *((int *)t21);
    t23 = (t19 * t22);
    t20 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t16, t23, 30);
    t24 = (t0 + 135184);
    t28 = ((IEEE_P_2592010699) + 2312);
    t30 = (t29 + 0U);
    t31 = (t30 + 0U);
    *((int *)t31) = 0;
    t31 = (t30 + 4U);
    *((int *)t31) = 1;
    t31 = (t30 + 8U);
    *((int *)t31) = 1;
    t32 = (1 - 0);
    t33 = (t32 * 1);
    t33 = (t33 + 1);
    t31 = (t30 + 12U);
    *((unsigned int *)t31) = t33;
    t26 = xsi_base_array_concat(t26, t27, t28, (char)97, t20, t16, (char)97, t24, t29, (char)101);
    t31 = (t16 + 12U);
    t33 = *((unsigned int *)t31);
    t33 = (t33 * 1U);
    t34 = (t33 + 2U);
    t35 = (32U != t34);
    if (t35 == 1)
        goto LAB15;

LAB16:    t36 = (t0 + 135176);
    t37 = *((int *)t36);
    t38 = (t37 - 0);
    t39 = (t38 * 1);
    t40 = (32U * t39);
    t41 = (0U + t40);
    t42 = (t0 + 2264);
    t43 = (t42 + 32U);
    t44 = *((char **)t43);
    t45 = (t44 + 32U);
    t46 = *((char **)t45);
    memcpy(t46, t26, 32U);
    xsi_driver_first_trans_delta(t42, t41, 32U, 0LL);
    goto LAB13;

LAB15:    xsi_size_not_matching(32U, t34, 0);
    goto LAB16;

LAB19:    xsi_set_current_line(38, ng0);
    t10 = (t0 + 135194);
    t17 = (t0 + 135186);
    t20 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t16, *((int *)t17), 24);
    t24 = ((IEEE_P_2592010699) + 2312);
    t25 = (t29 + 0U);
    t26 = (t25 + 0U);
    *((int *)t26) = 0;
    t26 = (t25 + 4U);
    *((int *)t26) = 7;
    t26 = (t25 + 8U);
    *((int *)t26) = 1;
    t19 = (7 - 0);
    t33 = (t19 * 1);
    t33 = (t33 + 1);
    t26 = (t25 + 12U);
    *((unsigned int *)t26) = t33;
    t21 = xsi_base_array_concat(t21, t27, t24, (char)97, t10, t29, (char)97, t20, t16, (char)101);
    t26 = (t16 + 12U);
    t33 = *((unsigned int *)t26);
    t33 = (t33 * 1U);
    t34 = (8U + t33);
    t2 = (32U != t34);
    if (t2 == 1)
        goto LAB22;

LAB23:    t28 = (t0 + 135186);
    t22 = *((int *)t28);
    t23 = (t22 - 0);
    t39 = (t23 * 1);
    t40 = (32U * t39);
    t41 = (0U + t40);
    t30 = (t0 + 2264);
    t31 = (t30 + 32U);
    t36 = *((char **)t31);
    t42 = (t36 + 32U);
    t43 = *((char **)t42);
    memcpy(t43, t21, 32U);
    xsi_driver_first_trans_delta(t30, t41, 32U, 0LL);

LAB20:    t1 = (t0 + 135186);
    t14 = *((int *)t1);
    t3 = (t0 + 135190);
    t18 = *((int *)t3);
    if (t14 == t18)
        goto LAB21;

LAB24:    t8 = (t14 + 1);
    t14 = t8;
    t4 = (t0 + 135186);
    *((int *)t4) = t14;
    goto LAB18;

LAB22:    xsi_size_not_matching(32U, t34, 0);
    goto LAB23;

LAB26:    xsi_set_current_line(41, ng0);
    t10 = (t0 + 135210);
    t17 = (t0 + 135202);
    t20 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t16, *((int *)t17), 24);
    t24 = ((IEEE_P_2592010699) + 2312);
    t25 = (t29 + 0U);
    t26 = (t25 + 0U);
    *((int *)t26) = 0;
    t26 = (t25 + 4U);
    *((int *)t26) = 7;
    t26 = (t25 + 8U);
    *((int *)t26) = 1;
    t22 = (7 - 0);
    t33 = (t22 * 1);
    t33 = (t33 + 1);
    t26 = (t25 + 12U);
    *((unsigned int *)t26) = t33;
    t21 = xsi_base_array_concat(t21, t27, t24, (char)97, t10, t29, (char)97, t20, t16, (char)101);
    t26 = (t16 + 12U);
    t33 = *((unsigned int *)t26);
    t33 = (t33 * 1U);
    t34 = (8U + t33);
    t2 = (32U != t34);
    if (t2 == 1)
        goto LAB29;

LAB30:    t28 = (t0 + 135202);
    t23 = *((int *)t28);
    t32 = (t23 - 0);
    t39 = (t32 * 1);
    t40 = (32U * t39);
    t41 = (0U + t40);
    t30 = (t0 + 2264);
    t31 = (t30 + 32U);
    t36 = *((char **)t31);
    t42 = (t36 + 32U);
    t43 = *((char **)t42);
    memcpy(t43, t21, 32U);
    xsi_driver_first_trans_delta(t30, t41, 32U, 0LL);

LAB27:    t1 = (t0 + 135202);
    t18 = *((int *)t1);
    t3 = (t0 + 135206);
    t19 = *((int *)t3);
    if (t18 == t19)
        goto LAB28;

LAB31:    t8 = (t18 + 1);
    t18 = t8;
    t4 = (t0 + 135202);
    *((int *)t4) = t18;
    goto LAB25;

LAB29:    xsi_size_not_matching(32U, t34, 0);
    goto LAB30;

LAB33:    xsi_set_current_line(44, ng0);
    t10 = (t0 + 135226);
    t17 = (t0 + 135218);
    t20 = ieee_p_3499444699_sub_2213602152_3536714472(IEEE_P_3499444699, t16, *((int *)t17), 24);
    t24 = ((IEEE_P_2592010699) + 2312);
    t25 = (t29 + 0U);
    t26 = (t25 + 0U);
    *((int *)t26) = 0;
    t26 = (t25 + 4U);
    *((int *)t26) = 7;
    t26 = (t25 + 8U);
    *((int *)t26) = 1;
    t22 = (7 - 0);
    t33 = (t22 * 1);
    t33 = (t33 + 1);
    t26 = (t25 + 12U);
    *((unsigned int *)t26) = t33;
    t21 = xsi_base_array_concat(t21, t27, t24, (char)97, t10, t29, (char)97, t20, t16, (char)101);
    t26 = (t16 + 12U);
    t33 = *((unsigned int *)t26);
    t33 = (t33 * 1U);
    t34 = (8U + t33);
    t2 = (32U != t34);
    if (t2 == 1)
        goto LAB36;

LAB37:    t28 = (t0 + 135218);
    t23 = *((int *)t28);
    t32 = (t23 - 0);
    t39 = (t32 * 1);
    t40 = (32U * t39);
    t41 = (0U + t40);
    t30 = (t0 + 2264);
    t31 = (t30 + 32U);
    t36 = *((char **)t31);
    t42 = (t36 + 32U);
    t43 = *((char **)t42);
    memcpy(t43, t21, 32U);
    xsi_driver_first_trans_delta(t30, t41, 32U, 0LL);

LAB34:    t1 = (t0 + 135218);
    t18 = *((int *)t1);
    t3 = (t0 + 135222);
    t19 = *((int *)t3);
    if (t18 == t19)
        goto LAB35;

LAB38:    t8 = (t18 + 1);
    t18 = t8;
    t4 = (t0 + 135218);
    *((int *)t4) = t18;
    goto LAB32;

LAB36:    xsi_size_not_matching(32U, t34, 0);
    goto LAB37;

LAB39:    xsi_set_current_line(47, ng0);
    t1 = (t0 + 868U);
    t4 = *((char **)t1);
    t1 = (t0 + 776U);
    t7 = *((char **)t1);
    t1 = (t0 + 3944U);
    t8 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t7, t1);
    t9 = (t8 - 0);
    t33 = (t9 * 1);
    t34 = (32U * t33);
    t39 = (0U + t34);
    t10 = (t0 + 2264);
    t13 = (t10 + 32U);
    t17 = *((char **)t13);
    t20 = (t17 + 32U);
    t21 = *((char **)t20);
    memcpy(t21, t4, 32U);
    xsi_driver_first_trans_delta(t10, t39, 32U, 0LL);
    goto LAB6;

}


extern void work_a_3392787015_3212880686_init()
{
	static char *pe[] = {(void *)work_a_3392787015_3212880686_p_0,(void *)work_a_3392787015_3212880686_p_1};
	xsi_register_didat("work_a_3392787015_3212880686", "isim/hwt_tb_isim_beh.exe.sim/work/a_3392787015_3212880686.didat");
	xsi_register_executes(pe);
}
