.global _main
.align 2

.text
_main:
    mov x0, 1
    mov x1, 2

    mov x2, 4
    mov x3, 5

    subs x0, x0, x2
    sbcs x1, x1, x3

    ret
