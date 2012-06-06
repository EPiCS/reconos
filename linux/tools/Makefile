objs	= configd fbctl fbprop fbviz readpvr sensord sensord/plugins timedb vlink
curr	= $(PWD)

all: $(objs)
	for object in $(objs) ; do \
	    cd $(curr)/$$object && $(MAKE); \
	done

clean:
	for object in $(objs) ; do \
	    cd $(curr)/$$object && $(MAKE) clean; \
	done
