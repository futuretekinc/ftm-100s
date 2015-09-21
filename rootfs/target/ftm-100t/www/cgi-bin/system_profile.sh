#!/bin/sh
echo "MODEL:" `cat /proc/cmdline | awk '{for (i = 1 ; i <= NF ; i++){if ($i ~ /model=*/){ split($i, tokens, "="); print tokens[2];}}}'`
echo "S/N:" `cat /proc/cmdline | awk '{for (i = 1 ; i <= NF ; i++){if ($i ~ /devid=*/){ split($i, tokens, "="); print tokens[2];}}}'`
