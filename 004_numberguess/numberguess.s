.global _main

.data
welcome:
    .asciz "Guess a number between 1 and 100!\n"
prompt:
    .asciz "-> Your guess: "
youwin:
    .asciz "You won the game!\n"
toosmall:
    .asciz "Too small!\n"
toolarge:
    .asciz "Too large!\n"

.text
_main:
    stp x29, x30, [sp, -16]!
    sub sp, sp, 16

    ; We allocated the stack to contain: the 4 bytes for the target, the 4 bytes for the moves count.
    ; Let's zero-initialize it, we also pad 8 bytes to make sure sp is aligned 16-bytes.
    str xzr, [sp]
    str xzr, [sp, 8]

    ; Now we can get the random number
    mov x0, 1
    mov x1, 101
    bl _randint
    str w0, [sp]                ; store our target number on the stack
    str wzr, [sp, 4]            ; store our moves count on the stack also

    adrp x0, welcome@PAGE       ; sends a welcome message
    bl _strprint

_main_loop:                     ; here, we can start the game
    adrp x0, prompt@PAGE        ; for each loop, we print out the prompt
    add x0, x0, prompt@PAGEOFF
    bl _strprint
    bl _numread

    ; x0 now contains our number from the user, we can now try to check that against the target
    ldr w1, [sp, 4]             ; add 1 to the moves count and put it back on the stack
    add w1, w1, 1
    str w1, [sp, 4]

    ldr w1, [sp]                ; loads up the target number

    ; compare and branch necessarily
    cmp x0, x1
    b.lt _main_loop_too_low
    b.gt _main_loop_too_high
    b _main_loop_end

_main_loop_too_low:
    ; print the too low message!
    adrp x0, toosmall@PAGE
    add x0, x0, toosmall@PAGEOFF
    bl _strprint
    b _main_loop

_main_loop_too_high:
    ; print the too high message!
    adrp x0, toolarge@PAGE
    add x0, x0, toolarge@PAGEOFF
    bl _strprint
    b _main_loop

_main_loop_end:
    ; we won the game! let's print that message out here
    adrp x0, youwin@PAGE
    add x0, x0, youwin@PAGEOFF
    bl _strprint

    ldr w0, [sp, 4]             ; load the move count into x0
    add sp, sp, 16
    ldp x29, x30, [sp], 16

    ret

; Counts the number of bytes in a string.
;
; Parameters:
; - x0: the address to the string
;
; Returns:
; - x0: the length of the string
_strlen:
    mov x9, x0
    mov w0, 0
_strlen_loop:
    ldrb w10, [x9, w0, uxtw]
    add w0, w0, 1
    cbnz w10, _strlen_loop
    sub w0, w0, 1
    ret

; Prints out a string.
;
; Parameters:
; - x0: the address to the string
;
; Returns:
; - x0: the error code of write syscall
_strprint:
    stp x29, x30, [sp, -16]!
    mov x1, x0
    bl _strlen

    ; Now x0 = length, x1 = address of string.
    ; We try to call syscall 4 for write
    ; write(fd, buffer, length)
    mov x16, 4
    mov x2, x0
    mov x0, 1                       ; fd for stdout = 1
    svc 0x80

    ldp x29, x30, [sp], 16
    ret

.data
devrandom:
    .asciz "/dev/random"
.text

; Retrieves a random number between between two values.
; This uses the entropy available in /dev/random.
;
; If you're on Linux, you have syscall 384 for getrandom, but MacOS
; doesn't have that because of course it doesn't.
;
; Parameters:
; - x0: first number of the range
; - x1: second number of the range
;
; Returns:
; - x0: the number in that range
_randint:
    mov x9, x0
    mov x10, x1

    ; do a syscall 5 for open(path, flags, mode)
    ; after this, x0 contains the file descriptor
    mov x16, 5
    adrp x0, devrandom@PAGE
    add x0, x0, devrandom@PAGEOFF
    mov x1, 0
    mov x2, 0444
    svc 0x80

    ; now we read in 4 bytes from /dev/random using another syscall
    ; that is syscall #3 called read(fd, buf, len)
    ; now we need to pull out somewhere to actually read, let's put it on the stack
    ; again anything needs 16-byte alignments even though we only need 4 bytes to read an integer
    mov x8, x0          ; save the file descriptor
    mov x16, 3
    sub sp, sp, 16      ; allocate 16 bytes on the stack
    mov x1, sp
    mov x2, 4
    svc 0x80

    ; we have read 4 bytes, now we can close the file descriptor
    ; which is syscall #6 for close(fd)
    mov x0, x8
    mov x16, 6
    svc 0x80

    ; let's handle the number we read in by taking num % x1, load in a 32-bit number
    ; to do a % operation we need to divide first and subtract from the main dividend
    ; we put w8 = dividend, w9 = divisor, w10 = quotient, w11 = remainder
    ldr w8, [sp]
    sub x9, x9, x10
    cmp x9, 0           ; compare divisor to 0
    cneg x9, x9, lt     ; flip the sign of the divisor if it is < 0
    udiv x10, x8, x9
    msub x11, x10, x9, x8
    add x11, x11, x0

    add sp, sp, 16      ; collapse

    ; move the remainder into the return value
    add x11, x0, x11
    mov x0, x11
    mov x0, x11
    ret

; Reads in an integer based on what the user has input.
;
; Parameters: None
;
; Returns:
; - x0: the number that has been parsed
_numread:
    sub sp, sp, 16          ; allocate 16 bytes for the buffer
    str xzr, [sp]           ; zero it out
    str xzr, [sp, 8]

    mov x16, 3              ; another syscall for read(fd, buf, len)
    mov x0, 0               ; stdin
    mov x1, sp
    mov x2, 16
    svc 0x80

    ; now we got our number in x0, we need to start parsing it, we only accept 0-9s
    ; for simplicity, no hexadecimal or whatever
    ; we put the length of the string in w9
    ; we put the iterator index in w10
    ; we put the actual byte to parse in x11
    ; we put the number parsed in x12
    mov w9, w0
    mov w10, 0
    mov x12, 0
    mov x13, 10                             ; the multiplier needed because mul instruction uses registers
_numread_parse_loop:
    ldrb w11, [sp, w10, uxtw]               ; load the next byte into w11
    cmp w11, '0'
    b.lt _numread_parse_continue
    cmp w11, '9'
    b.gt _numread_parse_continue
    sub w11, w11, '0'                       ; parse the number
                                            ; we add the number into our result with a = 10 * a + new
    mul x12, x12, x13                       ; result = result * 10 (x13 = 10)
    add x12, x12, x11                       ; result = result + new
_numread_parse_continue:
    add w10, w10, 1
    cmp w10, w9
    b.lt _numread_parse_loop                ; loop back if w10 < w9 (len of str)

    ; we can return here
    ; move the result, clear the stack and return
    mov x0, x12
    add sp, sp, 16
    ret
