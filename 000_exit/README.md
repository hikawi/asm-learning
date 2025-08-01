# Step 0 - The ASM and ARM64 system

## Assembly Instructions

### CPU Registers

To put it simply, registers are simple 64-bit memory blocks that we can load data into and process data or run arithmetic operations. Registers are inside the CPU, therefore, are extremely fast, compared to the "memory" or the RAM where there's some latency in reading.

The ARM processor provides two basic types of instructions:

- Instructions that **load memory**, or **store data into registers**.
- Instructions that **perform an operation** with registers.

A simple addition probably needs to be split into 3 steps: for example, loading two numbers from memory into registers, doing the addition, and storing it back into the memory.

A program we write has access to 31 "general-purpose" registers, a program counter (read-only), and some random others:

- `x0` to `x30`: 31 registers.
- `sp` and `xzr`: the stack pointer or the zero register (there are more caveats).
- `x30`, `lr`: the link register. For calling functions, this holds where to jump back to (calling a function requires you to jump into that function, and when that function exists, you need to continue from where you called it right). _Avoid using this for other purposes_.
- `pc`: the program counter. Points to the executing instruction's memory address. It's read-only.

We sometimes don't use the full 64 bits of a register, so there are ways to use them as 32-bit registers by calling them with `w0` to `w30` and `wzr` (the `w` instead of `x`). The instruction will use the _lower 32 bits_ and set the _upper 32_ to zero. It just saves memory. We're at the point where using a 8 byte or 4 byte integer is a concern now.

### ARM Instruction

I have some experience with weird bit chunks that represent instructions from modding Paper Mario. Each instruction has 32 bits (to read it from a binary file), so you know where an instruction starts and where an instruction ends.

> There's a warning for caution that you can't mix registers. Either stick with `w` registers or `x` registers only.

You can write 32-bit numbers into a program to create instructions for the ARM. But is it really worth it? The assembler will convert our "still-readable" instructions like `add x1, x2` into these 32-bit numbers. Here, I'll use CMake to build the assembly.

### System calls

System calls, here, called **supervisor calls**. These are statements that request the operating system to do something _on behalf of us_. We actually do not have permissions to read files, write to files, or even to console as those are considered system resources. But we do have permission to tell the OS what we want to access or do, then "ask the OS to do it for us" through a _system call_.

A system call in Linux ARM is the following instruction:

```assembly
svc 0
```

Which stands for supervisor call. On MacOS, for some weird reasons, you need to provide an **immediate value** (you can consider this like _literals_ in other languages, data that is not bound to a certain memory address, it's just there, like to add 2 to a register, you don't have to just create a new register with that value 2 to add, you can just "add" with 2 as the immediate value).

It seems like currently there is _no use for this immediate value_ for supervisor calls, but apparently Apple's programs have a convention to use `0x80` as the immediate value for supervisor calls. It means nothing, it's just a convention.

```assembly
svc 0x80
```

The way you use system calls is:

1. Load the "opcode" register with the number of the system call you want to use. There are various of them. Like `1` for `exit`, `4` for `write`, etc. **Linux provides compatibility so opcodes never change for them, whereas MacOS does not make this claim**. Of course, it's Apple. The opcode register on Linux seems to be `x8` where the opcode register on MacOS seems to be `x16`.
2. Load the arguments into various registers, by convention is `x0` to `x6` (Apple also uses `x7` and `x8` for some system calls). This is similar to calling functions with arguments.
3. Run the supervisor call instruction.
4. Mess with the return value, usually put into `x0` and `x1`.

So, yes, a simple `printf` like in a C program would require a lot more instructions:

1. Put the opcode for write into `x8` or `x16` (depending on whether you're on MacOS or Linux).
2. Put `0` into `x0` (which stands for first argument to be `stdout`).
3. Put the memory of the string to print into `x1`.
4. Put the length of the string to print into `x2`.
5. Supervisor call.

## Compilation

For me, the compile commands never worked with using `as` and `ld` for assembling and linking, even though both are provided by Apple as part of XCode Developer Tools. Of course, don't use AI here if you can help it, it will give out nonsensical comments because of how obscure Apple's ARM system is.

### Using assembler and linker

Assembler and linker are provided as part of XCode Tools, and they may be used for doing what they do for creating Assembly programs. For Linux, I think the book mentions GNU's `as` and `ld`.

I do not have a Linux machine to test it out, but here's an extract from the book:

```
as -o file.o file.s
ld -o file file.o
./File
```

#### Dynamic Linker for MacOS

This, unsurprisingly, does not work with MacOS assembler and linker. Here's how I managed to work it out:

```
as -o file.o file.s
```

This assembles the assembly file into an object file. This is normal for both Unix-based systems. Here's the tricky part, if you try to do the same thing on Linux for MacOS, there's a good chance this error message is displayed:

```
~/Desktop/projects/misc/asm-learning> ld main.o -o main
ld: dynamic executables or dylibs must link with libSystem.dylib
```

Apparently, every program that wants to link dynamically must link with that library for MacOS. You can run this `xcrun --show-sdk-path` to show where the SDKs are which seem to help. For me, this was `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`.

Now, you can run this command:

```
ld -lSystem -syslibroot THAT_PATH_FOR_YOU -o main main.o
```

Now, it works! 🎉

#### Static Linker for MacOS

The way I just showed you was for dynamically linking to an existing MacOS library. Statically linking means the library is put into the executable itself.

> When you **statically link** a program, the linker takes _all_ the necessary code from the libraries your program uses and **copies it directly into your final executable file**. It's as if every brick needed for a building is physically included within the blueprint of _that specific building_.

Running a static linker doesn't seem to have the error that it must link with the dynamic library (dylib on MacOS, or probably familiar to you for gamers as "missing dll files", those are Windows's version of dynamic libraries).

