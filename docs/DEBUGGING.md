# Debugging Guide

### `helm template` / `helm lint` fails
Run `helm lint charts/platform` for the exact line. Common causes: YAML indentation in
`values.yaml`, or a `{{ }}` typo in a template. Render with values to inspect:
`helm template coma charts/platform --debug`.

### kind: `ERROR: failed to create cluster`
Docker Desktop must be **running** (WSL2 backend on Windows). Check `docker info`. If a stale cluster
exists: `kind delete cluster --name coma` then retry.

### Pods stuck in `ImagePullBackOff`
- **kind:** the image wasn't loaded — run `kind load docker-image sample-service:dev --name coma`,
  and ensure `image.pullPolicy=IfNotPresent` with a tag that exists locally.
- **AKS:** ACR not attached — `az aks update --attach-acr <acr>`; confirm `image.repository` points at
  your ACR.

### Pods `CrashLoopBackOff`
`kubectl -n coma logs <pod>`. The service listens on 8080 (`ASPNETCORE_URLS`); make sure the probe
ports and `defaults.port` match.

### ServiceMonitor applied but no metrics in Prometheus
The Prometheus Operator CRDs must exist (install kube-prometheus-stack first). On plain kind without
the operator, install the chart with `--set metrics.enabled=false`. Verify the ServiceMonitor's
`release:` label matches your Prometheus release's selector.

### KEDA not scaling
Check `kubectl get scaledobject -n coma` and `kubectl describe scaledobject notification-scaler`.
Ensure KEDA is installed, the `servicebus-secret` exists, and the queue name matches. KEDA scales to
`minReplicaCount` when the queue is empty.

### ArgoCD shows `OutOfSync`
`argocd app get coma-platform` (or the UI). With `selfHeal: true`, manual cluster edits are reverted —
change Git, not the cluster.
