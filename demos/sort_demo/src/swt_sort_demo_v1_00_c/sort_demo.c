#include "reconos.h"
#include "reconos_app.h"
#include "mbox.h"

static struct mbox *mbox_addr;
static struct mbox *mbox_ack;

void bubblesort(uint32_t *data, int data_count) {
	int i;
	uint32_t tmp;
	int s, n, newn;

	s = 1;
	n = data_count - 1;
	newn = n;

	while (s) {
		s = 0;
		for (i = 0; i < n; i++) {
			if (data[i] > data[i + 1]) {
				tmp = data[i];
				data[i] = data[i + 1];
				data[i + 1] = tmp;
				newn = i;
				s = 1;
			}
		}

		n = newn;
	}
}

void *swt_sort_demo(void *data) {
	uint32_t ret;
	struct reconos_thread *rt = (struct reconos_thread *)data;
	struct reconos_resource *res = rt->resources;

	mbox_addr = (struct mbox *)res[SORTDEMO_RESOURCES_ADDRESS].ptr;
	mbox_ack = (struct mbox *)res[SORTDEMO_RESOURCES_ADDRESS].ptr;

	while (1) {
		ret = mbox_get(mbox_addr);

		if (ret == 0xffffffff) {
			pthread_exit(0);
		}

		bubblesort((unsigned int *)ret, 1024);
		mbox_put(mbox_ack, ret);
	}
}