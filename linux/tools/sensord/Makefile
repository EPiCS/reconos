LIBS		= -lpthread -ldl -rdynamic
CFLAGS		+= -rdynamic -Wall -O3 -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT

core-objs	= sensord.o
lib-objs	= loader.o plugin.o xutils.o sched.o

target		= sensord

all: $(lib-objs) $(core-objs)
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

%.o: %.c
	gcc -c $(CFLAGS) $<

clean:
	rm -f *.o sensord
