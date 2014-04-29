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
static const char *ng0 = "/home/aloesch/reconos/pcores/fifo32_v1_00_a/hdl/vhdl/fifo32.vhd";
extern char *IEEE_P_2592010699;
extern char *IEEE_P_3620187407;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );
unsigned char ieee_p_3620187407_sub_2546418145_3965413181(char *, char *, char *, int );
char *ieee_p_3620187407_sub_27954454_3965413181(char *, char *, int , char *, char *);
char *ieee_p_3620187407_sub_28026328_3965413181(char *, char *, int , char *, char *);
unsigned char ieee_p_3620187407_sub_4060537613_3965413181(char *, char *, char *, char *, char *);
char *ieee_p_3620187407_sub_436279890_3965413181(char *, char *, char *, char *, int );
int ieee_p_3620187407_sub_514432868_3965413181(char *, char *, char *);
char *ieee_p_3620187407_sub_767740470_3965413181(char *, char *, char *, char *, char *, char *);


static void fifo32_v1_00_a_a_1491014556_3640575771_p_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    xsi_set_current_line(35, ng0);

LAB3:    t1 = xsi_get_transient_memory(6U);
    memset(t1, 0, 6U);
    t2 = t1;
    memset(t2, (unsigned char)2, 6U);
    t3 = (t0 + 3820);
    t4 = (t3 + 32U);
    t5 = *((char **)t4);
    t6 = (t5 + 32U);
    t7 = *((char **)t6);
    memcpy(t7, t1, 6U);
    xsi_driver_first_trans_fast(t3);

