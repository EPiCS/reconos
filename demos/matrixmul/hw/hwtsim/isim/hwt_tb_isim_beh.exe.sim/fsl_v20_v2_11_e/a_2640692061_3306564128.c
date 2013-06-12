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
static const char *ng0 = "/opt/Xilinx/14.4/ISE_DS/EDK/hw/XilinxProcessorIPLib/pcores/fsl_v20_v2_11_e/hdl/vhdl/gen_srlfifo.vhd";
extern char *IEEE_P_2592010699;

unsigned char ieee_p_2592010699_sub_1605435078_503743352(char *, unsigned char , unsigned char );
unsigned char ieee_p_2592010699_sub_1690584930_503743352(char *, unsigned char );
unsigned char ieee_p_2592010699_sub_2507238156_503743352(char *, unsigned char , unsigned char );
unsigned char ieee_p_2592010699_sub_2545490612_503743352(char *, unsigned char , unsigned char );


static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_0(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t4;
    unsigned int t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;

LAB0:    xsi_set_current_line(136, ng0);
    t1 = (t0 + 7432U);
    t2 = *((char **)t1);
    t1 = (t0 + 33672);
    t4 = 1;
    if (4U == 4U)
        goto LAB5;

LAB6:    t4 = 0;

LAB7:    if (t4 != 0)
        goto LAB3;

LAB4:
LAB11:    t13 = (t0 + 12656);
    t14 = (t13 + 32U);
    t15 = *((char **)t14);
    t16 = (t15 + 32U);
    t17 = *((char **)t16);
    *((unsigned char *)t17) = (unsigned char)2;
    xsi_driver_first_trans_fast(t13);

LAB2:    t18 = (t0 + 12524);
    *((int *)t18) = 1;

LAB1:    return;
LAB3:    t8 = (t0 + 12656);
    t9 = (t8 + 32U);
    t10 = *((char **)t9);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    *((unsigned char *)t12) = (unsigned char)3;
    xsi_driver_first_trans_fast(t8);
    goto LAB2;

LAB5:    t5 = 0;

LAB8:    if (t5 < 4U)
        goto LAB9;
    else
        goto LAB7;

LAB9:    t6 = (t2 + t5);
    t7 = (t1 + t5);
    if (*((unsigned char *)t6) != *((unsigned char *)t7))
        goto LAB6;

LAB10:    t5 = (t5 + 1);
    goto LAB8;

LAB12:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_1(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;

LAB0:    xsi_set_current_line(146, ng0);

LAB3:    t1 = (t0 + 6880U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 12692);
    t4 = (t1 + 32U);
    t5 = *((char **)t4);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = t3;
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t8 = (t0 + 12532);
    *((int *)t8) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_2(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t4;
    unsigned int t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;

LAB0:    xsi_set_current_line(151, ng0);
    t1 = (t0 + 6788U);
    t2 = *((char **)t1);
    t1 = (t0 + 33676);
    t4 = 1;
    if (4U == 4U)
        goto LAB5;

LAB6:    t4 = 0;

LAB7:    if (t4 != 0)
        goto LAB3;

LAB4:
LAB11:    t13 = (t0 + 12728);
    t14 = (t13 + 32U);
    t15 = *((char **)t14);
    t16 = (t15 + 32U);
    t17 = *((char **)t16);
    *((unsigned char *)t17) = (unsigned char)2;
    xsi_driver_first_trans_fast(t13);

LAB2:    t18 = (t0 + 12540);
    *((int *)t18) = 1;

LAB1:    return;
LAB3:    t8 = (t0 + 12728);
    t9 = (t8 + 32U);
    t10 = *((char **)t9);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    *((unsigned char *)t12) = (unsigned char)3;
    xsi_driver_first_trans_fast(t8);
    goto LAB2;

LAB5:    t5 = 0;

LAB8:    if (t5 < 4U)
        goto LAB9;
    else
        goto LAB7;

LAB9:    t6 = (t2 + t5);
    t7 = (t1 + t5);
    if (*((unsigned char *)t6) != *((unsigned char *)t7))
        goto LAB6;

LAB10:    t5 = (t5 + 1);
    goto LAB8;

LAB12:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_3(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    unsigned char t7;
    char *t8;
    unsigned char t9;
    char *t10;
    unsigned char t11;
    unsigned char t12;
    unsigned char t13;
    char *t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    unsigned char t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    xsi_set_current_line(153, ng0);

LAB3:    t1 = (t0 + 7156U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6972U);
    t4 = *((char **)t1);
    t5 = *((unsigned char *)t4);
    t6 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t5);
    t7 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t3, t6);
    t1 = (t0 + 6972U);
    t8 = *((char **)t1);
    t9 = *((unsigned char *)t8);
    t1 = (t0 + 6236U);
    t10 = *((char **)t1);
    t11 = *((unsigned char *)t10);
    t12 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t9, t11);
    t13 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t7, t12);
    t1 = (t0 + 7156U);
    t14 = *((char **)t1);
    t15 = *((unsigned char *)t14);
    t1 = (t0 + 6420U);
    t16 = *((char **)t1);
    t17 = *((unsigned char *)t16);
    t18 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t17);
    t19 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t15, t18);
    t20 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t13, t19);
    t1 = (t0 + 12764);
    t21 = (t1 + 32U);
    t22 = *((char **)t21);
    t23 = (t22 + 32U);
    t24 = *((char **)t23);
    *((unsigned char *)t24) = t20;
    xsi_driver_first_trans_fast(t1);

