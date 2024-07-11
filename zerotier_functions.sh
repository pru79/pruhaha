#!/bin/bash

# Function to check ZeroTier status
check_zerotier_status() {
    /etc/init.d/zerotier status | grep -q "running"
    return $?
}

# Function to enable ZeroTier
enable_zerotier() {
    /etc/init.d/zerotier start
    /etc/init.d/zerotier enable
    echo "ZeroTier enabled."
}

# Function to disable ZeroTier
disable_zerotier() {
    echo "Disabling ZeroTier..."
    /etc/init.d/zerotier stop
    uci delete network.zt

    # Retrieve the index of the zztt firewall zone
    zone_index=$(uci show firewall | awk -F '[\[\]]' '/firewall.@zone\[/{print $2}' | awk '/zztt/{print NR-1}')

    if [ -z "$zone_index" ]; then
        echo "Error: zztt firewall zone not found."
        return
    fi

    echo "Found zztt firewall zone index: $zone_index"

    # Delete the zztt firewall zone
    uci delete firewall.@zone["$zone_index"]

    # Commit changes
    uci commit

    echo "Deleted zztt firewall zone."
    sleep 5
    clear
}

# Function to configure ZeroTier
configure_zerotier() {
    # Enable ZeroTier configuration (if needed)
    sed -i -E 's/option (enabled|nat) .*/option \1 '\''1'\''/' /etc/config/zerotier

    # Prompt for ZeroTier network ID
    echo -n "Enter ZeroTier network ID: "
    read -r n

    # Validate and sanitize network ID input
    n=$(echo "$n" | tr -cd 'a-z0-9')

    # Check if network ID is valid
    if [ -z "$n" ]; then
        echo "No valid network ID entered. Exiting."
        return
    fi

    # Configure ZeroTier network ID
    sed -i "s/list join '[^']*'/list join '$n'/" /etc/config/zerotier

    # Start ZeroTier service
    /etc/init.d/zerotier start

    # Leave any previously joined ZeroTier network
    echo "Leaving any previously joined network..."
    zerotier-cli leave "$n" 2>/dev/null || true

    sleep 5

    # Join the specified ZeroTier network
    echo "Joining network $n..."
    join_output=$(zerotier-cli join "$n" 2>&1)
    join_status=$?

    if [ $join_status -ne 0 ]; then
        echo "Joining network $n failed with error: $join_output"
        return
    fi

    echo "Successfully joined network $n."

    # Wait for ZeroTier interface to become active
    echo "Waiting for ZeroTier interface..."

    # Loop to wait for ZeroTier interface to appear
    while ! zt_interface=$(get_zerotier_interface); [ -z "$zt_interface" ]; do
        echo "tunggu $zt_interface";sleep 1
    done

    echo "ZeroTier interface detected: $zt_interface"

    # Configure ZeroTier interface settings
    uci set network.ZT=interface
    uci set network.ZT.proto='none'
    uci set network.ZT.ifname="$zt_interface"
    uci set network.ZT.auto='1'
    uci commit

    # Configure firewall zone ZZTT if not already configured
    if ! uci show firewall.ZZTT >/dev/null 2>&1; then
        uci add firewall zone
        uci set firewall.@zone[-1].name='ZZTT'
        uci set firewall.@zone[-1].network='ZT'
        uci set firewall.@zone[-1].input='ACCEPT'
        uci set firewall.@zone[-1].output='ACCEPT'
        uci set firewall.@zone[-1].forward='ACCEPT'
        uci set firewall.@zone[-1].masq='1'
        uci commit
        echo "Firewall zone ZZTT configured."
    fi

    # Enable ZeroTier service to start on boot
    /etc/init.d/zerotier enable

    echo "ZeroTier setup completed successfully."

    # Check if the ZeroTier interface has an IP address
    ipaddr=$(get_zerotier_ip "$zt_interface")
    if [ -n "$ipaddr" ]; then
        echo "ZeroTier $n IP address is $ipaddr"
    else
        echo "Please authorize at https://my.zerotier.com/network/"
    fi
}

# Function to get ZeroTier version
get_zerotier_version() {
    zerotier-cli -v
}

# Function to get ZeroTier interface name
get_zerotier_interface() {
    ip a | awk '/^.*: zt[0-9a-fA-F]*/ {print $2}' | cut -d ':' -f 1
}

# Function to get ZeroTier IP address
get_zerotier_ip() {
    ip -4 -o addr show dev "$1" | awk '{print $4}' | cut -d '/' -f 1
}
