CFLAGS=-O3 -g -Wall -I ../../../../linux/reconos/libreconos-us
CC=microblaze-unknown-linux-gnu-gcc

TARGET=icap_demo
APP_OBJS = icap_cmds.o icap_demo.o timing.o icap_demo_args.o bitstream.o

all: $(TARGET) 

$(TARGET): $(APP_OBJS)
	$(CC) $(CFLAGS) -L ../../../../linux/reconos/libreconos-us $(APP_OBJS) -o $(TARGET) -static -lreconos -lpthread -lrt -lm

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<


clean:
	rm -f *.o $(TARGET) 
