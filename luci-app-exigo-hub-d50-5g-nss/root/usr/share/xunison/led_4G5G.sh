#!/bin/sh
#
# Copyright 2026 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.
#

DEVICE="/dev/ttyUSB2"
NETWORK="modem"
LED_4G="/sys/class/leds/green:4g/brightness"
LED_5G="/sys/class/leds/green:5g/brightness"
LED_RED="/sys/class/leds/red:5g/brightness"
INTERVAL=20

while true; do
    UP=""
    IFACE=""
    eval $(ifstatus ${NETWORK} 2>/dev/null | jsonfilter -q -e 'UP=@.up' -e 'IFACE=@.l3_device' 2>/dev/null)
    
    if [ "x$UP" != "x1" ]; then
        echo 0 > $LED_4G 2>/dev/null
        echo 0 > $LED_5G 2>/dev/null
        echo 1 > $LED_RED 2>/dev/null
        sleep $INTERVAL
        continue
    fi
    
    if [ ! -e "$DEVICE" ]; then
        echo 0 > $LED_4G 2>/dev/null
        echo 0 > $LED_5G 2>/dev/null
        echo 1 > $LED_RED 2>/dev/null
        sleep $INTERVAL
        continue
    fi
    
    MODE=$(sms_tool -d $DEVICE at 'at+qeng="servingcell"' 2>/dev/null | grep "+QENG:")
    
    if [ -z "$MODE" ]; then
        echo 0 > $LED_4G 2>/dev/null
        echo 0 > $LED_5G 2>/dev/null
        echo 1 > $LED_RED 2>/dev/null
        sleep $INTERVAL
        continue
    fi
    
    if echo "$MODE" | grep -q "NR5G-SA"; then
        # 5G Standalone - 5G
        echo 0 > $LED_4G 2>/dev/null
        echo 1 > $LED_5G 2>/dev/null
        echo 0 > $LED_RED 2>/dev/null
    elif echo "$MODE" | grep -q "NR5G-NSA"; then
        # 5G Non-Standalone - 4G + 5G
        echo 1 > $LED_4G 2>/dev/null
        echo 1 > $LED_5G 2>/dev/null
        echo 0 > $LED_RED 2>/dev/null
    elif echo "$MODE" | grep -q "LTE"; then
        # 4G LTE - 4G
        echo 1 > $LED_4G 2>/dev/null
        echo 0 > $LED_5G 2>/dev/null
        echo 0 > $LED_RED 2>/dev/null
    else
        # Unknown
        echo 0 > $LED_4G 2>/dev/null
        echo 0 > $LED_5G 2>/dev/null
#        echo 1 > $LED_RED 2>/dev/null
        
	LEDT="/sys/class/leds/red:5g/trigger"
	LEDON="/sys/class/leds/red:5g/delay_on"
	LEDOFF="/sys/class/leds/red:5g/delay_off"

        echo timer > $LEDT 2>/dev/null
        echo 2000 > $LEDOFF 2>/dev/null
        echo 1000 > $LEDON 2>/dev/null
        
    fi
    
    sleep $INTERVAL
done
