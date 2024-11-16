#!/bin/bash

set -e

# build template
export TRAEFIK_IP=$(kubectl -n traefik get svc traefik -o jsonpath='{.spec.clusterIP}')
envsubst < deploy/kustomize/coredns/config-template.yaml > deploy/kustomize/coredns/config.yaml

# dns
echo "reconfiguring coredns"
kubectl apply -k ./deploy/kustomize/coredns