```
ld -static -e _main main.o
```

For static linking, I use another flag called _entrypoint flag_, this tells the linker the "symbol" that starts our program. You will see this later. I think it expects to have a `start` symbol? But i used `_main` as my starting point. I explain this part down in the **using compiler** section, just below.

### Using compiler

Apparently Linux's `gcc` or Apple's `cc` can just compile the assembly straight to a runnable executable. So uhhh, you can use that too I guess.

```
cc main.s -o main
./main
```

To use a compiler for compiling assembly code, the entry point for the program must be `_main` for my system. I don't know what yours is. But running the linker without a `_main` symbol for me would fail with the message:

```
Undefined symbols for architecture arm64:
  "_main", referenced from:
      <initial-undefines>
ld: symbol(s) not found for architecture arm64
```

Apparently, from what I see, is that the system library provides C-like functions like `write()` or `exit()` where it has its own `start` symbol to setup the system library itself. So for user programs like ours, we don't have to run that starting pipeline, that's why for us, it starts at `_main` instead.

> If you want to use a simple compiler to compile your program, `_main` would be your starting symbol, not `start`.

## First ever program

You probably expect a "Hello, World!" program here, but it somehow goes even deeper. **Assembly programs by default, do not have a graceful exit**. You know how programs like in C have a main function that returns `0` to signify success?

```assembly
.text
.global _main

_main:
    mov x0, 0
    add x1, x0, 1
```

Here's a super simple Assembly program, but there are still a few things going on:

1. `.text` signifies the "code blocks", meaning from here on out, these are CPU instructions.
2. `.global _main`: marks our symbol `_main` as a global symbol for the linker to find.
3. `_main:` tells the program what our symbol signifies. The symbol is merely a label like a switch statement or `goto` in C. It simply marks that the current memory address is named `_main` and here at this memory there are these instructions.
4. `mov x0, 0`: copy or (_move_) the immediate value `0` to the `x0` register.
5. `add x1, x0, 1`: _add_ the value of the second operand (`x0`) with the third operand (`1`), save the result into the first operand (`x1`).

When you compile and run it, it will cause a fault because the program has not been instructed to exit properly. But you notice, in a normal C program, we need to have a `return 0` in our program. A return instructions in Assembly is `ret`. Let's do exactly that:

```assembly
_main:
    mov         x1, 0               ; x1 = 0
    add         x0, x1, 0           ; x0 = x1 + 0
    ret
```

Now running a program exists gracefully without any faults!

### Checking with a C program

Here's a simple C program everyone knows and loves:

```c
int main() {
	return 0;
}
```

When compiling with `cc -O3 main.c` (I don't know why this optimization level for now, but it should be done to remove the random stack manipulations the C program provides as of right now). Here's the disassembly:

```
Disassembly of section __TEXT,__text:

0000000100000328 <_main>:
100000328: 52800000    	mov	w0, #0x0                ; =0
10000032c: d65f03c0    	ret
```

Looks understandable now, right? We understand what it means, but in case you haven't caught the idea of it yet, we're moving `0` (the return value) into `w0` (since `int` is 32-bit, we don't need to use the entire 64-bit register for it), then `ret` (returns).

**Random notes**: You can see the "32-bit instruction" part as the first part `52800000` for the instruction of `mov w0, 0`. That number is decoded into that instruction. This decoding step is essential to the CPU for its (fetch-decode-execute cycle). You can check out Tom Scott's video about this as it goes into pretty good details but not too much details about this.

> If you don't compile with `-O3`, there are weird things going on with stack manipulation. I don't know why yet.

For example, we can check the return code in bash with `echo $?` for the following program:

```assembly
_main:
    mov x0, 0xFF
    ret
```

We can see the return result here (`0xFF` is `255`):

```
light@lunar 000_exit % cc exit.asm && ./a.out
light@lunar 000_exit % echo $?
255
```
