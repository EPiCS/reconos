all: #doc
	mkdir bin
	make -C src all

clean:
	make -C src clean
	rm -rf bin/*
	rm -rf bin
        
mrproper: clean docclean
        
#doc: netimage.doxy
#	doxygen netimage.doxy
        
docclean:
	rm -rf doc/
        
.PHONY: clean docclean
