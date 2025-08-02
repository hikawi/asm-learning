# Moving and Adding

Now that we're more well versed with how Assembly works and how to write Assembly. How ironic, to get to basic addition and movement in Assembly, it takes 2 days where as all other languages is a 5 minute documentation read.

## Operation Basics

Some operations or instructions sometimes have a _carry flag_, which consists of information about how and what happened during the instruction. Just imagine it's like a status code.

Most of the Assembly programming is just manipulating the 31 registers in a smart way to do some action. There are 4 useful bitwise operations pointed out in the book in the part for shifting and rotating.

**Logical shift left** (or LSL): shift all bits left, put zeros on the right. The **last** bit that gets shifted left and falls out gets put in the _carry flag_.

**Logical shift right** (or LSR): same as LSL in reverse, zeros on the left. Last shifted out ends up in the _carry flag_.

**Arithmetic shift right** (or ASR): when we do a right shift with zeros coming in on the right, if the bitmask represents a number, then suddenly a negative number becomes a positive number (since the first bit is the sign bit, 0 for positive and 1 for negative). Here, ASR puts in 1s from the left if the number is negative, and 0s if the number is positive. **Use this for shifting signed integers**.

**Rotate right**: rotating is like a double ended queue in Python, or a circular linked list. It essentially does a shift right, but any bits that fall off at the end wrap around to the other side.

## Move Instruction

Reading the documentation on the ARM website, it's quite confusing because there are a lot of versions of a move instruction. The simple `mov` actually has 5 different classes (5 behaviors of the instruction), but it's not that complicated, since most of the time, the compiler will look for the best class to apply for your case.

There's a caveat that when running a mov command with arbitrary 64-bit values, it may give you this error:

```
movadd.s:10:13: error: expected compatible register or logical immediate
    mov x4, 0x1234567812345678
            ^
```

There are 5 cases for the move instruction:

1. Bitmask Immediate
2. Inverse 16-bit immediate
3. Register copy
4. To/From stack pointer
5. Wide Immediate

Here's what I found on a StackOverflow thread: This instruction can take many forms, depending on the value needed to be moved. And it changes if the value is a register or if it is an immediate. If it is in a register, then it produces an `ORR` instruction (`ORR <Xd>, XZR, <Wm>`). If it is using the `SP` (Stack Pointer) it produces an `ADD` instruction (`ADD <Xd|XSP>, <Xn|XSP>, #0`). If moving an immediate, then it is one of the `MOVZ`, `MOVK` or `MOVN` instructions.

### MOV (Bitmask Immediate)

```
mov <dest>, #imm
```

This is a fast bitmask copy that uses the fact that the immediate values have repeating patterns, basically blocks of 1s and 0s in binary. The value must be able to be represented as a repeating pattern, and fails otherwise.

Here's some pop quiz, consider yourself which ones of these are bitmasks:

1. `0x0000111100001111`
2. `0xFEFEFEFEFEFEFEFE`
3. `0xFFFF0000FFFF0000`
4. `0x1234123412341234`
5. `0x00000000FFFFFFFF`

The correct answer is, **2, 3 and 5**. _4_ is obviously not it, but why is _1_ not it but _2_ is? it's because of their binary presentation.

`0x1111` written in binary is `0b0001000100010001` which are blocks of 0 randomly interrupted by a single `1`. Therefore, it is not continuous. And `0xFEFE` written in binary would be `0b1111111011111110`, therefore, it is continuous. Confused yet? Yes, me too.

Let's hope I don't have to hit this a lot.

### MOV (Inverse 16-bit immediate)

```
mov <dest>, #imm
```

This is just a movement option, that if the inverse of the immediate value can be encoded in 16 bits, then it will use the inverted immediate value as the move operand.

The simplest way to understand this `mov` instruction is to think of it as a specialized tool for loading constants that are **mostly ones**. If it is a negative number with an `F` at the start, there's a chance it may choose this too, from my testing.

This is an alias of `movn`. You can check out `movn` (move-inverse) below. A `mov x0, #FFFF0000FFFF` might be converted into a `movn` call similarly `movn x0, #FFFF0000`.

### MOV (Register copy)

```
mov <dest>, <src>
```

This is quite intuitive. Just fully copy from a register and place the value in another register. You can actually write to the stack pointer (`sp`) also, but the assembler will pick class-4 `mov`.

