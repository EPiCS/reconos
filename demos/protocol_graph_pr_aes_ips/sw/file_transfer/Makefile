CFLAGS	=	-O2 -g -Wall -I../../../../linux/net/ -I../../../../linux/tools/configd/
CC	=	microblaze-unknown-linux-gnu-gcc
AR	=	microblaze-unknown-linux-gnu-ar

#file_transfer:

all: file_transfer_simple pr_reconfig

file_transfer_simple: 

pr_reconfig: pr_reconfig.o

clean:
	rm -f *.o file_transfer file_transfer_simple
