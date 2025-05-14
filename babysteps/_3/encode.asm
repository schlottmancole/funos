;example machine code

; simple 16-bit mov
;mov cx, 0xFF
;times 510-($-$$) db 0
;dd 0xAA55

; 32-bit mov
;mov ecx, 0xFF
;times 510-($-$$) db 0
;dd 0xAA55

; NASM directive requests 32-bit by default
;[BITS 32]
;mov cx, 0xFF
;times 510-($-$$) db 0
;dd 0xAA55

; using address encodings
;mov cx, [temp]
;temp db 0x99
;times 510-($-$$) db 0
;dd 0xAA55

mov ecx, [temp]
temp dd 0x99
times 510-($-$$) db 0
dw 0xAA55
