#!/bin/bash
# Configure ArgoCD

echo "Configuring ArgoCD..."
# Apply ArgoCD Command Parameters ConfigMap
echo "Applying ArgoCD Command Parameters ConfigMap..."
sudo kubectl apply -f argocd/argocd-cm.yaml

# Apply main ArgoCD ConfigMap with URL settings
echo "Applying main ArgoCD ConfigMap with URL settings..."
sudo kubectl apply -f argocd/argocd-main-cm.yaml

# Apply ArgoCD Application
echo "Applying ArgoCD Application..."
sudo kubectl apply -f argocd/argocd-application.yaml

# Apply ArgoCD Ingress
echo "Configuring ArgoCD Ingress with HTTP only..."
sudo kubectl apply -f argocd/argocd-ingress.yaml

# Restart ArgoCD server to apply changes
echo "Restarting ArgoCD server to apply changes..."
sudo kubectl -n argocd rollout restart deployment argocd-server
echo "Waiting for ArgoCD server to be ready..."
sudo kubectl -n argocd rollout status deployment argocd-server --timeout=180s

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"
echo "Try logging in with username: admin and the password shown above"
echo "Access ArgoCD at http://argocd.tradevis.click"
echo ""
echo "If you have issues logging in:"
echo "1. Try using an incognito window"
echo "2. Clear your browser cache"
echo "3. Make sure you're using http:// not https:// in the URL"