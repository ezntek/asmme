; AsmMe: an askme clone in x86_64 assembly.
;
; Copyright (c) ezntek, 2025.
; 
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.

%include "common.inc"

; strlen, strcmp, atoi
%include "util.s"

%define MAX_FILE_SIZE 32768

section .text
global main

parseargs:
    ;; rdi: int argc
    ;; rsi: const char* argv 
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; argc--, argv++
    dec rdi
    add rsi, 8

    ; if(!argc)
    test rdi, rdi
    jz parseargs_error

    ; ===== arg parsing =====
    ; argv[0][0] == '-'
    mov r8, qword [rsi]
    cmp byte [r8], '-'
    je parseargs_flag_help
    ; =======================

    ;; required args go here
    ; argv[0] is already in r8, copy *r8 into path_buf
    lea rsi, [rel path_buf]
    call3 strncpy, PATH_MAX, rsi, r8
    ; rsi is unchanged
    call1 strlen, rsi
    mov dword [path_buf_len], eax
    jmp parseargs_end

    ; ===== arg parsing branches =====
    ; unknown flag
    parseargs_flag_help:
    syscall3 SYS_write, stderr, msg_help_string, msg_help_string_len
    syscall1 SYS_exit, 1
    ; ================================

    parseargs_error:
    syscall3 SYS_write, stderr, msg_parseargs_error, msg_parseargs_error_len
    jmp parseargs_flag_help

    parseargs_end:
    add rsp, 8
    mov rsp, rbp
    pop rbp
    xor rax, rax
    ret

main:
    ;; rdi: int argc
    ;; rsi: char** argv
    push rbp
    mov rbp, rsp
    call parseargs

    ; print banner
    syscall3 SYS_write, stdout, msg_welcome, msg_welcome_len
   
    ; realistically, the user sholdnt provide 1024 chars in a path.
    ; however, we allocate 1024+64 (1088) bytes just in case.
    sub rsp, 1088 ; [rbp - 8]
    mov rsi, rsp ; rsp is the buffer  
    lea rdx, [rel msg_info_open_file]
    call3 strncpy, 1088, rsi, rdx
    ; we are copying a path this time
    add rsi, msg_info_open_file_len ; skip forward that many bytes
    dec rsi ; we dont want the null terminator
    lea rdx, [rel path_buf]
    call3 strncpy, PATH_MAX, rsi, rdx
    mov r8d, dword [path_buf_len] ; skip forward strlen(path) bytes 
    add rsi, r8
    mov byte [rsi], 0x22 ; " mark
    mov byte [rsi+1], 0x0 ; null terminate just in case
    call1 log_info, rsp
    add rsp, 1088

    ; open the file
    mov rsi, O_RDONLY
    syscall3 SYS_open, path_buf, rsi, DEFAULT_OPENMODE
    cmp rax, -1
    je main_open_file_fail
    mov dword [path_fd], eax

    ; get the length
    ; lseek(fd, 0, SEEK_END);
    mov r8d, eax
    syscall3 SYS_lseek, r8, 0, SEEK_END
    ; lseek(fd, 0, SEEK_SET);
    mov r9, rax ; file length is in r9
    mov qword [file_len], r9
    syscall3 SYS_lseek, r8, 0, SEEK_SET

    ; mmap the file (?!?!?!?) 
    ;   address = mmap(0, len, PROT_READ, MAP_PRIVATE, fildes, some_offset)
    ;
    ;  void *mmap(void *addr, size_t len, int prot, int flags,
    ;       int fildes, off_t off);
    
    mov rax, SYS_mmap
    mov rdi, 0
    mov rsi, qword [file_len]
    mov rdx, PROT_READ
    mov r10, MAP_PRIVATE
    mov r8d, dword [path_fd]
    mov r9, 0
    syscall
    mov qword [file_ptr], rax
    ; result is in rax

    mov rsi, qword [file_ptr]
    mov rdx, qword [file_len]
    syscall3 SYS_write, stdout, rsi, rdx

    main_end:
    ; close the file
    mov r8d, dword [path_fd]
    syscall1 SYS_close, r8
    mov rsp, rbp
    pop rbp
    xor rax, rax
    ret

    main_open_file_fail:
    call1 log_error, msg_open_file_fail
    syscall1 SYS_exit, EXIT_FAILURE

section .bss
    ; buffer for file name
    path_buf resb PATH_MAX
    path_buf_len resd 1
    path_fd resd 1
    file_ptr resq 1 ; from mmap
    file_len resq 1

section .data
    ; messages
    msg_info_open_file db "opening file ", 0x22, 0x0
    msg_info_open_file_len equ $ - msg_info_open_file

    msg_open_file_fail db "failed to open file", 0x0
    msg_open_file_fail_len equ $ - msg_open_file_fail

    msg_welcome db 0x1B, "[2m=================", 0x1B, "[0m", 0xA, "Welcome to AsmMe.", 0xA, 0x1B, "[2m=================", 0x1B, "[0m", 0xA, 0x0
    msg_welcome_len equ $ - msg_welcome
    msg_help_string db "Usage: asmme [--help] <file>", 0x0A, 0x0
    msg_help_string_len equ $ - msg_help_string
    msg_atoi_invalid_input db ": Invalid number", 0x0A, 0x0
    msg_atoi_invalid_input_len equ $ - msg_atoi_invalid_input
    msg_file_name_too_long db "File name is too long.", 0xA, 0x0
    msg_file_name_too_long_len equ $ - msg_file_name_too_long
    msg_parseargs_error db "Not enough args", 0xA, 0x0
    msg_parseargs_error_len equ $ - msg_parseargs_error
