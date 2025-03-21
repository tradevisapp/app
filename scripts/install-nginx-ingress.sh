#!/bin/bash
# Install Nginx Ingress Controller

echo "Installing Nginx Ingress Controller..."
# Apply the Nginx Ingress Controller manifests specifically for Kind
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Nginx ingress controller to be ready
echo "Waiting for Nginx Ingress Controller to be ready..."
echo "This may take a few minutes..."
sudo kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s 