#!/bin/bash

set -e

# start job
echo "starting kaniko build job"
export TIMESTAMP=$(date +%s)
envsubst < ./deploy/k8s/jobs/kaniko-build-job.yaml | kubectl apply -f -

# wait for job to complete
echo "waiting for kaniko build job to complete"
kubectl wait --for=condition=complete --timeout=300s job/chess-bot-kaniko-build-${TIMESTAMP} -n cicd
