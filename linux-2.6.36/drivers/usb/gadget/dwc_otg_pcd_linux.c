 /* ==========================================================================
  * $File: //dwh/usb_iip/dev/software/otg/linux/drivers/dwc_otg_pcd_linux.c $
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
//#ifndef DWC_HOST_ONLY

/** @file
 * This file implements the Peripheral Controller Driver.
 *
 * The Peripheral Controller Driver (PCD) is responsible for
 * translating requests from the Function Driver into the appropriate
 * actions on the DWC_otg controller. It isolates the Function Driver
 * from the specifics of the controller by providing an API to the
 * Function Driver.
 *
 * The Peripheral Controller Driver for Linux will implement the
 * Gadget API, so that the existing Gadget drivers can be used.
 * (Gadget Driver is the Linux terminology for a Function Driver.)
 *
 * The Linux Gadget API is defined in the header file
 * <code><linux/usb_gadget.h></code>.  The USB EP operations API is
 * defined in the structure <code>usb_ep_ops</code> and the USB
 * Controller API is defined in the structure
 * <code>usb_gadget_ops</code>.
 *
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/errno.h>
#include <linux/list.h>
#include <linux/interrupt.h>
#include <linux/string.h>
#include <linux/dma-mapping.h>
#include <linux/version.h>
//#include <asm/arch/regs-irq.h>
#include <asm/io.h>
#include <linux/irq.h>
#include <linux/platform_device.h>
//#include <linux/usb/gadget.h>

//#include <asm/arch/lm.h>
//#include <asm/arch/irqs.h>

#include <linux/usb/ch9.h>

#include <linux/usb/gadget.h>

#include "dwc_otg_driver.h"
#include "dwc_otg_pcd_if_1.h"
//#include "dwc_otg_pcd.h"
//#include "dwc_otg_dbg.h"
//#include <linux/usb/dwc_otg.h>



static struct gadget_wrapper {
	dwc_otg_pcd_t *pcd;

	struct usb_gadget gadget;
	struct usb_gadget_driver *driver;

	struct usb_ep ep0;
	struct usb_ep in_ep[4];
	struct usb_ep out_ep[4];

} *gadget_wrapper_1;

///#define lm_get_drvdata(lm)	((lm)->lm_drvdata)

/* Display the contents of the buffer */
extern void dump_msg(const u8 *buf, unsigned int length);
///struct platform_device *lmdev;

///struct platform_device *transfer_lmdev(void)
///{
// printk("%s : lmdev %x \n",__func__,lmdev);
/// return lmdev;
/// }
///EXPORT_SYMBOL(transfer_lmdev);

extern struct platform_device *transfer_lmdev_otg(void);
extern struct dwc_otg_device_t *transfer_dwc_otg_device(void);
extern void dwc_otg_enable_global_interrupts(dwc_otg_core_if_t * _core_if);
/* USB Endpoint Operations */
/*
 * The following sections briefly describe the behavior of the Gadget
 * API endpoint operations implemented in the DWC_otg driver
 * software. Detailed descriptions of the generic behavior of each of
 * these functions can be found in the Linux header file
 * include/linux/usb_gadget.h.
 *
 * The Gadget API provides wrapper functions for each of the function
 * pointers defined in usb_ep_ops. The Gadget Driver calls the wrapper
 * function, which then calls the underlying PCD function. The
 * following sections are named according to the wrapper
 * functions. Within each section, the corresponding DWC_otg PCD
 * function name is specified.
 *
 */

/**
 * This function is called by the Gadget Driver for each EP to be
 * configured for the current configuration (SET_CONFIGURATION).
 *
 * This function initializes the dwc_otg_ep_t data structure, and then
 * calls dwc_otg_ep_activate.
 */
static int ep_enable(struct usb_ep *usb_ep,
		     const struct usb_endpoint_descriptor *ep_desc)
{
	int retval;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%p)\n", __func__, usb_ep, ep_desc);

	if (!usb_ep || !ep_desc || ep_desc->bDescriptorType != USB_DT_ENDPOINT) {
		DWC_WARN("%s, bad ep or descriptor\n", __func__);
		return -EINVAL;
	}
	if (usb_ep == &gadget_wrapper_1->ep0) {
		DWC_WARN("%s, bad ep(0)\n", __func__);
		return -EINVAL;
	}

	/* Check FIFO size? */
	if (!ep_desc->wMaxPacketSize) {
		DWC_WARN("%s, bad %s maxpacket\n", __func__, usb_ep->name);
		return -ERANGE;
	}

	if (!gadget_wrapper_1->driver ||
	    gadget_wrapper_1->gadget.speed == USB_SPEED_UNKNOWN) {
		DWC_WARN("%s, bogus device state\n", __func__);
		return -ESHUTDOWN;
	}

	retval = dwc_otg_pcd_ep_enable(gadget_wrapper_1->pcd,
				       (const uint8_t *)ep_desc,
				       (void *)usb_ep);
	if (retval) {
		DWC_WARN("dwc_otg_pcd_ep_enable failed\n");
		return -EINVAL;
	}

	usb_ep->maxpacket = le16_to_cpu(ep_desc->wMaxPacketSize);

	return 0;
}

