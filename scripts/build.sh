#!/bin/bash

set -e

# build chess-bot
export TIMESTAMP=$(date +%s)
envsubst < ./deploy/k8s/jobs/kaniko-build-job.yaml | kubectl apply -f -
echo "waiting for kaniko build job to complete"
kubectl wait --for=condition=complete --timeout=300s job/chess-bot-kaniko-build-${TIMESTAMP} -n cicd
