; Name: Samir Game
; Roll No: 7263
; Date: 24 March, 2025

; ----------- Macros -----------
%macro io 4
    mov rax, %1         ; System call number (0=read, 1=write)
    mov rdi, %2         ; File descriptor (0=stdin, 1=stdout)
    mov rsi, %3         ; Address of buffer
    mov rdx, %4         ; Number of bytes to read/write
    syscall             ; Perform the syscall
%endmacro

%macro exit 0
    mov rax, 60         ; Exit syscall number
    mov rdi, 0          ; Exit code 0 (success)
    syscall             ; Exit program
%endmacro

; ----------- Data Section -----------
section .data
    source dq 0x123456789ABCDEF0, \                  ; Source block of 64-bit integers
           0x0FEDCBA987654321, \
           0xA1B2C3D4E5F60718, \
           0xFFFFFFFF00000000, \
           0x7F8E9DA1BC2D3E4F

    msg1 db "Source: ",10                            ; Message to display source data
    msg1len equ $-msg1                               ; Length of msg1

    msg2 db "Destination: ",10                       ; Message to display destination data
    msg2len equ $-msg2                               ; Length of msg2

    menu db "0. Exit",10,                            ; Menu options
         "1. Overlapped block transfer w/o string instructions",10,
         "2. Overlapped block transfer with string instructions",10
    menulen equ $-menu                               ; Length of menu

    newline db 10                                    ; Newline character
    arrow db "  --->   "                             ; Arrow between address and value
    arrowlen equ $-arrow                             ; Length of arrow

; ----------- BSS Section (Uninitialized Data) -----------
section .bss
    ascii64 resb 16                                   ; Buffer to hold 64-bit number in hex
    choice resb 2                                     ; Buffer to store user choice input

; ----------- Text Section -----------
section .text
    global _start

_start:
    io 1,1,menu,menulen                               ; Display the menu
    io 0,0,choice,2                                   ; Get user input

    cmp byte [choice], '1'                            ; If input is '1'
    je opt1                                           ; Jump to Option 1

    cmp byte [choice], '2'                            ; If input is '2'
    je opt2                                           ; Jump to Option 2

    exit                                              ; Otherwise, exit program

; ---------- Option 1: Manual Overlapped Transfer ----------
opt1:
    call print_src                                    ; Display source block before copy
    io 1,1,msg2,msg2len                               ; Print "Destination:"

    mov rsi, source                                   ; Start of source block
    add rsi, 32                                       ; Move to 5th element (last)
    mov rdi, source                                   ; Destination start
    add rdi, 56                                       ; Move to location after source

    mov rcx, 5                                        ; Set loop counter to 5
lp1:
    mov rbx, [rsi]                                    ; Load 8 bytes from source
    mov [rdi], rbx                                    ; Store to destination
    sub rsi, 8                                        ; Move source backward
    sub rdi, 8                                        ; Move destination backward
    loop lp1                                          ; Repeat 5 times

    call print_dest                                   ; Print the destination content
    exit                                              ; Exit program

; ---------- Option 2: Overlapped Transfer with String Instruction ----------
opt2:
    call print_src                                    ; Display source block before copy
    io 1,1,msg2,msg2len                               ; Print "Destination:"

    std                                               ; Set direction flag (for backward copying)

    mov rsi, source                                   ; Source start
    add rsi, 32                                       ; Move to last element

    mov rdi, source                                   ; Destination start
    add rdi, 56                                       ; Move to end of destination area

    mov rcx, 5                                        ; Number of 64-bit values to move
    rep movsq                                         ; Move 5 qwords from [rsi] to [rdi]

    cld                                               ; Clear direction flag
    call print_dest                                   ; Display destination block
    exit                                              ; Exit program

; ---------- Print Source ----------
print_src:
    io 1,1,msg1,msg1len                               ; Print "Source:"

    mov rsi, source                                   ; Start of source
    mov rcx, 5                                        ; Number of elements

.next:
    mov rbx, rsi                                      ; Copy address to rbx
    push rcx                                          ; Save loop counter
    push rsi                                          ; Save rsi (pointer)

    call hex_ascii64                                  ; Print address in hex
    io 1,1,arrow,arrowlen                             ; Print arrow

    pop rsi                                           ; Restore rsi
    mov rbx, [rsi]                                    ; Load value at address
    push rsi                                          ; Save again
    call hex_ascii64                                  ; Print value in hex
    io 1,1,newline,1                                  ; Print newline

    pop rsi                                           ; Restore rsi
    pop rcx                                           ; Restore loop counter
    add rsi, 8                                        ; Move to next 64-bit value
    loop .next                                        ; Repeat 5 times
    ret

; ---------- Print Destination ----------
print_dest:
    mov rsi, source                                   ; Start of source
    add rsi, 56                                       ; Move to start of destination block
    mov rcx, 5                                        ; Number of elements

.next2:
    mov rbx, rsi                                      ; Copy address to rbx
    push rcx                                          ; Save loop counter
    push rsi                                          ; Save rsi

    call hex_ascii64                                  ; Print address in hex
    io 1,1,arrow,arrowlen                             ; Print arrow

    pop rsi                                           ; Restore rsi
    mov rbx, [rsi]                                    ; Load value
    push rsi                                          ; Save again
    call hex_ascii64                                  ; Print value
    io 1,1,newline,1                                  ; Print newline

    pop rsi                                           ; Restore rsi
    pop rcx                                           ; Restore loop counter
    add rsi, 8                                        ; Move to next
    loop .next2                                       ; Repeat 5 times
    ret

; ---------- Hex to ASCII 64-bit ----------
hex_ascii64:
    mov rdi, ascii64                                  ; Destination buffer
    mov rcx, 16                                       ; Loop 16 times (16 hex digits)

.hexloop:
    rol rbx, 4                                        ; Rotate left by 4 bits
    mov al, bl                                        ; Copy lowest 8 bits to al
    and al, 0Fh                                       ; Mask lower 4 bits

    cmp al, 9                                         ; Is it 0–9?
    jbe .digit
    add al, 55                                        ; Convert 10–15 to 'A'–'F'
    jmp .store

.digit:
    add al, '0'                                       ; Convert 0–9 to '0'–'9'

.store:
    mov [rdi], al                                     ; Store character
    inc rdi                                           ; Move to next byte
    loop .hexloop                                     ; Loop until rcx = 0

    io 1,1,ascii64,16                                 ; Print the final 16-character hex
    ret
