; stage 1 bootloader

[bits 16]
[org 0x7c00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    
    mov si, msg_loading
    call print
    
    ; load stage 2 (4 sectors from sector 2)
    mov ah, 0x02
    mov al, 4
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, 0x00
    mov bx, 0x1000
    int 0x13
    jc error
    
    ; check stage 2 signature
    mov ax, [0x1000]
    cmp ax, 0x5347
    jne error
    
    mov si, msg_success
    call print
    
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov dl, 0x00
    
    jmp 0x0000:0x1000

print:
    mov ah, 0x0e
    mov bx, 0x0007
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

error:
    mov si, msg_error
    call print
    cli
    hlt
    jmp error

msg_loading     db 'Loading Stage 2...', 13, 10, 0
msg_error       db 'Error!', 13, 10, 0
msg_success     db 'Stage 2 found!', 13, 10, 0

times 510-($-$$) db 0
dw 0xaa55
