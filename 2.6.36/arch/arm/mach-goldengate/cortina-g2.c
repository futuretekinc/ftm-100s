/*
 *  linux/arch/arm/mach-goldengate/cortina-g2.c
 *
 * Copyright (c) Cortina-Systems Limited 2010.  All rights reserved.
 *                Jason Li <jason.li@cortina-systems.com>
 *
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

#include <linux/init.h>
#include <linux/platform_device.h>
//#include <linux/dma-mapping.h> /* for dma_alloc_writecombine */
#include <linux/sysdev.h>
#include <linux/amba/bus.h>
#include <linux/amba/pl061.h>
#include <linux/amba/mmci.h>
#include <linux/io.h>

#include <mach/hardware.h>
#include <mach/platform.h>
#include <mach/gpio.h>
#include <mach/gpio_alloc.h>
#include <linux/input.h>
#include <linux/gpio_keys.h>
#include <linux/gpio_buttons.h>
#include <mach/cs75xx_i2c.h>
#include <linux/spi/spi.h>
#include <mach/cs75xx_spi.h>
#include <mach/cs75xx_ir.h>
#include "../../../sound/soc/cs75xx/cs75xx_snd_sport.h"

#include <asm/irq.h>
#include <asm/leds.h>
#include <asm/mach-types.h>
#include <asm/hardware/gic.h>
#include <asm/hardware/icst.h>
#include <asm/hardware/cache-l2x0.h>
#include <asm/localtimer.h>

#include <asm/mach/arch.h>
#include <asm/mach/map.h>
#include <asm/mach/time.h>
#include <asm/mach/irq.h>

#include <mach/irqs.h>
#include <mach/vmalloc.h>
#include <mach/debug_print.h>
#include <mach/cs75xx_adma.h>

#include <mach/cs752x_clcdfb.h>

#include "core.h"
/* #include "clock.h" */

static u64 cs75xx_dmamask = 0xffffffffUL;
static DEFINE_SPINLOCK(regbus_irq_controller_lock);
static DEFINE_SPINLOCK(dmaeng_irq_controller_lock);
static DEFINE_SPINLOCK(dmassp_irq_controller_lock);

void __iomem *gic_cpu_base_addr;
#ifdef CONFIG_ACP
unsigned int acp_enabled = 0;
#endif
extern u32 cs_acp_enable;
static struct map_desc goldengate_io_desc[] __initdata = {

	{
	 .virtual = IO_ADDRESS(GOLDENGATE_GLOBAL_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_GLOBAL_BASE),
	 .length = SZ_8M,
	 .type = MT_DEVICE,
	 },
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_SCU_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_SCU_BASE),
	 .length = SZ_8K,
	 .type = MT_DEVICE,
	 },
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_TWD_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_TWD_BASE),
	 .length = SZ_4K,
	 .type = MT_DEVICE,
	 },
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RTC_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RTC_BASE),
	 .length = SZ_4K,
	 .type = MT_DEVICE,
	 },
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_L220_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_L220_BASE),
	 .length = SZ_8K,
	 .type = MT_DEVICE,
	 },
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_XRAM_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_XRAM_BASE),
	 .length = SZ_1M,
	 .type = MT_DEVICE,
	 },
	{
         .virtual = IO_ADDRESS(GOLDENGATE_AHCI_BASE),
         .pfn = __phys_to_pfn(GOLDENGATE_AHCI_BASE),
         .length = SZ_4K,
         .type = MT_DEVICE,
         },
	/* RCPU I/DRAM  */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_DRAM0_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_DRAM0_BASE),
	 .length = SZ_256K,
	 .type = MT_DEVICE,
	 },
	/* RRAM0 */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_RRAM0_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_RRAM0_BASE),
	 .length = SZ_32K,
	 .type = MT_DEVICE,
	 },
	/* RRAM1 */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_RRAM1_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_RRAM1_BASE),
	 .length = SZ_32K,
	 .type = MT_DEVICE,
	 },
	/* Crypto Core0 */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_CRYPT0_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_CRYPT0_BASE),
	 .length = SZ_64K,
	 .type = MT_DEVICE,
	 },
	/* Crypto Core0 */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_CRYPT1_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_CRYPT1_BASE),
	 .length = SZ_64K,
	 .type = MT_DEVICE,
	 },
	/* RCPU_REG  */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_REG_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_REG_BASE),
	 .length = SZ_512K,
	 .type = MT_DEVICE,
	 },
	/* RCPU SADB */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_SADB_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_SADB_BASE),
	 .length = SZ_64K,
	 .type = MT_DEVICE,
	 },
	/* RCPU PKT Buffer */
	{
	 .virtual = IO_ADDRESS(GOLDENGATE_RCPU_PKBF_BASE),
	 .pfn = __phys_to_pfn(GOLDENGATE_RCPU_PKBF_BASE),
	 .length = SZ_256K,
	 .type = MT_DEVICE,
	 },

#ifdef CONFIG_CS75xx_IPC2RCPU
	/* Share memory for Re-circulation CPU */
	{
	 .virtual = VMALLOC_END,
	 .pfn = __phys_to_pfn(GOLDENGATE_IPC_BASE),
	 .length = GOLDENGATE_IPC_MEM_SIZE,
	 .type = MT_DEVICE,
	 },
#endif
	{
	 .virtual = IO_ADDRESS( GOLDENGATE_OTP_BASE ),
	 .pfn = __phys_to_pfn( GOLDENGATE_OTP_BASE ),
	 .length = SZ_1K,
	 .type = MT_DEVICE,
	},
};

static void __init goldengate_map_io(void)
{
	iotable_init(goldengate_io_desc, ARRAY_SIZE(goldengate_io_desc));
}

/* FPGA Primecells */
#if (defined(CONFIG_FB_CS752X_CLCD) | defined(CONFIG_FB_CS752X_CLCD_MODULE))
//    Added by SJ, 20120328
//	GLOBAL_SCRATCH: 0xf00000c0
//    bit 13: 0 - the LCD base clock is 250MHz
//               1 - the LCD base clock is 150MHz
#define CLCDCLK_150M       (1 << 13)

static int cs75xx_fb_get_clk_div(unsigned int target_clk)
{
//	printk("cs75xx_fb_get_clk_div :  target_clk %d------\n",target_clk);
	if ((target_clk >= 148500) && (target_clk <= 150000)) { /* pixel clock = 150 = 150MHz  */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) | CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
//		bypass
		return -1;
	} else if ((target_clk >= 74000) && (target_clk <= 75000)) { /* pixel clock = 150/(0+2) = 75MHz  */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) | CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 0;
	} else if ((target_clk >= 60000) && (target_clk <= 65100)) {	/* pixel clock = 250/(2+2) = 62.5MHz  */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) & ~CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 2;
	} else if ((target_clk >= 50000) && (target_clk < 51000)) {	/* pixel clock = 250/(3+2) = 50MHz  */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) & ~CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 2;
	} else if ((target_clk >= 40000) && (target_clk < 41000) ) {	/* pixel clock = 250/(4+2) = 41.67 MHz */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) & ~CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 4;
	} else if ((target_clk >= 27000) && (target_clk < 30000)) {	/* pixel clock = 250/(7+2) = 27.7 MHz */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) & ~CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 7;
	} else if ((target_clk >= 25000) && (target_clk < 27000)) { /* pixel clock = 250/(8+2) = 25MHz */
		writel(readl(IO_ADDRESS(GLOBAL_SCRATCH)) & ~CLCDCLK_150M, IO_ADDRESS(GLOBAL_SCRATCH));
		return 8;
	} else {
		printk("target_clk :%d, Error not in table list",target_clk);
		return 0;
	}

}

static struct cs75xx_fb_plat_data fb_plat_data = {
        .get_clk_div=cs75xx_fb_get_clk_div,
};


static struct resource cs75xx_lcdc_resources[] = {
        [0] = {
                .start = GOLDENGATE_LCDC_BASE,
                .end = GOLDENGATE_LCDC_BASE + SZ_4K - 1,
                .flags = IORESOURCE_MEM,
        },
        [1] = {
                .start = IRQ_LCD,
                .end = IRQ_LCD,
                .flags = IORESOURCE_IRQ,
        },
};

