mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
insmod lana.ko
insmod fb_dummy.ko
insmod fb_pflana.ko
./fbctl add eth1 ch.ethz.csg.dummy
./fbctl add fb1 ch.ethz.csg.dummy
./fbctl flag eth1 hw
./echo 2> output.txt &   #-> x
./fbctl bind x fb1
./fbctl bind fb1 eth1
./fbctl set x iface=lo

