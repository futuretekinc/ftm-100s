ving device app
========

## log file configuration
 * log4js configuration at device/logger_cfg.json
 * path: /var/log/sensorjs/
 * files:
    * forever.log : forever logs and ERROR and above logs
    * sensorjs.log : logs per levels configured at logger_cfg.json
    * sensorjs.log.# : old logs. max 3 files and size limiting upto 500KB.
