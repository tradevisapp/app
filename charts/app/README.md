# App Helm Chart

This Helm chart deploys the TradeVis application on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Ingress controller (such as nginx-ingress)

## Installing the Chart

To install the chart with the release name `my-app`:

```bash
helm install my-app ./app
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create namespace | `true` |
| `namespace.name` | Namespace name | `app` |
| `deployment.name` | Deployment name | `tradevis-frontend` |
| `deployment.replicas` | Number of replicas | `2` |
| `deployment.image.repository` | Image repository | `roeilevinson/tradevis-frontend` |
| `deployment.image.tag` | Image tag | `v0.1.20` |
| `deployment.image.pullPolicy` | Image pull policy | `Always` |
| `deployment.resources.limits.cpu` | CPU limit | `500m` |
| `deployment.resources.limits.memory` | Memory limit | `512Mi` |
| `deployment.resources.requests.cpu` | CPU request | `100m` |
| `deployment.resources.requests.memory` | Memory request | `128Mi` |
| `service.name` | Service name | `tradevis-frontend` |
| `service.type` | Service type | `NodePort` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Service target port | `80` |
| `service.nodePort` | Service node port | `30080` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.name` | Ingress name | `tradevis-ingress` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.host` | Ingress host | `tradevis.click` |
| `ingress.path` | Ingress path | `/` |
| `ingress.pathType` | Ingress path type | `Prefix` |

## Usage

To customize the deployment, create a values.yaml file and specify the parameters you want to override:

```yaml
deployment:
  replicas: 3
  image:
    tag: v0.1.21
ingress:
  host: dev.tradevis.click
```

Then install the chart with your custom values:

```bash
helm install my-app ./app -f values.yaml
``` 