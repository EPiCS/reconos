FILE1 = basicmath_small.c rad2deg.c cubic.c isqrt.c
FILE2 = basicmath_large.c rad2deg.c cubic.c isqrt.c
FILE3 = basicmath_small_hybrid.c  rad2deg.c  cubic.c   isqrt.c
FILE4 = basicmath_large_hybrid.c  rad2deg.c  cubic.c   isqrt.c

APP_OBJS = timing.o

CC = microblaze-unknown-linux-gnu-gcc
CFLAGS= -static -O3 -mhard-float -mxl-float-convert	-mxl-float-sqrt											
#-O0 -g -Wall

HOST_CC = gcc
HOST_CFLAGS = -O0 -g -m32  -Wall -DHOST_COMPILE

LIBPATH = -L ../../../../linux/libreconos -L ../../../../linux/eif
INCLUDEPATH = -I ../../../../linux/libreconos -I ../../../../linux/eif

HOST_LIBPATH = -L ../../libreconos -L ../../eif
HOST_INCLUDEPATH = -I ../../libreconos -I ../../eif

LIBS = -lreconos -lpthread -lm -lrt

all: basicmath_small basicmath_large basicmath_small_hybrid basicmath_large_hybrid

basicmath_small: ${FILE1} Makefile
	$(CC) $(CFLAGS) ${FILE1} -o basicmath_small -lm
basicmath_large: ${FILE2} Makefile
	$(CC) $(CFLAGS) ${FILE2} -o basicmath_large -lm
basicmath_small_hybrid: ${FILE3} Makefile
	$(CC) $(APP_OBJS) $(CFLAGS) $(HOST_LIBPATH) $(HOST_INCLUDEPATH) ${FILE3} -o basicmath_small_hybrid $(LIBS)
basicmath_large_hybrid: ${FILE4} Makefile
	$(CC) $(APP_OBJS) $(CFLAGS) $(HOST_LIBPATH) $(HOST_INCLUDEPATH) ${FILE4} -o basicmath_large_hybrid $(LIBS)

clean:
	rm -rf basicmath_small basicmath_large basicmath_small_hybrid basicmath_large_hybrid output*

#copy files to export filesystem
mibenchhybridinstall:
	cp basicmath_small /exports/rootfs_mb/demos/mibench/basicmath/
	cp basicmath_large /exports/rootfs_mb/demos/mibench/basicmath/
	cp basicmath_small_hybrid /exports/rootfs_mb/demos/mibench/basicmath/
	cp basicmath_large_hybrid /exports/rootfs_mb/demos/mibench/basicmath/
	cp runme_* /exports/rootfs_mb/demos/mibench/basicmath/
