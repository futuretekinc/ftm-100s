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

#ifndef EXPORT_SYMTAB
#define EXPORT_SYMTAB
#endif

#include <osdep.h>
#include <linux/if_arp.h>

#if defined(ATH_PERF_PWR_OFFLOAD) && defined(HIF_PCI)
#include "ol_if_athvar.h"
#include "ath_pci.h"
#endif

#include "if_athvar.h"
#include "if_ath_pci.h"
#include "if_bus.h"

#ifdef MAGPIE_HIF_PCI
/* WMI/HTC/HIF */
#include "ath_htc.h"
#endif


#ifndef ATH_BUS_PM
#ifdef CONFIG_PM
#define ATH_BUS_PM
#endif /* CONFIG_PM */
#endif /* ATH_BUS_PM */

#ifdef ATH_BUS_PM
#define ATH_PCI_PM_CONTROL 0x44
#endif

#ifdef AH_CAL_IN_FLASH_PCI
static u_int32_t    CalAddr[AH_CAL_RADIOS_PCI] = {AH_CAL_LOCATIONS_PCI};
#endif

#ifdef AH_CAL_IN_DRAM_PCI
static u_int32_t    CalAddr_dram[AH_CAL_RADIOS_PCI] = {AH_CAL_LOCATIONS_DRAM_PCI};
#endif

#ifdef CONFIG_CS75XX_WFO_AR9580
#include "ah_devid.h"
#include "cs_atheros_11n_wfo.h"
#endif

#if (LINUX_VERSION_CODE < KERNEL_VERSION(2,4,0))
/*
 * PCI initialization uses Linux 2.4.x version and
 * older kernels do not support this
 */
#error Atheros PCI version requires at least Linux kernel version 2.4.0
#endif /* kernel < 2.4.0 */

struct ath_pci_softc {
    struct ath_softc_net80211   aps_sc;
    struct _NIC_DEV             aps_osdev;
#ifdef ATH_BUS_PM
    u32                         aps_pmstate[16];
#endif
};

#ifdef CONFIG_CS75XX
extern unsigned int msi_enable;
#endif /* CONFIG_CS75XX */

unsigned int ahbskip = 0;
module_param(ahbskip, int, 0644);

/*
 * Use a static table of PCI id's for now.  While this is the
 * "new way" to do things, we may want to switch back to having
 * the HAL check them by defining a probe method.
 */
