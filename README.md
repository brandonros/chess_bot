# chess_bot

Rust chess bot HTTP API

## How to deploy

```shell
# dependencies
brew install kubectl lima helm

# lima
limactl start ./assets/k3s.yaml
export KUBECONFIG="/Users/brandon/.lima/k3s/copied-from-guest/kubeconfig.yaml"

# trust
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /Users/brandon/.lima/k3s/copied-from-guest/server-ca.crt

# cert manager
helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
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
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: k3s-server-ca-issuer
spec:
  ca:
    secretName: k3s-server-ca-secret
EOF

# kubernetes dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ --force-update
helm upgrade \
  --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace

# service account
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
# kubectl -n kubernetes-dashboard create token admin-user
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

# ingress + certificate
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kubernetes-dashboard-tls
  namespace: kubernetes-dashboard
spec:
  dnsNames:
    - kubernetes-dashboard.k3s.cluster.local
  secretName: kubernetes-dashboard-tls
  issuerRef:
    name: k3s-server-ca-issuer
    kind: ClusterIssuer
---
apiVersion: traefik.io/v1alpha1
kind: ServersTransport
metadata:
  name: kubernetes-dashboard-transport
  namespace: kubernetes-dashboard
spec:
  insecureSkipVerify: true
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: kubernetes-dashboard-ingress-route
  namespace: kubernetes-dashboard
spec:
  entryPoints:
    - websecure
  tls:
    secretName: kubernetes-dashboard-tls
  routes:
    - kind: Rule
      match: Host("kubernetes-dashboard.k3s.cluster.local")
      services:
        - kind: Service
          port: 443
          name: kubernetes-dashboard-kong-proxy
          namespace: kubernetes-dashboard
          serversTransport: kubernetes-dashboard-transport
EOF

# edit hosts
127.0.0.1 kubernetes-dashboard.k3s.cluster.local

# port forward
kubectl -n kube-system port-forward svc/traefik 8443:443

# get token
TOKEN=$(kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 --decode)
echo $TOKEN

# open
open https://kubernetes-dashboard.k3s.cluster.local:8443
```
