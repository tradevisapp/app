# TradeVis Application

This application uses ArgoCD for GitOps-based Kubernetes deployments.

## Setup

1. Run the `run-app.sh` script to set up the environment:
   ```
   bash run-app.sh
   ```

This script will:
- Install Docker, kubectl, and Kind
- Create a Kind cluster based on the kind-config.yaml
- Install ArgoCD in the cluster
- Configure ArgoCD to watch your Git repository
- Apply the initial deployment

## Accessing the application

- **TradeVis Application**: http://localhost
- **ArgoCD UI**: https://localhost:8080
  - Username: admin
  - Password: (displayed after setup)

## How ArgoCD works with this app

ArgoCD continuously monitors the Git repository and automatically synchronizes the Kubernetes resources when changes are detected. The deployment process is:

1. Make changes to Kubernetes manifests in the `kubernetes/` directory
2. Commit and push to your Git repository
3. ArgoCD detects the changes and applies them to the cluster

## Manual sync

If you need to trigger a manual sync:

```
kubectl argo cd app sync tradevis-app -n argocd
```

## Viewing Application Status

```
kubectl get applications -n argocd
```

Or use the ArgoCD UI at https://localhost:8080

## Troubleshooting

If ArgoCD is not syncing properly, check:
1. ArgoCD pod status: `kubectl get pods -n argocd`
2. Application status: `kubectl describe application tradevis-app -n argocd`
3. ArgoCD logs: `kubectl logs deployment/argocd-application-controller -n argocd` 