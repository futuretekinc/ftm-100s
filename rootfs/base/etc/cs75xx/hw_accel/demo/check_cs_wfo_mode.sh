#!/bin/sh
# RETURN: 
#      ERROR 1 - WFO mode and PKT_BUF for QM enabled.
#      ERROR 2 - Normal mode and PKT_BUF for QM disabled.

WFO_MODE_ID=$1
CUR_QM_INT_BUFF=`fw_printenv QM_INT_BUFF |  awk '{FS="="} {print$2}'`

if  [ "$WFO_MODE_ID" == "8" ] || [ "$WFO_MODE_ID" == "9" ] || [ "$WFO_MODE_ID" == "10" ] || [ "$WFO_MODE_ID" == "12" ]  || [ "$WFO_MODE_ID" == "13" ]  || [ "$WFO_MODE_ID" == "14" ] || [ "$WFO_MODE_ID" == "16" ] || [ "$WFO_MODE_ID" == "17" ] || [ "$WFO_MODE_ID" == "-2" ] || [ "$WFO_MODE_ID" == "4" ]; then
    if [ $CUR_QM_INT_BUFF -ne 0 ]; then
        echo "PKT_BUF for QM should be disabled."
        exit 1
    fi
else
    if [ "$CUR_QM_INT_BUFF" == "0" ]; then
        echo "PKT_BUF for QM should be enabled."
        exit 2
    fi
fi
