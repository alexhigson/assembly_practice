; Program to add two integers and display the result
; We need to:
; 1. Add the numbers
; 2. Convert the numeric result to text (since we can only display text)
; 3. Display the text

; Registers used:
; eax - Used for division/arithmetic
; ebx - Used for system call parameters
; ecx - Used for counting/pointing
; edx - Used with division and length
; edi - Destination pointer
; esi - Source pointer

section .data
    x dd 13      ; First number stored as a 32-bit integer
    y dd 21      ; Second number stored as a 32-bit integer
    msg db "The result is "   ; Message for user-friendly output
    msg_len equ $ - msg       ; Message length needed as OS needs to know how many characters to print
    newline db 10             ; Newline character to format output on terminal
    ten dd 10                 ; 10 for division because we'll convert number to decimal digits

section .bss
    ; Need a buffer because we can't directly print a number - must be converted to ASCII text
    ; 12 bytes because a 32-bit number can have up to 10 digits, plus newline and null terminator
    buffer resb 12    

section .text    
    global _start    ; For OS to know where to start executing

_start:    
    ; Add the numbers
    ; - We use eax because it's required for division in x86 - the dividend must be in eax
    mov eax, [x]          ; Load first number into eax to hold running total
    add eax, [y]          ; Add second number to eax

    ; Convert number to printable string (because the OS can only print text characters, not raw numbers)
    ; - Using edi is appropriate as it's often used as a pointer to where we want to write data (d=destination)
    ; - Using ecx because it's commonly used as a counter
    
    mov edi, buffer       ; Point to start of buffer where string will be built
    mov byte [buffer+11], 0  ; Null terminator included as common string convention
    mov byte [buffer+10], 10 ; Newline for output formatting
    mov ecx, 9            ; Start at position 9 (right-aligned) since we don't know number length yet

.convert_loop:    
    ; Convert the number to string by dividing each digit by 10 and using remainders
    ; - After division, eax holds quotient and edx holds remainder (requirement in x86)
    ; - This gives us digits from right to left
    mov edx, 0           ; Clear edx because div instruction uses edx:eax as dividend
    div dword [ten]      ; Divide number by 10: quotient in eax (for next iteration), remainder in edx (current digit)
    add dl, '0'          ; Convert digit to ASCII by adding ASCII code for '0' (48)
    mov [buffer+ecx], dl ; Store this digit (lowest 8 bits of edx, as ASCII chars are 8 bits) in buffer at correct index
    dec ecx              ; Move left in buffer for next digit by reducing ecx by 1
    test eax, eax        ; Check if we have more digits to convert
    jnz .convert_loop    ; If quotient not zero, continue converting

    ; Prepare to print result
    ; Calculate where the actual number starts in our buffer (skipping unused positions)
    ; - esi is the source index, used for source data (what we're reading from)
    lea esi, [buffer+ecx+1]  ; Point to first actual digit (after unused buffer space)
    mov ecx, buffer+10       ; Point to end of number (before newline)
    sub ecx, esi            ; Calculate length of just the digits
    inc ecx                 ; Include newline in length

    ; Print the message
    mov eax, 4          ; We want to write (eax=4)
    mov ebx, 1          ; We want to write to stdout (ebx=1)
    mov ecx, msg        ; We want to write the message (ecx)
    mov edx, msg_len    ; We need to write the number of bytes in edx
    int 0x80           

    ; Print the actual number
    mov eax, 4          
    mov ebx, 1          
    mov ecx, esi        ; Point to start of actual number (skipping unused buffer)
    push ecx            ; Save this pointer (good practice for system calls)
    mov edx, buffer+10  ; Point to end of number (at newline)
    sub edx, ecx        ; Calculate exact length of digits so system knows how many to print and doesn't print unused buffer space
    inc edx             ; Include newline in what we print
    int 0x80           

    ; Exit program
    ; We need to explicitly exit otherwise program would continue in memory
    mov eax, 1          ; sys_exit system call
    xor ebx, ebx        ; Return 0 to indicate successful execution (every bit XORed with itself becomes 0)
    int 0x80