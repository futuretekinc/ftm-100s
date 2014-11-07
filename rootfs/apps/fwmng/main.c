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

static struct option long_options[] =
{
};


int main(int argc, char *argv[])
{
	char	*lpszSrc;
	char	*lpszDest;
	int		opt, opt_idx;

	while((opt = getopt_long(argc, argv, "si: o: vV", long_options, &opt_idx)) != -1)
	{
		switch(opt)
		{
		case	's':
			return showStatus();

		case	'i':
			lpszSrc = optarg;
			break;

		case	'o':
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
