#!/bin/sh
# set CPU tag
# USAGE: sw_set_cpu_tag.sh [mode] [position] [port]
# mode     --   1: enable, 0: disable
# position --	1: end of packet (before CRC), 0: after MAC
# port     --   0-3: LAN, 5: CPU port

# position --     1: end of packet (before CRC), 0: after MAC
sw_cfg -c RTK_CPU_TAG_POSITION_SET -s
sw_cfg -c RTK_CPU_TAG_POSITION_SET -f position -v $2
sw_cfg -c RTK_CPU_TAG_POSITION_SET -e

# enable --     1: enable, 0: disable
sw_cfg -c RTK_CPU_ENABLE_SET -s
sw_cfg -c RTK_CPU_ENABLE_SET -f enable -v $1
sw_cfg -c RTK_CPU_ENABLE_SET -e

# port --       0-7
# mode --       0: all, 1: trapped packets only, 2: none
sw_cfg -c RTK_CPU_TAG_PORT_SET -s
sw_cfg -c RTK_CPU_TAG_PORT_SET -f port -v $3
sw_cfg -c RTK_CPU_TAG_PORT_SET -f mode -v 0
sw_cfg -c RTK_CPU_TAG_PORT_SET -e

