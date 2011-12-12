# if KERNELRELEASE is defined (i.e. != ""), we've been invoked from
# the kernel build system and can build the module
ARCH = microblaze
CROSS_COMPILE = microblaze-unknown-linux-gnu-
export ARCH CROSS_COMPILE

ifneq ($(KERNELRELEASE),)
# extend include directories
#EXTRA_CFLAGS += -I$(HW_DESIGN)/ppc405_0/include

  
obj-m := fsl.o
#fsl-objs := fsl.o

else

KERNELDIR ?= ~/linux-2.6-xlnx

PWD       := $(shell pwd)


modules:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

endif

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions Module.symvers modules.order
	
depend .depend dep:
	$(CC) $(CFLAGS) -M *.c > .depend
	
ifeq (.depend,$(wildcard .depend))
include .depend
endif
