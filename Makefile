.POSIX:

build:
	nasm -felf64 -g -o asmme.o asmme.s
	$(CC) -no-pie -o asmme asmme.o
	
clean:
	rm *.o asmme
