#
# Makefile for the FREAX-kernel.
#
# Note! Dependencies are done automagically by 'make dep', which also
# removes any old dependencies. DON'T put your own dependencies here
# unless it's something special (ie not a .c file).
#

CFLAGS += -finline-functions -nostdinc -I../include

.s.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS  = sched.o system_call.o traps.o asm.o fork.o \
	panic.o printk.o vsprintf.o tty_io.o console.o \
	keyboard.o rs_io.o hd.o sys.o exit.o serial.o \
	mktime.o

kernel.o: $(OBJS)
	$(LD) -r -o kernel.o $(OBJS)

clean:
	rm -f *.o

.PHONY: clean

