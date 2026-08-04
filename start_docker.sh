#!/bin/bash

# Prompt: Enable debug mode?
read -p "Start container in debug mode? (y/n) [Enter = n]: " response

# Default: Debug mode disabled (if Enter is pressed)
response=${response:-n}

# Normalize input (y/yes → true, n/no → false)
case "$response" in
    [yY]|[yY][eE][sS]) debug_mode=true ;;
    [nN]|[nN][oO])     debug_mode=false ;;
    *)                 debug_mode=false ;;  # Default: n/Enter
esac

# Define ports
EXTERNAL_PORT_18080=18080
EXTERNAL_PORT_18081=18081
EXTERNAL_PORT_1081=1081

# Start the Docker container
if [[ "$debug_mode" == true ]]; then
    echo "Starting container in DEBUG MODE..."
    docker run --rm -it \
        -p $EXTERNAL_PORT_18080:$EXTERNAL_PORT_18080 \
        -p $EXTERNAL_PORT_18081:$EXTERNAL_PORT_18081 \
        -p $EXTERNAL_PORT_1081:$EXTERNAL_PORT_1081 \
        --network host \
        opera-vpn-proxy /bin/sh -c "echo 'Container started' && sh -c 'bash -xv /sbin/start.sh &';bash"
else
    echo "Starting container in PRODUCTION MODE..."
    docker run --rm -it \
        -p $EXTERNAL_PORT_18080:$EXTERNAL_PORT_18080 \
        -p $EXTERNAL_PORT_18081:$EXTERNAL_PORT_18081 \
        -p $EXTERNAL_PORT_1081:$EXTERNAL_PORT_1081 \
        --network host \
        opera-vpn-proxy /bin/sh -c "echo 'Container started' && sh -c '/sbin/start.sh &';bash"
fi
