#!/bin/bash

# Download the latest hosts block file
sudo wget -O /etc/hosts https://someonewhocares.org/hosts/hosts
if [ -f "/etc/hosts2" ]; then
    sudo su -c "cat /etc/hosts2 >> /etc/hosts" && echo && echo "Custom Host Deny List" && echo && cat /etc/hosts2 
    echo
fi

# Base port for Tor instances
TOR_PORT_BASE=9150  # Adjusted to the port range of the Docker script

# Use a temporary directory in RAM (e.g., tmpfs)
base_tmp_dir="/mnt/ramdisk"  # Make sure this is created

# Create the directory if it does not exist and mount it
mkdir -p "$base_tmp_dir" && mount -t tmpfs -o size=1G tmpfs "$base_tmp_dir" 2> /dev/null

# Create a unique folder for each Tor instance
tor_data_dir="$base_tmp_dir/tor_instance_${TOR_PORT_BASE}"
mkdir -p "$tor_data_dir"

# Change the ownership of the folder (check if user 'tor' exists)
if id "tor" &>/dev/null; then
    chown tor:tor "$tor_data_dir"
else
    echo "User 'tor' does not exist!"
    exit 1
fi

# Start the Tor instance with specific parameters and redirect output
sudo -u tor tor --SocksPort "${TOR_PORT_BASE}" --ControlPort "9151" \
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

echo "Started Tor client on port ${TOR_PORT_BASE} with data directory $tor_data_dir"
sleep 2  # Ensure Tor has time to start
kill -USR1 $(pidof tor)


# Signal processing loop to renew circuits periodically
while true; do
  sleep 90
  kill -USR1 $(pidof tor)
  echo
  echo "Renewing circuit for $(pidof tor)"
  echo
done &

# Start dnscrypt-proxy client
stubby -l &

# Wait for Tor to be ready (45 seconds max, with GNU-style countdown)
echo
echo -n "Waiting for Tor to start..."
echo

for ((i=1; i<=45; i++)); do
  if nc -z 127.0.0.1 ${TOR_PORT_BASE}; then
    printf "\rTor is ready. Proceeding with VPN setup.\n"
    break
  else
    printf "\rWaiting for Tor to start (%d/45)..." "$i"
    sleep 1
  fi
done

# Exit if Tor didn't start
if ! nc -z 127.0.0.1 9250; then
  echo "Error: Tor did not start on port ${TOR_PORT_BASE} after 45 seconds!"
fi

# Verify Tor connection
echo -n "Verifying Tor connection..."
if curl --socks5-hostname 127.0.0.1:${TOR_PORT_BASE} -s https://check.torproject.org/ \
   | grep -q "Congratulations. This browser is configured to use Tor." &>/dev/null; then
  printf "\rTor connection verified. Starting VPN...\n"
else
  printf "\rError: Tor is running but not routing traffic correctly!\n"
  echo "Response from check.torproject.org:"
  curl --socks5-hostname 127.0.0.1:${TOR_PORT_BASE} -s https://check.torproject.org/
fi

# Start VPN processes
/usr/bin/opera-vpn -bind-address 127.0.0.1:18081 -country AS -proxy socks5://127.0.0.1:${TOR_PORT_BASE} -server-selection random &
/usr/bin/opera-vpn -bind-address 127.0.0.1:1081 -country AS -proxy socks5://127.0.0.1:4711 -server-selection random &
/usr/bin/opera-vpn -country AS -server-selection random &
