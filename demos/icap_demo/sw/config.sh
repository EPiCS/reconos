# set up icap demo
mount -n -o remount,rw /; ./load_fsl2.sh; ./load_getpgd.sh
./icap_demo