This is an alias for a bitwise OR, it essentially takes the source register, bitwise OR it with `0`, and puts the result in the destination register. Since any number `OR` with 0 is just that number, (in maths they call this the identity function) so this is simply just a copy from one to another.

This is because there are only so many bits to cramp the op-code in the 32-bit instruction, the ARM designers need to make sure that all op-codes are used in a meaningful way, instead of having multiple `mov`s that can do similar things and skip out more important operations like arithmetics.

### MOV (From and To the stack pointer)

```
mov <dest|sp>, <src|sp>
```

This is exactly the same as **MOV (Register copy)** since all in all, `sp` is still a register. The only difference is that the assembler will transform a `mov` call that involves `sp` into an `add` operation instead of `orr`.

> What's the difference? Essentially none. _Adding 0 to a number_ and _OR 0 and a number_ basically just yields the number itself. But I'm guessing there are semantics around the `sp` register that an `ORR` would not fit well.

### MOV (Wide immediate)

```
mov <dest>, <value>
```

This is the most used class of the instruction by far, even though it looks limited. Putting any small 16-bit immediate value here would default to this instruction. This can also with arbitrary values on some architectures, but **not all**. But we're on Assembly for learning purposes, what's the point of worrying about other machine implementations of the ARM Instruction Set!

The value here must always be a 16-bit arbitrary value (for my machine), anymore and you need to use a different instruction, since a number larger than 16-bit can not be fully encoded in the 32-bit space for the instruction.

This is an alias for `movz`, you check this instruction out below!

### Conclusion

`mov` is definitely weird in Assembly, here is a simple comparison between all 5 classes.

| Assembly                     | Compiled Instruction        | Class                 |
| ---------------------------- | --------------------------- | --------------------- |
| `mov x0, 0x0000FFFF0000FFFF` | `mov x0, 0xffff0000ffff`    | Bitmask Immediate     |
| `mov x1, 0xFFF000000000FFFF` | `mov x1, #-0xfffffffff0001` | Inverse immediate     |
| `mov x2, x3`                 | `orr x2, xzr, x3`           | Register copy         |
| `mov x3, sp`                 | `add x3, sp, 0`             | From/to stack pointer |
| `mov x4, 0x4567`             | `mov x4, 0x4567`            | Wide immediate        |

## More movement options

`mov` decays into `orr` and `add` for class-3 and class-4 instructions. But other 3 can decay into these additional movement options if the assembler and your system support it, mine doesn't.

You can also use these instructions to be more precise on what to do, since when you're at Assembly level, every instruction matters.

### MOVK (Move with Keep)

```
movk <dest>, #imm [, LSL #shift]
```

This instruction moves a shifted 16-bit immediate value into a register, **while leaving all other bits untouched**. This is one way to construct a 64-bit arbitrary value on a register.

LSL notes how many bits to shift the immediate value by. Since a register is 64-bits, you can decide where these 16 bits are, by having the shift number be different. A register is split into 4 half-words (16-bit blocks), which can be replaced by using the LSL shift. If you don't specify a shift, it defaults to a shift of 0 bits.

Some notes:

- The shift for LSL must be a multiple of 16, including 0, 16, 32 and 48.
- If you use a 32-bit register as the destination, only LSL 0 and LSL 16 are available.

### MOVN (Move Inverse)

```
movn <dest>, #imm [, LSL #shift]
```

This has similar instruction syntax to `movk`, where you can specify the shift cycle. But beware, **this instruction does not preserve other bits**, this instruction uses the entire register. If you run a `movn` with `#FFFF`, it will actually put the value `#FFFFFFFFFFFF0000` to the register. You can check it out with my program down here:

```azsembly
_main:
	movn x0, 0xFFFF
	ret
```

When running the program, it starts with this:

```
        x0 = 0x0000000000000001
```

After reaching the instruction, it becomes:

```
        x0 = 0xffffffffffff0000
```

Some note is that since the assembler can choose which `mov` to select, it actually picked the inverse version of `mov` (disassembly version):

```
mov x0, #-0xf0001
```

### MOVZ (Move with zeros)

```
movz <dest>, #imm [, LSL #shift]
```

This instruction moves a 16-bit immediate value to a register at a certain _half-word_, denoted by the shift number. But different from `movk`, it zeros out the entire register, before putting the half-word where you want to put.

This is the most simple form of `mov`, and actually used by `mov (wide immediate)` class under the hood by assemblers.

## Additions and Subtractions

Additions are as simple as you can imagine it to be.

