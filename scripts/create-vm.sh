#!/bin/bash

set -e

# provision VM
echo "provisioning VM"
limactl start --name debian-k3s ./deploy/vm/debian-k3s.yaml

# trust k3s-generated CA
echo "trusting k3s-generated CA"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /Users/brandon/.lima/debian-k3s/copied-from-guest/server-ca.crt
