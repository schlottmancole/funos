; boot.asm
	cli
hang:
	jmp hang
	; NASM for fill the rest of this 512 bytes logical block with zeros
	times 510-($-$$) db 0
	db 0x55
	db 0xAA
