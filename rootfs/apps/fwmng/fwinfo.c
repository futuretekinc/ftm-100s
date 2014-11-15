#include <stdio.h>
#include "crc32.h"
#include "fwmng.h"

#define	MTD_SYS_INFO	"/dev/mtdblock0"

int check_kernel(char *pMTD, image_header_t *pHeader);
uint8_t	buff[0x20000];

int main(int argc, char *argv[])
{
	int				fp;
	sys_info_t		sysInfo = {.index = -1};
	image_header_t	header;
	uint32_t		crc;

	fp = open(MTD_SYS_INFO, O_RDONLY, O_NONBLOCK);
	if (fp == 0)
	{
		fprintf(stderr, "Can't open file[%s]\n", MTD_SYS_INFO);
		return	-1;
	}

	while (read(fp, buff, sizeof(buff)) == sizeof(buff))
	{
		crc = crc32(0, (uint8_t *)buff, sizeof(sys_info_t) - sizeof(uint32_t));
		if (((sys_info_t *)buff)->crc32 == crc)
		{
			if ((sysInfo.index == -1) || (((sys_info_t *)buff)->index > sysInfo.index))
			{
				memcpy(&sysInfo, buff, sizeof(sys_info_t));	
			}
		}
	}
	close(fp);

	if (sysInfo.index == -1)
	{
		fprintf(stderr, "System information not found!\n");
	}
	else
	{
		printf("System information\n");
		printf("%16s : %08x\n", "MAGIC CODE", 	sysInfo.magic);
		printf("%16s : %d\n", 	"INDEX", 		sysInfo.index);
		printf("%16s : %d\n", 	"Primary Kernel", sysInfo.kernel);
		printf("%16s : %d\n", 	"Primary RootFS", sysInfo.rootfs);
	}

	printf("Kernel Information\n");
	check_kernel("/dev/mtdblock2", &header);
	printf("%16s : %s\n", "Primary", header.ih_name);
	check_kernel("/dev/mtdblock7", &header);
	printf("%16s : %s\n", "Secondary", header.ih_name);

	printf("Root File System Information\n");
	printf("%16s : %s\n", "Primary", sysInfo.header[sysInfo.rootfs].ih_name);
	printf("%16s : %s\n", "Secondary", sysInfo.header[(sysInfo.rootfs + 1) % 2].ih_name);

	return	0;
	
}

int check_kernel(char *pMTD, image_header_t *pHeader)
{
	int	fp;
	image_header_t	header;

	fp = open(pMTD, O_RDONLY, O_NONBLOCK);
	if (fp == 0)
	{
		fprintf(stderr, "Can't open file[%s]\n", pMTD);
		return	-1;
	}

	if (read(fp, &header, sizeof(header)) != sizeof(header))
	{
		close(fp);
		return	-1;
	}

	memcpy(pHeader, &header, sizeof(header));
	close(fp);
	return	0;
}