static u64 cs75xx_device_lcd_dmamask = 0xffffffffUL;
struct platform_device cs75xx_lcd_device = {
        .name             = "cs75xx_lcdfb",
        .id               = -1,
        .dev            = {
                .dma_mask               = &cs75xx_device_lcd_dmamask,
                .coherent_dma_mask      = 0xffffffffUL,
                .platform_data= &fb_plat_data,
        },
        .resource       = cs75xx_lcdc_resources,
        .num_resources  = ARRAY_SIZE(cs75xx_lcdc_resources),
};

void __init cs75xx_add_device_lcd(void)
{
	/* GPIO 4 Bit[28:0] */
	int status;
	status = readl(IO_ADDRESS(GLOBAL_GPIO_MUX_4));
	status &= ~0x1FFFFFFF;  /* GPIO 4 Bit[28:0] */
	printk("write gpio %x \n",status);
	writel(status, IO_ADDRESS(GLOBAL_GPIO_MUX_4));
	//MEMORY Priority
	writel(0xffff00, IO_ADDRESS(0xf050012c));
	platform_device_register(&cs75xx_lcd_device);
}
#else
void __init cs75xx_add_device_lcd(void) {}
#endif


/*
 * GoldenGate EB platform devices
 */
/*
static struct resource goldengate_flash_resource = {
	.start			= GOLDENGATE_FLASH_BASE,
	.end			= GOLDENGATE_FLASH_BASE + GOLDENGATE_FLASH_SIZE - 1,
	.flags			= IORESOURCE_MEM,
};

static struct resource goldengate_eth_resources[] = {
	[0] = {
		.start		= GOLDENGATE_NEMAC_BASE,
		.end		= GOLDENGATE_NEMAC_BASE + SZ_64K - 1,
		.flags		= IORESOURCE_MEM,
	},
	[1] = {
		.start		= IRQ_EB_ETH,
		.end		= IRQ_EB_ETH,
		.flags		= IORESOURCE_IRQ,
	},
};
*/
static struct resource goldengate_ahci_resources[] = {
	[0] = {
	       .start = GOLDENGATE_AHCI_BASE,
	       .end = GOLDENGATE_AHCI_BASE + SZ_64K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_AHCI,
	       .end = GOLDENGATE_IRQ_AHCI,
	       .flags = IORESOURCE_IRQ,
	       },
};

/* Platform device */
struct platform_device goldengate_ahci_device = {
	.name = "goldengate-ahci",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_ahci_resources),
	.resource = goldengate_ahci_resources,
};

#ifdef CONFIG_CORTINA_G2_ADMA
/* Async. DMA */
static struct resource goldengate_adma_resources[] = {
	[0] = {
	       .start = GOLDENGATE_DMA_BASE,
	       .end = GOLDENGATE_DMA_BASE + SZ_1K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_DMA_RX6,
	       .end = GOLDENGATE_IRQ_DMA_RX6,
	       .flags = IORESOURCE_IRQ,
	       },
	[2] = {
	       .start = GOLDENGATE_IRQ_DMA_TX6,
	       .end = GOLDENGATE_IRQ_DMA_TX6,
	       .flags = IORESOURCE_IRQ,
	       },
};

struct platform_device goldengate_dma_device = {
	.name = "cs75xx_adma",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_adma_resources),
	.resource = goldengate_adma_resources,
};
#endif

static struct resource goldengate_ts_resources[] = {
	[0] = {
	       .start = GOLDENGATE_TS_BASE,
	       .end = GOLDENGATE_TS_BASE + SZ_64K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_TS,
	       .end = GOLDENGATE_IRQ_TS,
	       .flags = IORESOURCE_IRQ,
	       },
};

struct platform_device goldengate_ts_device = {
	.name = "g2-ts",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_ts_resources),
	.resource = goldengate_ts_resources,
};

static struct resource goldengate_wdt_resources[] = {
	[0] = {
	       .start = GOLDENGATE_TWD_BASE,
	       .end = GOLDENGATE_TWD_BASE + SZ_1K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_WDT,
	       .end = GOLDENGATE_IRQ_WDT,
	       .flags = IORESOURCE_IRQ,
	       },
};

struct platform_device goldengate_wdt_device = {
	.name = "g2-wdt",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_wdt_resources),
	.resource = goldengate_wdt_resources,
};

static struct resource goldengate_flash_resources[] = {
	[0] = {
	       .start = GOLDENGATE_FLASH_BASE,
	       .end = GOLDENGATE_FLASH_BASE + SZ_128M - 1,
	       .flags = IORESOURCE_IO,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_FLSH,
	       .end = GOLDENGATE_IRQ_FLSH,
	       .flags = IORESOURCE_IRQ,
	       },
};

struct platform_device goldengate_flash_device = {
	.name = "cs752x_nand",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_flash_resources),
	.resource = goldengate_flash_resources,
};

static struct resource goldengate_rtc_resources[] = {
	[0] = {
	       .start = GOLDENGATE_RTC_BASE,
	       .end = GOLDENGATE_RTC_BASE + SZ_1K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = IRQ_RTC_ALM,
	       .end = IRQ_RTC_ALM,
	       .flags = IORESOURCE_IRQ,
	       },
	[2] = {
	       .start = IRQ_RTC_PRI,
	       .end = IRQ_RTC_PRI,
	       .flags = IORESOURCE_IRQ,
	       },
};

struct platform_device goldengate_rtc_device = {
	.name = "g2-rtc",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_rtc_resources),
	.resource = goldengate_rtc_resources,
};

#if defined(CONFIG_CS752X_SD)
#define SD_DEVICE_NAME "cs752x_sd"
static struct resource goldengate_sd_resources[] = {
	[0] = {
	       .start = GOLDENGATE_SDC_BASE,
	       .end = GOLDENGATE_SDC_BASE + SZ_64K - 1,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = GOLDENGATE_IRQ_MMC,
	       .end = GOLDENGATE_IRQ_MMC,
	       .flags = IORESOURCE_IRQ,
	       },
};
struct platform_device goldengate_sd_device = {
	.name = SD_DEVICE_NAME,
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_sd_resources),
	.resource = goldengate_sd_resources,
};
#endif				/* CONFIG_CS752X_SD */

static struct resource cs75xx_gpio_resources[] = {
	[0] = {
	       .name = "global",
	       .start = GOLDENGATE_GLOBAL_BASE,
	       .end = GOLDENGATE_GLOBAL_BASE + 0xBB,
	       .flags = IORESOURCE_IO,
	       },
	[1] = {
	       .name = "gpio0",
	       .start = GOLDENGATE_GPIO0_BASE,
	       .end = GOLDENGATE_GPIO1_BASE - 1,
	       .flags = IORESOURCE_IO,
	       },
	[2] = {
	       .name = "gpio1",
	       .start = GOLDENGATE_GPIO1_BASE,
	       .end = GOLDENGATE_GPIO2_BASE - 1,
	       .flags = IORESOURCE_IO,
	       },
	[3] = {
	       .name = "gpio2",
	       .start = GOLDENGATE_GPIO2_BASE,
	       .end = GOLDENGATE_GPIO3_BASE - 1,
	       .flags = IORESOURCE_IO,
	       },
	[4] = {
	       .name = "gpio3",
	       .start = GOLDENGATE_GPIO3_BASE,
	       .end = GOLDENGATE_GPIO4_BASE - 1,
	       .flags = IORESOURCE_IO,
	       },
	[5] = {
	       .name = "gpio4",
	       .start = GOLDENGATE_GPIO4_BASE,
	       .end = GOLDENGATE_GPIO4_BASE + 0x1B,
	       .flags = IORESOURCE_IO,
	       },
	[6] = {
	       .name = "irq_gpio0",
	       .start = GOLDENGATE_IRQ_GPIO0,
	       .end = GOLDENGATE_IRQ_GPIO0,
	       .flags = IORESOURCE_IRQ,
	       },
	[7] = {
	       .name = "irq_gpio1",
	       .start = GOLDENGATE_IRQ_GPIO1,
	       .end = GOLDENGATE_IRQ_GPIO1,
	       .flags = IORESOURCE_IRQ,
	       },
	[8] = {
	       .name = "irq_gpio2",
	       .start = GOLDENGATE_IRQ_GPIO2,
	       .end = GOLDENGATE_IRQ_GPIO2,
	       .flags = IORESOURCE_IRQ,
	       },
	[9] = {
	       .name = "irq_gpio3",
	       .start = GOLDENGATE_IRQ_GPIO3,
	       .end = GOLDENGATE_IRQ_GPIO3,
	       .flags = IORESOURCE_IRQ,
	       },
	[10] = {
		.name = "irq_gpio4",
		.start = GOLDENGATE_IRQ_GPIO4,
		.end = GOLDENGATE_IRQ_GPIO4,
		.flags = IORESOURCE_IRQ,
		},
};

