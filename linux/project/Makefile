<<reconos_preproc>>

PRJ = <<SWDIR>>
CC = $(CROSS_COMPILE)gcc
CFLAGS += -Wall -I <<REPO_REL>> -I lib/include -D RECONOS_OS_<<OS>> -D RECONOS_BOARD_<<BOARD>> <<CFLAGS>>
LDFLAGS += -static -lpthread <<LDFLAGS>>

MKDIRP = mkdir -p

OBJS = <<generate for OBJS>><<Source>> <<end generate>>
BUILD_OBJS = $(OBJS:%=_build/%)

all: $(BUILD_OBJS)
	$(CC) $(BUILD_OBJS) $(LDFLAGS) -o <<NAME>>

clean:
	rm -rf _build <<NAME>>

_build/%.o: %.c
	$(MKDIRP) $(@D)
	$(CC) $(CFLAGS) -c $< -o $@