/* ==========================================================================
 * $File: //dwh/usb_iip/dev/software/otg/linux/drivers/dwc_otg_pcd.h $
 * $Revision$
 * $Date$
 * $Change: 1146996 $
 *
 * Synopsys HS OTG Linux Software Driver and documentation (hereinafter,
 * "Software") is an Unsupported proprietary work of Synopsys, Inc. unless
 * otherwise expressly agreed to in writing between Synopsys and you.
 *
 * The Software IS NOT an item of Licensed Software or Licensed Product under
 * any End User Software License Agreement or Agreement for Licensed Product
 * with Synopsys or any supplement thereto. You are permitted to use and
 * redistribute this Software in source and binary forms, with or without
 * modification, provided that redistributions of source code must retain this
 * notice. You may not view, use, disclose, copy or distribute this file or
 * any information contained herein except pursuant to this license grant from
 * Synopsys. If you do not agree with this notice, including the disclaimer
 * below, then you are not authorized to use the Software.
 *
 * THIS SOFTWARE IS BEING DISTRIBUTED BY SYNOPSYS SOLELY ON AN "AS IS" BASIS
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE HEREBY DISCLAIMED. IN NO EVENT SHALL SYNOPSYS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * ========================================================================== */
#ifndef DWC_HOST_ONLY
#if !defined(__DWC_PCD_H__)
#define __DWC_PCD_H__

#include <linux/usb/dwc_usb.h>


//#include "../otg/dwc_otg_cil.h"
//#include "dwc_otg_pcd_if.h"
//#include "dwc_list.h"
#include "dwc_otg_cil.h"

/**
 * @file
 *
 * This file contains the structures, constants, and interfaces for
 * the Perpherial Contoller Driver (PCD).
 *
 * The Peripheral Controller Driver (PCD) for Linux will implement the
 * Gadget API, so that the existing Gadget drivers can be used.	 For
 * the Mass Storage Function driver the File-backed USB Storage Gadget
 * (FBS) driver will be used.  The FBS driver supports the
 * Control-Bulk (CB), Control-Bulk-Interrupt (CBI), and Bulk-Only
 * transports.
 *
 */

/** Max Transfer size for any EP */
#define DDMA_MAX_TRANSFER_SIZE 65535

/** Max DMA Descriptor count for any EP */
#define MAX_DMA_DESC_CNT 64
//#define MAX_DMA_DESC_CNT 32

/**
 * Get the pointer to the core_if from the pcd pointer.
 */
#define GET_CORE_IF( _pcd ) (_pcd->core_if)

/**
 * States of EP0.
 */
typedef enum ep0_state {
	EP0_DISCONNECT,		/* no host */
	EP0_IDLE,
	EP0_IN_DATA_PHASE,
	EP0_OUT_DATA_PHASE,
	EP0_IN_STATUS_PHASE,
	EP0_OUT_STATUS_PHASE,
	EP0_STALL,
} ep0state_e;

/** Fordward declaration.*/
struct dwc_otg_pcd;

/** DWC_otg iso request structure.
 *
 */
typedef struct usb_iso_request dwc_otg_pcd_iso_request_t;

/** DWC_otg request structure.
 * This structure is a list of requests.
 */
typedef struct dwc_otg_pcd_request {
	void *priv;
	void *buf;
	dwc_dma_t dma;
	uint32_t length;
	uint32_t actual;
	unsigned sent_zlp:1;

	 DWC_CIRCLEQ_ENTRY(dwc_otg_pcd_request) queue_entry;
} dwc_otg_pcd_request_t;

DWC_CIRCLEQ_HEAD(req_list, dwc_otg_pcd_request);

/**	  PCD EP structure.
 * This structure describes an EP, there is an array of EPs in the PCD
 * structure.
 */
typedef struct dwc_otg_pcd_ep {
	/** USB EP Descriptor */
	const usb_endpoint_descriptor_t *desc;

	/** queue of dwc_otg_pcd_requests. */
	struct req_list queue;
	unsigned stopped:1;
	unsigned disabling:1;
	unsigned dma:1;
	unsigned queue_sof:1;

#ifdef DWC_EN_ISOC
	/** ISOC req handle passed */
	void *iso_req_handle;
#endif				//_EN_ISOC_

	/** DWC_otg ep data. */
	dwc_ep_t dwc_ep;

	/** Pointer to PCD */
	struct dwc_otg_pcd *pcd;

	void *priv;
} dwc_otg_pcd_ep_t;

/** DWC_otg PCD Structure.
 * This structure encapsulates the data for the dwc_otg PCD.
 */
struct dwc_otg_pcd {
	const struct dwc_otg_pcd_function_ops *fops;
	/** Core Interface */
	dwc_otg_core_if_t *core_if;
	/** State of EP0 */
	ep0state_e ep0state;
	/** EP0 Request is pending */
	unsigned ep0_pending:1;
	/** Indicates when SET CONFIGURATION Request is in process */
	unsigned request_config:1;
	/** The state of the Remote Wakeup Enable. */
	unsigned remote_wakeup_enable:1;
	/** The state of the B-Device HNP Enable. */
	unsigned b_hnp_enable:1;
	/** The state of A-Device HNP Support. */
	unsigned a_hnp_support:1;
	/** The state of the A-Device Alt HNP support. */
	unsigned a_alt_hnp_support:1;
	/** Count of pending Requests */
	unsigned request_pending;

	/** SETUP packet for EP0
	 * This structure is allocated as a DMA buffer on PCD initialization
	 * with enough space for up to 3 setup packets.
	 */
	union {
		usb_device_request_t req;
		uint32_t d32[2];
	} *setup_pkt;

	dwc_dma_t setup_pkt_dma_handle;

	/** 2-byte dma buffer used to return status from GET_STATUS */
	uint16_t *status_buf;
	dwc_dma_t status_buf_dma_handle;

	/** EP0 */
	dwc_otg_pcd_ep_t ep0;

	/** Array of IN EPs. */
	dwc_otg_pcd_ep_t in_ep[MAX_EPS_CHANNELS - 1];
	/** Array of OUT EPs. */
	dwc_otg_pcd_ep_t out_ep[MAX_EPS_CHANNELS - 1];
	/** number of valid EPs in the above array. */
//        unsigned      num_eps : 4;
	dwc_spinlock_t *lock;
	/** Timer for SRP. If it expires before SRP is successful
	 * clear the SRP. */
	dwc_timer_t *srp_timer;

	/** Tasklet to defer starting of TEST mode transmissions until
	 *	Status Phase has been completed.
	 */
	dwc_tasklet_t *test_mode_tasklet;

	/** Tasklet to delay starting of xfer in DMA mode */
	dwc_tasklet_t *start_xfer_tasklet;

	/** The test mode to enter when the tasklet is executed. */
	unsigned test_mode;

};

//FIXME this functions should be static, and this prototypes should be removed
extern void dwc_otg_request_nuke(dwc_otg_pcd_ep_t * ep);
extern void dwc_otg_request_done(dwc_otg_pcd_ep_t * ep,
				 dwc_otg_pcd_request_t * req, int32_t status);

//void dwc_otg_iso_buffer_done(dwc_otg_pcd_t * pcd, dwc_otg_pcd_ep_t * ep,
//			     void *req_handle);

extern void do_test_mode(void *data);
#endif
#endif				/* DWC_HOST_ONLY */
