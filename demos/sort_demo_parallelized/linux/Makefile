# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -O0 -g -Wall -static -L $(RECONOS)/linux/reconos/libreconos-us -I $(RECONOS)/linux/reconos/libreconos-us

APP_OBJS = bubblesort.o data.o merge.o timing.o

all: sort_demo_parallelized

sort_demo_parallelized: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) sort_demo_parallelized.c -o sort_demo_parallelized -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o sort_demo_parallelized

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

install:
	cp sort_demo_parallelized /exports/rootfs_mb/demos/sort_demo_parallelized/
	
