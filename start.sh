#!/bin/bash

# Download latest hosts block file

sudo wget -O /etc/hosts https://someonewhocares.org/hosts/hosts
sudo su -c "cat /etc/hosts2 >> /etc/hosts"

# Base port for Tor instances
TOR_PORT_BASE=9050  # Adjusted to the port range of the Docker script

# Use a temporary directory in RAM (e.g., tmpfs)
base_tmp_dir="/mnt/ramdisk"  # Make sure this is created

# Create the directory if it does not exist
#mkdir -p "$base_tmp_dir"
mount -t tmpfs -o size=1G tmpfs "$base_tmp_dir" 2> /dev/null

port=9050

# Create a unique folder for each Tor instance
tor_data_dir="$base_tmp_dir/tor_instance_$port"
mkdir -p "$tor_data_dir"

# Change the ownership of the folder
chown tor:tor "$tor_data_dir"

# Start the Tor instance with specific parameters and redirect output
sudo -u tor tor --SocksPort "$port" --ControlPort "9150" \
    --DataDirectory "$tor_data_dir" \
    --Sandbox 1 \
    --HardwareAccel 1 \
    --BandwidthBurst 1547483647 \
    --BandwidthRate 1547483647 \
    --ExcludeExitNodes '{us},{uk},{ca},{au},{nz},{dk},{fr},{nl},{no},{de},{be},{se},{es},{it},{at},{fi},{ru}' \
    --ClientOnly 1 \
    --DisableNetwork 0 \
    --UseBridges 0 \
    --DisableDebuggerAttachment 1 \
    --AvoidDiskWrites 1 1> /dev/null &

echo "Started Tor client on port $port with data directory $tor_data_dir"
sleep 1  # Ensure Tor has time to start

# Signal processing loop
while true; do
  sleep 90
  kill -USR1 $(pidof tor)
  echo
  echo "Renewing circuit for $(pidof tor)"
  echo
done &

# Start dnscrypt-proxy client
stubby -l &

# Start processes
/usr/bin/opera-vpn -bind-address 127.0.0.1:18081 -proxy socks5://127.0.0.1:9050 &
/usr/bin/opera-vpn &
