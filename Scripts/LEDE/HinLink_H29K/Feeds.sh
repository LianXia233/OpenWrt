#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Add a feed source
echo 'src-git modem https://github.com/FUjr/modem_feeds.git;main' >>feeds.conf.default
echo 'src-git homeproxy https://github.com/immortalwrt/homeproxy.git;master' >>feeds.conf.default
echo 'src-git easytier https://github.com/EasyTier/luci-app-easytier.git;main' >>feeds.conf.default
