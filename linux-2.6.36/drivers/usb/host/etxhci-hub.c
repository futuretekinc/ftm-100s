/*
 * xHCI host controller driver
 *
 * Copyright (C) 2008 Intel Corp.
 *
 * Author: Sarah Sharp
 * Some code borrowed from the Linux EHCI driver.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <asm/unaligned.h>

#include "etxhci.h"

#define	PORT_WAKE_BITS	(PORT_WKOC_E | PORT_WKDISC_E | PORT_WKCONN_E)
#define	PORT_RWC_BITS	(PORT_CSC | PORT_PEC | PORT_WRC | PORT_OCC | \
			 PORT_RC | PORT_PLC | PORT_PE)

static void xhci_hub_descriptor(struct xhci_hcd *xhci,
		struct usb_hub_descriptor *desc)
{
	int i, ports;
	__le32 __iomem *addr;
	u32 portsc;
	u16 temp;

	ports = HCS_MAX_PORTS(xhci->hcs_params1);

	desc->bDescriptorType = 0x2a;
	desc->bDescLength = 12;
	desc->bPwrOn2PwrGood = 10;	/* xhci section 5.4.9 says 20ms max */
	desc->bHubContrCurrent = 0;
	desc->bNbrPorts = ports;

	/* header decode latency should be zero for roothubs,
	 * see section 4.23.5.2.
	 */
	desc->u.ss.bHubHdrDecLat = 0;
	desc->u.ss.wHubDelay = 0;

	temp = 0;
	/* bit 0 is reserved, bit 1 is for port 1, etc. */
	for (i = 0; i < ports; i++) {
		addr = &xhci->op_regs->port_status_base + NUM_PORT_REGS * i;
		portsc = xhci_readl(xhci, addr);
		if (portsc & PORT_DEV_REMOVE)
			temp |= 1 << (i + 1);
	}

	desc->u.ss.DeviceRemovable = cpu_to_le16(temp);

	/* Ugh, these should be #defines, FIXME */
	/* Using table 11-13 in USB 2.0 spec. */
	temp = 0;
	/* Bits 1:0 - support port power switching, or power always on */
	if (HCC_PPC(xhci->hcc_params))
		temp |= 0x0001;
	else
		temp |= 0x0002;
	/* Bit  2 - root hubs are not part of a compound device */
	/* Bits 4:3 - individual port over current protection */
	temp |= 0x0008;
	/* Bits 6:5 - no TTs in root ports */
	/* Bit  7 - no port indicators */
	desc->wHubCharacteristics = cpu_to_le16(temp);
}

static unsigned int xhci_port_speed(unsigned int port_status)
{
	if (DEV_LOWSPEED(port_status))
		return USB_PORT_STAT_LOW_SPEED;
	if (DEV_HIGHSPEED(port_status))
		return USB_PORT_STAT_HIGH_SPEED;
	/*
	 * FIXME: Yes, we should check for full speed, but the core uses that as
	 * a default in portspeed() in usb/core/hub.c (which is the only place
	 * USB_PORT_STAT_*_SPEED is used).
	 */
	return 0;
}

/*
 * These bits are Read Only (RO) and should be saved and written to the
 * registers: 0, 3, 10:13, 30
 * connect status, over-current status, port speed, and device removable.
 * connect status and port speed are also sticky - meaning they're in
 * the AUX well and they aren't changed by a hot, warm, or cold reset.
 */
#define	XHCI_PORT_RO	((1<<0) | (1<<3) | (0xf<<10) | (1<<30))
/*
 * These bits are RW; writing a 0 clears the bit, writing a 1 sets the bit:
 * bits 5:8, 9, 14:15, 25:27
 * link state, port power, port indicator state, "wake on" enable state
 */
#define XHCI_PORT_RWS	((0xf<<5) | (1<<9) | (0x3<<14) | (0x7<<25))
/*
 * These bits are RW; writing a 1 sets the bit, writing a 0 has no effect:
 * bit 4 (port reset)
 */
#define	XHCI_PORT_RW1S	((1<<4))
/*
 * These bits are RW; writing a 1 clears the bit, writing a 0 has no effect:
 * bits 1, 17, 18, 19, 20, 21, 22, 23
 * port enable/disable, and
 * change bits: connect, PED, warm port reset changed (reserved zero for USB 2.0 ports),
 * over-current, reset, link state, and L1 change
 */
#define XHCI_PORT_RW1CS	((1<<1) | (0x7f<<17))
/*
 * Bit 16 is RW, and writing a '1' to it causes the link state control to be
 * latched in
 */
#define	XHCI_PORT_RW	((1<<16))
/*
 * These bits are Reserved Zero (RsvdZ) and zero should be written to them:
 * bits 2, 24, 28:31
 */
#define	XHCI_PORT_RZ	((1<<2) | (1<<24) | (0xf<<28))

/*
 * Given a port state, this function returns a value that would result in the
 * port being in the same state, if the value was written to the port status
 * control register.
 * Save Read Only (RO) bits and save read/write bits where
 * writing a 0 clears the bit and writing a 1 sets the bit (RWS).
 * For all other types (RW1S, RW1CS, RW, and RZ), writing a '0' has no effect.
 */
u32 etxhci_port_state_to_neutral(u32 state)
{
	/* Save read-only status and port state */
	return (state & XHCI_PORT_RO) | (state & XHCI_PORT_RWS);
}

/*
 * find slot id based on port number.
 */
int etxhci_find_slot_id_by_port(struct xhci_hcd *xhci, u16 port)
{
	int slot_id;
	int i;

	slot_id = 0;
	for (i = 1; i < MAX_HC_SLOTS; i++) {
		if (!xhci->devs[i])
			continue;
		if (xhci->devs[i]->port == port) {
			slot_id = i;
			break;
		}
	}

	return slot_id;
}

/*
 * Stop device
 * It issues stop endpoint command for EP 0 to 30. And wait the last command
 * to complete.
 * suspend will set to 1, if suspend bit need to set in command.
 */
static int xhci_stop_device(struct xhci_hcd *xhci, int slot_id, int suspend)
{
	struct xhci_virt_device *virt_dev;
	struct xhci_command *cmd;
	unsigned long flags;
	int timeleft;
	int ret;
	int i;

	ret = 0;
	virt_dev = xhci->devs[slot_id];
	cmd = etxhci_alloc_command(xhci, false, true, GFP_NOIO);
	if (!cmd) {
		xhci_dbg(xhci, "Couldn't allocate command structure.\n");
		return -ENOMEM;
	}

	spin_lock_irqsave(&xhci->lock, flags);
	for (i = LAST_EP_INDEX; i > 0; i--) {
		if (virt_dev->eps[i].ring && virt_dev->eps[i].ring->dequeue)
			etxhci_queue_stop_endpoint(xhci, slot_id, i, suspend);
	}
	cmd->command_trb = xhci->cmd_ring->enqueue;

	/* Enqueue pointer can be left pointing to the link TRB,
	 * we must handle that
	 */
	if (TRB_TYPE_LINK_LE32(cmd->command_trb->link.control))
		cmd->command_trb =
			xhci->cmd_ring->enq_seg->next->trbs;

	list_add_tail(&cmd->cmd_list, &virt_dev->cmd_list);
	etxhci_queue_stop_endpoint(xhci, slot_id, 0, suspend);
	etxhci_ring_cmd_db(xhci);
	spin_unlock_irqrestore(&xhci->lock, flags);

	/* Wait for last stop endpoint command to finish */
	timeleft = wait_for_completion_interruptible_timeout(
			cmd->completion,
			250);
	if (timeleft <= 0) {
		xhci_warn(xhci, "%s while waiting for stop endpoint command\n",
				timeleft == 0 ? "Timeout" : "Signal");
		spin_lock_irqsave(&xhci->lock, flags);
		/* The timeout might have raced with the event ring handler, so
		 * only delete from the list if the item isn't poisoned.
		 */
		if (cmd->cmd_list.next != LIST_POISON1)
			list_del(&cmd->cmd_list);
		spin_unlock_irqrestore(&xhci->lock, flags);
		ret = -ETIME;
		goto command_cleanup;
	}

command_cleanup:
	etxhci_free_command(xhci, cmd);
	return ret;
}

/*
 * Ring device, it rings the all doorbells unconditionally.
 */
