ARCH		=	microblaze
CROSS_COMPILE	=	microblaze-unknown-linux-gnu-
KDIR		?=	~/linux-2.6-xlnx

export ARCH CROSS_COMPILE

obj-m := reconos.o

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
