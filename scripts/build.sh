#!/bin/bash

set -e

# start job
echo "starting kaniko build job"
export TIMESTAMP=$(date +%s)
export IMAGE_DESTINATION="docker-registry.docker-registry.svc.cluster.local:5000/chess-bot:latest"
export PVC_NAME="local-path-pvc"
envsubst < ./deploy/k8s/jobs/kaniko-build-job.yaml | kubectl apply -f -

# wait for job to complete
echo "waiting for kaniko build job to complete"
kubectl wait --for=condition=complete --timeout=300s job/kaniko-build-${TIMESTAMP} -n cicd
