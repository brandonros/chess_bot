#!/bin/bash

set -e

# metrics-server
echo "deploying metrics-server"
kubectl apply -f ./deploy/k8s/charts/metrics-server.yaml
kubectl wait --for=create --timeout=90s deployment/metrics-server -n kube-system
kubectl rollout status deployment/metrics-server -n kube-system --timeout=90s --watch

# cert-manager
echo "deploying cert-manager"
kubectl apply -f ./deploy/k8s/charts/cert-manager.yaml
kubectl wait --for=create --timeout=90s deployment/cert-manager -n cert-manager
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=90s --watch
kubectl wait --for=condition=available --timeout=90s deployment/cert-manager-webhook -n cert-manager
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=90s --watch

# cert-manager cluster-issuer
echo "creating cluster-issuer"
export BASE64_ENCODED_CERT_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.crt | base64)
export BASE64_ENCODED_KEY_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.key | base64)
envsubst < ./deploy/k8s/certs/cluster-issuer.yaml | kubectl apply -f -

# traefik
echo "deploying traefik"
kubectl apply -f ./deploy/k8s/charts/traefik.yaml
kubectl wait --for=create --timeout=90s deployment/traefik -n traefik
kubectl rollout status deployment/traefik -n traefik --timeout=90s --watch

# gateway-tls
echo "deploying gateway-tls"
kubectl apply -f ./deploy/k8s/certs/gateway-tls.yaml
kubectl wait --for=create --timeout=90s certificate/gateway-tls -n traefik

# gateway
echo "deploying gateway"
kubectl apply -f ./deploy/k8s/gateways/gateway.yaml

# docker-registry
echo "deploying docker-registry"
kubectl apply -f ./deploy/k8s/charts/docker-registry.yaml
kubectl wait --for=create --timeout=90s deployment/docker-registry -n docker-registry
kubectl rollout status deployment/docker-registry -n docker-registry --timeout=90s --watch

# docker-registry route
echo "deploying docker-registry route"
export SERVICE_NAME="docker-registry"
export NAMESPACE="docker-registry"
export HOSTNAME="docker-registry.debian-k3s"
export PORT="5000"
export NAME="docker-registry"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# storage
echo "deploying storage"
export HOST_PATH="/mnt/chess_bot"
envsubst < ./deploy/k8s/storage/local-path-pvc.yaml | kubectl apply -f -

# dns
echo "reconfiguring coredns"
export TRAEFIK_IP=$(kubectl -n traefik get svc traefik -o jsonpath='{.spec.clusterIP}')
envsubst < deploy/k8s/dns/coredns-config.yaml | kubectl apply -f -

# kube-prometheus-stack
echo "deploying kube-prometheus-stack"
kubectl apply -f ./deploy/k8s/charts/kube-prometheus-stack.yaml
kubectl wait --for=create --timeout=90s deployment/kube-prometheus-stack-grafana -n monitoring
kubectl rollout status deployment/kube-prometheus-stack-grafana -n monitoring --timeout=180s --watch

# grafana route
echo "deploying grafana route"
export SERVICE_NAME="grafana"
export NAMESPACE="monitoring"
export HOSTNAME="grafana.debian-k3s"
export PORT="80"
export NAME="kube-prometheus-stack-grafana"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# loki-stack
echo "deploying loki-stack"
kubectl apply -f ./deploy/k8s/charts/loki-stack.yaml
kubectl wait --for=create --timeout=90s statefulset/loki-stack -n monitoring
kubectl rollout status statefulset/loki-stack -n monitoring --timeout=90s --watch

# tempo
echo "deploying tempo"
kubectl apply -f ./deploy/k8s/charts/tempo.yaml
kubectl wait --for=create --timeout=90s statefulset/tempo -n monitoring
kubectl rollout status statefulset/tempo -n monitoring --timeout=90s --watch

# tempo route
echo "deploying tempo route"
export SERVICE_NAME="tempo"
export NAMESPACE="monitoring"
export HOSTNAME="tempo.debian-k3s"
export PORT="4318"
export NAME="tempo"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# ngrok
echo "deploying ngrok"
envsubst < ./deploy/k8s/charts/ngrok-operator.yaml | kubectl apply -f -
kubectl wait --for=create --timeout=90s deployment/ngrok-operator-manager -n ngrok
kubectl rollout status deployment/ngrok-operator-manager -n ngrok --timeout=90s --watch
