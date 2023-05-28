#!/bin/bash
###########################################################
# Script: gui_network_questions.sh
# Author: Dr. Sherif Omran
# Date: 27.05.2023
# Description: This script presents a dialog-based interface
#              to configure network settings for a list of
#              devices. It allows selecting options such as
#              "Main Router Internet," "With Internet," and
#              "Without Internet" for each device. The list 
#              of devices can be given in the command line
#
# Notes: 
#
#   - Requires 'dialog' package to be installed.
#   - Devices can be provided as command line arguments.
#     and if not provided, it will use default 5 devices
#   - IP Address of machine is 3rd last argument, if not
#     given it will use default 127.0.0.1
#   - Zerotier address is 2nd last argument, if not given 
#     it will use 10.147.20.2
#   - zerotier subnet mask as last argument, if not given
#     it will use 255.255.255.0
#
#         gui_network_questions device1 device2  192.168.188.1 10.147.20.2 255.255.255.0
#         gui_network_questions
#
# ./gui_network_questions.sh         "enp1s0f0", "enp2s0", "enp1s0f1", "enp1s0f2", "enp1s0f3", "ztyqbvbk6k" 192.168.188.51 10.147.20.3 255.255.255.0
###########################################################


# Function to convert IP address and subnet mask to network range
convert_to_network_range() {
  local ip_address="$1"
  local subnet_mask="$2"

  # Convert IP address to binary
  IFS='.' read -r -a ip_parts <<< "$ip_address"
  ip_binary=""
  for part in "${ip_parts[@]}"; do
    ip_binary+="$(printf "%08d" "$(bc <<< "obase=2;$part")")"
  done

  # Convert subnet mask to binary
  IFS='.' read -r -a mask_parts <<< "$subnet_mask"
  mask_binary=""
  for part in "${mask_parts[@]}"; do
    mask_binary+="$(printf "%08d" "$(bc <<< "obase=2;$part")")"
  done

  # Calculate network address
  network_binary=""
  for ((i=0; i<${#ip_binary}; i++)); do
    if [ "${ip_binary:$i:1}" == "1" ] && [ "${mask_binary:$i:1}" == "1" ]; then
      network_binary+="1"
    else
      network_binary+="0"
    fi
  done

  # Convert network address binary to decimal
  network_parts=()
  for ((i=0; i<${#network_binary}; i+=8)); do
    network_parts+=("$((2#${network_binary:$i:8}))")
  done

  network_address="${network_parts[0]}.${network_parts[1]}.${network_parts[2]}.${network_parts[3]}"

  echo "$network_address"
}


# Step 1: Install 'dialog' if needed
# Check if dialog is installed
if ! command -v dialog >/dev/null 2>&1; then
  echo "Dialog is not installed. Installing..."
  
  # Check if the package manager is apt or yum
  if command -v apt >/dev/null 2>&1; then
    # Install dialog using apt
    sudo apt update
    sudo apt install -y dialog
  elif command -v yum >/dev/null 2>&1; then
    # Install dialog using yum
    sudo yum update
    sudo yum install -y dialog
  else
    echo "Unable to determine the package manager. Please install dialog manually."
    exit 1
  fi

  echo "Dialog has been installed."
else
  echo "Dialog is already installed."
fi

#Step 2: Extract ip from last argument and devices from other arguments
# Get the IP address from the 3rd last argument
device_local_ip_address="${@: -3:1}"

# Get the ZeroTier IP address from the 2nd last argument
zerotier_ip="${@: -2:1}"

# Get the ZeroTier subnet mask from the last argument
zerotier_subnet_mask="${!#}"

# Get the device names from the remaining arguments
if [ $# -gt 3 ]; then
  devices=("${@:1:$(($#-3))}")
else
  devices=("Device 1" "Device 2" "Device 3" "Device 4" "Device 5")
fi


# Exclude the ZeroTier device (starts with "zt")
zt_device=""
for device in "${devices[@]}"; do
  if [[ "$device" == "zt"* ]]; then
    zt_device="$device"
    continue
  fi
  filtered_devices+=("$device")
done

# Assign the filtered devices without zt to the devices array
devices=("${filtered_devices[@]}")

# Step 3: Ask about each network interface if it is connected to internet or not or router main lan
# If devices are provided as command line arguments, use them; otherwise, use the default devices array

# Array to store selected options for each device
selected_options=()

# Array to store devices selected as "Main Router Internet"
main_router_devices=()

# Array to store devices with the "With Internet" option
with_internet_devices=()

# Add the ZeroTier device to the with_internet_devices array
# if the variable is not empty
if [ -n "$zt_device" ]; then
  with_internet_devices=("$zt_device")
fi

# Array to store devices with the "Without Internet" option
without_internet_devices=()

# Variable to track the count of devices selected as "Main Router Internet"
main_router_count=0

# Iterate over each device
for device in "${devices[@]}"; do
    # Create dialog command for the device form
    dialog_cmd="dialog --stdout --radiolist \"${device} Settings:\" 0 0 0"
    dialog_cmd+=" \"Main Router Internet\" \"\" off"
    dialog_cmd+=" \"With Internet\" \"\" off"
    dialog_cmd+=" \"Without Internet\" \"\" off"

    # Execute the dialog command for the device and capture the user's input
    input=$(eval "$dialog_cmd")

    # Store the selected option for the device
    selected_options+=("${device} status: ${input}")

    # Check if the selected option is "Main Router Internet"
    if [[ "$input" == "Main Router Internet" ]]; then
        ((main_router_count++))
        main_router_devices+=("$device")
    fi

    # Check if the selected option is "With Internet"
    if [[ "$input" == "With Internet" ]]; then
        with_internet_devices+=("$device")
    fi

    # Check if the selected option is "Without Internet"
    if [[ "$input" == "Without Internet" ]]; then
        without_internet_devices+=("$device")
    fi

done

# Check if more than one device is selected as "Main Router Internet"
if [[ "$main_router_count" -gt 1 ]]; then
    echo "Error: Cannot have more than 1 device selected as Main Router Internet."
    exit 1
fi

# Print the selected options for all devices
for option in "${selected_options[@]}"; do
    echo "$option"
done

echo "-------------------"

# Print devices with the "Main Internet" option
echo "Devices with the \"Main Internet Router\" option:"
for device in "${main_router_devices[@]}"; do
    echo "$device"
done

echo "---------------"


# Print devices with the "With Internet" option
echo "Devices with the \"With Internet\" option:"
for device in "${with_internet_devices[@]}"; do
    echo "$device"
done

echo "---------------"

# Print devices with the "Without Internet" option
echo "Devices with the \"Without Internet\" option:"
for device in "${without_internet_devices[@]}"; do
    echo "$device"
done

# Print the extracted IP address and device names
echo "IP Address: $device_local_ip_address"
echo "Device Names: ${devices[@]}"
echo "ZeroTier Device: $zt_device"
echo "ZeroTier IP Address: $zerotier_ip"
echo "ZeroTier Subnet Mask: $zerotier_subnet_mask"


#Step 3 now create the bridge that includes all devices with internet and without internet
# except the local host that is already filtered and main router lan device

# Convert the arrays to comma-separated strings
with_internet_devices_string=$(IFS=,; echo "${with_internet_devices[*]}")
with_internet_devices_string="${with_internet_devices_string//,,/,}"
with_internet_devices_string="${with_internet_devices_string%,}"

without_internet_devices_string=$(IFS=,; echo "${without_internet_devices[*]}")
without_internet_devices_string="${without_internet_devices_string//,,/,}"
without_internet_devices_string="${without_internet_devices_string%,}"

#here are main router devices, although it is only 1 device for now, but i convert it
#because i intend to bind multiple main devices later on
main_router_devices_string=$(IFS=,; echo "${main_router_devices[*]}")
main_router_devices_string="${main_router_devices_string//,,/,}"
main_router_devices_string="${main_router_devices_string%,}"


read -p "Press Enter to start creating the bridge devices ..."

# Run the Ansible playbook and pass the devices strings as extra variables
# this will create the ovs bridge and add all devices including zerotier to the br0, it will exclude the main router internet device
ansible-playbook 6bridge_network_device_same_PCI.yml -e "with_internet_devices=$with_internet_devices_string" \
                         -e "without_internet_devices=$without_internet_devices_string" \
                         -e "zerotier_ip=$zerotier_ip" \
                         -e "zerotier_subnet_mask=$zerotier_subnet_mask" \
                         -i inventory.ini --limit "$device_local_ip_address"



#Step 4 create the local br0 file but here i need to pass: the zt_ip_address/subnet mask from main script
# with_internet_devices/without_internet_devices because they are all added to the bridge, except main router device, 
# i need also to pass zerotier device in this $zt_device

read -p "Press Enter to create the bridge file..."

ansible-playbook 7create_br0_file.yml -e "with_internet_devices=$with_internet_devices_string" \
                         -e "without_internet_devices=$without_internet_devices_string" \
                         -e "zt_device=$zt_device" \
                         -e "bridge_ip=$zerotier_ip" \
                         -e "bridge_netmask=$zerotier_subnet_mask" \
                         -i inventory.ini --limit "$device_local_ip_address"

#Step 5 allow tranffic forwarder 
ansible-playbook 8allow_traffic_forward.yml -i inventory.ini --limit "$device_local_ip_address"

#Step 6 convert zerotier ip and subnet into range
zt_network_range=$(convert_to_network_range "$zerotier_ip" "$zerotier_subnet_mask")

#Step 7 create the firwall, pass zerotier ip 10.147.20.0 with last variable 0
read -p "Press endter to create the firewall .."
ansible-playbook 8firewall_gateway_setup.yml -i inventory.ini \
                         -e "zerotier_ip_range=$zt_network_range"  \
                         -e "without_internet_devices=$without_internet_devices_string" \
                         -e "with_internet_devices=$with_internet_devices_string" \
                         -e "main_router_devices=$main_router_devices_string" \
                         --limit "$device_local_ip_address"


