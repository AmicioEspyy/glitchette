enter_protected_mode:
    cli

    mov ah, 0x0e
    mov al, 'X'
    mov bh, 0x00
    int 0x10

    mov eax, cr0
    or eax, CR0_PE
    mov cr0, eax

    jmp CODE_SEG:protected_mode_start

[bits 32]
protected_mode_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov esp, STACK_32BIT

    mov edi, VGA_TEXT_BUFFER
    
    mov word [edi], 0x0733      ; '3'
    add edi, 2
    mov word [edi], 0x0732      ; '2'
    add edi, 2
    mov word [edi], 0x0742      ; 'B'
    add edi, 2
    mov word [edi], 0x0749      ; 'I'
    add edi, 2
    mov word [edi], 0x0754      ; 'T'
    add edi, 2
    mov word [edi], 0x0720      ; ' '
    add edi, 2
    mov word [edi], 0x074D      ; 'M'
    add edi, 2
    mov word [edi], 0x074F      ; 'O'
    add edi, 2
    mov word [edi], 0x0744      ; 'D'
    add edi, 2
    mov word [edi], 0x0745      ; 'E'
    add edi, 2
    mov word [edi], 0x0720      ; ' '
    add edi, 2
    mov word [edi], 0x074F      ; 'O'
    add edi, 2
    mov word [edi], 0x074B      ; 'K'

    add edi, 4
    mov word [edi], 0x074B      ; 'K'
    add edi, 2
    mov word [edi], 0x0745      ; 'E'
    add edi, 2
    mov word [edi], 0x0752      ; 'R'
    add edi, 2
    mov word [edi], 0x074E      ; 'N'
    add edi, 2
    mov word [edi], 0x0745      ; 'E'
    add edi, 2
    mov word [edi], 0x074C      ; 'L'

    call jump_to_kernel

    mov esi, msg_kernel_returned_32
    call print_string_32
    jmp halt_32

clear_screen_32:
    push eax
    push ecx
    push edi

    mov edi, VGA_TEXT_BUFFER
    mov eax, 0x07200720
    mov ecx, (SCREEN_WIDTH * SCREEN_HEIGHT) / 2
    rep stosd

    mov dword [cursor_pos_32], 0
    mov dword [cursor_pos_32], 0

    pop edi
    pop ecx
    pop eax
    ret

print_string_32:
    push eax
    push edx
    push edi

    mov edi, VGA_TEXT_BUFFER
    add edi, [cursor_pos_32]

.loop:
    lodsb
    cmp al, CHAR_NULL
    je .done
    
    cmp al, CHAR_LF
    je .newline
    
    cmp al, CHAR_CR
    je .loop
    
    mov ah, ATTR_GRAY
    stosw
    add dword [cursor_pos_32], BYTES_PER_CHAR
    
    ; wrap to next line if needed
    mov eax, [cursor_pos_32]
    mov edx, 0
    mov ecx, SCREEN_WIDTH * BYTES_PER_CHAR
    div ecx
    cmp edx, 0
    jne .loop
    
    call newline_32
    mov edi, VGA_TEXT_BUFFER
    add edi, [cursor_pos_32]
    jmp .loop

.newline:
    call newline_32
    mov edi, VGA_TEXT_BUFFER
    add edi, [cursor_pos_32]
    jmp .loop

.done:
    pop edi
    pop edx
    pop eax
    ret

newline_32:
    push eax
    push edx
    push ecx

    mov eax, [cursor_pos_32]
    mov edx, 0
    mov ecx, SCREEN_WIDTH * BYTES_PER_CHAR
    div ecx
    inc eax
    mul ecx
    
    ; scroll if we're at the bottom
    cmp eax, (SCREEN_WIDTH * SCREEN_HEIGHT * BYTES_PER_CHAR)
    jl .no_scroll
    
    call scroll_screen_32
    mov eax, (SCREEN_WIDTH * (SCREEN_HEIGHT - 1) * BYTES_PER_CHAR)

.no_scroll:
    mov [cursor_pos_32], eax

    pop ecx
    pop edx
    pop eax
    ret

