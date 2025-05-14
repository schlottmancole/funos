
	mov ax, 0x07c0
	mov ds, ax
	jmp start

	%include "print.inc"

start:
	xor ax, ax ;make 0
	mov ss, ax ;SS=0
	mov sp, 0x9c00 ;200h past code start. Need in order to use "call/ret"

	mov ax, 0xb800 ;text video memory
	mov es, ax; ES=b800. ES used for the DI string destination register

	cli ;disable interrupts while modifying IVT
	mov bx, 0x09 ; we'll be changing interrupt 0x09
	shl bx, 2 ; IVT entries are 4 bytes, so multiply by 4
	xor ax, ax
	mov gs, ax ;GS=0. The IVT will start at segment 0
	mov [gs:bx], word keyhandler ;put keyhandler address into IVT entry 0x09
	mov [gs:bx+2], ds ;include segment in IVT entry 0x09
	sti ;renable interrupts

	jmp $ ;infinite loop

keyhandler:
	in al, 0x60 ;input byte from I/O port address 0x60
	mov bl, al; save data
	mov byte [port60], al ; and save to port60 variable

	in al, 0x61 ;keybrd control port
	mov ah, al
	or al, 0x80
	out 0x61, al
	xchg ah, al
	out 0x61, al

	mov al, 0x20
	out 0x20, al

	and bl, 0x80
	jnz done

	mov ax, [port60] ;recall keyboard data and input to hex printer
	mov word [reg16], ax
	call printreg16

done:
	iret

; global variables
port60 dw 0

	times 510-($-$$) db 0
	dw 0xAA55
	
