.global _main

.data
outname:
    .asciz "a.txt"
quit:
    .asciz "quit\n"

.text
_main:
    stp x29, x30, [sp, -16]!
    sub sp, sp, 1040                    ; Allocate for the file descriptor (4 bytes) + buffer (1024 bytes)
                                        ; but we need to align it by 16 bytes at all time, we pad in 12 bytes

    ; First, I want to setup open the file first.
    ; Open is syscall 5 with open(name, flag, mode)
    ; name will be outname, flag will be for writing, mode will be permission modes
    mov x16, 5
    adrp x0, outname@PAGE
    add x0, x0, outname@PAGEOFF
    mov x1, 0x201                       ; write & create flag
    mov x2, 0777                        ; mode 777 in octal converted to hexa is 1FF
    svc 0x80
    str w0, [sp]                        ; store the file descriptor to the stack (integer 4 bytes)

    ; Next, we start a loop that keeps zeroing, reading and printing until we hits quit
_main_write_loop:

    add x0, sp, 16                      ; Start zeroing out at sp[16]
    mov x1, 1024                        ; 1024 bytes to zero
    bl _zero

    ; Memory to read to is still sp[16]
    ; Length is still 1024
    ; After this, x0 is now the length we need to work with
    bl _strread

    ; We save the length somewhere, preferably the stack but we know the entire program won't use x3.
    ; Let's save it there
    mov x3, x0

    ; Now we compare the strings, move the addresses of the strings
    ; The result is stored in x0
    add x0, sp, 16
    adrp x1, quit@PAGE
    add x1, x1, quit@PAGEOFF
    bl _streql

    ; Shorthand for cmp x0, 0 and b.eq _main_write_loop_end.
    ; This is a call for "Compare and Branch on Zero"
    cbz x0, _main_write_loop_end

    ; We write to the file and loop back
    ldr w0, [sp]
    add x1, sp, 16
    mov x2, x3
    mov x16, 4
    svc 0x80

    b _main_write_loop
_main_write_loop_end:

    ; Finally, we want to close the file after
    ; Close is syscall 6 with close(fd)
    mov x16, 6
    ldr w0, [sp]
    svc 0x80

    add sp, sp, 1040
    ldp x29, x30, [sp], 16
    ret

; Zeroes out the values at the provided address.
;
; Parameters:
; - x0: The address to start at
; - x1: How many bytes to write
;
; Returns:
; - None
_zero:
    mov x9, 0
_zero_loop:
    strb wzr, [x0, x9]
    add x9, x9, 1
    cmp x9, x1
    b.le _zero_loop
    ret

; Compares two strings.
;
; Parameters:
; - x0: the address of the first string
; - x1: the address of the second string
;
; Returns:
; - x0: 0 if both are equal, non-zero if not
_streql:
    mov w9, 0
_streql_loop:
    ldrb w10, [x0, w9, uxtw]
    ldrb w11, [x1, w9, uxtw]
    cmp w10, 0
    b.eq _streql_end
    cmp w11, 0
    b.eq _streql_end
    cmp w10, w11
    b.ne _streql_end
    add w9, w9, 1
    b _streql_loop
_streql_end:
    sub x0, x10, x11
    ret

; Reads a string from stdin, and places it on the stack.
;
; Parameters:
; - x0: The memory address to place the string at
; - x1: Maximum bytes to read from stdin
;
; Returns:
; - x0: the size read from stdin
_strread:
    ; syscall 3 is read(fd, buf, len)
    ; stdin is 0
    mov x2, x1
    mov x1, x0
    mov x0, 0
    mov x16, 3
    svc 0x80
    ret
