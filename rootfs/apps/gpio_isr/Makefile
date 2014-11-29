CC=arm-openwrt-linux-uclibcgnueabi-gcc
CFLAGS=-c -Wall -DDEBUG
LDFLAGS=
SOURCES=main.c 
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=gpio_isr

all: $(SOURCES) $(EXECUTABLE) 

gpio_isr: main.o
	$(CC) $(LDFLAGS) main.o -o $@
	
.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(EXECUTABLE) *.o
