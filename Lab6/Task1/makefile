all: task1 

start.o: start.s
	nasm -f elf32 start.s -o start.o

util.o: util.c util.h
	gcc -m32 -Wall -ansi -c -nostdlib -fno-stack-protector util.c -o util.o

task1.o: task1.s
	nasm -f elf32 task1.s -o task1.o

task1: start.o util.o task1.o
	ld -m elf_i386 start.o task1.o util.o -o task1

clean:
	rm -f start.o util.o task1.o task1