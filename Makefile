#
# Makefile for linux.
# If you don't have '-mstring-insns' in your gcc (and nobody but me has :-)
# remove them from the CFLAGS defines.
#

TOOLPREFIX =
CPUARCH = i386
CPUTUNE = i386

# toolchain
NASM = nasm
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)as
LD = $(TOOLPREFIX)ld
AR = $(TOOLPREFIX)ar

# cc flags
OPTWARN = -Wall
OPTCTRL = -O -fstrength-reduce -fomit-frame-pointer -std=gnu89
OPTARCH = -march=$(CPUARCH) -mtune=$(CPUTUNE) -m32
CFLAGS = $(OPTWARN) $(OPTCTRL) $(OPTARCH)

# ld flags
LDFLAGS = -s -x

# export
export CC AS LD AR CFLAGS LDFLAGS

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o
LIBS	=lib/lib.a

.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -c -o $*.o $<

all: boot/boot linux

boot/head.o: boot/head.s
	$(CC) $(CFLAGS) -c -o $@ $<

linux: boot/head.o init/main.o $(ARCHIVES) $(LIBS)
	$(LD) $(LDFLAGS) $^ -Ttext 0 -e startup_32 -o $@

kernel/kernel.o:
	$(MAKE) -C kernel

mm/mm.o:
	$(MAKE) -C mm

fs/fs.o:
	$(MAKE) -C fs

lib/lib.a:
	$(MAKE) -C lib

boot/boot: boot/boot.asm
	$(NASM) -f bin -o $@ $<

clean:
	rm -f boot/boot linux
	rm -f init/*.o boot/*.o
	$(MAKE) -C mm clean
	$(MAKE) -C fs clean
	$(MAKE) -C kernel clean
	$(MAKE) -C lib clean

.PHONY: clean
