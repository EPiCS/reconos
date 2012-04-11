CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: vmtest

vmtest: vmtest.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos-us -I ../../../linux/libreconos-us vmtest.c -o vmtest -static -lreconos -lpthread

clean:
	rm -f *.o vmtest 