/**
 * This function is called when an EP is disabled due to disconnect or
 * change in configuration. Any pending requests will terminate with a
 * status of -ESHUTDOWN.
 *
 * This function modifies the dwc_otg_ep_t data structure for this EP,
 * and then calls dwc_otg_ep_deactivate.
 */
static int ep_disable(struct usb_ep *usb_ep)
{
	int retval;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, usb_ep);
	if (!usb_ep) {
		DWC_DEBUGPL(DBG_PCD, "%s, %s not enabled\n", __func__,
			    usb_ep ? usb_ep->name : NULL);
		return -EINVAL;
	}

	retval = dwc_otg_pcd_ep_disable(gadget_wrapper_1->pcd, usb_ep);
	if (retval) {
		retval = -EINVAL;
	}

	return retval;
}

/**
 * This function allocates a request object to use with the specified
 * endpoint.
 *
 * @param ep The endpoint to be used with with the request
 * @param gfp_flags the GFP_* flags to use.
 */
static struct usb_request *dwc_otg_pcd_alloc_request(struct usb_ep *ep,
						     gfp_t gfp_flags)
{
	struct usb_request *usb_req;
	dma_addr_t dma;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%d)\n", __func__, ep, gfp_flags);
	if (0 == ep) {
		DWC_WARN("%s() %s\n", __func__, "Invalid EP!\n");
		return 0;
	}
	usb_req = kmalloc(sizeof(*usb_req), gfp_flags);
	if (0 == usb_req) {
		DWC_WARN("%s() %s\n", __func__, "request allocation failed!\n");
		return 0;
	}
	memset(usb_req, 0, sizeof(*usb_req));
//	usb_req->dma = DWC_INVALID_DMA_ADDR;
    usb_req->dma = dma_alloc_coherent(NULL, 512, &dma, GFP_KERNEL|GFP_DMA);

	return usb_req;
}

/**
 * This function frees a request object.
 *
 * @param ep The endpoint associated with the request
 * @param req The request being freed
 */
static void dwc_otg_pcd_free_request(struct usb_ep *ep, struct usb_request *req)
{
	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%p)\n", __func__, ep, req);

	if (0 == ep || 0 == req) {
		DWC_WARN("%s() %s\n", __func__,
			 "Invalid ep or req argument!\n");
		return;
	}

	kfree(req);
}

/**
 * This function allocates an I/O buffer to be used for a transfer
 * to/from the specified endpoint.
 *
 * @param usb_ep The endpoint to be used with with the request
 * @param bytes The desired number of bytes for the buffer
 * @param dma Pointer to the buffer's DMA address; must be valid
 * @param gfp_flags the GFP_* flags to use.
 * @return address of a new buffer or null is buffer could not be allocated.
 */
static void *dwc_otg_pcd_alloc_buffer(struct usb_ep *usb_ep, unsigned bytes,
				      dma_addr_t * dma, gfp_t gfp_flags)
{
	void *buf;
	dwc_otg_pcd_t *pcd = 0;

	pcd = gadget_wrapper_1->pcd;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%d,%p,%0x)\n", __func__, usb_ep, bytes,
		    dma, gfp_flags);

	/* Check dword alignment */
	if ((bytes & 0x3UL) != 0) {
		DWC_WARN("%s() Buffer size is not a multiple of"
			 "DWORD size (%d)", __func__, bytes);
	}

	buf = dma_alloc_coherent(NULL, bytes, dma, gfp_flags);

	/* Check dword alignment */
	if (((int)buf & 0x3UL) != 0) {
		DWC_WARN("%s() Buffer is not DWORD aligned (%p)",
			 __func__, buf);
	}

	return buf;
}

/**
 * This function frees an I/O buffer that was allocated by alloc_buffer.
 *
 * @param usb_ep the endpoint associated with the buffer
 * @param buf address of the buffer
 * @param dma The buffer's DMA address
 * @param bytes The number of bytes of the buffer
 */
static void dwc_otg_pcd_free_buffer(struct usb_ep *usb_ep, void *buf,
				    dma_addr_t dma, unsigned bytes)
{
	dwc_otg_pcd_t *pcd = 0;

	pcd = gadget_wrapper_1->pcd;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%0x,%d)\n", __func__, buf, dma, bytes);

	dma_free_coherent(NULL, bytes, buf, dma);
}

/**
 * This function is used to submit an I/O Request to an EP.
 *
 *	- When the request completes the request's completion callback
 *	  is called to return the request to the driver.
 *	- An EP, except control EPs, may have multiple requests
 *	  pending.
 *	- Once submitted the request cannot be examined or modified.
 *	- Each request is turned into one or more packets.
 *	- A BULK EP can queue any amount of data; the transfer is
 *	  packetized.
 *	- Zero length Packets are specified with the request 'zero'
 *	  flag.
 */
