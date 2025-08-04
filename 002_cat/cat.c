#include <stdio.h>

int main()
{
    char buf[1024] = {0};
    fgets(buf, 1024, stdin);
    fputs(buf, stdout);
    return 0;
}
