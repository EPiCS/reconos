#ifndef NOTIFICATION_H
#define NOTIFICATION_H

#include <sys/types.h>
#include <signal.h>

#include "timedb.h"

#define SIG_THRES_UPPER	SIGUSR1
#define SIG_THRES_LOWER	SIGUSR2

#define SOCK_ADDR	"/tmp/sensordsock"

#ifndef __packed
# define __packed	__attribute__((packed))
#endif

#define CMD_SET_UPPER_THRES	1	/* pid notifier, upper thres */
#define CMD_SET_LOWER_THRES	2	/* pid notifier, lower thres */
#define CMD_GET_VALUE		3	/* fetch db value */
#define CMD_SET_UNDO_THRES	4	/* deregister threshold */

#define PLUGIN_INST_SIZ		64

struct notfct_hdr {
	uint8_t cmd;
	pid_t proc;
	char plugin_inst[PLUGIN_INST_SIZ];
} __packed;

enum threshold_type {
	upper_threshold,
	lower_threshold,
};

struct shmnot_hdr {
	float64_t val;
	uint16_t cell_num;
	char plugin_inst[PLUGIN_INST_SIZ];
} __packed;

#endif /* NOTIFICATION_H */
