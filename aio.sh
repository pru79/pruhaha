#!/bin/bash

# Source the ZeroTier and Watchcat function files
source zerotier_functions.sh
source watchcat_functions.sh
source vnstat_functions.sh  # Assuming you have a vnstat_functions.sh file with install and uninstall functions

# Function to check Watchcat status
check_watchcat_status() {
    /etc/init.d/watchcat status | grep -q "running"
    return $?
}

# Function to check ZeroTier status
check_zerotier_status() {
    /etc/init.d/zerotier status | grep -q "running"
    return $?
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

# Function to get vnStat version
get_vnstat_version() {
    if command -v vnstat &> /dev/null; then
        vnstat -v | awk '/vnStat/ {print $2}'
    else
        echo "N/A"
    fi
}

# Function to get vnStat status
get_vnstat_status() {
    if [ -x "/etc/init.d/vnstat" ]; then
        vnstat_status=$(/etc/init.d/vnstat status 2>/dev/null)
        if [[ "$vnstat_status" == *"No such file or directory"* ]]; then
            echo "Not installed"
        elif echo "$vnstat_status" | grep -q "running"; then
            echo "Running"
        else
            echo "Stopped"
        fi
    else
        echo "Not installed"
    fi
}

# Function to get vnStat interfaces
get_vnstat_interfaces() {
    if command -v vnstat &> /dev/null; then
        vnstat | grep ":" | awk -F: '{print $1}' | tr '\n' ' ' | sed 's/ $//'
    else
        echo "N/A"
    fi
}

# Function to refresh menu components
refresh_menu() {
    clear
    # ZeroTier status and info
    zerotier_service_status=$(/etc/init.d/zerotier status)
    zerotier_final_status="OFFLINE"
    zerotier_interface=""
    zerotier_ip=""

    if [[ "$zerotier_service_status" == *"running"* ]]; then
        zerotier_final_status="ONLINE"
        zerotier_interface=$(get_zerotier_interface)
        zerotier_ip=$(get_zerotier_ip "$zerotier_interface")
    fi

    zerotier_version=$(get_zerotier_version)

    # Watchcat status and version
    watchcat_config="/etc/config/watchcat"

    if [[ -f "$watchcat_config" ]]; then
        watchcat_downtime=$(awk -F "'" '/option period/ {print $2}' "$watchcat_config")
        watchcat_period=$(awk -F "'" '/option pingperiod/ {print $2}' "$watchcat_config")
        watchcat_script=$(awk -F "'" '/option script/ {print $2}' "$watchcat_config")
    else
        watchcat_downtime="N/A"
        watchcat_period="N/A"
        watchcat_script="N/A"
    fi

    watchcat_service_status=$(/etc/init.d/watchcat status 2>/dev/null)
    watchcat_version=$(opkg list-installed | awk '/watchcat/ {print $3}' | sed 's/-/./')

    if [[ -z "$watchcat_version" ]]; then
        watchcat_final_status="Not installed"
        watchcat_version="N/A"
    elif check_watchcat_status; then
        watchcat_final_status="Running"
    else
        watchcat_final_status="Stopped"
    fi

    # vnStat status and version
    vnstat_final_status=$(get_vnstat_status)
    vnstat_version=$(get_vnstat_version)

    # vnStat interfaces
    vnstat_interfaces=$(get_vnstat_interfaces)

    # Display menu
    cat << EOF
Menu
####
1. ZeroTier
   Status: $zerotier_final_status
EOF

    if [[ "$zerotier_final_status" == "ONLINE" ]]; then
        echo "   Interface: $zerotier_interface"
        echo "   IP Address: $zerotier_ip"
    fi

cat << EOF
   Version: $zerotier_version
2. Watchcat
   Status: $watchcat_final_status
   Max Downtime: $watchcat_downtime
   Period: $watchcat_period
   Script: $watchcat_script
   Version: $watchcat_version
3. Vnstat
   Status: $vnstat_final_status
   Interfaces: $vnstat_interfaces
   Version: $vnstat_version
EOF
}

# Main script loop
while true; do
    refresh_menu
    # Prompt user for input
    read -t 5 -p "Choice: " user_choice
    case "$user_choice" in
        1)
            echo "Choice: 1 (ZeroTier)"

            if check_zerotier_status; then
                while true; do
                    read -p "Disable ZeroTier? [Y]es/[N]o: " disable_zt_choice
                    case "$disable_zt_choice" in
                        [Yy])
                            # Call disable function from zerotier_functions.sh
                            disable_zerotier
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            else
                while true; do
                    read -p "Enable ZeroTier? [Y]es/[N]o: " install_zt_choice
                    case "$install_zt_choice" in
                        [Yy])
                            # Call configure function from zerotier_functions.sh                            configure_zerotier
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            fi
            ;;
        2)
            echo "Choice: 2 (Watchcat)"

            if [[ "$watchcat_version" == "N/A" ]]; then
                # Watchcat is not installed
                while true; do
                    read -p "Install Watchcat? [Y]es/[N]o: " install_watchcat_choice
                    case "$install_watchcat_choice" in
                        [Yy])
                            # Call install function from watchcat_functions.sh
                            install_watchcat
                            monitor_watchcat
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            else
                # Watchcat is installed
                while true; do
                    read -p "Uninstall Watchcat? [Y]es/[N]o: " uninstall_watchcat_choice
                    case "$uninstall_watchcat_choice" in
                        [Yy])
                            # Call uninstall function from watchcat_functions.sh                            uninstall_watchcat
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            fi
            ;;
        3)
            echo "Choice: 3 (Vnstat)"

            if [[ "$vnstat_final_status" == "Running" ]]; then
                while true; do
                    read -p "Uninstall Vnstat? [Y]es/[N]o: " uninstall_vnstat_choice
                    case "$uninstall_vnstat_choice" in
                        [Yy])
                            # Call uninstall function from vnstat_functions.sh
                            uninstall_vnstat
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            else
                while true; do
                    read -p "Install Vnstat? [Y]es/[N]o: " install_vnstat_choice                    case "$install_vnstat_choice" in
                        [Yy])
                            # Call install function from vnstat_functions.sh
                            install_vnstat
                            break
                            ;;
                        [Nn])
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter Y or N."
                            ;;
                    esac
                done
            fi
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, or 3."
            ;;
    esac
done
