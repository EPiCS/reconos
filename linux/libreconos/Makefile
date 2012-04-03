CFLAGS	=	-O2 -g -Wall
CC	=	microblaze-unknown-linux-gnu-gcc
AR	=	microblaze-unknown-linux-gnu-ar

libreconos: libreconos.a
	@true

libreconos.a: libreconos.o fsl.o mbox.o rq.o
	$(AR) -rcsv libreconos.a libreconos.o fsl.o mbox.o rq.o

clean:
	rm -f *.o *.a
