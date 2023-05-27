#!/bin/bash

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


# Step 2: Create 'gui.sh' and make it executable

#!/bin/bash

# Create dialog command for the form
dialog_cmd="dialog --form \"Network Settings:\" 0 0 0"
dialog_cmd+=" \"Device Local IP:\" 1 1 \"\" 1 25 25 0"
dialog_cmd+=" \"Local Subnet Mask:\" 2 1 \"\" 2 25 25 0"
dialog_cmd+=" \"ZeroTier Network ID:\" 3 1 \"\" 3 25 25 0"
dialog_cmd+=" \"ZeroTier Device IP:\" 4 1 \"\" 4 25 25 0"
dialog_cmd+=" \"ZeroTier Device IP Mask:\" 5 1 \"\" 5 25 25 0"
dialog_cmd+=" --no-cancel"

# Execute the dialog command and capture the user's input for the form
input=$(eval $dialog_cmd 2>&1 >/dev/tty)

# Parse the user's input for the form
device_local_ip=$(echo "$input" | sed -n '1p')
local_subnet_mask=$(echo "$input" | sed -n '2p')
zerotier_network_id=$(echo "$input" | sed -n '3p')
zerotier_device_ip=$(echo "$input" | sed -n '4p')
zerotier_device_ip_mask=$(echo "$input" | sed -n '5p')

# Print the entered values
echo "Device Local IP: $device_local_ip"
echo "Local Subnet Mask: $local_subnet_mask"
echo "ZeroTier Network ID: $zerotier_network_id"
echo "ZeroTier Device IP: $zerotier_device_ip"
echo "ZeroTier Device IP Mask: $zerotier_device_ip_mask"


inventory_file="inventory.ini"
# Check if the IP address already exists in the inventory
if grep -q "$device_local_ip" "$inventory_file"; then
    echo "IP address $device_local_ip already exists in the inventory."
else
    # Add the IP address below [localpc] in the inventory file
    sed -i "/\[localpc\]/a $device_local_ip" "$inventory_file"
fi


#run first command
#output=$(ansible-playbook 1setvga.yml -i inventory.ini --limit $device_local_ip)
#dialog --msgbox "$output" 0 0


ansible-playbook 1setvga.yml -i inventory.ini --limit $device_local_ip
ansible-playbook 2zerotier.yml -i inventory.ini --limit $device_local_ip
ansible-playbook 3zerto_tier_connect.yml -i inventory.ini -e network_id_var=$zerotier_network_id --limit $device_local_ip


message="Now authenticate server on zerotier website, give it IP $zerotier_device_ip that you gave in the GUI. Enable 'Allow Ethernet Bridging' and 'don't auto assign IP' on the website."
dialog --msgbox "$message" 0 0

ansible-playbook 4vswitch_install.yml -i inventory.ini  --limit $device_local_ip


echo "detect network devices and create the softswitch"



