/*
 * Copyright (c) Cortina-Systems Limited 2010.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#include <mach/cs_types.h>
#include <mach/cs75xx_fe_core_table.h>
#include <cs_fe_table_api.h>
#include <cs_fe_head_table.h>

#include "cs752x_eth.h"
#include "cs_core_logic_data.h"
#include "cs_core_vtable.h"
#include "cs_fe_hash.h"
#include "cs_mtu.h"

/* L2 header(14B) + VLAN(4B) + FCS(4B) */
#define CS_PKT_HEADER (22)

enum {
	CS_MTU_IPOE = 1500,
	CS_MTU_PPPOE = 1492,
	CS_MTU_L2TP = 1452,	
	CS_MTU_IPSEC = 1389
};

cs_port_id_t cs_wan_port_id;

static cs_status_t cs_port_encap_ip_mtu_idx_get(cs_encap_type_t encap, cs_uint32_t *mtu_idx)
{
	if (mtu_idx == NULL)
		return CS_E_PARA;

	switch (encap) {
		case CS_ENCAP_IPOE:
			*mtu_idx = 0;
			break;
		case CS_ENCAP_PPPOE:
			*mtu_idx = 1;
			break;
		case CS_ENCAP_L2TP:
			*mtu_idx = 2;
			break;
		case CS_ENCAP_IPSEC:
			*mtu_idx = 3;
			break;
		default:
			return CS_E_PARA;
	}
	
	return CS_E_OK;
}

/*
*Currently, this API is support only for WAN port (UP link port). If the specified port_id is not WAN port, the API must fail.
*/
cs_status_t cs_port_encap_ip_mtu_add(cs_dev_id_t device_id, cs_port_id_t port_id, cs_encap_type_t encap, cs_uint32_t ip_mtu)
{
	fe_pktlen_rngs_entry_t entry[CS_ENCAP_MAX-1];
	unsigned int rslt_idx, data, addr;
	int ret, i;
	static int init=0;

	if (port_id != GE_PORT0 && port_id != GE_PORT1 && port_id != GE_PORT2)
		return CS_E_PARA;
	
	if ((encap == CS_ENCAP_IPOE && ip_mtu > CS_MTU_IPOE) ||
		(encap == CS_ENCAP_PPPOE && ip_mtu > CS_MTU_PPPOE) ||
		(encap == CS_ENCAP_L2TP && ip_mtu > CS_MTU_L2TP) ||
		(encap == CS_ENCAP_IPSEC && ip_mtu > CS_MTU_IPSEC))
		return CS_E_PARA;
	
	memset(entry, 0, (CS_ENCAP_MAX-1)*sizeof(fe_pktlen_rngs_entry_t));
	if (!init) {
		cs_wan_port_id = port_id;
		
		/* disable time stamp for GE_PORT0, GE_PORT1 and GE_PORT2
			NI_TOP_NI_ETH_MAC_CONFIG1_0
			ts_add_dis (Bit 15)
				When 1, disables adding time stamp (4 bytes) to packets from this Ethernet port.
				When 0, 4 byte time stamp is added to packets from this Ethernet port.
		*/
		for (i = 0; i < NI_TOP_NI_ETH_MAC_CONFIG1_0_COUNT; i++) {
			addr = NI_TOP_NI_ETH_MAC_CONFIG1_0 + i*NI_TOP_NI_ETH_MAC_CONFIG1_0_STRIDE;
			data = readl(addr);
			data |= (0x1 << 15);
			writel(data, addr);
		}

		/* flush pktlen range table */
		cs_fe_table_flush_table(FE_TABLE_PKTLEN_RANGE);
		
		/* allocate the first 4 pktlen range entries for IPOE(1), PPPoE(2), L2TP(3) and IPSEC(4) */
		/* IPoE */
		if (CS_E_OK == cs_port_encap_ip_mtu_idx_get(CS_ENCAP_IPOE, &rslt_idx)) {
			entry[rslt_idx].valid = 1;
			entry[rslt_idx].low = 64;
			entry[rslt_idx].high = 1522;
		}
		/* PPPoE */
		if (CS_E_OK == cs_port_encap_ip_mtu_idx_get(CS_ENCAP_PPPOE, &rslt_idx)) {
			entry[rslt_idx].valid = 1;
			entry[rslt_idx].low = 64;
			entry[rslt_idx].high = 1514;
		}
		/* L2TP */
		if (CS_E_OK == cs_port_encap_ip_mtu_idx_get(CS_ENCAP_L2TP, &rslt_idx)) {
			entry[rslt_idx].valid = 1;
			entry[rslt_idx].low = 64;
			entry[rslt_idx].high = 1474;
		}
		/* IPSEC */
		if (CS_E_OK == cs_port_encap_ip_mtu_idx_get(CS_ENCAP_IPSEC, &rslt_idx)) {
			entry[rslt_idx].valid = 1;
			entry[rslt_idx].low = 64;
			entry[rslt_idx].high = 1411;
		}
		
		for (i = 0; i < (CS_ENCAP_MAX-1); i++) {
			ret = cs_fe_table_add_entry(FE_TABLE_PKTLEN_RANGE, &entry[i], &rslt_idx);
			if (ret != 0) {
				printk(KERN_INFO "%s: cs_fe_table_add_entry() idx %d fails err %d!\n", __func__, i, ret);
				return CS_E_ERROR;
			}			
		}
		init = 1;
	}

	if (port_id != cs_wan_port_id)
		return CS_E_PARA;
	
	entry[0].valid = 1;
	entry[0].low = 64;
	/* ip_mtu + L2 header + FCS */
	entry[0].high = ip_mtu + CS_PKT_HEADER;

	if (entry[0].low > entry[0].high)
		return CS_E_ERROR;

	ret = cs_port_encap_ip_mtu_idx_get(encap, &rslt_idx);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_port_encap_ip_mtu_idx_get() fails!\n", __func__);
		return CS_E_ERROR;
	}

	ret = cs_fe_table_set_entry(FE_TABLE_PKTLEN_RANGE, rslt_idx, &entry[0]);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_fe_table_set_entry() idx %d fails err %d!\n", __func__, rslt_idx, ret);
		return CS_E_ERROR;
	}

	return CS_E_OK;
}

