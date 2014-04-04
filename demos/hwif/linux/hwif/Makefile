CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O0 -g -std=c99 -Wall -static -D_POSIX_C_SOURCE=200112L

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32 -std=c99  -Wall -static -D_POSIX_C_SOURCE=200112L
# -m32 

APP_OBJS = hwif.o

#CC=$(HOST_CC)
#CFLAGS=$(HOST_CFLAGS)

LIBPATH = 
#-L ../../../linux/reconos/libreconos-us
INCLUDEPATH = 
#-I ../../../linux/reconos/libreconos-us
LDFLAGS = 
#-lreconos -lpthread -lm -lrt

.PHONY: clean

all: hwif_tool gpio

#cmdline sort_demo sort_demo_shadowed fault_injection
 
#cmdline:
#	LD_LIBRARY_PATH="" gengetopt < cmdline.ggo
#	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o cmdline.o cmdline.c

hwif_tool: $(APP_OBJS) 
	$(CC) $(APP_OBJS) $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) hwif_tool.c -o hwif_tool $(LDFLAGS)

gpio: $(APP_OBJS)
	$(CC) $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) gpio-dev-mem-test.c -o gpio_tool $(LDFLAGS)


#sort_demo_shadowed: $(APP_OBJS) cmdline
# recompile needed object files for shadowing
#	rm -f sort8k.o
#	$(CC) -c $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) -o sort8k.o sort8k.c
#	$(CC) $(APP_OBJS) cmdline.o $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) sort_demo.c -o sort_demo_shadowed $(LDFLAGS)

#fault_injection:
#	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us -o fault_injection fault_injection.c -lreconos -lpthread
	
clean:
	rm -f *.o hwif_tool gpio_tool

install:
	#./genBenchmark.py benchmark.sh
	cp hwif_tool gpio_tool /exports/rootfs_mb/demos/hwif/

%.o: %.c
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o $@ $<
	


	
