CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

TARGET=memtest

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos-us -I ../../../linux/libreconos-us $(TARGET).c -o $(TARGET) -static -lreconos -lpthread

clean:
	rm -f *.o $(TARGET)
