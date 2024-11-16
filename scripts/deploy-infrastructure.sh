#!/bin/bash

set -e

# copy certs
mkdir -p ./deploy/kustomize/cert-manager/certs
cp ~/.lima/debian-k3s/copied-from-guest/server-ca.crt ./deploy/kustomize/cert-manager/certs/server-ca.crt
cp ~/.lima/debian-k3s/copied-from-guest/server-ca.key ./deploy/kustomize/cert-manager/certs/server-ca.key

# cicd template
export HOST_PATH="/mnt/chess_bot"
envsubst < ./deploy/kustomize/cicd/pvc-template.yaml > ./deploy/kustomize/cicd/pvc.yaml

# ngrok template
export NGROK_API_KEY=${NGROK_API_KEY}
export NGROK_AUTH_TOKEN=${NGROK_AUTH_TOKEN}
envsubst < ./deploy/kustomize/ngrok/chart-template.yaml > ./deploy/kustomize/ngrok/chart.yaml

# metrics-server
echo "deploying metrics-server"
kubectl apply -k ./deploy/kustomize/metrics-server
kubectl wait --for=create --timeout=90s deployment/metrics-server -n kube-system
kubectl rollout status deployment/metrics-server -n kube-system --timeout=90s --watch

# cert-manager
echo "deploying cert-manager"
kubectl apply -k ./deploy/kustomize/cert-manager
kubectl wait --for=create --timeout=90s deployment/cert-manager -n cert-manager
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=90s --watch
kubectl wait --for=condition=available --timeout=90s deployment/cert-manager-webhook -n cert-manager
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=90s --watch

# trust-manager
echo "deploying trust-manager"
kubectl apply -k ./deploy/kustomize/trust-manager
kubectl wait --for=create --timeout=90s deployment/trust-manager -n trust-manager
kubectl rollout status deployment/trust-manager -n trust-manager --timeout=90s --watch

# two versions of gateway-api because linkerd needs old v1beta and traefik needs new v1
if kubectl get crd gatewayclasses.gateway.networking.k8s.io -o json | jq -e '.status.storedVersions | contains(["v1beta1"])' >/dev/null; then
    echo "GatewayClass v1beta1 CRD is installed"
else
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.1/experimental-install.yaml
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.1/experimental-install.yaml
    sleep 10 # allow rollout
    # TODO: kubectl -n <namespace-here> wait --for condition=established --timeout=60s crd/<crd-name-here>
fi

# kube-prometheus-stack (linkerd needs crd from prometheus-operator)
echo "deploying kube-prometheus-stack"
kubectl apply -k ./deploy/kustomize/monitoring

# grafana
kubectl wait --for=create --timeout=90s deployment/kube-prometheus-stack-grafana -n monitoring
kubectl rollout status deployment/kube-prometheus-stack-grafana -n monitoring --timeout=180s --watch

# loki-stack
kubectl wait --for=create --timeout=90s statefulset/loki-stack -n monitoring
kubectl rollout status statefulset/loki-stack -n monitoring --timeout=90s --watch

# tempo
kubectl wait --for=create --timeout=90s statefulset/tempo -n monitoring
kubectl rollout status statefulset/tempo -n monitoring --timeout=90s --watch

# linkerd
echo "deploying linkerd-crds"
kubectl apply -k ./deploy/kustomize/linkerd
# TODO: kubectl -n <namespace-here> wait --for condition=established --timeout=60s crd/<crd-name-here>

# linkerd-control-plane
kubectl wait --for=create --timeout=90s deployment/linkerd-destination -n linkerd
kubectl rollout status deployment/linkerd-destination -n linkerd --timeout=90s --watch

# linkerd-viz
kubectl wait --for=create --timeout=90s deployment/web -n linkerd
kubectl rollout status deployment/web -n linkerd --timeout=90s --watch

# traefik
echo "deploying traefik"
kubectl apply -k ./deploy/kustomize/traefik
kubectl wait --for=create --timeout=90s deployment/traefik -n traefik
kubectl rollout status deployment/traefik -n traefik --timeout=90s --watch

# docker-registry
echo "deploying docker-registry"
kubectl apply -k ./deploy/kustomize/docker-registry
kubectl wait --for=create --timeout=90s deployment/docker-registry -n docker-registry
kubectl rollout status deployment/docker-registry -n docker-registry --timeout=90s --watch

# cicd
echo "deploying cicd"
kubectl apply -k ./deploy/kustomize/cicd
# TODO: wait for something?

# ngrok
echo "deploying ngrok"
kubectl apply -k ./deploy/kustomize/ngrok
kubectl wait --for=create --timeout=90s deployment/ngrok-operator-manager -n ngrok
kubectl rollout status deployment/ngrok-operator-manager -n ngrok --timeout=90s --watch
