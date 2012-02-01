CC = microblaze-unknown-linux-gnu-gcc
CFLAGS=-O -g -Wall

APP_OBJS = 

all: template_empty

template_empty: $(APP_OBJS)
	$(CC) $(APP_OBJS) $(CFLAGS) -L $(RECONOS)/linux/libreconos -I $(RECONOS)/linux/libreconos template_empty.c -o template_empty -static -lreconos -lpthread -lm -lrt

clean:
	rm -f *.o template_empty 

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<



	
