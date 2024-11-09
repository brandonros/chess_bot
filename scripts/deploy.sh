#!/bin/bash

set -e

# build chess-bot
export TIMESTAMP=$(date +%s)
envsubst < ./deploy/k8s/jobs/kaniko-build-job.yaml | kubectl apply -f -
kubectl wait --for=condition=complete --timeout=300s job/chess-bot-kaniko-build-${TIMESTAMP} -n cicd

# deploy chess-bot
helm dependency update ./deploy/helm
helm dependency build ./deploy/helm
helm upgrade --install chess-bot ./deploy/helm \
  --namespace chess-bot \
  --create-namespace
kubectl apply -f ./deploy/k8s/ingress/chess-bot-ingress.yaml # TODO: get this done via helm?

# restart deployment to ensure new image is used
kubectl rollout restart -n chess-bot deployment chess-bot
kubectl rollout status -n chess-bot deployment chess-bot --watch
