CC	= gcc
INC_DIR = ../include
DEBUG   = DEBUG_NONE
CFLAGS	= -O3 -I $(INC_DIR) `pkg-config --cflags opencv` -DDEBUG=$(DEBUG) 
LIBS	= `pkg-config --libs opencv`

EXECUTABLES = webcam receiveSendVideo

all: $(EXECUTABLES)
	cp $^ ../bin

webcam: webcam.o tcp_connection.o netimage.o graph_utils.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

receiveSendVideo: receiveSendVideo.o tcp_connection.o netimage.o graph_utils.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
