#if UMAC_SUPPORT_PROXY_ARP

#include <net/arp.h>    /* arp_send */
#include <net/ip.h>   /* ipv6 */
#include <net/ipv6.h>   /* ipv6 */
#include <net/ndisc.h>  /* ipv6 ndp */

#include "osif_private.h"
#include <wlan_opts.h>
#include <ieee80211_var.h>
#include "if_athvar.h"

#define OSIF_TO_NETDEV(_osif) (((osif_dev *)(_osif))->netdev)

struct dhcp_packet {            /* BOOTP/DHCP packet format */
        struct iphdr iph;       /* IP header */
        struct udphdr udph;     /* UDP header */
        u8 op;                  /* 1=request, 2=reply */
        u8 htype;               /* HW address type */
        u8 hlen;                /* HW address length */
        u8 hops;                /* Used only by gateways */
        u32 xid;             /* Transaction ID */
        u16 secs;            /* Seconds since we started */
        u16 flags;           /* Just what it says */
        u32 client_ip;       /* Client's IP address if known */
        u32 your_ip;         /* Assigned IP address */
        u32 server_ip;       /* (Next, e.g. NFS) Server's IP address */
        u32 relay_ip;        /* IP address of BOOTP relay */
        u8 hw_addr[16];         /* Client's HW address */
        u8 serv_name[64];       /* Server host name */
        u8 boot_file[128];      /* Name of boot file */
        u8 exten[312];          /* DHCP options / BOOTP vendor extensions */
}; /* packed naturally */

static const u8 ic_bootp_cookie[4] = { 99, 130, 83, 99 };

#define DHCPOFFER   2
#define DHCPACK     5

static inline int ipv6_addr_is_multicast(const struct in6_addr *addr)
{           
    return (addr->s6_addr32[0] & htonl(0xFF000000)) == htonl(0xFF000000);
}

static u8 *ipv6_ndisc_opt_lladdr(u8 *opt, int optlen, int src)
{
    struct nd_opt_hdr *ndopt = (struct nd_opt_hdr *)opt;
    int len;

    while (optlen) {
        if (optlen < sizeof(struct nd_opt_hdr))
            return NULL;

        len = ndopt->nd_opt_len << 3;
        if (optlen < len || len == 0)
            return NULL;

        switch (ndopt->nd_opt_type) {
        case ND_OPT_TARGET_LL_ADDR:
            if (!src) {
                return (u8 *)(ndopt + 1);
            }

            break;
        case ND_OPT_SOURCE_LL_ADDR:
            if (src) {
                return (u8 *)(ndopt + 1);
            }

            break;

        default:
            break;
        }
        optlen -= len;
        ndopt = (void *)ndopt + len;
    }

    return NULL;
}

#ifdef CONFIG_CS75XX
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(3,4,11))
#define LL_ALLOCATED_SPACE(dev) \
	        ((((dev)->hard_header_len+(dev)->needed_headroom+(dev)->needed_tailroom)&~(HH_DATA_MOD - 1)) + HH_DATA_MOD)

static inline void ipv6_addr_copy(struct in6_addr *a1, const struct in6_addr *a2)
{
	        memcpy(a1, a2, sizeof(struct in6_addr));
}

#endif
#endif /* CONFIG_CS75XX */
/*
 * IEEE 802.11v Proxy ARP
 *
 * When enabled, AP is responsible for sending ARP responses
 * on behalf of its associated clients. Gratuitous ARP's are
 * dropped sliently wthin the BSS.
 */
