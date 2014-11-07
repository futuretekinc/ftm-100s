#ifndef	__DEBUG_H__
#define	__DEBUG_H__
#include <errno.h>
#include <syslog.h>

#ifdef DEBUG
	int	 XTRACE_ON(void);
	int	 XTRACE_OFF(void);
	void XTRACE(const char *format, ...) ;
	int	 XERROR_ON(void);
	int	 XERROR_OFF(void);
	void XERROR(const char *format, ...) ;
#else
	#define	XTRACE_ON()
	#define	XTRACE_OFF()
	#define	XTRACE(format, ...) 
	#define	XERROR_ON()
	#define	XERROR_OFF()
	#define	XTRACE(format, ...) 
	#define	XERROR(format, ...) 
#endif

#define	XSYSLOG(foramt, ...) syslog(LOG_INFO|LOG_LOCAL0, format, ## __VA_ARGS )
#endif
