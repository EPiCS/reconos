CFLAGS	= -O3 -g -Wall -rdynamic -pthread
CC	=	microblaze-unknown-linux-gnu-gcc
AR	=	microblaze-unknown-linux-gnu-ar

HOST_AR = ar
HOST_CC = gcc
HOST_CFLAGS = -O0 -g -Wall -m32 -DHOST_COMPILE -pthread
# -m32

host:
#AR=$(HOST_AR)
#CC=$(HOST_CC)
#CFLAGS=$(HOST_CFLAGS)

APP_OBJS = reconos.o fsl.o mbox.o rqueue.o xutils.o glist.o timing.o fifo.o func_call.o max_covering_intervals.o thread_shadowing.o thread_shadowing_error_handler.o thread_shadowing_schedule.o thread_shadowing_subs.o cpuusage.o

all: libreconos
	/bin/true

libreconos: libreconos.a
	@true

libreconos.a: $(APP_OBJS) 
	$(AR) -rcsv libreconos.a $(APP_OBJS)

test: libreconos.a 
	$(CC) $(CFLAGS) -L./ -I./ -o sh_error_to_json_test sh_error_to_json_test.c -lreconos

clean:
	rm -f *.o *.a