static struct pci_device_id ath_pci_id_table[] __devinitdata = {
    { 0x168c, 0x0007, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x0012, PCI_ANY_ID, PCI_ANY_ID },
    { 0xa727, 0x0013, PCI_ANY_ID, PCI_ANY_ID }, /* 3com */
    { 0x10b7, 0x0013, PCI_ANY_ID, PCI_ANY_ID }, /* 3com 3CRDAG675 */
    { 0x168c, 0x1014, PCI_ANY_ID, PCI_ANY_ID }, /* IBM minipci 5212 */
    { 0x168c, 0x101a, PCI_ANY_ID, PCI_ANY_ID }, /* some Griffin-Lite */
    { 0x168c, 0x0015, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x0016, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x0017, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x0018, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x0019, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x001a, PCI_ANY_ID, PCI_ANY_ID },
    { 0x168c, 0x001b, PCI_ANY_ID, PCI_ANY_ID }, /* Eagle */
#ifndef BUILD_X86
    { 0x168c, 0x001c, PCI_ANY_ID, PCI_ANY_ID }, /* Swan */
#endif
    { 0x168c, 0x001d, PCI_ANY_ID, PCI_ANY_ID }, /* Nala */
    { 0x168c, 0xff1d, PCI_ANY_ID, PCI_ANY_ID }, /* owl emulation */
    { 0x168c, 0xff1c, PCI_ANY_ID, PCI_ANY_ID }, /* owl emulation */
    { 0x168c, 0x0023, PCI_ANY_ID, PCI_ANY_ID }, /* PCI (MB/CB)   */
    { 0x168c, 0x0024, PCI_ANY_ID, PCI_ANY_ID }, /* PCI-E (XB)    */
    { 0x168c, 0x0027, PCI_ANY_ID, PCI_ANY_ID }, /* Sowl PCI      */
    { 0x168c, 0x0029, PCI_ANY_ID, PCI_ANY_ID }, /* Merlin PCI    */
    { 0x168c, 0x002a, PCI_ANY_ID, PCI_ANY_ID }, /* Merlin PCIE   */
    { 0x168c, 0x002b, PCI_ANY_ID, PCI_ANY_ID }, /* Kite PCIE     */
    { 0x168c, 0x002d, PCI_ANY_ID, PCI_ANY_ID }, /* Kiwi PCI      */
    { 0x168c, 0x002e, PCI_ANY_ID, PCI_ANY_ID }, /* Kiwi PCIE     */
    { 0x168c, 0xabcd, PCI_ANY_ID, PCI_ANY_ID }, /* Osprey PCIE Emulation   */
    { 0x168c, 0x0030, PCI_ANY_ID, PCI_ANY_ID }, /* Osprey PCIE   */
    { 0x168c, 0x0032, PCI_ANY_ID, PCI_ANY_ID }, /* Poseidon PCIE   */
    { 0x168c, 0x0033, PCI_ANY_ID, PCI_ANY_ID }, /* Peacock PCIE  */
    { 0x168c, 0x0034, PCI_ANY_ID, PCI_ANY_ID }, /* Jupiter PCIE  */
    { 0x168c, 0x003c, PCI_ANY_ID, PCI_ANY_ID }, /* Peregrine PCIE  */
    { 0 }
};

        static u_int32_t bus_ctxt_v;
        static u_int32_t reg_phy_addr;

extern int __ath_attach(u_int16_t devid, struct net_device *dev, HAL_BUS_CONTEXT *bus_context, osdev_t osdev);
extern int __ath_detach(struct net_device *dev);
extern int __ath_suspend(struct net_device *dev);
extern int __ath_resume(struct net_device *dev);

extern void init_wlan(void);

static int
ath_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    unsigned long mem;
    struct ath_pci_softc *sc;
    struct net_device *dev;
    const char *athname;
    u_int8_t csz;
    u32 val;
    HAL_BUS_CONTEXT bus_context;

#if (ATH_PERF_PWR_OFFLOAD != 0) && defined(HIF_PCI)
#define AR9888_DEVICE_ID	(0x003c)
    /* Peregrine */
    if (id->device == AR9888_DEVICE_ID) {
        return ol_ath_pci_probe(pdev, id);
    }
