LIBS		= -lpthread -ldl -rdynamic
CFLAGS		+= -rdynamic -Wall -O3 -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT
#CC		= microblaze-unknown-linux-gnu-gcc
#AR		= microblaze-unknown-linux-gnu-ar

core-objs	= sensord.o
lib-objs	= loader.o plugin.o xutils.o sched.o storage.o notifier.o

target		= sensord

all: $(lib-objs) $(core-objs) builtin_client
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

%.o: %.c
	gcc -c $(CFLAGS) $<

builtin_client:

clean:
	rm -f *.o sensord builtin_client
