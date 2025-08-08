; check if cpu supports 64-bit mode

check_long_mode_support:
    push eax
    push ecx
    push edx

    ; check if cpuid works first
    call check_cpuid_support
    cmp ax, 0
    je .no_cpuid

    ; check extended cpuid
    mov eax, 0x80000000         
    cpuid
    cmp eax, 0x80000001         ; need at least 80000001h
    jl .no_long_mode

    ; check for 64-bit support
    mov eax, 0x80000001         
    cpuid
    test edx, (1 << LONG_MODE_BIT) ; bit 29
    jz .no_long_mode

    ; we got 64-bit support
    mov si, msg_long_mode_ok
    call print_string
    jmp .done

.no_cpuid:
    mov si, msg_no_cpuid
    call print_string
    jmp halt_system

.no_long_mode:
    mov si, msg_no_long_mode
    call print_string
    jmp halt_system

.done:
    pop edx
    pop ecx
    pop eax
    ret

; check if cpuid instruction works
check_cpuid_support:
    push ebx
    push ecx

    ; try flipping cpuid flag in eflags
    pushf                       
    pop eax                     
    mov ecx, eax                
    xor eax, CPUID_FLAG         
    push eax                    
    popf                        

    ; see if flag actually flipped
    pushf                       
    pop eax                     
    cmp eax, ecx                
    je .no_cpuid                

    ; cpuid works
    mov ax, 1
    jmp .done

.no_cpuid:
    mov ax, 0

.done:
    push ecx                    
    popf
    pop ecx
    pop ebx
    ret

; get basic cpu info
get_cpu_info:
    push eax
    push ebx
    push ecx
    push edx

    ; make sure cpuid works
    call check_cpuid_support
    cmp ax, 0
    je .no_cpuid

    ; get vendor string
    mov eax, 0                  
    cpuid
    ; ebx, edx, ecx have vendor string

    ; get feature flags
    mov eax, 1                  
    cpuid
    ; edx and ecx have feature flags

    jmp .done

.no_cpuid:
    ; old cpu without cpuid
    mov si, msg_no_cpuid
    call print_string

.done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; check for required features
check_required_features:
    push eax
    push ecx
    push edx

    ; check for PAE
    mov eax, 1
    cpuid
    test edx, (1 << 6)          ; PAE bit
    jz .no_pae

    ; check for MSR
    test edx, (1 << 5)          ; MSR bit
    jz .no_msr

    ; all good
    mov si, msg_features_ok
    call print_string
    jmp .done

.no_pae:
    mov si, msg_no_pae
    call print_string
    jmp halt_system

.no_msr:
    mov si, msg_no_msr
    call print_string
    jmp halt_system

.done:
    pop edx
    pop ecx
    pop eax
    ret

; messages
msg_long_mode_ok: db '64-bit support detected', 0x0d, 0x0a, 0
msg_no_cpuid: db 'ERROR: CPUID not supported!', 0x0d, 0x0a, 0
msg_no_long_mode: db 'ERROR: 64-bit mode not supported!', 0x0d, 0x0a, 0
msg_features_ok: db 'Required CPU features present', 0x0d, 0x0a, 0
msg_no_pae: db 'ERROR: PAE not supported!', 0x0d, 0x0a, 0
msg_no_msr: db 'ERROR: MSR not supported!', 0x0d, 0x0a, 0
