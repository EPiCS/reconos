CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: mutex_test

mutex_test: mutex_test.c
	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us mutex_test.c -o mutex_test -static -lreconos -lpthread

clean:
	rm -f *.o mutex_test 
