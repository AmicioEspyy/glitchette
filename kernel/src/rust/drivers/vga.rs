const VGA_BUFFER: *mut u16 = 0xb8000 as *mut u16;  
const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;

const CRTC_INDEX: u16 = 0x3D4;
const CRTC_DATA: u16 = 0x3D5;

static mut CURSOR_POS: usize = 0;

#[repr(u8)]
#[derive(Clone, Copy)]
pub enum VgaColor {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
}

/// make color byte from fg/bg colors
fn vga_entry_color(fg: VgaColor, bg: VgaColor) -> u8 {
    (fg as u8) | ((bg as u8) << 4)
}

/// combine char + color into u16
fn vga_entry(ch: u8, color: u8) -> u16 {
    (ch as u16) | ((color as u16) << 8)
}

/// write byte to port
unsafe fn outb(port: u16, value: u8) {
    core::arch::asm!(
        "out dx, al",
        in("dx") port,
        in("al") value,
        options(nomem, nostack, preserves_flags)
    );
}

/// disabled for now - qemu doesn't like it
unsafe fn update_cursor() {
    // outb(CRTC_INDEX, 14);
    // outb(CRTC_DATA, (CURSOR_POS >> 8) as u8);
    // outb(CRTC_INDEX, 15);
    // outb(CRTC_DATA, (CURSOR_POS & 0xFF) as u8);
}

/// move screen up one line
unsafe fn scroll_up() {
    let src = VGA_BUFFER.add(VGA_WIDTH);
    let dst = VGA_BUFFER;
    let count = (VGA_HEIGHT - 1) * VGA_WIDTH;
    
    core::ptr::copy(src, dst, count);
    
    // clear last line
    let last_line_start = (VGA_HEIGHT - 1) * VGA_WIDTH;
    let color = vga_entry_color(VgaColor::LightGrey, VgaColor::Black);
    let blank_entry = vga_entry(b' ', color);
    
    for i in 0..VGA_WIDTH {
        *VGA_BUFFER.add(last_line_start + i) = blank_entry;
    }
}

unsafe fn line_feed() {
    CURSOR_POS = CURSOR_POS - (CURSOR_POS % VGA_WIDTH) + VGA_WIDTH;
    if CURSOR_POS >= VGA_HEIGHT * VGA_WIDTH {
        scroll_up();
        CURSOR_POS -= VGA_WIDTH;
    }
}

/// clear screen
pub fn clearscr() {
    unsafe {
        let color = vga_entry_color(VgaColor::LightGrey, VgaColor::Black);
        let blank_entry = vga_entry(b' ', color);
        
        for i in 0..(VGA_WIDTH * VGA_HEIGHT) {
            *VGA_BUFFER.add(i) = blank_entry;
        }
        
        CURSOR_POS = 0;
        update_cursor();
    }
}

/// write single char
pub fn write_char(ch: u8) {
    unsafe {
        if ch == b'\n' {
            line_feed();
        } else {
            let color = vga_entry_color(VgaColor::LightGrey, VgaColor::Black);
            let entry = vga_entry(ch, color);
            
            *VGA_BUFFER.add(CURSOR_POS) = entry;
            CURSOR_POS += 1;
            
            if CURSOR_POS >= VGA_HEIGHT * VGA_WIDTH {
                scroll_up();
                CURSOR_POS -= VGA_WIDTH;
            }
        }
        
        update_cursor();
    }
}

/// print string
pub fn printstr(s: &str) {
    for byte in s.bytes() {
        write_char(byte);
    }
}
