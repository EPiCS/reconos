mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
insmod lana.ko
insmod fb_dummy.ko
insmod fb_aes_de.ko
insmod fb_pflana.ko
./fbctl add eth1 ch.ethz.csg.dummy
./fbctl add aes ch.ethz.csg.aes
echo "Hello World1234" > /proc/net/lana/fblock/aes
./fbctl flag eth1 hw
./fbctl unflag aes hw
./fbctl bind aes eth1
./file_transfer_simple client 2> out.txt &  #-> x
./fbctl bind x aes
./fbctl set x iface=lo


mount -n -o remount,rw /
ifconfig lo up
./load_fsl.sh
./load_getpgd.sh
insmod libreconos.ko
#insmod lana.ko
insmod lana_dyn.ko
insmod fb_dummy.ko
insmod fb_ips.ko
insmod fb_aes_dec.ko
insmod fb_pflana.ko

./fbctl add eth1 ch.ethz.csg.dummy
#./fbctl add ips ch.ethz.csg.dummy
./fbctl add ips ch.ethz.csg.ips
./fbctl flag eth1 hw
./fbctl unflag ips hw
./fbctl bind ips eth1
./file_transfer_simple client 2>out1.txt &
./fbctl bind x ips
./fbctl set x iface=lo


./fbctl add eth2 ch.ethz.csg.dummy
./fbctl add aes ch.ethz.csg.aes
#./fbctl add aes ch.ethz.csg.dummy
echo "Hello World1234" > /proc/net/lana/fblock/aes
./fbctl flag eth2 hw
./fbctl unflag aes hw
./fbctl bind aes eth2
./file_transfer_simple client 2>out2.txt &
./fbctl bind x aes
./fbctl set x iface=lo

./pr_reconfig
cat /proc/net/lana/stats