static int ep_queue(struct usb_ep *usb_ep, struct usb_request *usb_req,
		    gfp_t gfp_flags)
{
	dwc_otg_pcd_t *pcd;
	int retval;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%p,%d)\n",
		    __func__, usb_ep, usb_req, gfp_flags);

	if (!usb_req || !usb_req->complete || !usb_req->buf) {
		DWC_WARN("bad params\n");
		return -EINVAL;
	}

	if (!usb_ep) {
		DWC_WARN("bad ep\n");
		return -EINVAL;
	}

	pcd = gadget_wrapper_1->pcd;
	if (!gadget_wrapper_1->driver ||
	    gadget_wrapper_1->gadget.speed == USB_SPEED_UNKNOWN) {
		DWC_DEBUGPL(DBG_PCDV, "gadget.speed=%d\n",
			    gadget_wrapper_1->gadget.speed);
		DWC_WARN("bogus device state\n");
		return -ESHUTDOWN;
	}

	DWC_DEBUGPL(DBG_PCD, "%s queue req %p, len %d buf %p\n",
		    usb_ep->name, usb_req, usb_req->length, usb_req->buf);

	usb_req->status = -EINPROGRESS;
	usb_req->actual = 0;

	retval = dwc_otg_pcd_ep_queue(pcd, usb_ep, usb_req->buf, usb_req->dma,
				      usb_req->length, usb_req->zero, usb_req,
				      gfp_flags == GFP_ATOMIC ? 1 : 0);
	if (retval) {
		return -EINVAL;
	}

	return 0;
}

/**
 * This function cancels an I/O request from an EP.
 */
static int ep_dequeue(struct usb_ep *usb_ep, struct usb_request *usb_req)
{
	DWC_DEBUGPL(DBG_PCDV, "%s(%p,%p)\n", __func__, usb_ep, usb_req);
	if (!usb_ep || !usb_req) {
		DWC_WARN("bad argument\n");
		return -EINVAL;
	}
	if (!gadget_wrapper_1->driver ||
	    gadget_wrapper_1->gadget.speed == USB_SPEED_UNKNOWN) {
		DWC_WARN("bogus device state\n");
		return -ESHUTDOWN;
	}
	if (dwc_otg_pcd_ep_dequeue(gadget_wrapper_1->pcd, usb_ep, usb_req)) {
		return -EINVAL;
	}

	return 0;
}

/**
 * usb_ep_set_halt stalls an endpoint.
 *
 * usb_ep_clear_halt clears an endpoint halt and resets its data
 * toggle.
 *
 * Both of these functions are implemented with the same underlying
 * function. The behavior depends on the value argument.
 *
 * @param[in] usb_ep the Endpoint to halt or clear halt.
 * @param[in] value
 *	- 0 means clear_halt.
 *	- 1 means set_halt,
 *	- 2 means clear stall lock flag.
 *	- 3 means set  stall lock flag.
 */
static int ep_halt(struct usb_ep *usb_ep, int value)
{
	int retval = 0;

	DWC_DEBUGPL(DBG_PCD, "HALT %s %d\n", usb_ep->name, value);

	if (!usb_ep) {
		DWC_WARN("bad ep\n");
		return -EINVAL;
	}

	retval = dwc_otg_pcd_ep_halt(gadget_wrapper_1->pcd, usb_ep, value);
	if (retval == -DWC_E_AGAIN) {
		return -EAGAIN;
	} else if (retval) {
		retval = -EINVAL;
	}

	return retval;
}

//#ifdef DWC_EN_ISOC
#if 0
/**
 * This function is used to submit an ISOC Transfer Request to an EP.
 *
 *	- Every time a sync period completes the request's completion callback
 *	  is called to provide data to the gadget driver.
 *	- Once submitted the request cannot be modified.
 *	- Each request is turned into periodic data packets untill ISO
 *	  Transfer is stopped..
 */
static int iso_ep_start(struct usb_ep *usb_ep, struct usb_iso_request *req,
			gfp_t gfp_flags)
{
	int retval = 0;

	if (!req || !req->process_buffer || !req->buf0 || !req->buf1) {
		DWC_WARN("bad params\n");
		return -EINVAL;
	}

	if (!usb_ep) {
		DWC_PRINTF("bad params\n");
		return -EINVAL;
	}

	req->status = -EINPROGRESS;

	retval =
	    dwc_otg_pcd_iso_ep_start(gadget_wrapper_1->pcd, usb_ep, req->buf0,
				     req->buf1, req->dma0, req->dma1,
				     req->sync_frame, req->data_pattern_frame,
				     req->data_per_frame,
				     req->flags & USB_REQ_ISO_ASAP ? -1 : req->
				     start_frame, req->buf_proc_intrvl, req,
				     gfp_flags == GFP_ATOMIC ? 1 : 0);

	if (retval) {
		return -EINVAL;
	}

	return retval;
}

/**
 * This function stops ISO EP Periodic Data Transfer.
 */
