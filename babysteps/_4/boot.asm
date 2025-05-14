
[ORG 0x7c00] ;boot origin offset
	xor ax, ax ;make ax 0
	mov ds, ax ;DS=0
	mov ss, ax ;SS=0
	mov sp, 0x9c00 ;2000h past code start

	cld

	mov ax, 0xb800 ; text video memory addr
	mov es, ax ; put in ES

	mov si, msg ; put msg addr in si
	call while ; print message
	
	mov ax, 0xb800 ;text video memory addr
	mov gs, ax ; this time use gs
	mov bx, 0x0000
	mov ax, [gs:bx] ;read first video mem word

	mov word [reg16], ax ;copy to our reg16 variable
	call printreg16 ;print reg16 variable as hex characters

hang:
	jmp hang

do:
	call cprint
while:
	lodsb ;pull next char into al
	cmp al, 0 ;check for \0
	jne do
	inc byte [ypos] ; carriage return
	mov byte [xpos], 0 ; line feed
	ret

cprint:
	mov ah, 0x0F ;attrib = white on black. completes word by adding attribute to char
	mov cx, ax ;save attribute aside
	movzx ax, byte [ypos]
	mov dx, 160 ;160 per row (80 columns and each char has an attribute byte)
	mul dx ;DX:AX = AX * DX
	movzx bx, byte [xpos]
	shl bx, 1; xpos*2 because each char has 2 bytes

	; putting dest. addr into di
	mov di, 0 ;start of video memory
	add di, ax ;add y offset
	add di, bx ;add x offset

	mov ax, cx ;restore char/attribute
	stosw ;store string word
	add byte [xpos], 1 ; increment xpos

	ret

printreg16:
	mov di, outstr16 ;put outstr16 addr in di
	mov ax, [reg16] ;bring reg16 contents into ax
	mov si, hexstr ;ptr to LUT
	mov cx, 4 ;while loop counter
hexloop:
	rol ax, 4 ; start by rolling highest 4 bits to bottom
	mov bx, ax ;copy to bx
	and bx, 0x0f ;mask to isolate 4 low bits
	mov bl, [si + bx] ;perform lookup. store into Bl
	mov [di], bl ;then transfer to our dest. string
	inc di ;increment dest. ptr.
	dec cx ;decrement while loop counter
	jnz hexloop ;repeat 4 times

	mov si, outstr16 ; put hex string addr into si
	call while ;print hex string

	ret

; data
xpos db 0 ;screen x position
ypos db 0 ;screen y position
hexstr db '0123456789ABCDEF' ;lookup for hex characters
outstr16 db '0000', 0 ;4 byte string to hold hexified data
reg16 dw 0 ;will hold 16 bit variable to print
msg db "Example Print Message!", 0
times 510-($-$$) db 0
dw 0xAA55
