; transition from 32-bit to 64-bit and setup for rust kernel

[bits 32]

section .text.entry

; kernel signature - expected by bootloader
KERNEL_SIGNATURE    dw 0x4B47   ; "GK" 
KERNEL_VERSION      dw 0x0100   

; memory layout
STACK_64BIT         equ 0x500000    ; 5mb for 64-bit stack  
PAGE_TABLE_BASE     equ 0x100000    ; 1mb for page tables
KERNEL_HEAP_START   equ 0x300000    ; 3mb for kernel heap

; gdt selectors from bootloader
CODE_SEG_64         equ 0x28        
DATA_SEG_64         equ 0x30        
CODE_SEG_32         equ 0x08        
DATA_SEG_32         equ 0x10        

; page flags
PAGE_PRESENT        equ 1
PAGE_WRITABLE       equ 2
PAGE_USER           equ 4
PAGE_WRITE_THROUGH  equ 8
PAGE_CACHE_DISABLE  equ 16
PAGE_ACCESSED       equ 32
PAGE_DIRTY          equ 64
PAGE_SIZE           equ 128
PAGE_GLOBAL         equ 256

; control register bits
CR0_PE              equ 1        
CR0_PG              equ 0x80000000 
CR4_PAE             equ 32       
CR4_PGE             equ 128      
EFER_LME            equ 256      
EFER_LMA            equ 1024     

global _start
_start:
    cli

    call clear_screen_32

    mov esi, msg_kernel_start
    call print_string_32

    call check_long_mode_required

    mov esi, msg_setup_paging
    call print_string_32

    call setup_long_mode_paging

    mov esi, msg_enable_long_mode
    call print_string_32

    call enable_long_mode

    jmp CODE_SEG_64:long_mode_start

check_long_mode_required:
    ; check for extended cpuid
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jl .no_long_mode

    ; check for long mode bit
    mov eax, 0x80000001
    cpuid
    test edx, (1 << 29)         
    jz .no_long_mode

    ret

.no_long_mode:
    mov esi, msg_no_long_mode
    call print_string_32
    jmp kernel_panic_32

setup_long_mode_paging:
    ; clear page tables (16kb total)
    mov edi, PAGE_TABLE_BASE
    mov ecx, 4096               
    xor eax, eax
    rep stosd

    ; pml4 points to pdpt
    mov edi, PAGE_TABLE_BASE
    mov eax, PAGE_TABLE_BASE + 0x1000
    or eax, PAGE_PRESENT | PAGE_WRITABLE
    mov [edi], eax

    ; pdpt points to pd
    mov edi, PAGE_TABLE_BASE + 0x1000
    mov eax, PAGE_TABLE_BASE + 0x2000
    or eax, PAGE_PRESENT | PAGE_WRITABLE
    mov [edi], eax

    ; pd maps first few 2mb pages
    mov edi, PAGE_TABLE_BASE + 0x2000
    mov eax, 0x00000000
    or eax, PAGE_PRESENT | PAGE_WRITABLE | PAGE_SIZE
    mov [edi], eax

    ; second 2mb
    mov eax, 0x00200000
    or eax, PAGE_PRESENT | PAGE_WRITABLE | PAGE_SIZE
    mov [edi + 8], eax

    ; third 2mb
    mov eax, 0x00400000
    or eax, PAGE_PRESENT | PAGE_WRITABLE | PAGE_SIZE
    mov [edi + 16], eax

    ; fourth 2mb (for 64-bit stack)
    mov eax, 0x00600000
    or eax, PAGE_PRESENT | PAGE_WRITABLE | PAGE_SIZE
    mov [edi + 24], eax

    mov eax, PAGE_TABLE_BASE
    mov cr3, eax

    ret

enable_long_mode:
    ; enable pae
    mov eax, cr4
    or eax, CR4_PAE
    mov cr4, eax

    ; set long mode bit in efer
    mov ecx, 0xC0000080         
    rdmsr
    or eax, EFER_LME            
    wrmsr

    ; enable paging (activates long mode)
    mov eax, cr0
    or eax, CR0_PG
    mov cr0, eax

    ret

print_string_32:
    push eax
    push ebx
    push ecx
    push edi

    mov edi, 0xb8000            
    mov eax, [cursor_pos_32]
    add edi, eax

