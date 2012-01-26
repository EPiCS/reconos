all: #doc
	make -C src all

clean:
	make -C src clean
	rm -rf bin/*
        
mrproper: clean docclean
        
#doc: netimage.doxy
#	doxygen netimage.doxy
        
docclean:
	rm -rf doc/
        
.PHONY: clean docclean
