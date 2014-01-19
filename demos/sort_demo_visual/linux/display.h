#ifndef DISPLAY_H
#define DISPLAY_H

#include "ncurses.h"
#include "semaphore.h"

#include "sort_demo_visual.h"

struct display_option {
	int min, max;
	int *value;
	char *descr;
};

struct display {
	struct statistics *stats;
	struct configuration *conf;

	WINDOW *w_conf, *w_vis;
	int refresh_rate;

	pthread_t display_conf, display_vis;

	sem_t sem;

	int opt_select;
	int opt_count;
	struct display_option *opt;
};

int init_display(struct display *display, struct statistics *stats, struct configuration *conf);
int clean_display();

#endif /* DISPLAY_H */
