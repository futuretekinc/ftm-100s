#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
	unsigned char *	buff;
	int				block_size;
	int				src,dst;
	int				len;

	if (argc < 4)
	{
		return	-1;	
	}
	
	src = open(argv[2], O_RDONLY, O_NONBLOCK);
	if (src == 0)
	{
		fprintf(stderr, "Can't open source file[%s]\n", argv[2]);
		return	-1;	
	}

	dst = open(argv[3], O_CREAT | O_WRONLY, O_NONBLOCK);
	if (src == 0)
	{
		fprintf(stderr, "Can't create destination file[%s]\n", argv[3]);
		return	-1;	
	}

	block_size = atoi(argv[1]);
	if (block_size == 0)
	{
		return	-1;	
	}

	buff = malloc(block_size);
	if (buff == 0)
	{
		return	-1;	
	}

	while((len = read(src, buff, block_size)) > 0)
	{
		write(dst, buff, block_size);	
	}

	close(src);
	close(dst);

	free(buff);
	return	0;
}
