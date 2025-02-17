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

#ifndef _HW_DEF_H
#define _HW_DEF_H

/*
 * Atheros-specific
 */
typedef enum {
    ANTENNA_CONTROLLABLE,
    ANTENNA_FIXED_A,
    ANTENNA_FIXED_B,
    ANTENNA_DUMMY_MAX
} ANTENNA_CONTROL;

/* 
 * Number of (OEM-defined) functions using GPIO pins currently defined 
 *
 * Function 0: Link/Power LED
 * Function 1: Network/Activity LED
 * Function 2: Connection LED
 */
#define NUM_GPIO_FUNCS             3

/*
** Default cache line size, in bytes.
** Used when PCI device not fully initialized by bootrom/BIOS
*/

#define DEFAULT_CACHELINE	32

#if defined(CONFIG_ARM) && (LINUX_VERSION_CODE < KERNEL_VERSION(2,6,28))

/*
** This was borrowed from NETBSD.  Not very atomic
*/

#ifndef CONFIG_CS75XX
static INLINE int32_t cmpxchg(int32_t *_patomic_arg, int32_t _comparand, int32_t _exchange)
{
    if(*(_patomic_arg) == _comparand)
    {
         *(_patomic_arg) = _exchange;
         return _comparand;
    }
    return (*_patomic_arg);
}

#endif /* ! CONFIG_CS75XX */

#endif 

#endif
