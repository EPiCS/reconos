/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#ifndef NOTIFICATION_H
#define NOTIFICATION_H

#include <sys/types.h>

#define SOCK_ADDR	"sensordsock"

#ifndef __packed
# define __packed	__attribute__((packed))
#endif

#define CMD_SET_UPPER_THRES	1	/* pid notifier, upper thres */
#define CMD_SET_LOWER_THRES	2	/* pid notifier, lower thres */
#define CMD_GET_VALUE		3	/* fetch db value */

#define PLUGIN_INST_SIZ		64

struct notfct_hdr {
	uint8_t cmd;
	pid_t proc;
	char plugin_inst[PLUGIN_INST_SIZ];
} __packed;

#endif /* NOTIFICATION_H */