scroll_screen_32:
    push eax
    push ecx
    push edi
    push esi

    ; move everything up one line
    mov esi, VGA_TEXT_BUFFER + (SCREEN_WIDTH * BYTES_PER_CHAR)
    mov edi, VGA_TEXT_BUFFER
    mov ecx, (SCREEN_WIDTH * (SCREEN_HEIGHT - 1))
    rep movsw

    ; clear last line
    mov edi, VGA_TEXT_BUFFER + (SCREEN_WIDTH * (SCREEN_HEIGHT - 1) * BYTES_PER_CHAR)
    mov eax, 0x07200720
    mov ecx, SCREEN_WIDTH / 2
    rep stosd

    pop esi
    pop edi
    pop ecx
    pop eax
    ret

print_char_32:
    push eax
    push edi

    mov edi, VGA_TEXT_BUFFER
    add edi, [cursor_pos_32]
    
    mov ah, ATTR_GRAY
    stosw
    
    add dword [cursor_pos_32], BYTES_PER_CHAR

    pop edi
    pop eax
    ret

print_hex_32:
    push eax
    push ebx
    push ecx
    push edx

    mov ecx, 8
    mov ebx, eax

.loop:
    rol ebx, 4
    mov eax, ebx
    and eax, 0x0F
    
    ; make it ascii
    cmp eax, 9
    jle .digit
    add eax, 'A' - '0' - 10
.digit:
    add eax, '0'
    
    call print_char_32
    dec ecx
    jnz .loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

halt_32:
    cli
    hlt
    jmp halt_32

jump_to_kernel:
    ; show debug msg
    mov edi, VGA_TEXT_BUFFER + (SCREEN_WIDTH * 2 * 2)
    
    ; write "JUMPING TO KERNEL..."
    mov word [edi], 0x074A
    add edi, 2
    mov word [edi], 0x0755
    add edi, 2
    mov word [edi], 0x074D
    add edi, 2
    mov word [edi], 0x0750
    add edi, 2
    mov word [edi], 0x0749
    add edi, 2
    mov word [edi], 0x074E
    add edi, 2
    mov word [edi], 0x0747
    add edi, 2
    mov word [edi], 0x0720
    add edi, 2
    mov word [edi], 0x0754
    add edi, 2
    mov word [edi], 0x074F
    add edi, 2
    mov word [edi], 0x0720
    add edi, 2
    mov word [edi], 0x074B
    add edi, 2
    mov word [edi], 0x0745
    add edi, 2
    mov word [edi], 0x0752
    add edi, 2
    mov word [edi], 0x074E
    add edi, 2
    mov word [edi], 0x0745
    add edi, 2
    mov word [edi], 0x074C
    add edi, 2
    mov word [edi], 0x072E
    add edi, 2
    mov word [edi], 0x072E
    add edi, 2
    mov word [edi], 0x072E

    ; check if kernel is loaded
    mov edi, VGA_TEXT_BUFFER + (SCREEN_WIDTH * 3 * 2)
    
    ; read kernel signature
    mov esi, KERNEL_LOAD_ADDR
    mov eax, [esi]
    
    ; show what we read
    call print_hex_32
    call clear_screen_32

    ; jump to kernel (skip 4 byte signature)
    jmp KERNEL_LOAD_ADDR + 4

    ; if we get here, kernel returned unexpectedly
    mov edi, VGA_TEXT_BUFFER + (SCREEN_WIDTH * 4 * 2)
    mov word [edi], 0x0752
    add edi, 2
    mov word [edi], 0x0745
    add edi, 2
    mov word [edi], 0x0754
    add edi, 2
    mov word [edi], 0x0755
    add edi, 2
    mov word [edi], 0x0752
    add edi, 2
    mov word [edi], 0x074E
    add edi, 2
    mov word [edi], 0x0745
    add edi, 2
    mov word [edi], 0x0744



    jmp halt_32

cursor_pos_32       dd 0

msg_pmode_32: db 'Protected mode active!', 0
msg_calling_kernel_32: db 'Calling kernel...', 0
msg_kernel_returned_32: db 'ERROR: Kernel returned unexpectedly!', 0
