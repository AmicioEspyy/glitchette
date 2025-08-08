/* ==============================================================================
 * Glitchette Kernel Linker Script
 * ==============================================================================
 * This linker script defines the memory layout for the Glitchette kernel.
 * It ensures proper placement of code, data, and BSS sections.
 * ==============================================================================
 */

ENTRY(_start)

SECTIONS
{
    /* Kernel loads at 64KB mark (0x10000) */
    . = 0x10000;
    
    /* Kernel signature and entry point */
    .text ALIGN(4K) : {
        *(.text.entry)          /* Assembly entry point first */
        *(.text .text.*)        /* All other code */
    }
    
    /* Read-only data */
    .rodata ALIGN(4K) : {
        *(.rodata .rodata.*)
    }
    
    /* Initialized data */
    .data ALIGN(4K) : {
        *(.data .data.*)
    }
    
    /* Uninitialized data */
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss .bss.*)
    }
    
    /* Stack grows downward from this address */
    . = ALIGN(4K);
    _kernel_end = .;
    
    /* Discard unnecessary sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
    }
}
