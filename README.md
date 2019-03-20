# About

This container provides possibility to connect with remote VPN gateway with openfortivpn client. You can use two modes:

- forward mode
- direct mode

In forward mode you can connect to remote server through jump server and provide forward ports for host OS.

In direct mode you can directly connect with remote server.


# Requirements

- docker installed on your PC [look here](https://docs.docker.com/install/)

Please take into consideration that you need some credentials before you can continue to work with this script and those are:

- vpn user account
- vpn pasword for this user
- gatway hostname or IP
- jump host account (if you plan to use forward mode)

# Usage

For both modes you need to create image from which the container is created and set proper environment variables. So these steps are common for both modes:

Download this project from git

```
    git clone https://gitlab.devops.cloud.itbh.at/kabelplus/kabelplusvpn.git
    cd kabelplusvpn
```

Build image with build script
```
   ./build.sh

```
Please be advised that we use multistage image (for build and for production). Build script automatically removes intermediate images from the system.


## Forward mode

If you want to connect with a remote oracle service and make this to listen on your host OS use port forward mode  like this (we persume you want oracle service on port 1519 on your localhost):


```
    ./vpn_connect.sh gw-username gw-password gw-host forward jump-host-user@jump-host remote-server 1519:1521
```

If you need more ports to be published please provide hostPort:forwardPort pair at the end of ./vpn_connect script like this:

```
./vpn_connect.sh gw-username gw-password gw-host forward jump-host-user@jump-host remote-server  [hostPrt1:forwPrt1][hostPrt2:forwPrt2] ...
```

You can check your container with command ``docker ps -a``

Its name should be created according to particular mode in use. For example if you connect in forward mode on to remote-server the name will be
``vpn-kabelplus-forward-<ip-of-remote-server>```

If you want provide your own host-name (jump host or remote server) please add them
into vpn_connect.sh script in KNOWN_HOSTS array in form
`host-name:IP`

and you can use it for jump-host or remote-server arguments. They will be translated to IP automatically.

Now you should be able to connect to an oracle service on your host ``localhost:1519``

## Direct mode

In case you need directly work with remote server through ssh you can use direct mode. In this mode prompt from remote server will be at your disposal after connect.

Just run this command

```
./vpn_connect.sh gw-username gw-password gw-host direct user@remote-server
```

After this command the tunnel is created, remote server authenticate you and you will be offered the prompt.