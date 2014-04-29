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
extern char *UNISIM_P_3222816464;

unsigned char unisim_p_3222816464_sub_2053111517_279109243(char *, char *, char *);
int unisim_p_3222816464_sub_3182959421_279109243(char *, char *, char *);


static void unisim_a_2955733374_3996864970_p_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    unsigned char t5;
    char *t6;
    unsigned char t7;
    char *t8;
    unsigned char t9;
    char *t10;
    unsigned char t11;
    char *t12;
    int t13;
    int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;

LAB0:    t1 = xsi_get_transient_memory(4U);
    memset(t1, 0, 4U);
    t2 = t1;
    t3 = (t0 + 960U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    *((unsigned char *)t2) = t5;
    t2 = (t2 + 1U);
    t3 = (t0 + 868U);
    t6 = *((char **)t3);
    t7 = *((unsigned char *)t6);
    *((unsigned char *)t2) = t7;
    t2 = (t2 + 1U);
    t3 = (t0 + 776U);
    t8 = *((char **)t3);
    t9 = *((unsigned char *)t8);
    *((unsigned char *)t2) = t9;
    t2 = (t2 + 1U);
    t3 = (t0 + 684U);
    t10 = *((char **)t3);
    t11 = *((unsigned char *)t10);
    *((unsigned char *)t2) = t11;
    t3 = (t0 + 1612U);
    t12 = *((char **)t3);
    t3 = (t12 + 0);
    memcpy(t3, t1, 4U);
    t1 = (t0 + 1612U);
    t2 = *((char **)t1);
    t1 = (t0 + 4696U);
    t5 = unisim_p_3222816464_sub_2053111517_279109243(UNISIM_P_3222816464, t2, t1);
    t3 = (t0 + 1476U);
    t4 = *((char **)t3);
    t3 = (t4 + 0);
    *((unsigned char *)t3) = t5;
    t1 = (t0 + 1476U);
    t2 = *((char **)t1);
    t5 = *((unsigned char *)t2);
    if (t5 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 1544U);
    t2 = *((char **)t1);
    t1 = (t2 + 0);
    *((int *)t1) = 16;

LAB3:    t1 = (t0 + 1236U);
    t2 = *((char **)t1);
    t1 = (t0 + 1544U);
    t3 = *((char **)t1);
    t13 = *((int *)t3);
    t14 = (t13 - 16);
    t15 = (t14 * -1);
    xsi_vhdl_check_range_of_index(16, 0, -1, t13);
    t16 = (1U * t15);
    t17 = (0 + t16);
    t1 = (t2 + t17);
    t5 = *((unsigned char *)t1);
    t4 = (t0 + 2600);
    t6 = (t4 + 32U);
    t8 = *((char **)t6);
    t10 = (t8 + 32U);
    t12 = *((char **)t10);
    *((unsigned char *)t12) = t5;
    xsi_driver_first_trans_fast_port(t4);
    t1 = (t0 + 2540);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    t1 = (t0 + 1612U);
    t3 = *((char **)t1);
    t1 = (t0 + 4696U);
    t13 = unisim_p_3222816464_sub_3182959421_279109243(UNISIM_P_3222816464, t3, t1);
    t4 = (t0 + 1544U);
    t6 = *((char **)t4);
    t4 = (t6 + 0);
    *((int *)t4) = t13;
    goto LAB3;

}

