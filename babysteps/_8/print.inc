
do:
	call cprint
sprint:
	mov eax, [esi] ;MANUALLY PULL [ESI] to EAX, no more lodsb
	lea esi, [esi+1] ;MANUAL INCREMENT ESI
	cmp al, 0 ;check for \0
	jne do
	inc byte [ypos] ; carriage return
	mov byte [xpos], 0 ; line feed
	ret

cprint:
	mov ah, 0x0F ;attrib = white on black. completes word by adding attribute to char
	mov ecx, eax ;save attribute aside
	movzx eax, byte [ypos]
	mov edx, 160 ;160 per row (80 columns and each char has an attribute byte)
	mul edx ;DX:AX = AX * DX
	movzx ebx, byte [xpos]
	shl ebx, 1; xpos*2 because each char has 2 bytes

	; putting dest. addr into di
	mov edi, 0 ;start of video memory
	add edi, eax ;add y offset
	add edi, ebx ;add x offset

	mov eax, ecx ;restore char/attribute
	mov word [ds:edi], ax ;store string word - REPLACED STOSW
	add byte [xpos], 1 ; increment xpos

	ret

printreg32:
	mov edi, outstr32 ;put OUTSTR32 addr in di
	mov eax, [reg32] ;bring REG32 contents into ax
	mov esi, hexstr ;ptr to LUT
	mov ecx, 8 ;while loop counter
hexloop:
	rol eax, 4 ; start by rolling highest 4 bits to bottom
	mov ebx, eax ;copy to bx
	and ebx, 0x0f ;mask to isolate 4 low bits
	mov bl, [esi + ebx] ;perform lookup. store into Bl
	mov [edi], bl ;then transfer to our dest. string
	inc edi ;increment dest. ptr.
	dec ecx ;decrement while loop counter
	jnz hexloop ;repeat 8 times

	mov esi, outstr32 ; put hex string addr into si
	call sprint ;print hex string

	ret

; data
xpos db 0 ;screen x position
ypos db 0 ;screen y position
hexstr db '0123456789ABCDEF' ;lookup for hex characters
outstr32 db '00000000', 0 ;8 byte string to hold hexified data
reg32 dd 0 ;will hold 32 bit variable to print
