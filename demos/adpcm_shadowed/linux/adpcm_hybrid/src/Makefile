#
# Makefile for adpcm and test programs
# -------------------

#####################################################################
# Added by C. Lee.
#
# On Sun machines, gcc need to be informed whether the machines have
# integer multipliers by specifying this option: -mv8.
#
# Also, on Sun machines, in order to use the SPIXTOOLS and SHADE,
# uncomment this option: -static.
#
CC = microblaze-unknown-linux-gnu-gcc #modified by A. Sprenger: user microblaze compiler
LFLAGS = -mv8
LFLAGS = $(LFLAGS) -static
#
# End of addition
######################################################################
CFLAGS = -static -O3

# May need this on a sun:
# CFLAGS=-O -I/usr/demo/SOUND

######################################################################
# Added by A. Sprenger
MB_CC = microblaze-unknown-linux-gnu-gcc

LIBPATH = -L ../../../../linux/libreconos -L ../../../../linux/eif
INCLUDEPATH = -I ../../../../linux/libreconos -I ../../../../linux/eif

HOST_LIBPATH = -L ../../../libreconos -L ../../../eif
HOST_INCLUDEPATH = -I ../../../libreconos -I ../../../eif

LIBS = -lreconos -lpthread -lm -lrt
######################################################################

# Modified by A. Sprenger
ALLSRC=README adpcm.2 Makefile adpcm.h libst.h adpcm.c timing.c \
	rawcaudio.c rawcaudio_hybrid.c rawdaudio.c rawdaudio_hybrid.c suncaudio.c sgicaudio.c \
	sgidaudio.c hello.adpcm.uu

# Modified by A. Sprenger
all: adpcm.o rawcaudio rawdaudio timing timing_upb.o rawcaudio_hybrid rawdaudio_hybrid
	cp rawcaudio rawdaudio rawcaudio_hybrid rawdaudio_hybrid timing ../bin/.

sgi: all sgicaudio sgidaudio

sun: all suncaudio sundaudio

adpcm.o: adpcm.h

# added by A. Sprenger
timing_upb.o: timing_upb.c timing_upb.h

suncaudio: suncaudio.o adpcm.o
	$(CC) adpcm.o suncaudio.o -o suncaudio -L/usr/demo/SOUND -laudio

sundaudio: suncaudio
	cp suncaudio sundaudio

sgicaudio: sgicaudio.o adpcm.o
	$(CC) sgicaudio.o adpcm.o -o sgicaudio -laudiofile -lm

sgidaudio: sgidaudio.o adpcm.o
	$(CC) sgidaudio.o adpcm.o -o sgidaudio -laudiofile -lm

rawcaudio: rawcaudio.o adpcm.o
	$(MB_CC) $(CFLAGS) rawcaudio.o adpcm.o -o rawcaudio

rawdaudio: rawdaudio.o adpcm.o
	$(MB_CC) $(CFLAGS) rawdaudio.o adpcm.o -o rawdaudio

timing: timing.o adpcm.o
	$(MB_CC) $(CFLAGS) timing.o adpcm.o -o timing

# Added by A. Sprenger
rawcaudio_hybrid: adpcm.o rawcaudio_hybrid.c
	$(MB_CC) adpcm.o timing_upb.o $(CFLAGS) $(HOST_LIBPATH) $(HOST_INCLUDEPATH) rawcaudio_hybrid.c -o rawcaudio_hybrid $(LIBS)

rawdaudio_hybrid: adpcm.o rawdaudio_hybrid.c
	$(MB_CC) adpcm.o timing_upb.o $(CFLAGS) $(HOST_LIBPATH) $(HOST_INCLUDEPATH) rawdaudio_hybrid.c -o rawdaudio_hybrid $(LIBS)

adpcm.shar: $(ALLSRC)
	shar $(ALLSRC) > adpcm.shar

# Added by C. Lee
# Modified by A. Sprenger
clean:
	rm -f *.o ; rm rawcaudio rawdaudio timing rawcaudio_hybrid rawdaudio_hybrid; rm -f ../bin/* ../output*

# Added by A. Sprenger: copy data to export directory
mibenchhybridinstall:
	cp -r ../bin/ /exports/rootfs_mb/demos/mibench/adpcm/
	cp ../runme_* /exports/rootfs_mb/demos/mibench/adpcm/
