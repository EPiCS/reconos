# needed environment variables
# (shold be set by the reconos toolchain)
# CROSS_COMPILE
CC = $(CROSS_COMPILE)gcc

CFLAGS += -O0 -g -Wall -static -L $(RECONOS)/reconos_core/linux/libreconos-us -I $(RECONOS)/reconos_core/linux/libreconos-us/include

all: reconf_led

reconf_led: reconf_led.c
	$(CC) $(CFLAGS) reconf_led.c -o reconf_led -static -lreconos -lpthread

clean:
	rm -f *.o reconf_led

