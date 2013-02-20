CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O0 -g -Wall

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32  -Wall -DHOST_COMPILE
# -m32

APP_OBJS = bubblesort.o data.o merge.o timing.o sort8k.o

all: sort_demo sort_demo_shadowed

host:
CC=$(HOST_CC)
CFLAGS=$(HOST_CFLAGS)

LIBPATH = -L ../../../linux/reconos/libreconos-us -L ../../../linux/eif
INCLUDEPATH = -I ../../../linux/reconos/libreconos-us -I ../../../linux/eif
LIBS = -leif -lreconos -lpthread -lm -lrt

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo -static $(LIBS)

sort_demo_shadowed: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) sort_demo_shadowed.c -o sort_demo_shadowed $(LIBS)
# -static


clean:
	rm -f *.o sort_demo sort_demo_shadowed 

install:
	cp sort_demo sort_demo_shadowed /exports/rootfs_mb/demos/sort_demo/

%.o: %.c
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o $@ $<
	


	
