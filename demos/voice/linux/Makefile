#
# Lightweight Autonomic Network Architecture
#
# Copyright 2011 Daniel Borkmann <dborkma@tik.ee.ethz.ch>,
# Swiss federal institute of technology (ETH Zurich)
# Subject to the GPL.
#

LD_NORM      = echo "LD        $<"; \
               gcc -pie -z relo
CC_NORM      = echo "CC        $<"; \
               gcc

LD           = $(LD_NORM) -o
CC           = $(CC_NORM) -c

MAKEFLAGS   += --no-print-directory

BINDIR       = usr/sbin
ETCDIR       = etc

CFLAGS      += -O2 -fno-delete-null-pointer-checks -std=gnu99 -pedantic
CFLAGS      += -fstack-protector -D_FORTIFY_SOURCE=2 -fPIE -D_REENTRANT
CFLAGS      += -fno-strict-aliasing
CFLAGS      += -Wall -Wundef -Wstrict-prototypes -Wuninitialized

INCLUDE      = -I../src/

voe-libs   = -lspeexdsp -lasound -lcelt0 -lm
voe-objs   = voe.o xmalloc.o strlcpy.o alsa.o
voe-targ   = voe

all: build

build: build_voe

build_voe: $(voe-objs)
	@$(LD) $(voe-targ) $(voe-objs) $(voe-libs)

%.o: %.c
	@$(CC) $(CFLAGS) $(INCLUDE) $<

install:
	@install -D $(voe-targ) $(DESTDIR)/$(BINDIR)/$(voe-targ)

uninstall:
	@rm $(DESTDIR)/$(BINDIR)/$(voe-targ)

clean:
	@rm *.o *~ $(voe-targ) || true
	@find -name "*\.o"  -exec rm '{}' \; || true
	@find -name "*\.hi" -exec rm '{}' \; || true

help:
	@echo "make <targets>"
	@echo "available targets:"
	@echo "  build         - Builds source"
	@echo "  clean         - Removes generated files"
	@echo "  install       - Installs userspace tools into system"
	@echo "  uninstall     - Removes userspace tools from system"
	@echo "  help          - Shows this help"

