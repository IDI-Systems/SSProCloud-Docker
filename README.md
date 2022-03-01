# SSProCloud-Docker

Docker setup for Sparx Systems Pro Cloud Server for Enterprise Architect.

**Supported Pro Cloud Server version: `4.2`**

This project is built on top of [docker-wine](https://github.com/scottyhardy/docker-wine), providing Wine and Winetricks for running Sparx Systems software inside a Docker container.

_Note: Sparx Systems does not officially support running Pro Cloud Server or Enterprise Architect in a container. This project is also not supported in any way by Sparx Systems._

Running Pro Cloud Server in a container is composed of 2 separate steps:
- **Installation and Configuration** to setup the environment and install software inside the container. Installers are not publically available so we cannot preinstall them in an image. Additionally, installers require user interface input, for which we use an RDP connection.
- **Running** to run Pro Cloud Server as installed and configured completely headlessly. Due to Wine requirement, Xvfb is still used to provide a virtual screen and allow Wine programs to run.


## Setup

### Install

- Clone this repository.
- Place required Pro Cloud Server files somewhere (recommended into `ssprocloud` folder).
    - SSL certificate `server.pem` _(see below)_.
    - Installer `ssprocloudserver.msi` as obtained by Sparx Systems licence.
- Edit `.env` as required (may skip if following recommendations in this guide).
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
    - Install script will setup a Wine 32-bit prefix and nstall `mdac28` (both required for DBMS), as well as Pro Cloud Server if the installer was correctly setup.
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

To generate a self-signed certificate for testing purposes:
```sh
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.cert -days 3650 -subj /CN=server
cat server.cert > server.pem
cat server.key >> server.pem
```

Certificate is volume-mounted to the appropriate location in Pro Cloud Server installation. Edit the location in `.env` to specify the source.

### Credentials

Following credentials are setup by default. They can be changed using Admin mode of the container.

Container user (interactive session or RDP, capable of `sudo`):
- Username: `wineuser`
- Password: `wineuser`

Pro Cloud Config Client:
- Server Address: `localhost:1803`
- Password: `pcsadm1n`

### Database Managers

_At this time, only Firebird DBMS is tested._

Add a Database Manager (Model) in Pro Cloud Config Client and use `<name>.feap` as a Filename (replace `<name>` with a wanted Model name). This will create a Firebird database which can be loaded in Enterprise Architect.

TO load a Model in Enterprise Architect, use the following Cloud Connection details:
- Protocol: `https://`
- Server: _address of your server_
- Port: `1805` for `https://`, `1804` for `http://`
- Model Name: `<name>`

### Floating License Server

Minimal configuration includes modifying the `ssflsgroups.config` to allow access to the Floating License Config Client to connect to the Server. The following can be done in Admin mode inside the container or in volume-mounted `winehome`.

- Open `"winehome/wineuser/.wine/drive_c/Program Files/Sparx Systems/Pro Cloud Server/Service/ssflsgroups.config"`.
- Find Administrator group named `Sparx PCS Floating License Admin`.
- Replace `EncryptPwd=Z?@k$wvaxzm2Ak` with `Password=admin` (or other custom password).
    - _Floating License Config Client will crash if an empty password is provided!_

Now Floating License Config Client can connect to Floating License Server using the following details:
- Protocol: `https://`
- Server Address: `localhost`
- Port: `1805`
- User Name: `admin`
- Password: `admin` (or password set above)

Keystore should successfully load and additional configuration can be done in the user interface or through `ssflsgroups.config` file.
