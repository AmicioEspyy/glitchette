; load kernel from disk and check signature

load_kernel:
    push ax
    push bx
    push cx
    push dx

    ; reset disk first
    call reset_disk
    jc .disk_error

    ; debug
    mov ah, 0x0e
    mov al, '1'
    mov bh, 0x00
    int 0x10

    ; Load kernel sectors
    mov ah, 0x02                ; Read sectors function
    mov al, KERNEL_SECTORS      ; Number of sectors to read
    mov ch, 0x00                ; Cylinder 0
    mov cl, KERNEL_START_SECTOR ; Starting sector
    mov dh, 0x00                ; Head 0
    mov dl, [boot_drive]        ; Drive number from Stage 1
    
    ; Debug: Print drive number + '0' to see what drive we're using
    push ax
    mov ah, 0x0e
    mov al, [boot_drive]
    add al, '0'                 ; Convert to ASCII
    mov bh, 0x00
    int 0x10
    pop ax
    
    ; Set up segment:offset for 64KB (0x10000) - back to correct location
    push es                     ; Save ES
    mov bx, 0x1000             ; Segment for 64KB
    mov es, bx                 ; ES = 0x1000
    mov bx, 0x0000             ; Offset = 0x0000
    
    ; Debug: Print '2' before disk read
    push ax
    mov ah, 0x0e
    mov al, '2'
    mov bh, 0x00
    int 0x10
    pop ax
    
    ; keep ah = 0x02
    mov ah, 0x02
    
    int 0x13                    
    
    pop es                      

    ; debug - print '3' after read
    push ax
    mov ah, 0x0e
    mov al, '3'
    mov bh, 0x00
    int 0x10
    pop ax

    jc .disk_error              
    
    ; check ah for error even if cf not set
    push ax
    mov bl, ah                  
    cmp ah, 0
    je .no_error                
    
    ; print error code
    mov ah, 0x0e
    mov al, 'H'                 
    int 0x10
    
    ; convert to hex and print
    mov al, bl
    shr al, 4                   
    add al, '0'
    cmp al, '9'
    jle .high_ok
    add al, 7
.high_ok:
    mov ah, 0x0e
    int 0x10
    
    mov al, bl
    and al, 0x0F               
    add al, '0'
    cmp al, '9'
    jle .low_ok
    add al, 7
.low_ok:
    mov ah, 0x0e
    int 0x10
    
    pop ax
    jmp .disk_error

.no_error:
    pop ax

    ; check kernel signature at 0x10000
    push es                     
    mov bx, 0x1000             
    mov es, bx                 
    mov ax, [es:0x0000]        
    pop es                      
    
    ; check for "GK" signature
    cmp ax, KERNEL_SIGNATURE    
    jne .kernel_error

    ; success
    mov si, msg_kernel_loaded
    call print_string

    pop dx
    pop cx
    pop bx
    pop ax
    ret

.disk_error:
    ; debug - print 'E' for error
    mov ah, 0x0e
    mov al, 'E'
    mov bh, 0x00
    int 0x10
    jmp halt_system

.disk_error_with_code:
    ; print error code in ah
    push ax
    mov ah, 0x0e
    mov al, 'E'
    mov bh, 0x00
    int 0x10
    
    ; print error as hex
    pop ax
    push ax
    shr al, 4              
    add al, '0'
    cmp al, '9'
    jle .print_high
    add al, 7              
.print_high:
    mov ah, 0x0e
    int 0x10
    
    pop ax
    and al, 0x0F           ; Get low nibble  
    add al, '0'
    cmp al, '9'
    jle .print_low
    add al, 7              ; Convert to A-F
.print_low:
    mov ah, 0x0e
    int 0x10
    jmp halt_system

.kernel_error:
    ; Debug: Print 'S' for signature error  
    mov ah, 0x0e
    mov al, 'S'
    mov bh, 0x00
    int 0x10
    jmp halt_system

reset_disk:
    push ax
    push dx

    mov ah, 0x00                
    mov dl, [boot_drive]        
    int 0x13                    

    pop dx
    pop ax
    ret

; read with retries
read_sectors_retry:
    push cx
    push ax

    mov cx, 3                   

.retry_loop:
    ; save regs for retry
    push ax
    push bx
    push cx
    push dx

    mov ah, 0x02                
    int 0x13                    

    ; restore regs
    pop dx
    pop cx
    pop bx
    pop ax

    jnc .success                

    ; reset and retry
    push ax
    call reset_disk
    pop ax

    dec cx                      
    jnz .retry_loop             

    ; all retries failed
    stc                         
    jmp .done

.success:
    clc                         

.done:
    pop ax
    pop cx
    ret

; get drive params
get_drive_params:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    mov ah, 0x08                
    int 0x13                    

    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; messages
msg_kernel_loaded: db 'Kernel loaded successfully', 0x0d, 0x0a, 0
msg_disk_error: db 'ERROR: Disk read error!', 0x0d, 0x0a, 0
msg_kernel_error: db 'ERROR: Invalid kernel signature!', 0x0d, 0x0a, 0