static struct platform_device cs75xx_gpio_device = {
	.name = CS75XX_GPIO_CTLR_NAME,
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_gpio_resources),
	.resource = cs75xx_gpio_resources,
};

static struct gpio_keys_button cs75xx_gpio_keys[] = {
#ifdef GPIO_WPS_SW
	{
		/* Configuration parameters */
		.code = KEY_WPS_BUTTON,
		.gpio = GPIO_WPS_SW,
		.active_low = 1,
		.desc = "GPIO_WPS_SW",
		.type = EV_KEY,		/* input event type (EV_KEY, EV_SW) */
		.wakeup = 1,		/* configure the button as a wake-up source */
		.debounce_interval = 0,	/* debounce ticks interval in msecs */
		.can_disable = 1	/* dedicated pin */
	},
#endif
#ifdef GPIO_WIFI_SW
	[1] = {
		/* Configuration parameters */
		.code = KEY_WLAN,
		.gpio = GPIO_WIFI_SW,
		.active_low = 1,
		.desc = "GPIO_WIFI_SW",
		.type = EV_KEY, 	/* input event type (EV_KEY, EV_SW) */
		.wakeup = 1,		/* configure the button as a wake-up source */
		.debounce_interval = 0,	/* debounce ticks interval in msecs */
		.can_disable = 1
	},
#endif
};

static struct gpio_keys_platform_data cs75xx_gpio_keys_platform = {
	.buttons = cs75xx_gpio_keys,
	.nbuttons = ARRAY_SIZE(cs75xx_gpio_keys),
	.rep = 0,		/* enable input subsystem auto repeat */
	.enable = NULL,
	.disable = NULL
};

static struct platform_device cs75xx_gpio_keys_device = {
	.name = "gpio-keys",
	.id = -1,
	.dev = {
		.power.can_wakeup = 1,
		.power.should_wakeup = 1,
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		.platform_data = &cs75xx_gpio_keys_platform
	},
};

static struct gpio_button cs75xx_gpio_btns[] = {
#ifdef GPIO_FACTORY_DEFAULT
	{
		.gpio = GPIO_FACTORY_DEFAULT,
		.active_low = 1,
		.desc = "GPIO_FACTORY_DEFAULT",
		.type = EV_KEY,
		.code = KEY_VENDOR,
		.threshold = FACTORY_DEFAULT_TIME,
	},
#endif
};

static struct gpio_buttons_platform_data cs75xx_gpio_btns_platform = {
	.buttons = cs75xx_gpio_btns,
	.nbuttons = ARRAY_SIZE(cs75xx_gpio_btns),
#ifdef GPIO_BTNS_POLLING_INTERVAL
	.poll_interval = GPIO_BTNS_POLLING_INTERVAL,
#endif
};

static struct platform_device cs75xx_gpio_btns_device = {
	.name = "gpio-buttons",
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		.platform_data = &cs75xx_gpio_btns_platform
		},
};

static struct gpio_led cs75xx_leds[] = {
#ifdef GPIO_VOIP_LED
	{
		.name = "voip:green",
		.gpio = GPIO_VOIP_LED,
		.active_low = 0,
		.default_state = LEDS_GPIO_DEFSTATE_OFF,
	},
#endif
#ifdef GPIO_SYS_RDY_LED
	{
		.name = "sys",
		.gpio = GPIO_SYS_RDY_LED,
		.active_low = 0,
		.default_state = LEDS_GPIO_DEFSTATE_OFF,
	},
#endif
#ifdef GPIO_USB_LED
	{
		.name = "usb",
		.gpio = GPIO_USB_LED,
		.active_low = 0,
		.default_state = LEDS_GPIO_DEFSTATE_OFF,
	},
#endif
#ifdef GPIO_USB_LED0
	{
		.name = "usb0",
		.gpio = GPIO_USB_LED0,
		.active_low = 0,
		.default_state = LEDS_GPIO_DEFSTATE_OFF,
	},
#endif
#ifdef GPIO_USB_LED1
	{
		.name = "usb1",
		.gpio = GPIO_USB_LED1,
		.active_low = 0,
		.default_state = LEDS_GPIO_DEFSTATE_OFF,
	},
#endif
};

static struct gpio_led_platform_data cs75xx_led_platform_data = {
	.leds		= cs75xx_leds,
	.num_leds	= ARRAY_SIZE(cs75xx_leds),
};

static struct platform_device cs75xx_led_device = {
	.name	= "leds-gpio",
	.id	= -1,
	.dev	= {
		.platform_data = &cs75xx_led_platform_data,
	},
};

static struct cs75xx_i2c_pdata cs75xx_i2c_cfg = {
	APB_CLOCK,
	100000,
	100,
	3
};

static struct resource cs75xx_i2c_resources[] = {
	{
	 .name = "i2c",
	 .start = GOLDENGATE_BIW_BASE,
	 .end = GOLDENGATE_BIW_BASE + 0x27,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_i2c",
	 .start = GOLDENGATE_IRQ_BIWI,
	 .end = GOLDENGATE_IRQ_BIWI,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_i2c_device = {
	.name = CS75XX_I2C_CTLR_NAME,
	.id = -1,
	.dev = {
		.platform_data = &cs75xx_i2c_cfg,
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_i2c_resources),
	.resource = cs75xx_i2c_resources,
};

static struct i2c_board_info i2c_board_infos[] __initdata = {
#if defined(CONFIG_CORTINA_FPGA)
	{
	 I2C_BOARD_INFO("cs4341", 0x10),
	 .flags = 0,
	 .irq = 0,
	 .platform_data = NULL,
	},
#endif
#if defined(CONFIG_CORTINA_ENGINEERING) || defined(CONFIG_CORTINA_ENGINEERING_S)
#if defined(CONFIG_SND_SOC_DAE4P)
	{
	 I2C_BOARD_INFO("dae4p", 0x59),
	 .flags = 0,
	 .irq = 0,
#if defined(CONFIG_CORTINA_ENGINEERING)
	 .platform_data = GPIO_SLIC1_RESET,
#elif defined(CONFIG_CORTINA_ENGINEERING_S)
	 .platform_data = GPIO_SLIC0_RESET,
#endif
	},
#endif
#endif
#if defined(CONFIG_CORTINA_ENGINEERING) || defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 I2C_BOARD_INFO("si5338_70", 0x70),
	 .flags = 0,
	 .irq = 0,
	 .platform_data = NULL,
	},
#if !defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 I2C_BOARD_INFO("si5338_71", 0x71),
	 .flags = 0,
	 .irq = 0,
	 .platform_data = NULL,
	},
#endif
#endif
#if defined(CONFIG_CORTINA_ENGINEERING) || defined(CONFIG_CORTINA_PON) \
	|| defined(CONFIG_CORTINA_WAN)
	{
		I2C_BOARD_INFO("anx9805-sys", 0x39),
		.flags = 0,
		.irq = 0,
		.platform_data = NULL,
	},
	{
		I2C_BOARD_INFO("anx9805-dp", 0x38),
		.flags = 0,
		.irq = 0,
		.platform_data = NULL,
	},
	{
		I2C_BOARD_INFO("anx9805-hdmi", 0x3d),
		.flags = 0,
		.irq = 0,
		.platform_data = NULL,
	},
#endif
};

