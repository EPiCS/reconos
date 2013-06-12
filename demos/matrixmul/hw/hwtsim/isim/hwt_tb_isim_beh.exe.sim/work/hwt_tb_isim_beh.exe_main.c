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

#include "xsi.h"

struct XSI_INFO xsi_info;

char *IEEE_P_1242562249;
char *PROC_COMMON_V3_00_A_P_2444876401;
char *IEEE_P_2592010699;
char *STD_STANDARD;
char *IEEE_P_3620187407;
char *IEEE_P_3499444699;
char *UNISIM_P_0947159679;
char *RECONOS_V3_00_B_P_3499986223;
char *IEEE_P_2717149903;
char *STD_TEXTIO;
char *UNISIM_P_3222816464;
char *IEEE_P_1367372525;


int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    ieee_p_2592010699_init();
    ieee_p_3499444699_init();
    ieee_p_3620187407_init();
    proc_common_v3_00_a_p_2444876401_init();
    reconos_v3_00_b_p_3499986223_init();
    unisim_p_0947159679_init();
    work_a_0099215392_3212880686_init();
    work_a_1147007984_3640575771_init();
    std_textio_init();
    ieee_p_2717149903_init();
    ieee_p_1367372525_init();
    unisim_p_3222816464_init();
    ieee_p_1242562249_init();
    unisim_a_2955733374_3996864970_init();
    unisim_a_1836616293_3089378898_init();
    unisim_a_0868425105_1864968857_init();
    unisim_a_3193750915_0385652344_init();
    unisim_a_3484885994_2523279426_init();
    unisim_a_1398595224_1990404599_init();
    fsl_v20_v2_11_e_a_2640692061_3306564128_init();
    fsl_v20_v2_11_e_a_3271584164_0090727531_init();
    fsl_v20_v2_11_e_a_3736320033_3306564128_init();
    fifo32_v1_00_a_a_1491014556_3640575771_init();
    work_a_3392787015_3212880686_init();
    work_a_0308195381_2372691052_init();


    xsi_register_tops("work_a_0308195381_2372691052");

    IEEE_P_1242562249 = xsi_get_engine_memory("ieee_p_1242562249");
    PROC_COMMON_V3_00_A_P_2444876401 = xsi_get_engine_memory("proc_common_v3_00_a_p_2444876401");
    IEEE_P_2592010699 = xsi_get_engine_memory("ieee_p_2592010699");
    xsi_register_ieee_std_logic_1164(IEEE_P_2592010699);
    STD_STANDARD = xsi_get_engine_memory("std_standard");
    IEEE_P_3620187407 = xsi_get_engine_memory("ieee_p_3620187407");
    IEEE_P_3499444699 = xsi_get_engine_memory("ieee_p_3499444699");
    UNISIM_P_0947159679 = xsi_get_engine_memory("unisim_p_0947159679");
    RECONOS_V3_00_B_P_3499986223 = xsi_get_engine_memory("reconos_v3_00_b_p_3499986223");
    IEEE_P_2717149903 = xsi_get_engine_memory("ieee_p_2717149903");
    STD_TEXTIO = xsi_get_engine_memory("std_textio");
    UNISIM_P_3222816464 = xsi_get_engine_memory("unisim_p_3222816464");
    IEEE_P_1367372525 = xsi_get_engine_memory("ieee_p_1367372525");

    return xsi_run_simulation(argc, argv);

}
