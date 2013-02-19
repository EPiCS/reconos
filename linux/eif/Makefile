CC = microblaze-unknown-linux-gnu-gcc
AR=microblaze-unknown-linux-gnu-ar
CFLAGS=-O0 -g -Wall -pthread

HOST_AR = ar
HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32  -Wall -DHOST_COMPILE
# -m32

APP_OBJS = eif.o 

host:
AR=$(HOST_AR)
CC=$(HOST_CC)
CFLAGS=$(HOST_CFLAGS)


all: libeif main

main: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) main.c -o main -static -lpthread -lm -lrt

libeif: libeif.a
	/bin/true

libeif.a: eif.o
	$(AR) -rcsv libeif.a eif.o
	
clean:
	rm -f *.a *.o main 

install:
	cp main /exports/rootfs_mb/demos/sort_demo/

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
	



