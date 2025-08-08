KERNEL_LOAD_ADDR    equ 0x10000
STACK_16BIT         equ 0x7c00
STACK_32BIT         equ 0x90000
VGA_TEXT_BUFFER     equ 0xb8000

KERNEL_START_SECTOR equ 0x07
KERNEL_SECTORS      equ 4

KERNEL_SIGNATURE    equ 0x4B47

SCREEN_WIDTH        equ 80
SCREEN_HEIGHT       equ 25
BYTES_PER_CHAR      equ 2

ATTR_GRAY           equ 0x07
ATTR_WHITE          equ 0x0F
ATTR_RED            equ 0x04
ATTR_GREEN          equ 0x02

CHAR_NULL           equ 0x00
CHAR_CR             equ 0x0D
CHAR_LF             equ 0x0A
CHAR_SPACE          equ 0x20

CPUID_FLAG          equ 0x00200000
LONG_MODE_BIT       equ 29

CR0_PE              equ 1