.loop:
    lodsb                       
    cmp al, 0                   
    je .done
    
    cmp al, 0x0a                
    je .newline
    
    mov ah, 0x0F                
    stosw                       
    add dword [cursor_pos_32], 2 
    jmp .loop

.newline:
    ; move to next line
    mov eax, [cursor_pos_32]
    mov ebx, 160                
    mov edx, 0
    div ebx                     
    inc eax                     
    mul ebx                     
    mov [cursor_pos_32], eax
    mov edi, 0xb8000
    add edi, eax
    jmp .loop

.done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

; clear 32-bit vga screen
clear_screen_32:
    push eax
    push ecx
    push edi
    
    mov edi, 0xb8000            
    mov eax, 0x0F200F20         
    mov ecx, 80 * 25 / 2        
    rep stosd                   
    
    mov dword [cursor_pos_32], 0 
    
    pop edi
    pop ecx
    pop eax
    ret

kernel_panic_32:
    mov esi, msg_panic
    call print_string_32
    cli
    hlt
    jmp kernel_panic_32

[bits 64]
long_mode_start:
    ; setup 64-bit segments
    mov ax, DATA_SEG_64         
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; setup aligned stack
    mov rsp, STACK_64BIT
    and rsp, ~0xF               

    call clear_screen_64
    mov rsi, msg_long_mode_active
    call print_string_64

    ; init heap pointer
    mov rax, KERNEL_HEAP_START
    mov [kernel_heap_ptr], rax

    mov rsi, msg_calling_rust
    call print_string_64

    mov rsi, msg_debug_stack
    call print_string_64

    ; align stack for rust abi
    and rsp, ~0xF               
    sub rsp, 8                  

    ; call rust main
    extern rust_main
    call rust_main

    add rsp, 8

    ; shouldn't get here
    mov rsi, msg_rust_returned
    call print_string_64
    jmp kernel_halt_64

clear_screen_64:
    push rax
    push rcx
    push rdi

    mov rdi, 0xb8000            
    mov rax, 0x0F200F20         
    mov rcx, 80 * 25 / 2        
    rep stosq

    mov qword [cursor_pos_64], 0

    pop rdi
    pop rcx
    pop rax
    ret

print_string_64:
    push rax
    push rdi

    mov rdi, 0xb8000
    add rdi, [cursor_pos_64]

.loop:
    lodsb
    cmp al, 0
    je .done
    
    cmp al, 0x0a
    je .newline
    
    mov ah, 0x0F                
    stosw
    add qword [cursor_pos_64], 2
    jmp .loop

.newline:
    mov rax, [cursor_pos_64]
    add rax, 160
    and rax, ~159
    mov [cursor_pos_64], rax
    mov rdi, 0xb8000
    add rdi, rax
    jmp .loop

.done:
    pop rdi
    pop rax
    ret

kernel_halt_64:
    cli
    hlt
    jmp kernel_halt_64

; exports for rust to use
global print_char_64
print_char_64:
    ; rdi = character to print
    push rax
    push rbx
    push rcx
    push rdx

    mov rax, rdi                
    mov rbx, 0xb8000
    add rbx, [cursor_pos_64]
    
    mov ah, 0x0F                
    mov [rbx], ax
    
    add qword [cursor_pos_64], 2

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

global newline_64
newline_64:
    push rax
    
    mov rax, [cursor_pos_64]
    add rax, 160
    and rax, ~159
    mov [cursor_pos_64], rax
    
    pop rax
    ret

cursor_pos_32       dd 0
cursor_pos_64       dq 0
kernel_heap_ptr     dq 0

msg_kernel_start    db 'Glitchette Kernel Starting...', 0x0a, 0
msg_setup_paging    db 'Setting up long mode paging...', 0x0a, 0
msg_enable_long_mode db 'Enabling long mode...', 0x0a, 0
msg_long_mode_active db 'Long mode active!', 0x0a, 0
msg_calling_rust    db 'Calling Rust kernel...', 0x0a, 0
msg_debug_stack     db 'Debug: About to call Rust main', 0x0a, 0
msg_rust_returned   db 'ERROR: Rust kernel returned!', 0x0a, 0
msg_no_long_mode    db 'ERROR: Long mode not supported!', 0x0a, 0
msg_panic           db 'KERNEL PANIC!', 0x0a, 0