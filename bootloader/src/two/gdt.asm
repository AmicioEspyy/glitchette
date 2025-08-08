; gdt setup for protected mode

setup_gdt:
    lgdt [gdt_descriptor]       
    ret

gdt_start:
    ; null descriptor - required first entry
    gdt_null:
        dd 0x00000000           
        dd 0x00000000           

    ; code segment - ring 0, 32-bit
    gdt_code:
        dw 0xFFFF               ; Limit (low 16 bits) - 4GB limit
        dw 0x0000               ; Base (low 16 bits) - base 0
        db 0x00                 ; Base (middle 8 bits)
        db 0x9A                 ; Access byte: P=1, DPL=00, S=1, Type=1010 (exec/read)
        db 0xCF                 ; Flags: G=1, D/B=1, L=0, AVL=0, Limit[19:16]=1111
        db 0x00                 

    ; data segment - ring 0, 32-bit
    gdt_data:
        dw 0xFFFF               
        dw 0x0000               
        db 0x00                 
        db 0x92                 
        db 0xCF                 
        db 0x00                 

    ; user code - ring 3, 32-bit (for later)
    gdt_user_code:
        dw 0xFFFF               
        dw 0x0000               
        db 0x00                 
        db 0xFA                 
        db 0xCF                 
        db 0x00                 

    ; user data - ring 3, 32-bit (for later)
    gdt_user_data:
        dw 0xFFFF               
        dw 0x0000               
        db 0x00                 
        db 0xF2                 
        db 0xCF                 
        db 0x00                 

    ; 64-bit code segment
    gdt_code_64:
        dw 0x0000               
        dw 0x0000               
        db 0x00                 
        db 0x9A                 
        db 0xAF                 
        db 0x00                 

    ; 64-bit data segment
    gdt_data_64:
        dw 0x0000               
        dw 0x0000               
        db 0x00                 
        db 0x92                 
        db 0x00                 
        db 0x00                 

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  
    dd gdt_start                

; segment selectors
CODE_SEG        equ gdt_code - gdt_start        
DATA_SEG        equ gdt_data - gdt_start        
USER_CODE_SEG   equ gdt_user_code - gdt_start  
USER_DATA_SEG   equ gdt_user_data - gdt_start  
CODE_SEG_64     equ gdt_code_64 - gdt_start    
DATA_SEG_64     equ gdt_data_64 - gdt_start    

get_gdt_entries:
    mov ax, (gdt_end - gdt_start) / 8
    ret

validate_gdt:
    ; check if gdt is sized right
    mov ax, gdt_end - gdt_start
    cmp ax, 8                   
    jl .invalid
    
    ; check null descriptor
    mov eax, [gdt_start]
    cmp eax, 0
    jne .invalid
    mov eax, [gdt_start + 4]
    cmp eax, 0
    jne .invalid
    
    ; looks good
    mov ax, 1
    ret

.invalid:
    mov ax, 0
    ret
