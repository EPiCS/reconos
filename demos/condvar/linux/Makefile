CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: condvar_test

condvar_test: condvar_test.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos-us -I ../../../linux/libreconos-us condvar_test.c -o condvar_test -static -lreconos -lpthread

clean:
	rm -f *.o condvar_test 
