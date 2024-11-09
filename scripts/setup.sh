#!/bin/bash

set -e

# traefik
kubectl apply -f ./deploy/helm/traefik.yaml
kubectl rollout status deployment/traefik -n kube-system --timeout=90s --watch

# cert-manager
kubectl apply -f ./deploy/helm/cert-manager.yaml
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=90s --watch

# cluster-issuer
export BASE64_ENCODED_CERT_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.crt | base64)
export BASE64_ENCODED_KEY_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.key | base64)
envsubst < ./deploy/helm/cluster-issuer.yaml | kubectl apply -f -

# docker-registry
kubectl apply -f ./deploy/helm/docker-registry.yaml
kubectl rollout status deployment/docker-registry -n docker-registry --timeout=90s --watch

# cicd
kubectl apply -f ./deploy/helm/cicd.yaml
