#!/bin/bash

set -e

limactl stop debian-k3s || true
limactl delete debian-k3s || true

CERTS=$(security find-certificate -a -c "k3s-server-ca" | grep "alis" | cut -d'"' -f4)

if [ -z "$CERTS" ]; then
    echo "No k3s-server-ca certificates found"
    exit 0
fi

for cert in $CERTS; do
    echo "Found certificate: $cert"
    echo "Deleting..."
     if sudo security delete-certificate -c "$cert"; then
        echo "Successfully deleted $cert"
    else
        echo "Failed to delete $cert"
    fi
done
