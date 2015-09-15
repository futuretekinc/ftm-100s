CC=arm-openwrt-linux-uclibcgnueabi-gcc
CFLAGS=-c -Wall -DDEBUG
LDFLAGS=
SOURCES=lock.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=lock

all: $(SOURCES) $(EXECUTABLE) 

lock: lock.o
	$(CC) $(LDFLAGS) lock.o -o $@

install: $(EXECUTABLE)
	cp $(EXECUTABLE) ../target/bin
	cp ftm_upgrade.sh ../target/bin
	
.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(EXECUTABLE) *.o
