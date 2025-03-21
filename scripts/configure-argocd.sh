#!/bin/bash
# Configure ArgoCD

echo "Configuring ArgoCD..."
sudo kubectl apply -f argocd/argocd-install.yaml
#sudo kubectl apply -f argocd/argocd-application.yaml

# Apply ArgoCD ConfigMap to disable HTTPS
echo "Configuring ArgoCD to use HTTP..."
sudo kubectl apply -f argocd/argocd-cm.yaml
sudo kubectl -n argocd rollout restart deployment argocd-server

# Wait for ArgoCD server to restart
echo "Waiting for ArgoCD server to restart..."
sleep 30

# Apply ArgoCD Ingress
echo "Configuring ArgoCD Ingress with HTTP only..."
sudo kubectl apply -f argocd/argocd-ingress.yaml

# Get ArgoCD initial admin password
ARGO_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD initial admin password is: $ARGO_PASSWORD"

# Login to ArgoCD and update admin password (commented out for manual execution)
#echo "Updating ArgoCD admin password to 'adminadmin'..."
#argocd login argocd.tradevis.click --username admin --password $ARGO_PASSWORD --insecure

# Update the password to 'adminadmin' (need minimum 8 characters for ArgoCD password)
#echo "Setting new admin password..."
#argocd account update-password --current-password $ARGO_PASSWORD --new-password adminadmin

echo "ArgoCD password has been retrieved"
echo "ArgoCD is now available through Nginx Ingress at http://argocd.tradevis.click"
echo "Username: admin"
echo "Password: Use the password shown above"
