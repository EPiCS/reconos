mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
insmod lana.ko
insmod fb_dummy.ko
insmod fb_pflana.ko
./fbctl add eth1 ch.ethz.csg.dummy
./fbctl flag eth1 hw

./file_transfer_simple server 2> my_output.txt &

./fbctl bind x eth1
./fbctl set x iface=lo

