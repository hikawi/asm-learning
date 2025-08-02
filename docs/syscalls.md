# MacOS System Calls

This is to document the functions and system calls available in MacOS as I go through them. I needed a way to catalog what system calls are available, but most resources only cover Linux-based syscalls which are not what I want.

Also, Apple's Open Source KNU kernel has a system call list. But it does not mention how and what to pass to the system call. This is what I aim to do.

## Recap

To recap, a system call in assembly (with ARM64 syntax) can be done with the following steps:

1. Put the "system call number" into the opcode register (`x16` on MacOS and `x8` on Linux).
2. Put your arguments needed into argument registers (`x0` to `x8` on MacOS and `x0` to `x6` on Linux, MacOS reserves `x7` and `x8` for certain things).
3. Run a supervisor call (`svc`).
   - The operand for the supervisor call is an immediate value (like `svc 0`).
   - For MacOS platforms, this is `svc 0x80` for some reasons. It does not matter and MacOS just ignores it, but Apple has this convention for `svc`.

## Table of Contents

A list of opcodes are available here without further documentation on arguments: [ARM Syscall](https://arm.syscall.sh/).

## System call documentation
