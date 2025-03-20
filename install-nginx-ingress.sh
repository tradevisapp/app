#!/bin/bash
set -e

echo "Installing NGINX Ingress Controller..."

# Add the NGINX Helm repository
sudo helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
sudo helm repo update

# Install NGINX Ingress Controller
sudo helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

# Wait for the NGINX Ingress Controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
sudo kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get the node IP
NODE_IP=$(sudo kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "NGINX Ingress Controller has been installed successfully!"
echo "You can access your application at http://$NODE_IP:30080"
echo "To use with a custom domain, update your DNS to point to the EC2 instance IP" 