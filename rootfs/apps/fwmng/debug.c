#include <stdio.h>
#include <stdarg.h>
#include "debug.h"

static int nTraceOn = 0;
static int nErrorOn = 1;

int	 XTRACE_ON(void)
{
	return nTraceOn = 1;
}

int	 XTRACE_OFF(void)
{
	return nTraceOn = 0;
}

int	 XERROR_ON(void)
{
	return nErrorOn = 1;
}

int	 XERROR_OFF(void)
{
	return nErrorOn = 0;
}

void XTRACE(const char *format, ...) 
{

	if ( nTraceOn )
	{
		va_list arglist;

		va_start(arglist, format);
		vfprintf(stderr, format, arglist);
		va_end(arglist);
	}
}

void XERROR(const char *format, ...)
{
	if ( nErrorOn )
	{
		va_list arglist;

		va_start(arglist, format);
		vfprintf(stderr, format, arglist);
		va_end(arglist);
	}
}

