CONFIG_SHOW_BOOT_PROGRESS=y
CONFIG_CS752X_NAND_ECC_HW_HAMMING_256=y
CONFIG_SYS_MAX_NAND_DEVICE=y
CONFIG_MTD_NAND_VERIFY_WRITE=y
CONFIG_SYS_GBL_DATA_SIZE=128
CONFIG_SYS_LONGHELP=y
CONFIG_SYS_LOAD_ADDR="0x05000000"
CONFIG_STACKSIZE="(256 * 1024)"
CONFIG_BOOTDELAY=2
CONFIG_SYS_NAND_BASE="0xE0000000"
CONFIG_SYS_HELP_CMD_WIDTH=8
CONFIG_NR_DRAM_BANKS=y
CONFIG_SYS_CBSIZE=1024
CONFIG_ETHADDR="00.40.5c.12.34.56 /--* talk on MY local MAC address */"
CONFIG_SYS_MONITOR_LEN="(0x100000)"
CONFIG_ENV_RANGE="(G2_UBOOT_ENV_RANGE)"
CONFIG_MD5=y
CONFIG_GOLDENGATE_SERIAL=y
CONFIG_GATEWAYIP="192.168.1.1 /--* current gateway IP */"
CONFIG_CS75XX_MAC_TO_EXT_SWITCH=y
CONFIG_MISC_INIT_R=y
CONFIG_ENV_OFFSET="(G2_UBOOT_ENV_OFFSET)"
CONFIG_RELOC_FIXUP_WORKS=y
CONFIG_GOLDENGATE=y
CONFIG_MK_100S=y
CONFIG_ENV_OVERWRITE=y
CONFIG_CMD_NET=y
CONFIG_ENV_SIZE="(G2_UBOOT_ENV_SIZE)"
CONFIG_NAND_CS75XX=y
CONFIG_CMD_PING=y
CONFIG_SYS_MALLOC_LEN="(CONFIG_ENV_SIZE + 128 * 1024)"
CONFIG_SYSTEM_CLOCK="(100*1000000)"
CONFIG_INITRD_TAG=y
CONFIG_CS75XX_GMAC2_TO_EXT_SWITCH=y
CONFIG_CMD_SAVEENV=y
CONFIG_ENV_SECT_SIZE="(CONFIG_ENV_SIZE)"
CONFIG_CMD_NAND=y
CONFIG_ENV_ADDR="(PHYS_FLASH_1 + CONFIG_ENV_OFFSET)"
CONFIG_CMD_MEMORY=y
CONFIG_SYS_MAXARGS=32
CONFIG_CMD_RUN=y
CONFIG_IPADDR="192.168.1.222 /--* static IP I currently own */"
CONFIG_SYS_PBSIZE="(CONFIG_SYS_CBSIZE + sizeof(CONFIG_SYS_PROMPT) + 16)"
CONFIG_BOOTP_HOSTNAME=y
CONFIG_UBOOT_CPU_TO_GMAC=2
CONFIG_BOOTCOMMAND="run process setbootargs b"
CONFIG_MK_FTM=y
CONFIG_CS75XX_NAND_REGS_BASE="0xf0050000"
CONFIG_SYS_NAND_MAX_CHIPS=2
CONFIG_FM_A9_SMP=y
CONFIG_NET_MULTI=y
CONFIG_SYS_BARGSIZE="CONFIG_SYS_CBSIZE"
CONFIG_GOLDENGATE_SPI=y
CONFIG_SYS_HZ="(1000)"
CONFIG_IDENT_STRING=" FutureTek FTM-100S"
CONFIG_SYS_BAUDRATE_TABLE="{ 9600, 19200, 38400, 57600, 115200 }"
CONFIG_CS75XX_PHY_ADDR_GMAC0=y
CONFIG_CS75XX_PHY_ADDR_GMAC1=5
CONFIG_CS75XX_PHY_ADDR_GMAC2=0
CONFIG_ENV_IS_IN_NAND=y
CONFIG_BOOTP_GATEWAY=y
CONFIG_SYS_MONITOR_BASE="(PHYS_FLASH_1)"
CONFIG_CMD_RECOVERY=y
CONFIG_SYS_NAND_BASE_LIST="{ CONFIG_SYS_NAND_BASE }"
CONFIG_BAUDRATE=115200
CONFIG_NETMASK="255.255.255.0 /--* talk on MY local net */"
CONFIG_CMDLINE_TAG=y
CONFIG_NAND_G2=y
CONFIG_SYS_DEF_EEPROM_ADDR=0
CONFIG_SYS_MEMTEST_END="0xf0000000"
CONFIG_CMD_ENV=y
CONFIG_SYS_NO_FLASH=y
CONFIG_SYS_FLASH_BASE="0xe0000000"
CONFIG_SYS_MAX_FLASH_BANKS=y
CONFIG_SYS_PROMPT="FTM-100S # "
CONFIG_BOOTP_BOOTPATH=y
CONFIG_SETUP_MEMORY_TAGS=y
CONFIG_CS75XX_NAND_HWECC=y
CONFIG_SYS_MEMTEST_START="0x00100000"
CONFIG_CMD_LOADB=y
CONFIG_CMD_IMI=y
CONFIG_CONS_INDEX=0
CONFIG_ARM=y
CONFIG_SYS_MAX_FLASH_SECT="(512 * 2)"
CONFIG_CMD_BDI=y
CONFIG_SERVERIP="192.168.1.1 /--* current IP of my dev pc */"
CONFIG_MTD_CORTINA_CS752X_NAND=y
CONFIG_BOOTP_SUBNETMASK=y
