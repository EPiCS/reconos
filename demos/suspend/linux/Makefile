# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include

all: sort_demo_suspend

sort_demo_suspend: sort_demo_suspend.c
	$(CC) $(APP_OBJS) $(CFLAGS) sort_demo_suspend.c -o sort_demo_suspend -lreconos -lpthread

clean:
	rm -f *.o sort_demo_suspend

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
