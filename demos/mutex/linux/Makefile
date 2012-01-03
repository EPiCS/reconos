CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: mutex_test

mutex_test: mutex_test.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos mutex_test.c -o mutex_test -static -lreconos -lpthread

clean:
	rm -f *.o mutex_test 
