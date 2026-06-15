# Deployment Guide

## A. Local (kind) — free
Prereqs: Docker Desktop running, plus `kind`, `kubectl`, `helm`.
```powershell
./scripts/kind-up.ps1
kubectl get pods -n coma
```

## B. Validate the chart (no cluster)
```powershell
helm lint charts/platform
helm template coma charts/platform
```

## C. AKS (production — bills hourly)
```powershell
./scripts/provision-aks.ps1 -ResourceGroup rg-jobsdart-aks -Acr jobsdartacr -Cluster coma-aks
```
This provisions AKS + ACR (with AcrPull attached), installs **Prometheus stack**, **ArgoCD** and
**KEDA**, and builds the image into ACR. Then hand the platform to GitOps:
```powershell
kubectl apply -f gitops/argocd-application.yaml
```
ArgoCD will sync `charts/platform` from the Git repo into the `coma` namespace.

### KEDA secret (for Service Bus scaling)
```powershell
kubectl -n coma create secret generic servicebus-secret `
  --from-literal=connection="<servicebus-connection-string>"
kubectl apply -f keda/scaledobject-notification.yaml
```

### Observability
Prometheus auto-discovers the ServiceMonitors (label `release: prometheus`). Import
`observability/grafana-dashboard.json` into Grafana, or rely on the bundled dashboards.

## Image registry
- Local/kind: image is built and `kind load`ed (no registry).
- AKS: `az acr build` pushes to ACR; set `image.repository` in `values.yaml` to
  `<acr>.azurecr.io/sample-service`.
- CI: GitHub Actions pushes to GHCR on `main`.

## Production checklist
- [ ] ACR + AKS managed identity (no admin keys)
- [ ] ArgoCD with SSO + RBAC
- [ ] Network policies + private cluster
- [ ] Resource quotas per namespace
- [ ] Alerting rules in Prometheus (e.g. pod restarts, queue backlog)
