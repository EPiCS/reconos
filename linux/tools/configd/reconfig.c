#include <stdio.h>
#include <signal.h>
#include <assert.h>
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

#define MAXP	64

struct fb {
	char name[FBNAMSIZ];
	char type[TYPNAMSIZ];
};

static struct fb pipeline[MAXP];
static int curr = 0;

void dumpstack(void)
{
	int i;
	printd("Dump:\n");
	for(i=0;i<=curr;++i) {
		printd("-- %s(%s)\n", pipeline[i].name, pipeline[i].type);
	}
}

void init_reconfig(char *upper_name, char *upper_type,
		   char *lower_name, char *lower_type)
{
	memset(pipeline, 0, sizeof(pipeline));

	strlcpy(pipeline[0].name, lower_name, sizeof(pipeline[0].name));
	strlcpy(pipeline[0].type, lower_type, sizeof(pipeline[0].type));

	strlcpy(pipeline[1].name, upper_name, sizeof(pipeline[1].name));
	strlcpy(pipeline[1].type, upper_type, sizeof(pipeline[1].type));

	printd("Initial: %s(%s)->%s(%s)\n",
	       pipeline[0].name, pipeline[0].type,
	       pipeline[1].name, pipeline[1].type);

	curr=1;

	dumpstack();
}

void insert_and_bind_elem_to_stack(char *type, char *name, size_t len)
{
	int i, wanted, num=0;
	char **stack = NULL;
	size_t slen = 0;
	struct fb pipetmp[MAXP];

	wanted = curr; //XXX
	assert(type&&name&&len);

	printd("Getting dependencies for %s->%s\n", pipeline[wanted].type, type);
	get_dependencies(pipeline[wanted].type, type, &stack, &slen);
	assert(slen>=2);
	assert(wanted>0&&wanted+slen-1<MAXP);

	memcpy(pipetmp, &pipeline[wanted], (MAXP-curr)*sizeof(struct fb));
	unbind_elems_in_stack(pipeline[wanted-1].name, pipeline[wanted].name);

	for (i = 0; i < slen - 1; ++i) {
		if (i>0)
			curr++;
		strlcpy(pipeline[curr].type, stack[i], sizeof(pipeline[curr].type));
		insert_elem_to_stack(pipeline[curr].type, pipeline[curr].name,
				     sizeof(pipeline[curr].name));
		bind_elems_in_stack(pipeline[curr-1].name, pipeline[curr].name);
		num++;
	}

	memcpy(&pipeline[curr+1], pipetmp, (MAXP-(curr+1))*sizeof(struct fb));
	bind_elems_in_stack(pipeline[curr].name, pipeline[curr+1].name);
	curr+=num;

	dumpstack();
}

void remove_and_unbind_elem_from_stack(char *name, size_t len)
{
	int i, found=0;
	struct fb pipetmp[MAXP];

	for (i = 0; i < curr; ++i) {
		if (!strncmp(pipeline[i].name, name, len)) {
			assert(i>0);

			if (i!=curr-1) {
				unbind_elems_in_stack(pipeline[i-1].name, name);
				unbind_elems_in_stack(name, pipeline[i+1].name);
				bind_elems_in_stack(pipeline[i-1].name,
						    pipeline[i+1].name);
			} else {
				unbind_elems_in_stack(pipeline[i-1].name, name);
			}

			remove_elem_from_stack(name);
			found=1;
			break;
		}
	}

	if (found) {
		memcpy(pipetmp, &pipeline[i+1], (MAXP-curr)*sizeof(struct fb));
		memcpy(&pipeline[i], pipetmp, (MAXP-curr)*sizeof(struct fb));
		curr--;
		dumpstack();
	}
}

void cleanup_pipeline(void)
{
	while (curr > 1) {
		printf("Removing %s!\n", pipeline[1].name);
		remove_and_unbind_elem_from_stack(pipeline[1].name, sizeof(pipeline[1].name));
	}
}
