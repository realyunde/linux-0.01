#
# Makefile for linux.
# If you don't have '-mstring-insns' in your gcc (and nobody but me has :-)
# remove them from the CFLAGS defines.
#

TOOLPREFIX =

# toolchain
AS86 = as86 -0
LD86 = ld86 -0
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
AR = $(TOOLPREFIX)ar

# cc flags
OPTWARN = -Wall
OPTCTRL = -O -fstrength-reduce -fomit-frame-pointer -std=gnu89
CFLAGS = $(OPTWARN) $(OPTCTRL)

# ld flags
LDFLAGS = -s -x

# export
export CC AS LD AR CFLAGS LDFLAGS

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o
LIBS	=lib/lib.a

.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

all: boot/boot tools/system

boot/head.o: boot/head.s
	$(CC) $(CFLAGS) -c -o $@ $<

tools/system:	boot/head.o init/main.o $(ARCHIVES) $(LIBS)
	$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(LIBS) \
	-Ttext 0 -e startup_32 -o tools/system

kernel/kernel.o:
	$(MAKE) -C kernel

mm/mm.o:
	$(MAKE) -C mm

fs/fs.o:
	$(MAKE) -C fs

lib/lib.a:
	$(MAKE) -C lib

boot/boot:	boot/boot.s tools/system
	(echo -n "SYSSIZE = (";ls -l tools/system | grep system \
		| cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
	cat boot/boot.s >> tmp.s
	$(AS86) -o boot/boot.o tmp.s
	rm -f tmp.s
	$(LD86) -s -o boot/boot boot/boot.o

clean:
	rm -f boot/boot
	rm -f init/*.o boot/*.o tools/system
	(cd mm;make clean)
	(cd fs;make clean)
	(cd kernel;make clean)
	(cd lib;make clean)

init/main.o : init/main.c
