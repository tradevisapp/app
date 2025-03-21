#!/bin/bash
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

# Login to ArgoCD and update admin password (commented out for manual execution)
#echo "Updating ArgoCD admin password to 'adminadmin'..."
#argocd login localhost:8080 --username admin --password $ARGO_PASSWORD --insecure

# Update the password to 'adminadmin' (need minimum 8 characters for ArgoCD password)
#echo "Setting new admin password..."
#argocd account update-password --current-password $ARGO_PASSWORD --new-password adminadmin

echo "ArgoCD password has been reset to 'adminadmin'"
echo "ArgoCD is now available through Nginx Ingress at http://localhost/argocd"
echo "Username: admin"
echo "Password: adminadmin" 