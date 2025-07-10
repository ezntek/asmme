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

section .text
global main

parseargs:
    ;; rdi: int argc
    ;; rsi: const char* argv
    
    push rdi
    push rsi

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
    ; argv[0] is already in r8, copy *r8 into file_buf
    lea rsi, [rel file_buf]
    call3 strncpy, PATH_MAX, rsi, r8
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
    pop rsi
    pop rdi
    ret

main:
    ;; rdi: int argc
    ;; rsi: char** argv

    call parseargs

    ; print banner
    syscall3 SYS_write, stdout, msg_welcome, msg_welcome_len
    
    ; print the file buf
    call1 strlen, file_buf
    mov r8, rax
    lea rsi, [rel file_buf]
    syscall3 SYS_write, stdout, rsi, r8

    xor rax, rax
    ret

section .bss
    ; buffer for file name
    file_buf resb PATH_MAX ; file path shouldnt be more.

section .data
    ; messages
    msg_welcome db "Welcome to AsmMe.", 0xA, 0x0
    msg_welcome_len equ $ - msg_welcome
    msg_help_string db "Usage: asmme [--help] <file>", 0x0A, 0x0
    msg_help_string_len equ $ - msg_help_string
    msg_atoi_invalid_input db ": Invalid number", 0x0A, 0x0
    msg_atoi_invalid_input_len equ $ - msg_atoi_invalid_input
    msg_file_name_too_long db "File name is too long.", 0xA, 0x0
    msg_file_name_too_long_len equ $ - msg_file_name_too_long
    msg_parseargs_error db "Not enough args", 0xA, 0x0
    msg_parseargs_error_len equ $ - msg_parseargs_error
