#!/bin/sh
# 
# Copyright 2026 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.
#

chmod +x /usr/share/xunison/led_4G5G.sh >/dev/null 2>&1 &
chmod +x /etc/init.d/modem_led >/dev/null 2>&1 &
chmod +x /usr/share/xunison/sensors.sh >/dev/null 2>&1 &

# CONFIG Xunison Exigo Hub D50 5G
uci set system.@system[0].hostname='Xunison'

uci add system led
uci set system.@led[-1].name='Internet'
uci set system.@led[-1].sysfs='green:wan-online'
uci set system.@led[-1].trigger='netdev'
uci set system.@led[-1].dev='rmnet_mhi0.1'
uci add_list system.@led[-1].mode='link'
uci add_list system.@led[-1].mode='rx'
uci commit system
/etc/init.d/led restart

# uci set network.globals.packet_steering='2'

uci set network.modem=interface
uci set network.modem.proto='quectel'
uci set network.modem.device='/dev/mhi_QMI0'
uci set network.modem.auth='none'
uci set network.modem.pdptype='ipv4'
uci set network.modem.multipath='off'
uci set network.modem.apn='internet'
uci set network.modem.metric='11'
uci set network.modem.force_apn='1'
uci set network.modem.logfile='/var/run/quectel/dial_log'
uci set network.modem.auto='0'
uci commit network

uci add_list firewall.@zone[1].network='modem'
# uci set firewall.@defaults[0].flow_offloading='1'
# uci set firewall.@defaults[0].flow_offloading_hw='1'
uci commit firewall

A_FILE="/etc/config/atinout"
if [ -f "$A_FILE" ]; then
	uci set atinout.@atinout[0].set_port='/dev/ttyUSB2'
	uci commit atinout
fi

if [ -d /etc/modem/atinoutatcommands ]; then
	mv /etc/modem/atinoutatcommands/quectel.user.default /etc/modem/atinoutatcommands/quectel.user >/dev/null 2>&1 &
	sleep 5
	chmod 664 /etc/modem/atinoutatcommands/quectel.user >/dev/null 2>&1 &
else
	rm /etc/modem/atinoutatcommands/quectel.user.default >/dev/null 2>&1 &
fi

NSS_FILE="/www/luci-static/resources/view/status/include/16_nss_offload.js"
if [ -f "$NSS_FILE" ]; then
	sleep 10
	mv /www/luci-static/resources/view/status/include/16_nss_offload.js /www/luci-static/resources/view/status/include/16_nss_offload.bak >/dev/null 2>&1 &
	sleep 3
 	rm /www/luci-static/resources/view/status/include/16_nss_offload.js >/dev/null 2>&1 &
fi

S_FILE="/etc/config/sms_tool_js"
if [ -f "$S_FILE" ]; then
	uci set sms_tool_js.@sms_tool_js[0].readport='/dev/ttyUSB2'
	uci set sms_tool_js.@sms_tool_js[0].sendport='/dev/ttyUSB2'
	uci set sms_tool_js.@sms_tool_js[0].ussdport='/dev/ttyUSB2'
	uci set sms_tool_js.@sms_tool_js[0].callport='/dev/ttyUSB2'
	uci set sms_tool_js.@sms_tool_js[0].coding='auto'
	uci set sms_tool_js.@sms_tool_js[0].ussd='1'
	uci set sms_tool_js.@sms_tool_js[0].pdu='1'
	uci set sms_tool_js.@sms_tool_js[0].atport='/dev/ttyUSB2'
	uci set sms_tool_js.@sms_tool_js[0].ledtype='D'
	uci set sms_tool_js.@sms_tool_js[0].smsled='green:mesh'
	uci commit sms_tool_js
fi

if [ -d /etc/modem/atcmmds ]; then
	mv /etc/modem/atcmmds/quectel.user.default /etc/modem/atcmmds/quectel.user >/dev/null 2>&1 &
	sleep 5
	chmod 664 /etc/modem/atcmmds/quectel.user >/dev/null 2>&1 &
else
	rm /etc/modem/atcmmds/quectel.user.default >/dev/null 2>&1 &
fi

D_FILE="/etc/config/defmodems"
if [ -f "$D_FILE" ]; then
	uci set defmodems.defmodems=defmodems
	uci set defmodems.defmodems.modem='Quectel RM500Q-AE'
	uci set defmodems.defmodems.modemdata='serial'
	uci set defmodems.defmodems.comm_port='/dev/ttyUSB2'
	uci set defmodems.defmodems.comm_serial='/dev/ttyUSB2'
	uci set defmodems.defmodems.network='modem'
	uci set defmodems.defmodems.user_desc='primary'
	uci commit defmodems
fi

MB_FILE="/etc/config/modemband"
if [ -f "$MB_FILE" ]; then
	uci set modemband.@modemband[0].iface='modem'
	uci set modemband.@modemband[0].set_port='/dev/ttyUSB2'
	uci commit modemband
fi

W_FILE="/etc/config/watchdog"
if [ -f "$W_FILE" ]; then
	uci set watchdog.@watchdog[0].iface='modem'
	uci commit watchdog
fi

F_FILE="/etc/config/qfirehose"
if [ -f "$F_FILE" ]; then
	uci set qfirehose.@qfirehose[0].port='/dev/ttyUSB2'
	uci commit qfirehose
fi

E_FILE="/etc/config/easyconfig_transfer"
if [ -f "$E_FILE" ]; then
	uci set easyconfig_transfer.global.network='modem'
	uci commit easyconfig_transfer
fi

rm -rf /tmp/luci-indexcache >/dev/null 2>&1 &
rm -rf /tmp/luci-modulecache/ >/dev/null 2>&1 &


# /etc/init.d/qca-nss-drv enable >/dev/null 2>&1 &
# sleep 5
# /etc/init.d/qca-nss-drv start >/dev/null 2>&1 &
sleep 30 && /etc/init.d/pcie_mhi reload

/etc/init.d/network reload
/etc/init.d/firewall reload

PORTS_BAK="/www/luci-static/resources/view/status/include/29_ports.bak"
USER_DEFINED_PORTS="/etc/user_defined_ports.json"

if [ -f "$PORTS_BAK" ]; then
	cp /etc/modem/user_defined_ports.json.default /etc/user_defined_ports.json >/dev/null 2>&1 &
else
	rm /etc/modem/user_defined_ports.json.default >/dev/null 2>&1 &
fi

sleep 5

if [ -f "$USER_DEFINED_PORTS" ]; then
    chmod 664 "$USER_DEFINED_PORTS" >/dev/null 2>&1 &
fi

echo "" >> /var/run/quectel/dial_log 2>&1 &
if [ -f /var/run/quectel/dial_log ]; then
	sleep 10
	chmod 664 /var/run/quectel/dial_log >/dev/null 2>&1 &
fi

exit 0
