#include <linux/netdevice.h>
#include "osif_private.h"

void wlan_pltfrm_attach(struct net_device *dev){};
void wlan_pltfrm_detach(struct net_device *dev){};
void osif_pltfrm_create_vap(osif_dev *osifp){};
void osif_pltfrm_delete_vap(osif_dev *osifp){};

#ifdef CONFIG_CS75XX_WOT
extern int wot_queue_dispatch(osif_dev  *osifp, int q);
#endif

#define OSIF_TO_NETDEV(_osif) (((osif_dev *)(_osif))->netdev)
 void osif_pltfrm_receive (os_if_t osif, wbuf_t wbuf,
                          u_int16_t type, u_int16_t subtype,
                          ieee80211_recv_status *rs)
{
    struct net_device *dev = OSIF_TO_NETDEV(osif);
    struct sk_buff *skb = (struct sk_buff *)wbuf;
#if defined(ATH_SUPPORT_VLAN) || defined(CONFIG_CS75XX_WOT)
    osif_dev  *osifp = (osif_dev *) osif;
#endif

    if (type != IEEE80211_FC0_TYPE_DATA) {
        wbuf_free(wbuf);
        return;
    }

    skb->dev = dev;

#ifdef USE_HEADERLEN_RESV
    skb->protocol = ath_eth_type_trans(skb, dev);
#else
    skb->protocol = eth_type_trans(skb, dev);
#endif
#if ATH_SUPPORT_VLAN
    if ( osifp->vlanID != 0 && osifp->vlgrp != NULL)
    {
        /* attach vlan tag */
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,36)
        vlan_hwaccel_rx(skb, osifp->vlgrp, osifp->vlanID);
#else
        __vlan_hwaccel_put_tag(skb, osifp->vlanID);
#endif
    }
    else
#endif
#ifdef CONFIG_CS75XX_WOT		/* Dispatch RX processing to CPU#1*/
    if(skb_queue_len(&osifp->pending_rx)>12288) { /* Drop if too many pending frame */
			dev_kfree_skb_any(skb);
    } else {
	    skb_queue_tail(&osifp->pending_rx , skb);
	    if(wot_queue_dispatch(osifp, 0))
        	printk("failed to enqueue skb on CPU#1\n");
    }
#else
    netif_rx(skb);
#endif
    dev->last_rx = jiffies;
}

int wlan_pltfrm_set_param(wlan_if_t vaphandle, u_int32_t val)
{
   return 0;
}

int wlan_pltfrm_get_param(wlan_if_t vaphandle)
{
   return 0;
}

void osif_pltfrm_record_macinfor(unsigned char unit, unsigned char* mac)
{
}

void osif_pltfrm_vlan_feature_set(struct net_device *dev)
{
                dev->features |= NETIF_F_HW_VLAN_TX | NETIF_F_HW_VLAN_RX |
                        NETIF_F_HW_VLAN_FILTER;
}

DEFINE_SPINLOCK(pltfrm_pciwar_lock);
void
WAR_PLTFRM_PCI_WRITE32(char *addr, u32 offset, u32 value, unsigned int war1)
{

   if (war1) {
        unsigned long irq_flags;

        spin_lock_irqsave(&pltfrm_pciwar_lock, irq_flags);

        (void)ioread32((void __iomem *)(addr+offset+4)); /* 3rd read prior to write */
        (void)ioread32((void __iomem *)(addr+offset+4)); /* 2nd read prior to write */
        (void)ioread32((void __iomem *)(addr+offset+4)); /* 1st read prior to write */
        iowrite32((u32)(value), (void __iomem *)(addr+offset));

	spin_unlock_irqrestore(&pltfrm_pciwar_lock, irq_flags);

    } else {
        iowrite32((u32)(value), (void __iomem *)(addr+offset));
    }
}

#if ATH_PERF_PWR_OFFLOAD
void
osif_pltfrm_deliver_data_ol(os_if_t osif, struct sk_buff *skb_list)
{
    struct net_device *dev = OSIF_TO_NETDEV(osif);
#if defined(ATH_SUPPORT_VLAN) || defined(CONFIG_CS75XX_WOT)
    osif_dev  *osifp = (osif_dev *) osif;
#endif
#if ATH_RXBUF_RECYCLE
    struct net_device *comdev;
    struct ath_softc_net80211 *scn;
    struct ath_softc *sc;
#endif /* ATH_RXBUF_RECYCLE */

#if ATH_RXBUF_RECYCLE
    comdev = ((osif_dev *)osif)->os_comdev;
    scn = ath_netdev_priv(comdev);
    sc = ATH_DEV_TO_SC(scn->sc_dev);
#endif /* ATH_RXBUF_RECYCLE */

    while (skb_list) {
        struct sk_buff *skb;

        skb = skb_list;
        skb_list = skb_list->next;

        skb->dev = dev;

#ifdef USE_HEADERLEN_RESV
        skb->protocol = ath_eth_type_trans(skb, dev);
#else
        skb->protocol = eth_type_trans(skb, dev);
#endif

#if ATH_RXBUF_RECYCLE
	    /*
	     * Do not recycle the received mcast frame b/c it will be cloned twice
	     */
        if (sc->sc_osdev->rbr_ops.osdev_wbuf_collect && !(wbuf_is_cloned(skb)))
        {
            sc->sc_osdev->rbr_ops.osdev_wbuf_collect((void *)sc, (void *)skb);
        }
#endif /* ATH_RXBUF_RECYCLE */
#if ATH_SUPPORT_VLAN
        if ( osifp->vlanID != 0 && osifp->vlgrp != NULL)
        {
            /* attach vlan tag */
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,36)
        vlan_hwaccel_rx(skb, osifp->vlgrp, osifp->vlanID);
#else
        __vlan_hwaccel_put_tag(skb, osifp->vlanID);
#endif
        }
        else
#endif
#ifdef ATH_SUPPORT_HTC
        if (in_interrupt())
            netif_rx(skb);
        else
        netif_rx_ni(skb);
#else
#ifdef CONFIG_CS75XX_WOT		/* Dispatch RX processing to another CPU */
		if(skb_queue_len(&osifp->pending_rx)>16384) {
			dev_kfree_skb_any(skb);
			continue;
		}
		skb_queue_tail(&osifp->pending_rx , skb);
		if(wot_queue_dispatch(osifp, 0))
			printk("failed to enqueue skb on CPU#1\n");
#else
        	//netif_rx(skb);
        	netif_receive_skb(skb);
#endif

#endif
    }
    dev->last_rx = jiffies;
}
#endif /* ATH_PERF_PWR_OFFLOAD */


