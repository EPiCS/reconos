CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: rq_test

rq_test: rq_test.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos rq_test.c -o rq_test -static -lreconos -lpthread -lrt

clean:
	rm -f *.o rq_test 