void etxhci_ring_device(struct xhci_hcd *xhci, int slot_id)
{
	int i;

	for (i = 0; i < LAST_EP_INDEX + 1; i++)
		if (xhci->devs[slot_id]->eps[i].ring &&
		    xhci->devs[slot_id]->eps[i].ring->dequeue)
			etxhci_ring_ep_doorbell(xhci, slot_id, i, 0);

	return;
}

static void xhci_disable_port(struct xhci_hcd *xhci, u16 wIndex,
		__le32 __iomem *addr, u32 port_status)
{
	/* Don't allow the USB core to disable SuperSpeed ports. */
	if (xhci->port_array[wIndex] == 0x03) {
		xhci_dbg(xhci, "Ignoring request to disable "
				"SuperSpeed port.\n");
		return;
	}

	/* Write 1 to disable the port */
	xhci_writel(xhci, port_status | PORT_PE, addr);
	port_status = xhci_readl(xhci, addr);
	xhci_dbg(xhci, "disable port, actual port %d status  = 0x%x\n",
			wIndex, port_status);
}

static void xhci_clear_port_change_bit(struct xhci_hcd *xhci, u16 wValue,
		u16 wIndex, __le32 __iomem *addr, u32 port_status)
{
	char *port_change_bit;
	u32 status;

	switch (wValue) {
	case USB_PORT_FEAT_C_RESET:
		status = PORT_RC;
		port_change_bit = "reset";
		break;
	case USB_PORT_FEAT_C_BH_PORT_RESET:
		status = PORT_WRC;
		port_change_bit = "warm(BH) reset";
		break;
	case USB_PORT_FEAT_C_CONNECTION:
		status = PORT_CSC;
		port_change_bit = "connect";
		break;
	case USB_PORT_FEAT_C_OVER_CURRENT:
		status = PORT_OCC;
		port_change_bit = "over-current";
		break;
	case USB_PORT_FEAT_C_ENABLE:
		status = PORT_PEC;
		port_change_bit = "enable/disable";
		break;
	case USB_PORT_FEAT_C_SUSPEND:
		status = PORT_PLC;
		port_change_bit = "suspend/resume";
		break;
	case USB_PORT_FEAT_C_PORT_LINK_STATE:
		status = PORT_PLC;
		port_change_bit = "link state";
		break;
	case USB_PORT_FEAT_C_PORT_CONFIG_ERROR:
		status = PORT_CEC;
		port_change_bit = "config error";
		break;
	default:
		/* Should never happen */
		return;
	}
	/* Change bits are all write 1 to clear */
	xhci_writel(xhci, port_status | status, addr);
	port_status = xhci_readl(xhci, addr);
	xhci_dbg(xhci, "clear port %s change, actual port %d status  = 0x%x\n",
			port_change_bit, wIndex, port_status);
}

/* Test and clear port RWC bit */
void xhci_test_and_clear_bit(struct xhci_hcd *xhci, __le32 __iomem *addr,
		u32 port_bit)
{
	u32 temp;

	temp = xhci_readl(xhci, addr);
	if (temp & port_bit) {
		temp = etxhci_port_state_to_neutral(temp);
		temp |= port_bit;
		xhci_writel(xhci, temp, addr);
	}
}

