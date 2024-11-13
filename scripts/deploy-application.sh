#!/bin/bash

set -e

# deploy application
echo "deploying chess-bot"
kubectl apply -f ./deploy/k8s/charts/chess-bot.yaml
kubectl wait --for=create --timeout=90s deployment/chess-bot -n chess-bot
kubectl rollout status deployment/chess-bot -n chess-bot --timeout=90s --watch

# deploy ngrok ingress
envsubst < ./deploy/k8s/ingress/chess-bot-ngrok-ingress.yaml | kubectl apply -f -

# deploy chess-bot route
echo "deploying chess-bot route"
export SERVICE_NAME="chess-bot"
export NAMESPACE="chess-bot"
export HOSTNAME="chess-bot.debian-k3s"
export PORT="8080"
export NAME="chess-bot"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -
