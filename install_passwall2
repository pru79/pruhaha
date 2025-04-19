#!/bin/sh
cat <<EOF >> /etc/opkg/customfeeds.conf
src/gz passwall2 https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-24.10/aarch64_cortex-a53/passwall2
src/gz passwall_luci https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-24.10/aarch64_cortex-a53/passwall_luci
src/gz passwall_packages https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-24.10/aarch64_cortex-a53/passwall_packages
EOF
wget -O passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub
opkg-key add passwall.pub
opkg update && opkg install --nodeps luci-app-passwall2
wget https://github.com/pru79/pruhaha/raw/refs/heads/main/xray25.3.31.gz
gunzip xray25.3.31.gz;chmod +x xray25.3.31
cp /usr/bin/xray xray.bak
cp xray25.3.31 /usr/bin/xray
uci set passwall2.@global_forwarding[0].tcp_redir_ports='1:65535'
uci commit passwall2
/etc/init.d/passwall2 restart
sed -i '/^exit 0/i sleep 25;/etc/init.d/passwall2 restart' /etc/rc.local