int etxhci_hub_control(struct usb_hcd *hcd, u16 typeReq, u16 wValue,
		u16 wIndex, char *buf, u16 wLength)
{
	struct xhci_hcd	*xhci = hcd_to_xhci(hcd);
	int ports;
	unsigned long flags;
	u32 temp, temp1, status;
	int retval = 0;
	__le32 __iomem *addr;
	int slot_id;
	u16 link_state = 0;

	ports = HCS_MAX_PORTS(xhci->hcs_params1);

	spin_lock_irqsave(&xhci->lock, flags);
	switch (typeReq) {
	case GetHubStatus:
		/* No power source, over-current reported per port */
		memset(buf, 0, 4);
		break;
	case GetHubDescriptor:
		xhci_hub_descriptor(xhci, (struct usb_hub_descriptor *) buf);
		break;
	case GetPortStatus:
		if (!wIndex || wIndex > ports)
			goto error;
		wIndex--;
		status = 0;
		addr = &xhci->op_regs->port_status_base + NUM_PORT_REGS*(wIndex & 0xff);
		temp = xhci_readl(xhci, addr);
		xhci_dbg(xhci, "get port status, actual port %d status  = 0x%x\n", wIndex, temp);

		/* wPortChange bits */
		if (temp & PORT_CSC)
			status |= USB_PORT_STAT_C_CONNECTION << 16;
		if (temp & PORT_PEC)
			status |= USB_PORT_STAT_C_ENABLE << 16;
		if ((temp & PORT_OCC))
			status |= USB_PORT_STAT_C_OVERCURRENT << 16;
		if ((temp & PORT_RC))
			status |= USB_PORT_STAT_C_RESET << 16;
		/* USB3.0 only */
		if (xhci->port_array[wIndex] == 0x03) {
			if ((temp & PORT_PLC))
				status |= USB_PORT_STAT_C_LINK_STATE << 16;
			if ((temp & PORT_WRC))
				status |= USB_PORT_STAT_C_BH_RESET << 16;
			if ((temp & PORT_CEC))
				status |= USB_PORT_STAT_C_CONFIG_ERROR << 16;
		}

		if (xhci->port_array[wIndex] != 0x03) {
			if ((temp & PORT_PLS_MASK) == XDEV_U3
					&& (temp & PORT_POWER))
				status |= USB_PORT_STAT_SUSPEND;
		}
		if ((temp & PORT_PLS_MASK) == XDEV_RESUME &&
				!DEV_SUPERSPEED(temp)) {
			if ((temp & PORT_RESET) || !(temp & PORT_PE))
				goto error;
			if (time_after_eq(jiffies,
					xhci->resume_done[wIndex])) {
				xhci_dbg(xhci, "Resume USB2 port %d\n",
					wIndex + 1);
				xhci->resume_done[wIndex] = 0;
				temp1 = etxhci_port_state_to_neutral(temp);
				temp1 &= ~PORT_PLS_MASK;
				temp1 |= PORT_LINK_STROBE | XDEV_U0;
				xhci_writel(xhci, temp1, addr);

				xhci_dbg(xhci, "set port %d resume\n",
					wIndex + 1);
				slot_id = etxhci_find_slot_id_by_port(xhci,
								 wIndex + 1);
				if (!slot_id) {
					xhci_dbg(xhci, "slot_id is zero\n");
					goto error;
				}
				etxhci_ring_device(xhci, slot_id);
				xhci->port_c_suspend |= 1 << wIndex;
				xhci->suspended_ports &= ~(1 << wIndex);
			} else {
				/*
				 * The resume has been signaling for less than
				 * 20ms. Report the port status as SUSPEND,
				 * let the usbcore check port status again
				 * and clear resume signaling later.
				 */
				status |= USB_PORT_STAT_SUSPEND;
			}
		}
		if ((temp & PORT_PLS_MASK) == XDEV_U0
			&& (temp & PORT_POWER)
			&& (xhci->suspended_ports & (1 << wIndex))) {
			xhci->suspended_ports &= ~(1 << wIndex);
			if (xhci->port_array[wIndex] != 0x03)
				xhci->port_c_suspend |= 1 << wIndex;
		}
		if (temp & PORT_CONNECT) {
			status |= USB_PORT_STAT_CONNECTION;
			status |= xhci_port_speed(temp);
		}
		if (temp & PORT_PE)
			status |= USB_PORT_STAT_ENABLE;
		if (temp & PORT_OC)
			status |= USB_PORT_STAT_OVERCURRENT;
		if (temp & PORT_RESET)
			status |= USB_PORT_STAT_RESET;
		if (temp & PORT_POWER) {
			if (xhci->port_array[wIndex] == 0x03)
				status |= USB_SS_PORT_STAT_POWER;
			else
				status |= USB_PORT_STAT_POWER;
		}
		/* Port Link State */
		if (xhci->port_array[wIndex] == 0x03) {
			/* resume state is a xHCI internal state.
			 * Do not report it to usb core.
			 */
			if ((temp & PORT_PLS_MASK) != XDEV_RESUME)
				status |= (temp & PORT_PLS_MASK);
		}
		if (xhci->port_c_suspend & (1 << wIndex))
			status |= USB_PORT_STAT_C_SUSPEND << 16;
		xhci_dbg(xhci, "Get port status returned 0x%x\n", status);
		put_unaligned(cpu_to_le32(status), (__le32 *) buf);
		break;
	case SetPortFeature:
		if (wValue == USB_PORT_FEAT_LINK_STATE)
			link_state = (wIndex & 0xff00) >> 3;
		wIndex &= 0xff;
		if (!wIndex || wIndex > ports)
			goto error;
		wIndex--;
		addr = &xhci->op_regs->port_status_base + NUM_PORT_REGS*(wIndex & 0xff);
		temp = xhci_readl(xhci, addr);
		temp = etxhci_port_state_to_neutral(temp);
		/* FIXME: What new port features do we need to support? */
		switch (wValue) {
		case USB_PORT_FEAT_SUSPEND:
			temp = xhci_readl(xhci, addr);
			/* In spec software should not attempt to suspend
			 * a port unless the port reports that it is in the
			 * enabled (PED = ????PLS < ???? state.
			 */
			if ((temp & PORT_PE) == 0 || (temp & PORT_RESET)
				|| (temp & PORT_PLS_MASK) >= XDEV_U3) {
				xhci_warn(xhci, "USB core suspending device "
					  "not in U0/U1/U2.\n");
				goto error;
			}

			slot_id = etxhci_find_slot_id_by_port(xhci, wIndex + 1);
			if (!slot_id) {
				xhci_warn(xhci, "slot_id is zero\n");
				goto error;
			}
			/* unlock to execute stop endpoint commands */
			spin_unlock_irqrestore(&xhci->lock, flags);
			xhci_stop_device(xhci, slot_id, 1);
			spin_lock_irqsave(&xhci->lock, flags);

			temp = etxhci_port_state_to_neutral(temp);
			temp &= ~PORT_PLS_MASK;
			temp |= PORT_LINK_STROBE | XDEV_U3;
			xhci_writel(xhci, temp, addr);

			spin_unlock_irqrestore(&xhci->lock, flags);
			msleep(10); /* wait device to enter */
			spin_lock_irqsave(&xhci->lock, flags);

			temp = xhci_readl(xhci, addr);
			xhci->suspended_ports |= 1 << wIndex;
			break;
		case USB_PORT_FEAT_LINK_STATE:
			temp = xhci_readl(xhci, addr);
			/* Software should not attempt to set
			 * port link state above '5' (Rx.Detect) and the port
			 * must be enabled.
			 */
			if ((temp & PORT_PE) == 0 ||
				(link_state > USB_SS_PORT_LS_RX_DETECT)) {
				xhci_warn(xhci, "Cannot set link state.\n");
				goto error;
			}

			if (link_state == USB_SS_PORT_LS_U3) {
				slot_id = etxhci_find_slot_id_by_port(xhci, wIndex + 1);
				if (slot_id) {
					/* unlock to execute stop endpoint
					 * commands */
					spin_unlock_irqrestore(&xhci->lock,
								flags);
					xhci_stop_device(xhci, slot_id, 1);
					spin_lock_irqsave(&xhci->lock, flags);
				}
			}

			temp = etxhci_port_state_to_neutral(temp);
			temp &= ~PORT_PLS_MASK;
			temp |= PORT_LINK_STROBE | link_state;
			xhci_writel(xhci, temp, addr);

			spin_unlock_irqrestore(&xhci->lock, flags);
			msleep(20); /* wait device to enter */
			spin_lock_irqsave(&xhci->lock, flags);

			temp = xhci_readl(xhci, addr);
			if (link_state == USB_SS_PORT_LS_U3)
				xhci->suspended_ports |= 1 << wIndex;
			break;
		case USB_PORT_FEAT_POWER:
			/*
			 * Turn on ports, even if there isn't per-port switching.
			 * HC will report connect events even before this is set.
			 * However, khubd will ignore the roothub events until
			 * the roothub is registered.
			 */
			xhci_writel(xhci, temp | PORT_POWER, addr);

			temp = xhci_readl(xhci, addr);
			xhci_dbg(xhci, "set port power, actual port %d status  = 0x%x\n", wIndex, temp);
			break;
		case USB_PORT_FEAT_RESET:
			temp = (temp | PORT_RESET);
			xhci_writel(xhci, temp, addr);

			temp = xhci_readl(xhci, addr);
			xhci_dbg(xhci, "set port reset, actual port %d status  = 0x%x\n", wIndex, temp);
			break;
		case USB_PORT_FEAT_BH_PORT_RESET:
			temp |= PORT_WR;
			xhci_writel(xhci, temp, addr);

			temp = xhci_readl(xhci, addr);
			break;
		default:
			goto error;
		}
		temp = xhci_readl(xhci, addr); /* unblock any posted writes */
		break;
	case ClearPortFeature:
		if (!wIndex || wIndex > ports)
			goto error;
		wIndex--;
		addr = &xhci->op_regs->port_status_base +
			NUM_PORT_REGS*(wIndex & 0xff);
		temp = xhci_readl(xhci, addr);
		/* FIXME: What new port features do we need to support? */
		temp = etxhci_port_state_to_neutral(temp);
		switch (wValue) {
		case USB_PORT_FEAT_SUSPEND:
			temp = xhci_readl(xhci, addr);
			xhci_dbg(xhci, "clear USB_PORT_FEAT_SUSPEND\n");
			xhci_dbg(xhci, "PORTSC %04x\n", temp);
			if (temp & PORT_RESET)
				goto error;
			if ((temp & PORT_PLS_MASK) == XDEV_U3) {
				if ((temp & PORT_PE) == 0)
					goto error;

				temp = etxhci_port_state_to_neutral(temp);
				temp &= ~PORT_PLS_MASK;
				temp |= PORT_LINK_STROBE | XDEV_RESUME;
				xhci_writel(xhci, temp, addr);

				spin_unlock_irqrestore(&xhci->lock,
						       flags);
				msleep(20);
				spin_lock_irqsave(&xhci->lock, flags);

				temp = xhci_readl(xhci, addr);
				temp = etxhci_port_state_to_neutral(temp);
				temp &= ~PORT_PLS_MASK;
				temp |= PORT_LINK_STROBE | XDEV_U0;
				xhci_writel(xhci, temp, addr);
			}
			xhci->port_c_suspend |= 1 << wIndex;

			slot_id = etxhci_find_slot_id_by_port(xhci, wIndex + 1);
			if (!slot_id) {
				xhci_dbg(xhci, "slot_id is zero\n");
				goto error;
			}
			etxhci_ring_device(xhci, slot_id);
			break;
		case USB_PORT_FEAT_C_SUSPEND:
			xhci->port_c_suspend &= ~(1 << wIndex);
		case USB_PORT_FEAT_C_RESET:
		case USB_PORT_FEAT_C_BH_PORT_RESET:
		case USB_PORT_FEAT_C_CONNECTION:
		case USB_PORT_FEAT_C_OVER_CURRENT:
		case USB_PORT_FEAT_C_ENABLE:
		case USB_PORT_FEAT_C_PORT_LINK_STATE:
		case USB_PORT_FEAT_C_PORT_CONFIG_ERROR:
			xhci_clear_port_change_bit(xhci, wValue, wIndex,
					addr, temp);
			break;
		case USB_PORT_FEAT_ENABLE:
			xhci_disable_port(xhci, wIndex, addr, temp);
			break;
		default:
			goto error;
		}
		break;
	default:
error:
		/* "stall" on error */
		retval = -EPIPE;
	}
	spin_unlock_irqrestore(&xhci->lock, flags);
	return retval;
}