#endif /* ATH_PERF_PWR_OFFLOAD && HIF_PCI */

    if (pci_enable_device(pdev))
        return (-EIO);

    /* XXX 32-bit addressing only */
    if (pci_set_dma_mask(pdev, 0xffffffff)) {
        printk(KERN_ERR "ath_pci: 32-bit DMA not available\n");
        goto bad;
    }

    /*
     * Cache line size is used to size and align various
     * structures used to communicate with the hardware.
     */
    pci_read_config_byte(pdev, PCI_CACHE_LINE_SIZE, &csz);
    if (csz == 0) {
        /*
         * Linux 2.4.18 (at least) writes the cache line size
         * register as a 16-bit wide register which is wrong.
         * We must have this setup properly for rx buffer
         * DMA to work so force a reasonable value here if it
         * comes up zero.
         */
        csz = L1_CACHE_BYTES / sizeof(u_int32_t);
        pci_write_config_byte(pdev, PCI_CACHE_LINE_SIZE, csz);
    }
    /*
     * The default setting of latency timer yields poor results,
     * set it to the value used by other systems. It may be worth
     * tweaking this setting more.
     */
    pci_write_config_byte(pdev, PCI_LATENCY_TIMER, 0xa8);

    pci_set_master(pdev);

    /*
     * Disable the RETRY_TIMEOUT register (0x41) to keep
     * PCI Tx retries from interfering with C3 CPU state.
     *
     * Code taken from ipw2100 driver - jg
     */
    pci_read_config_dword(pdev, 0x40, &val);
    if ((val & 0x0000ff00) != 0)
        pci_write_config_dword(pdev, 0x40, val & 0xffff00ff);

    if (!request_mem_region(pci_resource_start(pdev, 0), pci_resource_len(pdev, 0), "ath")) {
        printk(KERN_ERR "ath_pci: cannot reserve PCI memory region\n");
        goto bad;
    }

    mem = (unsigned long) ioremap(pci_resource_start(pdev, 0), pci_resource_len(pdev, 0));
    if (!mem) {
        printk(KERN_ERR "ath_pci: cannot remap PCI memory region\n") ;
        goto bad1;
    }

    dev = alloc_netdev(sizeof(struct ath_pci_softc), "wifi%d", ether_setup);
    if (dev == NULL) {
        printk(KERN_ERR "ath_pci: no memory for device state\n");
        goto bad2;
    }
    sc = ath_netdev_priv(dev);
    sc->aps_osdev.netdev = dev;
    sc->aps_osdev.bdev = (void *) pdev;
#ifdef ATH_SUPPORT_HTC
    sc->aps_osdev.wmi_dev = (void *)sc;
#endif

#ifdef CONFIG_CS75XX
    if (msi_enable) {
       if (pci_enable_msi(pdev)) {
               printk("%s: **************** Unable to enable MSI ***************************\n", __func__ );
       }
    }
    else
       printk("%s: **************** Enabled Legacy Interrupts ***************************\n", __func__ );
#endif /* CONFIG_CS75XX */

    dev->irq = pdev->irq;
    dev->mem_start = mem;
    dev->mem_end = mem + pci_resource_len(pdev, 0);

    /*
     * Don't leave arp type as ARPHRD_ETHER as this is no eth device
     */
    dev->type = ARPHRD_IEEE80211;

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,24)
    SET_MODULE_OWNER(dev);
#endif
    SET_NETDEV_DEV(dev, &pdev->dev);

    pci_set_drvdata(pdev, dev);

#ifdef ATH_SUPPORT_HTC
    HIF_PCIDeviceInserted(&sc->aps_osdev);
    fwd_module_init(&sc->aps_osdev);

    /* HTC/HIF/WMI */
    MpHtcAttach(&sc->aps_osdev);
#endif

#ifdef AH_CAL_IN_FLASH_PCI
    bus_context.bc_info.bc_tag = (void *) CalAddr[PCI_SLOT(pdev->devfn)];
    bus_context.bc_info.cal_in_flash = 1;
#else
    bus_context.bc_info.bc_tag = NULL;
    bus_context.bc_info.cal_in_flash = 0;
#endif
#ifdef AH_CAL_IN_DRAM_PCI
    bus_context.bc_info.bc_tag = (void *) CalAddr_dram[PCI_SLOT(pdev->devfn)];
    bus_context.bc_info.cal_in_flash = 0;
#endif

    bus_context.bc_handle = (void *)dev->mem_start;
    bus_context.bc_bustype = HAL_BUS_TYPE_PCI;

#ifdef CONFIG_CS75XX_WFO_AR9580_RX
		printk("%s CONFIG_CS75XX_WFO_AR9580_RX\n", __func__);
#endif
#ifdef CONFIG_CS75XX_WFO_AR9580_TX
		printk("%s CONFIG_CS75XX_WFO_AR9580_TX\n", __func__);
#endif

