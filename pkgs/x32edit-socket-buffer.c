#define _GNU_SOURCE

#include <sys/socket.h>
#include <sys/syscall.h>
#include <unistd.h>

/*
 * X32 Edit 4.4.1 fills JUCE's internal message socket while constructing its
 * interface, before the event loop can drain it. The default 64 KiB send
 * buffer then deadlocks both the main and timer threads in write(2).
 *
 * Raise the send buffer only for Unix stream socket pairs created inside X32
 * Edit. Linux doubles SO_SNDBUF values internally, yielding a 2 MiB buffer.
 */
int socketpair(int domain, int type, int protocol, int sockets[2]) {
  int result = (int)syscall(SYS_socketpair, domain, type, protocol, sockets);

  if (result == 0 && domain == AF_UNIX && (type & SOCK_STREAM) == SOCK_STREAM) {
    int buffer_size = 1024 * 1024;

    (void)setsockopt(sockets[0], SOL_SOCKET, SO_SNDBUF, &buffer_size,
                     sizeof(buffer_size));
    (void)setsockopt(sockets[1], SOL_SOCKET, SO_SNDBUF, &buffer_size,
                     sizeof(buffer_size));
  }

  return result;
}
