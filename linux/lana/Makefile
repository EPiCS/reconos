lana-y   := core.o xt_vlink.o xt_engine.o xt_fblock.o xt_critbit.o
obj-m    += lana.o
obj-m    += fb_dummy.o
obj-m    += fb_eth.o
obj-m    += fb_ipv4.o
obj-m    += fb_udp.o
obj-m    += fb_tcp.o
obj-m    += fb_ethtag.o
obj-m    += fb_pflana.o
obj-m    += fb_bpf.o
obj-m    += fb_counter.o
obj-m    += fb_tee.o

MDIR     := /lib/modules/$(shell uname -r)
KDIR     := $(MDIR)/build
DEST     := $(MDIR)/kernel/drivers/net/lana/

all: build

build:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean

