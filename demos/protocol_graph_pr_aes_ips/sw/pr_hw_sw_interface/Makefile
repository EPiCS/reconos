ARCH		=	microblaze
CROSS_COMPILE	=	microblaze-unknown-linux-gnu-
KDIR		?=	~/linux-2.6-xlnx
EXTRA_CFLAGS	+=	-I$(PWD)/../../../../linux/reconos/libreconos-ks/

export ARCH CROSS_COMPILE

obj-m		:= pr_hw_sw_interface.o

modules:
	@cp ../../../../linux/reconos/libreconos-ks/Module.symvers .
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

