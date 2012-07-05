LIBS		= -lpthread -ldl -rdynamic
CFLAGS		+= -rdynamic -Wall -O3 -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT -I../../lana/
#CC		= microblaze-unknown-linux-gnu-gcc
#AR		= microblaze-unknown-linux-gnu-ar

core-objs	= configd.o
lib-objs	= xutils.o reconfig.o ipc.o props.o lex.yy.o parser.tab.o

target		= configd

all: $(lib-objs) $(core-objs) builtin_client
	gcc $(core-objs) $(lib-objs) -o $(target) $(LIBS)

lex.yy.c:
	flex lexer.l

parser.tab.c:
	bison -d parser.y

%.o: %.c
	gcc -c $(CFLAGS) $<

builtin_client:

clean:
	rm -f *.o configd builtin_client lex.yy.c parser.tab.c parser.tab.h
