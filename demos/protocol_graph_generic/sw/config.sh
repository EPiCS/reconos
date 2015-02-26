# set up generic app demo
mount -n -o remount,rw /; ./load_fsl.sh; ./load_getpgd.sh
./app
