cat /etc/ssl_config/system.conf | awk 'BEGIN{ count=0; } { if (0 < NF) { split($1, arr, "="); if (arr[1] != "[SSL]" && arr[1] != "[KEEP_ALIVE]") { printf ("%s %s\n", arr[1], arr[2]);}} }'