LAB2:    t25 = (t0 + 12548);
    *((int *)t25) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_4(char *t0)
{
    unsigned char t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    unsigned char t6;
    unsigned char t7;
    char *t8;
    unsigned char t9;
    unsigned char t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;

LAB0:    xsi_set_current_line(159, ng0);
    t2 = (t0 + 6028U);
    t3 = xsi_signal_has_event(t2);
    if (t3 == 1)
        goto LAB5;

LAB6:    t1 = (unsigned char)0;

LAB7:    if (t1 != 0)
        goto LAB2;

LAB4:
LAB3:    t2 = (t0 + 12556);
    *((int *)t2) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(160, ng0);
    t4 = (t0 + 6144U);
    t8 = *((char **)t4);
    t9 = *((unsigned char *)t8);
    t10 = (t9 == (unsigned char)3);
    if (t10 != 0)
        goto LAB8;

LAB10:    xsi_set_current_line(163, ng0);
    t2 = (t0 + 7064U);
    t4 = *((char **)t2);
    t1 = *((unsigned char *)t4);
    t2 = (t0 + 12800);
    t5 = (t2 + 32U);
    t8 = *((char **)t5);
    t11 = (t8 + 32U);
    t12 = *((char **)t11);
    *((unsigned char *)t12) = t1;
    xsi_driver_first_trans_fast(t2);

LAB9:    goto LAB3;

LAB5:    t4 = (t0 + 6052U);
    t5 = *((char **)t4);
    t6 = *((unsigned char *)t5);
    t7 = (t6 == (unsigned char)3);
    t1 = t7;
    goto LAB7;

LAB8:    xsi_set_current_line(161, ng0);
    t4 = (t0 + 12800);
    t11 = (t4 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    *((unsigned char *)t14) = (unsigned char)2;
    xsi_driver_first_trans_fast(t4);
    goto LAB9;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_5(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;

LAB0:    xsi_set_current_line(168, ng0);

LAB3:    t1 = (t0 + 7156U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 12836);
    t4 = (t1 + 32U);
    t5 = *((char **)t4);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = t3;
    xsi_driver_first_trans_fast_port(t1);

LAB2:    t8 = (t0 + 12564);
    *((int *)t8) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_6(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    unsigned char t5;
    char *t6;
    unsigned char t7;
    unsigned char t8;
    unsigned char t9;
    unsigned char t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    xsi_set_current_line(170, ng0);

LAB3:    t1 = (t0 + 6236U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6420U);
    t4 = *((char **)t1);
    t5 = *((unsigned char *)t4);
    t1 = (t0 + 6880U);
    t6 = *((char **)t1);
    t7 = *((unsigned char *)t6);
    t8 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t7);
    t9 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t5, t8);
    t10 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t3, t9);
    t1 = (t0 + 12872);
    t11 = (t1 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    *((unsigned char *)t14) = t10;
    xsi_driver_first_trans_fast(t1);

LAB2:    t15 = (t0 + 12572);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_7(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;

LAB0:    xsi_set_current_line(172, ng0);

LAB3:    t1 = (t0 + 7248U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 12908);
    t4 = (t1 + 32U);
    t5 = *((char **)t4);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    *((unsigned char *)t7) = t3;
    xsi_driver_first_trans_delta(t1, 0U, 1, 0LL);

LAB2:    t8 = (t0 + 12580);
    *((int *)t8) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_8(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    int t6;
    int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned char t11;
    unsigned char t12;
    char *t13;
    char *t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    unsigned char t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    xsi_set_current_line(176, ng0);

LAB3:    t1 = (t0 + 6420U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6788U);
    t4 = *((char **)t1);
    t1 = (t0 + 7924U);
    t5 = *((char **)t1);
    t6 = *((int *)t5);
    t7 = (t6 - 0);
    t8 = (t7 * 1);
    t9 = (1U * t8);
    t10 = (0 + t9);
    t1 = (t4 + t10);
    t11 = *((unsigned char *)t1);
    t12 = ieee_p_2592010699_sub_2507238156_503743352(IEEE_P_2592010699, t3, t11);
    t13 = (t0 + 6236U);
    t14 = *((char **)t13);
    t15 = *((unsigned char *)t14);
    t13 = (t0 + 6972U);
    t16 = *((char **)t13);
    t17 = *((unsigned char *)t16);
    t18 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t17);
    t19 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t15, t18);
    t20 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t12, t19);
    t13 = (t0 + 12944);
    t21 = (t13 + 32U);
    t22 = *((char **)t21);
    t23 = (t22 + 32U);
    t24 = *((char **)t23);
    *((unsigned char *)t24) = t20;
    xsi_driver_first_trans_delta(t13, 0U, 1, 0LL);

LAB2:    t25 = (t0 + 12588);
    *((int *)t25) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_9(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    int t6;
    int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned char t11;
    unsigned char t12;
    char *t13;
    char *t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    unsigned char t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    xsi_set_current_line(176, ng0);

LAB3:    t1 = (t0 + 6420U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6788U);
    t4 = *((char **)t1);
    t1 = (t0 + 7992U);
    t5 = *((char **)t1);
    t6 = *((int *)t5);
    t7 = (t6 - 0);
    t8 = (t7 * 1);
    t9 = (1U * t8);
    t10 = (0 + t9);
    t1 = (t4 + t10);
    t11 = *((unsigned char *)t1);
    t12 = ieee_p_2592010699_sub_2507238156_503743352(IEEE_P_2592010699, t3, t11);
    t13 = (t0 + 6236U);
    t14 = *((char **)t13);
    t15 = *((unsigned char *)t14);
    t13 = (t0 + 6972U);
    t16 = *((char **)t13);
    t17 = *((unsigned char *)t16);
    t18 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t17);
    t19 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t15, t18);
    t20 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t12, t19);
    t13 = (t0 + 12980);
    t21 = (t13 + 32U);
    t22 = *((char **)t21);
    t23 = (t22 + 32U);
    t24 = *((char **)t23);
    *((unsigned char *)t24) = t20;
    xsi_driver_first_trans_delta(t13, 1U, 1, 0LL);

