# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -O0 -g -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include

all: sort_demo

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) matrixmul.c -o matrixmul -static -lreconos -lpthread

clean:
	rm -f *.o matrixmul

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
