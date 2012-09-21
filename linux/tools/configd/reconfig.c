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
#include "sha1.h"

#define MAXP	64

struct fb {
	char name[FBNAMSIZ];
	char type[TYPNAMSIZ];
};

static struct fb pipeline[MAXP];
static int curr = 0;

static struct fb vpipeline[MAXP];
static int vcurr = 0;

char glob_appname[256];

static void cleanup_pre_pipeline(void)
{
	while (curr > 1) {
		if (!strcmp(pipeline[1].type, "ch.ethz.csg.pf_lana"))
			break;
		printf("Removing %s!\n", pipeline[1].name);
		remove_and_unbind_elem_from_stack(pipeline[1].name, sizeof(pipeline[1].name));
	}
}

void dumpstack(void)
{
	int i;
	printd("Dump:\n");
	for(i=0;i<=curr;++i) {
		printd("-- %s(%s)\n", pipeline[i].name, pipeline[i].type);
	}
}

void copy_pipeline_to_vpipeline(void)
{
	memcpy(vpipeline, pipeline, sizeof(pipeline));
	vcurr=curr+1;
}

void build_stack_and_hash(char *cfg[MAXS], size_t max){}
#if 0
void build_stack_and_hash(char *cfg[MAXS], size_t max)
{
	git_SHA_CTX sha;
	unsigned char hashout[20], hash[40];
	char hashfoo[2048];
	off_t l = 0;
	char hashopt[1024], str[64];
	int i, j, exists;
	char name[FBNAMSIZ];

	cleanup_pre_pipeline();

	for (i = 0; i < max; ++i) {
		exists = 0;
		for(j = 0; j <= curr; ++j) {
			if (!strcmp(cfg[i], pipeline[j].type))
				exists = 1;
		}
		if (!exists)
			insert_and_bind_elem_to_stack(cfg[i], name, sizeof(name));
		else
			printd("%s already exists\n", cfg[i]);
	}

	memset(hashfoo, 0, sizeof(hashfoo));
	l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "ch.ethz.csg.eth-");
	for (i = 0; i <= curr; ++i) {
		if(!strcmp(pipeline[i].type, "ch.ethz.csg.pf_lana") ||
		   !strcmp(pipeline[i].type, "ch.ethz.csg.eth"))
			continue;
		l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "%s-", pipeline[i].type);
	}
	l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "ch.ethz.csg.pf_lana");

	printd("Update hash ...\n");

	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, hashfoo, strlen(hashfoo));
	git_SHA1_Final(hash, &sha);
	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, glob_appname, strlen(glob_appname));
	git_SHA1_Final(&hash[20], &sha);
	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, hash, sizeof(hash));
	git_SHA1_Final(hashout, &sha);

	memset(hashopt, 0, sizeof(hashopt));

	snprintf(hashopt, sizeof(hashopt)-1, "%s=%s",
		bin2hex_compat(hashout, 8, str, sizeof(str)),
		pipeline[1].name);

	setopt_of_elem_in_stack(pipeline[0].name, hashopt, strlen(hashopt));
	printd("%s set with opt: %s\n", pipeline[0].name, hashopt);
	sleep(1);
}
#endif

int init_negotiation(char *fbpfname, char *appname)
{
	int i;
	size_t used = 0;
	char conf[MAXS][256];

	memcpy(glob_appname, appname, strlen(appname));
	for (i=0;i < vcurr;++i) {
		strlcpy(conf[i], vpipeline[i].type, TYPNAMSIZ);
		used++;
	}

	return negotiation_client(conf, used, fbpfname);
}

void init_reconfig(char *upper_name, char *upper_type,
		   char *lower_name, char *lower_type)
{
	memset(pipeline, 0, sizeof(pipeline));

	strlcpy(pipeline[0].name, lower_name, sizeof(pipeline[0].name));
	strlcpy(pipeline[0].type, lower_type, sizeof(pipeline[0].type));
	strlcpy(vpipeline[0].type, lower_type, sizeof(vpipeline[0].type));
	vcurr++;
	strlcpy(pipeline[1].name, upper_name, sizeof(pipeline[1].name));
	strlcpy(pipeline[1].type, upper_type, sizeof(pipeline[1].type));
	strlcpy(vpipeline[1].type, upper_type, sizeof(vpipeline[1].type));
	vcurr++;

	printd("Initial: %s(%s)->%s(%s)\n",
	       pipeline[0].name, pipeline[0].type,
	       pipeline[1].name, pipeline[1].type);

	curr=1;

	dumpstack();
}

