; macro.asm - Macros for Linux syscalls

%macro Print 2
    mov rax, 1          ; syscall: write (1 is the sys_write syscall number)
    mov rdi, 1          ; stdout (1 is the file descriptor for stdout)
    mov rsi, %1         ; buffer (pointer to the buffer to write)
    mov rdx, %2         ; length (length of data to write)
    syscall
%endmacro

%macro Accept 2
    mov rax, 0          ; syscall: read (0 is the sys_read syscall number)
    mov rdi, 0          ; stdin (0 is the file descriptor for stdin)
    mov rsi, %1         ; buffer (pointer to where input will be stored)
    mov rdx, %2         ; size (number of bytes to read)
    syscall
%endmacro

%macro fopen 1
    mov rax, 2          ; syscall: open (2 is the sys_open syscall number)
    mov rdi, %1         ; filename pointer (pointer to the file name)
    mov rsi, 0          ; read-only (0 is for open with read-only mode)
    syscall
%endmacro

%macro fread 3
    mov rax, 0          ; syscall: read (0 is the sys_read syscall number)
    mov rdi, %1         ; file descriptor (file to read from)
    mov rsi, %2         ; buffer (pointer to buffer to store data)
    mov rdx, %3         ; size (number of bytes to read)
    syscall
%endmacro

%macro fwrite 3
    mov rax, 1          ; syscall: write (1 is the sys_write syscall number)
    mov rdi, %1         ; file descriptor (file to write to)
    mov rsi, %2         ; buffer (pointer to the data to write)
    mov rdx, %3         ; size (number of bytes to write)
    syscall
%endmacro

%macro fclose 1
    mov rax, 3          ; syscall: close (3 is the sys_close syscall number)
    mov rdi, %1         ; file descriptor (file to close)
    syscall
%endmacro

%macro fcreate 1
    mov rax, 2              ; syscall: open (2 is the sys_open syscall number)
    mov rdi, %1             ; filename (pointer to file name)
    mov rsi, 42h           ; O_WRONLY | O_CREAT | O_TRUNC (577 octal = 0x241 hex)
    mov rdx, 7777h         ; permissions (0777 octal = 0x1FF hex, full permissions)
    syscall
%endmacro

%macro fdelete 1
    mov rax, 87             ; syscall: unlink (87 is the sys_unlink syscall number)
    mov rdi, %1             ; filename (pointer to file name)
    syscall
%endmacro

; ass9.asm - Menu-driven TYPE, COPY, DELETE
; Name: Samir Game
; Roll No: 7263
; Date: 7/04/2025

%include "macro.asm"  ; Include the macro file that defines all the system call macros

section .data
    intro_msg db 10,"Write X86/64 ALP to implement TYPE, COPY, DELETE \
    using file operations", 10, \
    
    intro_len equ $-intro_msg  ; Calculate the length of the intro message

    ; Menu display message
    msg db "------------------MENU------------------", 10 
        db "1. TYPE ", 10 
        db "2. COPY ", 10 
        db "3. DELETE ", 10 
        db "4. Exit ", 10
        db "Enter your choice : "

    msglen equ $-msg  ; Calculate the length of the menu message

    endl db 10        ; New line character for formatting
    m db "DONE!", 10  ; "DONE!" message after an operation is complete

section .bss
    choice resb 2      ; Reserve 2 bytes for user input choice
    fname1 resb 50     ; Reserve 50 bytes for first file name
    fname2 resb 50     ; Reserve 50 bytes for second file name
    filehandle1 resq 1 ; Reserve space for first file descriptor (64-bit)
    filehandle2 resq 1 ; Reserve space for second file descriptor (64-bit)
    buffer resb 100    ; Reserve space for 100-byte buffer
    bufferlen resq 1   ; Reserve space for buffer length (64-bit)

section .text
global _start
_start:
    ; Command-line arguments handling
    pop rbx             ; Pop the first argument (argc)
    pop rsi             ; Pop the program name (we don't use it, so skip it)

    ; Show intro message
    Print intro_msg, intro_len

    ; Read the first file name into fname1
    mov rdi, fname1
.mark:
    pop rsi             ; Pop the next argument (characters of the file name)
    mov rdx, 0          ; Reset the character counter
.next:
    mov al, byte [rsi + rdx]  ; Get the next character from the input
    mov [rdi + rdx], al       ; Store the character into fname1
    cmp al, 0            ; Check if we've reached the null terminator
    je .next1
    inc rdx              ; Increment the character counter
    jmp .next

.next1:
    cmp rdi, fname2      ; Check if the first file name is fully stored
    je main_menu         ; If true, go to the menu
    mov rdi, fname2      ; Otherwise, move to the second file name
    jmp .mark            ; Continue reading the next file name

main_menu:
    Print msg, msglen    ; Print the menu
    Accept choice, 2     ; Accept the user's menu choice

    ; Check user choice and jump to the corresponding case
    cmp byte [choice], '1'
    je case1
    cmp byte [choice], '2'
    je case2
    cmp byte [choice], '3'
    je case3
    cmp byte [choice], '4'
    je case4
    jmp main_menu        ; If invalid choice, loop back to the menu

case1:
    call type            ; Call TYPE function
    jmp main_menu        ; Go back to the menu after operation

case2:
    call copy            ; Call COPY function
    jmp main_menu        ; Go back to the menu after operation

case3:
    call delete          ; Call DELETE function
    jmp main_menu        ; Go back to the menu after operation

case4:
    mov rax, 60          ; syscall: exit (60 is the sys_exit syscall number)
    xor rdi, rdi         ; Exit code 0
    syscall              ; Exit the program

; TYPE implementation - Display the contents of the file
type:
    fopen fname1         ; Open the file in read-only mode
    cmp rax, -1          ; Check if the file was opened successfully
    je case4             ; If not, exit the program
    mov [filehandle1], rax  ; Store the file descriptor

    fread [filehandle1], buffer, 100  ; Read the file content into buffer
    mov [bufferlen], rax  ; Store the length of the data read
    Print endl, 1         ; Print a new line
    Print buffer, [bufferlen]  ; Print the contents of the buffer
    fclose [filehandle1]  ; Close the file
    ret

; COPY implementation - Copy the contents from one file to another
copy:
    fopen fname1         ; Open the source file in read-only mode
    cmp rax, -1          ; Check if the source file was opened successfully
    je case4             ; If not, exit the program
    mov [filehandle1], rax  ; Store the file descriptor

    fcreate fname2       ; Create the destination file
    cmp rax, -1          ; Check if the destination file was created successfully
    je case4             ; If not, exit the program
    mov [filehandle2], rax  ; Store the file descriptor of the destination

.copy_loop:
    fread [filehandle1], buffer, 100  ; Read data from source file
    cmp rax, 0              ; Check if EOF is reached
    je .copy_done
    mov rdi, [filehandle2]  ; Move the file descriptor of the destination file
    mov rsi, buffer         ; Set the buffer pointer
    mov rdx, rax            ; Set the number of bytes to write
    mov rax, 1              ; sys_write
    syscall
    jmp .copy_loop

.copy_done:
    fclose [filehandle1]    ; Close the source file
    fclose [filehandle2]    ; Close the destination file
    Print m, 6              ; Print "DONE!"
    ret

; DELETE implementation - Delete the specified file
delete:
    fdelete fname2          ; Delete the file specified by fname2
    Print m, 6              ; Print "DONE!"
    ret