#ifdef CONFIG_CS75XX_WFO_AR9580
    printk("%s CONFIG_CS75XX_WFO_AR9580 \n", __func__);

    printk("\t %s  struct ath_pci_softc *sc=%p sc->aps_osdev.netdev=%p %s sc->aps_osdev.bdev=%p pdev=%p phy_addr start=%x start=%x \n",
        __func__, sc, dev, dev->name, sc->aps_osdev.bdev, pdev,pci_resource_start(pdev, 0),  pdev->resource[0].start);

    printk("\t %s ath_netdev_priv(dev)=%p  sc->aps_sc=%p sc->aps_sc.sc_dev=%p \n",
        __func__,  ath_netdev_priv(dev), &sc->aps_sc,  sc->aps_sc.sc_dev);
    sc->aps_sc.wfo_enabled = 0;
    if ((id->device == AR9300_DEVID_AR9380_PCIE) ||(id->device == AR9300_DEVID_AR9580_PCIE)) {
        if (CS_AR9580_WFO_PNI_init(ath_netdev_priv(dev), pdev->resource[0].start, pdev->resource[0].end)
			 == 0)
			 goto bad3;
    }
#endif

    if (__ath_attach(id->device, dev, &bus_context, &sc->aps_osdev) != 0)
        goto bad3;

    athname = ath_hal_probe(id->vendor, id->device);

    {
        HAL_BUS_HANDLE bus_ctxt = &bus_ctxt_v;
        u_int32_t size;
        ath_hal_getdiagstate(
            ((struct ath_softc *)(sc->aps_sc.sc_dev))->sc_ah,
            HAL_DIAG_GET_REGBASE, 0, 0, &bus_ctxt, &size);

        printk(KERN_INFO "%s: %s: mem=0x%llx, irq=%d hw_base=0x%p\n",
               dev->name, athname ? athname : "Atheros ???", (unsigned long long)pci_resource_start(pdev, 0),
               dev->irq, (void *)bus_ctxt_v);
        reg_phy_addr=(u_int32_t)pci_resource_start(pdev,0);
    }

    return 0;
bad3:
    free_netdev(dev);
bad2:
    iounmap((void *) mem);
bad1:
    release_mem_region(pci_resource_start(pdev, 0), pci_resource_len(pdev, 0));
bad:
    pci_disable_device(pdev);
    return (-ENODEV);
}

static u_int32_t
get_pci_reg_addr()
{
  return reg_phy_addr;;
}

static u_int32_t
get_pci_virt_addr()
{
  return bus_ctxt_v;
}
static void
ath_pci_remove(struct pci_dev *pdev)
{
    struct net_device *dev = pci_get_drvdata(pdev);
    u16 val;

#ifdef MAGPIE_HIF_PCI
    struct ath_pci_softc *sc = ath_netdev_priv(dev);
    struct _NIC_DEV *os_hdl = &sc->aps_osdev;

    /* HTC/HIF/WMI */
    MpHtcDetach(os_hdl);
    HIF_PCIDeviceDetached((void*)os_hdl);
#endif

#if (ATH_PERF_PWR_OFFLOAD != 0) && defined(HIF_PCI)
    /* Peregrine */
    if (pdev->device == AR9888_DEVICE_ID) {
        ol_ath_pci_remove(pdev);
        return;
    }
#endif /* ATH_PERF_PWR_OFFLOAD && HIF_PCI */
    /*
     * Do a config read to clear pre-existing pci error status.
     * Merlin WAR for bug# 34991.
     */
    pci_read_config_word(pdev, PCI_COMMAND, &val);

#ifdef CONFIG_CS75XX
#ifndef ATH_SUPPORT_HTC
    if (dev->irq)
       {
        free_irq(dev->irq, dev);
               dev->irq = 0;
       }
#endif
       if (pdev->msi_enabled == 1)
               pci_disable_msi(pdev);
#endif /* CONFIG_CS75XX */
    __ath_detach(dev);
    iounmap((void *) dev->mem_start);
    release_mem_region(pci_resource_start(pdev, 0),
               pci_resource_len(pdev, 0));
    pci_disable_device(pdev);
    free_netdev(dev);
}