LAB2:
LAB1:    return;
LAB4:    goto LAB2;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_1(char *t0)
{
    char t4[16];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned char t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    xsi_set_current_line(37, ng0);

LAB3:    t1 = (t0 + 1880U);
    t2 = *((char **)t1);
    t1 = (t0 + 1788U);
    t3 = *((char **)t1);
    t5 = ((IEEE_P_2592010699) + 2312);
    t6 = (t0 + 7252U);
    t7 = (t0 + 7236U);
    t1 = xsi_base_array_concat(t1, t4, t5, (char)97, t2, t6, (char)97, t3, t7, (char)101);
    t8 = (6U + 10U);
    t9 = (16U != t8);
    if (t9 == 1)
        goto LAB5;

LAB6:    t10 = (t0 + 3856);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    memcpy(t14, t1, 16U);
    xsi_driver_first_trans_fast_port(t10);

LAB2:    t15 = (t0 + 3728);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

LAB5:    xsi_size_not_matching(16U, t8, 0);
    goto LAB6;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_2(char *t0)
{
    char t4[16];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned char t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    xsi_set_current_line(38, ng0);

LAB3:    t1 = (t0 + 1880U);
    t2 = *((char **)t1);
    t1 = (t0 + 1696U);
    t3 = *((char **)t1);
    t5 = ((IEEE_P_2592010699) + 2312);
    t6 = (t0 + 7252U);
    t7 = (t0 + 7220U);
    t1 = xsi_base_array_concat(t1, t4, t5, (char)97, t2, t6, (char)97, t3, t7, (char)101);
    t8 = (6U + 10U);
    t9 = (16U != t8);
    if (t9 == 1)
        goto LAB5;

LAB6:    t10 = (t0 + 3892);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    memcpy(t14, t1, 16U);
    xsi_driver_first_trans_fast_port(t10);

LAB2:    t15 = (t0 + 3736);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

LAB5:    xsi_size_not_matching(16U, t8, 0);
    goto LAB6;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_3(char *t0)
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

LAB0:    xsi_set_current_line(39, ng0);

LAB3:    t1 = (t0 + 1420U);
    t2 = *((char **)t1);
    t1 = (t0 + 1604U);
    t3 = *((char **)t1);
    t1 = (t0 + 7204U);
    t4 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t3, t1);
    t5 = (t4 - 0);
    t6 = (t5 * 1);
    xsi_vhdl_check_range_of_index(0, 1023, 1, t4);
    t7 = (32U * t6);
    t8 = (0 + t7);
    t9 = (t2 + t8);
    t10 = (t0 + 3928);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    memcpy(t14, t9, 32U);
    xsi_driver_first_trans_fast_port(t10);

LAB2:    t15 = (t0 + 3744);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_4(char *t0)
{
    char t6[16];
    char t21[16];
    char t22[16];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    unsigned char t5;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned char t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    unsigned int t30;
    unsigned int t31;
    unsigned char t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;

LAB0:    xsi_set_current_line(41, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t1 = (t0 + 7188U);
    t3 = (t0 + 1604U);
    t4 = *((char **)t3);
    t3 = (t0 + 7204U);
    t5 = ieee_p_3620187407_sub_4060537613_3965413181(IEEE_P_3620187407, t2, t1, t4, t3);
    if (t5 != 0)
        goto LAB3;

LAB4:
LAB7:    t23 = (t0 + 1512U);
    t24 = *((char **)t23);
    t23 = (t0 + 7188U);
    t25 = ieee_p_3620187407_sub_27954454_3965413181(IEEE_P_3620187407, t22, 1024, t24, t23);
    t26 = (t0 + 1604U);
    t27 = *((char **)t26);
    t26 = (t0 + 7204U);
    t28 = ieee_p_3620187407_sub_767740470_3965413181(IEEE_P_3620187407, t21, t25, t22, t27, t26);
    t29 = (t21 + 12U);
    t30 = *((unsigned int *)t29);
    t31 = (1U * t30);
    t32 = (10U != t31);
    if (t32 == 1)
        goto LAB9;

LAB10:    t33 = (t0 + 3964);
    t34 = (t33 + 32U);
    t35 = *((char **)t34);
    t36 = (t35 + 32U);
    t37 = *((char **)t36);
    memcpy(t37, t28, 10U);
    xsi_driver_first_trans_fast(t33);

LAB2:    t38 = (t0 + 3752);
    *((int *)t38) = 1;

LAB1:    return;
LAB3:    t7 = (t0 + 1512U);
    t8 = *((char **)t7);
    t7 = (t0 + 7188U);
    t9 = (t0 + 1604U);
    t10 = *((char **)t9);
    t9 = (t0 + 7204U);
    t11 = ieee_p_3620187407_sub_767740470_3965413181(IEEE_P_3620187407, t6, t8, t7, t10, t9);
    t12 = (t6 + 12U);
    t13 = *((unsigned int *)t12);
    t14 = (1U * t13);
    t15 = (10U != t14);
    if (t15 == 1)
        goto LAB5;

LAB6:    t16 = (t0 + 3964);
    t17 = (t16 + 32U);
    t18 = *((char **)t17);
    t19 = (t18 + 32U);
    t20 = *((char **)t19);
    memcpy(t20, t11, 10U);
    xsi_driver_first_trans_fast(t16);
    goto LAB2;

LAB5:    xsi_size_not_matching(10U, t14, 0);
    goto LAB6;

LAB8:    goto LAB2;

LAB9:    xsi_size_not_matching(10U, t31, 0);
    goto LAB10;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_5(char *t0)
{
    char t1[16];
    int t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned char t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;

LAB0:    xsi_set_current_line(42, ng0);

LAB3:    t2 = (1024 - 1);
    t3 = (t0 + 1788U);
    t4 = *((char **)t3);
    t3 = (t0 + 7236U);
    t5 = ieee_p_3620187407_sub_28026328_3965413181(IEEE_P_3620187407, t1, t2, t4, t3);
    t6 = (t1 + 12U);
    t7 = *((unsigned int *)t6);
    t8 = (1U * t7);
    t9 = (10U != t8);
    if (t9 == 1)
        goto LAB5;

LAB6:    t10 = (t0 + 4000);
    t11 = (t10 + 32U);
    t12 = *((char **)t11);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    memcpy(t14, t5, 10U);
    xsi_driver_first_trans_fast(t10);

LAB2:    t15 = (t0 + 3760);
    *((int *)t15) = 1;

LAB1:    return;
LAB4:    goto LAB2;

LAB5:    xsi_size_not_matching(10U, t8, 0);
    goto LAB6;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_6(char *t0)
{
    char t19[16];
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    unsigned char t11;
    int t12;
    int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    char *t17;
    char *t18;

LAB0:    xsi_set_current_line(46, ng0);
    t1 = (t0 + 592U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 752U);
    t3 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 3768);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(47, ng0);
    t1 = xsi_get_transient_memory(10U);
    memset(t1, 0, 10U);
    t5 = t1;
    memset(t5, (unsigned char)2, 10U);
    t6 = (t0 + 4036);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 32U);
    t10 = *((char **)t9);
    memcpy(t10, t1, 10U);
    xsi_driver_first_trans_fast(t6);
    goto LAB3;

LAB5:    xsi_set_current_line(49, ng0);
    t2 = (t0 + 1328U);
    t5 = *((char **)t2);
    t4 = *((unsigned char *)t5);
    t11 = (t4 == (unsigned char)3);
    if (t11 != 0)
        goto LAB7;

LAB9:
LAB8:    goto LAB3;

LAB7:    xsi_set_current_line(50, ng0);
    t2 = (t0 + 960U);
    t6 = *((char **)t2);
    t2 = (t0 + 1512U);
    t7 = *((char **)t2);
    t2 = (t0 + 7188U);
    t12 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t7, t2);
    t13 = (t12 - 0);
    t14 = (t13 * 1);
    t15 = (32U * t14);
    t16 = (0U + t15);
    t8 = (t0 + 4072);
    t9 = (t8 + 32U);
    t10 = *((char **)t9);
    t17 = (t10 + 32U);
    t18 = *((char **)t17);
    memcpy(t18, t6, 32U);
    xsi_driver_first_trans_delta(t8, t16, 32U, 0LL);
    xsi_set_current_line(51, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t1 = (t0 + 7188U);
    t12 = (1024 - 1);
    t3 = ieee_p_3620187407_sub_2546418145_3965413181(IEEE_P_3620187407, t2, t1, t12);
    if (t3 != 0)
        goto LAB10;

LAB12:    xsi_set_current_line(54, ng0);
    t1 = (t0 + 1512U);
    t2 = *((char **)t1);
    t1 = (t0 + 7188U);
    t5 = ieee_p_3620187407_sub_436279890_3965413181(IEEE_P_3620187407, t19, t2, t1, 1);
    t6 = (t19 + 12U);
    t14 = *((unsigned int *)t6);
    t15 = (1U * t14);
    t3 = (10U != t15);
    if (t3 == 1)
        goto LAB13;

LAB14:    t7 = (t0 + 4036);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    t10 = (t9 + 32U);
    t17 = *((char **)t10);
    memcpy(t17, t5, 10U);
    xsi_driver_first_trans_fast(t7);

LAB11:    goto LAB8;

LAB10:    xsi_set_current_line(52, ng0);
    t5 = xsi_get_transient_memory(10U);
    memset(t5, 0, 10U);
    t6 = t5;
    memset(t6, (unsigned char)2, 10U);
    t7 = (t0 + 4036);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    t10 = (t9 + 32U);
    t17 = *((char **)t10);
    memcpy(t17, t5, 10U);
    xsi_driver_first_trans_fast(t7);
    goto LAB11;

LAB13:    xsi_size_not_matching(10U, t15, 0);
    goto LAB14;

}

static void fifo32_v1_00_a_a_1491014556_3640575771_p_7(char *t0)
{
    char t17[16];
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    unsigned char t11;
    int t12;
    unsigned char t13;
    char *t14;
    char *t15;
    char *t16;
    unsigned int t18;
    unsigned int t19;

LAB0:    xsi_set_current_line(62, ng0);
    t1 = (t0 + 592U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 660U);
    t3 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 3776);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(63, ng0);
    t1 = xsi_get_transient_memory(10U);
    memset(t1, 0, 10U);
    t5 = t1;
    memset(t5, (unsigned char)2, 10U);
    t6 = (t0 + 4108);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 32U);
    t10 = *((char **)t9);
    memcpy(t10, t1, 10U);
    xsi_driver_first_trans_fast(t6);
    goto LAB3;

LAB5:    xsi_set_current_line(65, ng0);
    t2 = (t0 + 1236U);
    t5 = *((char **)t2);
    t4 = *((unsigned char *)t5);
    t11 = (t4 == (unsigned char)3);
    if (t11 != 0)
        goto LAB7;

LAB9:
LAB8:    goto LAB3;

LAB7:    xsi_set_current_line(66, ng0);
    t2 = (t0 + 1604U);
    t6 = *((char **)t2);
    t2 = (t0 + 7204U);
    t12 = (1024 - 1);
    t13 = ieee_p_3620187407_sub_2546418145_3965413181(IEEE_P_3620187407, t6, t2, t12);
    if (t13 != 0)
        goto LAB10;

LAB12:    xsi_set_current_line(69, ng0);
    t1 = (t0 + 1604U);
    t2 = *((char **)t1);
    t1 = (t0 + 7204U);
    t5 = ieee_p_3620187407_sub_436279890_3965413181(IEEE_P_3620187407, t17, t2, t1, 1);
    t6 = (t17 + 12U);
    t18 = *((unsigned int *)t6);
    t19 = (1U * t18);
    t3 = (10U != t19);
    if (t3 == 1)
        goto LAB13;

LAB14:    t7 = (t0 + 4108);
    t8 = (t7 + 32U);
    t9 = *((char **)t8);
    t10 = (t9 + 32U);
    t14 = *((char **)t10);
    memcpy(t14, t5, 10U);
    xsi_driver_first_trans_fast(t7);

LAB11:    goto LAB8;

LAB10:    xsi_set_current_line(67, ng0);
    t7 = xsi_get_transient_memory(10U);
    memset(t7, 0, 10U);
    t8 = t7;
    memset(t8, (unsigned char)2, 10U);
    t9 = (t0 + 4108);
    t10 = (t9 + 32U);
    t14 = *((char **)t10);
    t15 = (t14 + 32U);
    t16 = *((char **)t15);
    memcpy(t16, t7, 10U);
    xsi_driver_first_trans_fast(t9);
    goto LAB11;

LAB13:    xsi_size_not_matching(10U, t19, 0);
    goto LAB14;

}


extern void fifo32_v1_00_a_a_1491014556_3640575771_init()
{
	static char *pe[] = {(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_0,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_1,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_2,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_3,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_4,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_5,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_6,(void *)fifo32_v1_00_a_a_1491014556_3640575771_p_7};
	xsi_register_didat("fifo32_v1_00_a_a_1491014556_3640575771", "isim/hwt_tb_isim_beh.exe.sim/fifo32_v1_00_a/a_1491014556_3640575771.didat");
	xsi_register_executes(pe);
}