/*
 * Returns 0 if the status hasn't changed, or the number of bytes in buf.
 * Ports are 0-indexed from the HCD point of view,
 * and 1-indexed from the USB core pointer of view.
 *
 * Note that the status change bits will be cleared as soon as a port status
 * change event is generated, so we use the saved status from that event.
 */
int etxhci_hub_status_data(struct usb_hcd *hcd, char *buf)
{
	unsigned long flags;
	u32 temp, status;
	u32 mask;
	int i, retval;
	struct xhci_hcd	*xhci = hcd_to_xhci(hcd);
	int ports;
	__le32 __iomem *addr;

	ports = HCS_MAX_PORTS(xhci->hcs_params1);

	/* Initial status is no changes */
	retval = (ports + 8) / 8;
	memset(buf, 0, retval);
	status = 0;

	mask = PORT_CSC | PORT_PEC | PORT_OCC | PORT_PLC | PORT_WRC | PORT_CEC;

	spin_lock_irqsave(&xhci->lock, flags);
	/* For each port, did anything change?  If so, set that bit in buf. */
	for (i = 0; i < ports; i++) {
		addr = &xhci->op_regs->port_status_base +
			NUM_PORT_REGS*i;
		temp = xhci_readl(xhci, addr);
		if ((temp & mask) != 0 ||
			(xhci->port_c_suspend & 1 << i) ||
			(xhci->resume_done[i] && time_after_eq(
			    jiffies, xhci->resume_done[i]))) {
			buf[(i + 1) / 8] |= 1 << (i + 1) % 8;
			status = 1;
		}
	}
	spin_unlock_irqrestore(&xhci->lock, flags);
	return status ? retval : 0;
}