static struct cs75xx_spi_info cs75xx_spi_cfg = {
	.tclk = APB_CLOCK,
	.divider = CS75XX_SPI_CLOCK_DIV,
	.timeout = (2 * HZ)
};

static struct resource cs75xx_spi_resources[] = {
	{
	 .name = "spi",
	 .start = GOLDENGATE_SPI_BASE,
	 .end = GOLDENGATE_SPI_BASE + 0x3B,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_spi",
	 .start = GOLDENGATE_IRQ_SPI,
	 .end = GOLDENGATE_IRQ_SPI,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_spi_device = {
	.name = CS75XX_SPI_CTLR_NAME,
	.id = -1,
	.dev = {
		.platform_data = &cs75xx_spi_cfg,
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_spi_resources),
	.resource = cs75xx_spi_resources,
};

static struct spi_board_info spi_board_infos[] __initdata = {

#if defined(CONFIG_CORTINA_CUSTOM_BOARD)


/* custom board patch start HERE: */

/* Review contents of included template below. After review, apply patch to replace 
 * everything between the start HERE: comment above to the and end HERE: comment below
 * including the start HERE: and end HERE: lines themselves. 
 *
 * This patch should also remove the warning below and also change inclusion path to be a location 
 * within YOUR own custom_board/my_board_name tree which will not be overwritten by
 * future Cortina releases.   
 *
 * WARNING: Do NOT remove or change the CONFIG_CORTINA_CUSTOM_BOARD pre-processor definition name above.
 * Cortina will only support custom board builds which use the CONFIG_CORTINA_CUSTOM_BOARD definition.
 */

#if defined(CONFIG_FTG_1000) || \
	defined(CONFIG_FTW_1000) || \
	defined(CONFIG_FTM_100S) || \
	defined(CONFIG_FTW_1000_V2) || \
	defined(CONFIG_FTM_NICO2) 
#else
#warning CUSTOM_BOARD_REVIEW_ME
#include <mach/custom_board/template/spi/cfg_spi_board_info.h>

/* custom board patch end HERE: */
#endif

#else /* defined(CONFIG_CORTINA_CUSTOM_BOARD) else */


#if !defined(CONFIG_CORTINA_BHR) && defined(CONFIG_SLIC_VE880_SLOT0)
	{
	 .modalias = "ve880_slot0",
	 .platform_data = GPIO_SLIC0_RESET,
#if defined(CONFIG_CORTINA_ENGINEERING_S) || defined(CONFIG_CORTINA_REFERENCE_S)
	 .irq = -1,	/* not support SLIC interrupt */
#else
	 .irq = GPIO_SLIC_INT,
#endif /* defined(CONFIG_CORTINA_ENGINEERING_S) || defined(CONFIG_CORTINA_REFERENCE_S) */
	 .max_speed_hz = 8000000,
	 .bus_num = 0,
#if defined(CONFIG_CORTINA_FPGA) || defined(CONFIG_CORTINA_REFERENCE) \
	 || defined(CONFIG_CORTINA_REFERENCE_B) || defined(CONFIG_CORTINA_PON) \
	 || defined(CONFIG_CORTINA_WAN) || defined(CONFIG_CORTINA_REFERENCE_Q) 
	 .chip_select = 0,
#elif defined(CONFIG_CORTINA_ENGINEERING) || defined(CONFIG_CORTINA_ENGINEERING_S) || defined(CONFIG_CORTINA_REFERENCE_S)
	 .chip_select = 1,
#endif /* defined(CONFIG_CORTINA_ENGINEERING_S) || defined(CONFIG_CORTINA_REFERENCE_S) ...defined(CONFIG_CORTINA_REFERENCE_Q) endif */
	 .mode = (CS75XX_SPI_MODE_ISAM)|SPI_MODE_3
	 },
#endif /* !defined(CONFIG_CORTINA_BHR) && defined(CONFIG_SLIC_VE880_SLOT0) endif */

#if defined(CONFIG_CORTINA_ENGINEERING) && defined(CONFIG_SLIC_VE880_SLOT1)
	{
	 .modalias = "ve880_slot1",
	 .platform_data = GPIO_SLIC1_RESET,
	 .irq = GPIO_SLIC_INT,
	 .max_speed_hz = 8000000,
	 .bus_num = 0,
	 .chip_select = 2,
	 .mode = (CS75XX_SPI_MODE_ISAM)|SPI_MODE_3
	 },
#endif

#if defined(CONFIG_SLIC_SI3226X_SLOT0)	 
	// For silicon lab si3226x SLIC IC.
	{
	 .modalias = "si3226x_slot0",
	 .platform_data = GPIO_SLIC0_RESET,
	 .irq = GPIO_SLIC_INT,
	 .max_speed_hz = 8000000,
	 .bus_num = 0,
	 .chip_select = 0,
	 .mode = (CS75XX_SPI_MODE_ISAM)|SPI_MODE_3
	 },
#endif

#if defined(CONFIG_SLIC_SI3226X_SLOT1)	
	{
	 .modalias = "si3226x_slot1",
	 .platform_data = GPIO_SLIC1_RESET,
	 .irq = GPIO_SLIC_INT,
	 .max_speed_hz = 8000000,
	 .bus_num = 0,
	 .chip_select = 1,
	 .mode = (CS75XX_SPI_MODE_ISAM)|SPI_MODE_3
	 },
#endif
#if defined(CONFIG_PANEL_HX8238A)
        {       /* HX8238A TFT LCD Single Chip */
         .modalias = "hx8238a_panel",
         .max_speed_hz = 200000,
         .bus_num = 0,
         .chip_select = 3,
         .mode = SPI_MODE_3},   /* CPOL=1, CPHA=1 */
#endif  /* CONFIG_PANEL_HX8238A */
#endif /* defined(CONFIG_CORTINA_CUSTOM_BOARD) endif */
};

static struct resource cs75xx_ir_resources[] = {
	{
	 .name = "cir",
	 .start = GOLDENGATE_CIR_BASE,
	 .end = GOLDENGATE_CIR_BASE + 0x33,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_cir",
	 .start = GOLDENGATE_IRQ_CIR,
	 .end = GOLDENGATE_IRQ_CIR,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_ir_device = {
	.name = CS75XX_IR_NAME,
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_ir_resources),
	.resource = cs75xx_ir_resources,
};

static struct resource cs75xx_pwr_resources[] = {
	{
	 .name = "cir",
	 .start = GOLDENGATE_CIR_BASE,
	 .end = GOLDENGATE_CIR_BASE + 0x33,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_pwr",
	 .start = GOLDENGATE_IRQ_PWC,
	 .end = GOLDENGATE_IRQ_PWC,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_pwr_device = {
	.name = "cs75xx-pwr",
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_pwr_resources),
	.resource = cs75xx_pwr_resources,
};

static struct resource cs75xx_sport_resources[] = {
	/* SSP */
	{
	 .name = "ssp0",
	 .start = GOLDENGATE_SSP0_BASE,
	 .end = GOLDENGATE_SSP0_BASE + 0x57,
	 .flags = IORESOURCE_IO,
	 },
#if !defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 .name = "ssp1",
	 .start = GOLDENGATE_SSP1_BASE,
	 .end = GOLDENGATE_SSP1_BASE + 0x57,
	 .flags = IORESOURCE_IO,
	 },
#endif
	{
	 .name = "irq_ssp0",
	 .start = GOLDENGATE_IRQ_DMASSP_SSP0,
	 .end = GOLDENGATE_IRQ_DMASSP_SSP0,
	 .flags = IORESOURCE_IRQ,
	 },
#if !defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 .name = "irq_ssp1",
	 .start = GOLDENGATE_IRQ_DMASSP_SSP1,
	 .end = GOLDENGATE_IRQ_DMASSP_SSP1,
	 .flags = IORESOURCE_IRQ,
	 },
#endif
	/* SPDIF */
	{
	 .name = "spdif",
#ifdef CONFIG_CORTINA_FPGA
	 .start = 0xF0700000,
	 .end = 0xF0700000 + 0xf7,
#else
	 .start = GOLDENGATE_SPDIF_BASE,
	 .end = GOLDENGATE_SPDIF_BASE + 0xf7,
#endif
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_spdif",
#ifdef CONFIG_CORTINA_FPGA
	.start = GOLDENGATE_IRQ_SSP0,
	.end = GOLDENGATE_IRQ_SSP0,
#else
	 .start = GOLDENGATE_IRQ_SPDIF,
	 .end = GOLDENGATE_IRQ_SPDIF,
#endif
	 .flags = IORESOURCE_IRQ,
	 },
	/* DMA */
	{
	 .name = "dma_ssp",
	 .start = DMA_DMA_SSP_RXDMA_CONTROL,
	 .end = DMA_DMA_SSP_RXDMA_CONTROL + 0xE7,
	 .flags = IORESOURCE_DMA,
	 },
	{
	 .name = "dma_desc",
	 .start = GOLDENGATE_IRQ_DMASSP_DESC,
	 .end = GOLDENGATE_IRQ_DMASSP_DESC,
	 .flags = IORESOURCE_IRQ,
	 },
	{
	 .name = "dma_rx_ssp0",
	 .start = GOLDENGATE_IRQ_DMASSP_RX6,
	 .end = GOLDENGATE_IRQ_DMASSP_RX6,
	 .flags = IORESOURCE_IRQ,
	 },
#if !defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 .name = "dma_rx_ssp1",
	 .start = GOLDENGATE_IRQ_DMASSP_RX7,
	 .end = GOLDENGATE_IRQ_DMASSP_RX7,
	 .flags = IORESOURCE_IRQ,
	 },
#endif
	{
	 .name = "dma_tx_ssp0",
	 .start = GOLDENGATE_IRQ_DMASSP_TX6,
	 .end = GOLDENGATE_IRQ_DMASSP_TX6,
	 .flags = IORESOURCE_IRQ,
	 },
#if !defined(CONFIG_CORTINA_ENGINEERING_S)
	{
	 .name = "dma_tx_ssp1",
	 .start = GOLDENGATE_IRQ_DMASSP_TX7,
	 .end = GOLDENGATE_IRQ_DMASSP_TX7,
	 .flags = IORESOURCE_IRQ,
	 },
#endif
};

static struct platform_device cs75xx_sport_device = {
	.name = "cs75xx-sport",
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_sport_resources),
	.resource = cs75xx_sport_resources,
};

