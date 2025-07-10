%ifndef _COMMON_INC
%define _COMMON_INC

%define stdin 0
%define stdout 1
%define stderr 2

%define EXIT_SUCCESS 0
%define EXIT_FAILURE 1

%define SYS_write 1
%define SYS_exit 60
%define PATH_MAX 1024
%define BUF_MAX 4096

%macro syscall1 2
    mov rax, %1
    mov rdi, %2
    syscall
%endmacro

%macro syscall2 3
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    syscall
%endmacro

%macro syscall3 4
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    syscall
%endmacro

%macro call1 2
    mov rdi, %2
    call %1
%endmacro

%macro call2 3
    mov rdi, %2
    mov rsi, %3
    call %1
%endmacro

%macro call3 4
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    call %1
%endmacro

%endif