cs_status_t cs_port_encap_ip_mtu_delete(cs_dev_id_t device_id, cs_port_id_t port_id, cs_encap_type_t encap)
{
	fe_pktlen_rngs_entry_t entry;
	unsigned int rslt_idx;
	int ret;
	
	if (port_id != cs_wan_port_id)
		return CS_E_PARA;

	ret = cs_port_encap_ip_mtu_idx_get(encap, &rslt_idx);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_port_encap_ip_mtu_idx_get() fails!\n", __func__);
		return CS_E_PARA;
	}
	/* get hw mtu entry */
	ret = cs_fe_table_get_entry(FE_TABLE_PKTLEN_RANGE, rslt_idx, &entry);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_fe_table_get_entry() idx %d fails err %d!\n", __func__, rslt_idx, ret);
		return CS_E_ERROR;
	}
	
	if (!entry.valid)
		return CS_E_OK;
	/* disable valid flag and update entry */
	entry.valid = 0;
	ret = cs_fe_table_set_entry(FE_TABLE_PKTLEN_RANGE, rslt_idx, &entry);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_fe_table_set_entry() idx %d fails err %d!\n", __func__, rslt_idx, ret);
		return CS_E_ERROR;
	}

	return CS_E_OK;
}

cs_status_t cs_port_encap_ip_mtu_get(cs_dev_id_t device_id, cs_port_id_t port_id, cs_encap_type_t encap, cs_uint32_t *ip_mtu)
{
	fe_pktlen_rngs_entry_t entry;
	unsigned int rslt_idx;
	int ret;
	
	if (port_id != cs_wan_port_id)
		return CS_E_PARA;

	if (ip_mtu == NULL)
		return CS_E_PARA;
		
	ret = cs_port_encap_ip_mtu_idx_get(encap, &rslt_idx);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_port_encap_ip_mtu_idx_get() fails!\n", __func__);
		return CS_E_PARA;
	}

	ret = cs_fe_table_get_entry(FE_TABLE_PKTLEN_RANGE, rslt_idx, &entry);
	if (ret != 0) {
		printk(KERN_INFO "%s: cs_fe_table_get_entry() idx %d fails err %d!\n", __func__, rslt_idx, ret);
		return CS_E_ERROR;
	}

	if (!entry.valid)
		return CS_E_ERROR;

	*ip_mtu = entry.high - CS_PKT_HEADER;
	
	return CS_E_OK;
}

