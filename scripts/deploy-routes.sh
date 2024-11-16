#!/bin/bash

set -e

# linkerd-viz route
echo "deploying linkerd-viz route"
export SERVICE_NAME="web"
export NAMESPACE="linkerd"
export HOSTNAME="linkerd-viz.debian-k3s"
export PORT="8084"
export NAME="linkerd-viz"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -

# docker-registry route
echo "deploying docker-registry route"
export SERVICE_NAME="docker-registry"
export NAMESPACE="docker-registry"
export HOSTNAME="docker-registry.debian-k3s"
export PORT="5000"
export NAME="docker-registry"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -

# grafana route
echo "deploying grafana route"
export SERVICE_NAME="kube-prometheus-stack-grafana"
export NAMESPACE="monitoring"
export HOSTNAME="grafana.debian-k3s"
export PORT="80"
export NAME="grafana"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -

# prometheus route
echo "deploying prometheus route"
export SERVICE_NAME="kube-prometheus-stack-prometheus"
export NAMESPACE="monitoring"
export HOSTNAME="prometheus.debian-k3s"
export PORT="9090"
export NAME="prometheus"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -

# tempo route
echo "deploying tempo route"
export SERVICE_NAME="tempo"
export NAMESPACE="monitoring"
export HOSTNAME="tempo.debian-k3s"
export PORT="4318"
export NAME="tempo"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -

# deploy chess-bot route
echo "deploying chess-bot route"
export SERVICE_NAME="chess-bot"
export NAMESPACE="chess-bot"
export HOSTNAME="chess-bot.debian-k3s"
export PORT="8080"
export NAME="chess-bot"
envsubst < ./deploy/kustomize/traefik/route-template.yaml | kubectl apply -f -
