#!/bin/bash
set -e

DOCKERHUB_USERNAME="roeilevinson"
export DOCKERHUB_USERNAME

# Function to properly kill port-forwarding processes
kill_port_forward() {
  echo "Stopping port forwarding processes..."
  # Kill any processes using port 8080
  sudo kill $(sudo lsof -t -i:8080) 2>/dev/null || true
  # Give it a moment to clean up
  sleep 2
}

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

# Verify cluster is running
sudo kubectl cluster-info --context kind-tradevis-cluster
echo "Kind cluster created successfully"

# Install ArgoCD
echo "Installing ArgoCD..."
# Create namespace
sudo kubectl create namespace argocd
# Create app namespace
sudo kubectl create namespace app
# Install ArgoCD components
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Give ArgoCD time to start up before checking its status
echo "Waiting for ArgoCD to start (60 seconds)..."
sleep 60

# Verify ArgoCD components are running
echo "Verifying ArgoCD installation..."
sudo kubectl get pods -n argocd

# Apply ArgoCD Configuration
echo "Applying ArgoCD Configuration..."
sudo kubectl apply -f argocd/argocd-cm.yaml

# Configure ArgoCD
echo "Configuring ArgoCD..."
sudo kubectl apply -f argocd/argocd-install.yaml

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"

# Install argocd CLI
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Set up temporary port forwarding for ArgoCD CLI
echo "Setting up temporary port forwarding for ArgoCD CLI..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 &
PORT_FORWARD_PID=$!

# Give port forwarding time to establish
echo "Waiting for port forwarding to establish (5 seconds)..."
sleep 5

# Login to ArgoCD and update admin password
echo "Updating ArgoCD admin password to 'adminadmin'..."
argocd login localhost:8080 --username admin --password $ARGO_PASSWORD --insecure

# Update the password to 'adminadmin' (need minimum 8 characters for ArgoCD password)
echo "Setting new admin password..."
argocd account update-password --current-password $ARGO_PASSWORD --new-password adminadmin

echo "ArgoCD password has been reset to 'adminadmin'"

# Stop the temporary port forwarding
kill_port_forward

# Deploy NGINX Ingress Controller via ArgoCD
echo "Deploying NGINX Ingress Controller via ArgoCD..."
sudo kubectl apply -f argocd/nginx-ingress-application.yaml

# Deploy TradeVis application via ArgoCD
echo "Deploying TradeVis application via ArgoCD..."
sudo kubectl apply -f argocd/argocd-application.yaml

# Wait for applications to be synced
echo "Waiting for applications to be synced (60 seconds)..."
sleep 60

# Get node IP
NODE_IP=$(sudo kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Apply ArgoCD Ingress
echo "Applying ArgoCD Ingress configuration..."
sudo kubectl apply -f argocd/argocd-ingress.yaml

# Restart ArgoCD server to pick up the new configuration
echo "Restarting ArgoCD server..."
sudo kubectl -n argocd rollout restart deployment argocd-server

# Wait for ArgoCD server to restart
echo "Waiting for ArgoCD server to restart (30 seconds)..."
sleep 30

# Set up temporary port forwarding for ArgoCD CLI to force sync applications
echo "Setting up temporary port forwarding for ArgoCD CLI to sync applications..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 &
PORT_FORWARD_PID=$!

# Give port forwarding time to establish
echo "Waiting for port forwarding to establish (5 seconds)..."
sleep 5

# Force sync applications
echo "Force syncing applications..."
argocd login localhost:8080 --username admin --password adminadmin --insecure
argocd app sync tradevis-app
argocd app sync nginx-ingress

# Stop the temporary port forwarding
kill_port_forward

# Wait for everything to be set up
echo "Waiting for final setup (30 seconds)..."
sleep 30

echo "TradeVis application setup completed successfully with ArgoCD and NGINX Ingress!"
echo "You can access the application at http://$NODE_IP:30080"
echo "You can access ArgoCD at http://$NODE_IP:30080/argocd"
echo "You can check the application sync status with: kubectl get applications -n argocd"

# Make sure no port forwarding is left running at the end
kill_port_forward
