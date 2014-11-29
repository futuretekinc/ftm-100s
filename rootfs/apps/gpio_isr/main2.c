#include <stdio.h>
#include <poll.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int main(void)
{
	int fd = open("/sys/class/gpio/gpio37/value", O_RDONLY|O_NONBLOCK);
	if (-1 != fd)
	{
		struct pollfd poll_123 = { .fd = fd, .events = POLLPRI|POLLERR };
		while(1)
		{
		int rv = poll(&poll_123, 1, -1);    /* block endlessly */
		if (rv > 0)
		{
			if (poll_123.revents & POLLPRI)
			{
				/* IRQ happened */
				char buf[2];
				lseek(poll_123.fd, 0, SEEK_SET);
				int n = read(poll_123.fd, buf, sizeof(buf));
				if (n > 0)
				{
					char gpio_val = (buf[0] == 48) ? 0 : 1;
					printf("gpio_val = %d\n", gpio_val);
				}
			}
		}
		}
	}

	return	0;
}
