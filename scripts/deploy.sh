
# deploy chess-bot
helm dependency update ./deploy/helm
helm dependency build ./deploy/helm
helm upgrade --install chess-bot ./deploy/helm \
  --namespace chess-bot \
  --create-namespace
kubectl apply -f ./deploy/k8s/ingress/chess-bot-ingress.yaml # TODO: get this done via helm?

# restart deployment to ensure new image is used
kubectl rollout restart -n chess-bot deployment chess-bot
kubectl rollout status -n chess-bot deployment chess-bot --watch