static void unisim_a_2955733374_3996864970_p_1(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    unsigned char t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    char *t8;
    unsigned char t9;
    unsigned char t10;
    char *t11;
    char *t12;
    unsigned char t13;
    unsigned char t14;
    unsigned char t15;
    char *t16;
    char *t17;
    unsigned char t18;
    unsigned char t19;
    char *t20;
    unsigned char t21;
    unsigned char t22;
    int t23;
    int t24;
    int64 t25;
    int t26;
    int t27;
    int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    char *t32;
    int t33;
    int t34;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    int t44;
    int t45;
    unsigned int t46;
    unsigned int t47;
    unsigned int t48;
    char *t49;

LAB0:    t1 = (t0 + 2360U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    t2 = (t0 + 1680U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    if (t4 != 0)
        goto LAB4;

LAB6:
LAB5:    t2 = (t0 + 1028U);
    t5 = xsi_signal_has_event(t2);
    if (t5 == 1)
        goto LAB23;

LAB24:    t4 = (unsigned char)0;

LAB25:    if (t4 != 0)
        goto LAB20;

LAB22:    t2 = (t0 + 1028U);
    t5 = xsi_signal_has_event(t2);
    if (t5 == 1)
        goto LAB38;

LAB39:    t4 = (unsigned char)0;

LAB40:    if (t4 != 0)
        goto LAB36;

LAB37:
LAB21:
LAB46:    t2 = (t0 + 2556);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB47;

LAB1:    return;
LAB4:
LAB9:    t2 = (t0 + 2548);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB10;
    goto LAB1;

LAB7:    t16 = (t0 + 2548);
    *((int *)t16) = 0;
    t2 = (t0 + 1680U);
    t3 = *((char **)t2);
    t2 = (t3 + 0);
    *((unsigned char *)t2) = (unsigned char)0;
    goto LAB5;

LAB8:    t7 = (t0 + 1028U);
    t8 = xsi_signal_last_value(t7);
    t9 = *((unsigned char *)t8);
    t10 = (t9 == (unsigned char)2);
    if (t10 == 1)
        goto LAB14;

LAB15:    t11 = (t0 + 1028U);
    t12 = xsi_signal_last_value(t11);
    t13 = *((unsigned char *)t12);
    t14 = (t13 == (unsigned char)3);
    t6 = t14;

LAB16:    if (t6 == 1)
        goto LAB11;

LAB12:    t5 = (unsigned char)0;

LAB13:    if (t5 == 1)
        goto LAB7;
    else
        goto LAB9;

LAB10:    goto LAB8;

LAB11:    t16 = (t0 + 1052U);
    t17 = *((char **)t16);
    t18 = *((unsigned char *)t17);
    t19 = (t18 == (unsigned char)2);
    if (t19 == 1)
        goto LAB17;

LAB18:    t16 = (t0 + 1052U);
    t20 = *((char **)t16);
    t21 = *((unsigned char *)t20);
    t22 = (t21 == (unsigned char)3);
    t15 = t22;

LAB19:    t5 = t15;
    goto LAB13;

LAB14:    t6 = (unsigned char)1;
    goto LAB16;

LAB17:    t15 = (unsigned char)1;
    goto LAB19;

LAB20:    t8 = (t0 + 1052U);
    t11 = *((char **)t8);
    t10 = *((unsigned char *)t11);
    t13 = (t10 == (unsigned char)3);
    if (t13 != 0)
        goto LAB26;

LAB28:    t2 = (t0 + 1052U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    t5 = (t4 == (unsigned char)1);
    if (t5 != 0)
        goto LAB34;

LAB35:
LAB27:    goto LAB21;

LAB23:    t3 = (t0 + 1028U);
    t7 = xsi_signal_last_value(t3);
    t6 = *((unsigned char *)t7);
    t9 = (t6 == (unsigned char)2);
    t4 = t9;
    goto LAB25;

LAB26:    t8 = (t0 + 4753);
    *((int *)t8) = 15;
    t12 = (t0 + 4757);
    *((int *)t12) = 1;
    t23 = 15;
    t24 = 1;

LAB29:    if (t23 >= t24)
        goto LAB30;

LAB32:    t25 = (100 * 1LL);
    t2 = (t0 + 1144U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    t2 = (t0 + 2636);
    t7 = (t2 + 32U);
    t8 = *((char **)t7);
    t11 = (t8 + 32U);
    t12 = *((char **)t11);
    *((unsigned char *)t12) = t4;
    xsi_driver_first_trans_delta(t2, 16U, 1, t25);
    t16 = (t0 + 2636);
    xsi_driver_intertial_reject(t16, t25, t25);
    goto LAB27;

LAB30:    t25 = (100 * 1LL);
    t16 = (t0 + 1236U);
    t17 = *((char **)t16);
    t16 = (t0 + 4753);
    t26 = *((int *)t16);
    t27 = (t26 - 1);
    t28 = (t27 - 16);
    t29 = (t28 * -1);
    xsi_vhdl_check_range_of_index(16, 0, -1, t27);
    t30 = (1U * t29);
    t31 = (0 + t30);
    t20 = (t17 + t31);
    t14 = *((unsigned char *)t20);
    t32 = (t0 + 4753);
    t33 = *((int *)t32);
    t34 = (t33 - 16);
    t35 = (t34 * -1);
    t36 = (1 * t35);
    t37 = (0U + t36);
    t38 = (t0 + 2636);
    t39 = (t38 + 32U);
    t40 = *((char **)t39);
    t41 = (t40 + 32U);
    t42 = *((char **)t41);
    *((unsigned char *)t42) = t14;
    xsi_driver_first_trans_delta(t38, t37, 1, t25);
    t43 = (t0 + 4753);
    t44 = *((int *)t43);
    t45 = (t44 - 16);
    t46 = (t45 * -1);
    t47 = (1 * t46);
    t48 = (0U + t47);
    t49 = (t0 + 2636);
    xsi_driver_intertial_reject(t49, t25, t25);

LAB31:    t2 = (t0 + 4753);
    t23 = *((int *)t2);
    t3 = (t0 + 4757);
    t24 = *((int *)t3);
    if (t23 == t24)
        goto LAB32;

LAB33:    t26 = (t23 + -1);
    t23 = t26;
    t7 = (t0 + 4753);
    *((int *)t7) = t23;
    goto LAB29;

LAB34:    t25 = (100 * 1LL);
    t2 = xsi_get_transient_memory(17U);
    memset(t2, 0, 17U);
    t7 = t2;
    memset(t7, (unsigned char)1, 17U);
    t8 = (t0 + 2636);
    t11 = (t8 + 32U);
    t12 = *((char **)t11);
    t16 = (t12 + 32U);
    t17 = *((char **)t16);
    memcpy(t17, t2, 17U);
    xsi_driver_first_trans_delta(t8, 0U, 17U, t25);
    t20 = (t0 + 2636);
    xsi_driver_intertial_reject(t20, t25, t25);
    goto LAB27;

LAB36:    t8 = (t0 + 1052U);
    t11 = *((char **)t8);
    t10 = *((unsigned char *)t11);
    t13 = (t10 == (unsigned char)3);
    if (t13 != 0)
        goto LAB41;

LAB43:
LAB42:    goto LAB21;

LAB38:    t3 = (t0 + 1028U);
    t7 = xsi_signal_last_value(t3);
    t6 = *((unsigned char *)t7);
    t9 = (t6 == (unsigned char)1);
    t4 = t9;
    goto LAB40;

LAB41:    t25 = (100 * 1LL);
    t8 = xsi_get_transient_memory(17U);
    memset(t8, 0, 17U);
    t12 = t8;
    memset(t12, (unsigned char)1, 17U);
    t16 = (t0 + 2636);
    t17 = (t16 + 32U);
    t20 = *((char **)t17);
    t32 = (t20 + 32U);
    t38 = *((char **)t32);
    memcpy(t38, t8, 17U);
    xsi_driver_first_trans_delta(t16, 0U, 17U, t25);
    t39 = (t0 + 2636);
    xsi_driver_intertial_reject(t39, t25, t25);
    goto LAB42;

LAB44:    t3 = (t0 + 2556);
    *((int *)t3) = 0;
    goto LAB2;

LAB45:    goto LAB44;

LAB47:    goto LAB45;

}


extern void unisim_a_2955733374_3996864970_init()
{
	static char *pe[] = {(void *)unisim_a_2955733374_3996864970_p_0,(void *)unisim_a_2955733374_3996864970_p_1};
	xsi_register_didat("unisim_a_2955733374_3996864970", "isim/hwt_tb_isim_beh.exe.sim/unisim/a_2955733374_3996864970.didat");
	xsi_register_executes(pe);
}
