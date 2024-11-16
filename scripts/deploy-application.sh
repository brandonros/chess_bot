#!/bin/bash

set -e

# deploy application
echo "deploying chess-bot"
export NGROK_HOST=${NGROK_HOST}
envsubst < ./deploy/kustomize/chess-bot/ngrok-ingress-template.yaml > ./deploy/kustomize/chess-bot/ngrok-ingress.yaml
kubectl apply -k ./deploy/kustomize/chess-bot
kubectl wait --for=create --timeout=90s deployment/chess-bot -n chess-bot
kubectl rollout status deployment/chess-bot -n chess-bot --timeout=90s --watch
