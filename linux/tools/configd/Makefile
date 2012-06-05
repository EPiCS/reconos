LIBS		= -lpthread -ldl -rdynamic
CFLAGS		+= -rdynamic -Wall -O3 -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT -I../../lana/
#CC		= microblaze-unknown-linux-gnu-gcc
#AR		= microblaze-unknown-linux-gnu-ar

core-objs	= configd.o
lib-objs	= xutils.o reconfig.o ipc.o props.o

target		= configd

all: $(lib-objs) $(core-objs)
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

%.o: %.c
	gcc -c $(CFLAGS) $<

builtin_client:

clean:
	rm -f *.o configd
