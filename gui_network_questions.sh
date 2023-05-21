#!/bin/bash

# Step 1: Install 'dialog' if needed

# Step 2: Create 'gui.sh' and make it executable

#!/bin/bash

# Array of device names
devices=("Device 1" "Device 2" "Device 3" "Device 4" "Device 5")

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


