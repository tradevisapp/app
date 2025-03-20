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

# Install Helm
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
echo "Helm installed successfully"

# Install Kind
echo "Installing Kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "Kind installed successfully"

# Create Kind cluster
echo "Creating Kind cluster..."
sudo kind create cluster --name tradevis-cluster --config kind-config.yaml

# Set kubectl context to use the Kind cluster
echo "Setting kubectl context to use the Kind cluster..."
sudo kubectl config use-context kind-tradevis-cluster

# Verify cluster is running
sudo kubectl cluster-info --context kind-tradevis-cluster
echo "Kind cluster created successfully"

# Install ArgoCD
echo "Installing ArgoCD..."
# Create namespace
sudo kubectl create namespace argocd
# Create app namespace
sudo kubectl create namespace app
# Install ArgoCD components - fixed command to ensure proper installation
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Give ArgoCD time to start up before checking its status
echo "Waiting for ArgoCD to start (60 seconds)..."
sleep 60

# Verify ArgoCD components are running
echo "Verifying ArgoCD installation..."
sudo kubectl get pods -n argocd

# Install Nginx Ingress Controller (lightweight approach)
echo "Installing Nginx Ingress Controller..."
# Apply the Nginx Ingress Controller manifests specifically for Kind
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for Nginx ingress controller to be ready
echo "Waiting for Nginx Ingress Controller to be ready..."
sudo kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Configure ArgoCD
echo "Configuring ArgoCD..."
sudo kubectl apply -f argocd/argocd-install.yaml
sudo kubectl apply -f argocd/argocd-application.yaml

# Apply ArgoCD ConfigMap to disable HTTPS
echo "Configuring ArgoCD to use HTTP..."
sudo kubectl apply -f argocd/argocd-cm.yaml
sudo kubectl -n argocd rollout restart deployment argocd-server

# Wait for ArgoCD server to restart
echo "Waiting for ArgoCD server to restart..."
sleep 10

# Apply ArgoCD Ingress
echo "Configuring ArgoCD Ingress..."
sudo kubectl apply -f argocd/argocd-ingress.yaml

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"

# Install argocd CLI
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Login to ArgoCD and update admin password
#echo "Updating ArgoCD admin password to 'adminadmin'..."
#argocd login localhost:8080 --username admin --password $ARGO_PASSWORD --insecure

# Update the password to 'adminadmin' (need minimum 8 characters for ArgoCD password)
#echo "Setting new admin password..."
#argocd account update-password --current-password $ARGO_PASSWORD --new-password adminadmin

echo "ArgoCD password has been reset to 'adminadmin'"
echo "ArgoCD is now available through Nginx Ingress at http://localhost/argocd"
echo "Username: admin"
echo "Password: adminadmin"


echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://localhost"
echo "You can access ArgoCD at http://localhost/argocd"
echo "You can check the application sync status with: kubectl get applications -n argocd"
