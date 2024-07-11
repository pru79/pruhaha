#!/bin/bash

# Function to install Vnstat
install_vnstat() {
    read -p "Interface? (e.g. wwan0, wgcf, wwan0_1 default is wwan0): " interface
    interface=${interface:-wwan0}

    opkg update
    opkg install luci-app-vnstat

    # Modify vnstat.conf to use /etc/vnstat and set the interface
    sed -i "s/DatabaseDir \"\/var\/lib\/vnstat\"/DatabaseDir \"\/etc\/vnstat\"/g" /etc/vnstat.conf
    sed -i "s/eth0/$interface/g" /etc/vnstat.conf

    /etc/init.d/vnstat start
    vnstat -u -i $interface
    /etc/init.d/vnstat enable
}

# Function to uninstall Vnstat
uninstall_vnstat() {
    opkg remove luci-app-vnstat
    opkg remove vnstati
    opkg remove vnstat

    rm -rf /etc/vnstat* /etc/config/vnstat
}