#ifdef CONFIG_PM

int etxhci_bus_suspend(struct usb_hcd *hcd)
{
	struct xhci_hcd	*xhci = hcd_to_xhci(hcd);
	int max_ports, port_index, slot_id;
	unsigned long flags;

	xhci_dbg(xhci, "suspend root hub\n");
	max_ports = HCS_MAX_PORTS(xhci->hcs_params1);

	spin_lock_irqsave(&xhci->lock, flags);

	if (hcd->self.root_hub->do_remote_wakeup) {
		port_index = max_ports;
		while (port_index--) {
			if (xhci->resume_done[port_index] != 0) {
				spin_unlock_irqrestore(&xhci->lock, flags);
				xhci_dbg(xhci, "suspend failed because "
						"port %d is resuming\n",
						port_index + 1);
				return -EBUSY;
			}
		}
	}

	for (slot_id = 1; slot_id < MAX_HC_SLOTS; slot_id++) {
		if (!xhci->devs[slot_id])
			continue;
		spin_unlock_irqrestore(&xhci->lock, flags);
		xhci_stop_device(xhci, slot_id, 1);
		spin_lock_irqsave(&xhci->lock, flags);
	}

	port_index = max_ports;
	xhci->bus_suspended = 0;
	while (port_index--) {
		/* suspend the port if the port is not suspended */
		__le32 __iomem *addr;
		u32 t1, t2;

		addr = &xhci->op_regs->port_status_base +
			NUM_PORT_REGS * (port_index & 0xff);
		t1 = xhci_readl(xhci, addr);
		t2 = etxhci_port_state_to_neutral(t1);

		if ((t1 & PORT_PE) && !(t1 & PORT_PLS_MASK)) {
			xhci_dbg(xhci, "port %d not suspended\n", port_index);
			t2 &= ~PORT_PLS_MASK;
			t2 |= PORT_LINK_STROBE | XDEV_U3;
			set_bit(port_index, &xhci->bus_suspended);
		}
		if (hcd->self.root_hub->do_remote_wakeup) {
			if (t1 & PORT_CONNECT) {
				t2 |= PORT_WKOC_E | PORT_WKDISC_E;
				t2 &= ~PORT_WKCONN_E;
			} else {
				t2 |= PORT_WKOC_E | PORT_WKCONN_E;
				t2 &= ~PORT_WKDISC_E;
			}
		} else
			t2 &= ~PORT_WAKE_BITS;

		t1 = etxhci_port_state_to_neutral(t1);
		if (t1 != t2)
			xhci_writel(xhci, t2, addr);

		if (DEV_HIGHSPEED(t1)) {
			/* enable remote wake up for USB 2.0 */
			__le32 __iomem *addr;
			u32 tmp;

			addr = &xhci->op_regs->port_power_base +
				NUM_PORT_REGS * (port_index & 0xff);
			tmp = xhci_readl(xhci, addr);
			tmp |= PORT_RWE;
			xhci_writel(xhci, tmp, addr);
		}
	}
	hcd->state = HC_STATE_SUSPENDED;
	xhci->next_statechange = jiffies + msecs_to_jiffies(10);
	spin_unlock_irqrestore(&xhci->lock, flags);
	return 0;
}

