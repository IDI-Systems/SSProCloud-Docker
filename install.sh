#!/bin/bash

set -e

LOG=ssprocloud-docker.log
> $LOG

echo "Installing SSProCloud prerequisites"
echo "Follow installation instructions of any installer that will show"
echo ""

echo "Installing 32-bit prefix..." 2>&1 | tee -a $LOG
WINEARCH=win32 wine wineboot >>$LOG 2>&1
echo "Installing mdac28..." 2>&1 | tee -a $LOG
winetricks mdac28 >>$LOG 2>&1

if [ -f /home/wineuser/ssprocloud/ssprocloudserver.msi ]; then
    echo "Installing SSProCloud..." 2>&1 | tee -a $LOG
    wine /home/wineuser/ssprocloud/ssprocloudserver.msi >>$LOG 2>&1
else
    echo "Skipping SSProCloud installation - installer not found!"
fi

echo "Installation complete!"