int wlan_proxy_arp(wlan_if_t vap, wbuf_t wbuf)
{
    struct net_device *dev = OSIF_TO_NETDEV(vap->iv_ifp);
    struct ether_header *eh = (struct ether_header *) wbuf_header(wbuf);
    struct ieee80211_node_table *nt = &vap->iv_ic->ic_sta;
    struct ieee80211_node *ni;
    uint16_t ether_type;
    int linear_len;

    KASSERT(vap->iv_opmode == IEEE80211_M_HOSTAP, ("Proxy ARP in !AP mode"));

    if (IEEE80211_VAP_IS_DELIVER_80211_ENABLED(vap)) {
        printk("%s: IEEE80211_FEXT_DELIVER_80211 is not supported\n", __func__);
        goto pass;
    }
    ether_type = eh->ether_type;
    linear_len = sizeof(*eh);

    if (ether_type == htons(ETHERTYPE_ARP)) {
        struct arphdr *arp = (struct arphdr *)(eh + 1);

        linear_len += sizeof(struct arphdr);
        if (!pskb_may_pull(wbuf, linear_len))
            goto pass;

        if (arp->ar_op == htons(ARPOP_REQUEST)) {
            unsigned char *arp_ptr;
            unsigned char *sha;
            __be32 sip, tip;

            arp_ptr = (unsigned char *)(arp + 1);
            sha = arp_ptr;
            arp_ptr += dev->addr_len;
            memcpy(&sip, arp_ptr, 4);
            arp_ptr += 4;
            arp_ptr += dev->addr_len;
            memcpy(&tip, arp_ptr, 4);

            /* Learn ARP mapping from Gratuitous ARP request */
            if (tip == sip) {
                ni = ieee80211_find_node(nt, sha);
                if (ni && ni->ni_vap &&
                    ni->ni_associd &&
                    ni->ni_ipv4_addr == 0)
                {
                    ieee80211_node_add_ipv4(nt, ni, sip);
                    /*
                     * If we receive a gratuitous ARP for a previously
                     * expired DHCP lease, change the lease type to
                     * ulimited.
                     */
                    if (ni->ni_ipv4_lease_timeout &&
                        ni->ni_ipv4_lease_timeout < jiffies_to_msecs(jiffies) / 1000)
                    {
                        ni->ni_ipv4_lease_timeout = 0;
                    }
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "Gratuitous "
                            "ARP: mac %s -> ip %pI4\n",
                            ether_sprintf(sha), &sip);
                }

                /* Suppress Gratuitous ARP request within the BSS */
                goto drop_node;
            }

            /* Proxy ARP request for the clients within the BSS */
            ni = ieee80211_find_node_by_ipv4(nt, tip);
            if (ni && ni->ni_vap == vap &&
                ni->ni_associd &&
                ni != vap->iv_bss)
            {
                if (ni->ni_ipv4_lease_timeout != 0 &&
                    ni->ni_ipv4_lease_timeout < jiffies_to_msecs(jiffies) / 1000)
                {
                    /* remove the node from the ipv4 hash table */
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "Remove "
                            "ARP entry: mac %s -> ip %pI4 due to timeout. "
                            "expire %d, current %d\n",
                            ether_sprintf(ni->ni_macaddr), &tip,
                            ni->ni_ipv4_lease_timeout,
                            jiffies_to_msecs(jiffies) / 1000);
                    ieee80211_node_remove_ipv4(ni);
                } else {
                    /*
                     * Send the proxy ARP reply: if the ARP request sender is
                     * within the BSS, we can send the ARP reply directly.
                     * Otherwise it must be coming from the bridge. If this
                     * is the case, we assemble an ARP reply packet and give
                     * it to the local stack so that the bridge code can
                     * forward it to the ARP request sender.
                     */
                    struct ieee80211_node *ni1 = ieee80211_find_node(nt, sha);

                    if (ni1 && ni1 != vap->iv_bss) {
#ifdef HOST_OFFLOAD
                        struct sk_buff *skb;

                        ieee80211_free_node(ni1);
                        
                        skb = arp_create(ARPOP_REPLY, ETH_P_ARP, sip, dev, tip,
                                         sha, ni->ni_macaddr, sha);
                        if (skb)
                            atd_proxy_arp_send(skb);
#else
                        ieee80211_free_node(ni1);
                        
                        arp_send(ARPOP_REPLY, ETH_P_ARP, sip, dev, tip, sha,
                                 ni->ni_macaddr, sha);
#endif
                    } else {
                        struct sk_buff *skb;

                        if (ni1) {
                            ieee80211_free_node(ni1);
                            ni1 = NULL;
                        }
                        skb = arp_create(ARPOP_REPLY, ETH_P_ARP, sip, dev, tip,
                                         sha, ni->ni_macaddr, sha);
                        if (skb)
                            __osif_deliver_data(vap->iv_ifp, skb);
                    }
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "send ARP "
                                      "reply for ip %pI4 -> mac %s to %pM %s\n",
                                      &tip, ether_sprintf(ni->ni_macaddr), sha,
                                      ni1 ? "over the air" : "via local stack");
                }
            }

            /* Suppress ARP Request within the BSS */
            goto drop_node;
        } else if (arp->ar_op == htons(ARPOP_REPLY)) {
            /* Suppress Gratuitous ARP reply within the BSS */
            if (IEEE80211_IS_BROADCAST(eh->ether_dhost))
                goto drop;
        }
    } else if (ether_type == htons(ETHERTYPE_IP)) {
        struct dhcp_packet *dhcp = (struct dhcp_packet *)(eh + 1);
        int len, ext_len;

        /* Do not pull too deep ATM */
        linear_len += sizeof(struct iphdr) + sizeof(struct udphdr) + 1;
        if (!pskb_may_pull(wbuf, linear_len))
            goto pass;


        /*
         * We only care about downstream DHCP packets i.e.
         * DHCPOFFER and DHCPACK
         */
        if (dhcp->iph.protocol != IPPROTO_UDP ||
            dhcp->udph.source != 67 ||
            dhcp->udph.dest != 68 ||
            dhcp->op != 2) /* BOOTP Reply */
        {
            goto pass;
        }

        /* If it is a unicast packet, make sure it is within our BSS */
        if (!IEEE80211_IS_BROADCAST(eh->ether_dhost)) {
            ni = ieee80211_find_node(nt, eh->ether_dhost);
            if (!ni || ni->ni_vap != vap || !ni->ni_associd)
                goto pass_node;
            if (ni)
                ieee80211_free_node(ni);
        }

        if (wbuf->len < ntohs(dhcp->iph.tot_len))
            goto pass;

        if (ntohs(dhcp->iph.tot_len) < ntohs(dhcp->udph.len) + sizeof(struct iphdr))
            goto pass;

        len = ntohs(dhcp->udph.len) - sizeof(struct udphdr);
        ext_len = len - (sizeof(*dhcp) -
                         sizeof(struct iphdr) -
                         sizeof(struct udphdr) -
                         sizeof(dhcp->exten));
        if (ext_len < 0)
            goto pass;

        /* linearize the skb */
        if (skb_linearize(wbuf))
            goto pass;

        /* reload pointer after skb_linearize */
        dhcp = (struct dhcp_packet *)skb_network_header(wbuf);

        /* Parse extensions */
        if (ext_len >= 4 && !memcmp(dhcp->exten, ic_bootp_cookie, 4)) {
            u8 *end = (u8 *)dhcp + ntohs(dhcp->iph.tot_len);
            u8 *ext = &dhcp->exten[4];
            int mt = 0;
            uint32_t lease_time = 0;

            while (ext < end && *ext != 0xff) {
                u8 *opt = ext++;
                if (*opt == 0) /* padding */
                    continue;
                ext += *ext + 1;
                if (ext >= end)
                    break;
                switch (*opt) {
                case 53: /* message type */
                    if (opt[1])
                        mt = opt[2];
                    break;
                case 51: /* lease time */
                    if (opt[1] == 4)
                        lease_time = ntohl(*(uint32_t *)&opt[2]);
                    break;
                }
            }

            if (mt == DHCPACK) {
                ni = ieee80211_find_node(nt, dhcp->hw_addr);
                if (ni && ni->ni_vap == vap &&
                    ni->ni_associd &&
                    ni != vap->iv_bss)
                {
                    if (dhcp->your_ip == 0) {
                        /* DHCPACK for DHCPINFORM */
                        IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP,
                            "DHCPACK: respond to DHCPINFORM for mac %s "
                            "lease %u seconds\n",
                            ether_sprintf(dhcp->hw_addr), lease_time);
                        goto pass_node;
                    }

                    /* DHCPACK for DHCPREQUEST */
                    ieee80211_node_add_ipv4(nt, ni, dhcp->your_ip);

                    if (lease_time)
                        ni->ni_ipv4_lease_timeout = jiffies_to_msecs(jiffies) / 1000 + lease_time;
                    else
                        ni->ni_ipv4_lease_timeout = 0;

                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "DHCPACK: "
                            "mac %s -> ip %pI4, lease %u seconds\n",
                            ether_sprintf(dhcp->hw_addr), &dhcp->your_ip,
                            lease_time);
                }
                if (ni)
                    ieee80211_free_node(ni);
            }
