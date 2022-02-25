#!/bin/bash

MODE=${MODE:run}

if [ "${MODE}" = "admin" ]; then
    echo "Running in 'admin' mode - RDP enabled"

    # Create desktop shortcut to install.sh
    if [ ! -f /home/wineuser/Desktop/ssprocloud-install.sh ]; then
        echo 'xfce4-terminal -x bash -c "/usr/bin/ssprocloud-install; read -p \"Press enter to close\""' > /home/wineuser/Desktop/ssprocloud-install.sh
        chmod +x /home/wineuser/Desktop/ssprocloud-install.sh
    fi

    # Run RDP
    RDP_SERVER=yes exec /usr/bin/entrypoint
elif [ "${MODE}" = "run" ]; then
    echo "Running in 'run' mode - RDP disabled"

    # Make sure wineuser is created,
    # will throw gosa error, but we can ignore that
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
