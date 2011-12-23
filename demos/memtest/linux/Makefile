CFLAGS=-O -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

TARGET=memtest

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos $(TARGET).c -o $(TARGET) -static -lreconos -lpthread

clean:
	rm -f *.o $(TARGET)
