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
#
#         gui_network_questions device1 device2
#         gui_network_questions
#
###########################################################


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

# Step 2: Run 'gui.sh' and make it executable
# If devices are provided as command line arguments, use them; otherwise, use the default devices array
if [ $# -gt 0 ]; then
  devices=("$@")
else
  devices=("Device 1" "Device 2" "Device 3" "Device 4" "Device 5")
fi

# Array to store selected options for each device
selected_options=()

# Array to store devices selected as "Main Router Internet"
main_router_devices=()
# Array to store devices with the "With Internet" option
with_internet_devices=()
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


