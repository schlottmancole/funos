
boot.bin: boot.asm
	nasm boot.asm -f bin boot.bin
qemu:
	qemu-system-i386 -hda boot.bin

