# set up protocol graph demo
mount -n -o remount,rw /; ifconfig lo up; ./load_fsl.sh; ./load_getpgd.sh; insmod libreconos.ko
alias AES="cat partial_bitstreams/partial_aes.bit > /dev/icap0"; alias IPS="cat partial_bitstreams/partial_ips.bit > /dev/icap0"
insmod pr_hw_sw_interface.ko

# for partial reconfiguration
AES
IPS

#cat partial_bitstreams/partial_a.bit > /dev/icap0
#cat partial_bitstreams/partial_b.bit > /dev/icap0




./pr_demo_reconfig
