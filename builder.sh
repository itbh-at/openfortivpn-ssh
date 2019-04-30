#!/bin/bash
#
# Create image required for VPN container.
# Intermediate build image will be deleted at the end of creation process
# This script is used for manual image creation. You can also use our image
# directly from docker hub with command:
#
# docker pull itbhat/openfortivpn-ssh:tagname
#
# where tagname is one of the tags on docker hub in itbhat/openfortivpn-ssh repository (e.x. v1.9.0)
#
# Usage:
#    ./build.sh

docker build -t itbhat/openfortivpn-ssh:v1.9.0 .

#remove intermediate builder image
docker rmi $(docker images -q -f dangling=true)

exit 0