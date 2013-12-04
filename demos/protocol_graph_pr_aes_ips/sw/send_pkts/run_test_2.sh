#! /bin/bash

#impulses with variing packet rate, cd => aes
#./send_pkts packet_type scheme pps nr_of_pkts pkt_len
#./send_pkts cd 1 200 2000 64
#sleep 5
#./send_pkts cd 1 400 4000 64
#sleep 5
#./send_pkts ab 1 600 6000 64
#sleep 5
./send_pkts ab 1 1000 30000 1500
sleep 5
./send_pkts ab 1 1000 30000 1500
sleep 5
./send_pkts cd 1 1000 30000 1500
sleep 5
./send_pkts cd 1 1000 30000 1500
#sleep 5
#./send_pkts ab 1 1600 16000 1500
#sleep 5
#./send_pkts ab 1 1800 18000 1500
#sleep 5
#./send_pkts ab 1 2000 20000 1500
#sleep 5
#./send_pkts ab 1 2200 22000 1500
#sleep 5
#./send_pkts ab 1 2400 24000 1500
#sleep 5
#./send_pkts ab 1 2600 26000 1500
#sleep 5
#./send_pkts ab 1 2800 28000 1500
#sleep 5
#./send_pkts ab 1 3000 30000 64
#sleep 5
#./send_pkts ab 1 3200 32000 64
#sleep 5
#./send_pkts ab 1 3400 34000 64
#sleep 5
#./send_pkts ab 1 3600 36000 64
#sleep 5
#./send_pkts ab 1 3800 38000 64
#sleep 5
#./send_pkts ab 1 4000 40000 64
#sleep 5
#./send_pkts ab 1 4200 42000 64
#sleep 5
#./send_pkts ab 1 4400 44000 64
#sleep 5
#./send_pkts ab 1 4600 46000 64
