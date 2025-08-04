#include <stdio.h>
#include <string.h>

int _strcmp(char *a, char *b)
{
    while (*a != 0 && *b != 0 && *a++ == *b++)
        ;
    return *a - *b;
}

int main()
{
    FILE *fp       = fopen("./a.txt", "w");
    char buf[1024] = {0};

    while (1)
    {
        fgets(buf, 1024, stdin);
        if (_strcmp(buf, "quit\n") == 0)
            break;
        fputs(buf, fp);
        memset(buf, 0, 1024);
    }

    fclose(fp);
    return 0;
}
