objs	= drivers/fsl_driver drivers/getpgd lana reconos/libreconos-us reconos/libreconos-ks tools
curr	= $(PWD)

all: $(objs)
	for object in $(objs) ; do \
	    cd $(curr)/$$object && $(MAKE); \
	done

clean:
	for object in $(objs) ; do \
	    cd $(curr)/$$object && $(MAKE) clean; \
	done