static int iso_ep_stop(struct usb_ep *usb_ep, struct usb_iso_request *req)
{
	int retval = 0;

	if (!usb_ep) {
		DWC_WARN("bad ep\n");
	}

	if (!gadget_wrapper_1->driver ||
	    gadget_wrapper_1->gadget.speed == USB_SPEED_UNKNOWN) {
		DWC_DEBUGPL(DBG_PCDV, "gadget.speed=%d\n",
			    gadget_wrapper_1->gadget.speed);
		DWC_WARN("bogus device state\n");
	}

	dwc_otg_pcd_iso_ep_stop(gadget_wrapper_1->pcd, usb_ep, req);
	if (retval) {
		retval = -EINVAL;
	}

	return retval;
}

static struct usb_iso_request *alloc_iso_request(struct usb_ep *ep,
						 int packets, gfp_t gfp_flags)
{
	struct usb_iso_request *pReq = NULL;
	uint32_t req_size;

	req_size = sizeof(struct usb_iso_request);
	req_size +=
	    (2 * packets * (sizeof(struct usb_gadget_iso_packet_descriptor)));

	pReq = kmalloc(req_size, gfp_flags);
	if (!pReq) {
		DWC_WARN("Can't allocate Iso Request\n");
		return 0;
	}
	pReq->iso_packet_desc0 = (void *)(pReq + 1);

	pReq->iso_packet_desc1 = pReq->iso_packet_desc0 + packets;

	return pReq;
}

static void free_iso_request(struct usb_ep *ep, struct usb_iso_request *req)
{
	kfree(req);
}

static struct usb_isoc_ep_ops dwc_otg_pcd_ep_ops = {
	.ep_ops = {
		   .enable = ep_enable,
		   .disable = ep_disable,

		   .alloc_request = dwc_otg_pcd_alloc_request,
		   .free_request = dwc_otg_pcd_free_request,

//		   .alloc_buffer = dwc_otg_pcd_alloc_buffer,
//		   .free_buffer = dwc_otg_pcd_free_buffer,

		   .queue = ep_queue,
		   .dequeue = ep_dequeue,

		   .set_halt = ep_halt,
		   .fifo_status = 0,
		   .fifo_flush = 0,
		   },
	.iso_ep_start = iso_ep_start,
	.iso_ep_stop = iso_ep_stop,
	.alloc_iso_request = alloc_iso_request,
	.free_iso_request = free_iso_request,
};
#endif
//#else

static struct usb_ep_ops dwc_otg_pcd_ep_ops = {
	.enable = ep_enable,
	.disable = ep_disable,

	.alloc_request = dwc_otg_pcd_alloc_request,
	.free_request = dwc_otg_pcd_free_request,

//	.alloc_buffer = dwc_otg_pcd_alloc_buffer,
//	.free_buffer = dwc_otg_pcd_free_buffer,

	.queue = ep_queue,
	.dequeue = ep_dequeue,

	.set_halt = ep_halt,
	.fifo_status = 0,
	.fifo_flush = 0,

};

//#endif				/* _EN_ISOC_ */
/*	Gadget Operations */
/**
 * The following gadget operations will be implemented in the DWC_otg
 * PCD. Functions in the API that are not described below are not
 * implemented.
 *
 * The Gadget API provides wrapper functions for each of the function
 * pointers defined in usb_gadget_ops. The Gadget Driver calls the
 * wrapper function, which then calls the underlying PCD function. The
 * following sections are named according to the wrapper functions
 * (except for ioctl, which doesn't have a wrapper function). Within
 * each section, the corresponding DWC_otg PCD function name is
 * specified.
 *
 */

/**
 *Gets the USB Frame number of the last SOF.
 */
static int get_frame_number(struct usb_gadget *gadget)
{
	struct gadget_wrapper *d;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, gadget);

	if (gadget == 0) {
		return -ENODEV;
	}

	d = container_of(gadget, struct gadget_wrapper, gadget);
	return dwc_otg_pcd_get_frame_number(d->pcd);
}

static int test_lpm_enabled(struct usb_gadget *gadget)
{
	struct gadget_wrapper *d;

	d = container_of(gadget, struct gadget_wrapper, gadget);

	return dwc_otg_pcd_is_lpm_enabled(d->pcd);
}

/**
 * Initiates Session Request Protocol (SRP) to wakeup the host if no
 * session is in progress. If a session is already in progress, but
 * the device is suspended, remote wakeup signaling is started.
 *
 */
static int wakeup(struct usb_gadget *gadget)
{
	struct gadget_wrapper *d;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, gadget);

	if (gadget == 0) {
		return -ENODEV;
	} else {
		d = container_of(gadget, struct gadget_wrapper, gadget);
	}
	dwc_otg_pcd_wakeup(d->pcd);
	return 0;
}

static const struct usb_gadget_ops dwc_otg_pcd_ops = {
	.get_frame = get_frame_number,
	.wakeup = wakeup,
	.lpm_support = test_lpm_enabled,
	// current versions must always be self-powered
};