int etxhci_bus_resume(struct usb_hcd *hcd)
{
	struct xhci_hcd	*xhci = hcd_to_xhci(hcd);
	int max_ports, port_index, slot_id;
	u32 temp;
	unsigned long flags;

	xhci_dbg(xhci, "resume root hub\n");
	max_ports = HCS_MAX_PORTS(xhci->hcs_params1);

	if (time_before(jiffies, xhci->next_statechange))
		msleep(5);

	spin_lock_irqsave(&xhci->lock, flags);
#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,36))
	if (!HCD_HW_ACCESSIBLE(hcd)) {
#else
	if (!test_bit(HCD_FLAG_HW_ACCESSIBLE, &hcd->flags)) {
#endif
		spin_unlock_irqrestore(&xhci->lock, flags);
		return -ESHUTDOWN;
	}

	/* delay the irqs */
	temp = xhci_readl(xhci, &xhci->op_regs->command);
	temp &= ~CMD_EIE;
	xhci_writel(xhci, temp, &xhci->op_regs->command);

	port_index = max_ports;
	while (port_index--) {
		/* Check whether need resume ports. If needed
		   resume port and disable remote wakeup */
		__le32 __iomem *addr;
		u32 temp;

		addr = &xhci->op_regs->port_status_base +
			NUM_PORT_REGS * (port_index & 0xff);
		temp = xhci_readl(xhci, addr);
		if (DEV_SUPERSPEED(temp))
			temp &= ~(PORT_RWC_BITS | PORT_CEC | PORT_WAKE_BITS);
		else
			temp &= ~(PORT_RWC_BITS | PORT_WAKE_BITS);
		if (test_bit(port_index, &xhci->bus_suspended) &&
		    (temp & PORT_PLS_MASK)) {
			if (DEV_SUPERSPEED(temp)) {
				temp = etxhci_port_state_to_neutral(temp);
				temp &= ~PORT_PLS_MASK;
				temp |= PORT_LINK_STROBE | XDEV_U0;
				xhci_writel(xhci, temp, addr);
			} else {
				temp = etxhci_port_state_to_neutral(temp);
				temp &= ~PORT_PLS_MASK;
				temp |= PORT_LINK_STROBE | XDEV_RESUME;
				xhci_writel(xhci, temp, addr);

				spin_unlock_irqrestore(&xhci->lock, flags);
				msleep(20);
				spin_lock_irqsave(&xhci->lock, flags);

				temp = xhci_readl(xhci, addr);
				temp = etxhci_port_state_to_neutral(temp);
				temp &= ~PORT_PLS_MASK;
				temp |= PORT_LINK_STROBE | XDEV_U0;
				xhci_writel(xhci, temp, addr);
			}
			/* wait for the port to enter U0 and report port link
			 * state change.
			 */
			spin_unlock_irqrestore(&xhci->lock, flags);
			msleep(20);
			spin_lock_irqsave(&xhci->lock, flags);

			/* Clear PLC */
			xhci_test_and_clear_bit(xhci, addr, PORT_PLC);
		} else
			xhci_writel(xhci, temp, addr);

		if (DEV_HIGHSPEED(temp)) {
			/* disable remote wake up for USB 2.0 */
			__le32 __iomem *addr;
			u32 tmp;

			addr = &xhci->op_regs->port_power_base +
				NUM_PORT_REGS * (port_index & 0xff);
			tmp = xhci_readl(xhci, addr);
			tmp &= ~PORT_RWE;
			xhci_writel(xhci, tmp, addr);
		}
	}

	for (slot_id = 1; slot_id < MAX_HC_SLOTS; slot_id++) {
		if (!xhci->devs[slot_id])
			continue;
		etxhci_ring_device(xhci, slot_id);
	}

	(void) xhci_readl(xhci, &xhci->op_regs->command);

	xhci->next_statechange = jiffies + msecs_to_jiffies(5);
	hcd->state = HC_STATE_RUNNING;
	/* re-enable irqs */
	temp = xhci_readl(xhci, &xhci->op_regs->command);
	temp |= CMD_EIE;
	xhci_writel(xhci, temp, &xhci->op_regs->command);
	temp = xhci_readl(xhci, &xhci->op_regs->command);

	spin_unlock_irqrestore(&xhci->lock, flags);
	return 0;
}

#endif	/* CONFIG_PM */
