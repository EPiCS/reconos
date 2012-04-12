CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

TARGET=memtest

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -L ../../../linux/reconos/libreconos-us -I ../../../linux/reconos/libreconos-us $(TARGET).c -o $(TARGET) -static -lreconos -lpthread

clean:
	rm -f *.o $(TARGET)
