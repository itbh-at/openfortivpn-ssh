# OPENFORTIVPN-SSH

This container provides possibility to connect remote VPN gateway with
openfortivpn client. Container is working with one time password or so called
token generated on fortitoken generator. We tested it with FortiToken 200. After
container start the token is asked on command line and will be used for next
authentication.

You can use two modes:

- forward mode
- direct mode

In forward mode you can connect to remote server through jump server and provide
forward ports for host OS.

In direct mode you can directly connect with remote server.

## Requirements

- docker installed on your PC [look here](https://docs.docker.com/install/)

Please take into consideration that you need some credentials before you can
continue to work with this script and those are:

- vpn user account
- vpn pasword for this user
- gatway hostname or IP
- jump host account (if you plan to use forward mode)
- forti token generator device

## Usage

For both modes you need to create image from which the container is created and
set proper environment variables. So these steps are common for both modes:

Download this project from git

Build image with build script

```bash
   ./build.sh
```

Please be advised that we use multistage image (for build and for production).
Build script automatically removes intermediate images from the system.

If you wish you can use directly our image from the the docker hub repository
`itbhat/openfortivpn-ssh`

Just write:

```bash
    docker pull itbhat/openfortivpn-ssh:v1.9.0
```

where v1.9.0 is the version of respective openfortivpn client.

`vpn_connect.sh` script uses `itbhat/openfortivpn-ssh:v1.9.0` as default image.
If you prefer to use your own image name you can do it with -i switch
`vpn_connect.sh -i <image_name>`

### Forward mode

Forward mode forwards traffic from contianer through jump host to remote server
where some service is listening. Let's assume we need to connect from our
localhost to Oracle service on port 1521 on remote server. We presume you want
oracle service on port 1519 on your localhost.

```bash
    ./vpn_connect.sh gw-username gw-password gw-host forward jump-host-user@jump-host remote-server 1519:1521
```

If you need more ports to be published please provide hostPort:forwardPort pair
at the end of ./vpn_connect script like this:

```bash
    ./vpn_connect.sh gw-username gw-password gw-host forward jump-host-user@jump-host remote-server  [hostPort1:forwardPort1][hostPort2:forwardPort2] ...
```

You can check your container with command ``docker ps -a``

Its name should be created from particular mode in use and remote server.
`direct-remote-server-name`

If you want to provide your own host-name-IP mapping you can do so by providing
file with -f switch `vpn_connect.sh -f host_file`. This is useful when you need
to use host names for jump host or remote server and DNS resolution isn't
available.

The syntax of this file is following `host-name:IP` where every line contains
one hostname - IP mapping which is directly added in containers `/etc/hosts`
file

Now you should be able to connect to an oracle service on your host
``localhost:1519``

### Direct mode

In case you need directly work with remote server through ssh you can use direct
mode. In this mode prompt from remote server will be at your disposal after
connect.

Just run this command

```bash
    ./vpn_connect.sh gw-username gw-password gw-host direct user@remote-server
```

After this command the tunnel is created, remote server authenticate you and you
will be offered the prompt.