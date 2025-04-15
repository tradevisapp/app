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

# Check for Auth0 client secret
if [ -z "$AUTH0_CLIENT_SECRET" ]; then
  echo "AUTH0_CLIENT_SECRET environment variable is not set."
  echo "You will be prompted to enter it when creating the Auth0 secret."
fi

# Create Auth0 secret
echo "Creating Auth0 credentials secret..."
source ./scripts/create-auth0-secret.sh

# Build and push Docker images (frontend and backend)
echo "Building and pushing Docker images..."
cd ../frontend
docker build -t ${DOCKERHUB_USERNAME}/tradevis-frontend:latest .
docker push ${DOCKERHUB_USERNAME}/tradevis-frontend:latest

cd ../backend
docker build -t ${DOCKERHUB_USERNAME}/tradevis-backend:latest .
docker push ${DOCKERHUB_USERNAME}/tradevis-backend:latest

cd ../app

# Deploy the application with Helm
echo "Deploying application with Helm..."
helm upgrade --install tradevis ./charts/app --namespace app

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://tradevis.click"
echo "You can access ArgoCD at http://argocd.tradevis.click"
echo "You can check the application sync status with: kubectl get applications -n argocd" 