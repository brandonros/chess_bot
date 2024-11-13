# chess_bot

Rust JSON HTTP API over chess move scoring engine

## Technologies used

- Lima (Apple Virtualization framework, Ubuntu GNU/Linux virtual machine)
- K3s (Kubernetes cluster, workload orchestration)
- Traefik (ingress, SSL, load balancing, routing)
- cert-manager (automated certificate management)
- docker-registry (stores and serves container images)
- Kaniko (builds container images)
- Helm (deployment package manager / YAML templating engine)
- Rust (JSON HTTP server)

## How to use

```shell
# dependencies
brew install kubectl lima helm

# configure kubectl
export KUBECONFIG="/Users/brandon/.lima/debian-k3s/copied-from-guest/kubeconfig.yaml"

# create VM
./scripts/create-vm.sh

# deploy infrastructure
./scripts/deploy-infrastructure.sh

# build application
./scripts/build-application.sh

# deploy application
./scripts/deploy-application.sh

# append exposed external services from ingress to /etc/hosts
echo "127.0.0.1 chess-bot.debian-k3s grafana.debian-k3s docker-registry.debian-k3s tempo.debian-k3s prometheus.debian-k3s linkerd-viz.debian-k3s" | sudo tee -a /etc/hosts

# get best move
curl --verbose -X POST -H 'Content-Type: application/json' https://chess-bot.debian-k3s/move/best -d '{
  "engine": "rustic",
  "depth": 6,
  "fen": "rnbqkbnr/pp1pppp1/8/2p4p/4P3/2P5/PP1P1PPP/RNBQKBNR w KQkq h6 0 3"
}'
```
