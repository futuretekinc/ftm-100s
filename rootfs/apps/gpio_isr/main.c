#include <stdio.h>       /* For printf() */
#include <string.h>      /* For strerror() */
#include <unistd.h>      /* For read(), close() */
#include <fcntl.h>       /* For open() */
#include <errno.h>       /* For errno */
#include <sys/poll.h>    /* For poll() */

#define ERREXIT(str) {printf("err %s, %s\n", str, strerror(errno)); return -1;}

int main(int argc, char** argv)
{
	struct pollfd xfds[1];
	const char *fn;
	char buf[4];
	int rc;
	int fd;
	int i;

	/* export */
	fn = "/sys/class/gpio/export";
	fd = open(fn, O_WRONLY); 
	if(fd < 0) 
	{
		ERREXIT("open export")
	}

	rc = write(fd, "37", 3); 
	if(rc != 3) 
	{
		ERREXIT("write export")
	}
	close(fd);

	/* direction */
	fn = "/sys/class/gpio/gpio37/direction";
	fd = open(fn, O_RDWR);
	if(fd < 0)
	{
		ERREXIT("open direction")
	}
	rc = write(fd, "in", 3);
	if(rc != 3)
	{
		ERREXIT("write direction")
	}
	close(fd);

		/* edge */
	fn = "/sys/class/gpio/gpio37/edge";
	fd = open(fn, O_RDWR);
	if(fd < 0) 
	{
		ERREXIT("open edge")
	}

	rc = write(fd, "falling", 8); 
	if(rc != 8) 
	{
		ERREXIT("write edge")
	}

	rc = lseek(fd, 0, SEEK_SET);
	if(rc < 0)  
	{
		ERREXIT("lseek edge")
	}

	rc = read(fd, buf, 10); 
	if(rc <= 0)
	{
		ERREXIT("read edge")
	}

	buf[10] = '\0';
	printf("read gpio37/edge:%s\n", buf);
	close(fd);

	/* wait for interrupt - try it a few times */
	fn = "/sys/class/gpio/gpio37/value";
	fd = open(fn, O_RDWR);
	if(fd < 0)
	{
		ERREXIT("open value")
	}

	xfds[0].fd       = fd;
	xfds[0].events   = POLLPRI | POLLERR;
	xfds[0].revents  = 0;
	for (i=0; i<3; i++)
	{
		printf("Waiting for interrupt..\n");
		rc = poll(xfds, 1, 10000); 
		if(rc == -1) 
		{
			ERREXIT("poll value")
		}
		printf("poll rc=%d, revents=0x%x\n", rc, xfds[0].revents);
	}

	/* get value */
	rc = lseek(fd, 0, SEEK_SET); 
	if (rc < 0)
	{
		ERREXIT("lseek value")
	}

	rc = read(fd, buf, 2);
	if (rc != 2) 
	{
		ERREXIT("read value")
	}
	close(fd);
	buf[1] = '\0'; /* Overwrite the newline character with terminator */
	printf("read rc=%d, val=%s\n", rc, buf);

	/* unexport */
	fn = "/sys/class/gpio/unexport";
	fd = open(fn, O_WRONLY); 
	if(fd < 0) 
	{
		ERREXIT("open unexport")
	}

	rc = write(fd, "37", 3);
	if(rc != 3)
	{
		ERREXIT("write unexport")
	}
	close(fd);

	return 0;
}
