#!/bin/bash

set -e

# start job
echo "starting kaniko build job"
export TIMESTAMP=$(date +%s)
export JOB_NAME="kaniko-build-${TIMESTAMP}"
export IMAGE_DESTINATION="docker-registry.docker-registry.svc.cluster.local:5000/chess-bot:latest"
export PVC_NAME="local-path-pvc"
export DOCKERFILE="./Dockerfile"
export CONTEXT="/workspace"
envsubst < ./deploy/kustomize/cicd/build-job-template.yaml | kubectl apply -f -

# wait for job to complete
echo "waiting for kaniko build job to complete"
kubectl wait --for=condition=complete --timeout=300s job/${JOB_NAME} -n cicd
