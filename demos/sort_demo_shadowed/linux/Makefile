CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O0 -g -std=c99 -Wall -static

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32 -std=c99 -Wall  -DHOST_COMPILE -static
# -m32

APP_OBJS = bubblesort.o data.o merge.o sort8k.o sort_shmem.o sort_rq.o sort_mbox.o



host:
#CC=$(HOST_CC)
#CFLAGS=$(HOST_CFLAGS)

LIBPATH = -L ../../../linux/reconos/libreconos-us
INCLUDEPATH = -I ../../../linux/reconos/libreconos-us
LDFLAGS = -lreconos -lpthread -lm -lrt

.PHONY: clean

all: cmdline sort_demo sort_demo_shadowed fault_injection
 
cmdline:
	LD_LIBRARY_PATH="" gengetopt < cmdline.ggo
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o cmdline.o cmdline.c

sort_demo: $(APP_OBJS) cmdline
	$(CC) $(APP_OBJS) cmdline.o  $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo $(LDFLAGS)

sort_demo_shadowed: $(APP_OBJS) cmdline
	# recompile needed object files for shadowing
	rm -f sort8k.o
	$(CC) -c $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) -o sort8k.o sort8k.c
	$(CC) $(APP_OBJS) cmdline.o $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo_shadowed $(LDFLAGS)

fault_injection:
	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us -o fault_injection fault_injection.c -lreconos -lpthread
	
clean:
	rm -f *.o sort_demo sort_demo_shadowed fault_injection cmdline.c cmdline.h

install:
	./genBenchmark.py benchmark.sh
	cp sort_demo sort_demo_shadowed benchmark.sh  fault_injection /exports/rootfs_mb/demos/sort_demo_shadowed/

%.o: %.c
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o $@ $<
	


	
