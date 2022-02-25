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

    # Remove duplicated link files on Desktop
    rm "/home/wineuser/Desktop/Pro Cloud Config Client.lnk"
    rm "/home/wineuser/Desktop/Floating License Config Client.lnk"
else
    echo "Skipping SSProCloudServer installation - installer not found!"
fi

echo "Installation complete!"
