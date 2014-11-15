#include <stdio.h>
#include "fwmng.h"
#include "crc32.h"

#define	PAGESIZE	0x20000

uint8_t	buff[0x20000];

int main(int argc, char *argv[])
{
	FILE *FP;
	int	 fp , len;
	int	index = 0, 	last = -1, new = -1;
	sys_info_t		sysInfo;
	image_header_t	imageHeader;

	if (argc < 7)
	{
		return	-1;	
	}

	fp = open(argv[1], O_RDONLY, O_NONBLOCK);
	if (fp == 0)
	{
		fprintf(stderr, "Can't open MTD[%s]\n", argv[1]);	
		return	-1;
	}

	while((len = read(fp, buff, sizeof(buff))) > 0)
	{
		int crc = crc32(0, buff, sizeof(sys_info_t) - sizeof(int));
		if (crc != ((sys_info_t *)buff)->crc32)	
		{
			continue;
		}

		printf("sysinfo.index = %d\n", sysInfo.index);
		if (last == -1 || sysInfo.index < ((sys_info_t *)buff)->index)
		{
			memcpy(&sysInfo, buff, sizeof(sys_info_t));
			last = 	sysInfo.index;
		}
	}

	close(fp);

	new = (last+1) % 16;

	fp = open(argv[4], O_RDONLY, O_NONBLOCK);
	if (fp == 0)
	{
		fprintf(stderr, "Can't open header[%s]\n", argv[4]);
		return	-1;
	}

	len = read(fp, &imageHeader, sizeof(imageHeader));
	close(fp);
	if (len != sizeof(imageHeader))
	{
		fprintf(stderr, "Invalid image header\n");
		return	-1;
	}

	if (strcmp(argv[2], "rootfs") == 0)
	{
		sysInfo.index = new;
		if (strcmp(argv[3], "primary") == 0)
		{
			memcpy(&sysInfo.header[0], &imageHeader, sizeof(image_header_t));

		}
		else if (strcmp(argv[3], "secondary") == 0)
		{
			memcpy(&sysInfo.header[1], &imageHeader, sizeof(image_header_t));
		}
		else
		{
			return	-1;	
		}
	}
	else
	{
		return	-1;	
	}

	
	sysInfo.crc32 = crc32(0, (unsigned char *)&sysInfo, sizeof(sysInfo) - sizeof(int));

	memset(buff, 0, sizeof(buff));
	memcpy(buff, &sysInfo, sizeof(sysInfo));

	FP = fopen(argv[5], "w");
	if (FP == NULL)
	{
		fprintf(stderr, "Can't open file[%s]\n", argv[5]);
		return	-1;
	}
	fprintf(FP, "%d", new * PAGESIZE);
	fclose(FP);

	fp = open(argv[6], O_WRONLY | O_CREAT, O_NONBLOCK);
	write(fp, buff, sizeof(buff));
	close(fp);


	return	0;
}
