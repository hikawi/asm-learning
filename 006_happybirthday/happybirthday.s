.global _main

.data
hpbd:
    .asciz "Happy Birthday, Vũ Hoàng Minh Tuấn!!"
hpbd_len:
    .word . - hpbd - 1

.text
_main:
    stp x29, x30, [sp, -16]!
    sub sp, sp, 16

    bl _initscr         ; init screen
    str x0, [sp]        ; keeps stdscr in the stack

    bl _noecho          ; removes echo

    mov x0, 0           ; removes cursor
    bl _curs_set

    ldr x0, [sp]
    bl _print_and_wait
    bl _endwin

    add sp, sp, 16
    ldp x29, x30, [sp], 16
    mov x0, 0
    ret

; Prints out a string and waits for the next input
;
; Parameters:
; - x0: the stdscr
_print_and_wait:
    stp x29, x30, [sp, -16]!

    ; we want to allocate:
    ; 8 bytes (the WINDOW *), 4 bytes (max X), 4 bytes (max Y)
    sub sp, sp, 16

    ; store the stdscr back into the stack here
    str x0, [sp]

    ; first we read the max window width and height first
    ldr x0, [sp]
    bl _getmaxx
    str w0, [sp, 8]

    ldr x0, [sp]
    bl _getmaxy
    str w0, [sp, 12]

    ; now we can do stuff to get the center of the screen
    mov w0, 2
    ldp w1, w2, [sp, 8]
    sdiv w1, w1, w0
    sdiv w2, w2, w0
    stp w1, w2, [sp, 8]

    ; subtract from the string length
    adrp x3, hpbd_len@PAGE
    add x3, x3, hpbd_len@PAGEOFF
    ldr w4, [x3]
    sdiv w4, w4, w0
    sub w1, w1, w4
    str w1, [sp, 8]

    ; now the stack hold where we want to move to to print
    ; we want to call wmove
    ; then call waddstr
    ldr x0, [sp]
    ldp w2, w1, [sp, 8]
    bl _wmove

    ldr x0, [sp]
    adrp x1, hpbd@PAGE
    add x1, x1, hpbd@PAGEOFF
    bl _waddstr

    ; now we wait for the char
    bl _getch

    add sp, sp, 16
    ldp x29, x30, [sp], 16
    ret
