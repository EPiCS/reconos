#include <stdio.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <linux/netlink.h>
#include <linux/types.h>
#include <linux/if.h>

#include "reconfig.h"
#include "notification.h"
#include "xutils.h"
#include "props.h"
#include "xt_vlink.h"
#include "xt_fblock.h"

static sig_atomic_t need_privacy = 0, need_privacy_switched = 0;
//static char name_privacy[FBNAMSIZ];

void reconfig_notify_privacy(int type)
{
	if (type == SIG_THRES_UPPER) {
		if (need_privacy == 1)
			need_privacy_switched = 1;
		need_privacy = 0;
	} else {
		if (need_privacy == 0)
			need_privacy_switched = 1;
		need_privacy = 1;
	}
}

void reconfig_privacy(void)
{
	if (need_privacy == 1 && need_privacy_switched == 1) {
		printd("Need privacy!\n");
//		__reconfig_privacy_check_for_inclusion();
	} else if (need_privacy == 0 && need_privacy_switched == 1) {
		printd("Don't need privacy!\n");
//		__reconfig_privacy_check_for_exclusion();
	}

	need_privacy_switched = 0;
}
