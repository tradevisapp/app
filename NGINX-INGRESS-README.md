# NGINX Ingress Controller Setup for TradeVis

This document explains how to use NGINX Ingress Controller with TradeVis on your EC2 instance instead of port forwarding.

## Overview

The setup includes:
- NGINX Ingress Controller deployed as an ArgoCD application
- TradeVis application deployed as an ArgoCD application
- Ingress resources for both the TradeVis application and ArgoCD
- Custom configuration for EC2 environment

## ArgoCD Applications

The deployment uses two ArgoCD applications:
1. **nginx-ingress** - Manages the NGINX Ingress Controller deployment
2. **tradevis** - Manages the TradeVis application deployment

## Configuration Files

The NGINX Ingress setup uses the following configuration files:
- `argocd/nginx-ingress-application.yaml` - ArgoCD application for NGINX Ingress Controller
- `argocd/argocd-ingress.yaml` - Ingress resource for ArgoCD
- `helm-charts/tradevis/templates/ingress.yaml` - Ingress resource for the TradeVis application

## How it Works

Instead of using port forwarding, the application is now exposed through the NGINX Ingress Controller:
- The Ingress Controller listens on port 80 (HTTP) and 443 (HTTPS) on the EC2 instance
- Requests are routed to the appropriate services based on path or hostname
- The TradeVis application is available at the root path `/`
- ArgoCD is available at the `/argocd` path

## Prerequisites

- EC2 instance with proper security group rules to allow traffic on ports 80 and 443
- Kubernetes cluster running on the EC2 instance

## Security Group Configuration

Ensure your EC2 security group allows inbound traffic on:
- Port 80 (HTTP)
- Port 443 (HTTPS)

## Using a Custom Domain

If you want to use a custom domain:

1. Configure your DNS to point to the EC2 instance's public IP
2. Update the ingress.host value in the values.yaml file:
   ```yaml
   ingress:
     enabled: true
     className: nginx
     host: "yourdomain.com"  # Replace with your domain
   ```
3. Update the ingress.yaml template to use the host value

## Troubleshooting

If you encounter issues:

1. Check the status of ArgoCD applications:
   ```
   kubectl get applications -n argocd
   ```

2. Check that the NGINX Ingress Controller is running:
   ```
   kubectl get pods -n ingress-nginx
   ```

3. Check the ingress resources:
   ```
   kubectl get ingress --all-namespaces
   ```

4. Check the NGINX Ingress Controller logs:
   ```
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ``` 