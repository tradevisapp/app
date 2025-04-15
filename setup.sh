#!/bin/bash
set -e

DOCKERHUB_USERNAME="roeilevinson"
export DOCKERHUB_USERNAME

echo "Starting TradeVis application setup..."

# Source all component scripts
source ./scripts/update-system.sh
source ./scripts/install-docker.sh
source ./scripts/install-kubectl.sh
source ./scripts/install-helm.sh
source ./scripts/install-kind.sh
source ./scripts/setup-kind-cluster.sh
source ./scripts/install-argocd.sh
source ./scripts/install-nginx-ingress.sh
source ./scripts/configure-argocd.sh

# Deploy the application with Helm
echo "Deploying application with Helm..."
helm install tradevis ./charts/app --namespace app \
  --set auth0.domain="$AUTH0_DOMAIN" \
  --set auth0.audience="$AUTH0_AUDIENCE" \
  --set auth0.clientSecret="$AUTH0_CLIENT_SECRET"

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://tradevis.click"
echo "You can access ArgoCD at http://argocd.tradevis.click"
echo "You can check the application sync status with: kubectl get applications -n argocd" 