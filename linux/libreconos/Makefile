CFLAGS	=	-O2 -g -Wall
CC	=	microblaze-unknown-linux-gnu-gcc
AR	=	microblaze-unknown-linux-gnu-ar

libreconos: libreconos.a
	@true

libreconos.a: reconos.o fsl.o mbox.o rqueue.o xutils.o
	$(AR) -rcsv libreconos.a reconos.o fsl.o mbox.o rqueue.o xutils.o

clean:
	rm -f *.o *.a
