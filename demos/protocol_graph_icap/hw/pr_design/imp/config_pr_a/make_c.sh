name="hwt_pr_a"
name2="hwt_aes"

rm -f bitstreams_${name2}.c

../../tools/bin2c ${name2} < system_hwt_pr_0_${name}_partial.bin >> bitstreams_${name2}.c




