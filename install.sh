#!/bin/bash

set -e

echo "Installing SSProCloud prerequisites"
echo "Follow installation instructions of any installer that will show"
echo ""

echo "Installing 32-bit prefix..."
WINEARCH=win32 wine wineboot &> ssprocloud-docker.log
echo "Installing mdac28..."
winetricks mdac28 &> ssprocloud-docker.log

if [ -f /home/wineuser/ssprocloud/ssprocloudserver.msi ]; then
    wine /home/wineuser/ssprocloud/ssprocloudserver.msi
else
    echo "Skipping SSProCloudServer installation - installer not found!"
fi
if [ -f /home/wineuser/ssprocloud/server.pem ]; then
    cp /home/wineuser/ssprocloud/server.pem /home/wineuser/.wine/drive_c/Program\ Files/Sparx\ Systems/Pro\ Cloud\ Server/Service/server.pem
else
    echo "Skipping SSL Certificate installation - certificate not found!"
fi

echo "Installation complete!"