LAB2:    t25 = (t0 + 12596);
    *((int *)t25) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_10(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    int t6;
    int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned char t11;
    unsigned char t12;
    char *t13;
    char *t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    unsigned char t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    xsi_set_current_line(176, ng0);

LAB3:    t1 = (t0 + 6420U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6788U);
    t4 = *((char **)t1);
    t1 = (t0 + 8060U);
    t5 = *((char **)t1);
    t6 = *((int *)t5);
    t7 = (t6 - 0);
    t8 = (t7 * 1);
    t9 = (1U * t8);
    t10 = (0 + t9);
    t1 = (t4 + t10);
    t11 = *((unsigned char *)t1);
    t12 = ieee_p_2592010699_sub_2507238156_503743352(IEEE_P_2592010699, t3, t11);
    t13 = (t0 + 6236U);
    t14 = *((char **)t13);
    t15 = *((unsigned char *)t14);
    t13 = (t0 + 6972U);
    t16 = *((char **)t13);
    t17 = *((unsigned char *)t16);
    t18 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t17);
    t19 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t15, t18);
    t20 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t12, t19);
    t13 = (t0 + 13016);
    t21 = (t13 + 32U);
    t22 = *((char **)t21);
    t23 = (t22 + 32U);
    t24 = *((char **)t23);
    *((unsigned char *)t24) = t20;
    xsi_driver_first_trans_delta(t13, 2U, 1, 0LL);

