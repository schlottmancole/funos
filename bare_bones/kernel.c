
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// Issue warning if compiler is targeting the wrong OS
#if defined(__linux__)
#error "You aren't using the cross-compiler!"
#endif

// Tutorial only works for 32-bit ix86 targets
#if !defined(__i386__)
#error "This tutorial needs to be compiled with a ix86-elf compiler"
#endif

// text mode color constants
enum vga_color {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_WHITE = 15,
};

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
	return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
	return (uint16_t) uc | (uint16_t) color << 8;
}

size_t strlen(const char* str) {
	size_t len = 0;
	while(str[len]) len++;
	return len;
}

static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t *terminal_buffer;

void terminal_initialize(void) {
	terminal_row = 0;
	terminal_column = 0;
	terminal_color = vga_entry_color(VGA_COLOR_GREEN, VGA_COLOR_BLACK);
	terminal_buffer = (uint16_t*) 0xB8000;
	for(size_t y = 0; y < VGA_HEIGHT; y++) {
		for(size_t x = 0; x < VGA_WIDTH; x++) {
			const size_t index = y * VGA_WIDTH + x;
			terminal_buffer[index] = vga_entry(' ', terminal_color);
		}
	}
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) {
	const size_t index = y * VGA_WIDTH + x;
	terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(char c) {
	switch(c) {
		case 13:
	        case '\n':
			terminal_column = 0;
			terminal_row += 1;
			break;
		case 127:
			terminal_putentryat(' ', terminal_color, --terminal_column, terminal_row);
			terminal_column -= 1;
			break;
		default:
			terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
			break;
	}
	if(++terminal_column == VGA_WIDTH) {
		terminal_column = 0;
		if(++terminal_row == VGA_HEIGHT) terminal_row = 0;
	}
}

void terminal_write(const char* data, size_t size) {
	for (size_t i = 0; i < size; i++) 
		terminal_putchar(data[i]);
}

void terminal_writestring(const char* data) {
	terminal_write(data, strlen(data));
}

// Serial Port Address
#define PORT 0x3f8 // COM1

// assembly convenience functions
static inline void outb(uint16_t port, uint8_t val) {
	__asm__ volatile ( "outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory");
}

static inline uint8_t inb(uint16_t port) {
	uint8_t ret;
	__asm__ volatile ( "inb %w1, %b0" : "=a"(ret) : "Nd"(port) : "memory");
	return ret;
}

// serial 
static int init_serial() {
	outb(PORT + 1, 0x00); // disable interrupts
	outb(PORT + 3, 0x80); // Enable DLAB (set baud rate divisor)
	outb(PORT + 0, 0x03); // set divisor to 3 (lo byte) 38400 baud
	outb(PORT + 1, 0x00); // (hi byte)
	outb(PORT + 3, 0x03); // 8 bits, no parity, one stop bit
	outb(PORT + 2, 0xC7); // enable FIFO, clear them, with 15-byte threshold
	outb(PORT + 4, 0x0B); // IRQs enabled, RTS/DSR set
	outb(PORT + 4, 0x1E); // set in loopback mode, test the serial chip
	outb(PORT + 0, 0xAE); // test write
	
	if(inb(PORT + 0) != 0xAE) {
		return 1;
	}

	outb(PORT + 4, 0x0F); // else disable loopback
	return 0;
	
}

int serial_received() {
	return inb(PORT + 5) & 1;
}

char read_serial() {
	while (serial_received() == 0);
	return inb(PORT);
}

int is_transmit_empty() {
	return inb(PORT + 5) & 0x20;
}

void write_serial(char a) {
	while (is_transmit_empty() == 0);
	outb(PORT, a);
}

void write_str(char *str) {
	while(*str) write_serial(*str++);
}

typedef struct {
	uint32_t flags;
	uint32_t mem_lower;
	uint32_t mem_upper;
	uint32_t boot_device;
	uint32_t cmdline;
	uint32_t mods_count;
	uint32_t mods_addr;
	uint32_t syms0;
	uint32_t syms1;
	uint32_t syms2;
	uint32_t mmap_length;
	uint32_t mmap_addr;
	uint32_t drives_length;
	uint32_t drives_addr;
	uint32_t config_table;
	uint32_t boot_loader_name;
	uint32_t apm_table;
	uint32_t vbe_control_info;
	uint32_t vbe_mode_info;
	uint16_t vbe_mode;
	uint16_t vbe_interface_seg;
	uint32_t vbe_interface_off;
	uint32_t vbe_interface_len;
	uint64_t framebuffer_addr;
	uint32_t framebuffer_pitch;
	uint32_t framebuffer_width;
	uint32_t framebuffer_height;
	uint8_t framebuffer_bpp;
	uint8_t framebuffer_type;
	uint8_t color_info[5];
} multiboot_table;


void green(const multiboot_table *mb) {
	uint32_t width = mb->framebuffer_width;
	uint32_t height = mb->framebuffer_height;
	uint32_t *screen = (uint32_t*)mb->framebuffer_addr;
	
	for(uint32_t i=0; i < width*height; i++) { screen[i] = 0xC0C0C0; }

}

void print_hex(uint32_t w) {
	write_str("0x");
	for(int32_t i=28; i >= 0; i-=4){
		uint8_t b = (w >> i) & 0xF;
		if(b > 9) { b += 55; }
		else { b += 48; }
		write_serial((char) b);
	}
}
// 
// 
// EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
// UINTN SizeOfInfo, numModes, nativeMode;
// 
// status = uefi_call_wrapper(gop->QueryMode, 4, gop, gop->Mode==NULL? 0 : gop->Mode->Mode, &SizeOfInfo, &info);
// if (status == EFI_NOT_STARTED) {
// 	status = uefi_call_wrapper(gop->SetMode, 2, gop, 0);
// }
// if (EFI_ERROR(status)) {
// 	PrintLn(L"Unable to get native mode");
// } else {
// 	nativeMode = gop->Mode->Mode;
// 	numModes = gop->Mode->MaxMode;
// }

void text_mode_main() {
	terminal_initialize();
	init_serial();
	terminal_writestring("Hello, kernel World!\n");
	while(1) {
	       terminal_putchar(read_serial());
	}	
}

void serial_main() {

	init_serial();
	write_str("Hello World!");
	while(1) {
	       write_serial(read_serial());
	}	
}

void show_multiboot_table(const multiboot_table* mb, uint32_t magic) {
	init_serial();
	write_str("\nmagic: ");
	print_hex(magic);
	write_str("\nMB Addr: ");
	print_hex((uint32_t) mb);

	// for(uint32_t* p = (uint32_t*)mb; (uint32_t)p < (uint32_t)(mb+1); p++){
	// 	write_str("\n");
	// 	print_hex((uint32_t)p);
	// 	write_str(": ");
	// 	print_hex(*p);
	// }

	write_str("\nwidth: ");
	print_hex(mb->framebuffer_width);
	write_str("\nheight: ");
	print_hex(mb->framebuffer_height);

	// *((int*)(mb->framebuffer_addr)) = 0x00FF0000;
}

void kernel_main(const multiboot_table* mb, uint32_t magic) {
	text_mode_main();	
}

