#!/bin/bash


echo "set vga, and network settings"
ansible-playbook 1setvga.yml -i inventory.ini --limit 192.168.188.59

ansible-playbook 2zerotier.yml -i inventory.ini --limit 192.168.188.59

ansible-playbook 3zerto_tier_connect.yml -i inventory.ini -e network_id_var=8bd5124fd642e41c --limit 192.168.188.59

ansible-playbook 4vswitch_install.yml -i inventory.ini  --limit 192.168.188.59
"echo authenticate zerotier now"
read

ansible-playbook 5bridge_network_device_same_PCI.yml -i inventory.ini  --limit 192.168.188.59

ansible-playbook 6add_Zerotier_to_bridge.yml -i inventory.ini -e network_id_var=8bd5124fd642e41c --limit 192.168.188.59

echo "Autheticte the zerotier adapter from Zerotier website and make sure you can ping the machine  .. Press any key to continue..."
read

while true
do
    ping -c 1 10.147.20.2 > /dev/null
    if [ $? -eq 0 ]
    then
        echo "Ping successful, continuing..."
        break
    fi
    echo "Ping failed, retrying in 5 seconds..."
    sleep 5
done


ansible-playbook 7create_br0_file.yml -i inventory.ini -e zt_network_id=8bd5124fd642e41c -e bridge_ip=10.147.20.2 -e bridge_netmask=255.255.255.0 --limit 10.147.20.2

ansible-playbook -i inventory.ini 9install_fusionpbx.yml --extra-vars "domain_name=10.147.20.2 system_username=admin system_password=sherifomran database_name=fusionpbx database_username=fusionpbx database_password=sherifomran letsencrypt_folder=false" --limit 10.147.20.2