static int _setup(dwc_otg_pcd_t * pcd, uint8_t * bytes)
{
	int retval = -DWC_E_NOT_SUPPORTED;
	if (gadget_wrapper_1->driver && gadget_wrapper_1->driver->setup) {
		retval = gadget_wrapper_1->driver->setup(&gadget_wrapper_1->gadget, (struct usb_ctrlrequest	*)bytes);
	}
	if (retval == -ENOTSUPP) {
		retval = -DWC_E_NOT_SUPPORTED;
	} else if (retval < 0) {
		retval = -DWC_E_INVALID;
	}

	return retval;
}

#ifdef DWC_EN_ISOC
static int _isoc_complete(dwc_otg_pcd_t * pcd, void *ep_handle,
			  void *req_handle, int proc_buf_num)
{
	int i, packet_count;
	struct usb_gadget_iso_packet_descriptor *iso_packet = 0;
	struct usb_iso_request *iso_req = req_handle;

	if (proc_buf_num) {
		iso_packet = iso_req->iso_packet_desc1;
	} else {
		iso_packet = iso_req->iso_packet_desc0;
	}
	packet_count =
	    dwc_otg_pcd_get_iso_packet_count(pcd, ep_handle, req_handle);
	for (i = 0; i < packet_count; ++i) {
		int status;
		int actual;
		int offset;
		dwc_otg_pcd_get_iso_packet_params(pcd, ep_handle, req_handle,
						  i, &status, &actual, &offset);
		switch (status) {
		case -DWC_E_NO_DATA:
			status = -ENODATA;
			break;
		default:
			if (status) {
				DWC_PRINTF("unknown status in isoc packet\n");
			}

		}
		iso_packet[i].status = status;
		iso_packet[i].offset = offset;
		iso_packet[i].actual_length = actual;
	}

	iso_req->status = 0;
	iso_req->process_buffer(ep_handle, iso_req);

	return 0;
}
#endif				/* DWC_EN_ISOC */

static int _complete(dwc_otg_pcd_t * pcd, void *ep_handle,
		     void *req_handle, int32_t status, uint32_t actual)
{
	struct usb_request *req = (struct usb_request *)req_handle;
	if (req && req->complete) {
		switch (status) {
		case -DWC_E_SHUTDOWN:
			req->status = -ESHUTDOWN;
			break;
		case -DWC_E_RESTART:
			req->status = -ECONNRESET;
			break;
		case -DWC_E_INVALID:
			req->status = -EINVAL;
			break;
		case -DWC_E_TIMEOUT:
			req->status = -ETIMEDOUT;
			break;
		default:
			req->status = status;

		}
		req->actual = actual;
		req->complete(ep_handle, req);
	}

	return 0;
}

static int _connect(dwc_otg_pcd_t * pcd, int speed)
{
	gadget_wrapper_1->gadget.speed = speed;
	return 0;
}

static int _disconnect(dwc_otg_pcd_t * pcd)
{
	if (gadget_wrapper_1->driver && gadget_wrapper_1->driver->disconnect) {
		gadget_wrapper_1->driver->disconnect(&gadget_wrapper_1->gadget);
	}
	return 0;
}

static int _resume(dwc_otg_pcd_t * pcd)
{
	if (gadget_wrapper_1->driver && gadget_wrapper_1->driver->resume) {
		gadget_wrapper_1->driver->resume(&gadget_wrapper_1->gadget);
	}

	return 0;
}

static int _suspend(dwc_otg_pcd_t * pcd)
{
	if (gadget_wrapper_1->driver && gadget_wrapper_1->driver->suspend) {
		gadget_wrapper_1->driver->suspend(&gadget_wrapper_1->gadget);
	}
	return 0;
}

/**
 * This function updates the otg values in the gadget structure.
 */
extern uint32_t get_b_hnp_enable(dwc_otg_pcd_t * pcd);
static int _hnp_changed(dwc_otg_pcd_t * pcd)
{

	if (!gadget_wrapper_1->gadget.is_otg)
		return 0;

	gadget_wrapper_1->gadget.b_hnp_enable = get_b_hnp_enable(pcd);
	gadget_wrapper_1->gadget.a_hnp_support = get_a_hnp_support(pcd);
	gadget_wrapper_1->gadget.a_alt_hnp_support = get_a_alt_hnp_support(pcd);
	return 0;
}

static int _reset(dwc_otg_pcd_t * pcd)
{
	return 0;
}

static const struct dwc_otg_pcd_function_ops fops = {
	.complete = _complete,
#ifdef DWC_EN_ISOC
	.isoc_complete = _isoc_complete,
#endif
	.setup = _setup,
	.disconnect = _disconnect,
	.connect = _connect,
	.resume = _resume,
	.suspend = _suspend,
	.hnp_changed = _hnp_changed,
	.reset = _reset,
};

/**
 * This function is the top level PCD interrupt handler.
 */
