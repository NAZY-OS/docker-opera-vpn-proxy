#!/bin/bash

echo
echo Rebuilding docker in 5 sec
echo
echo
sleep 6

bash remove_docker.sh
bash build_docker.sh

echo
echo
echo Rebuild completed
echo
echo Done!
sleep 2

bash run-docker.sh
