#!/bin/bash


################################################################################
#                                                                              #
#                      CONFIGURATION A, ADDITION                               #
#                                                                              #
################################################################################
echo "######################################################################"
echo "######################################################################"
echo "######################################################################"
echo ""
echo "BUILDING CONFIGURATION A"
echo ""
echo "######################################################################"
echo "######################################################################"
echo "######################################################################"

# Make sure that we are really building the addition
sed -i '14s/.*/    G_ADD : boolean := true/' ./pcores/hwt_pr_block_v1_00_a/hdl/vhdl/hwt_pr_block.vhd
# build mul
rm ./pcores/hwt_pr_app_v1_00_a
ln -s ../../pcores/hwt_pr_mul_v1_00_a/ ./pcores/hwt_pr_app_v1_00_a

################################################################################
# Building netlist
################################################################################
echo "run netlist" | xps -nw ./system.xmp

################################################################################
# Move netlist to new folder where PAR is executed
################################################################################
cp ./implementation/*.ngc ../pr_design/syn/static/

# Netlist of Reconfigurable Module is moved to a folder specific for this
# configuration
mv ../pr_design/syn/static/system_hwt_pr_block_0_wrapper.ngc ../pr_design/syn/pr_a/
mv ../pr_design/syn/static/system_hwt_pr_block_1_wrapper.ngc ../pr_design/syn/pr_a/

echo "CONFIGURATION A FINISHED"

################################################################################
#                                                                              #
#                      CONFIGURATION B, SUBTRACTION                            #
#                                                                              #
################################################################################
echo "######################################################################"
echo "######################################################################"
echo "######################################################################"
echo ""
echo "BUILDING CONFIGURATION B"
echo ""
echo "######################################################################"
echo "######################################################################"
echo "######################################################################"

# Make sure that we are really building the subtraction
sed -i '14s/.*/    G_ADD : boolean := false/' ./pcores/hwt_pr_block_v1_00_a/hdl/vhdl/hwt_pr_block.vhd
# build lfsr
rm ./pcores/hwt_pr_app_v1_00_a
ln -s ../../pcores/hwt_pr_lfsr_v1_00_a/ ./pcores/hwt_pr_app_v1_00_a

################################################################################
# Building netlist
################################################################################
echo "run netlist" | xps -nw ./system.xmp

################################################################################
# Move netlist to new folder where PAR is executed
################################################################################
#cp ./implementation/*.ngc ../pr_design/syn/static/

# Netlist of Reconfigurable Module is moved to a folder specific for this
# configuration
cp ./implementation/system_hwt_pr_block_0_wrapper.ngc ../pr_design/syn/pr_b/
cp ./implementation/system_hwt_pr_block_1_wrapper.ngc ../pr_design/syn/pr_b/

echo "CONFIGURATION B FINISHED"


# restore addition as this is what is on git, we do not want useless commits for
# this stuff
sed -i '14s/.*/    G_ADD : boolean := true/' ./pcores/hwt_pr_block_v1_00_a/hdl/vhdl/hwt_pr_block.vhd
# build mul
rm ./pcores/hwt_pr_app_v1_00_a
ln -s ../../pcores/hwt_pr_mul_v1_00_a/ ./pcores/hwt_pr_app_v1_00_a