irqreturn_t dwc_otg_pcd_irq(int irq, void *dev)
{
	dwc_otg_pcd_t *pcd = dev;
	int32_t retval = IRQ_NONE;

    pcd->fops = &fops;
	retval = dwc_otg_pcd_handle_intr(pcd);
//	if (retval != 0) {
//		S3C2410X_CLEAR_EINTPEND();
//	}
	return IRQ_RETVAL(retval);
}

/**
 * This function initialized the usb_ep structures to there default
 * state.
 *
 * @param d Pointer on gadget_wrapper.
 */
const char *names[] = {

		"ep0",
		"ep1in",
		"ep2in",
		"ep3in",
#if 0
		"ep4in",
		"ep5in",
		"ep6in",
		"ep7in",
		"ep8in",
		"ep9in",
		"ep10in",
		"ep11in",
		"ep12in",
		"ep13in",
		"ep14in",
		"ep15in",
#endif
		"ep1out",
		"ep2out",
		"ep3out"
#if 0
		"ep4out",
		"ep5out",
		"ep6out",
		"ep7out",
		"ep8out",
		"ep9out",
		"ep10out",
		"ep11out",
		"ep12out",
		"ep13out",
		"ep14out",
		"ep15out"
#endif
	};


static struct usb_ep *e_temp;
struct list_head  ep_list_head;

void gadget_add_eps(struct gadget_wrapper *d)
{

	int i;
	struct usb_ep *ep;

	DWC_DEBUGPL(DBG_PCDV, "%s\n", __func__);

	INIT_LIST_HEAD(&d->gadget.ep_list);

	d->gadget.ep0 = &d->ep0;
	d->gadget.speed = USB_SPEED_UNKNOWN;

	INIT_LIST_HEAD(&d->gadget.ep0->ep_list);

	/**
	 * Initialize the EP0 structure.
	 */
	ep = &d->ep0;
	e_temp = &d->ep0;
	gadget_wrapper_1->gadget.ep0 = &d->ep0;
	gadget_wrapper_1->pcd->ep0.priv = &d->ep0;
    printk("%s : gadget_wrapper_1->gadget.ep0 %x gadget_wrapper_1->pcd->ep0.priv %x\n",__func__,gadget_wrapper_1->gadget.ep0,gadget_wrapper_1->pcd->ep0.priv);
	/* Init the usb_ep structure. */
	ep->name = names[0];
	ep->ops = (struct usb_ep_ops *)&dwc_otg_pcd_ep_ops;
	//Move from usb_ep_autoconfig_reset
    ep->driver_data = NULL;
	/**
	 * @todo NGS: What should the max packet size be set to
	 * here?  Before EP type is set?
	 */
	ep->maxpacket = MAX_PACKET_SIZE;
	dwc_otg_pcd_ep_enable(d->pcd, NULL, ep);


	list_add_tail(&ep->ep_list, &d->gadget.ep_list);
	/**
	 * Initialize the EP structures.
	 */
//	for (i = 0; i < 15; i++) { //cs752x only support 1 control, 1 bluk, 1 isogonos, 1 interrupt
	for (i = 0; i < 3; i++) {
		ep = &d->in_ep[i];

        gadget_wrapper_1->pcd->in_ep[i].priv = &d->in_ep[i];
		/* Init the usb_ep structure. */
		ep->name = names[i + 1];
//		printk("%s : ep(in)->name %s names[%x+1] %x &ep->ep_list %x ep %x &d->in_ep[%x].ep_list %x \n",__func__,ep->name,i,names[i + 1],&ep->ep_list,ep,i,&d->in_ep[i].ep_list);
		ep->ops = (struct usb_ep_ops *)&dwc_otg_pcd_ep_ops;
        //Move from usb_ep_autoconfig_reset
        ep->driver_data = NULL;
		/**
		 * @todo NGS: What should the max packet size be set to
		 * here?  Before EP type is set?
		 */
		ep->maxpacket = MAX_PACKET_SIZE;
		//Add for fsg_bind.
        list_add_tail(&ep->ep_list, &d->gadget.ep_list);
#if 1
        //=================================================
        ep = &d->out_ep[i];

        gadget_wrapper_1->pcd->out_ep[i].priv = &d->out_ep[i];
		/* Init the usb_ep structure. */
		ep->name = names[3 + i + 1];
		printk("%s : ep(out)->name %s names[3+%x+1] %x &ep->ep_list %x ep %x \n",__func__,ep->name,i,names[3+i+1],&ep->ep_list,ep);
		ep->ops = (struct usb_ep_ops *)&dwc_otg_pcd_ep_ops;
        //Move from usb_ep_autoconfig_reset
        ep->driver_data = NULL;
		/**
		 * @todo NGS: What should the max packet size be set to
		 * here?  Before EP type is set?
		 */
		ep->maxpacket = MAX_PACKET_SIZE;

		list_add_tail(&ep->ep_list, &d->gadget.ep_list);
#endif
	}

#if 0
//	for (i = 0; i < 15; i++) { //cs752x only support 1 control, 1 bluk, 1 isogonos, 1 interrupt
	for (i = 0; i < 3; i++) {
		ep = &d->out_ep[i];

		/* Init the usb_ep structure. */
		ep->name = names[3 + i + 1];
//		printk("%s : ep(out)->name %s names[3+%x+1] %x &ep->ep_list %x ep %x &d->in_ep[%x].ep_list %x \n",__func__,ep->name,i,names[3+i+1],&ep->ep_list,ep,i,&d->out_ep[i].ep_list);
		ep->ops = (struct usb_ep_ops *)&dwc_otg_pcd_ep_ops;
        //Move from usb_ep_autoconfig_reset
        ep->driver_data = NULL;
		/**
		 * @todo NGS: What should the max packet size be set to
		 * here?  Before EP type is set?
		 */
		ep->maxpacket = MAX_PACKET_SIZE;

		list_add_tail(&ep->ep_list, &d->gadget.ep_list);
	}
#endif
	/* remove ep0 from the list.  There is a ep0 pointer. */
	list_del_init(&d->ep0.ep_list);
    ep_list_head = d->gadget.ep_list;
//    printk("%s : ep_list_head %x \n",__func__,ep_list_head);
	d->ep0.maxpacket = MAX_EP0_SIZE;

}
//EXPORT_SYMBOL(gadget_add_eps);

