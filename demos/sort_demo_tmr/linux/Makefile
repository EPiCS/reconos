CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O -g -Wall

APP_OBJS = bubblesort.o data.o merge.o timing.o

all: sort_demo

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us sort_demo.c -o sort_demo -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o sort_demo 

install:
	cp sort_demo /exports/rootfs_mb/demos/sort_demo_tmr

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
