# TradeVis Helm Chart

This Helm chart deploys the TradeVis application to a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `tradevis`:

```bash
helm install tradevis ./tradevis
```

## Configuration

The following table lists the configurable parameters of the TradeVis chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `deployment.name` | Name of the deployment | `tradevis-frontend` |
| `deployment.replicas` | Number of replicas | `2` |
| `image.repository` | Image repository | `roeilevinson/tradevis-frontend` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `service.type` | Service type | `NodePort` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port | `80` |
| `service.nodePort` | Node port | `30080` |
| `namespace` | Namespace | `app` |
| `resources.limits.cpu` | CPU limits | `500m` |
| `resources.limits.memory` | Memory limits | `512Mi` |
| `resources.requests.cpu` | CPU requests | `100m` |
| `resources.requests.memory` | Memory requests | `128Mi` |

## Using the Chart with ArgoCD

The chart can be used with ArgoCD by configuring your ArgoCD Application to point to the Helm chart:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tradevis-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/tradevisapp/app.git
    targetRevision: HEAD
    path: helm-charts/tradevis
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Updating the Image

To update the application with a new Docker image while keeping the `:latest` tag, you can:

1. Push your new image to DockerHub with the `:latest` tag
2. Use the `imagePullPolicy: Always` setting (default in this chart)
3. Trigger a rollout using one of these methods:
   - Force ArgoCD to sync: `argocd app sync tradevis-app --force`
   - Restart the deployment: `kubectl rollout restart deployment tradevis-frontend -n app`
   - Use ArgoCD Image Updater (recommended for production) 