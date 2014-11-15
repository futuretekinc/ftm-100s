#ifndef	__FWMNG_H__
#define	__FWMNG_H__

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
	int		index;
	uint	kernel;
	uint	rootfs;
	image_header_t	header[2];
	uint	crc32;
}	sys_info_t;

typedef	struct	
{
	char	szSrcName[256];
	char	szDestName[256];
	int		size;
	int		nProgress;
}	status_t;

typedef	enum
{
	FWT_UNKNOWN = 0,
	FWT_KERNEL,
	FWT_ROOTFS
}	fw_type_t;

typedef	struct
{
	uint32_t	primary_kernel;
	uint32_t	secondary_kernel;
	uint32_t	primary_rootfs;
	uint32_t	secondary_rootfs;
}	fwmng_config_t;

#endif

