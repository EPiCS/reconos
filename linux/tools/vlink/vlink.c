#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <linux/netlink.h>
#include <linux/if.h>

#include "xt_vlink.h"

#ifndef likely
# define likely(x) __builtin_expect(!!(x), 1)
#endif
#ifndef unlikely
# define unlikely(x) __builtin_expect(!!(x), 0)
#endif
#ifndef bug
# define bug() __builtin_trap()
#endif

#define PROGNAME "vlink"
#define VERSNAME "0.9"

/* Copyright 1991, 1992 Linus Torvalds <torvalds@linux-foundation.org> */
size_t strlcpy(char *dest, const char *src, size_t size)
{
	size_t ret = strlen(src);

	if (size) {
		size_t len = (ret >= size) ? size - 1 : ret;
		memcpy(dest, src, len);
		dest[len] = '\0';
	}

	return ret;
}

static inline void die(void)
{
	exit(EXIT_FAILURE);
}

static inline void panic(char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);

	die();
}

static inline void whine(char *msg, ...)
{
	va_list vl;
	va_start(vl, msg);
	vfprintf(stderr, msg, vl);
	va_end(vl);
}

static void *xzmalloc(size_t size)
{
	void *ptr;

	if (unlikely(size == 0))
		panic("xzmalloc: zero size\n");

	ptr = malloc(size);
	if (unlikely(ptr == NULL))
		panic("xzmalloc: out of memory (allocating %lu bytes)\n",
		      (u_long) size);
	memset(ptr, 0, size);

	return ptr;
}

static void xfree(void *ptr)
{
	if (unlikely(ptr == NULL))
		panic("xfree: NULL pointer given as argument\n");
	free(ptr);
}

void check_for_root_maybe_die(void)
{
	if (geteuid() != 0 || geteuid() != getuid())
		panic("Uhhuh, not root?! \n");
}

static void usage(void)
{
	printf("\n%s %s\n", PROGNAME, VERSNAME);
	printf("Usage: %s <linktype> <cmd> [<args> ...]\n", PROGNAME);
	printf("Linktypes:\n");
	printf("  ethernet\n");
	printf("Commands:\n");
	printf("  add <name> <rootdev> <port>\n");
	printf("  rm <name>\n");
	printf("  hook <rootdev>\n");
	printf("  unhook <rootdev>\n");
	printf("\n");
	printf("Note: 'hook' redirects all traffic of a specified interface\n");
	printf("      into the LANA stack. Hence, all socket connections on\n");
	printf("      that interface will stop working until you've 'unhook'ed it!\n");
	printf("\n");
	printf("Please report bugs to <dborkma@tik.ee.ethz.ch>\n");
	printf("Copyright (C) 2011 Daniel Borkmann\n");
	printf("License: GNU GPL version 2\n");
	printf("This is free software: you are free to change and redistribute it.\n");
	printf("There is NO WARRANTY, to the extent permitted by law.\n\n");
	die();
}

static void version(void)
{
	printf("\n%s %s\n", PROGNAME, VERSNAME);
	printf("Please report bugs to <dborkma@tik.ee.ethz.ch>\n");
	printf("Copyright (C) 2011 Daniel Borkmann\n");
	printf("License: GNU GPL version 2\n");
	printf("This is free software: you are free to change and redistribute it.\n");
	printf("There is NO WARRANTY, to the extent permitted by law.\n\n");
	die();
}

void do_ethernet(int argc, char **argv)
{
	int sock, ret;
	uint8_t cmd = 0;
	struct sockaddr_nl src_addr, dest_addr;
	struct nlmsghdr *nlh;
	struct iovec iov;
	struct msghdr msg;
	struct vlinknlmsg *vmsg;

	if (unlikely(argc == 0))
		usage();
	if (!strncmp("add", argv[0], strlen("add")) && argc == 4)
		cmd = VLINKNLCMD_ADD_DEVICE;
	else if (!strncmp("rm", argv[0], strlen("rm")) && argc == 2)
		cmd = VLINKNLCMD_RM_DEVICE;
	else if (!strncmp("hook", argv[0], strlen("hook")) && argc == 2)
		cmd = VLINKNLCMD_START_HOOK_DEVICE;
	else if (!strncmp("unhook", argv[0], strlen("unhook")) && argc == 2)
		cmd = VLINKNLCMD_STOP_HOOK_DEVICE;
	else
		usage();

	sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_VLINK);
	if (unlikely(sock < 0))
		panic("Cannot get NETLINK_VLINK socket from kernel! "
		      "Modules not loaded?!\n");

	memset(&src_addr, 0, sizeof(src_addr));
	src_addr.nl_family = AF_NETLINK;
	src_addr.nl_pad = 0;
	src_addr.nl_pid = getpid();
	src_addr.nl_groups = 0;

	ret = bind(sock, (struct sockaddr *) &src_addr, sizeof(src_addr));
	if (unlikely(ret))
		panic("Cannot bind socket!\n");

	memset(&dest_addr, 0, sizeof(dest_addr));
	dest_addr.nl_family = AF_NETLINK;
	dest_addr.nl_pad = 0;
	dest_addr.nl_pid = 0;
	dest_addr.nl_groups = 0;

	nlh = xzmalloc(NLMSG_SPACE(sizeof(*vmsg)));
	nlh->nlmsg_len = NLMSG_SPACE(sizeof(*vmsg));
	nlh->nlmsg_pid = getpid();
	nlh->nlmsg_type = VLINKNLGRP_ETHERNET;
	nlh->nlmsg_flags = NLM_F_REQUEST;

	vmsg = (struct vlinknlmsg *) NLMSG_DATA(nlh);
	vmsg->cmd = cmd;
	if (cmd == VLINKNLCMD_ADD_DEVICE)
		vmsg->port = (uint16_t) (0xFFFF & atoi(argv[3]));
	vmsg->flags = 0;
	strlcpy((char *) vmsg->virt_name, argv[1], sizeof(vmsg->virt_name));
	if (cmd == VLINKNLCMD_ADD_DEVICE)
		strlcpy((char *) vmsg->real_name, argv[2],
			sizeof(vmsg->real_name));
	else if (cmd == VLINKNLCMD_START_HOOK_DEVICE ||
		 cmd == VLINKNLCMD_STOP_HOOK_DEVICE)
		strlcpy((char *) vmsg->real_name, argv[1],
			sizeof(vmsg->real_name));

	iov.iov_base = nlh;
	iov.iov_len = nlh->nlmsg_len;

	memset(&msg, 0, sizeof(msg));
	msg.msg_name = &dest_addr;
	msg.msg_namelen = sizeof(dest_addr);
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;

	ret = sendmsg(sock, &msg, 0);
	if (unlikely(ret < 0))
		panic("Cannot send NETLINK message to the kernel!\n");

	close(sock);
	xfree(nlh);
}

int main(int argc, char **argv)
{
	check_for_root_maybe_die();

	if (argc <= 1)
		usage();
	argc--;	argv++;
	if (!strncmp("help", argv[0], strlen("help")))
		usage();
	else if (!strncmp("version", argv[0], strlen("version")))
		version();
	else if (!strncmp("ethernet", argv[0], strlen("ethernet")))
		do_ethernet(--argc, ++argv);
	else
		usage();

	return 0;
}

