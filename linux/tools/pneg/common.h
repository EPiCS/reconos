#ifndef COMMON_H
#define COMMON_H

#define TYPE_SUGGEST	1
#define TYPE_COMPOSE	2
#define TYPE_ACK	3
#define TYPE_NACK	4

#define MAXMSG		256

struct pn_hdr {
	uint16_t seq;
	uint16_t ack;
	uint8_t type;
};

#define STATE_MAP_SET(s, f)  {	\
	.num  = (s),		\
	.func = (f)		\
}

#endif /* COMMON_H */
