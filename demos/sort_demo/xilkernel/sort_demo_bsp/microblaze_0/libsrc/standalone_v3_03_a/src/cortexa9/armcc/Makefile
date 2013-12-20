######################################################################
# Copyright (c) 2011 Xilinx, Inc.  All rights reserved. 
# 
# Xilinx, Inc. 
# XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
######################################################################

include config.make

AS=armasm
COMPILER=armcc
ARCHIVER=armar
CP=cp
COMPILER_FLAGS=
EXTRA_COMPILER_FLAGS=

LIB=libxil.a

CC_FLAGS = $(COMPILER_FLAGS)
ECC_FLAGS = $(EXTRA_COMPILER_FLAGS)

ECC_FLAGS	+= --cpu=Cortex-A9 --fpu=VFPv3_FP16 --vectorize

RELEASEDIR=../../../lib
INCLUDEDIR=../../../include

INCLUDES=-I./. -I${INCLUDEDIR}

INCLUDEFILES=*.h

#OUTS = *.o

#libs: boot.s $(LIBS) clean

#standalone_libs: $(LIBSOURCES)
#	echo "Compiling standalone"
#	$(COMPILER) $(CC_FLAGS) $(ECC_FLAGS) $(INCLUDES) $^
#	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} ${OUTS}
#	#$(ARCHIVER) -d ${RELEASEDIR}/${LIB} asm_vectors.o
#	#$(ARCHIVER) -s ${RELEASEDIR}/${LIB}
#	#${CP} asm_vectors.o ${RELEASEDIR}
#	${CP} ${OUTS} ${RELEASEDIR}
#	
#boot.s: boot.S
#	${COMPILER} $(INCLUDES) -E -o $@ $<
#	${AS} --cpu=Cortex-A9 --fpu=VFPv3_FP16 -o boot.o $@
#	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} ${OUTS}

OBJECTS =	$(addsuffix .o, $(basename $(wildcard *.c)))
OBJECTS +=	$(addsuffix .o, $(basename $(wildcard *.s)))
OBJECTS +=	boot.o

libs: banner $(LIBS) clean

boot.s: boot.S
	${COMPILER} $(INCLUDES) -E -o $@ $<

%.o: %.s
	${AS} --cpu=Cortex-A9 --fpu=VFPv3_FP16 -o $@ $<

%.o: %.c
	${COMPILER} -c $(CC_FLAGS) $(ECC_FLAGS) $(INCLUDES) -o $@ $<

banner:
	echo "Compiling standalone"

standalone_libs: ${OBJECTS}
	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} ${OBJECTS}

.PHONY: include
include: standalone_includes

standalone_includes:
	${CP} ${INCLUDEFILES} ${INCLUDEDIR}

clean:
	rm -rf ${OBJECTS}
