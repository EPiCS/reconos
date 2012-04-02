ARCH = microblaze
CROSS_COMPILE = microblaze-unknown-linux-gnu-
KDIR ?= ~/linux-2.6-xlnx

export ARCH CROSS_COMPILE

obj-m := getpgd.o

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions Module.symvers modules.order
