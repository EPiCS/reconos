CC	= gcc
DEBUG   = DEBUG_NONE
CFLAGS	= -O3 `pkg-config --cflags opencv` -DDEBUG=$(DEBUG) 
LIBS	= `pkg-config --libs opencv` -lstdc++

EXECUTABLES = show_single_camera show_all_cameras

all: $(EXECUTABLES)

show_single_camera: show_single_camera.o
	$(CC) $^ -o $@ $(CFLAGS) $(LIBS)

show_all_cameras: show_all_cameras.o
	$(CC) $^ -o $@ $(CFLAGS) $(LIBS)

clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
