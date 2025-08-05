#include <stdio.h>
#include <stdlib.h>

int main()
{
    // We use /dev/random to get the random bytes.
    FILE *random = fopen("/dev/random", "r");
    unsigned int target;
    fread(&target, 4, 1, random);
    target %= 100;
    fclose(random);

    printf("%u\n", target);
    return 0;

    int moves = 0;
    char buf[16];

    fputs("Guess a number from 1 to 100!\n", stdout);
    while (1)
    {
        fputs("-> Your guess: ", stdout);
        fgets(buf, 16, stdin);

        int num = atoi(buf);
        moves++;
        if (num < target)
        {
            fputs("Too small!\n", stdout);
        }
        else if (num > target)
        {
            fputs("Too big!\n", stdout);
        }
        else
        {
            printf("You won in %d moves\n", moves);
            break;
        }
    }

    return 0;
}
