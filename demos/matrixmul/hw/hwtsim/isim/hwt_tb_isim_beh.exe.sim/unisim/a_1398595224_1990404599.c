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


static void unisim_a_1398595224_1990404599_p_0(char *t0)
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
    t3 = (t0 + 1704U);
    t12 = *((char **)t3);
    t3 = (t12 + 0);
    memcpy(t3, t1, 4U);
    t1 = (t0 + 1704U);
    t2 = *((char **)t1);
    t1 = (t0 + 4888U);
    t5 = unisim_p_3222816464_sub_2053111517_279109243(UNISIM_P_3222816464, t2, t1);
    t3 = (t0 + 1568U);
    t4 = *((char **)t3);
    t3 = (t4 + 0);
    *((unsigned char *)t3) = t5;
    t1 = (t0 + 1568U);
    t2 = *((char **)t1);
    t5 = *((unsigned char *)t2);
    if (t5 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 1636U);
    t2 = *((char **)t1);
    t1 = (t2 + 0);
    *((int *)t1) = 16;

LAB3:    t1 = (t0 + 1328U);
    t2 = *((char **)t1);
    t1 = (t0 + 1636U);
    t3 = *((char **)t1);
    t13 = *((int *)t3);
    t14 = (t13 - 16);
    t15 = (t14 * -1);
    xsi_vhdl_check_range_of_index(16, 0, -1, t13);
    t16 = (1U * t15);
    t17 = (0 + t16);
    t1 = (t2 + t17);
    t5 = *((unsigned char *)t1);
    t4 = (t0 + 2692);
    t6 = (t4 + 32U);
    t8 = *((char **)t6);
    t10 = (t8 + 32U);
    t12 = *((char **)t10);
    *((unsigned char *)t12) = t5;
    xsi_driver_first_trans_fast_port(t4);
    t1 = (t0 + 2632);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    t1 = (t0 + 1704U);
    t3 = *((char **)t1);
    t1 = (t0 + 4888U);
    t13 = unisim_p_3222816464_sub_3182959421_279109243(UNISIM_P_3222816464, t3, t1);
    t4 = (t0 + 1636U);
    t6 = *((char **)t4);
    t4 = (t6 + 0);
    *((int *)t4) = t13;
    goto LAB3;

}

