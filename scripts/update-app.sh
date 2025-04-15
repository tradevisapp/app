#!/bin/bash
set -e

# Default username or use provided
DOCKERHUB_USERNAME=${1:-"roeilevinson"}
# Default tag or use provided
TAG=${2:-"latest"}

echo "Updating TradeVis application with images from ${DOCKERHUB_USERNAME}/tradevis-*:${TAG}"

# Navigate to project directories and build/push Docker images
cd "$(dirname "$0")/../../frontend"
echo "Building and pushing frontend image..."
docker build -t ${DOCKERHUB_USERNAME}/tradevis-frontend:${TAG} .
docker push ${DOCKERHUB_USERNAME}/tradevis-frontend:${TAG}

cd ../backend
echo "Building and pushing backend image..."
docker build -t ${DOCKERHUB_USERNAME}/tradevis-backend:${TAG} .
docker push ${DOCKERHUB_USERNAME}/tradevis-backend:${TAG}

cd ../app

# Update the Helm release
echo "Updating Helm release with new images..."
helm upgrade --install tradevis ./charts/app \
  --namespace app \
  --set frontend.deployment.image.repository=${DOCKERHUB_USERNAME}/tradevis-frontend \
  --set frontend.deployment.image.tag=${TAG} \
  --set backend.deployment.image.repository=${DOCKERHUB_USERNAME}/tradevis-backend \
  --set backend.deployment.image.tag=${TAG}

echo "Application update completed successfully!"
echo "You can access the application at http://tradevis.click" 