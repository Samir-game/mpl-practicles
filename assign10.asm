; far.asm

%include "macro.asm"    ; Include the macro for printing

section .data
    msg_space db "Number of spaces: ", 0        ; Message for space count
    msg_space_len equ $-msg_space                ; Length of the message
    msg_line db "Number of lines: ", 0          ; Message for line count
    msg_line_len equ $-msg_line                  ; Length of the message
    msg_char db "Number of occurrences of character: ", 0  ; Message for character count
    msg_char_len equ $-msg_char                  ; Length of the message
    dispbuff db 0, 0                            ; Buffer for displaying results (2 characters for the number)
    nl db 10                                    ; Newline character

section .bss
    scount resb 1   ; Reserve 1 byte for space count
    ncount resb 1   ; Reserve 1 byte for line count
    ccount resb 1   ; Reserve 1 byte for character count

section .text
    global far_procedure    ; Declare far_procedure as global so it can be called from other files
    extern buffer, buf_len, character  ; Declare external variables (buffer, buf_len, and character)

far_procedure:
    ; Clear registers to prepare for counting
    xor rcx, rcx          ; Clear rcx register (loop counter)
    xor rbx, rbx          ; Clear rbx register (character count for target character)
    xor rdx, rdx          ; Clear rdx register (not used, but cleaned up)

    ; Load buffer address into rsi and buffer length into rcx
    mov rsi, buffer       ; Load address of buffer into rsi
    mov rcx, [buf_len]    ; Load buffer length into rcx (loop counter)
    mov bl, byte [character]  ; Load target character (to search for) into bl

.count_loop:
    cmp rcx, 0            ; Check if we've reached the end of the buffer
    je display_results    ; If buffer length is 0, jump to display results

    mov al, [rsi]         ; Load the current byte from buffer into al
    cmp al, 0x20          ; Compare the byte with ASCII value of space (0x20)
    jne .check_line       ; If not space, jump to check for newline character

    ; Increment space count
    inc byte [scount]     ; Increment the space count in scount

.check_line:
    cmp al, 0x0A          ; Compare the byte with ASCII value of newline (0x0A)
    jne .check_char       ; If not newline, jump to check for target character

    ; Increment line count
    inc byte [ncount]     ; Increment the line count in ncount

.check_char:
    cmp al, bl            ; Compare the byte with the target character (stored in bl)
    jne .next             ; If it's not the target character, jump to the next byte

    ; Increment character count
    inc byte [ccount]     ; Increment the character count in ccount

.next:
    inc rsi               ; Move to the next byte in the buffer
    dec rcx               ; Decrement the loop counter
    jmp .count_loop       ; Repeat the loop

display_results:
    ; Display space count
    Print msg_space, msg_space_len  ; Print the "Number of spaces: " message
    mov bl, [scount]      ; Load the space count into bl
    call display8num      ; Call display8num to print the space count

    ; Display line count
    Print msg_line, msg_line_len    ; Print the "Number of lines: " message
    mov bl, [ncount]      ; Load the line count into bl
    call display8num      ; Call display8num to print the line count

    ; Display character count
    Print msg_char, msg_char_len    ; Print the "Number of occurrences of character: " message
    mov bl, [ccount]      ; Load the character count into bl
    call display8num      ; Call display8num to print the character count

    ret                   ; Return from far_procedure

; display8num procedure: Display an 8-bit number (stored in bl)
display8num:
    mov rsi, dispbuff     ; Load the address of the display buffer into rsi
    mov rcx, 2            ; Set loop count to 2 (for two digits)

.next_digit:
    rol bl, 4             ; Rotate left the contents of bl (shifting the nibble to the left)
    mov al, bl            ; Move the most significant nibble into al
    and al, 0x0F          ; Mask the upper 4 bits (keep only the lower 4 bits)
    cmp al, 9             ; Compare the nibble with 9
    jbe .add30            ; If the nibble is <= 9, jump to add ASCII '0'

    add al, 0x37          ; If the nibble is > 9, add 0x37 to get ASCII 'A' to 'F'

.add30:
    add al, 0x30          ; Add 0x30 to convert the nibble to its ASCII value ('0'-'9' or 'A'-'F')
    mov [rsi], al         ; Store the ASCII character in the buffer
    inc rsi               ; Move to the next position in the buffer
    loop .next_digit      ; Repeat for the next digit

    Print dispbuff, 2      ; Print the two ASCII characters (the number)
    Print nl, 1            ; Print a newline
    ret                   ; Return from display8num
