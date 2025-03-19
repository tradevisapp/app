#!/bin/bash
set -e

DOCKERHUB_USERNAME="roeilevinson"
export DOCKERHUB_USERNAME

echo "Starting TradeVis application setup..."

# Update system packages
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add current user to docker group
sudo usermod -aG docker $USER
echo "Docker installed successfully"

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "kubectl installed successfully"

# Install Kind
echo "Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "Kind installed successfully"

# Create Kind cluster
echo "Creating Kind cluster..."
sudo kind create cluster --name tradevis-cluster --config kind-config.yaml

# Verify cluster is running
sudo kubectl cluster-info --context kind-tradevis-cluster
echo "Kind cluster created successfully"

# Install ArgoCD
echo "Installing ArgoCD..."
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
sudo kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
sudo kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
sudo kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd

# Configure ArgoCD
echo "Configuring ArgoCD..."
sudo kubectl apply -f kubernetes/argocd-install.yaml
sudo kubectl apply -f kubernetes/argocd-application.yaml

# Set up port forwarding for ArgoCD UI
echo "Setting up port forwarding for ArgoCD UI..."
nohup sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 > /tmp/argocd-port-forward.log 2>&1 &

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD is available at https://localhost:8080"
echo "Username: admin"
echo "Password: $ARGO_PASSWORD"

# Apply initial Kubernetes resources to bootstrap
echo "Applying initial Kubernetes resources..."
sudo kubectl apply -f kubernetes/deployment.yaml

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://localhost or http://$(curl -s ifconfig.me)"
echo "You can access ArgoCD at https://localhost:8080"


