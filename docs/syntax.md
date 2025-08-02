# ARM64 Syntax

This is a quick overview on ARM64 syntax. It's dead simple but there's a good number of stuff to be known, since it's not very intuitive like swapping from a programming language to another.

## Directives

Directives are lines that start with a `.`, _usually_.

- `.section __TEXT,__text`: defines this section would contain executable code.
- `.text`: shorthand for `.section __TEXT,__text`.
- `.section __DATA,__data`: defines this section would contain data stored in memory.
- `.data`: shorthand for `.section __DATA,__data`.
- `.global x`: mark the symbol `x` as a globally accessible symbol.
- `.ascii` and `.asciz`: marks the data as an ASCII string and a null-terminated ASCII string.

## Labels

Labels are like goto labels in C. They are memory addresses with a name. They are a simple text string that ends in `:`.

For example, this is a label named `label_hihi`. We can call this a **symbol**:

```assembly
label_hihi:
```

## Instructions

An instruction is akin to a function call, but this is a direct instruction to the CPU to work on our data. It always starts with the _operator_, followed by its _operands_. Each instruction takes up a fixed 32 bits at a certain offset in the binary, which is pointed to by the _program counter_.

- Operator is like the name of the function, for example `add` for addition and `sub` for subtraction, or `b` for branching logic if some condition holds.
- Operands are similar to function's arguments, separated with commas. `add 1,2` (example only) is an `add` instruction with 2 operands `1` and `2`.

> Hold! Instructions are instructions and do not mean actual functions in a programming language. There isn't a function concept in Assembly, everything is done with correct label jumping. Do not mix the two.

## Registers

We get 31 registers to work with:

|            Register            | Usage                                                                           |
| :----------------------------: | ------------------------------------------------------------------------------- |
|         `x0` to `x30`          | 31 general-purpose registers for us to use, some may have double meaning        |
|              `x0`              | Used as return value for an instruction or the first argument for a system call |
|  `x0` to `x8` (`x6` on Linux)  | Arguments for a system call                                                     |
| `x8` (Linux) and `x16` (MacOS) | System call number register                                                     |
|         `x29` or `fp`          | Frame pointer (for accessing stack-allocated memory)                            |
|         `x30` or `lr`          | Link register (holds where to jump back to after a 'function call')             |
|              `sp`              | Stack pointer                                                                   |
|              `pc`              | Program counter, points to the current executing instruction (read-only)        |

`pc` might not be accessible easily in some systems with ARM64.

## R-values

There are some ways to pass information to operands:

- Immediate value: a literal `1`, `2`, `42069`, etc. Used by just having the number or prepended with `#`. Can be binary (`0x000001111`), hexadecimal (`0x10`) or decimal (`1234`).
- Register value: referring the register directly means you want to use what it stores as a value (`x1`, `x2`, `x15`, etc.)
- Indirect register: using the value in a register as a memory address. This is similar to deferencing in C. (`[x1]`, `[x18]`, etc.)
- Indirect register offset: using the value in a register as a memory address, shifted by a value. This is similar to pointer arithmetic in C. `[x1, 8]` means 8 bytes offset from the memory `x1` points to. (`x1[8]` in C)
- Position Independent Code on MacOS: to access the memory address of a label, it's required to do `label@PAGE` to read the _page address_, and you may get the _memory address_ by adding `label@PAGEOFF` to the page address.

## Comments

Comments can be `//`, `#`, `@`, or `;`. Here, I use `//`.
