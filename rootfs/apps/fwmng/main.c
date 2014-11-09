#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <signal.h>
#include "xshared.h"
#include "debug.h"
#include "crc32.h"

typedef	unsigned int	uint32_t;
typedef	unsigned char 	uint8_t;

typedef struct image_header 
{
    uint32_t    ih_magic;   /* Image Header Magic Number    */
    uint32_t    ih_hcrc;    /* Image Header CRC Checksum    */
    uint32_t    ih_time;    /* Image Creation Timestamp */
    uint32_t    ih_size;    /* Image Data Size      */
    uint32_t    ih_load;    /* Data  Load  Address      */
    uint32_t    ih_ep;      /* Entry Point Address      */
    uint32_t    ih_dcrc;    /* Image Data CRC Checksum  */
    uint8_t     ih_os;      /* Operating System     */
    uint8_t     ih_arch;    /* CPU architecture     */
    uint8_t     ih_type;    /* Image Type           */
    uint8_t     ih_comp;    /* Compression Type     */
    uint8_t     ih_name[32];  /* Image Name       */
} image_header_t;

typedef	struct
{
	uint	magic;
	uint	index;
	uint	kernel;
	uint	rootfs;
	image_header_t	header[2];
	uint	crc32;
}	sys_info_t;

typedef	struct	
{
	char	szSrcName[256];
	char	szDestName[256];
	int		nSize;
	int		nProgress;
}	STATUS;

long	filesize(char *lpszName);

key_t	key = 0x4432;
STATUS	*pxStatus = NULL;
uint	sysInfoMagic = 0;

static struct option long_options[] =
{
};


int main(int argc, char *argv[])
{
	sys_info_t	sys_info;
	char	*lpszSrc;
	char	*lpszDest;
	int		opt, opt_idx;

	while((opt = getopt_long(argc, argv, "sk: f: m: vV", long_options, &opt_idx)) != -1)
	{
		switch(opt)
		{
		case	's':
			return showStatus();

		case	'k':
			lpszSrc = optarg;
			break;

		case	'f':
			lpszSrc = optarg;
			break;

		case	'm':
			lpszDest = optarg;
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

	
	return	upgradeFirmware(lpszSrc, lpszDest);
}

int	loadSysInfo(sys_info_t *pSysInfo)
{
	sys_info_t	sysInfo;
	
	int hMTD = open("/dev/mtdblock0", O_RDONLY, O_NONBLOCK);
	if (hMTD < 0)
	{
		return	-1;	
	}
	
	nSize = read(hMTD, &sysInfo, sizeof(sysInfo));
	if (nSize != sizeof(sysInfo))
	{
		close(hMTD);
		return	-1;	
	}
	close(hMTD);
	
	if (sysInfo.magic != sysInfoMagic)
	{
		return	-1;	
	}

	if (sysInfo.crc32 != crc32(&sysInfo, sizeof(sysInfo) - sizeof(uint)))
	{
		return	-1;	
	}

	memcpy(pSysInfo, &sysInfo, sizeof(sysInfo));

	return	0;
}

int saveSysInfo(sys_info_t *pSysInfo)
{
	int			hMTD;
	sys_info_t	sysInfo;

	memcpy(&sysInfo, pSysInfo, sizeof(sys_info_t));
	sysInfo.crc32 = crc32(&sysInfo, sizeof(sysInfo) - sizeof(uint));
	
	hMTD = open("/dev/mtdblock0", O_RDWR, O_NONBLOCK);
	if (hMTD < 0)
	{
		return	-1;	
	}

	nSize = write(hMTD, &sysInfo, sizeof(sysInfo));
	if (nSize != sizeof(sysInfo))
	{
		return	-1;	
	}
	close(hMTD);

	return	0;
}

int	showStatus(void)
{
	pxStatus = XSD_Open(key, sizeof(STATUS));
	if (pxStatus == 0)
	{
		pxStatus = XSD_Create(key, sizeof(STATUS));
		if (pxStatus == 0)
		{
			return	-1;	
		}
	}
	
	fprintf(stdout, "%d\n", pxStatus->nProgress);

	return	0;
}

int	upgradeKernel(char *lpszSrc)
{
	sys_info_t	sysInfo;

	if (loadSysInfo(&sysInfo) != 0)
	{
		return -1;
	}

	struct stat xStat;
	if (stat (lpszSrc, &xStat) == -1)
	{
		XERROR("Source file invalid[%s]\n",	lpszSrc);
		return -1;
	}

	if (xStat.st_size <= 0)
	{
		XERROR("Source file invalid[%s]\n",	lpszSrc);
		return	-1;
	}

	int hSrc = open(lpszSrc, O_RDONLY, O_NONBLOCK);
	if (hSrc < 0)
	{
		return	-1;	
	}

	int hDest= open("/dev/mtdblock7", O_WRONLY, O_NONBLOCK);
	if (hDest < 0)
	{
		close(hSrc);
		return	-1;
	}

	char	szBuf[4096];
	int		nSize = 0;
	int		nReadSize = 0;

	while((nSize = read(hSrc, szBuf, sizeof(szBuf))) > 0)
	{

		write(hDest, szBuf, nSize);

		nReadSize += nSize;
	}

	close(hDest);
	close(hSrc);

	if (saveSysInfo(&sysInfo) != 0)
	{
		return	-1;	
	}

	return	0;
}

int	upgradeFirmware(char *lpszSrc, char *lpszDest)
{
	pxStatus = XSD_Open(key, sizeof(STATUS));
	if (pxStatus == 0)
	{
		pxStatus = XSD_Create(key, sizeof(STATUS));
		if (pxStatus == 0)
		{
			return	-1;	
		}
	}

	strncpy(pxStatus->szSrcName, lpszSrc, sizeof(pxStatus->szSrcName) - 1);
	strncpy(pxStatus->szDestName, lpszDest, sizeof(pxStatus->szDestName) - 1);
	pxStatus->nProgress = 0;

	struct stat xStat;
	if (stat (lpszSrc, &xStat) == -1)
	{
		XERROR("Source file invalid[%s]\n",	lpszSrc);
		return -1;
	}

	if (xStat.st_size <= 0)
	{
		XERROR("Source file invalid[%s]\n",	lpszSrc);
		return	-1;
	}
	pxStatus->nSize = xStat.st_size;

	int hSrc = open(lpszSrc, O_RDONLY, O_NONBLOCK);
	int hDest= open(lpszDest, O_WRONLY, O_NONBLOCK);

	if (hSrc < 0)
	{
		XERROR("Source file open failed[%s]\n", lpszSrc);
		close(hDest);
		return	-1;	
	}

	if (hDest < 0)
	{
		XERROR("Destination file open failed[%s]\n", lpszDest);
		close(hSrc);
		return	-1;	
	}

	char	szBuf[4096];
	int		nSize = 0;
	int		nReadSize = 0;

	while((nSize = read(hSrc, szBuf, sizeof(szBuf))) > 0)
	{

		write(hDest, szBuf, nSize);

		nReadSize += nSize;
		pxStatus->nProgress = (int)(nReadSize * 100 / pxStatus->nSize);
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
