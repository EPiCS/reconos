CC	= gcc
DEBUG   = DEBUG_NONE
CFLAGS	= -O3 -DDEBUG=$(DEBUG) 
#LIBS	= -lstdc++

EXECUTABLES = send_pkts

all: $(EXECUTABLES)

send_pkts: send_pkts.o
	$(CC) $^ -o $@ $(CFLAGS) $(LIBS)


clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
