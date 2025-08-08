#![no_std]
#![no_main]

use core::panic::PanicInfo;

// import drivers
mod drivers;
use drivers::vga::{printstr, clearscr};

#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    clearscr();
    printstr("Glitchette");
    
    loop {
        unsafe {
            core::arch::asm!("hlt");
        }
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    printstr("\nKERNEL PANIC!\n");
    printstr("System halted.\n");
    
    loop {
        unsafe {
            core::arch::asm!("hlt");
        }
    }
}
