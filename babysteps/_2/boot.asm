; lets adjust so that the print routine is separated
%macro BiosPrint 1
	mov si, word %1; si will point to the message
loop:
	lodsb ;load a byte into AL from [si] and increment si
	or al, al ;our test to see if we hit the null character
	jz done ;at null character we'll stop, otherwise al gets passed to BIOS for printing
	mov ah, 0x0E ;function number 0Eh == Display Character
	mov bh, 0
	int 0x10 ;print character (BIOS video service interrupt)
	jmp loop ;repeat
done:
%endmacro

[ORG 0x7c00] ;ORG directive tells NASM to offset all section labels to this new origin
	xor ax, ax; put segment value of 0 into ax
	mov ds, ax; move that segment into the data segment register
	cld; clear direction flag so that our string pointers increment from lodsb
	
	BiosPrint msg ;call our print macro
	
hang:
	jmp hang

msg db 'Hello World', 13, 10, 0 ;string, then carriage return, then line feed, then \0
	times 510-($-$$) db 0; pad rest of sector with 0s
	dw 0xAA55; except the boot signature at the very end of the sector
