#include <stdio.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <fcntl.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include "xshared.h"
#include "debug.h"

struct flock lock, unlock;

int XSD_OpenLock(int fd, int index)
{
	lock.l_start	=	index;
	lock.l_type		=	F_WRLCK;
	lock.l_len		=	1;
	lock.l_whence	=	SEEK_SET;
	return	fcntl(fd, F_SETLKW, &lock);
}

int	XSD_CloseLock(int fd, int index)
{
	unlock.l_start	=	index;
	unlock.l_type	=	F_UNLCK;
	unlock.l_len	=	1;
	unlock.l_whence	=	SEEK_SET;
	return	fcntl(fd, F_SETLK, &unlock);
}

void XSD_InitLock(void)
{
	lock.l_start	=	0;
	lock.l_type		=	F_WRLCK;
	lock.l_len		=	1;
	lock.l_whence	=	SEEK_SET;
}

void XSD_InitUnlock(void)
{
	unlock.l_start	=	0;
	unlock.l_type	=	F_UNLCK;
	unlock.l_len	=	1;
	unlock.l_whence	=	SEEK_SET;
}

void *XSD_Create(key_t key, int size)
{
	int		nID;
	void	*pAddr;

	nID = shmget(key, size, 0666 | IPC_CREAT | IPC_EXCL);
	if (nID < 0)
	{
		XERROR("shared memory creation failed\n");
		return	NULL;	
	}

	pAddr = shmat(nID, NULL, 0);
	if (pAddr == NULL)
	{
		XERROR("A system chooses a suitable (unused) address at which to attach the segment\n");
	}
	else
	{ 
		memset(pAddr, 0, size);
	}

	return	pAddr;
}

void *XSD_Open(key_t key, int size)
{
	int		nID;

	nID = shmget(key, size, 0666);
	if (nID < 0)
	{
		XERROR("It's not found shared memory [%08x:%d]\n", key, size);
		return	NULL;	
	}

	XTRACE("It's found shared memory [%08x:%08x:%d]\n", nID, key, size);
	return	shmat(nID, NULL, 0);
}

int XSD_Delete(key_t key)
{
	return	shmctl(key, IPC_RMID, 0);
}
