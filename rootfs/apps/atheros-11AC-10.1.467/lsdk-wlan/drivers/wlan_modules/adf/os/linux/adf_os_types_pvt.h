/*
 * Copyright (c) 2010, Atheros Communications Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef _ADF_CMN_OS_TYPES_PVT_H
#define _ADF_CMN_OS_TYPES_PVT_H

#ifndef __KERNEL__
#define __iomem
#else
#include <linux/types.h>
#endif

#include <asm/types.h>
#include <asm/byteorder.h>
#include <linux/version.h>
#include <linux/kconfig.h>

#ifdef __KERNEL__
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 33)
#include <linux/autoconf.h>
#else
#include <generated/autoconf.h>
#endif
#endif
#include <linux/compiler.h>
#include <linux/dma-mapping.h>
#include <linux/wireless.h>
#include <linux/if.h>
#else
/*
 * Provide dummy defs for kernel data types, functions, and enums
 * used in this header file.
 */

/*
 * Hack - coexist with prior defs of dma_addr_t.
 * Eventually all other defs of dma_addr_t should be removed.
 * At that point, the "already_defined" wrapper can be removed.
 */
#ifndef __dma_addr_t_already_defined__
#define __dma_addr_t_already_defined__
typedef u_int32_t* dma_addr_t;
#endif

#define uint64_t u_int64_t
#define uint32_t u_int32_t
#define uint16_t u_int16_t
#define uint8_t  u_int8_t
#define SIOCGIWAP       0
#define IWEVCUSTOM      0
#define IWEVREGISTERED  0
#define IWEVEXPIRED     0
#define SIOCGIWSCAN     0
#define DMA_TO_DEVICE   0
#define DMA_FROM_DEVICE 0
#endif /* __KERNEL__ */

/**
 * max sg that we support
 */
#define __ADF_OS_MAX_SCATTER        1
#define __ADF_OS_NAME_SIZE          IFNAMSIZ

#if defined(__LITTLE_ENDIAN_BITFIELD)
#define ADF_LITTLE_ENDIAN_MACHINE
#elif defined (__BIG_ENDIAN_BITFIELD)
#define ADF_BIG_ENDIAN_MACHINE
#else
#error  "Please fix <asm/byteorder.h>"
#endif

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,20) || !defined(__KERNEL__)
#ifndef __bool_already_defined__
#define __bool_already_defined__
/* boolean */
typedef enum bool {
    false = 0,
    true  = 1,
} bool;
#endif /* __bool_already_defined__ */
#endif

#define __adf_os_packed          __attribute__ ((packed))

#define __adf_os_ull(_num)  _num ## ULL

struct __adf_net_drv;

typedef int (*__adf_os_intr)(void *);
/**
 * Private definitions of general data types
 */
typedef dma_addr_t              __adf_os_dma_addr_t;
typedef size_t                  __adf_os_dma_size_t;
typedef dma_addr_t              __adf_os_dma_context_t;

#define adf_os_dma_mem_context(context) dma_addr_t   context
#define adf_os_get_dma_mem_context(var, field)   ((adf_os_dma_context_t)&(var->field))


typedef enum __adf_os_cache_sync{
    __ADF_SYNC_PREREAD,
    __ADF_SYNC_PREWRITE,
    __ADF_SYNC_POSTREAD,
    __ADF_SYNC_POSTWRITE
}__adf_os_cache_sync_t;

typedef struct __adf_os_resource{
    unsigned long   paddr;
    void __iomem *  vaddr;
    unsigned long   len;
}__adf_os_resource_t;

/**
 * generic data types
 */
struct __adf_device  {
    void                   *drv;
    void                   *drv_hdl;
    char                   *drv_name;
    int                    irq;
    struct device          *dev;
    __adf_os_resource_t    res;
    __adf_os_intr          func;/*Interrupt handler*/
}; 

typedef struct __adf_device *__adf_os_device_t;

typedef size_t            __adf_os_size_t;
typedef off_t             __adf_os_off_t;
typedef uint8_t __iomem * __adf_os_iomem_t;

typedef struct __adf_os_segment{
    dma_addr_t  daddr;
    uint32_t    len; 
}__adf_os_segment_t;

struct __adf_os_dma_map{
    uint32_t                mapped;
    uint32_t                nsegs;
    uint32_t                coherent;
    __adf_os_segment_t      seg[__ADF_OS_MAX_SCATTER];
};
typedef struct  __adf_os_dma_map  *__adf_os_dma_map_t;
typedef uint32_t  ath_dma_addr_t;
typedef uint8_t           __a_uint8_t;
typedef int8_t            __a_int8_t;
typedef uint16_t          __a_uint16_t;
typedef int16_t           __a_int16_t; 
typedef uint32_t          __a_uint32_t;
typedef int32_t           __a_int32_t;
typedef uint64_t          __a_uint64_t;
typedef int64_t           __a_int64_t;

enum __adf_net_wireless_evcode{
    __ADF_IEEE80211_ASSOC = SIOCGIWAP,
    __ADF_IEEE80211_REASSOC =IWEVCUSTOM,
    __ADF_IEEE80211_DISASSOC = SIOCGIWAP,
    __ADF_IEEE80211_JOIN = IWEVREGISTERED,
    __ADF_IEEE80211_LEAVE = IWEVEXPIRED,
    __ADF_IEEE80211_SCAN = SIOCGIWSCAN,
    __ADF_IEEE80211_REPLAY = IWEVCUSTOM,
    __ADF_IEEE80211_MICHAEL = IWEVCUSTOM,
    __ADF_IEEE80211_REJOIN = IWEVCUSTOM, 
    __ADF_CUSTOM_PUSH_BUTTON = IWEVCUSTOM,
};

#define __adf_os_print               printk
#define __adf_os_vprint              vprintk
#define __adf_os_snprint             snprintf
#define __adf_os_vsnprint            vsnprintf

#define __ADF_OS_DMA_TO_DEVICE      DMA_TO_DEVICE
#ifndef __ubicom32__
#define __ADF_OS_DMA_FROM_DEVICE    DMA_FROM_DEVICE
#else
#define __ADF_OS_DMA_FROM_DEVICE    DMA_TO_DEVICE
#endif
#define __adf_os_inline            inline

#endif /*_ADF_CMN_OS_TYPES_PVT_H*/