#ifdef ATH_BUS_PM
static int
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,10)
ath_pci_suspend(struct pci_dev *pdev, pm_message_t state)
#else
ath_pci_suspend(struct pci_dev *pdev, u32 state)
#endif
{
    struct net_device *dev = pci_get_drvdata(pdev);
    u32 val;

#if (ATH_PERF_PWR_OFFLOAD != 0) && defined(HIF_PCI)
    /* Peregrine */
    if (pdev->device == AR9888_DEVICE_ID) {
        if(ol_ath_pci_suspend(pdev, state)) {
            return (-1);
        }
        return 0;
    }
#endif /* ATH_PERF_PWR_OFFLOAD && HIF_PCI */
     __ath_suspend(dev);

    /* pci_set_power_state may use PCI word access, which don't
     * seem to work always, so do a dword access */
    //    pci_set_power_state(pdev, 3);
    pci_read_config_dword(pdev, ATH_PCI_PM_CONTROL, &val);
    if ((val & 0x000000ff) != 0x3) {
    PCI_SAVE_STATE(pdev,
        ((struct ath_pci_softc *)ath_netdev_priv(dev))->aps_pmstate);
    pci_disable_device(pdev);
        pci_write_config_dword(pdev, ATH_PCI_PM_CONTROL, (val & 0xffffff00) | 0x03);
    }

    return 0;
}

static int
ath_pci_resume(struct pci_dev *pdev)
{
    struct net_device *dev = pci_get_drvdata(pdev);

    u32 val;
    int err;

#if (ATH_PERF_PWR_OFFLOAD != 0) && defined(HIF_PCI)
    /* Peregrine */
    if (pdev->device == AR9888_DEVICE_ID) {
        if (ol_ath_pci_resume(pdev)) {
            return (-1);
        }
        return 0;
    }
#endif /* ATH_PERF_PWR_OFFLOAD && HIF_PCI */


    err = pci_enable_device(pdev);
    if (err)
	return err;

    pci_read_config_dword(pdev, ATH_PCI_PM_CONTROL, &val);
    if ((val & 0x000000ff) != 0) {
    PCI_RESTORE_STATE(pdev,
        ((struct ath_pci_softc *)ath_netdev_priv(dev))->aps_pmstate);

      pci_write_config_dword(pdev, ATH_PCI_PM_CONTROL, val & 0xffffff00);

    /*
     * Suspend/Resume resets the PCI configuration space, so we have to
     * re-disable the RETRY_TIMEOUT register (0x41) to keep
     * PCI Tx retries from interfering with C3 CPU state
     *
     * Code taken from ipw2100 driver - jg
     */
    pci_read_config_dword(pdev, 0x40, &val);
    if ((val & 0x0000ff00) != 0)
        pci_write_config_dword(pdev, 0x40, val & 0xffff00ff);
    __ath_resume(dev);
    }

    return 0;
}
#endif /* ATH_BUS_PM */

MODULE_DEVICE_TABLE(pci, ath_pci_id_table);

//static struct pci_driver ath_pci_drv_id = {
struct pci_driver ath_pci_drv_id = {
    .name       = "ath_pci",
    .id_table   = ath_pci_id_table,
    .probe      = ath_pci_probe,
    .remove     = ath_pci_remove,
#ifdef ATH_BUS_PM
    .suspend    = ath_pci_suspend,
    .resume     = ath_pci_resume,
#endif /* ATH_BUS_PM */
    /* Linux 2.4.6 has save_state and enable_wake that are not used here */
};

/*
 * Module glue.
 */
#include "version.h"
static char *version = ATH_PCI_VERSION " (Atheros/multi-bss)";
static char *dev_info = "ath_pci";

