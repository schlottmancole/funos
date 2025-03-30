.set ALIGN, 1<<0
.set MEMINFO, 1<<1
.set VIDEO, 1<<2
/*.set FLAGS, ALIGN | MEMINFO | VIDEO*/
.set FLAGS, ALIGN | MEMINFO
.set MAGIC, 0x1BADB002
.set CHECKSUM, -(MAGIC + FLAGS)
.set MODE_TYPE, 0
.set WIDTH, 0
.set HEIGHT, 0
.set DEPTH, 0

.set HEADER_ADDR, 0
.set LOAD_ADDR, 0
.set LOAD_END_ADDR, 0
.set BSS_END_ADDR, 0
.set ENTRY_ADDR, 0

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM
.long HEADER_ADDR
.long LOAD_ADDR
.long LOAD_END_ADDR
.long BSS_END_ADDR
.long ENTRY_ADDR
.long MODE_TYPE
.long WIDTH
.long HEIGHT
.long DEPTH
.space 4 * 13


.section .bss
.align 16
stack_bottom:
.skip 16384
stack_top:

.section .text
.global _start
.type _start, @function
_start:
  mov $stack_top, %esp
  push %eax /* pass magic number */
  push %ebx /* Pass addr of Multiboot Info Struct as argument */
  call kernel_main
  cli
1:hlt
  jmp 1b

.size _start, . - _start
