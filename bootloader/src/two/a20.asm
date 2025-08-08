; need a20 to access memory above 1MB
; tries bios, keyboard controller, then fast gate method

enable_a20:
    push ax
    push cx

    call check_a20
    cmp ax, 1
    je .a20_enabled

    ; try bios first
    call enable_a20_bios
    call check_a20
    cmp ax, 1
    je .a20_enabled

    ; fallback to keyboard controller
    call enable_a20_keyboard
    call check_a20
    cmp ax, 1
    je .a20_enabled

    ; last resort - fast gate
    call enable_a20_fast
    call check_a20
    cmp ax, 1
    je .a20_enabled

    ; we're screwed
    mov si, msg_a20_error
    call print_string
    jmp halt_system

.a20_enabled:
    mov si, msg_a20_enabled
    call print_string
    
    pop cx
    pop ax
    ret

; returns 1 if enabled, 0 if disabled
check_a20:
    push ds
    push es
    push di
    push si

    cli
    
    xor ax, ax
    mov ds, ax
    mov di, 0x0500

    mov ax, 0xffff
    mov es, ax
    mov si, 0x0510

    mov al, byte [ds:di]
    push ax
    mov al, byte [es:si]
    push ax

    mov byte [ds:di], 0x00
    mov byte [es:si], 0xFF

    cmp byte [ds:di], 0xFF      ; if a20 disabled, addresses wrap around

    pop ax
    mov byte [es:si], al
    pop ax
    mov byte [ds:di], al

    mov ax, 0
    je .done
    mov ax, 1

.done:
    sti
    pop si
    pop di
    pop es
    pop ds
    ret

enable_a20_bios:
    mov ax, 0x2401
    int 0x15
    ret

enable_a20_keyboard:
    ; disable keyboard first
    call wait_8042_command
    mov al, 0xad
    out 0x64, al

    ; read current output port
    call wait_8042_command
    mov al, 0xd0
    out 0x64, al

    call wait_8042_data
    in al, 0x60
    push ax

    ; write back with a20 bit set
    call wait_8042_command
    mov al, 0xd1
    out 0x64, al

    call wait_8042_command
    pop ax
    or al, 2
    out 0x60, al

    ; re-enable keyboard
    call wait_8042_command
    mov al, 0xae
    out 0x64, al

    call wait_8042_command
    ret

enable_a20_fast:
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    and al, 0xfe                ; don't reset system
    out 0x92, al

.done:
    ret

wait_8042_command:
    in al, 0x64
    test al, 2                  ; wait for input buffer to be empty
    jnz wait_8042_command
    ret

wait_8042_data:
    in al, 0x64
    test al, 1                  ; wait for output buffer to have data
    jz wait_8042_data
    ret

msg_a20_enabled: db 'A20 line enabled', 0x0d, 0x0a, 0
msg_a20_error: db 'ERROR: Failed to enable A20 line!', 0x0d, 0x0a, 0