#if UMAC_SUPPORT_DGAF_DISABLE
            if ((mt == DHCPOFFER || mt == DHCPACK) &&
                IEEE80211_IS_BROADCAST(eh->ether_dhost))
            {
                ni = ieee80211_find_node(nt, dhcp->hw_addr);
                if (ni && ni->ni_vap == vap &&
                    ni->ni_associd &&
                    ni != vap->iv_bss)
                {
                    /* Convert broadcast DHCP reply to unicast */
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "convert "
                        "broadcast %s packet to unicast %s\n",
                        mt == DHCPOFFER ? "DHCPOFFER" : "DHCPACK",
                        ether_sprintf(dhcp->hw_addr));
                    memcpy(eh->ether_dhost, dhcp->hw_addr, ETH_ALEN);
                    ieee80211_free_node(ni);
                } else {
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "dropping "
                        "broadcast %s packet for %s\n",
                        mt == DHCPOFFER ? "DHCPOFFER" : "DHCPACK",
                        ether_sprintf(dhcp->hw_addr));
                    goto drop_node;
                }
            }
#endif
        }
    } else if (ether_type == htons(ETHERTYPE_IPV6)) {
        struct ipv6hdr *ip6 = (struct ipv6hdr *)(eh + 1);

        linear_len += sizeof(struct ipv6hdr);
        if (!pskb_may_pull(wbuf, linear_len))
            goto pass;

        if (ip6->nexthdr == IPPROTO_ICMPV6) {
            struct icmp6hdr *icmp6 = (struct icmp6hdr *)(ip6 + 1);
            struct nd_msg *msg = (struct nd_msg *)icmp6;
            int optlen = wbuf->len - linear_len - sizeof(struct nd_msg);
            u8 *lladdr;
            int src_type, dst_type;
            int unsolicited;

            linear_len += sizeof(struct icmp6hdr);
            if (!pskb_may_pull(wbuf, linear_len))
                goto pass;

            switch (icmp6->icmp6_type) {
            case NDISC_NEIGHBOUR_SOLICITATION:
                /*
                 * Learn neighbor mapping from DupAddrDetectTransmits
                 * Neighbor Solicitations:
                 *
                 *     ND Target:       address being checked
                 *     IP source:       unspecified address (::)
                 *     IP destination:  solicited-node multicast address
                 *
                 */
                src_type = ipv6_addr_type(&ip6->saddr);
                dst_type = ipv6_addr_type(&ip6->daddr);
                if ((src_type == IPV6_ADDR_ANY) && (dst_type & IPV6_ADDR_MULTICAST)) {
                    ni = ieee80211_find_node(nt, eh->ether_shost);
                    if (ni && ni->ni_vap == vap && ni->ni_associd) {
                        struct ieee80211_node *ni1;

                        /* See if the addr is already in our neighbor cache */
                        ni1 = ieee80211_find_node_by_ipv6(nt, (u8 *)&msg->target);
                        if (ni1 && (ni1 != ni)) {
                            IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "NDP SC: "
                                      "ipv6 %pI6 -> mac %pM ignored (DAD w/ %pM)\n",
                                      &msg->target, ni1->ni_macaddr, ni->ni_macaddr);
                            ieee80211_free_node(ni1);
                            /* We must pass this SC so that the DAD will work */
                            goto pass_node;
                        }
                        if (ni1)
                            ieee80211_free_node(ni1);

                        /* Learn from this SC if it is from our associated STA's */
                        if (ieee80211_node_add_ipv6(nt, ni, (u8 *)&msg->target)) {
                            printk("Maximum multiple IPv6 addresses exceeded "
                                    "]%d]. Proxy ARP disabled. Consider to "
                                    "increase IEEE80211_NODE_IPV6_MAX!\n",
                                    IEEE80211_NODE_IPV6_MAX);
                            ieee80211_vap_proxyarp_clear(vap);
                            goto pass_node;
                        }

                        IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "NDP "
                                "SC: mac %s -> ipv6 %pI6\n",
                                ether_sprintf(eh->ether_shost), &msg->target);
                        goto drop_node;
                    }
                    if (ni)
                        ieee80211_free_node(ni);
                }

                /* The normal Neighbor Solicitation must have the ICMPv6 Option */
                lladdr = ipv6_ndisc_opt_lladdr(msg->opt, optlen, 1);
                if (!lladdr)
                        goto drop;

                ni = ieee80211_find_node_by_ipv6(nt, (u8 *)&msg->target);
                if (ni && ni->ni_vap == vap &&
                    ni->ni_associd &&
                    ni != vap->iv_bss)
                {
                    struct sk_buff *skb;
                    struct ipv6hdr *nip6;
                    struct nd_msg *nmsg;
                    struct ieee80211_node *ni1;

                    skb = alloc_skb(LL_ALLOCATED_SPACE(dev) +
                                    sizeof(struct ipv6hdr) +
                                    sizeof(struct nd_msg) +
                                    8, /* ICMPv6 option */
                                    GFP_ATOMIC);
                    if (!skb) {
                        IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP,
                                "%s: couldn't alloc skb\n");
                        goto drop_node;
                    }
                    skb_reserve(skb, LL_RESERVED_SPACE(dev));
                    nip6 = (struct ipv6hdr *) skb_put(skb, sizeof(struct ipv6hdr));
                    skb->dev = dev;
                    skb->protocol = htons(ETHERTYPE_IPV6);
                    skb_put(skb, sizeof(struct nd_msg) + 8);
                    nmsg = (struct nd_msg *)(nip6 + 1);

                    /* Response with NDP NA */

                    /* fill the Ethernet header */
                    if (dev_hard_header(skb, dev, ETHERTYPE_IPV6, lladdr,
                                        ni->ni_macaddr, skb->len) < 0)
                    {
                        kfree_skb(skb);
                        goto drop_node;
                    }

                    /* build IPv6 header */
                    *(__be32 *)nip6 = htonl(0x60000000);
                    nip6->payload_len = htons(sizeof(struct nd_msg) + 8);
                    nip6->nexthdr = IPPROTO_ICMPV6;
                    nip6->hop_limit = 0xff;
                    ipv6_addr_copy(&nip6->daddr, &ip6->saddr);
                    ipv6_addr_copy(&nip6->saddr, &msg->target);

                    /* build ICMPv6 NDP NA packet */
                    memset(&nmsg->icmph, 0, sizeof(struct icmp6hdr));
                    nmsg->icmph.icmp6_type = NDISC_NEIGHBOUR_ADVERTISEMENT;
                    nmsg->icmph.icmp6_solicited = 1;
                    ipv6_addr_copy(&nmsg->target, &msg->target);
                    /* ICMPv6 Option */
                    nmsg->opt[0] = ND_OPT_TARGET_LL_ADDR;
                    nmsg->opt[1] = 1;
                    memcpy(&nmsg->opt[2], ni->ni_macaddr, IEEE80211_ADDR_LEN);

                    nmsg->icmph.icmp6_cksum = csum_ipv6_magic(&nip6->saddr,
                                &nip6->daddr, sizeof(*nmsg) + 8, IPPROTO_ICMPV6,
                                csum_partial(&nmsg->icmph, sizeof(*nmsg) + 8, 0));

                    ni1 = ieee80211_find_node(nt, lladdr);
                    if (ni1 && ni1->ni_vap == vap &&
                        ni1->ni_associd && ni1 != vap->iv_bss)
                    {
                        ieee80211_free_node(ni1);
                        /* Send it to the STA */
#ifdef HOST_OFFLOAD
                        atd_proxy_arp_send(skb);
#else                        
                        dev_queue_xmit(skb);
#endif
                    } else {
                        if (ni1) {
                            ieee80211_free_node(ni1);
                            ni1 = NULL;
                        }
                        /* Deliver it to the bridge */
                        __osif_deliver_data(vap->iv_ifp, skb);
                    }

                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "send NDP "
                                      "NA for ip %pI6 -> mac %pM to %pM %s\n",
                                      &msg->target, ni->ni_macaddr,
                                      &eh->ether_shost,
                                      ni1 ? "over the air" : "via local stack");

                    /* Suppress NDP NS within the BSS */
                    goto drop_node;
                }
                /*
                 * We drop all the ND SC packets here since we can detect the
                 * STA's IPv6 address w/ DAD reliably even for DHCPv6.
                 */
                goto drop_node;

            case NDISC_NEIGHBOUR_ADVERTISEMENT:
                if (msg->icmph.icmp6_solicited && ipv6_addr_is_multicast(&msg->target))
                    printf("ERROR: both solicited and multicast is set!\n");

                unsolicited = !msg->icmph.icmp6_solicited ||
                              ipv6_addr_is_multicast(&msg->target);

                /* Ignore NA packets w/o option */
                lladdr = ipv6_ndisc_opt_lladdr(msg->opt, optlen, 0);
                if (!lladdr) {
                    if (unsolicited)
                        goto drop;
                    else
                        goto pass;
                }

                ni = ieee80211_find_node_by_ipv6(nt, (u8 *)&msg->target);
                if (ni && memcmp(ni->ni_macaddr, lladdr, IEEE80211_ADDR_LEN)) {
                    /*
                     * Received a NA with a different link addr. It could
                     * be a NA indicating duplication of the tentative addr
                     * from a previous SC.
                     */
                    IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP, "NDP NA: "
                                      "ipv6 %pI6 8< mac %pM removed (DAD w/ %pM)\n",
                                      &msg->target, ni->ni_macaddr, lladdr);
                    ieee80211_node_remove_ipv6(nt, (u8 *)&msg->target);
                    goto pass_node;
                }
                if (ni)
                    ieee80211_free_node(ni);

                /* Suppress non-solicited NA within the BSS */
                if (unsolicited)
                    goto drop;
