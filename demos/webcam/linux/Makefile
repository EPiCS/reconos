CFLAGS=-O3 -g -Wall
CC=microblaze-unknown-linux-gnu-gcc

TARGET=webcam_demo
APPLICATION_SRC=webcam_demo.c ethernet.c filter.c

all: $(TARGET) 

$(TARGET): $(TARGET).c
	$(CC) $(CFLAGS) -L ../../../linux/libreconos -I ../../../linux/libreconos $(APPLICATION_SRC) -o $(TARGET) -static -lreconos -lpthread -lrt -lm

clean:
	rm -f *.o $(TARGET) 
