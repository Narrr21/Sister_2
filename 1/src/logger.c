#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

void log_msg(const char *msg) {
    int fd = open("server.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (fd < 0) {
        perror("open");
        return;
    }
    size_t len = strlen(msg);
    if (len > 0) {
        if (write(fd, msg, len) < 0) {
            perror("write");
        }
    }
    if (write(fd, "\n", 1) < 0) {
        perror("write");
    }
    close(fd);
}