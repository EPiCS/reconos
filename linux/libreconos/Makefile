CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc
AR=microblaze-unknown-linux-gnu-ar

all: libreconos
	/bin/true

libreconos: libreconos.a
	/bin/true

libreconos.a: libreconos.o fsl.o mbox.o
	$(AR) -rcsv libreconos.a libreconos.o fsl.o mbox.o

clean:
	rm -f *.o *.a

	


