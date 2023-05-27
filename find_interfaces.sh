#!/bin/bash
# find_interfaces
#  script to find the network interfaces on the host
#  -i 1  to find the internet interface ex. eth0
#  -i 2  to find the ethernet interfaces that reside on same PCI Device ex. eth1,eth2
#  -i 3  to find all physical ethernet interfaces

find_pairs() {
  names=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://')

  declare -A processed_pairs

  IFS=$'\n' read -rd '' -a names_array <<< "$names"

  for i in "${names_array[@]}"; do
    for j in "${names_array[@]}"; do
      if [[ $i == $j ]]; then
        continue
      fi

      if [[ ${processed_pairs["$i-$j"]} == 1 ]]; then
        continue
      fi

      if [[ ${#i} != ${#j} ]]; then
        continue
      fi

      diff_count=0
      for ((k=0; k<${#i}; k++)); do
        if [[ "${i:$k:1}" != "${j:$k:1}" ]]; then
          ((diff_count++))
        fi
      done

      if [[ $diff_count == 1 ]]; then
        echo "$i"
        echo "$j"
        processed_pairs["$i-$j"]=1
        processed_pairs["$j-$i"]=1
      fi
    done
  done
}

if [[ "$1" == "-i" ]]; then
  if [[ "$2" == "1" ]]; then
    # Call the first script
    names=$(ip a | grep BROADCAST | awk '{print $2}' | sed 's/://' | tr ' ' '\n' | grep -vE '^br|^ovs-' | tr '\n' ' ')
    all_SamePCI=$(find_pairs)

    # Loop through each Ethernet network
    for name in $names; do
      # Check if the name of the device belongs to the same pci interfaces
      if ! echo "$all_SamePCI" | grep -q "$name"; then
        # Check if Ethernet device has internet connectivity
        if ping -c 1 -I $name 8.8.8.8 >/dev/null 2>&1; then
          internet_interface="$name"
          break
        fi
      fi
    done

    echo "$internet_interface"
  elif [[ "$2" == "2" ]]; then
    # Call the second script
    find_pairs
  elif [[ "$2" == "3" ]]; then
    # Call the third script show all physical ethernet connections
    ip a | awk '/^[0-9]+: (eth|en|eno|ens|enp)/ {print substr($2, 1, length($2)-1)}' | grep -vE '^lo$'
  else
    echo "Invalid argument for -i"
    exit 1
  fi
else
  echo "Invalid arguments"
  exit 1
fi
