#!/bin/bash

printers=$(lpstat -v | sed 's/://' |  awk '{print $3}')

if [[ -n $printers ]]; then
    /bin/echo "Printers found..."

    for printer in $printers; do
        lpadmin -p "$printer" -o printer-is-shared=False
        /bin/echo "Disabled printer sharing for $printer."
    done

    /bin/echo "Restarting CUPS service..."
    launchctl stop org.cups.cupsd
    launchctl start org.cups.cupsd
    /bin/echo "Done"
else
    /bin/echo "No printers found, exiting..."
fi

exit 0
