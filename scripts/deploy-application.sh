#!/bin/bash

set -e

# deploy application
echo "deploying chess-bot"
kubectl apply -f ./deploy/k8s/charts/chess-bot.yaml
kubectl wait --for=create --timeout=90s deployment/chess-bot -n chess-bot
kubectl rollout status deployment/chess-bot -n chess-bot --timeout=90s --watch

# deploy external ingress
kubectl apply -f ./deploy/k8s/ingress/chess-bot-external-ingress.yaml

# deploy ngrok ingress
envsubst < ./deploy/k8s/ingress/chess-bot-ngrok-ingress.yaml | kubectl apply -f -
