#!/bin/bash

cd ./imp/config_pr_a/
./generate_config.sh

cd ../..

# copy bitfiles
cp ./imp/config_pr_a/system.bit ./bitfiles/system_add.bit
cp ./imp/config_pr_a/system_hwt_pr_block_0_hwt_pr_a_partial.bin ./bitfiles/partial_add.bin
cp ./imp/config_pr_a/system_hwt_pr_block_0_hwt_pr_a_partial.bit ./bitfiles/partial_add.bit
cp ./imp/config_pr_a/system_hwt_pr_block_1_hwt_pr_a_partial.bin ./bitfiles/partial_mul.bin
cp ./imp/config_pr_a/system_hwt_pr_block_1_hwt_pr_a_partial.bit ./bitfiles/partial_mul.bit

cd ./imp/config_pr_b/
./generate_config.sh

cd ../..

# copy bitfiles
cp ./imp/config_pr_b/system.bit ./bitfiles/system_sub.bit
cp ./imp/config_pr_b/system_hwt_pr_block_0_hwt_pr_b_partial.bin ./bitfiles/partial_sub.bin
cp ./imp/config_pr_b/system_hwt_pr_block_0_hwt_pr_b_partial.bit ./bitfiles/partial_sub.bit
cp ./imp/config_pr_b/system_hwt_pr_block_1_hwt_pr_b_partial.bin ./bitfiles/partial_lfsr.bin
cp ./imp/config_pr_b/system_hwt_pr_block_1_hwt_pr_b_partial.bit ./bitfiles/partial_lfsr.bit
