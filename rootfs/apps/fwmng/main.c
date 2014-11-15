#include "fwmng.h"
#include "xshared.h"
#include "debug.h"
#include "crc32.h"


int		showStatus(void);
long	filesize(char *filename);
int		upgradeKernel(fwmng_config_t *pConfig, char *srcFileName, int primary);
int		upgradeFirmware(fw_type_t type, char *filename, char *mtd);

int		loadConfig(fwmng_config_t *pConfig);
int		showConfig(fwmng_config_t *pConfig);

int 	showSysInfo(sys_info_t *pSysInfo);
int		loadSysInfo(sys_info_t *pSysInfo);
int 	storeSysInfo(sys_info_t *pSysInfo);

key_t			key = 0x4432;
status_t		*pxStatus = NULL;
uint			sysInfoMagic = 0;
char*			configFileName = "/etc/fwmng.conf";
fwmng_config_t	fwmngConfig = { 0, };

static struct option long_options[] =
{
};


int main(int argc, char *argv[])
{
	char	*kernelFileName = NULL;
	char	*rootfsFileName = NULL;
	int		opt, opt_idx;

	while((opt = getopt_long(argc, argv, "sc:k:f:vV", long_options, &opt_idx)) != -1)
	{
		switch(opt)
		{
		case	's':
			return showStatus();

		case	'c':
			configFileName=optarg;
			break;

		case	'k':
			kernelFileName = optarg;
			break;

		case	'f':
			rootfsFileName = optarg;
			break;

		case	'v':
			break;

		case	'V':
			XTRACE_ON();
			break;

		default:
			{
				fprintf(stderr, "%s: invalid option -- '%c'\n", argv[0], opt);
				return	0;
			}
		}
	}

	loadConfig(&fwmngConfig);

	pxStatus = XSD_Open(key, sizeof(status_t));
	if (pxStatus == 0)
	{
		pxStatus = XSD_Create(key, sizeof(status_t));
		if (pxStatus == 0)
		{
			return	-1;	
		}
	}

	if (kernelFileName != NULL)
	{
		upgradeKernel(&fwmngConfig, kernelFileName, 0);
		upgradeKernel(&fwmngConfig, kernelFileName, 1);
	}

	return	0;
}

int	loadConfig(fwmng_config_t *pConfig)
{
	char	buff[256];

	FILE *fp = fopen("/etc/fwmng.conf", "rt");	
	
	if (fp == NULL)
	{
		fprintf(stderr, "Can't open configuration file\n");
		return	-1;	
	}

	while(fgets(buff, sizeof(buff), fp) != NULL)
	{
		char *ptr = strchr(buff,'=');
		if (ptr != NULL)
		{
			char *item = buff;
			char *value = ptr+1;

			*ptr = '\0';

			if (strcmp(item, "primary_kernel") == 0)
			{
				pConfig->primary_kernel = atoi(value);
			}
			else if (strcmp(item, "secondary_kernel") == 0)
			{
				pConfig->secondary_kernel = atoi(value);
			}
			else if (strcmp(item, "primary_rootfs") == 0)
			{
				pConfig->primary_rootfs = atoi(value);
			}
			else if (strcmp(item, "secondary_rootfs") == 0)
			{
				pConfig->secondary_rootfs = atoi(value);
			}
		}
	}

	fclose(fp);

	showConfig(pConfig);

	return	0;
}

int	showConfig(fwmng_config_t *pConfig)
{
	printf("<FWMNG Config>\n");
	printf("%16s : %d\n", "Primary Kernel", pConfig->primary_kernel);
	printf("%16s : %d\n", "Secondary Kernel", pConfig->secondary_kernel);
	printf("%16s : %d\n", "Primary RootFS", pConfig->primary_rootfs);
	printf("%16s : %d\n", "Secondary RootFS", pConfig->secondary_rootfs);
	return	0;
}

int	loadSysInfo(sys_info_t *pSysInfo)
{
	int			size;
	sys_info_t	sysInfo;
	
	int hMTD = open("/dev/mtdblock0", O_RDONLY, O_NONBLOCK);
	if (hMTD < 0)
	{
		return	-1;	
	}
	
	size = read(hMTD, &sysInfo, sizeof(sysInfo));
	if (size != sizeof(sysInfo))
	{
		close(hMTD);
		return	-1;	
	}
	close(hMTD);
	
	if (sysInfo.magic != sysInfoMagic)
	{
		return	-1;	
	}

	if (sysInfo.crc32 != crc32(0, (unsigned char *)&sysInfo, sizeof(sysInfo) - sizeof(uint)))
	{
		return	-1;	
	}

	memcpy(pSysInfo, &sysInfo, sizeof(sysInfo));

	return	0;
}

int storeSysInfo(sys_info_t *pSysInfo)
{
	int			size;
	int			hMTD;
	sys_info_t	sysInfo;

	memcpy(&sysInfo, pSysInfo, sizeof(sys_info_t));
	sysInfo.crc32 = crc32(0, (unsigned char *)&sysInfo, sizeof(sysInfo) - sizeof(uint));
	
	hMTD = open("/dev/mtdblock0", O_RDWR, O_NONBLOCK);
	if (hMTD < 0)
	{
		return	-1;	
	}

	size = write(hMTD, &sysInfo, sizeof(sysInfo));
	if (size != sizeof(sysInfo))
	{
		return	-1;	
	}
	close(hMTD);

	return	0;
}

