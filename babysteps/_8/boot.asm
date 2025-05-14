; ORG 0x7c00
AsmExample:
;	xor ax, ax
	mov ax, 0x07c0
	mov ds, ax ;populate data segment based on where BIOS loads this code
	jmp start

start:
	xor ax, ax
	mov ss, ax ;stack segment starts at 0
	mov sp, 0x9c00 ;and stack pointer 2000 bytes into stack segment

	cli ;disable interrupts
	push ds ;save real-mode DS on stack

	lgdt [gdtinfo] ;load Global Descriptor Register w/ GDT address
	
	mov eax, cr0 ;RMW to set pmode bit of cr0
	or al, 1 
	mov cr0, eax
; WE ARE NOW IN PROTECTED MODE
	jmp 0x8:pmode

pmode:
	mov bx, 0x10 ;put descriptor 2 into DS (set DS[15:3] = 13'h00001)
	mov ds, bx

	and al, 0xFE ; clear cr0 bit 0
	mov cr0, eax
	jmp 0x0:unreal

; WE ARE IN (UN)REAL MODE AGAIN
unreal:
	pop ds ;restore DS to previous real mode value
	sti ;reenable interrupts

	mov bx, 0x0f01
	mov eax, 0x0b8000
	mov word [ds:eax], bx

	jmp $ ;infinite loop


; Global Descriptor Table
gdtinfo: ; these 6 bytes are loaded by LGDT (only 5 really used because operand size is 16 bits?)
	dw gdt_end - gdt - 1 ; 2 lower bytes are the size (in bytes) of the GDT
	dd gdt ; 32-bit (really 24 bits?) address of GDT
gdt dd 0, 0 ;entry 0 of GDT is always unused
codedesc db 0xff, 0xff, 0, 0, 0, 10011010b, 00000000b, 0
	; byte6[3:0],byte1,byte0 indicates size of 0x0_FFFF (64KiB-1)
	; byte7,byte4,byte3,byte2 indicate base address of 0x0000_0000
	; byte 5 fields
	;  P(1) - segment present in memory
	;  DPL(00) - privilege level 0 (highest privilege)
	;  S(1) - a code/data/stack segment
	;  Type(1010)
	;   1 - code segment
	;   0 - non-conforming
	;   1 - Read enabled
	;   0 - segment has not been accessed
	; byte 6 fields
	;  G(0) - 1 byte granularity
	;  D/B(0) - default operand/addr size is 16-bit
	;  R(0) - reserved
	;  AVL(0) - NOT available
	;  Size - bits [19:16] of size
flatdesc db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
	; byte6[3:0],byte1,byte0 indicates size of 0xF_FFFF (1MiB-1)
	; byte7,byte4,byte3,byte2 indicate base address of 0x0000_0000
	; byte 5 fields
	;  P(1) - segment present in memory
	;  DPL(00) - privilege level 0 (highest privilege)
	;  S(1) - a code/data/stack segment
	;  Type(0010)
	;   0 - data segment
	;   0 - expand up (normal stack behavior)
	;   1 - reading enabled
	;   0 - segment has not been accessed
	; byte 6 fields
	;  G(1) - 4K page granularity
	;  D/B(1) - stack pointer is 32-bit
	;  R(0) - reserved
	;  AVL(0) - NOT available
	;  Size - bits [19:16] of size
gdt_end:

; boot sector padding and boot signature
	times 510-($-$$) db 0
	dw 0xAA55