#if 0
                ni = ieee80211_find_node(nt, lladdr);
                if (!ni || ni->ni_vap != vap || !ni->ni_associd) {
                    /*
                     * In this case we are not interested in this NA packet.
                     * Forward it within the BSS if it is solicited or
                     * suppress it if it is non-solicited.
                     */
                    if (unsolicited)
                        goto drop_node;

                    goto pass_node;
                }

                /* Learn from this NA if it is from our associated STA's */
                ieee80211_node_add_ipv6(nt, ni, (u8 *)&msg->target);

                IEEE80211_DPRINTF(vap, IEEE80211_MSG_PROXYARP,
                        "NDP NA: mac %s -> ipv6 %pI6, multicast %d, solicited %d\n",
                        ether_sprintf(lladdr), &msg->target,
                        ipv6_addr_is_multicast(&msg->target),
                        msg->icmph.icmp6_solicited);
                 if (ni)
                     ieee80211_free_node(ni);

                /* Suppress non-solicited NA within the BSS */
                if (unsolicited)
                    goto drop;
#endif
                break;

            default:
                break;
            }
        }
    }

pass:
    /* pass by default */
    return 0;
pass_node:
    if (ni)
        ieee80211_free_node(ni);
    return 0;
drop_node:
    if (ni)
        ieee80211_free_node(ni);
drop:
    return 1;
}
#endif
