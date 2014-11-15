CC=arm-openwrt-linux-uclibcgnueabi-gcc
CFLAGS=-c -Wall -DDEBUG
LDFLAGS=
SOURCES=main.c xshared.c debug.c crc32.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=align_file update_sys_info fwinfo

all: $(SOURCES) $(EXECUTABLE) 

align_file: align_file.o
	$(CC) $(LDFLAGS) align_file.o -o $@

update_sys_info: update_sys_info.o crc32.o
	$(CC) $(LDFLAGS) update_sys_info.o crc32.o -o $@

fwinfo: fwinfo.o crc32.o
	$(CC) $(LDFLAGS) fwinfo.o crc32.o -o $@

install: $(EXECUTABLE)
	cp $(EXECUTABLE) ../target/bin
	cp ftm_upgrade.sh ../target/bin
	
.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(EXECUTABLE) *.o
