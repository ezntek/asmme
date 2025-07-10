%include "common.inc"

strlen:
    ;; rdi: const char*
    ;; rax: counter

    ; clear counter
    xor rax, rax
    strlen_loop:
        ; check null termination
        ; rax is our offset
        cmp byte [rdi+rax], 0
        je strlen_loop_after
        inc rax
        jmp strlen_loop
    strlen_loop_after:
    ret

strcmp:
    ;; rdi = str1
    ;; rsi = str2
    ; rax = isequal
    xor rcx, rcx
    strcmp_loop:
        movzx r8, byte [rdi+rcx]
        movzx r9, byte [rsi+rcx]
        test r8, r8 
        je strcmp_loop_after
        test r9, r9
        je strcmp_loop_after

        cmp r8, r9
        jne strcmp_loop_after
        inc rcx
        jmp strcmp_loop

    strcmp_loop_after:
    mov rax, r8
    sub rax, r9
    ret

atoi:
    ;; rdi = const char *in
    ;; rax = retval
    ; rcx = counter
    xor rax, rax
    xor rcx, rcx
    atoi_loop:
        movzx r8, byte [rdi+rcx]
        inc rcx
        ; if(!r8) break;
        test r8, r8
        je atoi_loop_after

        ; if(r8>9 || r8<0) goto invalid;
        cmp r8, '9'
        jg atoi_loop_invalid
        cmp r8, '0'
        jb atoi_loop_invalid

        ; r8 -= '0'
        sub r8, '0' ; 0-9

        ; rax = (rax*10) + r8
        imul rax, 10
        add rax, r8

        jmp atoi_loop

    atoi_loop_after:
    ret

    ; handle error
    atoi_loop_invalid:
    ; rdi = rdi
    call strlen
    mov r8, rdi
    mov r9, rax
    syscall3 SYS_write, 2, r8, r9
    syscall3 SYS_write, 2, msg_atoi_invalid_input, msg_atoi_invalid_input_len
    syscall1 SYS_exit, 1

strncpy:
    ;; rax: char*
    ;; rdi: int dsize 
    ;; rsi: char* dest
    ;; rdx: const char* src
    
    ; because while (i < dsize)
    sub rdi, 1

    ; rcx: int i
    xor rcx, rcx
    strncpy_loop: 
        ; if (i >= dsize) break;
        cmp rcx, rdi
        jge strncpy_loop_after

        ; if (src[i] != 0x0) goto _copy_byte
        cmp byte [rdx+rcx], 0
        jne strncpy_loop_copy_byte
        
        strncpy_loop_copy_null:
        mov byte [rsi+rcx], 0
        jmp strncpy_loop_end

        strncpy_loop_copy_byte:
        mov r8b, byte [rdx+rcx]
        mov byte [rsi+rcx], r8b
        
        strncpy_loop_end:
        ; i++
        inc rcx
        jmp strncpy_loop

    strncpy_loop_after:
    mov rax, rsi
    ret
