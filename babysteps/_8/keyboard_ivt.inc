
	%include "print.inc"

change_ivt:
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

	ret

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
	mov word [reg32], ax
	call printreg32

done:
	iret

; global variables
port60 dw 0
