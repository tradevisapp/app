#!/bin/bash
# Configure ArgoCD

echo "Configuring ArgoCD..."
# Apply ArgoCD ConfigMap
echo "Applying ArgoCD ConfigMap..."
sudo kubectl apply -f argocd/argocd-cm.yaml

# Apply ArgoCD Application
echo "Applying ArgoCD Application..."
sudo kubectl apply -f argocd/argocd-application.yaml

# Apply ArgoCD Ingress
echo "Configuring ArgoCD Ingress with HTTP only..."
sudo kubectl apply -f argocd/argocd-ingress.yaml

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"