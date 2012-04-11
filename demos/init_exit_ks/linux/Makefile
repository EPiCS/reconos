CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: init_exit_test

init_exit_test: init_exit_test.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos-us -I ../../../linux/libreconos-us init_exit_test.c -o init_exit_test -static -lreconos -lpthread

clean:
	rm -f *.o init_exit_test 
