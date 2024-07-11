#!/bin/bash

# Function to install Watchcat
install_watchcat() {
    echo "Installing Watchcat..."

    # Installation script for Watchcat
    cat <<'E' >/bin/rewg
n=0
m=0
/etc/init.d/watchcat stop > /dev/null 2>&1
while [ $n -le 1 ]; do
    /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=0 > /dev/null 2>&1 &&
    /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 "AT+CGDCONT=1,\"IPV6\",\"hos\"" > /dev/null 2>&1 &&
    /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 AT+CFUN=1 > /dev/null 2>&1 &&
    ifup wan && ifup wan1
    sleep 30
    ping -c 3 8.8.8.8
    [ $? -eq 0 ] && /etc/init.d/watchcat start && /etc/init.d/watchcat enable && exit 0
    n=$((n+1))
done
while [ $m -le 1 ]; do
    /usr/lib/rooter/gcom/gcom-locked /dev/ttyUSB2 run-at.gcom 1 "AT+CFUN=1,1" > /dev/null 2>&1
    ifup wan && ifup wan1
    sleep 90
    ping -c 3 8.8.8.8
    [ $? -eq 0 ] && /etc/init.d/watchcat start && /etc/init.d/watchcat enable && exit 0
    m=$((m+1))
done
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
E

    chmod +x /bin/rewg

    echo -e "search lan\nnameserver 127.0.0.1" > /etc/resolv.conf
    cp -rf /usr/lib/lua/luci/view/rooter/net_status.htm /usr/lib/lua/luci/view/rooter/net_status.htm.bak && wget -q -O /usr/lib/lua/luci/view/rooter/net_status.htm https://raw.githubusercontent.com/pru79/pruhaha/main/qwrtsignal
    wget https://downloads.immortalwrt.org/releases/23.05.2/packages/aarch64_cortex-a53/packages/watchcat_1-17_all.ipk -O /tmp/wc.ipk > /dev/null 2>&1
    opkg install /tmp/wc.ipk > /dev/null 2>&1

    uci batch <<'E' > /dev/null
set watchcat.@watchcat[0].period='30s'
set watchcat.@watchcat[0].mode='run_script'
set watchcat.@watchcat[0].pinghosts='1.1.1.1'
set watchcat.@watchcat[0].addressfamily='ipv4'
set watchcat.@watchcat[0].pingperiod='6s'
set watchcat.@watchcat[0].script='/bin/rewg'
commit watchcat
E

    /etc/init.d/watchcat start > /dev/null 2>&1
    /etc/init.d/watchcat enable > /dev/null 2>&1

    rm /tmp/wc.ipk

    # Check Watchcat status until it changes to Running
    while ! check_watchcat_status; do
        echo "Waiting for Watchcat to start..."
        sleep 5
    done

    echo "Watchcat setup completed successfully."
}

# Function to monitor Watchcat and restart if necessary
monitor_watchcat() {
    cat <<'E' >/bin/wcmon
#!/bin/sh
/etc/init.d/watchcat stop && /etc/init.d/watchcat disable > /dev/null 2>&1
while true; do
    curl -s --head http://example.com | grep "200 OK" > /dev/null && /etc/init.d/watchcat start && /etc/init.d/watchcat enable > /dev/null 2>&1
    sleep 60
done
E

    chmod a+x /bin/wcmon
echo "hahah"
    /bin/wcmon &

    sed -i '/exit 0/i /bin/wcmon &' /etc/rc.local

    echo "Watchcat monitoring setup completed."
}

# Function to uninstall Watchcat
uninstall_watchcat() {
    echo "Uninstalling Watchcat..."

    /etc/init.d/watchcat stop > /dev/null 2>&1
    opkg remove watchcat > /dev/null 2>&1
    rm -f /etc/config/watchcat /bin/rewg /bin/wcmon > /dev/null 2>&1
    sed -i '/\/bin\/wcmon/d' /etc/rc.local > /dev/null 2>&1
    ps | grep '/bin/wcmon' | grep -v grep | awk '{print $1}' | xargs kill -9 > /dev/null 2>&1

    sleep 2
    clear

    echo "Watchcat uninstalled successfully."
}

# Function to check Watchcat status
check_watchcat_status() {
    /etc/init.d/watchcat status | grep -q "running"
    return $?
}
