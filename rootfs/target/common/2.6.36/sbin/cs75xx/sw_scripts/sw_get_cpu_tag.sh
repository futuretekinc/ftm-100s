#!/bin/sh
# get CPU tag
# USAGE: sw_get_cpu_tag.sh

# position --     1: end of packet (before CRC), 0: after MAC
sw_cfg -c RTK_CPU_TAG_POSITION_GET -s
sw_cfg -c RTK_CPU_TAG_POSITION_GET -e

# enable --     1: enable, 0: disable
sw_cfg -c RTK_CPU_ENABLE_GET -s
sw_cfg -c RTK_CPU_ENABLE_GET -e

# port --       0-7
# mode --       0: all, 1: trap only, 2: none
sw_cfg -c RTK_CPU_TAG_PORT_GET -s
sw_cfg -c RTK_CPU_TAG_PORT_GET -e