LAB2:    t25 = (t0 + 12604);
    *((int *)t25) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fsl_v20_v2_11_e_a_2640692061_3306564128_p_11(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    char *t4;
    char *t5;
    int t6;
    int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned char t11;
    unsigned char t12;
    char *t13;
    char *t14;
    unsigned char t15;
    char *t16;
    unsigned char t17;
    unsigned char t18;
    unsigned char t19;
    unsigned char t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;

LAB0:    xsi_set_current_line(176, ng0);

LAB3:    t1 = (t0 + 6420U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t1 = (t0 + 6788U);
    t4 = *((char **)t1);
    t1 = (t0 + 8128U);
    t5 = *((char **)t1);
    t6 = *((int *)t5);
    t7 = (t6 - 0);
    t8 = (t7 * 1);
    t9 = (1U * t8);
    t10 = (0 + t9);
    t1 = (t4 + t10);
    t11 = *((unsigned char *)t1);
    t12 = ieee_p_2592010699_sub_2507238156_503743352(IEEE_P_2592010699, t3, t11);
    t13 = (t0 + 6236U);
    t14 = *((char **)t13);
    t15 = *((unsigned char *)t14);
    t13 = (t0 + 6972U);
    t16 = *((char **)t13);
    t17 = *((unsigned char *)t16);
    t18 = ieee_p_2592010699_sub_1690584930_503743352(IEEE_P_2592010699, t17);
    t19 = ieee_p_2592010699_sub_2545490612_503743352(IEEE_P_2592010699, t15, t18);
    t20 = ieee_p_2592010699_sub_1605435078_503743352(IEEE_P_2592010699, t12, t19);
    t13 = (t0 + 13052);
    t21 = (t13 + 32U);
    t22 = *((char **)t21);
    t23 = (t22 + 32U);
    t24 = *((char **)t23);
    *((unsigned char *)t24) = t20;
    xsi_driver_first_trans_delta(t13, 3U, 1, 0LL);

LAB2:    t25 = (t0 + 12612);
    *((int *)t25) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}


extern void fsl_v20_v2_11_e_a_2640692061_3306564128_init()
{
	static char *pe[] = {(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_0,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_1,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_2,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_3,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_4,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_5,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_6,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_7,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_8,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_9,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_10,(void *)fsl_v20_v2_11_e_a_2640692061_3306564128_p_11};
	xsi_register_didat("fsl_v20_v2_11_e_a_2640692061_3306564128", "isim/hwt_tb_isim_beh.exe.sim/fsl_v20_v2_11_e/a_2640692061_3306564128.didat");
	xsi_register_executes(pe);
}
