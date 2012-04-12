ARCH		=	microblaze
CROSS_COMPILE	=	microblaze-unknown-linux-gnu-
KDIR		?=	~/linux-2.6-xlnx

export ARCH CROSS_COMPILE

obj-m := fsl.o

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules
	@cat Module.symvers >> ../../reconos/libreconos-ks/Module.symvers

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
