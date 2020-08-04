CFLAGS += -nostdinc -I../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS=	open.o read_write.o inode.o file_table.o buffer.o super.o \
	block_dev.o char_dev.o file_dev.o stat.o exec.o pipe.o namei.o \
	bitmap.o fcntl.o ioctl.o tty_ioctl.o truncate.o

fs.o: $(OBJS)
	$(LD) -r -o fs.o $(OBJS)

clean:
	rm -f *.o *.a

.PHONY: clean
