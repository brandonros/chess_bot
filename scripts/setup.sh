#!/bin/bash

set -e

# dependencies
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo add twuni https://helm.twun.io --force-update
helm repo add hull https://vidispine.github.io/hull --force-update

# cert-manager
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.1 \
  --set crds.enabled=true
kubectl create secret tls \
  --namespace cert-manager \
  k3s-server-ca-secret \
  --cert=/Users/brandon/.lima/k3s/copied-from-guest/server-ca.crt \
  --key=/Users/brandon/.lima/k3s/copied-from-guest/server-ca.key || true
kubectl apply -f ./deploy/k8s/certs/cluster-issuer.yaml

# docker-registry
helm upgrade --install \
  docker-registry twuni/docker-registry \
  --namespace docker-registry \
  --create-namespace

# storage
kubectl apply -f ./deploy/k8s/storage/volumes.yaml
