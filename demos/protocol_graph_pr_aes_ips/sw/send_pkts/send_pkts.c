#include<netinet/in.h>
#include<errno.h>
#include<netdb.h>
#include<stdio.h>                     //For standard things
#include<stdlib.h>                    //malloc
#include<string.h>                    //strlen 
#include<netinet/if_ether.h>          //For ETH_P_ALL
#include<net/ethernet.h>              //For ether_header
#include<sys/socket.h>
#include<arpa/inet.h>
#include<sys/ioctl.h>
#include<sys/time.h>
#include<sys/types.h>
#include<unistd.h>
#include <linux/if_packet.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <time.h>

#define ETH_INTERFACE "eth1"
#define BUF_SIZE 1600

char sendbuf[BUF_SIZE];
int sock_send;
struct ifreq if_idx;
struct ifreq if_mac;
struct sockaddr_ll socket_address;
struct ether_header *eh = (struct ether_header *) sendbuf;

unsigned char aes_payload[] = {0x2c, 0xf6, 0xa4, 0xdd, 0xe0, 0x85, 0x62, 0x82, 0x18, 0xfc, 0x97, 0xe0, 0x0c, 0x6d, 0x63, 0x94};
 
//! send a packet 
void send_packet(char *type, int packet_len){
	int i,tx_len = sizeof(struct ether_header);
	int j = 0;
	
	// do not change the Ethernet header
	memset(&sendbuf[tx_len], 0, BUF_SIZE-tx_len);
	// set parameter
	for (i = 0; i < 8; i++){
		sendbuf[tx_len++] = strtol(type, NULL, 16);
	}
//#ifdef aes
	if(strncmp(type, "cd", 2) == 0){
	//we can only process packets with a length of multiple of 16 bytes + 2.
	j = (packet_len - 22) / 16;
	packet_len = j * 16;
//	printf("packet_len %d \n", packet_len);
		for(j = 0; j < packet_len; j = j + 16){
		//	printf("j = %d\n", j);
			for(i = 0; i < 16; i++){
				sendbuf[tx_len++] = aes_payload[i];
			}
		}
		j = htons(packet_len);
		memcpy(sendbuf + tx_len, &j, 2);
		tx_len += 2;
	//	for (i = 102; i < packet_len - 2; i++){
	//	sendbuf[tx_len++] = (char) 1; //(rand() % 256 + 1);
	//	}
	}
	else{
//#endif
		for (i = 22; i < packet_len; i++){
			sendbuf[tx_len++] = (char) 1; //(rand() % 256 + 1);
		}
//#ifdef aes
	}
//#endif
	// send packet
	//if (send(sock_send, sendbuf, tx_len, 0) )
	if (sendto(sock_send, sendbuf, tx_len, 0,(struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0)
		printf("error: send packet failed\n");

	// print_packet
	/*printf("print packet: ");
	for (i=0;i<tx_len;i++){
		byte = sendbuf[i];
		tmp = (int)byte;
		printf("%08x ",tmp);
		if ((i+1)%4==0) printf("\n              ");
	}
	printf("\n");*/
}

//! main function
int main(int argc, char **argv)
{
	int data_size, ret,i,j;
        int counter = 0;
	long int counter2 = 0;
        unsigned char *buffer = (unsigned char *) malloc(1514); 
	struct timespec req;
	struct timespec rem;
	int scheme = -1;
	int packet_rate = -1;
	int nr_of_packets = -1;
	int packet_len = -1;
	
	if (argc < 3){
		printf("invalid syntax, arguments are: \n");
		printf("Usage: %s type (ab|cd) scheme(1 = packet rate) scheme_specific(packet rate, number of packets, packet len)\n", argv[0]);
		return -1;
	}
	//scheme 1, fixed packet length, fixed pps
	if (atoi(argv[2]) == 1){
		if (argc != 6){
			printf("Usage for scheme 1: %s type 1 packet rate, number of packets, packet len\n", argv[0]);
			return -1;
		}
		scheme = 1;
		packet_rate = atoi(argv[3]);
		nr_of_packets = atoi(argv[4]);
		packet_len = atoi(argv[5]);
		fprintf(stderr, "scheme %d: packet rate: %d, nr_of_packets: %d packet_len: %d\n", scheme, packet_rate, nr_of_packets, packet_len);
	}

	else if(atoi(argv[2]) == 2){
		if(argc != 4){
			printf("Usage for scheme 2: %s type 2 packet rate\n", argv[0]);
			return -1;
		}
		scheme = 2;
		packet_rate = atoi(argv[3]);
		fprintf(stderr, "scheme %d packet rate %d\n", scheme, packet_rate);
	
	}
	else if(atoi(argv[2]) == 3){
		scheme = 3;
		fprintf(stderr, "scheme %d (increasing pps)\n", scheme);
	
	}
	else if(atoi(argv[2]) == 4){
		scheme = 4;
		fprintf(stderr, "scheme %d (decreasing pps)\n", scheme);
	
	}

	else{
		fprintf(stderr, "scheme %d not found\n", atoi(argv[2]));
		return -1;
	}

	// socket to send packets 
	// Open RAW socket to send on
	if ((sock_send = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
		perror("socket");
	}
	// Get the index of the interface to send on
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ETH_INTERFACE, IFNAMSIZ-1);
	if (ioctl(sock_send, SIOCGIFINDEX, &if_idx) < 0)
		perror("SIOCGIFINDEX");
	// Get the MAC address of the interface to send on
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ETH_INTERFACE, IFNAMSIZ-1);
	if (ioctl(sock_send, SIOCGIFHWADDR, &if_mac) < 0)
		perror("SIOCGIFHWADDR");

	memset(sendbuf, 0, BUF_SIZE);

	// Index of the network device
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	// Address length
	socket_address.sll_halen = ETH_ALEN;
	// Destination MAC (here: broadcast address = ff:ff:ff:ff:ff:ff)
	memset(socket_address.sll_addr,0x01,6);
	// Ethernet header

	memset(eh->ether_shost,0x11, 6); //&if_mac.ifr_hwaddr.sa_data,6);
	memset(eh->ether_dhost,0xff,6);
	// Ethertype field
	eh->ether_type = htons(0xACDC);


	if (scheme == 1){
		if (packet_rate > 1){
			req.tv_sec = 0;
			req.tv_nsec = (double)1/(double)packet_rate*1000000000;
		}
		else{
			req.tv_sec = 1/packet_rate;
			req.tv_nsec = 0;
		}

		for (i = 0; i < nr_of_packets; i++){
			send_packet(argv[1], packet_len);
			nanosleep(&req, &rem);
		}
	}

	//variable packet size
	if (scheme == 2){
		if (packet_rate > 1){
			req.tv_sec = 0;
			req.tv_nsec = (double)1/(double)packet_rate*1000000000;
		}
		else{
			req.tv_sec = 1/packet_rate;
			req.tv_nsec = 0;
		}

		for (j = 0; j < 5; j++){
			for (i = 0; i < 10*packet_rate; i++){
				send_packet(argv[1], 64 + j*350);
				nanosleep(&req, &rem);
			}
		}
	}

	//increasing packet rate
	if (scheme == 3){
		int j = 0;
		int total = 0;
		packet_len = 1500;
		for (j = 150; j > 0; j--){
				packet_rate = j * 6.6;
				nr_of_packets = packet_rate;
			
		
	//		printf("j = %d, packet_rate = %d, nr_of_packets = %d\n", j, packet_rate, nr_of_packets);
			req.tv_sec = 0;
			req.tv_nsec = (double)1/(double)packet_rate*1000000000;
	
			for (i = 0; i < nr_of_packets; i++){
				send_packet(argv[1], packet_len);
				nanosleep(&req, &rem);
				total++;
			}
		}
		printf("total packets scheme 3: %d\n", total);
	}

	//decreasing packet rate
	if (scheme == 4){
		int j = 0;
		int total = 0;
		packet_len = 1500;
		for (j = 1; j <= 150; j++){
				packet_rate = j * 6.6;
				nr_of_packets = packet_rate;
			
		
		//	printf("j = %d, packet_rate = %d, nr_of_packets = %d\n", j, packet_rate, nr_of_packets);
			req.tv_sec = 0;
			req.tv_nsec = (double)1/(double)packet_rate*1000000000;
	
			for (i = 0; i < nr_of_packets; i++){
				send_packet(argv[1], packet_len);
				nanosleep(&req, &rem);
				total++;
			}
		}
		printf("total packets scheme 4: %d\n", total);

	}





	close(sock_send);


	printf("Finished (%d)\n", nr_of_packets);
	return 0;
}


