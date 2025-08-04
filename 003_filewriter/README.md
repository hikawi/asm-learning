# Filewriter

## Overview

A program that takes user input and keeps on printing it to a file line by line until the user explicitly types `quit`. This program aims to practice the following methods:

- Function calls
- Stack manipulation
- File handling
- Input handling from `cat`
- Infinite loops
- String comparison

## Weird system calls

I was able to deduce the values of flags needed for file opening by using a C program see what O_CREAT from fcntl.h evaluates to

```
macro O_WRONLY
provided by <sys/fcntl.h>
Type: int
Value = 1
#define O_WRONLY 0x0001

// Expands to
0x0001
```

In case you want to know what I extracted:

- O_RDONLY is `0x000`
- O_WRONLY is `0x001`
- O_RDWR is `0x002`
- O_APPEND is `0x008`
- O_CREAT is `0x200`

For the user mode, I picked `777` converted to hexa as the full permission flag. You can change this to your liking with any converter, or use `NUMBERo` with the `o` at the end to signify it as an octal literal.
