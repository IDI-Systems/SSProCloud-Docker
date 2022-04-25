#!/bin/bash

ADMIN=${ADMIN:-no}
SSPROCLOUD_64BIT=${SSPROCLOUD_64BIT:-yes}

if [ "${ADMIN}" = "yes" ]; then
    echo "Running in 'admin' mode - RDP enabled"

    # Create Desktop folder as it won't be created until RDP server runs
    mkdir -p /home/wineuser/Desktop

    # Create desktop shortcut to install.sh (replace if already exists to update variables)
    rm /home/wineuser/Desktop/ssprocloud-install.sh
    echo 'xfce4-terminal -x bash -c "USE_64BIT='$SSPROCLOUD_64BIT' /usr/bin/ssprocloud-install; read -p \"Press enter to close\""' > /home/wineuser/Desktop/ssprocloud-install.sh
    chmod +x /home/wineuser/Desktop/ssprocloud-install.sh

    # Run RDP
    RDP_SERVER=yes exec /usr/bin/entrypoint
else
    echo "Running headless - RDP disabled"

    # Make sure wineuser is created (will throw gosa error, but we can ignore that)
    /usr/bin/entrypoint > /dev/null 2>&1

    # Kill any existing Xvfb lock from previous runs
    if [ -f /tmp/.X95-lock ]; then
        rm /tmp/.X95-lock
    fi

    # Run Xvfb to start wine programs, as xrdp does not create a display until something connects
    # Start a wine application (task manager) to keep Windows Services running (eg. SSProCloud)
    Xvfb :95 -screen 0 320x200x8 & sleep 1
    DISPLAY=:95 exec sudo -u wineuser -s wine taskmgr
fi
