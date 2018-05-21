#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int main(void)
{
    int current_uid = getuid();
    if (setuid(0) || setgid(0))
    {
        perror("setuid");
        return 1;
    }
    //I am now root!
    printf("My UID is: %d. My GID is: %d\n", getuid(), getgid());
    system("/bin/bash bin/launch-vpn-setuid.sh");
    return 0;
}