```assembly
mov x0, 0
add x0, x1, 3
```

This essentially is the same as the C code:

```c
x0 = 0;
x0 = x1 + 3;
```

So, yes, it's very simple. Subtraction is simply the inverse of addition (A - B = A + (-B)), so it extends from that. The only issue with this is that, when you use registers, you need to work with 2's complement version of integers.

2's complement is just a way to encode positive and negative integers using a sign bit (the first bit of the bit vector). I'll attempt to explain to my understanding why 2's complement is used.

### 2's Complement Problem

How would you try to implement negative numbers? Most straightforward way is to just use a _sign bit_, a leftmost bit that is 0 when positive and 1 when it is negative. Let's see how that works out. We will use **4-bit integers** just to keep it simple, but the first bit is the sign bit.

```
0001 = 1 (positive)
1001 = -1 (negative)
```

Very straightforward, correct? But here's the problem:

```
0000 = 0 (positive)
1000 = -0 (negative)
```

There are 2 versions of the same number/value. This might get in the way with calculations. Let's try to calculate something, what if I want to add a positive integer and a negative integer with this way of encoding.

```
   0001    (= 1)
+  1011    (= -3)
-------
   1100    (= -4)
```

Well there we have the problem. How can we calculate the sum correctly if we have to account for signed integers? There are some ways that people have designed to try fixing this problem:

- Shifting all values by the maximum, so all values computed would be positive, then we shift it back. Mathematically, it means, calculating `(A - n) + (B - n) = (C - n)`, adding back `n` would yield our correct result.
- Or, the way we're talking about, **2's complement**.

Instead of only using a sign bit, 2's complement tells us that we should flip all the bits after the sign bit too, and this only applies for the negative numbers. For example, to represent `-5` in 4-bits, we write `5` positive first `110`, then we have the sign bit and flip all other bits to become `1001`. Let's see how that works out for calculations.

```
   0001    (= 1)
+  1100    (= -3, 011 is 3 positive)
-------
   1101    (= -2, 010 is 2 positive)
```

Oh wow, the calculation matched up. How crazy is that? But there's still one problem with the double zero values (both `0000` and `1111` point to the same positive 0 and negative 0). To fix this once and for all, 2's complement requires us to _add 1_ to the bit vector if it is a negative number. So `-2` would actually be written as `010 -> 1101 + 1 = 1110`.

```
   0001    (= 1)
+  1101    (= -3, 011 is 3 positive, 1100 is without the +1)
-------
   1110    (= -2, 010 is 2 positive, 1101 is without the +1, so it's 1110 with the +1)
```

Now, we have the `0000` and `1111` pointed to different values and only one bitmask represents `0`.

You can try out the exercises below with me to further understand 2's complement.

### Setting Flags

The program has some flags set in the program state block, and some operations have an `s` variant to set the setting flags. For example `add` has a `adds`. The difference is that if `add` does operation that overflows, it drops the bits that get overflown. If you use `adds` instead, the _carry flag_ is actually set in the program.

Why should we care about this? It's because we have operations like `adc` (add with carry), that you run an addition operation while respecting the carry flag. This is so you can do arithmetics on arbitrarily large numbers (128-bit numbers, 256-bit numbers, etc.)

Of course, `adc` itself also has `adcs`, which sets the carry bit to `0` if this operation did not leave any bit carried over. You can try making a guess if `sub` has a _setting_ variant (yes, it's `subs`, and for `sbc` it's `sbcs`).

## Exercises

**Compute the 8-bit two's complement for -79 and -23**.

```
General Purpose Registers:
        x0 = 0xffffffffffffffb1
        x1 = 0xffffffffffffffe9
```

If you're correct, it would be `0xB1` which is `1101 0001` for `-79` 8-bit two's complement. If you still didn't get it, if you convert `79` to positive, you get the bit representation `0100 1111`, then flip the sign bit and everything to `1011 0000` and finally, add 1 `1011 0001`.

Try to do the same for `-23`, if you received `0xE9` which is `1110 1001`, you're correct!

**Write a program to add two 192-bit numbers.**

```assembly
    mov x0, 1
    mov x1, 2
    mov x2, 3

    mov x4, 4
    mov x5, 5
    mov x6, 6

    adds x0, x0, x4
    adcs x1, x1, x5
    adcs x2, x2, x6
```

**Write a program that performs 128-bit subtraction**.

```
    subs x0, x0, x2
    sbcs x1, x1, x3
```
