#!/bin/bash

# Determine Ethernet names and filter out bridges called br* or ovs*
names=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://' | tr ' ' '\n' | grep -vE '^br|^ovs-' | tr '\n' ' ')
all_SamePCI=$(sudo /tmp/find_network_interfaces_same_pci.sh)

# Loop through each Ethernet network
for name in $names; do
    # Check if the name of the device belongs to the same pci interfaces
    if ! echo "$all_SamePCI" | grep -q "$name"; then
        # Check if Ethernet device has internet connectivity
        if ping -c 1 -I $name 8.8.8.8 >/dev/null 2>&1; then
            inter_interface="$name"
            break
        fi
    fi
done

echo "$inter_interface"

