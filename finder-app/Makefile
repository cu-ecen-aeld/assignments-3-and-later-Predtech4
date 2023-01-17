#CC указывает компилятор, используемый для сборки
CC=$(CROSS_COMPILE)gcc
#в переменной CFLAGS лежат флаги, которые передаются компилятору
CFLAGS=-g -Wall -c

all: writer

writer: writer.o
	$(CC) writer.o -o writer

writer.o: writer.c
	$(CC) $(CFLAGS) writer.c

clean:
	rm -rf *.o writer
