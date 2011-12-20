CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

all: vmtest

vmtest: vmtest.c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos vmtest.c -o vmtest -static -lreconos -lpthread

clean:
	rm -f *.o vmtest 
