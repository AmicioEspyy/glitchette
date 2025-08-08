; stage 2 bootloader

[bits 16]
[org 0x1000]

dw 0x5347

%include "constants.inc"

boot_drive: db 0

start:
    mov ah, 0x0e
    mov al, 'S'
    mov bh, 0x00
    int 0x10

    mov [boot_drive], dl
    
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    sti

    mov ah, 0x0e
    mov al, '2'
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    
    mov si, msg_stage2_loaded
    call print_string

    call enable_a20

    mov si, msg_loading_kernel
    call print_string
    
    call load_kernel

    mov ah, 0x0e
    mov al, 'K'
    mov bh, 0x00
    int 0x10

    call check_long_mode_support
    
    mov ah, 0x0e
    mov al, 'C'
    mov bh, 0x00
    int 0x10

    mov si, msg_entering_pmode
    call print_string
    
    mov ah, 0x0e
    mov al, 'P'
    mov bh, 0x00
    int 0x10
    
    call setup_gdt
    call enter_protected_mode

    jmp $

print_string:
    mov ah, 0x0e
    mov bh, 0x00

.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop

.done:
    ret

halt_system:
    cli
    hlt                         
    jmp halt_system

%include "a20.asm"
%include "disk.asm"
%include "cpu.asm"
%include "gdt.asm"
%include "pmode.asm"

msg_stage2_loaded: db 'Glitchette Stage 2 Loaded!', 0x0d, 0x0a, 0
msg_loading_kernel: db 'Loading kernel...', 0x0d, 0x0a, 0
msg_entering_pmode: db 'Entering protected mode...', 0x0d, 0x0a, 0