/**
 * This function releases the Gadget device.
 * required by device_unregister().
 *
 * @todo Should this do something?	Should it free the PCD?
 */
static void dwc_otg_pcd_gadget_release(struct device *dev)
{
	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, dev);
}

//extern struct device lmdev_dev;
static struct gadget_wrapper *alloc_wrapper(struct platform_device *pdev)
{
	static char pcd_name[] = "dwc_otg_pcd";
	dwc_otg_device_t *otg_dev = dev_get_drvdata(&pdev->dev);
	struct gadget_wrapper *d;
	int retval;

	d = dwc_alloc(sizeof(*d));
	if (d == NULL) {
		return NULL;
	}

    printk("%s : sizeof(*d) %x d %x \n",__func__,sizeof(*d),d);
	memset(d, 0, sizeof(*d));

	d->gadget.name = pcd_name;
	d->pcd = otg_dev->pcd;
//	strcpy(d->gadget.dev.bus_id, "gadget");
//    lmdev_dev = lmdev->dev;
	d->gadget.dev.parent = &pdev->dev;
	d->gadget.dev.release = dwc_otg_pcd_gadget_release;
	d->gadget.ops = &dwc_otg_pcd_ops;
	d->gadget.is_dualspeed = dwc_otg_pcd_is_dualspeed(otg_dev->pcd);
	d->gadget.is_otg = dwc_otg_pcd_is_otg(otg_dev->pcd);
#if 0
	int i;
	for (i=0;i<3;i++)
	{
        printk("%s : &d->in_ep[%x].ep_list %x\n",__func__,i,&d->in_ep[i].ep_list);
        printk("%s : &d->out_ep[%x].ep_list %x\n",__func__,i,&d->out_ep[i].ep_list);
        }
#endif
	d->driver = 0;
	/* Register the gadget device */
///	retval = device_register(&d->gadget.dev);
///	printk("%s : retval %x \n",__func__, retval);
///	if (retval != 0) {
///		DWC_ERROR("device_register failed\n");
///		dwc_free(d);
///		return NULL;
///	}

	return d;
}

static void free_wrapper(struct gadget_wrapper *d)
{
	if (d->driver) {
		/* should have been done already by driver model core */
		DWC_WARN("driver '%s' is still registered\n",
			 d->driver->driver.name);
		usb_gadget_unregister_driver(d->driver);
	}

///	device_unregister(&d->gadget.dev);
	dwc_free(d);
}

/**
 * This function registers a gadget driver with the PCD.
 *
 * When a driver is successfully registered, it will receive control
 * requests including set_configuration(), which enables non-control
 * requests.  then usb traffic follows until a disconnect is reported.
 * then a host may connect again, or the driver might get unbound.
 *
 * @param driver The driver being registered
 */
int usb_gadget_register_driver(struct usb_gadget_driver *driver)
{
	int retval;

	DWC_DEBUGPL(DBG_PCD, "registering gadget driver '%s'\n",
		    driver->driver.name);

	if (!driver || driver->speed == USB_SPEED_UNKNOWN ||
	    !driver->bind ||
	    !driver->unbind || !driver->disconnect || !driver->setup) {
		DWC_DEBUGPL(DBG_PCDV, "EINVAL\n");
		return -EINVAL;
	}
	if (gadget_wrapper_1 == 0) {
		DWC_DEBUGPL(DBG_PCDV, "ENODEV\n");
		return -ENODEV;
	}
	if (gadget_wrapper_1->driver != 0) {
		DWC_DEBUGPL(DBG_PCDV, "EBUSY (%p)\n", gadget_wrapper->driver);
		return -EBUSY;
	}

	/* hook up the driver */
	gadget_wrapper_1->driver = driver;
	gadget_wrapper_1->gadget.dev.driver = &driver->driver;
	gadget_wrapper_1->gadget.ep0 = e_temp;
	gadget_wrapper_1->gadget.ep_list = ep_list_head;

	DWC_DEBUGPL(DBG_PCD, "bind to driver %s\n", driver->driver.name);
	retval = driver->bind(&gadget_wrapper_1->gadget);
	if (retval) {
		DWC_ERROR("bind to driver %s --> error %d\n",
			  driver->driver.name, retval);
		gadget_wrapper_1->driver = 0;
		gadget_wrapper_1->gadget.dev.driver = 0;
		return retval;
	}
	DWC_DEBUGPL(DBG_ANY, "registered gadget driver '%s'\n",
		    driver->driver.name);
	return 0;
}

