; simple bios services for 16-bit mode

; print string - si points to null-terminated string
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

print_char:
    mov ah, 0x0e                
    mov bh, 0x00                
    int 0x10                    
    ret

print_newline:
    mov al, 0x0d                
    call print_char
    mov al, 0x0a                
    call print_char
    ret

wait_key:
    mov ah, 0x00                
    int 0x16                    
    ret

halt_system:
    cli                         
    hlt                         
    jmp halt_system             
