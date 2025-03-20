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
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"

# Install argocd CLI
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Login to ArgoCD and update admin password
echo "Updating ArgoCD admin password to 'adminadmin'..."
argocd login localhost:8080 --username admin --password $ARGO_PASSWORD --insecure

# Update the password to 'adminadmin' (need minimum 8 characters for ArgoCD password)
echo "Setting new admin password..."
argocd account update-password --current-password $ARGO_PASSWORD --new-password adminadmin

echo "ArgoCD password has been reset to 'adminadmin'"
echo "ArgoCD is available at http://localhost:8080"
echo "Username: admin"
echo "Password: adminadmin"

# Wait for ArgoCD to synchronize the application
echo "Waiting for ArgoCD to synchronize the application (this may take a minute)..."
sleep 30

# Check if ArgoCD Image Updater should be installed
read -p "Do you want to install ArgoCD Image Updater to automatically detect new Docker images? (y/n): " install_updater
if [[ $install_updater == "y" || $install_updater == "Y" ]]; then
  echo "Installing ArgoCD Image Updater..."
  # Create ArgoCD Image Updater namespace
  sudo kubectl create namespace argocd-image-updater
  
  # Install ArgoCD Image Updater
  sudo kubectl apply -n argocd-image-updater -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
  
  # Wait for ArgoCD Image Updater to start
  echo "Waiting for ArgoCD Image Updater to start (30 seconds)..."
  sleep 30
  
  # Verify ArgoCD Image Updater components are running
  echo "Verifying ArgoCD Image Updater installation..."
  sudo kubectl get pods -n argocd-image-updater
  
  # Add annotations to the ArgoCD application for image updates
  echo "Adding image update annotations to ArgoCD application..."
  sudo kubectl patch application tradevis-app -n argocd -p '{
    "metadata": {
      "annotations": {
        "argocd-image-updater.argoproj.io/image-list": "roeilevinson/tradevis-frontend:latest",
        "argocd-image-updater.argoproj.io/tradevis-frontend.update-strategy": "latest"
      }
    }
  }' --type merge
  
  echo "ArgoCD Image Updater installed successfully!"
  echo "It will automatically check for new images with the 'latest' tag."
fi

# Set up port forwarding for the frontend service
echo "Waiting for tradevis-frontend service to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if sudo kubectl get svc tradevis-frontend -n app &>/dev/null; then
    echo "Service tradevis-frontend found in namespace app."
    break
  fi
  echo "Service not ready yet, waiting... ($RETRY_COUNT/$MAX_RETRIES)"
  RETRY_COUNT=$((RETRY_COUNT+1))
  sleep 10
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "WARNING: Service tradevis-frontend not found after maximum retries. Port forwarding may fail."
  echo "You can manually set up port forwarding later with:"
  echo "sudo kubectl port-forward svc/tradevis-frontend -n app 8081:80 --address 0.0.0.0"
fi

echo "Setting up port forwarding for the application..."
nohup sudo kubectl port-forward svc/tradevis-frontend -n app 8081:80 --address 0.0.0.0 > $HOME/port-forward.log 2>&1 &

# Check if port forwarding was successful
sleep 5
if ps aux | grep "[p]ort-forward.*tradevis-frontend" > /dev/null; then
  echo "Port forwarding for tradevis-frontend set up successfully."
else
  echo "WARNING: Port forwarding for tradevis-frontend might have failed."
  echo "Check logs at $HOME/port-forward.log for details."
  echo "You can manually set up port forwarding with:"
  echo "sudo kubectl port-forward svc/tradevis-frontend -n app 8081:80 --address 0.0.0.0"
fi

echo "TradeVis application setup completed successfully with ArgoCD!"
echo "You can access the application at http://localhost:8081"
echo "You can access ArgoCD at http://localhost:8080"
echo "ArgoCD controller metrics are available at http://localhost:8090/metrics"
echo "You can check the application sync status with: kubectl get applications -n argocd"

# Add instructions for manual Helm usage
echo "
=== Helm Chart Manual Usage ===
You can also manage the application directly with Helm:

# To install the chart locally (outside of ArgoCD):
helm install tradevis ./helm-charts/tradevis

# To upgrade the deployment with a new image tag:
helm upgrade tradevis ./helm-charts/tradevis --set image.tag=v1.0.1

# To force a refresh of the latest image:
kubectl rollout restart deployment tradevis-frontend -n app

# To view the Helm release status:
helm list
"


