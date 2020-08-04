CFLAGS += -finline-functions -nostdinc -I../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.s.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = memory.o page.o

all: mm.o

mm.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)

clean:
	rm -f *.o

.PHONY: clean
