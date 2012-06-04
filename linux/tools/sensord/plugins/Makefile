lib-objs = dummy.o netsoftirqs.o linkqual.o

all: $(lib-objs)
	for object in $(lib-objs) ; do \
	    gcc -shared -Wl,-soname,"`basename $$object .o`".so.1 \
		-o "`basename $$object .o`".so.1.0 $$object ; \
	done

%.o: %.c
	gcc -Wall -O2 -fPIC -lpthread -I../ -c $<

clean:
	rm *.o *.so *.so.*
