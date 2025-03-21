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

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://localhost"
echo "You can access ArgoCD at http://localhost/argocd"
echo "You can check the application sync status with: kubectl get applications -n argocd" 