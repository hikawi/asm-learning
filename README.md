# ASM Learning

## Overview

Hello, welcome dear reader to my diary of learning through ASM on ARM64 for the MacOS platform. There's a lot of resources of Assembly on Linux, and them being quite understandable, but there's not a lot of MacOS based Assembly resources, partly because of Apple being weird about it.

Each step of my journey has a diary entry attached to it in its own folder. Usually a folder contains the following files:

- A `.c` file. This is usually the C implementation of whatever the Assembly I worked with in the entry to compare how a C compiler compiles.
- A `.s` file. This is the assembly file, written in ARM64 format, targeting Macho64 on the Apple Silicon chip. (My laptop is Apple M1 Pro)
- A `.md` file. This is the entry related to the chapter.

## Journal Entries

1. [Exit](./000_exit/)
2. [Move and Add](./001_movadd/)
3. [Read and Print, cat command](./002_cat/)
4. [Stream to file line by line](./003_filewriter/)
5. [Number Guessing Game](./004_numberguess/)
6. [Happy Birthday with ncurses](./006_happybirthday/)

## Documentation

This serves as a public information repository for my ASM learning journey. If it helps someone else, great! If it doesn't, I'm glad I have my documentation. That's really it.

- [Syntax](./docs/syntax.md)
- [System calls](./docs/syscalls.md)
