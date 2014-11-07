CC=arm-openwrt-linux-uclibcgnueabi-gcc
CFLAGS=-c -Wall -DDEBUG
LDFLAGS=
SOURCES=main.c xshared.c debug.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=fwmng

all: $(SOURCES) $(EXECUTABLE)
	cp $(EXECUTABLE) ../target/bin
	
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(EXECUTABLE) *.o
