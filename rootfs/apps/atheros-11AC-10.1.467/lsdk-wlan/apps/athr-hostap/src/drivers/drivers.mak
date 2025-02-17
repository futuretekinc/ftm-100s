##### CLEAR VARS

DRV_CFLAGS =
DRV_WPA_CFLAGS =
DRV_AP_CFLAGS =
DRV_OBJS =
DRV_WPA_OBJS =
DRV_AP_OBJS =
DRV_LIBS =
DRV_WPA_LIBS =
DRV_AP_LIBS =

##### COMMON DRIVERS

ifdef CONFIG_DRIVER_WIRED
DRV_CFLAGS += -DCONFIG_DRIVER_WIRED
DRV_OBJS += ../src/drivers/driver_wired.o
endif

ifdef CONFIG_DRIVER_NL80211
DRV_CFLAGS += -DCONFIG_DRIVER_NL80211
DRV_OBJS += ../src/drivers/driver_nl80211.o
DRV_OBJS += ../src/utils/radiotap.o
NEED_SME=y
NEED_AP_MLME=y
NEED_NETLINK=y
NEED_LINUX_IOCTL=y
NEED_RFKILL=y

ifdef CONFIG_LIBNL32
  DRV_LIBS += -lnl-3
  DRV_LIBS += -lnl-genl-3
  DRV_CFLAGS += -DCONFIG_LIBNL20
else
  ifdef CONFIG_LIBNL_TINY
    DRV_LIBS += -lnl-tiny
  else
    DRV_LIBS += -lnl
  endif

  ifdef CONFIG_LIBNL20
    DRV_LIBS += -lnl-genl
    DRV_CFLAGS += -DCONFIG_LIBNL20
  endif
endif
endif

ifdef CONFIG_DRIVER_BSD
ifndef CONFIG_L2_PACKET
CONFIG_L2_PACKET=freebsd
endif
DRV_CFLAGS += -DCONFIG_DRIVER_BSD
DRV_OBJS += ../src/drivers/driver_bsd.o
CONFIG_L2_FREEBSD=y
CONFIG_DNET_PCAP=y
endif

ifdef CONFIG_DRIVER_TEST
DRV_CFLAGS += -DCONFIG_DRIVER_TEST
DRV_OBJS += ../src/drivers/driver_test.o
NEED_AP_MLME=y
endif

ifdef CONFIG_DRIVER_NONE
DRV_CFLAGS += -DCONFIG_DRIVER_NONE
DRV_OBJS += ../src/drivers/driver_none.o
endif

##### PURE AP DRIVERS

ifdef CONFIG_DRIVER_HOSTAP
DRV_AP_CFLAGS += -DCONFIG_DRIVER_HOSTAP
DRV_AP_OBJS += ../src/drivers/driver_hostap.o
CONFIG_WIRELESS_EXTENSION=y
NEED_AP_MLME=y
NEED_NETLINK=y
NEED_LINUX_IOCTL=y
endif

ifdef CONFIG_DRIVER_MADWIFI
DRV_AP_CFLAGS += -DCONFIG_DRIVER_MADWIFI
DRV_AP_OBJS += ../src/drivers/driver_madwifi.o
CONFIG_WIRELESS_EXTENSION=y
CONFIG_L2_PACKET=linux
NEED_NETLINK=y
NEED_LINUX_IOCTL=y
endif

ifdef CONFIG_DRIVER_ATHEROS
DRV_AP_CFLAGS += -DCONFIG_DRIVER_ATHEROS
DRV_AP_OBJS += ../src/drivers/driver_atheros.o
CONFIG_L2_PACKET=linux
NEED_NETLINK=y
NEED_LINUX_IOCTL=y
endif

##### PURE CLIENT DRIVERS

ifdef CONFIG_DRIVER_WEXT
DRV_WPA_CFLAGS += -DCONFIG_DRIVER_WEXT
CONFIG_WIRELESS_EXTENSION=y
NEED_NETLINK=y
NEED_LINUX_IOCTL=y
NEED_RFKILL=y
endif

ifdef CONFIG_DRIVER_NDIS
DRV_WPA_CFLAGS += -DCONFIG_DRIVER_NDIS
DRV_WPA_OBJS += ../src/drivers/driver_ndis.o
ifdef CONFIG_NDIS_EVENTS_INTEGRATED
DRV_WPA_OBJS += ../src/drivers/driver_ndis_.o
endif
ifndef CONFIG_L2_PACKET
CONFIG_L2_PACKET=pcap
endif
CONFIG_WINPCAP=y
ifdef CONFIG_USE_NDISUIO
DRV_WPA_CFLAGS += -DCONFIG_USE_NDISUIO
endif
endif

ifdef CONFIG_DRIVER_ROBOSWITCH
DRV_WPA_CFLAGS += -DCONFIG_DRIVER_ROBOSWITCH
DRV_WPA_OBJS += ../src/drivers/driver_roboswitch.o
endif

ifdef CONFIG_DRIVER_ATHROSX
DRV_WPA_CFLAGS += -DCONFIG_DRIVER_ATHROSX
DRV_WPA_OBJS += ../src/drivers/driver_athrosx.o
endif

ifdef CONFIG_DRIVER_ATHR
DRV_WPA_CFLAGS += -DCONFIG_DRIVER_ATHR
DRV_WPA_OBJS += ../src/drivers/driver_athr.o
CONFIG_L2_PACKET=linux
CONFIG_WIRELESS_EXTENSION=y
NEED_LINUX_IOCTL=y
NEED_NETLINK=y
endif

ifdef CONFIG_WIRELESS_EXTENSION
DRV_WPA_CFLAGS += -DCONFIG_WIRELESS_EXTENSION
DRV_WPA_OBJS += ../src/drivers/driver_wext.o
NEED_RFKILL=y
endif

ifdef NEED_NETLINK
DRV_OBJS += ../src/drivers/netlink.o
endif

ifdef NEED_LINUX_IOCTL
DRV_OBJS += ../src/drivers/linux_ioctl.o
endif

ifdef NEED_RFKILL
DRV_OBJS += ../src/drivers/rfkill.o
endif


##### COMMON VARS
DRV_BOTH_CFLAGS := $(DRV_CFLAGS) $(DRV_WPA_CFLAGS) $(DRV_AP_CFLAGS)
DRV_WPA_CFLAGS += $(DRV_CFLAGS)
DRV_AP_CFLAGS += $(DRV_CFLAGS)

DRV_BOTH_LIBS := $(DRV_LIBS) $(DRV_WPA_LIBS) $(DRV_AP_LIBS)
DRV_WPA_LIBS += $(DRV_LIBS)
DRV_AP_LIBS += $(DRV_LIBS)

DRV_BOTH_OBJS := $(DRV_OBJS) $(DRV_WPA_OBJS) $(DRV_AP_OBJS)
DRV_WPA_OBJS += $(DRV_OBJS)
DRV_AP_OBJS += $(DRV_OBJS)

DRV_BOTH_LDFLAGS := $(DRV_LDFLAGS) $(DRV_WPA_LDFLAGS) $(DRV_AP_LDFLAGS)
DRV_WPA_LDFLAGS += $(DRV_LDFLAGS)
DRV_AP_LDFLAGS += $(DRV_LDFLAGS)
