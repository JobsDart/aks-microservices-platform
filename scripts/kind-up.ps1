<#
.SYNOPSIS
    Spin up a local kind cluster and deploy the CoMa platform end-to-end — the free,
    local equivalent of the AKS deployment. Requires Docker Desktop running, plus kind,
    kubectl and helm on PATH.
.EXAMPLE
    ./scripts/kind-up.ps1
#>
$ErrorActionPreference = "Stop"
$cluster = "coma"
$image   = "sample-service:dev"

Write-Host "==> Creating kind cluster '$cluster'" -ForegroundColor Cyan
kind create cluster --name $cluster

Write-Host "==> Building service image" -ForegroundColor Cyan
docker build -t $image services/sample-service

Write-Host "==> Loading image into kind" -ForegroundColor Cyan
kind load docker-image $image --name $cluster

Write-Host "==> Installing Helm release (metrics off — no Prometheus Operator in plain kind)" -ForegroundColor Cyan
helm install coma charts/platform `
    --set image.repository=sample-service `
    --set image.tag=dev `
    --set image.pullPolicy=IfNotPresent `
    --set metrics.enabled=false `
    --namespace coma --create-namespace --wait --timeout 120s

Write-Host "==> Pods" -ForegroundColor Green
kubectl get pods -n coma -o wide

Write-Host ""
Write-Host "Port-forward a service to test it:" -ForegroundColor Green
Write-Host "  kubectl -n coma port-forward svc/coma-contract 8080:80"
Write-Host "  curl http://localhost:8080/health   # and /metrics"
Write-Host ""
Write-Host "Tear down with:  kind delete cluster --name $cluster" -ForegroundColor Yellow
