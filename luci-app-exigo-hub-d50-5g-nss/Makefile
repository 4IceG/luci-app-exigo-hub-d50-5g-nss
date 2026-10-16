#
# Copyright 2026 Rafał Wabik - IceG - From eko.one.pl forum
#
# Licensed to the GNU General Public License v3.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-exigo-hub-d50-5g-nss
PKG_MAINTAINER:=Rafał Wabik <4Rafal@gmail.com>
LUCI_TITLE:=LuCI JS support for Xunison Exigo Hub D50 5G
LUCI_DESCRIPTION:=A dedicated LuCI JS package for the Xunison Exigo Hub D50 5G.
LUCI_DEPENDS:=+sms-tool +ip-full +kmod-tun +ath11k-firmware-ipq5018 +kmod-ath11k-pci +ath11k-firmware-qcn9074 +ipq-wifi-xunison_exigo-hub-d50-5g
LUCI_PKGARCH:=all
PKG_LICENSE:=GNU
PKG_VERSION:=2.1
PKG_RELEASE:=20261015

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature


