all:
	nasm -f elf32 dist/out.s -o objects/out.o
	ld -m elf_i386 objects/out.o -o dist/mcc
	./dist/mcc