int showSysInfo(sys_info_t *pSysInfo)
{
	printf("%16s : %08x\n", "MAGIC", 	pSysInfo->magic);
	printf("%16s : %d\n", 	"INDEX", 	pSysInfo->index);
	printf("%16s : %d\n", 	"KERNEL", 	pSysInfo->kernel);
	printf("%16s : %d\n", 	"ROOT FS", 	pSysInfo->rootfs);
	printf("%16s : %08x\n", "CRC32", 	pSysInfo->crc32);

	return	0;
}

int	upgradeKernel(fwmng_config_t *pConfig, char *srcFileName, int primary)
{
	char		mtdName[256];
	char		szBuf[4096];
	int			size = 0;
	int			nReadSize = 0;
	struct stat xStat;

	XTRACE(" Srouce File Name : %s\n", srcFileName);
	XTRACE("Primary Partition : %s\n", (primary)?"YES":"NO");

	if (stat (srcFileName, &xStat) == -1)
	{
		XERROR("Source file invalid[%s]\n",	srcFileName);
		return -1;
	}

	if (xStat.st_size <= 0)
	{
		XERROR("Source file invalid[%s]\n",	srcFileName);
		return	-1;
	}

	int hSrc = open(srcFileName, O_RDONLY, O_NONBLOCK);
	if (hSrc < 0)
	{
		XERROR("Can't open file[ %s ] \n", srcFileName);
		return	-1;	
	}

	if (primary)
	{
		sprintf(mtdName, "/dev/mtdblock%d", pConfig->primary_kernel);
	}
	else
	{
		sprintf(mtdName, "/dev/mtdblock%d", pConfig->secondary_kernel);
	}
	int hDest= open(mtdName, O_WRONLY, O_NONBLOCK);
	if (hDest < 0)
	{
		XERROR("Can't open mtd[ %s ] \n", mtdName);
		close(hSrc);
		return	-1;
	}

	while((size = read(hSrc, szBuf, sizeof(szBuf))) > 0)
	{

		write(hDest, szBuf, size);

		nReadSize += size;
		XTRACE("write : %10d/%10d\n", nReadSize, xStat.st_size);
	}

	close(hDest);
	close(hSrc);

	return	0;
}

int	upgradeFirmware(fw_type_t type, char *srcFileName, char *mtd)
{
	sys_info_t	sysInfo;
	char	szBuf[4096];
	int		size = 0;
	int		nReadSize = 0;


	if (loadSysInfo(&sysInfo) != 0)
	{
		return -1;
	}

	strncpy(pxStatus->szSrcName, srcFileName, sizeof(pxStatus->szSrcName) - 1);
	strncpy(pxStatus->szDestName, mtd, sizeof(pxStatus->szDestName) - 1);
	pxStatus->nProgress = 0;

	struct stat xStat;
	if (stat (srcFileName, &xStat) == -1)
	{
		XERROR("Source file invalid[%s]\n",	srcFileName);
		return -1;
	}

	if (xStat.st_size <= 0)
	{
		XERROR("Source file invalid[%s]\n",	srcFileName);
		return	-1;
	}
	pxStatus->size = xStat.st_size;

	int hSrc = open(srcFileName, O_RDONLY, O_NONBLOCK);
	int hDest= open(mtd, O_WRONLY, O_NONBLOCK);

	if (hSrc < 0)
	{
		XERROR("Source file open failed[%s]\n", srcFileName);
		close(hDest);
		return	-1;	
	}

	if (hDest < 0)
	{
		XERROR("Destination file open failed[%s]\n", mtd);
		close(hSrc);
		return	-1;	
	}

	switch(type)
	{
	case	FWT_KERNEL:
		{
			while((size = read(hSrc, szBuf, sizeof(szBuf))) > 0)
			{

				write(hDest, szBuf, size);

				nReadSize += size;
				pxStatus->nProgress = (int)(nReadSize * 100 / pxStatus->size);
			}
			break;
		}
		break;

	case	FWT_ROOTFS:
		{
			image_header_t	header;

			size = read(hSrc, &header, sizeof(header));
			if (size != sizeof(header))
			{
			
			}

			while((size = read(hSrc, szBuf, sizeof(szBuf))) > 0)
			{

				write(hDest, szBuf, size);

				nReadSize += size;
				pxStatus->nProgress = (int)(nReadSize * 100 / pxStatus->size);
			}
			break;
		}
		break;
	default:
		{
		}
	}

	close(hDest);
	close(hSrc);

	XTRACE("Disk Sync...\n");
	FILE *fp = popen("sync;sync", "r");
	pclose(fp);

	XTRACE("Firmware upgrade done.\n");


	//XSD_Delete(key);

	return	0;
}

int	showStatus(void)
{
	if (pxStatus != 0)
	{
		fprintf(stdout, "%d\n", pxStatus->nProgress);
	}

	return	0;
}