#if defined(CONFIG_SND_SOC_SPDIF)
static struct platform_device spdif_dit_device = {
	.name = "spdif-dit",
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources =0,
	.resource = NULL,
};
#endif

#ifdef CONFIG_HW_RANDOM_CS75XX
static struct resource cs75xx_trng_resources[] = {
	{
	 .name = "trng",
	 .start = GOLDENGATE_TRNG_BASE,
	 .end = GOLDENGATE_TRNG_BASE + 0x1B,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_trng",
	 .start = GOLDENGATE_IRQ_TRNG,
	 .end = GOLDENGATE_IRQ_TRNG,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_trng_device = {
	.name = "cs75xx_trng",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_trng_resources),
	.resource = cs75xx_trng_resources,
};
#endif				/* CONFIG_HW_RANDOM_CS75XX */

static struct resource cs75xx_spacc_resources[] = {
	{
	 .name = "spacc0",
	 .start = GOLDENGATE_RCPU_CRYPT0_BASE,
	 .end = GOLDENGATE_RCPU_CRYPT0_BASE + 0x000C0000,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "spacc1",
	 .start = GOLDENGATE_RCPU_CRYPT1_BASE,
	 .end = GOLDENGATE_RCPU_CRYPT1_BASE + 0x000C0000,
	 .flags = IORESOURCE_IO,
	 },
	{
	 .name = "irq_spacc0",
	 .start = GOLDENGATE_IRQ_CRYPT0,
	 .end = GOLDENGATE_IRQ_CRYPT0,
	 .flags = IORESOURCE_IRQ,
	 },
	{
	 .name = "irq_spacc1",
	 .start = GOLDENGATE_IRQ_CRYPT1,
	 .end = GOLDENGATE_IRQ_CRYPT1,
	 .flags = IORESOURCE_IRQ,
	 },
};

static struct platform_device cs75xx_spacc_device = {
	.name = "cs75xx_spacc",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_spacc_resources),
	.resource = cs75xx_spacc_resources,
};

/* G2 NE */
static struct resource goldengate_ne_resources[] = {
	{
	 .name = "g2_ne",
	 .start = GOLDENGATE_NI_TOP_BASE,
	 .end = GOLDENGATE_NI_TOP_BASE + (5 * SZ_64K) - 1,
	 .flags = IORESOURCE_MEM,
	 },
	{
	 .name = "irq_ne",
	 .start = IRQ_NET_ENG,
	 .end = IRQ_NET_ENG,
	 .flags = IORESOURCE_IRQ,
	 },
};

struct platform_device goldengate_ne_device = {
	.name = "g2-ne",
	.id = 0,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(goldengate_ne_resources),
	.resource = goldengate_ne_resources,
};
/* G2 NE */

/* G2 Read/Write register */
static u64 g2_rw_dmamask = 0xffffffffUL;

static struct resource g2_rw_resources[] = {
	[0] = {
	       .start = GOLDENGATE_OHCI_BASE,
	       .end = GOLDENGATE_OHCI_BASE + 0x000000ff,
	       .flags = IORESOURCE_IO,
	       }
};

static struct platform_device g2_rw_device = {
	.name = "g2_rw",
	.id = -1,
//      .dev            = {*/
//              .dma_mask = &g2_rw_dmamask,*/
//              .coherent_dma_mask = 0xffffffff,*/
//      },*/
	.num_resources = ARRAY_SIZE(g2_rw_resources),
	.resource = g2_rw_resources,
};

/* #include "pcie.h" */
static u64 g2_pcie_dmamask = 0xffffffffUL;
static u64 g2_pcie_1_dmamask = 0xffffffffUL;

