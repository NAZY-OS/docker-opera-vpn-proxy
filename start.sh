#!/bin/bash

# Download the latest hosts block file
sudo wget -O /etc/hosts https://someonewhocares.org/hosts/hosts
if [ -f "/etc/hosts2" ]; then
    sudo su -c "cat /etc/hosts2 >> /etc/hosts"
fi

# Base port for Tor instances
TOR_PORT_BASE=9350  # Adjusted to the port range of the Docker script

OPERA_PROXY_COUNTRY=AS

# Possible values
## EU
## AS
## AM

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
sudo -u tor tor --SocksPort "${TOR_PORT_BASE}" --ControlPort "$((TOR_PORT_BASE + 100))" \
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
  # Random delay between 300 and 600 seconds to stagger renewals
  sleep $((RANDOM % 301 + 300))
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


# Start VPN processes
proxychains -f /etc/proxychains-tor.config /usr/bin/opera-vpn -bind-address 127.0.0.1:18081 -socks-mode -country ${OPERA_PROXY_COUNTRY} -server-selection random -api-proxy-parallel 15 &
proxychains -f /etc/proxychains-firewhonix.config /usr/bin/opera-vpn -bind-address 127.0.0.1:1081 -socks-mode -country ${OPERA_PROXY_COUNTRY} -server-selection random -api-proxy-parallel 15 &
/usr/bin/opera-vpn -socks-mode -country ${OPERA_PROXY_COUNTRY} -server-selection random -api-proxy-parallel 15 &
