CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: semaphore_test

semaphore_test: semaphore_test.c
	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us semaphore_test.c -o semaphore_test -static -lreconos -lpthread

clean:
	rm -f *.o semaphore_test 
