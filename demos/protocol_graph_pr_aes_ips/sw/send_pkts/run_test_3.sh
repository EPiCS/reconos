#! /bin/bash

#impulses with variing packet rate, cd => aes
#./send_pkts packet_type scheme pps nr_of_pkts pkt_len
sudo ./send_pkts ab 3 &
sudo ./send_pkts cd 4 &

