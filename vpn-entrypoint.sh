#!/bin/bash

VPN_USER=${1}
VPN_PASSWORD=${2}
GW=${3}
MODE=${4}

if [ ! -f /dev/ppp ];then
   echo "Creating special /dev/ppp device"
   mknod /dev/ppp c 108 0
fi

echo "Please give me your token (exactly 6 digits):"
read -s -n 6 TOKEN

echo $TOKEN | /usr/bin/openfortivpn ${GW} -u ${VPN_USER} -p ${VPN_PASSWORD}  &
sleep 5 # wait until VPN tunnel is created

shift 4 # shift away VPN_USER VPN_PASSWORD GW and MODE
REMOTE_SERVER=${1}

# get containers IP
CONTAINER_IP=$(ip a | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep 172.17 | grep -v 255.255)


if [[ "${MODE}" == "forward" ]];then
  echo "Forward mode..."
  
  shift # shift away REMOTE_SERVER
  JUMP_USER=${1}
  shift
  JUMP_HOST=${1}
  
  # getent hosts retrup always IP for both: host name or for IP
  echo "Resolving ${REMOTE_SERVER} to IP"
  REMOTE_SERVER_IP=$(getent hosts ${REMOTE_SERVER} | awk '{print $1}')
  echo $REMOTE_SERVER_IP
  
  echo "Resolving ${JUMP_HOST} to IP"
  JUMP_HOST_IP=$(getent hosts ${JUMP_HOST} | awk '{print $1}')
  echo $JUMP_HOST_IP

  shift # get ports
  forward_string=""
  while (( "$#" )); do
    forward_string+=" -L ${CONTAINER_IP}:${1}:${REMOTE_SERVER_IP}:${1}"
    shift
  done

  COMMAND="ssh -N -v -o ServerAliveInterval=60 ${forward_string} ${JUMP_USER}@${JUMP_HOST_IP}"
  echo "Using ssh port forward: ${COMMAND}"
  ${COMMAND}
fi


if [[ "${MODE}" == "direct" ]];then
  echo "Direct mode..."
  ssh -v -o ServerAliveInterval=60 ${REMOTE_SERVER}
fi

if [[ "${MODE}" == "rsync" ]];then
  echo "rsync transfer mode..."

  if [[ ${#} -eq 3 ]];then
    OPTS=${1}
    SOURCE=${2} 
    DST=${3} 
  else
    SOURCE=${1} 
    DST=${2} 
  fi

  if [[ "${SOURCE}" == *"@"* ]];then
    # this is the download case  user@host:/path/on/server --> /path/on/host
    DST="/host_dst/"
  else
    # this is the upload case /path/on/host --> user@host:/path/on/server
    
    FILE=${SOURCE##*/}
    if [[ -f "/host_dst/${FILE}" ]];then
      # is regular file
      SOURCE="/host_dst/${FILE}"
    else
      SOURCE="/host_dst/"
    fi
  fi

  COMMAND="rsync ${OPTS} -e ssh ${SOURCE} ${DST}"
  echo "Executing command: ${COMMAND}"
  $COMMAND
fi

