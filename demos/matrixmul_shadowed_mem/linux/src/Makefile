CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O0 -g -std=c99 -Wall -static

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32 -std=c99 -Wall  -DHOST_COMPILE -static
# -m32

APP_OBJS = common.o matrix_functions.o std_mmp.o str_mmp.o logging.o



#host:
CC=$(HOST_CC)
CFLAGS=$(HOST_CFLAGS)

LIBPATH = -L $(RECONOS)/linux/reconos/libreconos-us
INCLUDEPATH = -I $(RECONOS)/linux/reconos/libreconos-us
LDFLAGS = -lreconos -lpthread -lm -lrt

.PHONY: clean

all: matrixmul matrixmul_shadowed 

cmdline:
	LD_LIBRARY_PATH="" gengetopt < cmdline.ggo
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o cmdline.o cmdline.c

matrixmul: $(APP_OBJS) cmdline
	$(CC) $(APP_OBJS) cmdline.o  $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) matrixmul.c -o matrixmul $(LDFLAGS)

matrixmul_shadowed: $(APP_OBJS) cmdline
	# recompile needed object files for shadowing
	rm -f std_mmp.o
	$(CC) -c $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) -o std_mmp.o std_mmp.c
	$(CC) $(APP_OBJS) cmdline.o $(CFLAGS) -DSHADOWING $(LIBPATH) $(INCLUDEPATH) matrixmul.c -o matrixmul_shadowed $(LDFLAGS)

#fault_injection:
#	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us -o fault_injection fault_injection.c -lreconos -lpthread
	
clean:
	rm -f *.o matrixmul matrixmul_shadowed cmdline.c cmdline.h

#fault_injection	

install:
	#./genBenchmark.py benchmark.sh
	cp matrixmul matrixmul_shadowed /exports/rootfs_mb/demos/matrixmul_shadowed_mem/

%.o: %.c
	$(CC) -c $(CFLAGS) $(LIBPATH) $(INCLUDEPATH) -o $@ $<
	


	
