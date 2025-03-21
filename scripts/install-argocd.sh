#!/bin/bash
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
sleep 20

# Verify ArgoCD components are running
echo "Verifying ArgoCD installation..."
sudo kubectl get pods -n argocd

# Install argocd CLI
echo "Installing ArgoCD CLI..."
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd 