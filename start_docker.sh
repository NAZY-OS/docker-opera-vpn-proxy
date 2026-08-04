#!/bin/bash

read -p "Do you want to start the container interactively? (y/n): " response

# Definiere die Ports
EXTERNAL_PORT_18080=18080
EXTERNAL_PORT_18081=18081
EXTERNAL_PORT_18982=18982

# Starte den Docker-Container
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    docker run --rm -it \
        -p $EXTERNAL_PORT_18080:$EXTERNAL_PORT_18080 \
        -p $EXTERNAL_PORT_18081:$EXTERNAL_PORT_18081 \
        -p $EXTERNAL_PORT_18982:$EXTERNAL_PORT_18982 \
        --network host \
        opera-vpn-proxy /bin/sh -c "echo 'Container started' && sh -c '/sbin/start.sh &';bash"
else
    docker run --rm \
        -p $EXTERNAL_PORT_18080:$EXTERNAL_PORT_18080 \
        -p $EXTERNAL_PORT_18081:$EXTERNAL_PORT_18081 \
        -p $EXTERNAL_PORT_18982:$EXTERNAL_PORT_18982 \
        --network host \
        opera-vpn-proxy /bin/sh -c "echo 'Container started' && sh -c '/sbin/start.sh &';bash"
fi
