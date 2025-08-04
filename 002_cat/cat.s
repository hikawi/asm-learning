.global _main

.text
_main:

    // Before the allocation, the stack looks like
    // --------------------- <-- sp
    //
    // The stack grows downwards, which is a bit confusing. Despite the diagram, subtracting from sp
    // will grow the stack downwards (allocation), adding to sp will move the stack upwards (deallocation).

    stp x29, x30, [sp, -16]!            // Allocate for x29 and x30

    // After this allocation, the stack looks like this:
    // ---------------------
    // x30                   <-- sp + 8
    // x29                   <-- sp + 0
    // --------------------- <-- sp

    sub sp, sp, 1024                    // Allocate stack space for char[1024]

    // The stack should look like this after the next allocation
    // ---------------------
    // x30                   <-- sp + 1032
    // x29                   <-- sp + 1024
    // ---------------------
    // 1024 bytes            <-- sp + 0 to sp + 1023
    // --------------------- <-- sp
    //
    // So adding sp + 0 would be the start of our buffer, and sp + 1024 would point to x29 and
    // sp + 1032 would point to x30

    // Zero out the buffer, this loops over the stack and zeros each byte.
    mov x0, 0
_main_zero_loop:
    strb wzr, [sp, x0]
    add x0, x0, 1
    cmp x0, 1024
    b.lt _main_zero_loop

    // Now we read from stdin
    mov x0, 0                           // 0 is stdin
    mov x1, sp
    mov x2, 1024
    mov x16, 3                          // read(fd, buf, count)
    svc 0x80

    // Now we have it in the stack, we can print it back to stdout
    mov x2, x0                          // read syscall returns back length read in x0
    mov x0, 1
    mov x1, sp
    mov x16, 4
    svc 0x80

    add sp, sp, 1024                    // Clear out char[1024]
    ldp x29, x30, [sp], 16              // Load back the x29 and x30 in the stack space
    mov x0, 0
    ret