EXPORT_SYMBOL(usb_gadget_register_driver);

/**
 * This function unregisters a gadget driver
 *
 * @param driver The driver being unregistered
 */
int usb_gadget_unregister_driver(struct usb_gadget_driver *driver)
{
	//DWC_DEBUGPL(DBG_PCDV,"%s(%p)\n", __func__, _driver);

	if (gadget_wrapper_1 == 0) {
		DWC_DEBUGPL(DBG_ANY, "%s Return(%d): s_pcd==0\n", __func__,
			    -ENODEV);
		return -ENODEV;
	}
	if (driver == 0 || driver != gadget_wrapper_1->driver) {
		DWC_DEBUGPL(DBG_ANY, "%s Return(%d): driver?\n", __func__,
			    -EINVAL);
		return -EINVAL;
	}

	driver->unbind(&gadget_wrapper_1->gadget);
	gadget_wrapper_1->driver = 0;

	DWC_DEBUGPL(DBG_ANY, "unregistered driver '%s'\n", driver->driver.name);
	return 0;
}

EXPORT_SYMBOL(usb_gadget_unregister_driver);


/**
 * This function initialized the PCD portion of the driver.
 *
 */
int pcd_init(struct platform_device *pdev)
{
	dwc_otg_device_t *otg_dev = dev_get_drvdata(&pdev->dev);
	int retval = 0;
	int i;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, pdev);
	otg_dev->pcd = dwc_otg_pcd_init(otg_dev->core_if);
	if (!otg_dev->pcd) {
		DWC_ERROR("dwc_otg_pcd_init failed\n");
		return -ENOMEM;
	}

	gadget_wrapper_1 = alloc_wrapper(pdev);

	/*
	 * Initialize EP structures
	 */
	gadget_add_eps(gadget_wrapper_1);
#if 1
//	gadget_wrapper_1->gadget.ep0 = e_temp;
	gadget_wrapper_1->pcd->ep0.priv = e_temp;
//	for (i=0;i<3;i++)
//     {
//        gadget_wrapper_1->pcd->in_ep[i].priv = e_temp[i+1];
//        gadget_wrapper_1->pcd->out_ep[i].priv = e_temp[i+4];
//        }
#endif
	gadget_wrapper_1->gadget.ep_list = ep_list_head;
	/*
	 * Setup interupt handler
	 */

//	DWC_DEBUGPL(DBG_ANY, "registering handler for irq%d,%s\n", otg_dev->irq, gadget_wrapper_1->gadget.name);
	printk("registering handler for irq%d,%s\n", otg_dev->irq, gadget_wrapper_1->gadget.name);
#if 0
	retval = request_irq(otg_dev->irq, dwc_otg_pcd_irq,
			     IRQF_SHARED, gadget_wrapper_1->gadget.name,
			     otg_dev->pcd);
	if (retval != 0) {
		DWC_ERROR("request of irq%d failed\n", otg_dev->irq);
		free_wrapper(gadget_wrapper_1);
		return -EBUSY;
	}
#endif
//	dwc_otg_pcd_start(&gadget_wrapper_1->pcd, &fops);
	const struct dwc_otg_pcd_function_ops *temp;
	temp = &fops;

	gadget_wrapper_1->pcd->fops = temp;
//	dwc_otg_pcd_start(&gadget_wrapper_1->pcd, &fops);

	/*
	 * Enable the global interrupt after all the interrupt
	 * handlers are installed.
	 */
	/* dwc_otg_enable_global_interrupts(otg_dev->core_if); */
	return retval;
}
EXPORT_SYMBOL(pcd_init);


/**
 * Cleanup the PCD.
 */
void pcd_remove(struct platform_device *pdev)
{
	dwc_otg_device_t *otg_dev = dev_get_drvdata(&pdev->dev);
//	dwc_otg_pcd_t *pcd = otg_dev->pcd;

	DWC_DEBUGPL(DBG_PCDV, "%s(%p)\n", __func__, pdev);

	/*
	 * Free the IRQ
	 */
///	free_irq(otg_dev->irq, otg_dev->pcd);

	dwc_otg_pcd_remove(otg_dev->pcd);

	free_wrapper(gadget_wrapper_1);

	otg_dev->pcd = 0;
}

//#endif				/* DWC_HOST_ONLY */
