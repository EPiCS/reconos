# set up protocol graph demo
mount -n -o remount,rw /; ifconfig lo up; ./load_fsl.sh; ./load_getpgd.sh; 
./pr_demo

