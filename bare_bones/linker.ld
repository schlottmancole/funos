/* bootloader will start execution at the symbol designated as the entry point */
ENTRY(_start)

SECTIONS
{
	/* start at 2M in RAM to avoid bootloader firmware */
	. = 2M;
	/* Multiboot header has to appear early in the file */
	.text BLOCK(4K) : ALIGN(4K)
	{
		*(.multiboot)
		*(.text)
	}

	.rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
	}
	.data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
	}

	.bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
	}
}

