#!/bin/bash
# This bash script will search for ethernet interfaces, assmying that there is an internal interface in the PCI
# this one is connected to internet, it will be connected to public zone
# there is a PCIe card with other interfaces eth1/eth2... etc, it will take last interface, in my case eth2, and connect it to internal_with_internet
# there are other interfaces in the PCI, these will be connected to internal_without_internet.
# Zerotier ip is given as first parameter
# example: ./connect_ethernet_interfaces_to_zones.sh 10.147.20.0

# note that communiction between zones is not done in this script.


#input zerotier ip range to the script 10.147.20.0
zt_ip="$1"

# Determine Ethernet names and filter out bridges called br* or ovs*
names=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://' | tr ' ' '\n' | grep -vE '^br|^ovs-' | tr '\n' ' ')

# Determine last Ethernet device with the same PCI ID
all_SamePCI=$(sudo /tmp/find_network_interfaces_same_pci.sh)
echo "all interfaces in same pci are $all_SamePCI";

# Get the last interface in the list
last_interface=$(echo "$all_SamePCI" | tail -n 1)
echo "last interface in same pci is $last_interface"

# Loop through each Ethernet network
for name in $names; do
    echo "checking now .. $name";
    # Check if ZeroTier network interface
    if [[ "$name" == zt* && "$name" != br* && "$name" != ovs* ]]; then
        echo "ZeroTier interface: $name"
        # Determine the IP address of the ZeroTier interface and add it to the trusted zone
        sudo firewall-cmd --zone=trusted --add-source="$ip/24" --permanent
    else #not zerotier -> can be eth0/eth1/eth2
        #check if the name of the device belongs to the same pci interfaces
        if [[ $(echo $all_SamePCI | grep $name) ]]; then #eth2/eth1
            if [[ "$name" == "$last_interface" ]]; then # eth 2
                echo "Ethernet interface $name is the last device with the same PCI ID"
                firewall-cmd --zone=internal_without_internet --add-interface=$name --permanent
            else #eth1
                echo "Ethernet interface $name is not the last device with the same PCI ID"
                firewall-cmd --zone=internal_with_internet --add-interface=$name --permanent
            fi
        else #eth 0
            if ping -c 1 -I "$name" www.google.com > /dev/null; then #eth0
                echo "Ethernet interface $name has internet access"
                firewall-cmd --zone=public --add-interface=$name --permanent
            fi
        fi
    fi
done

# Reload the firewall
sudo firewall-cmd --reload

