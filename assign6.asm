; Program for non-overlapped block transfer
; Name: Samir Game
; Roll No: 7263
; Date: 24 March, 2025

; --------------------- MACROS ---------------------
%macro io 4
    mov rax, %1        ; System call number (0 for read, 1 for write)
    mov rdi, %2        ; File descriptor (0 for stdin, 1 for stdout)
    mov rsi, %3        ; Pointer to buffer
    mov rdx, %4        ; Number of bytes to read/write
    syscall            ; Perform system call
%endmacro

%macro exit 0
    mov rax, 60        ; System call number for exit (60)
    mov rdi, 0         ; Exit code 0 (success)
    syscall            ; Perform exit syscall
%endmacro

; --------------------- DATA SECTION ---------------------
section .data
    ; Source 64-bit values (5 QWORDS)
    source dq 0x123456789ABCDEF0, \
           0x0FEDCBA987654321, \
           0xA1B2C3D4E5F60718, \
           0xFFFFFFFF00000000, \
           0x7F8E9DA1BC2D3E4F

    ; Destination buffer (initially empty)
    dest dq 0, 0, 0, 0, 0

    len db 5                            ; Length = 5 QWORDs

    ; Message strings
    msg1 db "Source: ", 10              ; "Source: \n"
    msg1len equ $ - msg1

    msg2 db "Destination: ", 10         ; "Destination: \n"
    msg2len equ $ - msg2

    menu db "0. Exit",10,"1. Non-overlapped block transfer w/o string instructions",10,\
              "2. Non-overlapped block transfer with string instructions",10
    menulen equ $ - menu

    newline db 10                       ; Newline character
    arrow db "  --->   "               ; Arrow between addresses and values
    arrowlen equ $ - arrow

; --------------------- BSS SECTION ---------------------
section .bss
    ascii64 resb 16         ; Buffer for 64-bit hex value as ASCII
    choice  resb 2          ; User input for menu selection

; --------------------- TEXT SECTION ---------------------
section .text
    global _start
_start:
    ; Print menu
    io 1, 1, menu, menulen

    ; Get user choice
    io 0, 0, choice, 2

    ; Check option
    cmp byte [choice], '1'
    je opt1

    cmp byte [choice], '2'
    je opt2

    exit                    ; Default: exit program if invalid input

; --------------------- OPTION 1: MANUAL COPY ---------------------
opt1:
    call print_src          ; Print source memory
    mov rsi, source         ; rsi points to source
    mov rdi, dest           ; rdi points to destination
    mov rcx, 5              ; Copy 5 QWORDS

lp1:
    mov rbx, [rsi]          ; Load value from source
    mov [rdi], rbx          ; Store into destination
    add rsi, 8              ; Move to next QWORD (8 bytes)
    add rdi, 8
    loop lp1                ; Repeat rcx times

    call print_dest         ; Print destination memory
    exit                    ; Exit program

; --------------------- OPTION 2: USING STRING INSTRUCTIONS ---------------------
opt2:
    call print_src          ; Print source memory
    mov rsi, source         ; rsi = source
    mov rdi, dest           ; rdi = destination
    mov rcx, 5              ; Number of QWORDS to move
    rep movsq               ; Repeat move QWORD (uses rsi and rdi)
    call print_dest         ; Print destination
    exit                    ; Exit program

; --------------------- PRINT SOURCE ---------------------
print_src:
    io 1, 1, msg1, msg1len  ; Print "Source:\n"
    mov rsi, source         ; rsi = source base
    mov rcx, 5              ; 5 elements
next:
    mov rbx, rsi            ; Copy address
    push rcx
    push rsi
    call hex_ascii64        ; Convert address to ASCII hex
    io 1, 1, arrow, arrowlen ; Print "  --->   "
    pop rsi
    mov rbx, [rsi]          ; Load value at address
    push rsi
    call hex_ascii64        ; Convert value to ASCII hex
    io 1, 1, newline, 1     ; Print newline
    pop rsi
    pop rcx
    add rsi, 8              ; Move to next QWORD
    loop next
    ret

; --------------------- PRINT DESTINATION ---------------------
print_dest:
    io 1, 1, msg2, msg2len  ; Print "Destination:\n"
    mov rdi, dest           ; rdi = dest base
    mov rcx, 5              ; 5 elements
next2:
    mov rbx, rdi            ; Copy address
    push rcx
    push rdi
    call hex_ascii64        ; Convert address to ASCII hex
    io 1, 1, arrow, arrowlen ; Print "  --->   "
    pop rdi
    mov rbx, [rdi]          ; Load value at address
    push rdi
    call hex_ascii64        ; Convert value to ASCII hex
    io 1, 1, newline, 1     ; Print newline
    pop rdi
    pop rcx
    add rdi, 8              ; Move to next QWORD
    loop next2
    ret

; --------------------- CONVERT 64-BIT VALUE IN RBX TO ASCII HEX ---------------------
hex_ascii64:
    mov rdi, ascii64        ; Destination buffer
    mov rax, rbx            ; Value to convert
    mov rcx, 16             ; 16 hex digits for 64-bit
hxloop:
    rol rax, 4              ; Rotate left 4 bits (get high nibble)
    mov dl, al              ; Get low 8 bits
    and dl, 0Fh             ; Isolate lower 4 bits
    cmp dl, 9
    jbe digit
    add dl, 7               ; Convert to A-F if > 9
digit:
    add dl, '0'             ; Convert to ASCII
    mov [rdi], dl           ; Store in buffer
    inc rdi
    loop hxloop
    io 1, 1, ascii64, 16    ; Print 16 ASCII hex digits
    ret
