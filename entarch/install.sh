#!/bin/bash

set -e

LOG=entarch-docker.log
> $LOG

echo "Installing Enterprise Architect prerequisites"
echo "Follow installation instructions of any installer that will show"
echo ""

echo "Installing 32-bit prefix..." 2>&1 | tee -a $LOG
WINEARCH=win32 wine wineboot >>$LOG 2>&1
echo "Installing mdac28..." 2>&1 | tee -a $LOG
winetricks mdac28 >>$LOG 2>&1

if [ -f /home/wineuser/entarch/easetup.msi ]; then
    echo "Installing Enterprise Architect..." 2>&1 | tee -a $LOG
    wine /home/wineuser/entarch/easetup.msi >>$LOG 2>&1
else
    echo "Skipping Enterprise Architect installation - installer not found!"
fi

echo "Installation complete!"

