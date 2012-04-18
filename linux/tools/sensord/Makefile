LIBS		= -lpthread -ldl -rdynamic
CFLAGS		+= -rdynamic -Wall -O2 -g

core-objs	= sensord.o
lib-objs	= loader.o plugin.o xutils.o sched.o

target		= sensord

all: $(lib-objs) $(core-objs)
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

%.o: %.c
	gcc -c $(CFLAGS) $<

clean:
	rm -f *.o sensord
