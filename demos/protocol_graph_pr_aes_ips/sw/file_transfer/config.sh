mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
insmod lana.ko
insmod fb_dummy.ko
insmod fb_aes_enc.ko
insmod fb_pflana.ko
./fbctl add eth1 ch.ethz.csg.dummy
./fbctl add fb1 ch.ethz.csg.aes
echo "Hello World1234" > /proc/net/lana/fblock/fb1
./fbctl flag eth1 hw
./echo 2> output.txt &   #-> x
./fbctl bind x eth1
./fbctl set x iface=lo
./fbctl unbind x eth1
./fbctl bind fb1 eth1
./fbctl bind x fb1
./fbctl flag fb1 hw


mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
insmod lana.ko
insmod fb_dummy.ko
insmod fb_ips.ko
insmod fb_pflana.ko
./fbctl add eth1 ch.ethz.csg.dummy
./fbctl add ips ch.ethz.csg.ips
./fbctl add eth2 ch.ethz.csg.dummy
./fbctl add aes ch.ethz.csg.ips

./fbctl flag eth1 hw
./fbctl flag eth2 hw

./fbctl unflag ips hw
./fbctl unflag aes hw

./fbctl bind ips eth1
./fbctl bind aes eth1

./file_transfer_simple client 2>out.txt &


