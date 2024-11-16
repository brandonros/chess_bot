#!/bin/bash

set -e

# namespaces
echo "deploying namespaces"
kubectl apply -f ./deploy/k8s/namespaces/chess-bot.yaml
kubectl apply -f ./deploy/k8s/namespaces/cert-manager.yaml
kubectl apply -f ./deploy/k8s/namespaces/trust-manager.yaml
kubectl apply -f ./deploy/k8s/namespaces/ngrok.yaml
kubectl apply -f ./deploy/k8s/namespaces/monitoring.yaml
kubectl apply -f ./deploy/k8s/namespaces/cicd.yaml
kubectl apply -f ./deploy/k8s/namespaces/docker-registry.yaml
kubectl apply -f ./deploy/k8s/namespaces/linkerd.yaml
kubectl apply -f ./deploy/k8s/namespaces/traefik.yaml

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

# trust-manager
echo "deploying trust-manager"
kubectl apply -f ./deploy/k8s/charts/trust-manager.yaml
kubectl wait --for=create --timeout=90s deployment/trust-manager -n trust-manager
kubectl rollout status deployment/trust-manager -n trust-manager --timeout=90s --watch

# debian-k3s-tls secret
echo "deploying debian-k3s-tls secret"
export BASE64_ENCODED_CERT_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.crt | base64)
export BASE64_ENCODED_KEY_CONTENT=$(cat ~/.lima/debian-k3s/copied-from-guest/server-ca.key | base64)
envsubst < ./deploy/k8s/secrets/debian-k3s-tls.yaml | kubectl apply -f -

# debian-k3s-ca-issuer
echo "deploying debian-k3s-ca-issuer"
envsubst < ./deploy/k8s/ca/debian-k3s-ca-issuer.yaml | kubectl apply -f -

# traefik-gateway-tls cert
echo "creating traefik-gateway-tls"
kubectl apply -f ./deploy/k8s/certs/traefik-gateway-tls.yaml

# linkerd certs
echo "creating linkerd certs"
kubectl apply -f ./deploy/k8s/certs/linkerd-identity-issuer.yaml
kubectl apply -f ./deploy/k8s/certs/linkerd-identity-trust-roots.yaml
kubectl apply -f ./deploy/k8s/certs/linkerd-trust-anchor.yaml

# two versions of gateway-api because linkerd needs old v1beta and traefik needs new v1
if kubectl get crd gatewayclasses.gateway.networking.k8s.io -o json | jq -e '.status.storedVersions | contains(["v1beta1"])' >/dev/null; then
    echo "GatewayClass v1beta1 CRD is installed"
else
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.1/experimental-install.yaml
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.1/experimental-install.yaml
    sleep 10 # allow rollout
fi

# kube-prometheus-stack (linkerd needs crd from prometheus-operator)
echo "deploying kube-prometheus-stack"
kubectl apply -f ./deploy/k8s/charts/kube-prometheus-stack.yaml
kubectl wait --for=create --timeout=90s deployment/kube-prometheus-stack-grafana -n monitoring
kubectl rollout status deployment/kube-prometheus-stack-grafana -n monitoring --timeout=180s --watch

# linkerd-crds
echo "deploying linkerd-crds"
kubectl apply -f ./deploy/k8s/charts/linkerd-crds.yaml
kubectl wait --for=create --timeout=90s job/helm-install-linkerd-crds -n kube-system
kubectl wait --for=condition=complete --timeout=90s job/helm-install-linkerd-crds -n kube-system

# linkerd-control-plane
echo "deploying linkerd-control-plane"
kubectl apply -f ./deploy/k8s/charts/linkerd-control-plane.yaml
kubectl wait --for=create --timeout=90s deployment/linkerd-destination -n linkerd
kubectl rollout status deployment/linkerd-destination -n linkerd --timeout=90s --watch

# linkerd-viz
echo "deploying linkerd-viz"
kubectl apply -f ./deploy/k8s/charts/linkerd-viz.yaml
kubectl wait --for=create --timeout=90s deployment/web -n linkerd
kubectl rollout status deployment/web -n linkerd --timeout=90s --watch

# traefik
echo "deploying traefik"
kubectl apply -f ./deploy/k8s/charts/traefik.yaml
kubectl wait --for=create --timeout=90s deployment/traefik -n traefik
kubectl rollout status deployment/traefik -n traefik --timeout=90s --watch

# traefik-gateway
echo "deploying traefik-gateway"
kubectl apply -f ./deploy/k8s/gateways/traefik-gateway.yaml

# docker-registry
echo "deploying docker-registry"
kubectl apply -f ./deploy/k8s/charts/docker-registry.yaml
kubectl wait --for=create --timeout=90s deployment/docker-registry -n docker-registry
kubectl rollout status deployment/docker-registry -n docker-registry --timeout=90s --watch

# storage
echo "deploying storage"
export HOST_PATH="/mnt/chess_bot"
envsubst < ./deploy/k8s/storage/cicd-kaniko-local-pvc.yaml | kubectl apply -f -

# dns
echo "reconfiguring coredns"
export TRAEFIK_IP=$(kubectl -n traefik get svc traefik -o jsonpath='{.spec.clusterIP}')
envsubst < deploy/k8s/dns/coredns-config.yaml | kubectl apply -f -

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

# ngrok
echo "deploying ngrok"
envsubst < ./deploy/k8s/charts/ngrok-operator.yaml | kubectl apply -f -
kubectl wait --for=create --timeout=90s deployment/ngrok-operator-manager -n ngrok
kubectl rollout status deployment/ngrok-operator-manager -n ngrok --timeout=90s --watch

# linkerd-viz route
echo "deploying linkerd-viz route"
export SERVICE_NAME="web"
export NAMESPACE="linkerd"
export HOSTNAME="linkerd-viz.debian-k3s"
export PORT="8084"
export NAME="linkerd-viz"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# docker-registry route
echo "deploying docker-registry route"
export SERVICE_NAME="docker-registry"
export NAMESPACE="docker-registry"
export HOSTNAME="docker-registry.debian-k3s"
export PORT="5000"
export NAME="docker-registry"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# grafana route
echo "deploying grafana route"
export SERVICE_NAME="kube-prometheus-stack-grafana"
export NAMESPACE="monitoring"
export HOSTNAME="grafana.debian-k3s"
export PORT="80"
export NAME="grafana"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# prometheus route
echo "deploying prometheus route"
export SERVICE_NAME="kube-prometheus-stack-prometheus"
export NAMESPACE="monitoring"
export HOSTNAME="prometheus.debian-k3s"
export PORT="9090"
export NAME="prometheus"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -

# tempo route
echo "deploying tempo route"
export SERVICE_NAME="tempo"
export NAMESPACE="monitoring"
export HOSTNAME="tempo.debian-k3s"
export PORT="4318"
export NAME="tempo"
envsubst < ./deploy/k8s/routes/route.yaml | kubectl apply -f -
