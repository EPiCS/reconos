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

sig_atomic_t need_reliability = 0, need_reliability_switched = 0;
static char name_reliability[FBNAMSIZ], type_reliability[FBNAMSIZ];

extern char srv_name[FBNAMSIZ];
extern char srv_app[FBNAMSIZ];

static void __reconfig_reliability_check_for_inclusion(void)
{
	int ret;
	enum fblock_props needed[MAX_PROPS];
	size_t num = 0, orig;

	copy_pipeline_to_vpipeline();

	memset(needed, 0, sizeof(needed));
	needed[0] = RELIABLE;

	orig = num = 1;
	while ((ret = find_type_by_properties(type_reliability, needed, &num)) >= -32) {
		insert_and_bind_elem_to_vstack(type_reliability, name_reliability,
					      sizeof(name_reliability));
		printd("Added %s as reliability!\n", name_reliability);
		break;
	}

	printd("Initiate negotiation with server....\n");
	ret = init_negotiation(srv_name, srv_app);
	printd("client negotiation returned with %d!\n", ret);
	if (ret < 0) {
		printd("Remote end does not support stack config!\n");
		return;
	}
}

static void __reconfig_reliability_check_for_exclusion(void)
{
	int ret;

	copy_pipeline_to_vpipeline();
	remove_and_unbind_elem_from_vstack(type_reliability);

	printd("Initiate negotiation with server....\n");
	ret = init_negotiation(srv_name, srv_app);
	printd("client negotiation returned with %d!\n", ret);
	if (ret < 0) {
		printd("Remote end does not support stack config!\n");
		return;
	}
}

void reconfig_notify_reliability(int type)
{
	//printd("---------------------\n");
	if (type == SIG_THRES_UPPER) {
		if (need_reliability == 1){
	//		printd("2\n");
			need_reliability_switched = 1;
		}
		need_reliability = 0;
	} else {
		if (need_reliability == 0){
	//		printd("3\n");
			need_reliability_switched = 1;
		}
		need_reliability = 1;
	}
}

void reconfig_reliability(void)
{
	if (need_reliability == 1 && need_reliability_switched == 1) {
		printd("Need reliability!\n");
		__reconfig_reliability_check_for_inclusion();
	} else if (need_reliability == 0 && need_reliability_switched == 1) {
		printd("Don't need reliability!\n");
		__reconfig_reliability_check_for_exclusion();
	}

	need_reliability_switched = 0;
}
