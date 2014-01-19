# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include -I $(RECONOS)/demos/sort_demo_visual/linux/ncurses/usr/include -L $(RECONOS)/demos/sort_demo_visual/linux/ncurses/usr/lib
#CFLAGS += -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include -I /home/christoph/Desktop/asciiart/ncurses-5.9/_install/usr/include -L /home/christoph/Desktop/asciiart/ncurses-5.9/_install/usr/lib

all: sort_demo_visual

sort_demo_visual: sort_demo_visual.o display.o
	$(CC) $(CFLAGS) sort_demo_visual.o display.o -o sort_demo_visual -static -lreconos -lpthread -lcurses

clean:
	rm -f *.o sort_demo_visual

