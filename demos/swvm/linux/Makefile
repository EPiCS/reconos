CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: memtest

memtest: memtest.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos memtest.c -o memtest -static -lreconos -lpthread

clean:
	rm -f *.o memtest 
