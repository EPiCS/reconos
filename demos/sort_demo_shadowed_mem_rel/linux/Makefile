CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O3 -g -Wall

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32 -Wall -DHOST_COMPILE

APP_OBJS = bubblesort.o data.o merge.o timing.o sort8k.o

all: sort_demo sort_demo_shadowed

host:
CC=$(HOST_CC)
CFLAGS=$(HOST_CFLAGS)

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us sort_demo.c -o sort_demo -static -lreconos -lpthread -lm -lrt

sort_demo_shadowed: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us sort_demo_shadowed.c -o sort_demo_shadowed -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o sort_demo sort_demo_shadowed 

install:
	cp sort_demo sort_demo_shadowed /exports/rootfs_mb/demos/sort_demo/

%.o: %.c
	$(CC) -c $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us -o $@ $<
	



	