static void unisim_a_1398595224_1990404599_p_1(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    unsigned char t4;
    unsigned char t5;
    unsigned char t6;
    unsigned char t7;
    char *t8;
    char *t9;
    unsigned char t10;
    unsigned char t11;
    char *t12;
    unsigned char t13;
    unsigned char t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    char *t19;
    char *t20;
    unsigned char t21;
    unsigned char t22;
    unsigned char t23;
    char *t24;
    char *t25;
    unsigned char t26;
    unsigned char t27;
    char *t28;
    unsigned char t29;
    unsigned char t30;
    int t31;
    int t32;
    int64 t33;
    int t34;
    int t35;
    int t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    int t40;
    int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    char *t45;
    char *t46;
    char *t47;
    char *t48;
    char *t49;
    char *t50;
    int t51;
    int t52;
    unsigned int t53;
    unsigned int t54;
    unsigned int t55;
    char *t56;

LAB0:    t1 = (t0 + 2452U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    t2 = (t0 + 1772U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    if (t4 != 0)
        goto LAB4;

LAB6:
LAB5:    t2 = (t0 + 1120U);
    t5 = xsi_signal_has_event(t2);
    if (t5 == 1)
        goto LAB29;

LAB30:    t4 = (unsigned char)0;

LAB31:    if (t4 != 0)
        goto LAB26;

LAB28:    t2 = (t0 + 1120U);
    t5 = xsi_signal_has_event(t2);
    if (t5 == 1)
        goto LAB52;

LAB53:    t4 = (unsigned char)0;

LAB54:    if (t4 != 0)
        goto LAB50;

LAB51:
LAB27:
LAB63:    t2 = (t0 + 2648);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB64;

LAB1:    return;
LAB4:
LAB9:    t2 = (t0 + 2640);
    *((int *)t2) = 1;
    *((char **)t1) = &&LAB10;
    goto LAB1;

LAB7:    t24 = (t0 + 2640);
    *((int *)t24) = 0;
    t2 = (t0 + 1772U);
    t3 = *((char **)t2);
    t2 = (t3 + 0);
    *((unsigned char *)t2) = (unsigned char)0;
    goto LAB5;

LAB8:    t8 = (t0 + 1052U);
    t9 = *((char **)t8);
    t10 = *((unsigned char *)t9);
    t11 = (t10 == (unsigned char)3);
    if (t11 == 1)
        goto LAB17;

LAB18:    t8 = (t0 + 1052U);
    t12 = *((char **)t8);
    t13 = *((unsigned char *)t12);
    t14 = (t13 == (unsigned char)2);
    t7 = t14;

LAB19:    if (t7 == 1)
        goto LAB14;

LAB15:    t6 = (unsigned char)0;

LAB16:    if (t6 == 1)
        goto LAB11;

LAB12:    t5 = (unsigned char)0;

LAB13:    if (t5 == 1)
        goto LAB7;
    else
        goto LAB9;

LAB10:    goto LAB8;

LAB11:    t24 = (t0 + 1144U);
    t25 = *((char **)t24);
    t26 = *((unsigned char *)t25);
    t27 = (t26 == (unsigned char)2);
    if (t27 == 1)
        goto LAB23;

LAB24:    t24 = (t0 + 1144U);
    t28 = *((char **)t24);
    t29 = *((unsigned char *)t28);
    t30 = (t29 == (unsigned char)3);
    t23 = t30;

LAB25:    t5 = t23;
    goto LAB13;

LAB14:    t8 = (t0 + 1120U);
    t16 = xsi_signal_last_value(t8);
    t17 = *((unsigned char *)t16);
    t18 = (t17 == (unsigned char)2);
    if (t18 == 1)
        goto LAB20;

LAB21:    t19 = (t0 + 1120U);
    t20 = xsi_signal_last_value(t19);
    t21 = *((unsigned char *)t20);
    t22 = (t21 == (unsigned char)3);
    t15 = t22;

LAB22:    t6 = t15;
    goto LAB16;

LAB17:    t7 = (unsigned char)1;
    goto LAB19;

LAB20:    t15 = (unsigned char)1;
    goto LAB22;

LAB23:    t23 = (unsigned char)1;
    goto LAB25;

LAB26:    t9 = (t0 + 1144U);
    t12 = *((char **)t9);
    t10 = *((unsigned char *)t12);
    t11 = (t10 == (unsigned char)3);
    if (t11 != 0)
        goto LAB32;

LAB34:    t2 = (t0 + 1144U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    t5 = (t4 == (unsigned char)1);
    if (t5 != 0)
        goto LAB45;

LAB46:
LAB33:    goto LAB27;

LAB29:    t3 = (t0 + 1120U);
    t8 = xsi_signal_last_value(t3);
    t6 = *((unsigned char *)t8);
    t7 = (t6 == (unsigned char)2);
    t4 = t7;
    goto LAB31;

LAB32:    t9 = (t0 + 1052U);
    t16 = *((char **)t9);
    t13 = *((unsigned char *)t16);
    t14 = (t13 == (unsigned char)3);
    if (t14 != 0)
        goto LAB35;

LAB37:    t2 = (t0 + 1052U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    t5 = (t4 == (unsigned char)1);
    if (t5 != 0)
        goto LAB43;

LAB44:
LAB36:    goto LAB33;

LAB35:    t9 = (t0 + 4949);
    *((int *)t9) = 15;
    t19 = (t0 + 4953);
    *((int *)t19) = 1;
    t31 = 15;
    t32 = 1;

LAB38:    if (t31 >= t32)
        goto LAB39;

LAB41:    t33 = (100 * 1LL);
    t2 = (t0 + 1236U);
    t3 = *((char **)t2);
    t4 = *((unsigned char *)t3);
    t2 = (t0 + 2728);
    t8 = (t2 + 32U);
    t9 = *((char **)t8);
    t12 = (t9 + 32U);
    t16 = *((char **)t12);
    *((unsigned char *)t16) = t4;
    xsi_driver_first_trans_delta(t2, 16U, 1, t33);
    t19 = (t0 + 2728);
    xsi_driver_intertial_reject(t19, t33, t33);
    goto LAB36;

LAB39:    t33 = (100 * 1LL);
    t20 = (t0 + 1328U);
    t24 = *((char **)t20);
    t20 = (t0 + 4949);
    t34 = *((int *)t20);
    t35 = (t34 - 1);
    t36 = (t35 - 16);
    t37 = (t36 * -1);
    xsi_vhdl_check_range_of_index(16, 0, -1, t35);
    t38 = (1U * t37);
    t39 = (0 + t38);
    t25 = (t24 + t39);
    t15 = *((unsigned char *)t25);
    t28 = (t0 + 4949);
    t40 = *((int *)t28);
    t41 = (t40 - 16);
    t42 = (t41 * -1);
    t43 = (1 * t42);
    t44 = (0U + t43);
    t45 = (t0 + 2728);
    t46 = (t45 + 32U);
    t47 = *((char **)t46);
    t48 = (t47 + 32U);
    t49 = *((char **)t48);
    *((unsigned char *)t49) = t15;
    xsi_driver_first_trans_delta(t45, t44, 1, t33);
    t50 = (t0 + 4949);
    t51 = *((int *)t50);
    t52 = (t51 - 16);
    t53 = (t52 * -1);
    t54 = (1 * t53);
    t55 = (0U + t54);
    t56 = (t0 + 2728);
    xsi_driver_intertial_reject(t56, t33, t33);

LAB40:    t2 = (t0 + 4949);
    t31 = *((int *)t2);
    t3 = (t0 + 4953);
    t32 = *((int *)t3);
    if (t31 == t32)
        goto LAB41;

LAB42:    t34 = (t31 + -1);
    t31 = t34;
    t8 = (t0 + 4949);
    *((int *)t8) = t31;
    goto LAB38;

LAB43:    t33 = (100 * 1LL);
    t2 = xsi_get_transient_memory(17U);
    memset(t2, 0, 17U);
    t8 = t2;
    memset(t8, (unsigned char)1, 17U);
    t9 = (t0 + 2728);
    t12 = (t9 + 32U);
    t16 = *((char **)t12);
    t19 = (t16 + 32U);
    t20 = *((char **)t19);
    memcpy(t20, t2, 17U);
    xsi_driver_first_trans_delta(t9, 0U, 17U, t33);
    t24 = (t0 + 2728);
    xsi_driver_intertial_reject(t24, t33, t33);
    goto LAB36;

LAB45:    t2 = (t0 + 1052U);
    t8 = *((char **)t2);
    t6 = *((unsigned char *)t8);
    t7 = (t6 != (unsigned char)2);
    if (t7 != 0)
        goto LAB47;

LAB49:
LAB48:    goto LAB33;

LAB47:    t33 = (100 * 1LL);
    t2 = xsi_get_transient_memory(17U);
    memset(t2, 0, 17U);
    t9 = t2;
    memset(t9, (unsigned char)1, 17U);
    t12 = (t0 + 2728);
    t16 = (t12 + 32U);
    t19 = *((char **)t16);
    t20 = (t19 + 32U);
    t24 = *((char **)t20);
    memcpy(t24, t2, 17U);
    xsi_driver_first_trans_delta(t12, 0U, 17U, t33);
    t25 = (t0 + 2728);
    xsi_driver_intertial_reject(t25, t33, t33);
    goto LAB48;

LAB50:    t9 = (t0 + 1144U);
    t12 = *((char **)t9);
    t10 = *((unsigned char *)t12);
    t11 = (t10 == (unsigned char)3);
    if (t11 != 0)
        goto LAB55;

LAB57:
LAB56:    goto LAB27;

LAB52:    t3 = (t0 + 1120U);
    t8 = xsi_signal_last_value(t3);
    t6 = *((unsigned char *)t8);
    t7 = (t6 == (unsigned char)1);
    t4 = t7;
    goto LAB54;

LAB55:    t9 = (t0 + 1052U);
    t16 = *((char **)t9);
    t13 = *((unsigned char *)t16);
    t14 = (t13 != (unsigned char)2);
    if (t14 != 0)
        goto LAB58;

LAB60:
LAB59:    goto LAB56;

LAB58:    t33 = (100 * 1LL);
    t9 = xsi_get_transient_memory(17U);
    memset(t9, 0, 17U);
    t19 = t9;
    memset(t19, (unsigned char)1, 17U);
    t20 = (t0 + 2728);
    t24 = (t20 + 32U);
    t25 = *((char **)t24);
    t28 = (t25 + 32U);
    t45 = *((char **)t28);
    memcpy(t45, t9, 17U);
    xsi_driver_first_trans_delta(t20, 0U, 17U, t33);
    t46 = (t0 + 2728);
    xsi_driver_intertial_reject(t46, t33, t33);
    goto LAB59;

LAB61:    t3 = (t0 + 2648);
    *((int *)t3) = 0;
    goto LAB2;

LAB62:    goto LAB61;

LAB64:    goto LAB62;

}


extern void unisim_a_1398595224_1990404599_init()
{
	static char *pe[] = {(void *)unisim_a_1398595224_1990404599_p_0,(void *)unisim_a_1398595224_1990404599_p_1};
	xsi_register_didat("unisim_a_1398595224_1990404599", "isim/hwt_tb_isim_beh.exe.sim/unisim/a_1398595224_1990404599.didat");
	xsi_register_executes(pe);
}
