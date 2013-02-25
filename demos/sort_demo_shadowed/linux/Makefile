CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O0 -g -Wall -static

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32  -Wall  -DHOST_COMPILE -static
# -m32

APP_OBJS = bubblesort.o data.o merge.o timing.o sort8k.o



host:
#CC=$(HOST_CC)
#CFLAGS=$(HOST_CFLAGS)

LIBPATH = -L ../../../linux/reconos/libreconos-us -L ../../../linux/eif
INCLUDEPATH = -I ../../../linux/reconos/libreconos-us -I ../../../linux/eif
LDFLAGS = -leif -lreconos -lpthread -lm -lrt

.PHONY: clean

all: sort_demo sort_demo_shadowed
 
sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo $(LDFLAGS)

sort_demo_shadowed: $(APP_OBJS)
	# recompile needed object files for shadowing
	rm -f sort8k.o
	$(CC) -c $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) -o sort8k.o sort8k.c
	$(CC) $(APP_OBJS) $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo_shadowed $(LDFLAGS)

clean:
	rm -f *.o sort_demo sort_demo_shadowed 

install:
	./genBenchmark.py benchmark.sh
	cp sort_demo sort_demo_shadowed benchmark.sh /exports/rootfs_mb/demos/sort_demo_shadowed/

%.o: %.c
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o $@ $<
	


	
