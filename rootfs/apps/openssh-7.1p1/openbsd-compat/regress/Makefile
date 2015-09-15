# $Id: Makefile.in,v 1.5 2014/06/17 13:06:08 dtucker Exp $

sysconfdir=${prefix}/etc
piddir=/var/run
srcdir=.
top_srcdir=../..


CC=arm-openwrt-linux-uclibcgnueabi-gcc
LD=arm-openwrt-linux-uclibcgnueabi-ld
CFLAGS=-g -O2 -Wall -Wpointer-arith -Wuninitialized -Wsign-compare -Wformat-security -Wno-pointer-sign -Wno-unused-result -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -ftrapv -fno-builtin-memset -fPIE 
CPPFLAGS=-I. -I.. -I$(srcdir) -I$(srcdir)/.. -I/home/xtra/work/ftm-100s/rootfs/apps/build/openssl-1.0.1.e/include -I/home/xtra/work/ftm-100s/rootfs/apps/build/zlib-1.2.8/include  -DHAVE_CONFIG_H
EXEEXT=
LIBCOMPAT=../libopenbsd-compat.a
LIBS=-lcrypto -ldl -lutil -lz  -lcrypt
LDFLAGS=-L/home/xtra/work/ftm-100s/rootfs/apps/build/openssl-1.0.1.e/lib -L/home/xtra/work/ftm-100s/rootfs/apps/build/zlib-1.2.8/lib  -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -pie $(LIBCOMPAT)

TESTPROGS=closefromtest$(EXEEXT) snprintftest$(EXEEXT) strduptest$(EXEEXT) \
	strtonumtest$(EXEEXT) opensslvertest$(EXEEXT)

all:	t-exec ${OTHERTESTS}

%$(EXEEXT):	%.c $(LIBCOMPAT)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $< $(LIBCOMPAT) $(LIBS)

t-exec:	$(TESTPROGS)
	@echo running compat regress tests
	@for TEST in ""$?; do \
		echo "run test $${TEST}" ... 1>&2; \
		./$${TEST}$(EXEEXT) || exit $$? ; \
	done
	@echo finished compat regress tests

clean:
	rm -f *.o *.a core $(TESTPROGS) valid.out

distclean: clean
	rm -f Makefile *~
