# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -O0 -g -Wall -static -L $(RECONOS)/linux/lib -I $(RECONOS)/linux/lib/include

all: sort_demo

sort_demo: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) reconf_sort_matrix.c -o reconf_sort_matrix -static -lreconos -lpthread

clean:
	rm -f *.o reconf_sort_matrix

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
