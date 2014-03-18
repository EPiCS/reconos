CFLAGS=-O3 -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

TARGET=icap_demo
APPLICATION_SRC=icap_demo.c

all: $(TARGET) 

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -L ../../../../linux/reconos/libreconos-us -I ../../../../linux/reconos/libreconos-us $(APPLICATION_SRC) -o $(TARGET) -static -lreconos -lpthread -lrt -lm

clean:
	rm -f *.o $(TARGET) 
