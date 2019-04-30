#!/bin/sh
#
# Create VPN container from image itbhat/openfortivpn-ssh:tagname from our docker hub repository
# itbhat/openfortivpn-ssh
# If you wish you can use build.sh script to generate own docker image with own name and use this (with -i switch)
#
# There are two modes for this script:
#    - forward
#    - direct mode
# 
# Forward mode is used to forward ports to another host through jump host. Ports are 
# then available in host OS where other clients can use them.
#
# You can add your own hosts to this container.
# Hosts could be loaded from host file (taken with parameter -f).
#
# Usage (forward mode):
#    ./vpn_connect.sh -i image_name -f host_file <user> <password> <gateway> forward <username@jump-host> <remote-server> [<hostOS_port1>:<forward_port1>] [hostOS_port2:forward_port2] ...
#
# Direct mode is used to directly execute ssh command and get back ssh prompt
# You can use dns hostnames in direct mode.
#
# Usage (direct mode):
#    ./vpn_connect.sh -i image_name -f host_file <user> <password> <gateway> direct username@server-dns-or-ip


# Reset the POSIX variable in case getopts has been used previously in the
# shell.
OPTIND=1         


# Initialize variables with default values if not set

: "${IMAGE_NAME:=itbhat/openfortivpn-ssh:v1.9.0}"

show_help() {
  echo "Please use following syntax with modes ('forward' or 'direct). Host file and image name are optional"
  echo "Forward mode: "
  echo "./vpn_connect.sh -i image_name -f host_file <user> <password> <gateway> forward <username@jump-host> <remote-server> [<hostOS_port1>:<forward_port1>] [hostOS_port2:forward_port2] ..."
  echo "Direct mode:"
  echo "./vpn_connect.sh -i image_name -f host_file <user> <password> <gateway> direct  username@server-dns-or-ip"
}

while getopts "h?i:f:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    i)  IMAGE_NAME=$OPTARG
        ;;
    f)  HOST_FILE=$OPTARG
        IFS=$'\n' read -d '' -r -a KNOWN_HOSTS < ${HOST_FILE}
        ;;
    esac
done

shift $(($OPTIND - 1))

VPN_USER=$1
VPN_PASSWORD=$2
GW=$3
MODE=$4

if [[ "${MODE}" == "forward" ]];then

  JUMP_CRED=${5}
  REMOTE_SERVER=${6}

  if [[ ${JUMP_CRED} == *"@"* ]];then
    arrJumpCred=(${JUMP_CRED//@/ })
  else
    arrJumpCred+=($USER) #use currently logged user
    arrJumpCred+=(${JUMP_CRED})
  fi

  if [[ ${REMOTE_SERVER} == *"@"* ]];then
    arrHost=(${REMOTE_SERVER//@/ })
  else
    arrHost+=("")
    arrHost+=(${REMOTE_SERVER})
  fi

  shift 6 #shift other params up until to ports

  forward_ports=""
  while (( "$#" )); do
    published_ports+=" -p ${1}"
    arrPorts=(${1//:/ })

    forward_ports+="${arrPorts[1]} "
    shift
  done

  for i in "${KNOWN_HOSTS[@]}"
    do
        add_hosts+="--add-host $i "
  done

  # delegate this mode to docker container
  COMMAND="docker run ${published_ports} --rm --name="${MODE}-${arrHost[1]}" -it --privileged ${add_hosts} ${IMAGE_NAME} ${VPN_USER} ${VPN_PASSWORD} ${GW} ${MODE} ${REMOTE_SERVER} ${arrJumpCred[0]} ${arrJumpCred[1]} ${forward_ports}"
  echo $COMMAND
  $COMMAND
fi

if [[ "${MODE}" == "direct" ]];then
  # get remote server from params
  REMOTE_SERVER=${5}

  if [[ ${REMOTE_SERVER} == *"@"* ]];then
    arrHost=(${REMOTE_SERVER//@/ })
  fi

  for i in "${KNOWN_HOSTS[@]}"
    do
        add_hosts+="--add-host $i "
  done

  # delegate this mode to docker container
  COMMAND="docker run --rm --name="${MODE}-${arrHost[1]}" -it --privileged ${add_hosts} ${IMAGE_NAME} ${VPN_USER} ${VPN_PASSWORD} ${GW} ${MODE} ${REMOTE_SERVER}"
  echo $COMMAND
  $COMMAND
fi

if [[ "${MODE}" == "rsync" ]];then
# get remote server from params
  REMOTE_SERVER=${5}

  if [[ ${REMOTE_SERVER} == *"@"* ]];then
    arrHost=(${REMOTE_SERVER//@/ })
  fi

  for i in "${KNOWN_HOSTS[@]}"
    do
        add_hosts+="--add-host $i "
  done

  shift 4 # get away previouse options

  if [[ ${#} -eq 3 ]];then
    OPTS=${1}
    SOURCE=${2} 
    DST=${3} 
  else
    SOURCE=${1} 
    DST=${2} 
  fi

  echo ${OPTS}
  echo ${SOURCE}
  echo ${DST}

  # now according to possition mount respective SOURCE/DST folder to container
  if [[ "${SOURCE}" == *"@"* ]];then
    # this is the download case  user@host:/path/on/server --> /path/on/host

    BINDMOUNT_OPT="-v ${DST}:/host_dst/"
  else
   # this is the upload case /path/on/host --> user@host:/path/on/server
   

    if [[ -f "${SOURCE}" ]];then
      # is regular file
      FILE_DIR=${SOURCE%\/*}
      BINDMOUNT_OPT="-v ${FILE_DIR}:/host_dst/"
    else
      # ${SOURCE} is directory
      BINDMOUNT_OPT="-v ${SOURCE}:/host_dst/"
    fi
  fi

  COMMAND="docker run --rm ${BINDMOUNT_OPT} --name="${MODE}-${arrHost[1]}" -it --privileged ${add_hosts} ${IMAGE_NAME} ${VPN_USER} ${VPN_PASSWORD} ${GW} ${MODE} ${OPTS} ${SOURCE} ${DST}"
  echo $COMMAND
  $COMMAND
fi

exit 0