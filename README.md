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

# setup infrastructure
./scripts/setup-infrastructure.sh

# build application
./scripts/build.sh

# deploy application
./scripts/deploy.sh

# add ingress tunneled over cluster to /etc/hosts
echo "127.0.0.1 chess-bot.node.external" | sudo tee -a /etc/hosts

# get best move
curl --verbose -X POST -H 'Content-Type: application/json' https://chess-bot.node.external/chess/best-move -d '{
  "engine": "rustic",
  "depth": 7,
  "fen": "rnbqkbnr/pp1pppp1/8/2p4p/4P3/2P5/PP1P1PPP/RNBQKBNR w KQkq h6 0 3"
}'
```
