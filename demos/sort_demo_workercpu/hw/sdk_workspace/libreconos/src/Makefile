CFLAGS	=	-O2 -g -Wall -I../../workercpu_thread/microblaze_1/include
CC	=	mb-gcc
AR	=	mb-ar

all: libreconos

libreconos: libreconos.a
	@true

libreconos.a: reconos.o 
	$(AR) -rcsv libreconos.a reconos.o

clean:
	rm -f *.o *.a
