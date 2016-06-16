CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O -g -Wall

APP_OBJS = bubblesort.o data.o merge.o 
#timing.o
LIB_DIRS = ../../../linux/reconos/libreconos-us
INCLUDES = ../../../linux/reconos/libreconos-us
LIBS     = -lreconos -lpthread -lm -lrt

all: sort_demo workercpu workerreset

workerreset: workerreset.c
	$(CC) $(APP_OBJS) $(CFLAGS) -L $(LIB_DIRS)  -I $(INCLUDES)  workerreset.c -o workerreset -static $(LIBS)

workercpu: workercpu.c
	$(CC) $(APP_OBJS) $(CFLAGS) -L $(LIB_DIRS)  -I $(INCLUDES)  workercpu.c -o workercpu -static $(LIBS)

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L $(LIB_DIRS)  -I $(INCLUDES)  sort_demo.c -o sort_demo -static $(LIBS) 

clean:
	rm -f *.o sort_demo workercpu workerreset

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



install:
	cp sort_demo workercpu workerreset /exports/rootfs_mb/demos/sort_demo_workercpu