static struct resource g2_pcie_resources[] = {
	[0] = {
	       .name = "PCIe 0 Base Space",
	       .start = GOLDENGATE_PCIE0_BASE,
	       .end = GOLDENGATE_PCIE0_BASE + 0x1000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[1] = {
	       .name = "PCIe 0 I/O Space",
	       .start = GOLDENGATE_PCIE0_BASE + 0x1000,
	       .end = GOLDENGATE_PCIE0_BASE + 0x1000 + 0x5000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[2] = {
	       .name = "PCIe 0 irq",
	       .start = IRQ_PCIE0,
	       .end = IRQ_PCIE0,
	       .flags = IORESOURCE_IRQ,
	       },
	[3] = {
	       .name = "PCIe 1 Base Space",
	       .start = GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE,
	       .end =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE + 0x1000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[4] = {
	       .name = "PCIe 1 I/O Space",
	       .start =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE + 0x1000,
	       .end =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE + 0x1000 +
	       0x5000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[5] = {
	       .name = "PCIe 1 irq",
	       .start = IRQ_PCIE1,
	       .end = IRQ_PCIE1,
	       .flags = IORESOURCE_IRQ,
	       },
/* debug_Aaron on 04/15/2011 add for PCIe RC 2 */
#ifndef CONFIG_CORTINA_FPGA
	[6] = {
	       .name = "PCIe 2 Base Space",
	       .start = GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE * 2,
	       .end =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE * 2 + 0x1000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[7] = {
	       .name = "PCIe 2 I/O Space",
	       .start =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE * 2 + 0x1000,
	       .end =
	       GOLDENGATE_PCIE0_BASE + GOLDENGATE_PCI_MEM_SIZE * 2 + 0x1000 +
	       0x5000 - 1,
	       .flags = IORESOURCE_IO,
	       },
	[8] = {
	       .name = "PCIe 2 irq",
	       .start = IRQ_PCIE2,
	       .end = IRQ_PCIE2,
	       .flags = IORESOURCE_IRQ,
	       },
#endif
};

static struct platform_device goldengate_pcie_device = {
	.name = "g2_pcie",
	.id = -1,
	.dev = {
		.dma_mask = &g2_pcie_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(g2_pcie_resources),
	.resource = g2_pcie_resources,
};

/* cs752x USB host configuration */

static u64 cs752x_ehci_dmamask = 0xffffffffUL;
static u64 cs752x_ohci_dmamask = 0xffffffffUL;
static u64 cs752x_otg_dmamask = 0xffffffffUL;

static struct resource cs752x_ehci_resources[] = {
	[0] = {
	       .start = GOLDENGATE_EHCI_BASE,
	       .end = GOLDENGATE_EHCI_BASE + 0x0003ffff,
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = IRQ_USB_EHCI,
	       .end = IRQ_USB_EHCI,
	       .flags = IORESOURCE_IRQ,
	       },
};

#ifndef CONFIG_CORTINA_FPGA
static struct resource cs752x_ohci_resources[] = {
	[0] = {
	       .start = GOLDENGATE_OHCI_BASE,	/* 0xf4040000 */
	       .end = GOLDENGATE_OHCI_BASE + 0x00000fff,	/* 0xf407ffff */
	       .flags = IORESOURCE_MEM,
	       },
	[1] = {
	       .start = IRQ_USB_OHCI,
	       .end = IRQ_USB_OHCI,
	       .flags = IORESOURCE_IRQ,
	       },
};
#endif

static struct resource cs752x_otg_resources[] = {
	[0] = {
	       .start = GOLDENGATE_USB_DEVICE_BASE,
	       .end = GOLDENGATE_USB_DEVICE_BASE + SZ_1M - 1,
	       .flags = IORESOURCE_IO,
	       },
	[1] = {
	       .name = "otg_irq",
	       .start = IRQ_USB_DEV,
	       .end = IRQ_USB_DEV,
	       .flags = IORESOURCE_IRQ,
	       },
};

static struct platform_device cs752x_ehci_device = {
	.name = "cs752x_ehci",
	.id = -1,
	.dev = {
		.dma_mask = &cs752x_ehci_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs752x_ehci_resources),
	.resource = cs752x_ehci_resources,
};

#ifndef CONFIG_CORTINA_FPGA
static struct platform_device cs752x_ohci_device = {
	.name = "cs752x_ohci",
	.id = -1,
	.dev = {
		.dma_mask = &cs752x_ohci_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs752x_ohci_resources),
	.resource = cs752x_ohci_resources,
};
#endif

static struct platform_device cs752x_otg_device = {
	.name = "dwc_otg",
	.id = -1,
	.dev = {
		.dma_mask = &cs752x_otg_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs752x_otg_resources),
	.resource = cs752x_otg_resources,
};

#ifdef CONFIG_PHONE_CS75XX_WRAPPER
/*
 * phone wrapper resource for D2-VoIP
 */
static struct resource cs75xx_phone_resources[] = {

#if defined(CONFIG_CORTINA_CUSTOM_BOARD)


/* custom board patch start HERE: */

/* Review contents of included template below. After review, apply patch to replace 
 * everything between the start HERE: comment above to the and end HERE: comment below
 * including the start HERE: and end HERE: lines themselves. 
 *
 * This patch should also remove the warning below and also change inclusion path to be a location 
 * within YOUR own custom_board/my_board_name tree which will not be overwritten by
 * future Cortina releases.   
 *
 * WARNING: Do NOT remove or change the CONFIG_CORTINA_CUSTOM_BOARD pre-processor definition name above.
 * Cortina will only support custom board builds which use the CONFIG_CORTINA_CUSTOM_BOARD definition.
 */

#warning CUSTOM_BOARD_REVIEW_ME
#include <mach/custom_board/template/sound/misc/cs75xx_phone/cfg_cs75xx_phone.h>

/* custom board patch end HERE: */

#endif /* CUSTOM_BOARD end */
	{
	 .name = "ssp_index",
#ifdef CONFIG_CORTINA_ENGINEERING
	 .start = 1,
	 .end = 1,
#else
	 .start = 0,
	 .end = 0,
#endif
	 .flags = IORESOURCE_IRQ,
	 },
	{
	 .name = "sclk_sel",
#if defined(CONFIG_CORTINA_PON) || defined(CONFIG_CORTINA_WAN) || \
	 defined(CONFIG_CORTINA_REFERENCE_Q) 
	 .start = SPORT_INT_SYS_CLK_DIV,
	 .end = SPORT_INT_SYS_CLK_DIV,
#else
	 .start = SPORT_EXT_16384_CLK_DIV,
	 .end = SPORT_EXT_16384_CLK_DIV,
#endif
	 .flags = IORESOURCE_IRQ,
	 },
	{
	 .name = "dev_num",
	 .start = 1,
	 .end = 1,
	 .flags = IORESOURCE_IRQ,
	 },
	{
	 .name = "chan_num",
	 .start = 2,
	 .end = 2,
	 .flags = IORESOURCE_IRQ,
	 },
#if !defined(CONFIG_CORTINA_BHR)
	{
	 .name = "slic_reset",
	 .start = GPIO_SLIC0_RESET,
	 .end = GPIO_SLIC0_RESET,
	 .flags = IORESOURCE_IRQ,
	 },
#endif
};

static struct platform_device cs75xx_phone_device = {
	.name = "phone_wrapper",
	.id = -1,
	.dev = {
		.dma_mask = &cs75xx_dmamask,
		.coherent_dma_mask = 0xffffffff,
		},
	.num_resources = ARRAY_SIZE(cs75xx_phone_resources),
	.resource = cs75xx_phone_resources,
};
#endif

static struct platform_device *platform_devices[] __initdata = {
	&goldengate_ahci_device,
#if defined(CONFIG_CS752X_SD)
	&goldengate_sd_device,
#endif				/* CS752X_SD */
	&cs75xx_gpio_device,	/* CS75XX GPIO */
	&cs75xx_gpio_keys_device,
	&cs75xx_gpio_btns_device,
	&cs75xx_led_device,
	&cs75xx_i2c_device,	/* CS75XX I2C */
	&cs75xx_spi_device,	/* CS75XX SPI */
	&goldengate_flash_device,	/* G2 NAND */
	&cs75xx_ir_device,	/* CS75XX IR */
	&cs75xx_pwr_device,	/* CS75XX PWR */
	&cs75xx_sport_device,	/* CS75XX SSP */
#if defined(CONFIG_SND_SOC_SPDIF)
	&spdif_dit_device,
#endif
#ifdef CONFIG_HW_RANDOM_CS75XX
	&cs75xx_trng_device,	/* CS75XX TRNG */
#endif
	&cs75xx_spacc_device,	/* CS75XX SPAcc */
	&goldengate_ne_device,	/* G2 NE */
	&g2_rw_device,		/* G2 read/write register */
	&goldengate_wdt_device,	/* G2 Watchdog Timer */
	&goldengate_rtc_device,	/* G2 RTC */
#if !defined(CONFIG_FTM_100S)
	&goldengate_ts_device,	/* G2 TS */
#endif
	&goldengate_pcie_device,	/* G2 PCIe */
	&cs752x_ehci_device,	/* G2 EHCI */
#ifndef CONFIG_CORTINA_FPGA
	&cs752x_ohci_device,	/* G2 OHCI */
#endif
	&cs752x_otg_device,	/* G2 OTG */
#ifdef CONFIG_CORTINA_G2_ADMA
	&goldengate_dma_device,	/* Asynchro DMA */
#endif
#ifdef CONFIG_PHONE_CS75XX_WRAPPER
	&cs75xx_phone_device,
#endif
};

void regbus_ack_irq(unsigned int irq)
{
	unsigned int val;

	/* RegBus doesn't provide ack register, so just disable it */
	if ((irq > (REGBUS_IRQ_BASE + REGBUS_AGGRE_NO)) ||
		(irq < REGBUS_IRQ_BASE)) {
		printk("%s wrong irq no:%d\n", __func__, irq);
		return;
	}

	spin_lock(&regbus_irq_controller_lock);
	val = readl(IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	val &= ~(1 << (irq - REGBUS_IRQ_BASE));
	writel(val, IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	spin_unlock(&regbus_irq_controller_lock);
}

void regbus_mask_irq(unsigned int irq)
{
	unsigned int val;

	/* Disable INT */
	if ((irq > (REGBUS_IRQ_BASE + REGBUS_AGGRE_NO)) ||
		(irq < REGBUS_IRQ_BASE)) {
		printk("%s wrong irq no:%d\n", __func__, irq);
		return;
	}

	spin_lock(&regbus_irq_controller_lock);
	val = readl(IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	val &= ~(1 << (irq - REGBUS_IRQ_BASE));
	writel(val, IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	spin_unlock(&regbus_irq_controller_lock);
}

void regbus_unmask_irq(unsigned int irq)
{
	unsigned int val;

	/* Enable INT */
	if ((irq > (REGBUS_IRQ_BASE + REGBUS_AGGRE_NO)) ||
		(irq < REGBUS_IRQ_BASE)) {
		printk("%s wrong irq no:%d\n", __func__, irq);
		return;
	}

	spin_lock(&regbus_irq_controller_lock);
	val = readl(IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	val |= 1 << (irq - REGBUS_IRQ_BASE);
	writel(val, IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	spin_unlock(&regbus_irq_controller_lock);
}

static void regbus_irq_handler(unsigned int irq, struct irq_desc *desc)
{
	unsigned int irq_stat;
	struct irq_chip *chip = get_irq_chip(irq);
	int i = 0;

	chip->mask(irq);

	/* Read Status to decide interrupt source */
	spin_lock(&regbus_irq_controller_lock);
	irq_stat = __raw_readl(GOLDENGATE_REGBUS_BASE + 0);
	spin_unlock(&regbus_irq_controller_lock);

	irq_stat &= REGBUS_INT_MASK;
	/* None raise this interrupt ? */
	if (irq_stat == 0)
		goto none;

	for (i = REGBUS_IRQ_BASE; irq_stat; i++, irq_stat >>= 1)
		if (irq_stat & 1)
			generic_handle_irq(i);

      none:
	chip->ack(irq);
	chip->unmask(irq);
}

#ifdef CONFIG_PM
extern u16 regbus_wakeups;
extern u16 regbus_backups;
static int regbus_set_wake(unsigned irq, unsigned value)
{
	/* Enable INT */
	if ((irq > (REGBUS_IRQ_BASE + REGBUS_AGGRE_NO)) ||
		(irq < REGBUS_IRQ_BASE)) {
		printk("%s wrong irq no:%d\n", __func__, irq);
		return -ENXIO;
	}

	if (value)
		regbus_wakeups |= 1 << (irq - REGBUS_IRQ_BASE);
	else
		regbus_wakeups &= ~(1 << (irq - REGBUS_IRQ_BASE));

	return 0;
}
#endif

static struct irq_chip regbus_irq_chip = {
	.name = "REGBUS",
	.ack = regbus_ack_irq,
	.mask = regbus_mask_irq,
	.unmask = regbus_unmask_irq,
#ifdef CONFIG_PM
	.set_wake = regbus_set_wake,
#endif
};

/* DMA Engine IRQ dispatcher */
void dmaeng_ack_irq(unsigned int irq)
{
	unsigned int val;

	/* No ack register, so just disable it */
	if((irq > (IRQ_DMAENG_BASE + IRQ_DMAENG_NO)) ||
		(irq < IRQ_DMAENG_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmaeng_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	val &= ~(1 << (irq - IRQ_DMAENG_BASE));
	writel(val,IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	spin_unlock(&dmaeng_irq_controller_lock);
}

void dmaeng_mask_irq(unsigned int irq)
{
	unsigned int val;

	/* Disable INT */
	if((irq > (IRQ_DMAENG_BASE + IRQ_DMAENG_NO)) ||
		(irq < IRQ_DMAENG_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmaeng_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	val &= ~(1 << (irq - IRQ_DMAENG_BASE));
	writel(val,IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	spin_unlock(&dmaeng_irq_controller_lock);
}

void dmaeng_unmask_irq(unsigned int irq)
{
	unsigned int val;

	/* Enable INT */
	if((irq > (IRQ_DMAENG_BASE + IRQ_DMAENG_NO)) ||
		(irq < IRQ_DMAENG_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmaeng_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	val |= 1 << (irq - IRQ_DMAENG_BASE);
	writel(val,IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	spin_unlock(&dmaeng_irq_controller_lock);
}

static void dmaeng_irq_handler(unsigned int irq, struct irq_desc *desc)
{
	unsigned int irq_stat;
	struct irq_chip *chip = get_irq_chip(irq);
	int i=0;

	chip->ack(irq);

	/* Read Status to decide interrupt source */
	spin_lock(&dmaeng_irq_controller_lock);
	irq_stat = __raw_readl(DMA_DMA_LSO_DMA_LSO_INTERRUPT_0);
	spin_unlock(&dmaeng_irq_controller_lock);

	irq_stat &= DMAENG_INT_MASK;
	/* None raise this interrupt ? */
	if(irq_stat == 0)
		goto none;

	for (i = IRQ_DMAENG_BASE; irq_stat; i++, irq_stat >>= 1)
		if (irq_stat & 1)
			generic_handle_irq(i);

none:
	chip->unmask(irq);
}

static struct irq_chip dmaeng_irq_chip = {
	.name 	= "DMA-ENGINE",
	.ack 	= dmaeng_ack_irq,
	.mask 	= dmaeng_mask_irq,
	.unmask = dmaeng_unmask_irq,
};

/* DMA SSP IRQ dispatcher */
void dmassp_ack_irq(unsigned int irq)
{
	unsigned int val;

	/* No ack register, so just disable it */
	if((irq > (IRQ_DMASSP_BASE + IRQ_DMASSP_NO)) ||
		(irq < IRQ_DMASSP_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmassp_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	val &= ~(1 << (irq - IRQ_DMASSP_BASE));
	writel(val,IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	spin_unlock(&dmassp_irq_controller_lock);
}

void dmassp_mask_irq(unsigned int irq)
{
	unsigned int val;

	/* Disable INT */
	if((irq > (IRQ_DMASSP_BASE + IRQ_DMASSP_NO)) ||
		(irq < IRQ_DMASSP_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmassp_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	val &= ~(1 << (irq - IRQ_DMASSP_BASE));
	writel(val,IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	spin_unlock(&dmassp_irq_controller_lock);
}

void dmassp_unmask_irq(unsigned int irq)
{
	unsigned int val;

	/* Enable INT */
	if((irq > (IRQ_DMASSP_BASE + IRQ_DMASSP_NO)) ||
		(irq < IRQ_DMASSP_BASE)){
		printk("%s wrong irq no:%d\n", __func__, irq);
		return ;
	}

	spin_lock(&dmassp_irq_controller_lock);
	val = readl(IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	val |= 1 << (irq - IRQ_DMASSP_BASE);
	writel(val,IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	spin_unlock(&dmassp_irq_controller_lock);
}

static void dmassp_irq_handler(unsigned int irq, struct irq_desc *desc)
{
	unsigned int irq_stat;
	struct irq_chip *chip = get_irq_chip(irq);
	int i=0;

	chip->mask(irq);

	/* Read Status to decide interrupt source */
	spin_lock(&dmassp_irq_controller_lock);
	irq_stat = __raw_readl(DMA_DMA_SSP_DMA_SSP_INTERRUPT_0);
	spin_unlock(&dmassp_irq_controller_lock);

	irq_stat &= DMAENG_INT_MASK;
	/* None raise this interrupt ? */
	if(irq_stat == 0)
		goto none;

	for (i = IRQ_DMASSP_BASE; irq_stat; i++, irq_stat >>= 1)
		if (irq_stat & 1)
			generic_handle_irq(i);

none:
	chip->ack(irq);
	chip->unmask(irq);
}

static struct irq_chip dmassp_irq_chip = {
	.name 	= "DMA-SSP",
	.ack 	= dmassp_ack_irq,
	.mask 	= dmassp_mask_irq,
	.unmask = dmassp_unmask_irq,
};
void __init gic_init_irq(void)
{
	int j;

	/* core tile GIC, primary */
	gic_cpu_base_addr = __io_address(GOLDENGATE_GIC_CPU_BASE);
	gic_dist_init(0, __io_address(GOLDENGATE_GIC_DIST_BASE), 29);
	gic_cpu_init(0, gic_cpu_base_addr);

	/* REG Bus INT Controller, secondary */
	/* mask and all interrupts */
	writel(0, IO_ADDRESS(PER_PERIPHERAL_INTENABLE_0));
	for (j = REGBUS_IRQ_BASE; j < REGBUS_IRQ_BASE + REGBUS_AGGRE_NO; j++) {
		set_irq_chip(j, &regbus_irq_chip);
		set_irq_handler(j, handle_level_irq);
		set_irq_flags(j, IRQF_VALID);
	}
	set_irq_chained_handler(IRQ_PERI_REGBUS, regbus_irq_handler);
	set_irq_data(IRQ_PERI_REGBUS, NULL);
	irq_set_affinity(IRQ_PERI_REGBUS, cpu_all_mask);

	/* DMA SSP INT dispatcher */
	/* mask all interrupts */
	writel(0,IO_ADDRESS(DMA_DMA_SSP_DMA_SSP_INTENABLE_0));
	for (j = IRQ_DMASSP_BASE ; j < IRQ_DMASSP_BASE + IRQ_DMASSP_NO; j++) {
		set_irq_chip(j, &dmassp_irq_chip);
		set_irq_handler(j, handle_level_irq);
		set_irq_flags(j, IRQF_VALID);
	}
	set_irq_chained_handler(IRQ_REGBUS_SSP, dmassp_irq_handler);
	set_irq_data(IRQ_REGBUS_SSP, NULL);

	/* DMA Engine INT dispatcher */
	/* mask all interrupts */
	writel(0,IO_ADDRESS(DMA_DMA_LSO_DMA_LSO_INTENABLE_0));
	for (j = IRQ_DMAENG_BASE ; j < IRQ_DMAENG_BASE + IRQ_DMAENG_NO; j++) {
		set_irq_chip(j, &dmaeng_irq_chip);
		set_irq_handler(j, handle_level_irq);
		set_irq_flags(j, IRQF_VALID);
	}
	set_irq_chained_handler(IRQ_DMA, dmaeng_irq_handler);
	set_irq_data(IRQ_DMA, NULL);
	irq_set_affinity(IRQ_DMA, cpu_all_mask);

}

static void __init goldengate_timer_init(void)
{
	unsigned int timer_irq;

	timer0_va_base = __io_address(TIMER0_BASE);
	timer1_va_base = __io_address(TIMER1_BASE);

#ifdef CONFIG_LOCAL_TIMERS
	twd_base = __io_address(GOLDENGATE_TWD_BASE);
#endif
	timer_irq = GOLDENGATE_IRQ_TIMER0;

	goldengate_clock_init(timer_irq);
}

static struct sys_timer goldengate_timer = {
	.init = goldengate_timer_init,
};

int cs_rtl8211_phy_addr[] = {
	1,
	2,
	0
};

static void __init goldengate_init(void)
{
#if (defined(CONFIG_FB_CS752X_CLCD) | defined(CONFIG_FB_CS752X_CLCD_MODULE))
	int i;
#endif
	struct platform_clk clk;
	GLOBAL_SCRATCH_t global_scratch;

#ifdef CONFIG_CACHE_L2X0
#ifdef CONFIG_ACP
	GLOBAL_ARM_CONFIG_D_t gbl_arm_cfg_d;
	gbl_arm_cfg_d.wrd = readl(GLOBAL_ARM_CONFIG_D);
	/* Peripheral Cache: Write Back, No write allocate */
	gbl_arm_cfg_d.bf.periph_cache = 0x7;
	writel(gbl_arm_cfg_d.wrd, GLOBAL_ARM_CONFIG_D);
#endif
	void __iomem *l2x0_base = __io_address(GOLDENGATE_L220_BASE);

	writel(0, l2x0_base + L2X0_TAG_LATENCY_CTRL);
	writel(0x00000001, l2x0_base + L2X0_DATA_LATENCY_CTRL);

	/* updated by hkou & ted 02/23/2012 */
	//l2x0_init(__io_address(GOLDENGATE_L220_BASE), 0x00740000, 0xfe000fff);
	l2x0_init(__io_address(GOLDENGATE_L220_BASE), 0x40740001, 0x8200c3fe);
#endif
	/* Check Chip version in JTAG ID */
	system_rev = (readl(GLOBAL_JTAG_ID) >> 12) & 0x0000000F;
	switch(system_rev){
	case 0x0:
		system_rev = 0x7542A0;
		break;
	case 0x8:
		system_rev = 0x7542A1;
		break;
	case 0x1:
		system_rev = 0x7522A0;
		break;
	case 0x9:
		system_rev = 0x7522A1;
		break;
	default:
		printk("Wrong JTAG ID:%x (FPGA ?)\n", __io_address(GLOBAL_JTAG_ID));
	}

	if((system_rev & 0xFF) == 0xA1){
		cs_acp_enable = CS75XX_ACP_ENABLE_NI | CS75XX_ACP_ENABLE_CRYPT;
#if defined(CONFIG_SMB_TUNING) && defined(CONFIG_SMP)
		cs_acp_enable |= CS75XX_ACP_ENABLE_AHCI | CS75XX_ACP_ENABLE_USB;
#endif

		writel(0x210FF, GLOBAL_ARM_CONFIG_D);

		global_scratch.wrd = readl(GLOBAL_SCRATCH);
		if (cs_acp_enable & 0x000007FF) {
			/*enable the recirc ACP transactions "secured"*/
			global_scratch.wrd |= 0x1000;
		} else {
			global_scratch.wrd &= ~0x1000;
		}
		writel(global_scratch.wrd, GLOBAL_SCRATCH);

		writel(0xFF,__io_address(GOLDENGATE_L220_BASE) + 0x910);
		writel(0xFF,__io_address(GOLDENGATE_L220_BASE) + 0x914);
	}else{
		cs_acp_enable = 0;
	}

	get_platform_clk(&clk);

#ifdef CONFIG_I2C_CS75XX
	cs75xx_i2c_cfg.freq_rcl = clk.apb_clk;
#endif
#ifdef CONFIG_SPI_CS75XX
	cs75xx_spi_cfg.tclk = clk.apb_clk;
#endif
	platform_add_devices(platform_devices, ARRAY_SIZE(platform_devices));
	//Ryan Add for LCD
	cs75xx_add_device_lcd();

#if defined(CONFIG_I2C_CS75XX) && defined(CONFIG_I2C_BOARDINFO)
	i2c_register_board_info(0, i2c_board_infos, ARRAY_SIZE(i2c_board_infos));
#endif
#ifdef CONFIG_SPI_CS75XX
	spi_register_board_info(spi_board_infos, ARRAY_SIZE(spi_board_infos));
#endif

}

void goldengate_fixup(struct machine_desc *mdesc, struct tag *tags, char **from,
		      struct meminfo *meminfo)
{
	volatile u32 mem_sz=0;

	mem_sz = readl(IO_ADDRESS(GLOBAL_SOFTWARE2)) >> 20;
	printk("Mem_size=%d\n", mem_sz);

	meminfo->bank[0].size = (mem_sz - (mem_sz>>3)*CONFIG_CS752X_NR_QMBANK)*0x100000;

	meminfo->bank[0].start = GOLDENGATE_DRAM_BASE;
	meminfo->nr_banks = 1;
}

#ifdef CONFIG_CORTINA_FPGA
MACHINE_START(CORTINA_G2, "CORTINA-G2 FPGA")
#else
MACHINE_START(CORTINA_G2, "CORTINA-G2 EB")
#endif
    /* Maintainer: Cortina-Systems Digital-Home BU */
    .nr = MACH_TYPE_CORTINA_G2,
    .phys_io = 0xF0000000,
    .io_pg_offst = (IO_ADDRESS(0xF0000000) >> 18) & 0xfffc,
    .boot_params = PHYS_OFFSET + 0x00000100,
    .fixup = goldengate_fixup,
    .map_io = goldengate_map_io,
    .init_irq = gic_init_irq,
    .timer = &goldengate_timer,
    .init_machine = goldengate_init,
MACHINE_END
