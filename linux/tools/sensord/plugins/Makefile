lib-objs = dummy.o

all: $(lib-objs)
	for object in $(lib-objs) ; do \
	    gcc -shared -Wl,-soname,"`basename $$object .o`".so.1 \
		-o "`basename $$object .o`".so.1.0 $$object ; \
	done

%.o: %.c
	gcc -g -Wall -O2 -fPIC -I../ -c $<

clean:
	rm *.o *.so *.so.*
