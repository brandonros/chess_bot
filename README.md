# chess_bot

Rust chess bot via HTTP API + infrastructure exercise

## How to deploy VM

```shell
# dependencies
brew install kubectl lima helm

# lima
limactl start ./assets/k3s-vm.yaml
export KUBECONFIG="/Users/brandon/.lima/k3s/copied-from-guest/kubeconfig.yaml"

# trust
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /Users/brandon/.lima/k3s/copied-from-guest/server-ca.crt
```

## How to deploy Prometheus

```shell
# prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# service monitor
kubectl apply -f assets/traefik-service-monitor.yaml

# traefik deployment tweaks
kubectl patch deployment traefik \
  -n kube-system \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
    "--global.checknewversion",
    "--global.sendanonymoususage",
    "--entrypoints.metrics.address=:9100/tcp",
    "--entrypoints.traefik.address=:9000/tcp",
    "--entrypoints.web.address=:8000/tcp",
    "--entrypoints.websecure.address=:8443/tcp",
    "--api.dashboard=true",
    "--ping=true",
    "--metrics.prometheus=true",
    "--metrics.prometheus.entrypoint=metrics",
    "--metrics.prometheus.addEntryPointsLabels=true",
    "--metrics.prometheus.addRoutersLabels=true",
    "--metrics.prometheus.addServicesLabels=true",
    "--metrics.prometheus.headerlabels.xrequestpath=X-Replaced-Path",
    "--metrics.prometheus.headerlabels.xforwardedhost=X-Forwarded-Host",
    "--providers.kubernetescrd",
    "--providers.kubernetesingress",
    "--providers.kubernetesingress.ingressendpoint.publishedservice=kube-system/traefik",
    "--entrypoints.websecure.http.tls=true"
  ]}]'

# certificate + service + middleware + ingress route
kubectl apply -f assets/grafana-ingress.yaml

# edit hosts
127.0.0.1 grafana.k3s.cluster.local

# open (user: admin, password: prom-operator)
open https://grafana.k3s.cluster.local
```

## How to deploy cert-manager

```shell
# cert-manager
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.1 \
  --set crds.enabled=true

# insert secrets
kubectl create secret tls -n cert-manager k3s-server-ca-secret \
  --cert=/Users/brandon/.lima/k3s/copied-from-guest/server-ca.crt \
  --key=/Users/brandon/.lima/k3s/copied-from-guest/server-ca.key

# create issuer
kubectl apply -f assets/cluster-issuer.yaml
```

## How to deploy Kubernetes Dashboard

```shell
# kubernetes dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ --force-update
helm upgrade --install \
  kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace

# service account
kubectl apply -f assets/kubernetes-dashboard-service-account.yaml

# ingress + certificate
kubectl apply -f assets/kubernetes-dashboard-ingress.yaml

# edit hosts
127.0.0.1 kubernetes-dashboard.k3s.cluster.local

# get token
TOKEN=$(kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 --decode)
echo $TOKEN

# open
open https://kubernetes-dashboard.k3s.cluster.local
```

## How to deploy Docker registry

```shell
helm repo add twuni https://helm.twun.io --force-update
helm upgrade --install \
  docker-registry twuni/docker-registry \
  --namespace docker-registry \
  --create-namespace

# ingress
kubectl apply -f assets/docker-registry-ingress.yaml

# edit hosts
127.0.0.1 docker-registry.k3s.cluster.local
```

## How to build chess_bot

```shell
TIMESTAMP=$(date +%s) envsubst < assets/kaniko-build.yaml | kubectl apply -f -
```

## How to deploy chess_bot

```shell
helm repo add hull https://vidispine.github.io/hull
helm dependency update ./helm
helm dependency build ./helm
helm uninstall chess-bot -n chess-bot
helm upgrade --install chess-bot ./helm \
  --namespace chess-bot \
  --create-namespace

# ingress
kubectl apply -f assets/chess-bot-ingress.yaml

# edit hosts
127.0.0.1 chess-bot.k3s.cluster.local
```
