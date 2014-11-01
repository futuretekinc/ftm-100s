#!/bin/sh
sw_cfg -c RTK_MIRROR_PORT_BASED_SET -s
sw_cfg -c RTK_MIRROR_PORT_BASED_SET -f mirroring_port -v 3
sw_cfg -c RTK_MIRROR_PORT_BASED_SET -f mirrored_rx_portmask -v 0x2
sw_cfg -c RTK_MIRROR_PORT_BASED_SET -f mirrored_tx_portmask -v 0x2
sw_cfg -c RTK_MIRROR_PORT_BASED_SET -e

