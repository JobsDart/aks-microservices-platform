<#
.SYNOPSIS
    Provision a real AKS cluster + Azure Container Registry, install ArgoCD, KEDA and
    the Prometheus stack, then deploy the platform via GitOps.
.PREREQUISITES
    Azure CLI + `az login`. NOTE: a running AKS cluster costs money — this is the
    production path, not the free local demo (use kind-up.ps1 for that).
.EXAMPLE
    ./scripts/provision-aks.ps1 -ResourceGroup rg-jobsdart-aks -Acr jobsdartacr -Cluster coma-aks
#>
param(
    [Parameter(Mandatory = $true)] [string] $ResourceGroup,
    [Parameter(Mandatory = $true)] [string] $Acr,
    [Parameter(Mandatory = $true)] [string] $Cluster,
    [string] $Location = "swedencentral"
)
$ErrorActionPreference = "Stop"

az group create -n $ResourceGroup -l $Location | Out-Null
az acr create -n $Acr -g $ResourceGroup --sku Basic | Out-Null
az aks create -n $Cluster -g $ResourceGroup --node-count 2 --attach-acr $Acr `
    --enable-managed-identity --generate-ssh-keys | Out-Null
az aks get-credentials -n $Cluster -g $ResourceGroup --overwrite-existing

az acr build -r $Acr -t sample-service:latest services/sample-service

# Platform add-ons
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack `
    -n monitoring --create-namespace -f observability/prometheus-values.yaml
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda -n keda --create-namespace

Write-Host "Cluster ready. Apply the GitOps app:" -ForegroundColor Green
Write-Host "  kubectl apply -f gitops/argocd-application.yaml"
