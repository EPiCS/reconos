CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O -g -Wall

APP_OBJS = bubblesort.o data.o merge.o timing.o

all: sort_demo

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos sort_demo.c -o sort_demo -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o sort_demo 

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
