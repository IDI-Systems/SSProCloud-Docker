# SSProCloud-Docker

Docker setup for Sparx Systems Pro Cloud Server for Enterprise Architect, simplifying setup and reducing maintenance on Linux systems.

**Supported Pro Cloud Server versions: `4.2`, `5.0`, `5.1`**

This project is built on top of [docker-wine](https://github.com/scottyhardy/docker-wine), providing Wine and Winetricks for running Sparx Systems software inside a Docker container.

_Note: Sparx Systems does not officially support running Pro Cloud Server or Enterprise Architect in a container. This project is also not supported in any way by Sparx Systems._

Running Pro Cloud Server in a container is composed of 2 separate steps:
- **Installation and Configuration** to setup the environment and install software inside the container. Installers are not publically available so we cannot preinstall them in an image. Additionally, installers require user interface input, for which we use an RDP connection.
- **Running** to run Pro Cloud Server as installed and configured completely headlessly. Due to Wine requirement, Xvfb is still used to provide a virtual screen and allow Wine programs to run.

_Windows host systems are not tested, but should work correctly with Linux containers enabled._


## Setup

### Requirements

- Machine capable of running Linux Docker containers.
- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/).
- An SSL certificate in PEM format _(see below for examples, eg. self-signed, Traefik or other provider)_.
- Pro Cloud Server installer (`ssprocloudserver(_x64).msi`) obtained with a Sparx Systems licence.
- Remote Desktop Protocol client (eg. [Remmina](https://remmina.org/) with [FreeRDP](https://www.freerdp.com/)).

### Install

- Clone this repository.
- Place required Pro Cloud Server files into `ssprocloud` folder (or somewhere accessible by `docker-compose`):
    - SSL certificate `server.pem` if provided as file _(see below for alternatives)_.
    - Installer `ssprocloudserver(_x64).msi`.
- Edit variables in `.env` as required (may skip if following recommendations in this guide).
    - Modify variable starting with `SSPROCLOUD_` according to the version of Pro Cloud Server you have.
    - Modify `BASE_IP` if it clashes with other containers on the machine.
- Bring container up in Admin mode `ADMIN=yes docker-compose up`.
- Establish a Remote Desktop Protocol connection to the container.
    - RDP is only available locally by default, SSH tunneling should be used to connect to a remote RDP session.
    - Remmina with `freerdp` is recommended for ease of use, use the following details to connect:
        - Protocol: RDP - Remote Desktop Protocol
        - [Basic] Server: `localhost` (we connect to RDP locally _after_ connecting with SSH)
        - [Basic] Username: `wineuser`
        - [Basic] Password: `wineuser`
        - [SSH Tunnel] Enable SSH tunnel
        - [SSH Tunnel] Custom: _address of your server_
        - [SSH Tunnel] SSH Authentication: _as required_
- _Desktop of `wineuser` inside the container should now be visible._
- Run `ssprocloud-install.sh` from the Desktop and follow the installation prompts.
    - _(32-bit only)_ Install script will setup a Wine 32-bit prefix and nstall `mdac28` (both required for DBMS), as well as Pro Cloud Server if the installer was correctly setup.
    - _You may run install script multiple times._
- Configure software as necessary _(see below for various documentation on its configuration)_.
    - Entire `wineuser`'s home directory is volume-mounted as `winehome`.
- Close all programs and wait a few seconds for all Wine processes to stop gracefully.
- Shut down the container before proceeding to run it headlessly.

### Run

- Bring container up normally `docker-compose up` (`ADMIN=no` is default).

Container is setup to automatically restart after that. It will run `wine taskmgr` to keep the Wine processes up and running. RDP is not available in this mode, as it interferes with user interface rendering.


## Configuration

### SSL Certificate

An existing SSL certificate or a self-signed one must be used for Pro Cloud Server to fully function.

Certificate is volume-mounted to the appropriate location in Pro Cloud Server installation. Edit the location in `.env` to specify the source.

#### Self-signed

To generate a self-signed certificate for testing purposes:
```sh
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.cert -days 3650 -subj /CN=server
cat server.cert > server.pem
cat server.key >> server.pem
```

#### Traefik

Traefik can be used to provide a certificate with it's Let's Encrypt ACME provider.

Use [traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper) to export the certificates into PEM format Pro Cloud can consume. _Replace `<domain>` with the domain you are generating certificates for._
```yml
services:
  traefik:
    image: traefik:v2.6
    volumes:
      - ./letsencrypt:/letsencrypt

  traefik-certs-dumper:
    image: ldez/traefik-certs-dumper:v2.8.1
    entrypoint: sh -c '
      apk add jq
      ; while ! [ -e /data/acme.json ]
      || ! [ `jq ".[] | .Certificates | length" /data/acme.json` != 0 ]; do
      sleep 1
      ; done
      && traefik-certs-dumper file --version v2 --watch
      --source /data/acme.json --dest /data/certs --domain-subdir=true
      --post-hook "sh /data/server_pem.sh /data/certs/<domain>"'
    networks:
      - traefik
    volumes:
      - ./letsencrypt:/data
```

And use it in `.env`:
```
# Certificate generated by traefik-certs-dumper
SSL_CERT=/opt/docker/traefik/letsencrypt/certs/<domain>/server.pem
```

Following `docker-compose.yml` additions should be made for Web Config to work properly with a sub-path:
```yml
services:
  ssprocloudwebconfig:
    labels:
      - "traefik.http.routers.ssprocloudwebconfig.middlewares=add-trailing-slash@file,ssprocloudwebconfig-strip"
      - "traefik.http.middlewares.ssprocloudwebconfig-strip.stripprefix.prefixes=/ssprocloud"
```

### Credentials

Following credentials are setup by default. They can be changed using Admin mode of the container.

Container user (interactive session or RDP, capable of `sudo`):
- Username: `wineuser`
- Password: `wineuser`

Pro Cloud Config Client:
- Server Address: `localhost:1803`
- Password: `pcsadm1n`

Floating License Server:
- Username: `admin`
- Password: `password`

### Database Managers

#### Native

Native Database Managers are available since Pro Cloud Server v5.0 and should be used instead of ODBC. They do not require additional drivers and are easier to setup.

#### ODBC (v4.x)

**Note: Native Database Managers should be used instead of ODBC!**

_At this time, only Firebird DBMS is tested._

Add a Database Manager (Model) in Pro Cloud Config Client and use `<name>.feap` as a Filename (replace `<name>` with a wanted Model name). This will create a Firebird database which can be loaded in Enterprise Architect.

To load a Model in Enterprise Architect, use the following Cloud Connection details:
- Protocol: `https://`
- Server: _address of your server_
- Port: `1805` for `https://`, `1804` for `http://`
- Model Name: `<name>`

### Floating License Server

Floating License Config Client can connect to Floating License Server using the following details:
- Protocol: `https://`
- Server Address: `localhost`
- Port: `1805`
- Username and Password as noted above

Keystore should successfully load and additional configuration can be done in the user interface or through `ssflsgroups.config` file.

### WebConfig

An image is included for WebClient, hosted with Apache/PHP and by default configured to connect to default Pro Cloud Server port in the server image. `webconfig/settings.php` may be edited accordingly.

**WebClient will not have access to Pro Cloud Server with the default White List setup.** It is advisable to change the password of the Pro Cloud Server `admin` first, then add `181.3.0.3` (as configured) to the White List.
