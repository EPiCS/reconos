name="hwt_pr_b"
name2="hwt_ips"

rm -f bitstreams_${name2}.c

../../tools/bin2c ${name2} < system_hwt_pr_0_${name}_partial.bin >> bitstreams_${name2}.c




