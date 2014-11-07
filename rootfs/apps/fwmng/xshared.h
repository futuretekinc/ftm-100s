#ifndef	__XSHARED_H__
#define	__XSHARED_H__

typedef	struct
{
	key_t	xKey;
	int		nSize;
}	XSD_INFO;
	
int		XSD_Init(void);
void	*XSD_Open(key_t key, int size);
void	*XSD_Create(key_t key, int size);
int		XSD_Delete(key_t key);
int		XSD_IsExist(int nID);
void	*XSD_GetMemAddr(int nID);
#endif

