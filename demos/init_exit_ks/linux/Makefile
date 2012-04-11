ARCH		=	microblaze
CROSS_COMPILE	=	microblaze-unknown-linux-gnu-
KDIR		?=	~/linux-2.6-xlnx
EXTRA_CFLAGS	+=	-I$(PWD)/../../../linux/libreconos-ks/

export ARCH CROSS_COMPILE

obj-m		:= init_exit_test.o

modules:
	@cp ../../../linux/libreconos-ks/Module.symvers .
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