void pci_defer_reconnect(struct work_struct *pci_reconnect_work)
{
#ifdef notyet
#ifdef CONFIG_SYSCTL
    ath_sysctl_unregister();
#endif
#endif
    pci_unregister_driver(&ath_pci_drv_id);

    if (pci_register_driver(&ath_pci_drv_id) < 0)
        printk("ath_pci: No devices found, driver not installed.\n");

#ifdef notyet
#ifdef CONFIG_SYSCTL
    ath_sysctl_register();
#endif
#endif

}

#include <linux/ethtool.h>

int
ath_ioctl_ethtool(struct ath_softc_net80211 *sc, int cmd, void *addr)
{
    struct ethtool_drvinfo info;

    if (cmd != ETHTOOL_GDRVINFO)
        return -EOPNOTSUPP;
    memset(&info, 0, sizeof(info));
    info.cmd = cmd;
    strncpy(info.driver, dev_info, sizeof(info.driver)-1);
    strncpy(info.version, version, sizeof(info.version)-1);
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,4,22)
    /* include the device name so later versions of kudzu DTRT */
    strncpy(info.bus_info, pci_name((struct pci_dev *)sc->sc_osdev->bdev),
        sizeof(info.bus_info)-1);
#endif
    return _copy_to_user(addr, &info, sizeof(info)) ? -EFAULT : 0;
}

MODULE_AUTHOR("Errno Consulting, Sam Leffler");
MODULE_DESCRIPTION("Support for Atheros 802.11 wireless LAN cards.");
MODULE_SUPPORTED_DEVICE("Atheros WLAN cards");
#ifdef MODULE_LICENSE
MODULE_LICENSE("Dual BSD/GPL");
#endif

#if defined(CONFIG_KGDB)
unsigned int initbrk = 0;
module_param(initbrk, int, 0644);
#endif

static int __init
init_ath_pci(void)
{

#ifdef ATH_AHB
    int pciret = 0, ahbret = 0;
    int init_ath_ahb(void);
#endif

#if defined(CONFIG_KGDB)
    if (initbrk) {
        extern void kgdb_breakpoint(void);
        kgdb_breakpoint();
    }
#endif

#ifdef ATH_AHB
    if(ahbskip!=1)
    {
        ahbret = init_ath_ahb();
    }
    else
    {
        printk("%s[%d]  By pass AHB bus scan\n",__func__,__LINE__);
    }
#endif

    printk(KERN_INFO "%s: %s\n", dev_info, version);

    /* Init wlan reg params */
    init_wlan();



    if (pci_register_driver(&ath_pci_drv_id) < 0) {
        printk("ath_pci: No devices found, driver not installed.\n");
        pci_unregister_driver(&ath_pci_drv_id);
#ifdef ATH_AHB
    if(ahbskip!=1)
    {
        pciret = -ENODEV;
    } else {
        return (-ENODEV);
    }
#else
        return (-ENODEV);
#endif
    }

#ifdef notyet
#ifdef CONFIG_SYSCTL
    ath_sysctl_register();
#endif
#endif

#ifdef ATH_AHB
    /*
     * Return failure only when there is no wlan device
     * on both pci and ahb buses.
     */
    if(ahbskip!=1)
    {
        if (ahbret && pciret) {
            /* which error takes priority ?? */
            return ahbret;
        }
    }
#endif

    return 0;
}
module_init(init_ath_pci);

static void __exit
exit_ath_pci(void)
{
#ifdef notyet
#ifdef CONFIG_SYSCTL
    ath_sysctl_unregister();
#endif
#endif

    pci_unregister_driver(&ath_pci_drv_id);

#ifdef ATH_AHB

    {
        void exit_ath_ahb(void);
        exit_ath_ahb();
    }

#else
    printk(KERN_INFO "%s: driver unloaded\n", dev_info);
#endif /* ATH_AHB */

}
module_exit(exit_ath_pci);
EXPORT_SYMBOL(pci_defer_reconnect);
EXPORT_SYMBOL(get_pci_reg_addr);
EXPORT_SYMBOL(get_pci_virt_addr);
