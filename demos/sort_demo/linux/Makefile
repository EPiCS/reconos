# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -O0 -g -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include

APP_OBJS = bubblesort.o data.o merge.o timing.o

all: sort_demo

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) sort_demo.c -o sort_demo -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o sort_demo 

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
