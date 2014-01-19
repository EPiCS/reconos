#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <pthread.h>
#include "display.h"
#include <string.h>

#define Y_OFFSET 6

#define VIS_HEIGHT (LINES - Y_OFFSET - CONF_HEIGHT)
#define VIS_WIDTH COLS

#define CONF_HEIGHT 5
#define CONF_WIDTH COLS

#define MAX_Y 240

void *display_conf(void *arg) {
	int c, i, len, pos;
	struct display *display = (struct display *)arg;
	int *sel = &display->opt_select;
	WINDOW *win;

	display->w_conf = newwin(CONF_HEIGHT, CONF_WIDTH, VIS_HEIGHT + Y_OFFSET, 0);
	win = display->w_conf;
	box(win, 0, 0);

	keypad(win, 1);

	mvwprintw(win, 1, 2, "Settings");

	while (1) {
		pos = 2;
		for (i = 0; i < display->opt_count; i++) {
			len = strlen(display->opt[i].descr);

			// write description and clear value
			mvwprintw(win, 3, pos, display->opt[i].descr);
			mvwprintw(win, 3, pos + len, ":   ");

			// display values
			if (i == *sel) {
				wattron(win, A_REVERSE);
				mvwprintw(win, 3, pos + len + 2, "%d", *display->opt[i].value);
				wattroff(win, A_REVERSE);
			} else {
				mvwprintw(win, 3, pos + len + 2, "%d", *display->opt[i].value);
			}

			pos += len + 7;
		}


		// display changes
		sem_wait(&display->sem);
		wrefresh(win);
		sem_post(&display->sem);

		// process user input
		c = wgetch(win);
		switch (c) {
			case KEY_RIGHT:
				if (*sel < display->opt_count - 1)
					*sel += 1;
				else
					*sel = 0;
				break;
			case KEY_LEFT:
				if (*sel > 0)
					*sel -= 1;
				else
					*sel = display->opt_count - 1;
				break;
			case KEY_UP:
				if (*display->opt[*sel].value < display->opt[*sel].max) {
					*display->opt[*sel].value += 1;
					sem_post(display->conf->thread_control_wait);
				}
				break;
			case KEY_DOWN:
				if (*display->opt[*sel].value > display->opt[*sel].min) {
					*display->opt[*sel].value -= 1;
					sem_post(display->conf->thread_control_wait);
				}
				break;
		}
	}
}

void *display_vis(void *arg) {
	int x, y, h, h_disp;
	char c;
	struct display *display = (struct display *)arg;
	WINDOW *win;

	display->w_vis = newwin(VIS_HEIGHT, VIS_WIDTH, Y_OFFSET, 0);
	win = display->w_vis;
	box(win, 0, 0);

	mvwprintw(win, 1, 2, "Number of sorted blocks per second");

	while (1) {
		// move content one to the left
		for (x = 3; x < VIS_WIDTH - 2; x++) {
			for (y = VIS_HEIGHT - 2; y > 1; y--) {
				c = mvwinch(win, y, x);
				mvwaddch(win, y, x - 1, c);
			}
		}

		sem_wait(&display->stats->sem);
		h = display->stats->block_count * display->refresh_rate;
		display->stats->block_count = 0;
		sem_post(&display->stats->sem);

		h_disp = h * VIS_HEIGHT / MAX_Y;

		if (h_disp > VIS_HEIGHT)
			h_disp = VIS_HEIGHT - 1;

		for (y = VIS_HEIGHT - 2; y > 0 ; y--) {
			if (h_disp > 0) {
				h_disp--;
				mvwaddch(win, y, VIS_WIDTH - 3, '#');
			} else {
				mvwaddch(win, y, VIS_WIDTH - 3, ' ');
			}
		}

		mvwprintw(win, VIS_HEIGHT - 2, 2, "Current rate: %d Blocks/s ", h);

		sem_wait(&display->sem);
		wrefresh(win);
		sem_post(&display->sem);

		usleep(1000000 / display->refresh_rate);
	}
}

int init_display(struct display *display, struct statistics *stats, struct configuration *conf) {
	display->stats = stats;
	display->conf = conf;

	display->refresh_rate = 3;

	display->w_conf = NULL;
	display->w_vis = NULL;

	display->opt_select = 0;
	display->opt_count = 2;
	display->opt = malloc(3 * sizeof(struct display_option));
	display->opt[0].min = 0;
	display->opt[0].max = NUM_SWTS;
	display->opt[0].value = &display->conf->num_swts;
	display->opt[0].descr = "#SWTs";
	display->opt[1].min = 0;
	display->opt[1].max = NUM_HWTS;
	display->opt[1].value = &display->conf->num_hwts;
	display->opt[1].descr = "#HWTs";
	display->opt[2].min = 1;
	//display->opt[2].max = 3;
	//display->opt[2].value = &display->refresh_rate;
	//display->opt[2].descr = "Refresh Rate";

	initscr();

	clear();
	noecho();
	cbreak();

	mvprintw(0, 1, "                               ____  _____");
	mvprintw(1, 1, "   ________  _________  ____  / __ \\/ ___/");
	mvprintw(2, 1, "  / ___/ _ \\/ ___/ __ \\/ __ \\/ / / /\\__ \\ ");
	mvprintw(3, 1, " / /  /  __/ /__/ /_/ / / / / /_/ /___/ / ");
	//mvprintw(4, 0, "/_/   \\___/\\___/\\____/_/ /_/\\____//____/  ");
	mvprintw(4, 1, " Demo Application - Sort Demo Visual");

	refresh();

	sem_init(&display->sem, 0, 1);

	pthread_create(&display->display_vis, NULL, display_vis, display);
	pthread_create(&display->display_conf, NULL, display_conf, display);

	return 0;
}

int clean_display() {
	endwin();

	return 0;
}
