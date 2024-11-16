#!/bin/bash

set -e

# provision VM
echo "provisioning VM"
limactl start --tty=false --name debian-k3s ./deploy/vm/debian-k3s.yaml

# trust k3s-generated CA
echo "trusting k3s-generated CA"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /Users/brandon/.lima/debian-k3s/copied-from-guest/server-ca.crt

# append exposed external services from ingress to /etc/hosts if not already present
HOSTS_ENTRY="127.0.0.1 chess-bot.debian-k3s grafana.debian-k3s docker-registry.debian-k3s tempo.debian-k3s prometheus.debian-k3s"
if ! grep -qF "$HOSTS_ENTRY" /etc/hosts; then
    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
fi
