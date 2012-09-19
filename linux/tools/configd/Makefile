LIBS		= -lpthread -ldl -rdynamic
#CFLAGS		+= -rdynamic -Wall -O3 -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT -I../../lana/
CFLAGS		+= -Wall -O0 -I../../net/
#CC		= microblaze-unknown-linux-gnu-gcc
#AR		= microblaze-unknown-linux-gnu-ar

core-objs	= configd.o
lib-objs	= xutils.o reconfig.o ipc.o props.o lex.yy.o parser.tab.o  \
		  reconfig_simple.o reconfig_reliable.o reconfig_initial.o \
		  nego_client.o nego_server.o sha1.o

target		= configd

all: pre $(lib-objs) $(core-objs) builtin_client builtin_ping
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

pre:
	flex lexer.l
	bison -d parser.y

%.o: %.c
	gcc -c $(CFLAGS) $<

builtin_client:

builtin_ping:

clean:
	rm -f *.o configd builtin_client builtin_ping lex.yy.c parser.tab.c parser.tab.h
