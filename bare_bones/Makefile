

all: funos.iso

boot.o: boot.s
	i686-elf-as boot.s -o boot.o

kernel.o: kernel.c
	i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

funos.bin: kernel.o boot.o
	i686-elf-gcc -T linker.ld -o funos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

multiboot: funos.bin
	grub-file --is-x86-multiboot funos.bin

funos.iso: multiboot
	mkdir -p isodir/boot/grub
	cp funos.bin isodir/boot/
	cp grub.cfg isodir/boot/grub/
	grub-mkrescue -o funos.iso isodir
