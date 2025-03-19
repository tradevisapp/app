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
# Create namespace
sudo kubectl create namespace argocd
# Install ArgoCD components - fixed command to ensure proper installation
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Give ArgoCD time to start up before checking its status
echo "Waiting for ArgoCD to start (60 seconds)..."
sleep 60

# Verify ArgoCD components are running
echo "Verifying ArgoCD installation..."
sudo kubectl get pods -n argocd

# Configure ArgoCD
echo "Configuring ArgoCD..."
sudo kubectl apply -f argocd/argocd-install.yaml
sudo kubectl apply -f argocd/argocd-application.yaml

# Set up port forwarding for ArgoCD UI
echo "Setting up port forwarding for ArgoCD UI..."
nohup sudo kubectl port-forward svc/argocd-server -n argocd 8080:80 --address 0.0.0.0 > $HOME/argocd-port-forward.log 2>&1 &

# Add additional port forwarding for ArgoCD to application-controller
echo "Setting up additional port forwarding for ArgoCD controller..."
nohup sudo kubectl port-forward deployment/argocd-application-controller -n argocd 8090:8080 --address 0.0.0.0 > $HOME/argocd-controller-forward.log 2>&1 &

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD is available at http://localhost:8080"
echo "Username: admin"
echo "Password: $ARGO_PASSWORD"

# Apply initial Kubernetes resources to bootstrap
echo "Applying initial Kubernetes resources..."
sudo kubectl apply -f kube-app/deployment.yaml

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
sudo kubectl wait --for=condition=available --timeout=300s deployment/tradevis-frontend

# Set up port forwarding for the frontend service
echo "Setting up port forwarding for the application..."
nohup sudo kubectl port-forward svc/tradevis-frontend 80:80 --address 0.0.0.0 > $HOME/port-forward.log 2>&1 &

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://localhost or http://$(curl -s ifconfig.me)"
echo "You can access ArgoCD at http://localhost:8080"
echo "ArgoCD controller metrics are available at http://localhost:8090/metrics"