void insert_and_bind_elem_to_vstack(char *type, char *name, size_t len)
{
	strcpy(vpipeline[vcurr++].type, type);
	printd("Added to vpipe: %s\n", vpipeline[vcurr-1].type);
}

void remove_and_unbind_elem_from_vstack(char *type)
{
	int i, found = 0;
	for (i = 0; i < vcurr; ++i) {
		if (!strcmp(type, vpipeline[i].type)) {
			if (i + 1 < vcurr) {
				memmove(&vpipeline[i], &vpipeline[i+1],
					sizeof(vpipeline[i]) * (MAXP - (i + 1)));
			} else {
				memset(&vpipeline[i], 0, sizeof(vpipeline[i]));
			}
			found = 1;
			break;
		}
	}
	if (found)
		vcurr--;
}

void reconfig_tell_app(char *appname)
{
	memcpy(glob_appname, appname, strlen(appname));
}

void commit_vstack(char *appname)
{
	int i;
	char name[FBNAMSIZ];
	git_SHA_CTX sha;
	unsigned char hashout[20], hash[40];
	char hashfoo[2048];
	off_t l = 0;
	char hashopt[1024], str[64];

	cleanup_pre_pipeline();
	memset(hashfoo, 0, sizeof(hashfoo));
	l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "ch.ethz.csg.eth-");
	for (i = 0; i < vcurr; ++i) {
		if(!strcmp(vpipeline[i].type, "ch.ethz.csg.pf_lana") ||
		   !strcmp(vpipeline[i].type, "ch.ethz.csg.eth"))
			continue;
		insert_and_bind_elem_to_stack(vpipeline[i].type, name, sizeof(name));
		l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "%s-", vpipeline[i].type);
//		printd("Inserted %s:%s to stack!\n", name, vpipeline[i].type);
		memset(name, 0, sizeof(name));
	}
	l += snprintf(hashfoo + l, sizeof(hashfoo) - 1, "ch.ethz.csg.pf_lana");
	if (appname)
		memcpy(glob_appname, appname, strlen(appname));
	printd("Update hash for %s\n", glob_appname);
	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, hashfoo, strlen(hashfoo));
	git_SHA1_Final(hash, &sha);
	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, glob_appname, strlen(glob_appname));
	git_SHA1_Final(&hash[20], &sha);
	git_SHA1_Init(&sha);
	git_SHA1_Update(&sha, hash, sizeof(hash));
	git_SHA1_Final(hashout, &sha);

	memset(hashopt, 0, sizeof(hashopt));

	snprintf(hashopt, sizeof(hashopt)-1, "%s=%s",
		bin2hex_compat(hashout, 8, str, sizeof(str)),
		pipeline[1].name);

	setopt_of_elem_in_stack(pipeline[0].name, hashopt, strlen(hashopt));
	printd("%s set with opt: %s\n", pipeline[0].name, hashopt);
	sleep(1);

	vcurr = 0;
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
//	unbind_elems_in_stack(pipeline[wanted-1].name, pipeline[wanted].name);
	unbind_elems_in_stack(pipeline[wanted].name, pipeline[wanted-1].name);

	for (i = 0; i < slen - 1; ++i) {
		if (i>0)
			curr++;
		strlcpy(pipeline[curr].type, stack[i], sizeof(pipeline[curr].type));
		insert_elem_to_stack(pipeline[curr].type, pipeline[curr].name,
				     sizeof(pipeline[curr].name));
//		bind_elems_in_stack(pipeline[curr-1].name, pipeline[curr].name);
		bind_elems_in_stack(pipeline[curr].name, pipeline[curr-1].name);
		num++;
	}

	memcpy(&pipeline[curr+1], pipetmp, (MAXP-(curr+1))*sizeof(struct fb));
//	bind_elems_in_stack(pipeline[curr].name, pipeline[curr+1].name);
	bind_elems_in_stack(pipeline[curr+1].name, pipeline[curr].name);
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
//				unbind_elems_in_stack(pipeline[i-1].name, name);
//				unbind_elems_in_stack(name, pipeline[i+1].name);
				unbind_elems_in_stack(name, pipeline[i-1].name);
				unbind_elems_in_stack(pipeline[i+1].name, name);
//				bind_elems_in_stack(pipeline[i-1].name,
//						    pipeline[i+1].name);
				bind_elems_in_stack(pipeline[i+1].name,
						    pipeline[i-1].name);
			} else {
//				unbind_elems_in_stack(pipeline[i-1].name, name);
				unbind_elems_in_stack(name,pipeline[i-1].name);
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
