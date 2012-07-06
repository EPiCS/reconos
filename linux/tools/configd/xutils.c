/*
 * Copyright 2012 Daniel Borkmann <dborkma@tik.ee.ethz.ch>
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "xutils.h"

void *xmalloc(size_t size)
{
	void *ptr;

	if (size == 0)
		panic("xmalloc: zero size\n");

	ptr = malloc(size);
	if (ptr == NULL)
		panic("xmalloc: out of memory (allocating %zu bytes)\n", size);

	return ptr;
}

void *xzmalloc(size_t size)
{
	void *ptr;

	if (size == 0)
		panic("xzmalloc: zero size\n");

	ptr = malloc(size);
	if (ptr == NULL)
		panic("xzmalloc: out of memory (allocating %zu bytes)\n", size);

	memset(ptr, 0, size);

	return ptr;
}

void *xrealloc(void *ptr, size_t nmemb, size_t size)
{
	void *new_ptr;
	size_t new_size = nmemb * size;

	if (unlikely(new_size == 0))
		panic("xrealloc: zero size\n");
	if (unlikely(((size_t) ~0) / nmemb < size))
		panic("xrealloc: nmemb * size > SIZE_T_MAX\n");

	if (ptr == NULL)
		new_ptr = malloc(new_size);
	else
		new_ptr = realloc(ptr, new_size);

	if (unlikely(new_ptr == NULL))
		panic("xrealloc: out of memory (new_size %zu bytes)\n",
		      new_size);

	return new_ptr;
}

void xfree(void *ptr)
{
	if (ptr == NULL)
		panic("xfree: NULL pointer given as argument\n");

	free(ptr);
}

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

char *xstrdup(const char *str)
{
	size_t len;
	char *cp;

	len = strlen(str) + 1;
	cp = xmalloc(len);
	strlcpy(cp, str, len);

	return cp;
}

void send_netlink_vlink(struct vlinknlmsg *vmsg)
{
	int sock, ret;
	struct sockaddr_nl src_addr, dest_addr;
	struct nlmsghdr *nlh;
	struct iovec iov;
	struct msghdr msg;

	if (unlikely(!vmsg))
		return;

	sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_VLINK);
	if (unlikely(sock < 0))
		panic("Cannot get NETLINK_USERCTL socket from kernel! "
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

	memcpy(NLMSG_DATA(nlh), vmsg, sizeof(*vmsg));

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

void send_netlink_fbctl(struct lananlmsg *lmsg)
{
	int sock, ret;
	struct sockaddr_nl src_addr, dest_addr;
	struct nlmsghdr *nlh;
	struct iovec iov;
	struct msghdr msg;

	if (unlikely(!lmsg))
		return;

	sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_USERCTL);
	if (unlikely(sock < 0))
		panic("Cannot get NETLINK_USERCTL socket from kernel! "
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

	nlh = xzmalloc(NLMSG_SPACE(sizeof(*lmsg)));
	nlh->nlmsg_len = NLMSG_SPACE(sizeof(*lmsg));
	nlh->nlmsg_pid = getpid();
	nlh->nlmsg_type = USERCTLGRP_CONF;
	nlh->nlmsg_flags = NLM_F_REQUEST;

	memcpy(NLMSG_DATA(nlh), lmsg, sizeof(*lmsg));

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
