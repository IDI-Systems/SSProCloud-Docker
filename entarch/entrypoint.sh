#!/bin/bash

# Create desktop shortcut to install.sh
if [ ! -f /home/wineuser/Desktop/entarch-install.sh ]; then
    # Create Desktop folder as it won't be created until RDP server runs
    mkdir -p /home/wineuser/Desktop

    echo 'xfce4-terminal -x bash -c "/usr/bin/entarch-install; read -p \"Press enter to close\""' > /home/wineuser/Desktop/entarch-install.sh
    chmod +x /home/wineuser/Desktop/entarch-install.sh
fi

# Run RDP
RDP_SERVER=yes exec /usr/bin/entrypoint
